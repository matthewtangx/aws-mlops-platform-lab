from training import model
from training.data import FEATURES, TARGET


def _fit(frame, seed=42):
    X, y = frame[FEATURES], frame[TARGET]
    X_tr, X_te, y_tr, y_te = model.split(X, y, 0.2, seed)
    return model.train(X_tr, y_tr, seed), X_te, y_te


def test_model_learns_signal(frame):
    fitted, X_te, y_te = _fit(frame)
    metrics = model.evaluate(fitted, X_te, y_te)
    assert metrics["roc_auc"] > 0.9
    assert sum(metrics["confusion_matrix"].values()) == len(y_te)


def test_training_is_reproducible(frame):
    a = model.evaluate(*_fit(frame))
    b = model.evaluate(*_fit(frame))
    assert a == b


def test_split_is_stratified(frame):
    X, y = frame[FEATURES], frame[TARGET]
    _, _, y_tr, y_te = model.split(X, y, 0.2, 1)
    assert abs(y_tr.mean() - y_te.mean()) < 0.03
