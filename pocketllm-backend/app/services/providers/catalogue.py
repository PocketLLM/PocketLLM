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
from .imagerouter import ImageRouterProviderClient
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
    """Aggregate models across multiple provider clients with concurrency safeguards."""

    PROVIDER_TIMEOUT = 12.0
    TOTAL_TIMEOUT = 30.0

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
                "imagerouter": ImageRouterProviderClient,
            }
        )
        self._cache_ttl_seconds = self._coerce_ttl(
            getattr(settings, "provider_catalogue_cache_ttl", 300)
        )
        self._provider_timeout = self._coerce_timeout(
            getattr(settings, "provider_catalogue_provider_timeout", self.PROVIDER_TIMEOUT),
            self.PROVIDER_TIMEOUT,
        )
        self._total_timeout = self._coerce_timeout(
            getattr(settings, "provider_catalogue_total_timeout", self.TOTAL_TIMEOUT),
            self.TOTAL_TIMEOUT,
        )

        if 0 < self._total_timeout < self._provider_timeout:
            self._logger.warning(
                "Total timeout %.2fs is smaller than provider timeout %.2fs; clamping provider timeout.",
                self._total_timeout,
                self._provider_timeout,
            )
            self._provider_timeout = self._total_timeout

    _cache: dict[str, "_CacheEntry"] = {}
    _locks: dict[str, asyncio.Lock] = {}

    async def list_all_models(
        self,
        providers: Sequence[object] | None = None,
    ) -> list[ProviderModel]:
        """Return models from every configured provider."""

        clients = self._get_clients(providers)
        if not clients:
            self._logger.warning("No provider clients available for catalogue lookup")
            return []

        try:
            return await asyncio.wait_for(
                self._gather_models_concurrent(clients),
                timeout=self._total_timeout if self._total_timeout > 0 else None,
            )
        except asyncio.TimeoutError:
            self._logger.error(
                "Provider catalogue fetch exceeded %.2fs timeout; returning partial results.",
                self._total_timeout,
            )
            return []

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

        try:
            return await asyncio.wait_for(
                self._gather_models_concurrent(clients),
                timeout=self._provider_timeout if self._provider_timeout > 0 else None,
            )
        except asyncio.TimeoutError:
            self._logger.error(
                "Provider %s catalogue fetch exceeded %.2fs timeout", provider, self._provider_timeout
            )
            return []

    def _get_clients(self, providers: Sequence[object] | None) -> list[ProviderClient]:
        if self._clients_override is not None:
            return list(self._clients_override)
        configs = self._normalise_provider_configs(providers)
        clients: list[ProviderClient] = []
        for provider_name, config in configs.items():
            factory = self._client_factories.get(provider_name)
            if factory is None:
                continue
            metadata = dict(config.metadata or {})
            metadata.setdefault("timeout", self._provider_timeout)
            clients.append(
                factory(
                    self._settings,
                    base_url=config.base_url,
                    api_key=config.api_key,
                    metadata=metadata,
                )
            )
        return clients

    def _normalise_provider_configs(
        self,
        providers: Sequence[object] | None,
    ) -> dict[str, _ProviderConfig]:
        if not providers:
            return self._build_fallback_configs()

        configs: dict[str, _ProviderConfig] = {}

        for item in providers:
            provider = getattr(item, "provider", None)
            if not provider:
                continue

            provider_key = str(provider).lower()
            factory = self._client_factories.get(provider_key)
            if factory is None and self._clients_override is None:
                self._logger.debug(
                    "Skipping unsupported provider configuration %s", provider_key
                )
                continue

            is_active = bool(getattr(item, "is_active", False))
            if not is_active:
                self._logger.debug(
                    "Skipping provider %s because it is inactive", provider_key
                )
                continue

            requires_api_key = self.provider_requires_api_key(provider_key)

            base_url = getattr(item, "base_url", None)
            metadata_obj = getattr(item, "metadata", None)
            metadata: Mapping[str, Any] | None = None
            if isinstance(metadata_obj, Mapping):
                metadata = metadata_obj

            api_key: str | None = None
            direct_key = getattr(item, "api_key", None)
            if isinstance(direct_key, str) and direct_key.strip():
                api_key = direct_key.strip()
            elif metadata:
                candidate = metadata.get("api_key") or metadata.get("token")
                if isinstance(candidate, str) and candidate.strip():
                    api_key = candidate.strip()

            if api_key is None and requires_api_key:
                self._logger.warning(
                    "Provider %s has no configured API key; user configuration is required to fetch models",
                    provider_key,
                )
                continue

            configs[provider_key] = _ProviderConfig(
                provider=provider_key,
                base_url=base_url,
                api_key=api_key,
                metadata=metadata,
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

        imagerouter_key = getattr(self._settings, "imagerouter_api_key", None)
        cleaned_imagerouter_key: str | None = None
        if isinstance(imagerouter_key, str):
            stripped = imagerouter_key.strip()
            if stripped:
                cleaned_imagerouter_key = stripped

        fallbacks["imagerouter"] = _ProviderConfig(
            provider="imagerouter",
            base_url=getattr(self._settings, "imagerouter_api_base", None),
            api_key=cleaned_imagerouter_key,
            metadata=None,
        )

        return fallbacks

    async def _gather_models_concurrent(self, clients: Sequence[ProviderClient]) -> list[ProviderModel]:
        if not clients:
            return []

        tasks = [
            self._fetch_with_timeout(client, self._resolve_client_timeout(client))
            for client in clients
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        models: list[ProviderModel] = []
        for index, result in enumerate(results):
            if isinstance(result, Exception):
                client = clients[index]
                self._logger.error(
                    "Provider %s fetch failed with unexpected exception: %s",
                    getattr(client, "provider", "unknown"),
                    result,
                )
                continue
            models.extend(result)
        return models

    async def _fetch_with_timeout(
        self,
        client: ProviderClient,
        timeout: float,
    ) -> list[ProviderModel]:
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
                models = await asyncio.wait_for(
                    client.list_models(),
                    timeout=timeout if timeout > 0 else None,
                )
            except asyncio.TimeoutError:
                self._logger.error(
                    "Provider %s exceeded %.2fs timeout when fetching catalogue",
                    client.provider,
                    timeout,
                )
                models = []
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

    def _resolve_client_timeout(self, client: ProviderClient) -> float:
        metadata = getattr(client, "metadata", None)
        if isinstance(metadata, Mapping):
            candidate = metadata.get("timeout")
            try:
                if candidate is not None:
                    value = float(candidate)
                    return value if value > 0 else self._provider_timeout
            except (TypeError, ValueError):
                self._logger.debug(
                    "Ignoring invalid timeout override %r for provider %s",
                    candidate,
                    client.provider,
                )
        timeout = getattr(client, "timeout", None)
        if isinstance(timeout, (int, float)) and timeout > 0:
            return float(timeout)
        return self._provider_timeout

    def provider_requires_api_key(self, provider: str) -> bool:
        """Return True when the provider client mandates an API key."""

        provider_key = str(provider).lower()

        if self._clients_override is not None:
            for client in self._clients_override:
                if getattr(client, "provider", "").lower() == provider_key:
                    return getattr(client, "requires_api_key", True)

        factory = self._client_factories.get(provider_key)
        if factory is None:
            return True

        return getattr(factory, "requires_api_key", True)

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

    @staticmethod
    def _coerce_timeout(value: Any, default: float) -> float:
        try:
            timeout = float(value)
        except (TypeError, ValueError):
            return default
        return timeout if timeout > 0 else default


__all__ = ["ProviderModelCatalogue"]
