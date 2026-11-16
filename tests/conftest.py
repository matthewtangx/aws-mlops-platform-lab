import numpy as np
import pandas as pd
import pytest

from training.data import FEATURES, TARGET


def make_frame(rows: int = 600, fraud_rate: float = 0.1, seed: int = 0) -> pd.DataFrame:
    """Synthetic frame with the Kaggle schema and a learnable signal."""
    rng = np.random.default_rng(seed)
    y = (rng.random(rows) < fraud_rate).astype(int)
    X = rng.normal(size=(rows, len(FEATURES)))
    X[:, 1] += y * 2.5  # V1 separates the classes
    df = pd.DataFrame(X, columns=FEATURES)
    df[TARGET] = y
    return df


@pytest.fixture
def frame() -> pd.DataFrame:
    return make_frame()


@pytest.fixture
def dataset_csv(tmp_path, frame):
    path = tmp_path / "creditcard.csv"
    frame.to_csv(path, index=False)
    return path
