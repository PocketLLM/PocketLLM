"""Aggregation utilities for provider model catalogues."""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
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


@dataclass(frozen=True)
class _CacheEntry:
    expires_at: datetime
    models: list[ProviderModel]


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
        self._cache_ttl_seconds = self._coerce_ttl(
            getattr(settings, "provider_catalogue_cache_ttl", 60)
        )

    _cache: dict[str, "_CacheEntry"] = {}
    _locks: dict[str, asyncio.Lock] = {}

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
        if providers:
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

        for provider_name, fallback in self._build_fallback_configs().items():
            if provider_name in configs:
                continue
            configs[provider_name] = fallback
            self._logger.info(
                "Using environment fallback credentials for %s provider catalogue", provider_name
            )
        return configs

    def _build_fallback_configs(self) -> dict[str, _ProviderConfig]:
        fallbacks: dict[str, _ProviderConfig] = {}

        openai_key = getattr(self._settings, "openai_api_key", None)
        if isinstance(openai_key, str) and openai_key:
            fallbacks["openai"] = _ProviderConfig(
                provider="openai",
                base_url=getattr(self._settings, "openai_api_base", None),
                api_key=openai_key,
                metadata=None,
            )

        groq_key = getattr(self._settings, "groq_api_key", None)
        if isinstance(groq_key, str) and groq_key:
            fallbacks["groq"] = _ProviderConfig(
                provider="groq",
                base_url=getattr(self._settings, "groq_api_base", None),
                api_key=groq_key,
                metadata=None,
            )

        openrouter_key = getattr(self._settings, "openrouter_api_key", None)
        if isinstance(openrouter_key, str) and openrouter_key:
            metadata: dict[str, Any] = {}
            referer = getattr(self._settings, "openrouter_app_url", None)
            if isinstance(referer, str) and referer:
                metadata["http_referer"] = referer
            title = getattr(self._settings, "openrouter_app_name", None)
            if isinstance(title, str) and title:
                metadata["x_title"] = title
            fallbacks["openrouter"] = _ProviderConfig(
                provider="openrouter",
                base_url=getattr(self._settings, "openrouter_api_base", None),
                api_key=openrouter_key,
                metadata=metadata or None,
            )

        return fallbacks

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
        cache_key = self._build_cache_key(client)
        cached = self._cache_lookup(cache_key)
        if cached is not None:
            self._logger.debug(
                "Serving cached model catalogue for provider %s", client.provider
            )
            return cached

        lock = self._locks.setdefault(cache_key, asyncio.Lock())
        async with lock:
            cached = self._cache_lookup(cache_key)
            if cached is not None:
                self._logger.debug(
                    "Serving cached model catalogue for provider %s", client.provider
                )
                return cached
            try:
                models = await client.list_models()
            except Exception:  # pragma: no cover - defensive catch-all
                self._logger.exception(
                    "Failed to fetch models from provider %s", client.provider
                )
                models = []
            if not models:
                self._logger.info(
                    "Provider %s returned no models or is not configured", client.provider
                )
            self._store_cache(cache_key, models)
            return list(models)

    @classmethod
    def clear_cache(cls) -> None:
        """Reset the shared provider catalogue cache.

        Primarily intended for test environments to avoid state leakage across
        test cases.
        """

        cls._cache.clear()
        cls._locks.clear()

    def _cache_lookup(self, cache_key: str) -> list[ProviderModel] | None:
        if self._cache_ttl_seconds <= 0:
            return None
        entry = self._cache.get(cache_key)
        if entry is None:
            return None
        if entry.expires_at <= datetime.now(tz=timezone.utc):
            self._cache.pop(cache_key, None)
            return None
        return list(entry.models)

    def _store_cache(self, cache_key: str, models: list[ProviderModel]) -> None:
        if self._cache_ttl_seconds <= 0:
            return
        expires_at = datetime.now(tz=timezone.utc) + timedelta(
            seconds=self._cache_ttl_seconds
        )
        self._cache[cache_key] = _CacheEntry(expires_at=expires_at, models=list(models))

    def _build_cache_key(self, client: ProviderClient) -> str:
        provider = getattr(client, "provider", "unknown")
        base_url = getattr(client, "base_url", None)
        metadata = getattr(client, "metadata", None)
        api_key: str | None = None
        get_api_key = getattr(client, "_get_api_key", None)
        if callable(get_api_key):
            try:
                api_key = get_api_key()
            except Exception:  # pragma: no cover - defensive catch-all
                api_key = None

        components = [str(provider).lower()]
        if base_url:
            components.append(str(base_url))
        if api_key:
            components.append(self._hash_value(api_key))
        if metadata:
            components.append(self._hash_value(metadata))
        return "|".join(components)

    @staticmethod
    def _hash_value(value: Any) -> str:
        try:
            if isinstance(value, bytes):
                payload = value.decode("utf-8", "ignore")
            elif isinstance(value, str):
                payload = value
            else:
                payload = json.dumps(value, sort_keys=True, default=str)
        except Exception:  # pragma: no cover - defensive catch-all
            payload = str(value)
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    @staticmethod
    def _coerce_ttl(value: Any) -> int:
        try:
            ttl = int(value)
        except (TypeError, ValueError):  # pragma: no cover - defensive cast
            return 0
        return max(ttl, 0)


__all__ = ["ProviderModelCatalogue"]
