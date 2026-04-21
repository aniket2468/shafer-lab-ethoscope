"""Load Sleep Focal/Yoked tables and compute per-pair numeric features."""

from __future__ import annotations

from pathlib import Path
from typing import Any

import numpy as np


def _read_column(path: Path, col: str) -> tuple[np.ndarray, np.ndarray]:
    with open(path, encoding="utf-8") as f:
        header = f.readline().strip().split("\t")
    if "ZT" not in header:
        raise ValueError(f"No ZT column in {path}")
    if col not in header:
        raise ValueError(f"Column {col!r} not in {path}")
    zi = header.index("ZT")
    ci = header.index(col)
    zt_list: list[float] = []
    val_list: list[float] = []
    with open(path, encoding="utf-8") as f:
        next(f)
        for line in f:
            parts = line.strip().split("\t")
            if len(parts) <= max(zi, ci):
                continue
            zt_list.append(float(parts[zi]))
            v = parts[ci]
            if v in ("NA", "", "nan"):
                val_list.append(np.nan)
            else:
                val_list.append(float(v))
    return np.asarray(zt_list), np.asarray(val_list, dtype=np.float64)


def _trim(arr: np.ndarray, skip_rows: int) -> np.ndarray:
    if skip_rows <= 0:
        return arr.copy()
    return arr[int(skip_rows) :].copy()


def _safe_corr(a: np.ndarray, b: np.ndarray) -> float:
    m = np.isfinite(a) & np.isfinite(b)
    if m.sum() < 24:
        return float("nan")
    x, y = a[m], b[m]
    if x.std() < 1e-9 or y.std() < 1e-9:
        return float("nan")
    return float(np.corrcoef(x, y)[0, 1])


def _max_extreme_run(x: np.ndarray) -> int:
    """Longest consecutive bins with sleep < 1 or sleep > 29."""
    if len(x) == 0:
        return 0
    mask = np.isfinite(x) & ((x < 1.0) | (x > 29.0))
    best = cur = 0
    for v in mask:
        if v:
            cur += 1
            best = max(best, cur)
        else:
            cur = 0
    return int(best)


def _autocorr_lag(x: np.ndarray, lag: int) -> float:
    """Pearson corr between x[t] and x[t-lag] (same ZT next day)."""
    m = np.isfinite(x)
    if m.sum() < lag + 24:
        return float("nan")
    # use positions where both t and t-lag valid
    a = x[lag:]
    b = x[:-lag]
    m2 = np.isfinite(a) & np.isfinite(b)
    if m2.sum() < 24:
        return float("nan")
    a, b = a[m2], b[m2]
    if a.std() < 1e-9:
        return float("nan")
    return float(np.corrcoef(a, b)[0, 1])


def extract_pair_features(
    focal_path: Path,
    yoked_path: Path,
    focal_tube: int,
    yoked_tube: int,
    skip_rows: int,
) -> dict[str, Any]:
    """
    focal_path: Sleep_*_Focal.txt (columns T1,T3,...)
    yoked_path: Sleep_*_Yoked.txt (columns T12,...)
    """
    zt_f, f = _read_column(focal_path, f"T{focal_tube}")
    zt_y, y = _read_column(yoked_path, f"T{yoked_tube}")
    if len(zt_f) != len(zt_y) or not np.allclose(zt_f, zt_y, equal_nan=True):
        raise ValueError("Focal and Yoked files must have same length and ZT grid")

    f = _trim(f, skip_rows)
    y = _trim(y, skip_rows)
    zt = _trim(zt_f, skip_rows)

    m = np.isfinite(f) & np.isfinite(y)
    n_valid = int(m.sum())
    if n_valid < 48:
        return _empty_feature_dict(n_valid)

    f0, y0 = f[m], y[m]
    z0 = zt[m]

    light = (z0 > 0) & (z0 <= 12)
    dark = (z0 > 12) & (z0 <= 24)

    def phase_block(mask: np.ndarray) -> tuple[float, float, float, float]:
        if mask.sum() < 8:
            return (np.nan, np.nan, np.nan, np.nan)
        ff, yy = f0[mask], y0[mask]
        return (
            float(np.std(ff)),
            float(np.std(yy)),
            float(np.mean(np.abs(ff - yy))),
            float(np.mean(ff) - np.mean(yy)),
        )

    l_std_f, l_std_y, l_mad, l_mean_diff = phase_block(light)
    d_std_f, d_std_y, d_mad, d_mean_diff = phase_block(dark)

    wf, wy = 30.0 - f0, 30.0 - y0

    feats: dict[str, Any] = {
        "n_valid_bins": n_valid,
        "mean_sleep_f": float(np.mean(f0)),
        "mean_sleep_y": float(np.mean(y0)),
        "std_sleep_f": float(np.std(f0)),
        "std_sleep_y": float(np.std(y0)),
        "corr_fy": _safe_corr(f0, y0),
        "mean_abs_diff_fy": float(np.mean(np.abs(f0 - y0))),
        "frac_sat_f": float(np.mean((f0 < 0.5) | (f0 > 29.5))),
        "frac_sat_y": float(np.mean((y0 < 0.5) | (y0 > 29.5))),
        "max_run_extreme_f": float(_max_extreme_run(f)),
        "max_run_extreme_y": float(_max_extreme_run(y)),
        "std_wake_f": float(np.std(wf)),
        "std_wake_y": float(np.std(wy)),
        "light_std_f": l_std_f,
        "light_std_y": l_std_y,
        "light_mean_abs_diff_fy": l_mad,
        "light_mean_f_minus_y": l_mean_diff,
        "dark_std_f": d_std_f,
        "dark_std_y": d_std_y,
        "dark_mean_abs_diff_fy": d_mad,
        "dark_mean_f_minus_y": d_mean_diff,
        "autocorr_f_lag48": _autocorr_lag(f, 48),
        "autocorr_y_lag48": _autocorr_lag(y, 48),
    }
    return feats


def _empty_feature_dict(n_valid: int) -> dict[str, Any]:
    keys = [
        "n_valid_bins",
        "mean_sleep_f",
        "mean_sleep_y",
        "std_sleep_f",
        "std_sleep_y",
        "corr_fy",
        "mean_abs_diff_fy",
        "frac_sat_f",
        "frac_sat_y",
        "max_run_extreme_f",
        "max_run_extreme_y",
        "std_wake_f",
        "std_wake_y",
        "light_std_f",
        "light_std_y",
        "light_mean_abs_diff_fy",
        "light_mean_f_minus_y",
        "dark_std_f",
        "dark_std_y",
        "dark_mean_abs_diff_fy",
        "dark_mean_f_minus_y",
        "autocorr_f_lag48",
        "autocorr_y_lag48",
    ]
    out = {k: float("nan") for k in keys}
    out["n_valid_bins"] = float(n_valid)
    return out


FEATURE_ORDER = [
    "n_valid_bins",
    "mean_sleep_f",
    "mean_sleep_y",
    "std_sleep_f",
    "std_sleep_y",
    "corr_fy",
    "mean_abs_diff_fy",
    "frac_sat_f",
    "frac_sat_y",
    "max_run_extreme_f",
    "max_run_extreme_y",
    "std_wake_f",
    "std_wake_y",
    "light_std_f",
    "light_std_y",
    "light_mean_abs_diff_fy",
    "light_mean_f_minus_y",
    "dark_std_f",
    "dark_std_y",
    "dark_mean_abs_diff_fy",
    "dark_mean_f_minus_y",
    "autocorr_f_lag48",
    "autocorr_y_lag48",
]


def vectorize_features(feats: dict[str, Any]) -> np.ndarray:
    return np.array([feats.get(k, np.nan) for k in FEATURE_ORDER], dtype=np.float64)
