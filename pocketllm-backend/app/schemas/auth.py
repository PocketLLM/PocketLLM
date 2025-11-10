"""Authentication schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Literal, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, model_validator


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

    model_config = ConfigDict(populate_by_name=True)

    email: EmailStr
    password: str = Field(min_length=8)
    full_name: Optional[str] = Field(default=None, max_length=120)
    invite_code: Optional[str] = Field(
        default=None,
        max_length=64,
        description="Optional invite code required for gated onboarding.",
    )
    referral_code: Optional[str] = Field(
        default=None,
        max_length=64,
        description="Alias for invite_code for backward compatibility.",
    )

    @model_validator(mode="before")
    @classmethod
    def _populate_full_name(cls, data: Any) -> Any:
        if isinstance(data, dict) and "full_name" not in data and "name" in data:
            data = dict(data)
            data["full_name"] = data.get("name")
        if isinstance(data, dict):
            invite_code = data.get("invite_code") or data.get("referral_code")
            if invite_code:
                data = dict(data)
                normalized = str(invite_code).strip()
                data["invite_code"] = normalized or None
                data["referral_code"] = normalized or None
        return data


class AccountStatus(BaseModel):
    """Account lifecycle metadata returned with auth responses."""

    deletion_scheduled: bool = False
    deletion_scheduled_for: datetime | None = None
    deletion_requested_at: datetime | None = None
    deletion_canceled: bool = False
    previous_deletion_requested_at: datetime | None = None
    previous_deletion_scheduled_for: datetime | None = None


class SignUpResponse(BaseModel):
    """Response returned after a successful sign up."""

    user: AuthenticatedUser
    tokens: AuthTokens | None = None
    session: SessionMetadata | None = None
    account_status: AccountStatus = Field(default_factory=AccountStatus)


class SignInRequest(BaseModel):
    """Request body for user sign in."""

    email: EmailStr
    password: str


class SignInResponse(BaseModel):
    """Response payload for successful sign in."""

    user: AuthenticatedUser
    tokens: AuthTokens
    session: SessionMetadata
    account_status: AccountStatus


class MagicLinkRequest(BaseModel):
    """Request a passwordless email link."""

    email: EmailStr


class PhoneOtpRequest(BaseModel):
    """Request an OTP for phone-based sign in."""

    phone: str = Field(min_length=8, max_length=32)


class OAuthProviderRequest(BaseModel):
    """Initiate an OAuth sign-in flow."""

    provider: str


class AuthFeatureAvailabilityResponse(BaseModel):
    """Placeholder response for upcoming authentication features."""

    feature: str
    status: Literal["coming_soon", "available"] = "coming_soon"
    message: str


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

    refresh_token: str | None = None


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
    "AccountStatus",
    "MagicLinkRequest",
    "PhoneOtpRequest",
    "OAuthProviderRequest",
    "AuthFeatureAvailabilityResponse",
    "TokenPayload",
    "RefreshTokenRequest",
    "RefreshTokenResponse",
    "SignOutResponse",
]
