#!/usr/bin/env python3
"""
Score all five yoked pairs from one ethoscope's Sleep_*_Focal.txt and Sleep_*_Yoked.txt.

Example:
  cd "/path/to/Ethoscope"
  python -m ml_pair_qc.predict \\
    --focal "Summary/EXP_04_06/analysis_output/Sleep_Eth008_Focal.txt" \\
    --yoked "Summary/EXP_04_06/analysis_output/Sleep_Eth008_Yoked.txt" \\
    --skip-rows 34 \\
    --threshold 0.5
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import joblib
import pandas as pd

from ml_pair_qc.config import MODEL_PATH, PAIR_TUBES
from ml_pair_qc.features import vectorize_features, extract_pair_features


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--focal", type=Path, required=True, help="Sleep_*_Focal.txt path")
    parser.add_argument("--yoked", type=Path, required=True, help="Sleep_*_Yoked.txt path")
    parser.add_argument("--skip-rows", type=int, required=True, help="Bins to drop at start (match your R skip_rows)")
    parser.add_argument(
        "--model",
        type=Path,
        default=MODEL_PATH,
        help="Trained .joblib from train.py",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=0.5,
        help="Eliminate pair if P(Bad) >= threshold",
    )
    parser.add_argument("--json", action="store_true", help="Print one JSON object to stdout")
    args = parser.parse_args()

    if not args.model.is_file():
        print(f"Model not found: {args.model}\nRun: python -m ml_pair_qc.train", file=sys.stderr)
        sys.exit(1)

    art = joblib.load(args.model)
    pipe = art["pipeline"]

    rows = []
    for pair_id, (ft, yt) in PAIR_TUBES.items():
        feats = extract_pair_features(args.focal, args.yoked, ft, yt, args.skip_rows)
        x = vectorize_features(feats).reshape(1, -1)
        p_bad = float(pipe.predict_proba(x)[0, 1])
        eliminate = p_bad >= args.threshold
        rows.append(
            {
                "pair_id": pair_id,
                "focal_tube": ft,
                "yoked_tube": yt,
                "p_bad": round(p_bad, 4),
                "eliminate": bool(eliminate),
            }
        )

    if args.json:
        print(json.dumps(rows, indent=2))
        return

    df = pd.DataFrame(rows)
    print(df.to_string(index=False))
    to_drop = df.loc[df["eliminate"], "pair_id"].tolist()
    print(f"\nPairs to eliminate (P_bad >= {args.threshold}): {to_drop if to_drop else 'none'}")


if __name__ == "__main__":
    main()
