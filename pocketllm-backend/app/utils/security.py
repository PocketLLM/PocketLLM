"""Security utilities for JWT validation and secret management."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any, Mapping

import httpx
import jwt
from fastapi import HTTPException, status
from passlib.context import CryptContext

from app.core.config import Settings
from app.schemas.auth import TokenPayload


_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_secret(secret: str) -> str:
    """Return a hashed representation of ``secret`` suitable for storage."""

    return _pwd_context.hash(secret)


def verify_secret(secret: str, hashed_secret: str) -> bool:
    """Verify that ``secret`` matches ``hashed_secret``."""

    return _pwd_context.verify(secret, hashed_secret)


def mask_secret(secret: str, visible: int = 4) -> str:
    """Return a masked preview of a secret value."""

    if len(secret) <= visible * 2:
        return "*" * len(secret)
    return f"{secret[:visible]}{'*' * (len(secret) - visible * 2)}{secret[-visible:]}"


def decode_access_token(token: str, settings: Settings) -> TokenPayload:
    """Decode and validate a Supabase JWT access token."""

    if settings.supabase_jwt_secret:
        decoded = _decode_with_secret(token, settings)
    else:
        decoded = _decode_with_supabase_verification(token, settings)

    payload = TokenPayload.model_validate(decoded)
    if payload.exp < datetime.now(tz=UTC):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired")
    return payload


def _decode_with_secret(token: str, settings: Settings) -> Mapping[str, Any]:
    """Decode a JWT using the configured Supabase secret."""

    try:
        return jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=[settings.token_algorithm],
            audience=settings.supabase_jwt_audience,
        )
    except jwt.ExpiredSignatureError as exc:  # type: ignore[attr-defined]
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired") from exc
    except jwt.InvalidTokenError as exc:  # type: ignore[attr-defined]
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token") from exc


def _decode_with_supabase_verification(token: str, settings: Settings) -> Mapping[str, Any]:
    """Validate a Supabase JWT when the shared secret is not configured."""

    supabase_url = str(getattr(settings, "supabase_url", "")).rstrip("/")
    api_key = getattr(settings, "supabase_anon_key", None) or getattr(settings, "supabase_service_role_key", None)

    if not supabase_url or not api_key:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Supabase credentials are not configured",
        )

    auth_endpoint = f"{supabase_url}/auth/v1/user"
    headers = {
        "apikey": api_key,
        "Authorization": f"Bearer {token}",
    }

    try:
        response = httpx.get(auth_endpoint, headers=headers, timeout=5.0)
        response.raise_for_status()
    except httpx.HTTPStatusError as exc:
        if exc.response.status_code in {status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN}:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
            ) from exc
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to validate authentication token with Supabase",
        ) from exc
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Unable to contact Supabase for token validation",
        ) from exc

    user_data = response.json()

    try:
        unverified = jwt.decode(token, options={"verify_signature": False})
    except jwt.InvalidTokenError as exc:  # type: ignore[attr-defined]
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token") from exc

    exp = _coerce_timestamp(unverified.get("exp"))
    if exp is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token is missing an expiry")

    payload: dict[str, Any] = {
        "sub": user_data.get("id") or unverified.get("sub"),
        "email": user_data.get("email") or unverified.get("email"),
        "role": user_data.get("role") or unverified.get("role"),
        "aud": user_data.get("aud") or unverified.get("aud"),
        "exp": exp,
        "iat": _coerce_timestamp(unverified.get("iat")),
        "iss": unverified.get("iss"),
        "session_id": unverified.get("session_id") or user_data.get("session_id"),
    }

    if not payload.get("sub"):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token is missing a subject")

    return payload


def _coerce_timestamp(value: Any) -> datetime | None:
    """Convert a JWT timestamp into an aware ``datetime`` instance."""

    if value is None:
        return None

    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(value, tz=UTC)

    if isinstance(value, str) and value.isdigit():
        return datetime.fromtimestamp(int(value), tz=UTC)

    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=UTC)

    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token timestamp")


def create_supabase_service_headers(settings: Settings) -> dict[str, str]:
    """Return headers for Supabase service role authenticated requests."""

    return {
        "apikey": settings.supabase_service_role_key,
        "Authorization": f"Bearer {settings.supabase_service_role_key}",
    }


__all__ = [
    "hash_secret",
    "verify_secret",
    "mask_secret",
    "decode_access_token",
    "create_supabase_service_headers",
]
