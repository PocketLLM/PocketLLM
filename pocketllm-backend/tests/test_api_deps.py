"""Tests for dependency utilities used by API routes."""

from __future__ import annotations

from types import SimpleNamespace
from typing import Any, Dict

import pytest

from app.api.deps import get_current_token_payload
from app.core.config import Settings


class _CaseInsensitiveHeaders(dict):
    """Dictionary providing case-insensitive header access for tests."""

    def __init__(self, data: Dict[str, str] | None = None):
        super().__init__()
        if data:
            for key, value in data.items():
                self[key] = value

    def __setitem__(self, key: str, value: str) -> None:  # type: ignore[override]
        super().__setitem__(key.lower(), value)

    def get(self, key: str, default: Any = None) -> Any:  # type: ignore[override]
        return super().get(key.lower(), default)


class DummyRequest:
    """Minimal request object implementing the attributes used in dependencies."""

    def __init__(
        self,
        *,
        headers: Dict[str, str] | None = None,
        cookies: Dict[str, str] | None = None,
        query_params: Dict[str, str] | None = None,
    ) -> None:
        self.headers = _CaseInsensitiveHeaders(headers or {})
        self.cookies = cookies or {}
        self.query_params = query_params or {}
        self.state = SimpleNamespace()


def _make_settings() -> Settings:
    return Settings(supabase_jwt_secret="secret-key")


@pytest.mark.asyncio
async def test_get_current_token_payload_from_credentials(monkeypatch: pytest.MonkeyPatch) -> None:
    request = DummyRequest()
    credentials = SimpleNamespace(credentials="token-from-credentials", scheme="Bearer")
    settings = _make_settings()

    captured: dict[str, str] = {}

    def fake_decode(token: str, _settings: Settings) -> dict[str, str]:
        captured["token"] = token
        return {"token": token}

    monkeypatch.setattr("app.api.deps.decode_access_token", fake_decode)

    payload = await get_current_token_payload(request=request, credentials=credentials, settings=settings)

    assert payload == {"token": "token-from-credentials"}
    assert captured["token"] == "token-from-credentials"


@pytest.mark.asyncio
async def test_get_current_token_payload_from_authorization_header(monkeypatch: pytest.MonkeyPatch) -> None:
    request = DummyRequest(headers={"Authorization": "token-from-header"})
    settings = _make_settings()

    def fake_decode(token: str, _settings: Settings) -> dict[str, str]:
        return {"token": token}

    monkeypatch.setattr("app.api.deps.decode_access_token", fake_decode)

    payload = await get_current_token_payload(request=request, credentials=None, settings=settings)

    assert payload == {"token": "token-from-header"}


@pytest.mark.asyncio
async def test_get_current_token_payload_prefers_bearer_scheme_when_present(monkeypatch: pytest.MonkeyPatch) -> None:
    request = DummyRequest(headers={"Authorization": "Bearer token-from-bearer"})
    settings = _make_settings()

    def fake_decode(token: str, _settings: Settings) -> dict[str, str]:
        return {"token": token}

    monkeypatch.setattr("app.api.deps.decode_access_token", fake_decode)

    payload = await get_current_token_payload(request=request, credentials=None, settings=settings)

    assert payload == {"token": "token-from-bearer"}


@pytest.mark.asyncio
async def test_get_current_token_payload_from_cookie(monkeypatch: pytest.MonkeyPatch) -> None:
    request = DummyRequest(cookies={"sb-access-token": "token-from-cookie"})
    settings = _make_settings()

    def fake_decode(token: str, _settings: Settings) -> dict[str, str]:
        return {"token": token}

    monkeypatch.setattr("app.api.deps.decode_access_token", fake_decode)

    payload = await get_current_token_payload(request=request, credentials=None, settings=settings)

    assert payload == {"token": "token-from-cookie"}


@pytest.mark.asyncio
async def test_get_current_token_payload_from_query_parameter(monkeypatch: pytest.MonkeyPatch) -> None:
    request = DummyRequest(query_params={"access_token": "token-from-query"})
    settings = _make_settings()

    def fake_decode(token: str, _settings: Settings) -> dict[str, str]:
        return {"token": token}

    monkeypatch.setattr("app.api.deps.decode_access_token", fake_decode)

    payload = await get_current_token_payload(request=request, credentials=None, settings=settings)

    assert payload == {"token": "token-from-query"}


@pytest.mark.asyncio
async def test_get_current_token_payload_raises_for_missing_token(monkeypatch: pytest.MonkeyPatch) -> None:
    request = DummyRequest()
    settings = _make_settings()

    monkeypatch.setattr("app.api.deps.decode_access_token", lambda token, _settings: token)

    with pytest.raises(Exception) as exc_info:
        await get_current_token_payload(request=request, credentials=None, settings=settings)

    assert getattr(exc_info.value, "status_code", None) == 401
