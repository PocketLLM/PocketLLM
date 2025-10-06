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


try:  # pragma: no cover
    from groq import AsyncGroq
    from groq.errors import GroqError
except Exception:  # pragma: no cover
    AsyncGroq = None  # type: ignore[assignment]

    class GroqError(Exception):
        """Fallback Groq error."""


try:  # pragma: no cover
    from openrouter import AsyncOpenRouter, OpenRouterError
except Exception:  # pragma: no cover
    AsyncOpenRouter = None  # type: ignore[assignment]

    class OpenRouterError(Exception):
        """Fallback OpenRouter error."""


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
            raise RuntimeError("The 'groq' package is required to validate Groq API keys.")
        kwargs = {"api_key": api_key}
        if base_url:
            kwargs["base_url"] = base_url
        if metadata:
            for key in ("timeout", "max_retries"):
                value = metadata.get(key)
                if value is not None:
                    kwargs[key] = value
        client = AsyncGroq(**kwargs)
        try:
            await client.models.list()
        except GroqError as exc:  # pragma: no cover
            raise ValueError(f"Groq API key validation failed: {exc}") from exc
        finally:
            await _close_client(client)

    async def _validate_openrouter(
        self,
        api_key: str,
        base_url: str | None,
        metadata: Mapping[str, Any] | None,
    ) -> None:
        if AsyncOpenRouter is None:
            raise RuntimeError("The 'openrouter' package is required to validate OpenRouter API keys.")
        kwargs: dict[str, Any] = {"api_key": api_key}
        if base_url:
            kwargs["base_url"] = base_url
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
        if headers:
            kwargs["default_headers"] = headers
        client = AsyncOpenRouter(**kwargs)
        try:
            await client.models.list()
        except OpenRouterError as exc:  # pragma: no cover
            raise ValueError(f"OpenRouter API key validation failed: {exc}") from exc
        finally:
            await _close_client(client)

    async def _validate_imagerouter(self, api_key: str, base_url: str | None) -> None:
        url = (base_url or "https://api.imagerouter.com") + "/v1/models"
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

