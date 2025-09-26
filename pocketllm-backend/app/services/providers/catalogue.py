"""Aggregation utilities for provider model catalogues."""

from __future__ import annotations

import asyncio
import logging
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from typing import Any

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient
from .groq import GroqProviderClient
from .openai import OpenAIProviderClient
from .openrouter import OpenRouterProviderClient


@dataclass(frozen=True)
class _ProviderConfig:
    provider: str
    base_url: str | None
    api_key: str | None
    metadata: Mapping[str, Any] | None


class ProviderModelCatalogue:
    """Aggregate models across multiple provider clients."""

    def __init__(
        self,
        settings: Settings,
        *,
        clients: Iterable[ProviderClient] | None = None,
        client_factories: Mapping[str, type[ProviderClient]] | None = None,
    ) -> None:
        self._settings = settings
        self._clients_override = list(clients) if clients is not None else None
        self._logger = logging.getLogger("app.services.providers.catalogue")
        self._client_factories: dict[str, type[ProviderClient]] = (
            dict(client_factories)
            if client_factories is not None
            else {
                "openai": OpenAIProviderClient,
                "groq": GroqProviderClient,
                "openrouter": OpenRouterProviderClient,
            }
        )

    async def list_all_models(
        self,
        providers: Sequence[object] | None = None,
    ) -> list[ProviderModel]:
        """Return models from every configured provider."""

        clients = self._get_clients(providers)
        return await self._gather_models(clients)

    async def list_models_for_provider(
        self,
        provider: str,
        providers: Sequence[object] | None = None,
    ) -> list[ProviderModel]:
        """Return models for a single provider if supported."""

        provider_key = provider.lower()
        if provider_key not in self._client_factories:
            self._logger.warning("Requested unsupported provider catalogue: %s", provider)
            return []
        clients = [
            client
            for client in self._get_clients(providers)
            if client.provider == provider_key
        ]
        if not clients:
            self._logger.warning("Provider %s is not configured for this user", provider)
            return []
        return await self._gather_models(clients)

    def _get_clients(self, providers: Sequence[object] | None) -> list[ProviderClient]:
        if self._clients_override is not None:
            return list(self._clients_override)
        configs = self._normalise_provider_configs(providers)
        clients: list[ProviderClient] = []
        for provider_name, config in configs.items():
            factory = self._client_factories.get(provider_name)
            if factory is None:
                continue
            clients.append(
                factory(
                    self._settings,
                    base_url=config.base_url,
                    api_key=config.api_key,
                    metadata=config.metadata,
                )
            )
        return clients

    def _normalise_provider_configs(
        self,
        providers: Sequence[object] | None,
    ) -> dict[str, _ProviderConfig]:
        configs: dict[str, _ProviderConfig] = {}
        if not providers:
            return configs

        for item in providers:
            provider = getattr(item, "provider", None)
            if not provider:
                continue
            is_active = bool(getattr(item, "is_active", False))
            if not is_active:
                continue
            provider_key = str(provider).lower()
            base_url = getattr(item, "base_url", None)
            metadata_obj = getattr(item, "metadata", None)
            metadata: Mapping[str, Any] | None = None
            if isinstance(metadata_obj, Mapping):
                metadata = metadata_obj
            api_key: str | None = None
            if metadata:
                candidate = metadata.get("api_key") or metadata.get("token")
                if isinstance(candidate, str) and candidate:
                    api_key = candidate
            configs[provider_key] = _ProviderConfig(
                provider=provider_key,
                base_url=base_url,
                api_key=api_key,
                metadata=metadata,
            )
        return configs

    async def _gather_models(self, clients: Sequence[ProviderClient]) -> list[ProviderModel]:
        if not clients:
            return []
        tasks = [self._safe_list_models(client) for client in clients]
        results = await asyncio.gather(*tasks)
        models: list[ProviderModel] = []
        for provider_models in results:
            models.extend(provider_models)
        return models

    async def _safe_list_models(self, client: ProviderClient) -> list[ProviderModel]:
        try:
            models = await client.list_models()
        except Exception:  # pragma: no cover - defensive catch-all
            self._logger.exception("Failed to fetch models from provider %s", client.provider)
            return []
        if not models:
            self._logger.info("Provider %s returned no models or is not configured", client.provider)
        return models


__all__ = ["ProviderModelCatalogue"]
