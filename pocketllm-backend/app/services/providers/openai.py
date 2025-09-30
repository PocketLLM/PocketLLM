"""OpenAI provider client implementation backed by the official SDK."""

from __future__ import annotations

import inspect
from collections.abc import AsyncIterator, Iterable, Mapping, Sequence
from contextlib import asynccontextmanager
from typing import Any, Callable

import httpx

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient

try:  # pragma: no cover - exercised in production environments
    from openai import AsyncOpenAI
except Exception:  # pragma: no cover - defensive fallback for environments without the SDK
    AsyncOpenAI = None  # type: ignore[assignment]

try:  # pragma: no cover - exercised in production environments
    from openai import OpenAIError
except Exception:  # pragma: no cover - defensive fallback
    class OpenAIError(Exception):
        """Fallback error when the OpenAI SDK is unavailable."""


ClientFactory = Callable[..., Any]


def _default_client_factory(**kwargs: Any) -> Any:
    if AsyncOpenAI is None:
        raise RuntimeError(
            "The 'openai' package is required to use the OpenAI provider client. Install it via 'pip install openai'."
        )
    return AsyncOpenAI(**kwargs)


async def _close_client(client: Any) -> None:
    for attr in ("aclose", "close"):
        close_callable = getattr(client, attr, None)
        if callable(close_callable):
            result = close_callable()
            if inspect.isawaitable(result):
                await result
            return


@asynccontextmanager
async def _client_context(factory: ClientFactory, **kwargs: Any) -> AsyncIterator[Any]:
    client = factory(**kwargs)
    aenter = getattr(client, "__aenter__", None)
    if callable(aenter):
        try:
            yielded = await aenter()
            yield yielded
        finally:
            aexit = getattr(client, "__aexit__", None)
            if callable(aexit):
                await aexit(None, None, None)
    else:
        try:
            yield client
        finally:
            await _close_client(client)


def _build_client_kwargs(
    api_key: str | None,
    base_url: str | None,
    metadata: Mapping[str, Any] | None,
) -> dict[str, Any]:
    kwargs: dict[str, Any] = {}
    if api_key:
        kwargs["api_key"] = api_key
    if base_url:
        kwargs["base_url"] = base_url
    if metadata:
        for key in ("organization", "project", "timeout", "max_retries"):
            value = metadata.get(key)
            if value is not None:
                kwargs[key] = value
    return kwargs


class OpenAIProviderClient(ProviderClient):
    """Fetch models from OpenAI using the official Python SDK."""

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
        client_factory: ClientFactory | None = None,
    ) -> None:
        super().__init__(
            settings,
            base_url=base_url,
            api_key=api_key,
            metadata=metadata,
            transport=transport,
        )
        self._client_factory: ClientFactory = client_factory or _default_client_factory

    @property
    def base_url(self) -> str:
        if self._base_url_override:
            return self._base_url_override
        api_base = getattr(self._settings, "openai_api_base", None)
        return api_base or self.default_base_url

    async def list_models(self) -> list[ProviderModel]:
        if AsyncOpenAI is None and self._client_factory is _default_client_factory:
            self._logger.error(
                "OpenAI SDK is not installed; cannot list models. Install it via 'pip install openai'."
            )
            return []

        api_key = self._get_api_key()
        if self.requires_api_key and not api_key:
            self._logger.warning("Skipping %s provider because credentials are not configured", self.provider)
            return []

        client_kwargs = _build_client_kwargs(api_key, self.base_url, self.metadata)
        try:
            async with _client_context(self._client_factory, **client_kwargs) as client:
                payload = await client.models.list()
        except OpenAIError as exc:  # pragma: no cover - depends on SDK runtime
            self._logger.error("OpenAI SDK request failed: %s", exc)
            return []
        except Exception:  # pragma: no cover - defensive catch-all
            self._logger.exception("Unexpected error while fetching models from %s", self.provider)
            return []
        return self._parse_models(payload)

    async def list_models(self) -> list[ProviderModel]:
        if AsyncOpenAI is None and self._client_factory is _default_client_factory:
            self._logger.error(
                "OpenAI SDK is not installed; cannot list models. Install it via 'pip install openai'."
            )
            return []

        api_key = self._get_api_key()
        if self.requires_api_key and not api_key:
            self._logger.warning("Skipping %s provider because credentials are not configured", self.provider)
            return []

        client_kwargs = _build_client_kwargs(api_key, self.base_url, self.metadata)
        try:
            async with _client_context(self._client_factory, **client_kwargs) as client:
                payload = await client.models.list()
        except OpenAIError as exc:  # pragma: no cover - depends on SDK runtime
            self._logger.error("OpenAI SDK request failed: %s", exc)
            return []
        except Exception:  # pragma: no cover - defensive catch-all
            self._logger.exception("Unexpected error while fetching models from %s", self.provider)
            return []
        return self._parse_models(payload)

    def _parse_models(self, payload: Any) -> list[ProviderModel]:
        data_iterable = self._extract_model_entries(payload)
        models: list[ProviderModel] = []
        for entry in data_iterable:
            mapping = self._normalise_entry(entry)
            if not mapping:
                continue
            model_id = mapping.get("id")
            if not model_id:
                continue
            name = mapping.get("name") or model_id
            metadata_keys = ("object", "created", "owned_by", "permission")
            metadata = {key: mapping.get(key) for key in metadata_keys if mapping.get(key) is not None}
            models.append(
                ProviderModel(
                    provider=self.provider,
                    id=model_id,
                    name=name,
                    description=mapping.get("description"),
                    context_window=self._coerce_int(
                        mapping.get("context_window") or mapping.get("context_length")
                    ),
                    max_output_tokens=self._coerce_int(
                        mapping.get("max_output_tokens") or mapping.get("max_tokens")
                    ),
                    pricing=mapping.get("pricing"),
                    is_active=mapping.get("status"),
                    metadata=metadata or None,
                )
            )
        return models

    def _additional_headers(self) -> dict[str, str]:
        headers: dict[str, str] = {}
        metadata_source = self.metadata
        metadata = metadata_source if isinstance(metadata_source, Mapping) else {}
        organization = metadata.get("organization")
        project = metadata.get("project")
        if organization:
            headers["OpenAI-Organization"] = str(organization)
        if project:
            headers["OpenAI-Project"] = str(project)
        return headers

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
        keys_of_interest = {
            key: getattr(entry, key)
            for key in (
                "id",
                "name",
                "description",
                "context_window",
                "context_length",
                "max_output_tokens",
                "max_tokens",
                "pricing",
                "status",
                "object",
                "created",
                "owned_by",
                "permission",
            )
            if hasattr(entry, key)
        }
        return {key: value for key, value in keys_of_interest.items() if value is not None}

    @staticmethod
    def _coerce_int(value: Any) -> int | None:
        try:
            if value is None:
                return None
            return int(value)
        except (TypeError, ValueError):  # pragma: no cover - defensive cast
            return None


__all__ = ["OpenAIProviderClient"]
