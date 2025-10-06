"""Tests for :mod:`app.services.api_keys`."""

from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager
from types import SimpleNamespace
from typing import Any

import httpx
import pytest

from app.core.config import Settings
from app.services.api_keys import APIKeyValidationService


def test_validate_groq_falls_back_to_http_when_sdk_missing(monkeypatch: pytest.MonkeyPatch) -> None:
    """Ensure Groq validation succeeds via HTTP when the SDK is unavailable."""

    real_async_client = httpx.AsyncClient
    captured_requests: list[httpx.Request] = []
    captured_timeouts: list[Any] = []

    def handler(request: httpx.Request) -> httpx.Response:
        captured_requests.append(request)
        return httpx.Response(200, json={"data": []})

    transport = httpx.MockTransport(handler)

    @asynccontextmanager
    async def client_factory(*args: Any, **kwargs: Any):
        kwargs.setdefault("transport", transport)
        captured_timeouts.append(kwargs.get("timeout"))
        async with real_async_client(*args, **kwargs) as client:
            yield client

    monkeypatch.setattr("app.services.api_keys.AsyncGroq", None, raising=False)
    monkeypatch.setattr("app.services.api_keys.httpx.AsyncClient", client_factory, raising=False)

    service = APIKeyValidationService(Settings())

    asyncio.run(
        service.validate(
            "groq",
            "test-key",
            base_url="https://api.groq.com/openai/v1/",
            metadata={"timeout": "5"},
        )
    )

    assert captured_requests, "Expected an HTTP request to be issued"
    request = captured_requests[0]
    assert request.headers["Authorization"] == "Bearer test-key"
    assert request.url.path.endswith("/models")
    assert captured_timeouts and captured_timeouts[0] == 5.0


def test_validate_groq_http_fallback_appends_openai_prefix(monkeypatch: pytest.MonkeyPatch) -> None:
    """Ensure bare Groq base URLs gain the OpenAI compatibility prefix."""

    real_async_client = httpx.AsyncClient
    captured_urls: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        captured_urls.append(str(request.url))
        return httpx.Response(200, json={"data": []})

    transport = httpx.MockTransport(handler)

    @asynccontextmanager
    async def client_factory(*args: Any, **kwargs: Any):
        kwargs.setdefault("transport", transport)
        async with real_async_client(*args, **kwargs) as client:
            yield client

    monkeypatch.setattr("app.services.api_keys.AsyncGroq", None, raising=False)
    monkeypatch.setattr("app.services.api_keys.httpx.AsyncClient", client_factory, raising=False)

    service = APIKeyValidationService(Settings())

    asyncio.run(
        service.validate(
            "groq",
            "test-key",
            base_url="https://api.groq.com",
            metadata={},
        )
    )

    assert captured_urls
    assert captured_urls[0].endswith("/openai/v1/models")


def test_validate_groq_http_fallback_raises_for_errors(monkeypatch: pytest.MonkeyPatch) -> None:
    """HTTP fallback should surface non-success status codes as validation errors."""

    real_async_client = httpx.AsyncClient

    def handler(_: httpx.Request) -> httpx.Response:
        return httpx.Response(403, text="Forbidden")

    transport = httpx.MockTransport(handler)

    @asynccontextmanager
    async def client_factory(*args: Any, **kwargs: Any):
        kwargs.setdefault("transport", transport)
        async with real_async_client(*args, **kwargs) as client:
            yield client

    monkeypatch.setattr("app.services.api_keys.AsyncGroq", None, raising=False)
    monkeypatch.setattr("app.services.api_keys.httpx.AsyncClient", client_factory, raising=False)

    service = APIKeyValidationService(Settings())

    with pytest.raises(ValueError) as excinfo:
        asyncio.run(service.validate("groq", "invalid", metadata={}))

    assert "403" in str(excinfo.value)


def test_validate_groq_sdk_normalises_base_url(monkeypatch: pytest.MonkeyPatch) -> None:
    """The SDK validation path should strip redundant OpenAI prefixes."""

    created_kwargs: dict[str, Any] = {}

    class FakeGroqClient:
        def __init__(self, **kwargs: Any) -> None:
            created_kwargs.update(kwargs)
            self.models = SimpleNamespace(list=self._list)

        async def _list(self) -> Any:
            return {"data": []}

        async def aclose(self) -> None:  # pragma: no cover - exercised implicitly
            return None

    monkeypatch.setattr("app.services.api_keys.AsyncGroq", FakeGroqClient, raising=False)

    service = APIKeyValidationService(Settings())

    asyncio.run(
        service.validate(
            "groq",
            "test-key",
            base_url="https://proxy.example.com/openai/v1/",
            metadata={"timeout": 1},
        )
    )

    assert created_kwargs.get("api_key") == "test-key"
    assert created_kwargs.get("base_url") == "https://proxy.example.com"
