"""DeepSeek provider client implementation built on the OpenAI-compatible SDK."""

from __future__ import annotations

from typing import Mapping

import httpx

from app.core.config import Settings

from .openai import ClientFactory, OpenAIProviderClient


class DeepSeekProviderClient(OpenAIProviderClient):
    """Fetch models from DeepSeek using the OpenAI-compatible Python SDK."""

    provider = "deepseek"
    default_base_url = "https://api.deepseek.com"

    def __init__(
        self,
        settings: Settings,
        *,
        base_url: str | None = None,
        api_key: str | None = None,
        metadata: Mapping[str, object] | None = None,
        transport: httpx.AsyncBaseTransport | None = None,
        client_factory: ClientFactory | None = None,
    ) -> None:
        super().__init__(
            settings,
            base_url=base_url,
            api_key=api_key,
            metadata=metadata,
            transport=transport,
            client_factory=client_factory,
        )

    @property
    def base_url(self) -> str:
        if self._base_url_override:
            return self._base_url_override
        api_base = getattr(self._settings, "deepseek_api_base", None)
        return api_base or self.default_base_url

    def _get_api_key(self) -> str | None:
        if self._api_key_override:
            return self._api_key_override
        api_key = getattr(self._settings, "deepseek_api_key", None)
        if isinstance(api_key, str) and api_key.strip():
            return api_key.strip()
        return None

    def _additional_headers(self) -> dict[str, str]:  # type: ignore[override]
        # DeepSeek follows OpenAI's authentication model and does not require custom headers.
        return {}


__all__ = ["DeepSeekProviderClient"]
