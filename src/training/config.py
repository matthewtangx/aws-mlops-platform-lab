"""Runtime configuration, read from environment variables."""

from __future__ import annotations

import os
from collections.abc import Mapping
from dataclasses import dataclass


class ConfigError(ValueError):
    """Raised when required configuration is missing or invalid."""


@dataclass(frozen=True)
class Config:
    data_uri: str
    model_base_uri: str
    git_sha: str
    random_seed: int = 42
    test_size: float = 0.2

    @property
    def output_uri(self) -> str:
        """Versioned location for this run's artifacts: <MODEL_BASE_URI>/<GIT_SHA>."""
        return f"{self.model_base_uri.rstrip('/')}/{self.git_sha}"

    @classmethod
    def from_env(cls, env: Mapping[str, str] | None = None) -> Config:
        env = os.environ if env is None else env
        missing = [k for k in ("DATA_URI", "MODEL_BASE_URI", "GIT_SHA") if not env.get(k)]
        if missing:
            raise ConfigError(f"Missing required environment variables: {', '.join(missing)}")

        try:
            seed = int(env.get("RANDOM_SEED", "42"))
            test_size = float(env.get("TEST_SIZE", "0.2"))
        except ValueError as exc:
            raise ConfigError(f"Invalid numeric configuration: {exc}") from exc
        if not 0 < test_size < 1:
            raise ConfigError("TEST_SIZE must be between 0 and 1")

        return cls(
            data_uri=env["DATA_URI"],
            model_base_uri=env["MODEL_BASE_URI"],
            git_sha=env["GIT_SHA"],
            random_seed=seed,
            test_size=test_size,
        )
