"""Aggregation utilities for provider model catalogues."""

from __future__ import annotations

import asyncio
import logging
from collections.abc import Iterable, Sequence

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient
from .groq import GroqProviderClient
from .openai import OpenAIProviderClient
from .openrouter import OpenRouterProviderClient


class ProviderModelCatalogue:
    """Aggregate models across multiple provider clients."""

    def __init__(
        self,
        settings: Settings,
        *,
        clients: Iterable[ProviderClient] | None = None,
    ) -> None:
        self._settings = settings
        self._clients_override = list(clients) if clients is not None else None
        self._logger = logging.getLogger("app.services.providers.catalogue")

    async def list_all_models(self) -> list[ProviderModel]:
        """Return models from every configured provider."""

        clients = self._get_clients()
        return await self._gather_models(clients)

    async def list_models_for_provider(self, provider: str) -> list[ProviderModel]:
        """Return models for a single provider if supported."""

        provider_key = provider.lower()
        clients = [client for client in self._get_clients() if client.provider == provider_key]
        if not clients:
            self._logger.warning("Requested unsupported provider catalogue: %s", provider)
            return []
        return await self._gather_models(clients)

    def _get_clients(self) -> list[ProviderClient]:
        if self._clients_override is not None:
            return list(self._clients_override)
        return [
            OpenAIProviderClient(self._settings),
            GroqProviderClient(self._settings),
            OpenRouterProviderClient(self._settings),
        ]

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
