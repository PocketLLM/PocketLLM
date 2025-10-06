"""Base classes for provider model catalogue clients."""

from __future__ import annotations

import json
import logging
from abc import ABC, abstractmethod
from typing import Any, Mapping

import httpx

from app.core.config import Settings
from app.schemas.providers import ProviderModel


class ProviderClient(ABC):
    """Abstract base class for provider specific client integrations."""

    provider: str
    default_base_url: str
    models_endpoint: str = "/models"
    timeout: float = 15.0
    requires_api_key: bool = True

    def __init__(
        self,
        settings: Settings,
        *,
        base_url: str | None = None,
        api_key: str | None = None,
        metadata: Mapping[str, Any] | None = None,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self._settings = settings
        self._transport = transport
        self._logger = logging.getLogger(f"app.services.providers.{self.provider}")
        self._base_url_override = base_url
        self._api_key_override = api_key
        self._metadata: dict[str, Any] = dict(metadata or {})

        timeout_override = self._metadata.get("timeout")
        try:
            if timeout_override is not None:
                timeout_value = float(timeout_override)
                if timeout_value > 0:
                    self.timeout = timeout_value
        except (TypeError, ValueError):
            self._logger.debug(
                "Ignoring invalid timeout override %r for provider %s",
                timeout_override,
                self.provider,
            )

    @property
    def base_url(self) -> str:
        """Return the base URL for the provider API."""

        return self._base_url_override or self.default_base_url

    @property
    def metadata(self) -> Mapping[str, Any]:
        """Return metadata associated with the provider configuration."""

        return self._metadata

    def _build_headers(self) -> dict[str, str] | None:
        """Return HTTP headers for the provider request."""

        api_key = self._get_api_key()
        if self.requires_api_key and not api_key:
            return None
        headers: dict[str, str] = {"Accept": "application/json"}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        headers.update(self._additional_headers())
        return headers

    async def list_models(self) -> list[ProviderModel]:
        """Return the list of models provided by the provider."""

        headers = self._build_headers()
        if headers is None:
            self._logger.warning("Skipping %s provider because credentials are not configured", self.provider)
            return []

        try:
            payload = await self._fetch_payload(headers)
        except httpx.HTTPStatusError as exc:
            self._logger.error(
                "Provider %s responded with HTTP %s: %s",
                self.provider,
                exc.response.status_code,
                exc.response.text,
            )
            return []
        except httpx.HTTPError as exc:
            self._logger.error("Provider %s request failed: %s", self.provider, exc)
            return []
        except Exception:  # pragma: no cover - defensive catch-all
            self._logger.exception("Unexpected error while fetching models from %s", self.provider)
            return []

        try:
            models = self._parse_models(payload)
        except Exception:  # pragma: no cover - defensive catch-all
            self._logger.exception("Failed to parse model catalogue response from %s", self.provider)
            return []
        return models

    async def _fetch_payload(self, headers: dict[str, str]) -> Any:
        """Execute the HTTP request and return the response payload."""

        async with httpx.AsyncClient(
            base_url=self.base_url,
            headers=headers,
            timeout=self.timeout,
            transport=self._transport,
        ) as client:
            response = await client.get(self.models_endpoint)
            response.raise_for_status()
            if response.headers.get("content-type", "").startswith("application/json"):
                return response.json()
            return json.loads(response.text)

    def _additional_headers(self) -> dict[str, str]:
        """Return additional provider specific headers."""

        return {}

    def _get_api_key(self) -> str | None:
        """Return the provider API key if configured."""

        return self._api_key_override

    @abstractmethod
    def _parse_models(self, payload: Any) -> list[ProviderModel]:
        """Convert the provider response payload into provider models."""


__all__ = ["ProviderClient"]
