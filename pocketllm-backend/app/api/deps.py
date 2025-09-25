"""Common dependency utilities for FastAPI routers."""

from __future__ import annotations

from typing import AsyncIterator

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import Settings, get_settings
from app.core.database import Database, get_database
from app.schemas.auth import TokenPayload
from app.utils.security import decode_access_token


reusable_oauth2 = HTTPBearer(auto_error=False)


async def get_settings_dependency() -> Settings:
    """Provide application settings to request handlers."""

    return get_settings()


async def get_database_dependency(
    settings: Settings = Depends(get_settings_dependency),
) -> Database:
    """Return the database singleton."""

    database = get_database(settings)
    await database.connect()
    return database


async def get_current_token_payload(
    credentials: HTTPAuthorizationCredentials | None = Depends(reusable_oauth2),
    settings: Settings = Depends(get_settings_dependency),
) -> TokenPayload:
    """Decode the current JWT payload from the Authorization header."""

    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    return decode_access_token(credentials.credentials, settings)


async def get_current_request_user(
    request: Request,
    payload: TokenPayload = Depends(get_current_token_payload),
) -> TokenPayload:
    """Attach the authenticated user payload to the request state."""

    request.state.user = payload
    return payload


__all__ = [
    "get_settings_dependency",
    "get_database_dependency",
    "get_current_token_payload",
    "get_current_request_user",
]
