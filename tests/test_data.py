import pytest

from training.data import FEATURES, TARGET, load_dataset


def test_load_dataset_returns_features_and_target(dataset_csv):
    X, y = load_dataset(dataset_csv)
    assert list(X.columns) == FEATURES
    assert set(y.unique()) == {0, 1}


def test_missing_column_rejected(tmp_path, frame):
    path = tmp_path / "bad.csv"
    frame.drop(columns=["V1"]).to_csv(path, index=False)
    with pytest.raises(ValueError, match="V1"):
        load_dataset(path)


def test_single_class_rejected(tmp_path, frame):
    path = tmp_path / "one.csv"
    frame.assign(**{TARGET: 0}).to_csv(path, index=False)
    with pytest.raises(ValueError, match="both classes"):
        load_dataset(path)


def test_nan_rejected(tmp_path, frame):
    frame.loc[0, "Amount"] = None
    path = tmp_path / "nan.csv"
    frame.to_csv(path, index=False)
    with pytest.raises(ValueError, match="missing values"):
        load_dataset(path)
