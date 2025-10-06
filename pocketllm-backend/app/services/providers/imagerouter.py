"""ImageRouter provider client implemented using HTTP requests."""

from __future__ import annotations

from collections.abc import Iterable, Mapping, Sequence
from typing import Any

import httpx

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient


class ImageRouterProviderClient(ProviderClient):
    """Fetch ImageRouter models via its OpenAI-compatible HTTP API."""

    provider = "imagerouter"
    default_base_url = "https://api.imagerouter.io/v1/openai"

    def __init__(
        self,
        settings: Settings,
        *,
        base_url: str | None = None,
        api_key: str | None = None,
        metadata: Mapping[str, Any] | None = None,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        super().__init__(
            settings,
            base_url=base_url,
            api_key=api_key,
            metadata=metadata,
            transport=transport,
        )

    def _additional_headers(self) -> dict[str, str]:
        headers: dict[str, str] = {"Content-Type": "application/json"}
        metadata = self.metadata if isinstance(self.metadata, Mapping) else {}
        extra_headers = metadata.get("headers")
        if isinstance(extra_headers, Mapping):
            headers.update({str(key): str(value) for key, value in extra_headers.items()})
        return headers

    def _parse_models(self, payload: Any) -> list[ProviderModel]:
        entries = self._extract_model_entries(payload)
        models: list[ProviderModel] = []
        for entry in entries:
            mapping = self._normalise_entry(entry)
            if not mapping:
                continue
            model_id = mapping.get("id")
            if not model_id:
                continue
            name = mapping.get("name") or model_id
            metadata: dict[str, Any] = {}
            for key in ("capabilities", "supported_formats", "provider", "owned_by"):
                value = mapping.get(key)
                if value is not None:
                    metadata[key] = value
            description = mapping.get("description")
            pricing = mapping.get("pricing")
            models.append(
                ProviderModel(
                    provider=self.provider,
                    id=model_id,
                    name=name,
                    description=description,
                    context_window=None,
                    max_output_tokens=None,
                    pricing=pricing,
                    is_active=mapping.get("status") or mapping.get("enabled"),
                    metadata=metadata or None,
                )
            )
        return models

    def _extract_model_entries(self, payload: Any) -> Iterable[Any]:
        if payload is None:
            return []
        if isinstance(payload, Mapping):
            data = payload.get("data", [])
        elif hasattr(payload, "data"):
            data = getattr(payload, "data")
        elif hasattr(payload, "model_dump"):
            try:
                dumped = payload.model_dump()
            except Exception:  # pragma: no cover - defensive catch-all
                dumped = {}
            data = dumped.get("data", []) if isinstance(dumped, Mapping) else []
        else:
            data = []
        if isinstance(data, Sequence):
            return data
        if isinstance(data, Iterable):
            return list(data)
        return []

    def _normalise_entry(self, entry: Any) -> Mapping[str, Any]:
        if isinstance(entry, Mapping):
            return entry
        if hasattr(entry, "model_dump"):
            try:
                dumped = entry.model_dump()
                if isinstance(dumped, Mapping):
                    return dumped
            except Exception:  # pragma: no cover - defensive catch-all
                pass
        keys = {
            key: getattr(entry, key)
            for key in (
                "id",
                "name",
                "description",
                "pricing",
                "status",
                "enabled",
                "capabilities",
                "supported_formats",
                "provider",
                "owned_by",
            )
            if hasattr(entry, key)
        }
        return {key: value for key, value in keys.items() if value is not None}


__all__ = ["ImageRouterProviderClient"]
