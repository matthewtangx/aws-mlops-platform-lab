"""Model definition, training and evaluation."""

from __future__ import annotations

from typing import Any

import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    average_precision_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

MODEL_PARAMS: dict[str, Any] = {"class_weight": "balanced", "max_iter": 1000}


def split(
    X: pd.DataFrame, y: pd.Series, test_size: float, seed: int
) -> tuple[pd.DataFrame, pd.DataFrame, pd.Series, pd.Series]:
    return train_test_split(X, y, test_size=test_size, random_state=seed, stratify=y)


def build_pipeline(seed: int) -> Pipeline:
    return Pipeline(
        [
            ("scale", StandardScaler()),
            ("clf", LogisticRegression(random_state=seed, **MODEL_PARAMS)),
        ]
    )


def train(X_train: pd.DataFrame, y_train: pd.Series, seed: int) -> Pipeline:
    pipeline = build_pipeline(seed)
    pipeline.fit(X_train, y_train)
    return pipeline


def evaluate(model: Pipeline, X_test: pd.DataFrame, y_test: pd.Series) -> dict[str, Any]:
    scores = model.predict_proba(X_test)[:, 1]
    preds = model.predict(X_test)
    tn, fp, fn, tp = confusion_matrix(y_test, preds, labels=[0, 1]).ravel()
    return {
        "roc_auc": float(roc_auc_score(y_test, scores)),
        "average_precision": float(average_precision_score(y_test, scores)),
        "precision": float(precision_score(y_test, preds, zero_division=0)),
        "recall": float(recall_score(y_test, preds, zero_division=0)),
        "f1": float(f1_score(y_test, preds, zero_division=0)),
        "confusion_matrix": {
            "tn": int(tn),
            "fp": int(fp),
            "fn": int(fn),
            "tp": int(tp),
        },
        "test_rows": int(len(y_test)),
    }
