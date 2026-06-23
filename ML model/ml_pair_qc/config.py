"""Paths and constants shared by train / predict."""

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
LABELS_CSV = PROJECT_ROOT / "pair_labels.csv"
MODEL_PATH = Path(__file__).resolve().parent / "artifacts" / "pair_qc_model.joblib"
ARTIFACTS_DIR = Path(__file__).resolve().parent / "artifacts"

SUMMARY_ROOT = PROJECT_ROOT / "Summary"

# experiment_date -> directory containing Sleep_Eth*_Focal.txt (training data only)
EXPERIMENT_OUTPUT_DIRS = {
    "9-Feb-2026": SUMMARY_ROOT / "EXP_02_09" / "analysis_output",
    "17-Mar-2026": SUMMARY_ROOT / "EXP_03_17" / "Analysis scripts" / "analysis_output",
    "27-Mar-2026": SUMMARY_ROOT / "EXP_03_27" / "Analysis scripts" / "analysis_output",
    "6-Apr-2026": SUMMARY_ROOT / "EXP_04_06" / "analysis_output",
}

# pair_id -> (focal_tube, yoked_tube); must match R PAIRS
PAIR_TUBES = {
    1: (1, 12),
    2: (3, 14),
    3: (5, 16),
    4: (7, 18),
    5: (9, 20),
}

BINS_PER_DAY = 48  # 30-min bins, 24 h
