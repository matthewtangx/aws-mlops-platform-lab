import json

from training.config import Config
from training.pipeline import run


def test_run_writes_versioned_artifacts(tmp_path, dataset_csv):
    base = tmp_path / "models"
    cfg = Config(data_uri=str(dataset_csv), model_base_uri=str(base), git_sha="deadbeef")

    report = run(cfg)

    out = base / "deadbeef"
    assert (out / "model.joblib").stat().st_size > 0
    saved = json.loads((out / "metrics.json").read_text())
    assert saved["git_sha"] == "deadbeef"
    assert saved["data"]["rows"] == 600
    assert len(saved["data"]["sha256"]) == 64
    assert saved["metrics"] == report["metrics"]


def test_rerun_with_same_inputs_gives_same_metrics(tmp_path, dataset_csv):
    def go(name):
        cfg = Config(str(dataset_csv), str(tmp_path / name), "sha")
        return run(cfg)["metrics"]

    assert go("a") == go("b")
