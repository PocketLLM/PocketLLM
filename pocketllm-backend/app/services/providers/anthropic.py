"""Anthropic provider client implementation backed by the official SDK."""

from __future__ import annotations

import inspect
from collections.abc import Iterable, Mapping, Sequence
from contextlib import asynccontextmanager
from typing import Any, Callable

import httpx

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient

try:  # pragma: no cover - exercised in production environments
    from anthropic import AsyncAnthropic
except Exception:  # pragma: no cover - defensive fallback for environments without the SDK
    AsyncAnthropic = None  # type: ignore[assignment]

try:  # pragma: no cover - exercised in production environments
    from anthropic import APIError as AnthropicAPIError
except Exception:  # pragma: no cover - compatibility with alternate SDK versions
    try:  # pragma: no cover - alternate error type
        from anthropic import AnthropicError as AnthropicAPIError  # type: ignore
    except Exception:  # pragma: no cover - defensive fallback
        class AnthropicAPIError(Exception):
            """Fallback error raised when the Anthropic SDK is unavailable."""


ClientFactory = Callable[..., Any]


def _default_client_factory(**kwargs: Any) -> Any:
    if AsyncAnthropic is None:
        raise RuntimeError(
            "The 'anthropic' package is required to use the Anthropic provider client. Install it via 'pip install anthropic'."
        )
    return AsyncAnthropic(**kwargs)


async def _close_client(client: Any) -> None:
    for attr in ("aclose", "close"):
        close_callable = getattr(client, attr, None)
        if callable(close_callable):
            result = close_callable()
            if inspect.isawaitable(result):
                await result
            return


@asynccontextmanager
async def _client_context(factory: ClientFactory, **kwargs: Any):
    client = factory(**kwargs)
    aenter = getattr(client, "__aenter__", None)
    if callable(aenter):
        try:
            entered = aenter()
            if inspect.isawaitable(entered):
                entered = await entered
            yield entered
        finally:
            aexit = getattr(client, "__aexit__", None)
            if callable(aexit):
                exit_result = aexit(None, None, None)
                if inspect.isawaitable(exit_result):
                    await exit_result
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
        for key in ("max_retries", "timeout", "anthropic_version", "beta"):
            value = metadata.get(key)
            if value is not None:
                kwargs[key] = value
    return kwargs


async def _invoke_models_list(client: Any) -> Any:
    models_service = getattr(client, "models", None)
    if models_service is None:
        raise RuntimeError("Anthropic client does not expose a models service")
    list_callable = getattr(models_service, "list", None)
    if not callable(list_callable):
        raise RuntimeError("Anthropic client does not provide a list method for models")
    result = list_callable()
    if inspect.isawaitable(result):
        return await result
    return result


class AnthropicProviderClient(ProviderClient):
    """Fetch models from Anthropic using the official Python SDK."""

    provider = "anthropic"
    default_base_url = "https://api.anthropic.com"

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
        api_base = getattr(self._settings, "anthropic_api_base", None)
        return api_base or self.default_base_url

    def _get_api_key(self) -> str | None:
        if self._api_key_override:
            return self._api_key_override
        api_key = getattr(self._settings, "anthropic_api_key", None)
        if isinstance(api_key, str) and api_key.strip():
            return api_key.strip()
        return None

    async def list_models(self) -> list[ProviderModel]:
        if AsyncAnthropic is None and self._client_factory is _default_client_factory:
            self._logger.error(
                "Anthropic SDK is not installed; cannot list models. Install it via 'pip install anthropic'."
            )
            return []

        api_key = self._get_api_key()
        if self.requires_api_key and not api_key:
            self._logger.warning("Skipping %s provider because credentials are not configured", self.provider)
            return []

        client_kwargs = _build_client_kwargs(api_key, self.base_url, self.metadata)
        try:
            async with _client_context(self._client_factory, **client_kwargs) as client:
                payload = await _invoke_models_list(client)
        except AnthropicAPIError as exc:  # pragma: no cover - depends on SDK runtime
            self._logger.error("Anthropic SDK request failed: %s", exc)
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
            name = mapping.get("display_name") or mapping.get("name") or model_id
            metadata_keys = (
                "type",
                "display_name",
                "context_window",
                "max_context_length",
                "input_token_limit",
                "output_token_limit",
                "default_voice",
                "default_tool",
                "default_prompt_template",
                "aliases",
                "beta",
                "status",
            )
            metadata = {key: mapping.get(key) for key in metadata_keys if mapping.get(key) is not None}
            pricing = mapping.get("pricing") or mapping.get("price")
            if isinstance(pricing, Mapping):
                pricing_data: dict[str, Any] | None = dict(pricing)
            else:
                pricing_data = None
            context_window = self._coerce_int(
                mapping.get("context_window")
                or mapping.get("context_length")
                or mapping.get("max_context_length")
                or mapping.get("input_token_limit")
            )
            max_output_tokens = self._coerce_int(
                mapping.get("max_output_tokens")
                or mapping.get("output_token_limit")
                or mapping.get("default_max_output_tokens")
            )
            status = mapping.get("status")
            is_active: bool | None = None
            if isinstance(status, str):
                is_active = status.lower() in {"active", "available", "enabled"}
            elif isinstance(mapping.get("active"), bool):
                is_active = bool(mapping.get("active"))

            models.append(
                ProviderModel(
                    provider=self.provider,
                    id=str(model_id),
                    name=str(name),
                    description=mapping.get("description") or mapping.get("display_name"),
                    context_window=context_window,
                    max_output_tokens=max_output_tokens,
                    pricing=pricing_data,
                    is_active=is_active,
                    metadata=metadata or None,
                )
            )
        return models

    def _additional_headers(self) -> dict[str, str]:
        headers: dict[str, str] = {}
        metadata_source = self.metadata
        if isinstance(metadata_source, Mapping):
            version = metadata_source.get("anthropic-version") or metadata_source.get("anthropic_version")
            if version:
                headers["anthropic-version"] = str(version)
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
                "display_name",
                "description",
                "context_window",
                "context_length",
                "max_context_length",
                "input_token_limit",
                "output_token_limit",
                "max_output_tokens",
                "default_max_output_tokens",
                "pricing",
                "price",
                "status",
                "active",
                "aliases",
                "type",
                "beta",
                "default_voice",
                "default_tool",
                "default_prompt_template",
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


__all__ = ["AnthropicProviderClient"]
