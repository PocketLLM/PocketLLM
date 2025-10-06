"""Helpers for loading the bundled fallback model catalogue."""

from __future__ import annotations

import json
import logging
from functools import lru_cache
from importlib import resources as importlib_resources
from pathlib import Path
from typing import Any, Iterable

from app.schemas.providers import ProviderModel

_LOGGER = logging.getLogger("app.data.static_models")


@lru_cache(maxsize=1)
def load_static_models() -> tuple[ProviderModel, ...]:
    """Return the static model catalogue shipped with the backend.

    The deployed API occasionally runs without provider credentials configured.
    In that case we expose a curated list of models so the mobile client can
    still present a meaningful catalogue. The JSON file is cached after the
    first read to avoid repeated disk access.
    """

    try:
        payload = _read_catalogue_payload()
    except FileNotFoundError:
        _LOGGER.warning("Static model catalogue not found; falling back to empty list")
        return tuple()
    except Exception:  # pragma: no cover - defensive logging
        _LOGGER.exception("Failed to load static model catalogue")
        return tuple()

    items: Iterable[Any]
    if isinstance(payload, dict):
        items = payload.get("models", []) or []
    elif isinstance(payload, list):
        items = payload
    else:
        _LOGGER.error("Unexpected payload type for static model catalogue: %s", type(payload))
        return tuple()

    models: list[ProviderModel] = []
    for entry in items:
        if not isinstance(entry, dict):
            continue
        try:
            models.append(ProviderModel(**entry))
        except Exception as exc:  # pragma: no cover - defensive logging
            _LOGGER.debug("Skipping malformed fallback model entry: %s", exc)
            continue

    return tuple(models)


def load_static_models_for_provider(provider: str) -> tuple[ProviderModel, ...]:
    """Return static catalogue entries scoped to a single provider."""

    provider_key = provider.lower()
    return tuple(
        model for model in load_static_models() if model.provider.lower() == provider_key
    )


def _read_catalogue_payload() -> Any:
    """Load the static catalogue JSON from package data or the repository root."""

    # Prefer a packaged resource so deployments that bundle the JSON alongside
    # the application keep working when executed from a different directory.
    try:
        resource = importlib_resources.files("app.data").joinpath("modellist.json")
        if resource.is_file():
            with resource.open("r", encoding="utf-8") as handle:
                return json.load(handle)
    except (FileNotFoundError, ModuleNotFoundError, AttributeError):
        pass

    # Fallback to the repository layout used during local development.
    project_root = Path(__file__).resolve().parents[2]
    json_path = project_root / "modellist.json"
    if json_path.is_file():
        with json_path.open("r", encoding="utf-8") as handle:
            return json.load(handle)

    raise FileNotFoundError("modellist.json not found in expected locations")


__all__ = ["load_static_models", "load_static_models_for_provider"]
