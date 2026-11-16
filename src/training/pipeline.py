"""End-to-end run: fetch data, train, evaluate, publish versioned artifacts."""

from __future__ import annotations

import json
import logging
import platform
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
import sklearn

from . import data, model, storage
from .config import Config

logger = logging.getLogger(__name__)


def run(config: Config) -> dict[str, Any]:
    with tempfile.TemporaryDirectory() as tmp:
        workdir = Path(tmp)

        logger.info("Fetching dataset from %s", config.data_uri)
        data_path = storage.download(config.data_uri, workdir / "dataset.csv")
        X, y = data.load_dataset(data_path)

        X_train, X_test, y_train, y_test = model.split(X, y, config.test_size, config.random_seed)
        logger.info("Training on %d rows, evaluating on %d rows", len(y_train), len(y_test))
        fitted = model.train(X_train, y_train, config.random_seed)
        metrics = model.evaluate(fitted, X_test, y_test)

        report = {
            "git_sha": config.git_sha,
            "trained_at": datetime.now(timezone.utc).isoformat(),
            "random_seed": config.random_seed,
            "test_size": config.test_size,
            "model_params": model.MODEL_PARAMS,
            "data": {
                "uri": config.data_uri,
                "sha256": storage.sha256_file(data_path),
                "rows": int(len(y)),
                "fraud_rows": int(y.sum()),
            },
            "metrics": metrics,
            "versions": {
                "python": platform.python_version(),
                "scikit-learn": sklearn.__version__,
                "numpy": np.__version__,
                "pandas": pd.__version__,
            },
        }

        model_path = workdir / "model.joblib"
        metrics_path = workdir / "metrics.json"
        joblib.dump(fitted, model_path)
        metrics_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")

        logger.info("Publishing artifacts to %s", config.output_uri)
        storage.upload(model_path, f"{config.output_uri}/model.joblib")
        storage.upload(metrics_path, f"{config.output_uri}/metrics.json")

    logger.info(
        "Done: roc_auc=%.4f average_precision=%.4f",
        metrics["roc_auc"],
        metrics["average_precision"],
    )
    return report
