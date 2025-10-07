"""Tests for authentication cookie helpers."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

from fastapi import Response

from app.core.config import Settings
from app.schemas.auth import AuthTokens, SessionMetadata
from app.utils.auth_cookies import (
    ACCESS_COOKIE_NAME,
    REFRESH_COOKIE_NAME,
    clear_auth_cookies,
    get_refresh_token_from_request,
    set_auth_cookies,
)


def _build_session(expiry_minutes: int = 30, refresh_minutes: int = 60) -> SessionMetadata:
    now = datetime.now(tz=UTC)
    return SessionMetadata(
        session_id=uuid4(),
        expires_at=now + timedelta(minutes=expiry_minutes),
        refresh_expires_at=now + timedelta(minutes=refresh_minutes),
    )


def test_set_auth_cookies_sets_secure_http_only_cookies() -> None:
    settings = Settings(debug=False)
    response = Response()
    tokens = AuthTokens(access_token="access-token", refresh_token="refresh-token", expires_in=3600)
    session = _build_session()

    set_auth_cookies(response, tokens, session, settings)

    cookies = response.headers.getlist("set-cookie")
    assert any(cookie.startswith(f"{ACCESS_COOKIE_NAME}=access-token") for cookie in cookies)
    refresh_cookie = next(cookie for cookie in cookies if cookie.startswith(f"{REFRESH_COOKIE_NAME}="))
    assert "HttpOnly" in refresh_cookie
    assert "Secure" in refresh_cookie
    assert "SameSite=lax" in refresh_cookie


def test_clear_auth_cookies_marks_cookies_for_removal() -> None:
    response = Response()
    clear_auth_cookies(response)

    cookies = response.headers.getlist("set-cookie")
    assert any(cookie.startswith(f"{ACCESS_COOKIE_NAME}=") for cookie in cookies)
    assert all("Max-Age=0" in cookie for cookie in cookies)


def test_get_refresh_token_from_request_prefers_cookie() -> None:
    class DummyRequest:
        def __init__(self) -> None:
            self.cookies = {REFRESH_COOKIE_NAME: "cookie-token"}
            self.headers = {"X-Refresh-Token": "header-token"}

    request = DummyRequest()
    assert get_refresh_token_from_request(request) == "cookie-token"


def test_get_refresh_token_from_request_falls_back_to_header() -> None:
    class DummyRequest:
        def __init__(self) -> None:
            self.cookies = {}
            self.headers = {"X-Refresh-Token": " header-token "}

    request = DummyRequest()
    assert get_refresh_token_from_request(request) == "header-token"
