"""Core application infrastructure modules."""

from importlib import import_module
from typing import Any

__all__ = [
    "Settings",
    "get_settings",
    "Database",
    "get_database",
    "connect_to_database",
    "close_database",
    "configure_logging",
    "LoggingMiddleware",
    "RequestContextMiddleware",
]


_ATTR_TO_MODULE = {
    "Settings": "app.core.config",
    "get_settings": "app.core.config",
    "Database": "app.core.database",
    "get_database": "app.core.database",
    "connect_to_database": "app.core.database",
    "close_database": "app.core.database",
    "configure_logging": "app.core.logging",
    "LoggingMiddleware": "app.core.middleware",
    "RequestContextMiddleware": "app.core.middleware",
}


def __getattr__(name: str) -> Any:
    module_name = _ATTR_TO_MODULE.get(name)
    if module_name is None:
        raise AttributeError(f"module {__name__} has no attribute {name}")
    module = import_module(module_name)
    return getattr(module, name)
