"""Security utilities for JWT validation and secret management."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Optional

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

    if not settings.supabase_jwt_secret:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="JWT secret not configured")

    try:
        decoded = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=[settings.token_algorithm],
            audience=settings.supabase_jwt_audience,
        )
    except jwt.ExpiredSignatureError as exc:  # type: ignore[attr-defined]
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired") from exc
    except jwt.InvalidTokenError as exc:  # type: ignore[attr-defined]
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token") from exc

    payload = TokenPayload.model_validate(decoded)
    if payload.exp < datetime.now(tz=UTC):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired")
    return payload


def create_supabase_service_headers(settings: Settings) -> dict[str, str]:
    """Return headers for Supabase service role authenticated requests."""

    return {
        "apikey": settings.supabase_service_role_key,
        "Authorization": f"Bearer {settings.supabase_service_role_key}",
    }


__all__ = ["hash_secret", "verify_secret", "mask_secret", "decode_access_token", "create_supabase_service_headers"]
