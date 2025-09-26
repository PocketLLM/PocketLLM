"""Groq provider client implementation."""

from __future__ import annotations

from typing import Any

import httpx

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient


class GroqProviderClient(ProviderClient):
    """Fetch available models from Groq Cloud."""

    provider = "groq"
    default_base_url = "https://api.groq.com/openai/v1"

    def __init__(
        self,
        settings: Settings,
        *,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        super().__init__(settings, transport=transport)

    @property
    def base_url(self) -> str:
        api_base = getattr(self._settings, "groq_api_base", None)
        return api_base or self.default_base_url

    def _get_api_key(self) -> str | None:  # pragma: no cover - simple accessor
        return getattr(self._settings, "groq_api_key", None)

    def _parse_models(self, payload: Any) -> list[ProviderModel]:
        data = payload.get("data", []) if isinstance(payload, dict) else []
        models: list[ProviderModel] = []
        for entry in data:
            if not isinstance(entry, dict):
                continue
            model_id = entry.get("id")
            if not model_id:
                continue
            name = entry.get("name") or model_id
            metadata_keys = (
                "type",
                "owned_by",
                "permissions",
                "support_disclaimer",
                "capabilities",
            )
            metadata = {key: entry.get(key) for key in metadata_keys if entry.get(key) is not None}
            models.append(
                ProviderModel(
                    provider=self.provider,
                    id=model_id,
                    name=name,
                    description=entry.get("description"),
                    context_window=entry.get("context_window"),
                    max_output_tokens=entry.get("max_output_tokens"),
                    pricing=entry.get("pricing"),
                    is_active=entry.get("active"),
                    metadata=metadata or None,
                )
            )
        return models


__all__ = ["GroqProviderClient"]
