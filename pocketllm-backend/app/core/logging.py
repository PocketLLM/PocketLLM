"""Logging configuration helpers."""

from __future__ import annotations

import logging
from logging.config import dictConfig
from typing import Any, Dict

from .config import Settings


def configure_logging(settings: Settings) -> None:
    """Configure structured logging for the application."""

    log_format = "%(asctime)s | %(levelname)s | %(name)s | %(message)s"
    if settings.log_json:
        log_format = "%(message)s"

    log_config: Dict[str, Any] = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "default": {
                "format": log_format,
            },
            "uvicorn": {
                "()": "uvicorn.logging.DefaultFormatter",
                "fmt": "%(levelprefix)s %(name)s %(message)s",
                "use_colors": not settings.log_json,
            },
        },
        "handlers": {
            "default": {
                "level": settings.log_level,
                "class": "logging.StreamHandler",
                "formatter": "default",
            },
            "uvicorn.access": {
                "level": settings.log_level,
                "class": "logging.StreamHandler",
                "formatter": "uvicorn",
            },
        },
        "loggers": {
            "": {"handlers": ["default"], "level": settings.log_level},
            "uvicorn": {"handlers": ["default"], "level": settings.log_level},
            "uvicorn.error": {"handlers": ["default"], "level": settings.log_level, "propagate": True},
            "uvicorn.access": {
                "handlers": ["uvicorn.access"],
                "level": settings.log_level,
                "propagate": False,
            },
        },
    }

    dictConfig(log_config)
    logging.getLogger(__name__).info("Logging configured", extra={"level": settings.log_level})


__all__ = ["configure_logging"]
