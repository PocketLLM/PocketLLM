"""Authentication schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class AuthenticatedUser(BaseModel):
    """Information about the authenticated user."""

    id: UUID = Field(description="Unique identifier of the Supabase auth user")
    email: EmailStr
    full_name: Optional[str] = None
    created_at: datetime | None = None
    last_sign_in_at: datetime | None = None


class SessionMetadata(BaseModel):
    """Metadata describing the Supabase session."""

    session_id: UUID
    expires_at: datetime
    refresh_expires_at: datetime | None = None


class AuthTokens(BaseModel):
    """Bearer tokens returned by Supabase."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int | None = None


class SignUpRequest(BaseModel):
    """Payload used to register a user through Supabase."""

    email: EmailStr
    password: str = Field(min_length=8)
    full_name: Optional[str] = Field(default=None, max_length=120)


class SignUpResponse(BaseModel):
    """Response returned after a successful sign up."""

    user: AuthenticatedUser
    tokens: AuthTokens | None = None
    session: SessionMetadata | None = None


class SignInRequest(BaseModel):
    """Request body for user sign in."""

    email: EmailStr
    password: str


class SignInResponse(BaseModel):
    """Response payload for successful sign in."""

    user: AuthenticatedUser
    tokens: AuthTokens
    session: SessionMetadata


class TokenPayload(BaseModel):
    """Decoded access token payload."""

    sub: UUID
    email: Optional[EmailStr] = None
    role: Optional[str] = None
    aud: Optional[str] = None
    exp: datetime
    iat: datetime | None = None
    iss: Optional[str] = None
    session_id: Optional[UUID] = Field(default=None, alias="session_id")

    class Config:
        populate_by_name = True


class RefreshTokenRequest(BaseModel):
    """Request body for refreshing tokens."""

    refresh_token: str


class RefreshTokenResponse(BaseModel):
    """Payload returned after refreshing an access token."""

    tokens: AuthTokens
    session: SessionMetadata


class SignOutResponse(BaseModel):
    """Response for sign out action."""

    revoked_sessions: int = 1


__all__ = [
    "AuthenticatedUser",
    "SessionMetadata",
    "AuthTokens",
    "SignUpRequest",
    "SignUpResponse",
    "SignInRequest",
    "SignInResponse",
    "TokenPayload",
    "RefreshTokenRequest",
    "RefreshTokenResponse",
    "SignOutResponse",
]
