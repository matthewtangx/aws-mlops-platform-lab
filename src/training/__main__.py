"""Entry point: python -m training (configured via environment variables)."""

from __future__ import annotations

import logging
import sys

from .config import Config, ConfigError
from .pipeline import run


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
    try:
        config = Config.from_env()
    except ConfigError as exc:
        logging.error("%s", exc)
        return 2
    run(config)
    return 0


if __name__ == "__main__":
    sys.exit(main())
