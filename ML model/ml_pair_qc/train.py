#!/usr/bin/env python3
"""Train Good vs Bad pair classifier from pair_labels.csv + Summary Sleep files."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.impute import SimpleImputer
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import GroupKFold
from sklearn.pipeline import Pipeline

from ml_pair_qc.config import (
    ARTIFACTS_DIR,
    EXPERIMENT_OUTPUT_DIRS,
    LABELS_CSV,
    MODEL_PATH,
)
from ml_pair_qc.features import FEATURE_ORDER, extract_pair_features, vectorize_features


def build_training_matrix(labels_path: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray, list[str]]:
    df = pd.read_csv(labels_path)
    X_list: list[np.ndarray] = []
    y_list: list[int] = []
    groups: list[str] = []
    errors: list[str] = []

    for _, row in df.iterrows():
        exp = str(row["experiment_date"])
        eth = str(row["ethoscope_id"])
        if exp not in EXPERIMENT_OUTPUT_DIRS:
            errors.append(f"Unknown experiment {exp}")
            continue
        out_dir = EXPERIMENT_OUTPUT_DIRS[exp]
        fp = out_dir / f"Sleep_{eth}_Focal.txt"
        yp = out_dir / f"Sleep_{eth}_Yoked.txt"
        if not fp.is_file() or not yp.is_file():
            errors.append(f"Missing files for {exp} {eth}")
            continue

        skip = int(row["skip_rows"])
        ft = int(row["focal_tube"])
        yt = int(row["yoked_tube"])
        try:
            feats = extract_pair_features(fp, yp, ft, yt, skip)
        except Exception as e:
            errors.append(f"{exp} {eth} P{row['pair_id']}: {e}")
            continue

        X_list.append(vectorize_features(feats))
        y_list.append(1 if str(row["label"]).strip() == "Bad" else 0)
        groups.append(exp)

    if errors:
        print("Warnings:", file=sys.stderr)
        for e in errors[:20]:
            print(f"  {e}", file=sys.stderr)
        if len(errors) > 20:
            print(f"  ... and {len(errors) - 20} more", file=sys.stderr)

    if not X_list:
        raise SystemExit("No training rows loaded.")

    X = np.vstack(X_list)
    y = np.asarray(y_list, dtype=np.int32)
    groups_arr = np.asarray(groups)
    return X, y, groups_arr, groups


def make_pipeline() -> Pipeline:
    """Impute NaNs then HGB (handles nonlinearities; works well on small tabular data)."""
    return Pipeline(
        [
            (
                "imputer",
                SimpleImputer(strategy="median"),
            ),
            (
                "clf",
                HistGradientBoostingClassifier(
                    learning_rate=0.06,
                    max_iter=120,
                    max_depth=4,
                    min_samples_leaf=8,
                    l2_regularization=0.1,
                    class_weight="balanced",
                    random_state=42,
                ),
            ),
        ]
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--labels",
        type=Path,
        default=LABELS_CSV,
        help="Path to pair_labels.csv",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=MODEL_PATH,
        help="Where to save trained pipeline (.joblib)",
    )
    parser.add_argument("--no-cv", action="store_true", help="Skip leave-one-experiment-out CV")
    args = parser.parse_args()

    X, y, groups, group_names = build_training_matrix(args.labels)
    print(f"Loaded {len(y)} rows: Bad={int(y.sum())} Good={int(len(y) - y.sum())}")
    print(f"Features ({len(FEATURE_ORDER)}): {', '.join(FEATURE_ORDER[:6])}...")

    pipe = make_pipeline()

    if not args.no_cv:
        gkf = GroupKFold(n_splits=len(np.unique(groups)))
        oof_pred = np.zeros(len(y), dtype=np.int32)
        oof_proba = np.zeros(len(y), dtype=np.float64)
        for train_idx, test_idx in gkf.split(X, y, groups):
            pipe.fit(X[train_idx], y[train_idx])
            oof_proba[test_idx] = pipe.predict_proba(X[test_idx])[:, 1]
            oof_pred[test_idx] = pipe.predict(X[test_idx])
        print("\n=== Leave-one-experiment-out CV ===")
        for exp in np.unique(groups):
            m = groups == exp
            print(f"\nHeld out: {exp}  (n={m.sum()})")
            print(classification_report(y[m], oof_pred[m], target_names=["Good", "Bad"], zero_division=0))
        print("\n=== OOF (all held-out folds combined) ===")
        print(classification_report(y, oof_pred, target_names=["Good", "Bad"], zero_division=0))
        print("Confusion matrix [ [TN FP] [FN TP] ] Good=0 Bad=1:")
        print(confusion_matrix(y, oof_pred))

    pipe.fit(X, y)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    artifact = {
        "pipeline": pipe,
        "feature_names": FEATURE_ORDER,
        "label_bad_is_1": True,
        "training_csv": str(args.labels.resolve()),
    }
    joblib.dump(artifact, args.out)
    meta_path = args.out.with_suffix(".json")
    meta_path.write_text(
        json.dumps(
            {
                "feature_names": FEATURE_ORDER,
                "n_train": len(y),
                "n_bad": int(y.sum()),
                "n_good": int(len(y) - y.sum()),
                "experiments": sorted(set(group_names)),
                "model_path": str(args.out.resolve()),
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"\nSaved model -> {args.out}")
    print(f"Saved meta   -> {meta_path}")


if __name__ == "__main__":
    main()
