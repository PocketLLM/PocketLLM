"""Helper utilities for managing authentication cookies."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Final

from fastapi import Request, Response

from app.core.config import Settings
from app.schemas.auth import AuthTokens, SessionMetadata


ACCESS_COOKIE_NAME: Final[str] = "sb-access-token"
REFRESH_COOKIE_NAME: Final[str] = "sb-refresh-token"


def _seconds_until(expiry: datetime) -> int:
    """Return the number of whole seconds between now and ``expiry``."""

    delta = expiry - datetime.now(tz=UTC)
    seconds = int(delta.total_seconds())
    return max(seconds, 1)


def _refresh_expiry(session: SessionMetadata, settings: Settings) -> datetime:
    """Determine the expiry timestamp for the refresh token cookie."""

    if session.refresh_expires_at is not None:
        return session.refresh_expires_at
    refresh_minutes = getattr(settings, "refresh_token_expire_minutes", 0) or 0
    if refresh_minutes <= 0:
        refresh_minutes = 60 * 24 * 14  # fall back to Supabase default (14 days)
    return session.expires_at + timedelta(minutes=refresh_minutes)


def set_auth_cookies(
    response: Response,
    tokens: AuthTokens,
    session: SessionMetadata,
    settings: Settings,
) -> None:
    """Persist access and refresh tokens as secure HTTP-only cookies."""

    secure = not settings.debug
    same_site = "lax"

    response.set_cookie(
        ACCESS_COOKIE_NAME,
        tokens.access_token,
        max_age=_seconds_until(session.expires_at),
        expires=session.expires_at,
        httponly=True,
        secure=secure,
        samesite=same_site,
        path="/",
    )

    refresh_token = (tokens.refresh_token or "").strip()
    if not refresh_token:
        return

    refresh_expiry = _refresh_expiry(session, settings)
    response.set_cookie(
        REFRESH_COOKIE_NAME,
        refresh_token,
        max_age=_seconds_until(refresh_expiry),
        expires=refresh_expiry,
        httponly=True,
        secure=secure,
        samesite=same_site,
        path="/",
    )


def clear_auth_cookies(response: Response) -> None:
    """Remove authentication cookies from the client."""

    response.delete_cookie(ACCESS_COOKIE_NAME, path="/")
    response.delete_cookie(REFRESH_COOKIE_NAME, path="/")


def get_refresh_token_from_request(request: Request) -> str | None:
    """Extract a refresh token from request cookies or headers if available."""

    cookie_candidates = (
        request.cookies.get(REFRESH_COOKIE_NAME),
        request.cookies.get("refresh_token"),
    )
    for token in cookie_candidates:
        if token and token.strip():
            return token.strip()

    header_token = request.headers.get("X-Refresh-Token")
    if header_token and header_token.strip():
        return header_token.strip()

    return None


def get_access_token_from_request(request: Request) -> str | None:
    """Extract an access token from request cookies or headers if available."""

    cookie_candidates = (
        request.cookies.get(ACCESS_COOKIE_NAME),
        request.cookies.get("access_token"),
    )
    for token in cookie_candidates:
        if token and token.strip():
            return token.strip()

    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.strip():
        scheme, _, token = auth_header.partition(" ")
        if scheme.lower() == "bearer" and token.strip():
            return token.strip()

    return None


__all__ = [
    "ACCESS_COOKIE_NAME",
    "REFRESH_COOKIE_NAME",
    "set_auth_cookies",
    "clear_auth_cookies",
    "get_refresh_token_from_request",
    "get_access_token_from_request",
]

