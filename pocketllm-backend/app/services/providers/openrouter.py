"""OpenRouter provider client implementation."""

from __future__ import annotations

from typing import Any, Mapping

import httpx

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient


class OpenRouterProviderClient(ProviderClient):
    """Fetch available models through the OpenRouter catalogue."""

    provider = "openrouter"
    default_base_url = "https://openrouter.ai/api/v1"

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
        api_base = getattr(self._settings, "openrouter_api_base", None)
        return api_base or self.default_base_url

    def _get_api_key(self) -> str | None:  # pragma: no cover - simple accessor
        return self._api_key_override or getattr(self._settings, "openrouter_api_key", None)

    def _additional_headers(self) -> dict[str, str]:
        headers: dict[str, str] = {}
        metadata_referer = None
        metadata_title = None
        if self.metadata:
            metadata_referer = self.metadata.get("http_referer") or self.metadata.get("referer")
            metadata_title = self.metadata.get("x_title") or self.metadata.get("app_name")
        app_url = metadata_referer or getattr(self._settings, "openrouter_app_url", None)
        if app_url:
            headers["HTTP-Referer"] = app_url
        app_name = metadata_title or getattr(self._settings, "openrouter_app_name", None)
        if app_name:
            headers["X-Title"] = app_name
        return headers

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
            context_window = entry.get("context_length") or entry.get("context_window")
            pricing = entry.get("pricing")
            top_provider = entry.get("top_provider")
            if not isinstance(top_provider, dict):
                top_provider = None
            max_output_tokens = None
            if isinstance(top_provider, dict):
                max_output_tokens = top_provider.get("max_output_tokens")
            metadata = {
                key: entry.get(key)
                for key in ("description", "architecture", "display_name", "provider", "families", "tags")
                if entry.get(key) is not None
            }
            if top_provider:
                metadata.setdefault("top_provider", top_provider)
            models.append(
                ProviderModel(
                    provider=self.provider,
                    id=model_id,
                    name=name,
                    description=entry.get("description"),
                    context_window=context_window,
                    max_output_tokens=max_output_tokens,
                    pricing=pricing,
                    is_active=entry.get("status") or entry.get("enabled"),
                    metadata=metadata or None,
                )
            )
        return models


__all__ = ["OpenRouterProviderClient"]
