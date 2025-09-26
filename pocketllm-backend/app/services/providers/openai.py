"""OpenAI provider client implementation."""

from __future__ import annotations

from typing import Any, Mapping

import httpx

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient


class OpenAIProviderClient(ProviderClient):
    """Fetch models from the OpenAI platform."""

    provider = "openai"
    default_base_url = "https://api.openai.com/v1"

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

    @property
    def base_url(self) -> str:
        if self._base_url_override:
            return self._base_url_override
        api_base = getattr(self._settings, "openai_api_base", None)
        return api_base or self.default_base_url

    def _get_api_key(self) -> str | None:  # pragma: no cover - simple accessor
        return self._api_key_override or getattr(self._settings, "openai_api_key", None)

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
            context_window = entry.get("context_window") or entry.get("context_length")
            max_output_tokens = entry.get("max_output_tokens") or entry.get("max_tokens")
            metadata = {
                key: entry.get(key)
                for key in ("object", "created", "owned_by", "permission")
                if entry.get(key) is not None
            }
            models.append(
                ProviderModel(
                    provider=self.provider,
                    id=model_id,
                    name=name,
                    description=entry.get("description"),
                    context_window=context_window,
                    max_output_tokens=max_output_tokens,
                    pricing=None,
                    is_active=entry.get("status"),
                    metadata=metadata or None,
                )
            )
        return models


__all__ = ["OpenAIProviderClient"]
