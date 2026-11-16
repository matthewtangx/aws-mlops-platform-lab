"""Load and validate the Kaggle credit-card fraud dataset."""

from __future__ import annotations

from pathlib import Path

import pandas as pd

TARGET = "Class"
FEATURES = ["Time", *[f"V{i}" for i in range(1, 29)], "Amount"]


def load_dataset(path: Path) -> tuple[pd.DataFrame, pd.Series]:
    df = pd.read_csv(path)

    missing = [c for c in [*FEATURES, TARGET] if c not in df.columns]
    if missing:
        raise ValueError(f"Dataset is missing columns: {', '.join(missing)}")
    if df[[*FEATURES, TARGET]].isna().any().any():
        raise ValueError("Dataset contains missing values")
    if not set(df[TARGET].unique()) <= {0, 1}:
        raise ValueError("Target column must contain only 0 and 1")
    if df[TARGET].nunique() < 2:
        raise ValueError("Target column must contain both classes")

    return df[FEATURES], df[TARGET].astype(int)
