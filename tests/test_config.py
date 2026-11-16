import pytest

from training.config import Config, ConfigError

BASE = {"DATA_URI": "s3://b/data/x.csv", "MODEL_BASE_URI": "s3://b/models/", "GIT_SHA": "abc123"}


def test_from_env_defaults_and_output_uri():
    cfg = Config.from_env(BASE)
    assert cfg.random_seed == 42
    assert cfg.test_size == 0.2
    assert cfg.output_uri == "s3://b/models/abc123"


def test_missing_required_vars_listed():
    with pytest.raises(ConfigError, match="DATA_URI, GIT_SHA"):
        Config.from_env({"MODEL_BASE_URI": "s3://b/models"})


@pytest.mark.parametrize("override", [{"RANDOM_SEED": "x"}, {"TEST_SIZE": "1.5"}])
def test_invalid_values_rejected(override):
    with pytest.raises(ConfigError):
        Config.from_env({**BASE, **override})
