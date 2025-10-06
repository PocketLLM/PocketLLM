"""Provider API key validation helpers."""

from __future__ import annotations

import logging
from typing import Any, Mapping

import httpx

from app.core.config import Settings

try:  # pragma: no cover - exercised in production environments
    from openai import AsyncOpenAI, OpenAIError
except Exception:  # pragma: no cover - defensive fallback when SDK missing
    AsyncOpenAI = None  # type: ignore[assignment]

    class OpenAIError(Exception):
        """Fallback OpenAI error."""


_GROQ_IMPORT_ERROR: Exception | None = None

try:  # pragma: no cover
    from groq import APIError as GroqAPIError, AsyncGroq
except Exception as exc:  # pragma: no cover
    AsyncGroq = None  # type: ignore[assignment]
    _GROQ_IMPORT_ERROR = exc

    class GroqAPIError(Exception):
        """Fallback Groq error."""


logger = logging.getLogger(__name__)


class APIKeyValidationService:
    """Validate provider API keys using their official SDKs when available."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def validate(
        self,
        provider: str,
        api_key: str,
        *,
        base_url: str | None = None,
        metadata: Mapping[str, Any] | None = None,
    ) -> None:
        provider_key = provider.lower()
        if provider_key == "openai":
            await self._validate_openai(api_key, base_url)
            return
        if provider_key == "groq":
            await self._validate_groq(api_key, base_url, metadata)
            return
        if provider_key == "openrouter":
            await self._validate_openrouter(api_key, base_url, metadata)
            return
        if provider_key == "imagerouter":
            await self._validate_imagerouter(api_key, base_url)
            return
        raise ValueError(f"Unsupported provider '{provider}'.")

    async def _validate_openai(self, api_key: str, base_url: str | None) -> None:
        if AsyncOpenAI is None:
            raise RuntimeError("The 'openai' package is required to validate OpenAI API keys.")
        client = AsyncOpenAI(api_key=api_key, base_url=base_url or "https://api.openai.com/v1")
        try:
            await client.models.list()
        except OpenAIError as exc:  # pragma: no cover - depends on SDK runtime
            raise ValueError(f"OpenAI API key validation failed: {exc}") from exc
        finally:
            await _close_client(client)

    async def _validate_groq(
        self,
        api_key: str,
        base_url: str | None,
        metadata: Mapping[str, Any] | None,
    ) -> None:
        if AsyncGroq is None:
            logger.warning(
                "Groq SDK not available%s; falling back to HTTP-based validation.",
                f" ({_GROQ_IMPORT_ERROR})" if _GROQ_IMPORT_ERROR else "",
            )
            await self._validate_groq_via_http(api_key, base_url, metadata)
            return
        kwargs: dict[str, Any] = {"api_key": api_key}
        sdk_base_url = _normalise_groq_sdk_base_url(base_url)
        if sdk_base_url:
            kwargs["base_url"] = sdk_base_url
        timeout = _coerce_positive_float(metadata.get("timeout")) if metadata else None
        if timeout is not None:
            kwargs["timeout"] = timeout
        retries = _coerce_non_negative_int(metadata.get("max_retries")) if metadata else None
        if retries is not None:
            kwargs["max_retries"] = retries
        client = AsyncGroq(**kwargs)
        try:
            await client.models.list()
        except GroqAPIError as exc:  # pragma: no cover
            raise ValueError(f"Groq API key validation failed: {exc}") from exc
        finally:
            await _close_client(client)

    async def _validate_groq_via_http(
        self,
        api_key: str,
        base_url: str | None,
        metadata: Mapping[str, Any] | None,
    ) -> None:
        timeout = _coerce_positive_float(metadata.get("timeout")) if metadata else None
        timeout = timeout or 10.0
        http_base_url = _normalise_groq_http_base_url(base_url)
        url = _join_url_path(http_base_url, "models")
        headers = {"Authorization": f"Bearer {api_key}", "Accept": "application/json"}
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.get(url, headers=headers)
        except httpx.HTTPError as exc:
            raise ValueError(f"Groq API key validation failed: {exc}") from exc
        if response.status_code != 200:
            raise ValueError(
                "Groq API key validation failed with status "
                f"{response.status_code}: {response.text.strip()}"
            )

    async def _validate_openrouter(
        self,
        api_key: str,
        base_url: str | None,
        metadata: Mapping[str, Any] | None,
    ) -> None:
        if AsyncOpenAI is None:
            raise RuntimeError("The 'openai' package is required to validate OpenRouter API keys.")

        kwargs: dict[str, Any] = {
            "api_key": api_key,
            "base_url": base_url or "https://openrouter.ai/api/v1",
        }
        headers: dict[str, str] = {}
        if metadata:
            referer = metadata.get("http_referer") or metadata.get("referer")
            title = metadata.get("x_title") or metadata.get("app_name")
            extra_headers = metadata.get("headers")
            if isinstance(extra_headers, Mapping):
                headers.update({str(k): str(v) for k, v in extra_headers.items()})
            if referer:
                headers.setdefault("HTTP-Referer", str(referer))
            if title:
                headers.setdefault("X-Title", str(title))
            for key in ("timeout", "max_retries"):
                value = metadata.get(key)
                if value is not None:
                    kwargs[key] = value
        if headers:
            kwargs["default_headers"] = headers

        client = AsyncOpenAI(**kwargs)
        try:
            await client.models.list()
        except OpenAIError as exc:  # pragma: no cover - depends on SDK runtime
            raise ValueError(f"OpenRouter API key validation failed: {exc}") from exc
        finally:
            await _close_client(client)

    async def _validate_imagerouter(self, api_key: str, base_url: str | None) -> None:
        url = (base_url or "https://api.imagerouter.io/v1/openai") + "/models"
        headers = {"Authorization": f"Bearer {api_key}", "Accept": "application/json"}
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url, headers=headers)
        if response.status_code != 200:
            raise ValueError(
                f"ImageRouter API key validation failed with status {response.status_code}: {response.text.strip()}"
            )


async def _close_client(client: Any) -> None:
    for attr in ("aclose", "close"):
        closer = getattr(client, attr, None)
        if callable(closer):
            result = closer()
            if hasattr(result, "__await__"):
                await result  # type: ignore[func-returns-value]
            return


__all__ = ["APIKeyValidationService"]


def _coerce_positive_float(value: Any) -> float | None:
    """Attempt to coerce ``value`` into a positive float."""

    if isinstance(value, (int, float)):
        coerced = float(value)
    elif isinstance(value, str):
        value = value.strip()
        if not value:
            return None
        try:
            coerced = float(value)
        except ValueError:
            return None
    else:
        return None
    return coerced if coerced > 0 else None


def _coerce_non_negative_int(value: Any) -> int | None:
    """Attempt to coerce ``value`` into a non-negative integer."""

    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value if value >= 0 else None
    if isinstance(value, float):
        if value.is_integer() and value >= 0:
            return int(value)
        return None
    if isinstance(value, str):
        value = value.strip()
        if not value:
            return None
        if value.isdigit():
            return int(value)
    return None


def _join_url_path(base: str, path: str) -> str:
    """Return ``base`` joined with ``path`` ensuring a single slash."""

    if not base:
        return path
    return base.rstrip("/") + "/" + path.lstrip("/")


def _normalise_groq_sdk_base_url(base_url: str | None) -> str | None:
    """Strip the ``/openai/v1`` suffix Groq adds for OpenAI compatibility."""

    if not base_url:
        return None
    trimmed = base_url.rstrip("/")
    suffix = "/openai/v1"
    if trimmed.lower().endswith(suffix):
        trimmed = trimmed[: -len(suffix)]
    return trimmed or base_url


def _normalise_groq_http_base_url(base_url: str | None) -> str:
    """Return a Groq base URL that always includes the OpenAI-compatible prefix."""

    base = (base_url or "https://api.groq.com").rstrip("/")
    suffix = "/openai/v1"
    if base.lower().endswith(suffix):
        return base
    return _join_url_path(base, suffix.lstrip("/"))

