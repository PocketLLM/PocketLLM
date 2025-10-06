"""Groq provider client implementation backed by the official SDK."""

from __future__ import annotations

import inspect
import logging
from collections.abc import AsyncIterator, Iterable, Mapping, Sequence
from contextlib import asynccontextmanager
from typing import Any, Callable

import httpx

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient

try:  # pragma: no cover - exercised in production environments
    from groq import APIError as GroqAPIError, AsyncGroq
except Exception:  # pragma: no cover - defensive fallback for test environments
    AsyncGroq = None  # type: ignore[assignment]

    class GroqAPIError(Exception):
        """Fallback error type when the Groq SDK is unavailable."""


ClientFactory = Callable[..., Any]


def _default_client_factory(**kwargs: Any) -> Any:
    if AsyncGroq is None:
        raise RuntimeError(
            "The 'groq' package is required to use the Groq provider client. Install it via 'pip install groq'."
        )
    return AsyncGroq(**kwargs)


async def _close_client(client: Any) -> None:
    """Attempt to close the underlying Groq SDK client gracefully."""

    for attr in ("aclose", "close"):
        close_callable = getattr(client, attr, None)
        if callable(close_callable):
            result = close_callable()
            if inspect.isawaitable(result):
                await result
            return


@asynccontextmanager
async def _client_context(factory: ClientFactory, **kwargs: Any) -> AsyncIterator[Any]:
    """Yield a Groq SDK client, ensuring resources are closed afterwards."""

    client = factory(**kwargs)
    aenter = getattr(client, "__aenter__", None)
    if aenter is not None and callable(aenter):
        try:
            yielded = await aenter()
            yield yielded
        finally:
            aexit = getattr(client, "__aexit__", None)
            if aexit is not None and callable(aexit):
                await aexit(None, None, None)
    else:
        try:
            yield client
        finally:
            await _close_client(client)


def _normalise_base_url(base_url: str | None) -> str | None:
    """Strip the OpenAI compatibility suffix Groq adds at the HTTP layer."""

    if not base_url:
        return None
    trimmed = base_url.rstrip("/")
    suffix = "/openai/v1"
    if trimmed.lower().endswith(suffix):
        trimmed = trimmed[: -len(suffix)]
    return trimmed or base_url


def _build_client_kwargs(
    api_key: str | None,
    base_url: str | None,
    metadata: Mapping[str, Any] | None,
) -> dict[str, Any]:
    kwargs: dict[str, Any] = {}
    if api_key:
        kwargs["api_key"] = api_key
    normalised_base = _normalise_base_url(base_url)
    if normalised_base:
        kwargs["base_url"] = normalised_base
    if metadata:
        for key in ("timeout", "max_retries"):
            value = metadata.get(key)
            if value is not None:
                kwargs[key] = value
    return kwargs


class GroqProviderClient(ProviderClient):
    """Fetch available models from Groq Cloud using the official SDK."""

    provider = "groq"
    default_base_url = "https://api.groq.com"

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
        api_base = getattr(self._settings, "groq_api_base", None)
        return api_base or self.default_base_url

    async def list_models(self) -> list[ProviderModel]:
        if AsyncGroq is None and self._client_factory is _default_client_factory:
            self._logger.error(
                "Groq SDK is not installed; cannot list models. Install it via 'pip install groq'."
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
        except GroqAPIError as exc:  # pragma: no cover - depends on SDK error types
            self._logger.error("Groq SDK request failed: %s", exc)
            return []
        except Exception:  # pragma: no cover - defensive catch-all
            self._logger.exception("Unexpected error while fetching models from %s", self.provider)
            return []
        return self._parse_models(payload)

    async def list_models(self) -> list[ProviderModel]:
        if AsyncGroq is None and self._client_factory is _default_client_factory:
            self._logger.error(
                "Groq SDK is not installed; cannot list models. Install it via 'pip install groq'."
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
        except GroqAPIError as exc:  # pragma: no cover - depends on SDK error types
            self._logger.error("Groq SDK request failed: %s", exc)
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
            metadata_keys = (
                "type",
                "owned_by",
                "permissions",
                "support_disclaimer",
                "capabilities",
            )
            metadata = {key: mapping.get(key) for key in metadata_keys if mapping.get(key) is not None}
            models.append(
                ProviderModel(
                    provider=self.provider,
                    id=model_id,
                    name=name,
                    description=mapping.get("description"),
                    context_window=self._coerce_int(mapping.get("context_window") or mapping.get("context_length")),
                    max_output_tokens=self._coerce_int(mapping.get("max_output_tokens") or mapping.get("max_tokens")),
                    pricing=mapping.get("pricing"),
                    is_active=mapping.get("active") or mapping.get("status"),
                    metadata=metadata or None,
                )
            )
        return models

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
                "active",
                "status",
                "type",
                "owned_by",
                "permissions",
                "support_disclaimer",
                "capabilities",
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


class GroqSDKService:
    """High-level Groq helpers for chat, responses, and audio workflows."""

    def __init__(
        self,
        settings: Settings,
        *,
        api_key: str | None = None,
        base_url: str | None = None,
        metadata: Mapping[str, Any] | None = None,
        client_factory: ClientFactory | None = None,
    ) -> None:
        self._settings = settings
        self._api_key_override = api_key
        self._base_url_override = base_url
        self._metadata: Mapping[str, Any] | None = metadata
        self._client_factory: ClientFactory = client_factory or _default_client_factory
        self._logger = logging.getLogger("app.services.providers.groq.sdk")

    @property
    def base_url(self) -> str:
        if self._base_url_override:
            return self._base_url_override
        api_base = getattr(self._settings, "groq_api_base", None)
        return api_base or GroqProviderClient.default_base_url

    def _get_api_key(self) -> str | None:
        return self._api_key_override

    @asynccontextmanager
    async def _client(self) -> AsyncIterator[Any]:
        api_key = self._get_api_key()
        if not api_key:
            raise RuntimeError("Groq API key is not configured.")
        kwargs = _build_client_kwargs(api_key, self.base_url, self._metadata)
        async with _client_context(self._client_factory, **kwargs) as client:
            yield client

    async def create_chat_completion(
        self,
        *,
        model: str,
        messages: Sequence[Mapping[str, Any]],
        **kwargs: Any,
    ) -> Any:
        self._logger.debug("Creating Groq chat completion", extra={"model": model})
        async with self._client() as client:
            try:
                return await client.chat.completions.create(model=model, messages=list(messages), **kwargs)
            except GroqAPIError as exc:  # pragma: no cover - depends on SDK runtime
                self._logger.error("Groq chat completion failed: %s", exc)
                raise

    def stream_chat_completion(
        self,
        *,
        model: str,
        messages: Sequence[Mapping[str, Any]],
        **kwargs: Any,
    ) -> AsyncIterator[Any]:
        async def _stream() -> AsyncIterator[Any]:
            stream_kwargs = dict(kwargs)
            stream_kwargs["stream"] = True
            async with self._client() as client:
                try:
                    stream = await client.chat.completions.create(
                        model=model,
                        messages=list(messages),
                        **stream_kwargs,
                    )
                except GroqAPIError as exc:  # pragma: no cover - depends on SDK runtime
                    self._logger.error("Groq chat completion stream failed: %s", exc)
                    raise
                async for chunk in stream:
                    yield chunk

        return _stream()

    async def create_response(self, **kwargs: Any) -> Any:
        model = kwargs.get("model")
        self._logger.debug("Creating Groq response", extra={"model": model})
        async with self._client() as client:
            try:
                return await client.responses.create(**kwargs)
            except GroqAPIError as exc:  # pragma: no cover
                self._logger.error("Groq response request failed: %s", exc)
                raise

    async def transcribe_audio(self, *, file: Any, model: str, **kwargs: Any) -> Any:
        self._logger.debug("Submitting Groq audio transcription", extra={"model": model})
        async with self._client() as client:
            try:
                return await client.audio.transcriptions.create(file=file, model=model, **kwargs)
            except GroqAPIError as exc:  # pragma: no cover
                self._logger.error("Groq transcription failed: %s", exc)
                raise

    async def translate_audio(self, *, file: Any, model: str, **kwargs: Any) -> Any:
        self._logger.debug("Submitting Groq audio translation", extra={"model": model})
        async with self._client() as client:
            try:
                return await client.audio.translations.create(file=file, model=model, **kwargs)
            except GroqAPIError as exc:  # pragma: no cover
                self._logger.error("Groq translation failed: %s", exc)
                raise

    async def synthesize_speech(self, *, input_text: str, model: str, voice: str, **kwargs: Any) -> Any:
        payload = {"model": model, "voice": voice, "input": input_text}
        payload.update(kwargs)
        self._logger.debug("Creating Groq speech synthesis", extra={"model": model, "voice": voice})
        async with self._client() as client:
            try:
                return await client.audio.speech.create(**payload)
            except GroqAPIError as exc:  # pragma: no cover
                self._logger.error("Groq speech synthesis failed: %s", exc)
                raise


__all__ = ["GroqProviderClient", "GroqSDKService"]
