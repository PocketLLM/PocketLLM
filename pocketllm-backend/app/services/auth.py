"""Authentication service interacting with Supabase GoTrue."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID

import httpx
from fastapi import HTTPException, status

from app.core.config import Settings
from app.core.database import Database
from app.schemas.auth import (
    AccountStatus,
    AuthTokens,
    AuthenticatedUser,
    SessionMetadata,
    SignInRequest,
    SignInResponse,
    SignOutResponse,
    SignUpRequest,
    SignUpResponse,
)
from app.utils.security import create_supabase_service_headers
from app.services.users import UsersService


class AuthService:
    """Service responsible for user authentication workflow."""

    def __init__(self, settings: Settings, database: Database) -> None:
        self._settings = settings
        self._database = database

    async def sign_up(self, payload: SignUpRequest) -> SignUpResponse:
        """Register a new user via Supabase GoTrue."""

        request_body = {
            "email": payload.email,
            "password": payload.password,
            "data": {"full_name": payload.full_name},
        }
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(
                f"{self._settings.supabase_url}/auth/v1/signup",
                headers=create_supabase_service_headers(self._settings),
                json=request_body,
            )
        if response.status_code >= 400:
            detail = response.json().get("msg") if response.headers.get("content-type", "").startswith("application/json") else response.text
            raise HTTPException(status_code=response.status_code, detail=detail or "Sign up failed")

        data = response.json()
        user = self._map_user(data.get("user"))
        session_payload = data.get("session")
        tokens = self._map_tokens(session_payload) if session_payload else None
        session = self._map_session(session_payload)

        await self._upsert_profile(user, payload.full_name)
        account_status = AccountStatus()
        return SignUpResponse(
            user=user,
            tokens=tokens,
            session=session,
            account_status=account_status,
        )

    async def sign_in(self, payload: SignInRequest) -> SignInResponse:
        """Authenticate a user via email/password."""

        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(
                f"{self._settings.supabase_url}/auth/v1/token?grant_type=password",
                headers={
                    "apikey": self._settings.supabase_anon_key,
                    "Authorization": f"Bearer {self._settings.supabase_anon_key}",
                },
                json={"email": payload.email, "password": payload.password},
            )
        if response.status_code >= 400:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

        data = response.json()
        user = self._map_user(data.get("user"))
        tokens = self._map_tokens(data)
        session = self._map_session(data)
        await self._upsert_profile(user)
        account_status = await self._resolve_account_status(user.id)
        return SignInResponse(user=user, tokens=tokens, session=session, account_status=account_status)

    async def sign_out(self, access_token: str) -> SignOutResponse:
        """Invalidate the active session."""

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{self._settings.supabase_url}/auth/v1/logout",
                headers={
                    "apikey": self._settings.supabase_anon_key,
                    "Authorization": f"Bearer {access_token}",
                },
            )
        if response.status_code >= 400:
            raise HTTPException(status_code=response.status_code, detail="Failed to sign out")

        return SignOutResponse()

    async def _upsert_profile(self, user: AuthenticatedUser, full_name: str | None = None) -> None:
        """Ensure that a profile exists for the authenticated Supabase user."""

        query = """
        INSERT INTO public.profiles (id, email, full_name)
        VALUES ($1, $2, $3)
        ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email,
            full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
            updated_at = NOW()
        """
        await self._database.execute(query, user.id, user.email, full_name)

    async def _resolve_account_status(self, user_id: UUID) -> AccountStatus:
        users_service = UsersService(database=self._database)
        cancellation = await users_service.cancel_deletion_if_pending(user_id)
        profile = cancellation.profile
        deletion_scheduled = profile.deletion_status == "pending" and profile.deletion_scheduled_for is not None
        return AccountStatus(
            deletion_scheduled=deletion_scheduled,
            deletion_scheduled_for=profile.deletion_scheduled_for,
            deletion_requested_at=profile.deletion_requested_at,
            deletion_canceled=cancellation.canceled,
            previous_deletion_requested_at=cancellation.previous_deletion_requested_at,
            previous_deletion_scheduled_for=cancellation.previous_deletion_scheduled_for,
        )

    def _map_user(self, payload: dict[str, Any] | None) -> AuthenticatedUser:
        if not payload:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Invalid Supabase response")

        return AuthenticatedUser(
            id=UUID(payload["id"]),
            email=payload["email"],
            full_name=payload.get("user_metadata", {}).get("full_name"),
            created_at=self._parse_datetime(payload.get("created_at")),
            last_sign_in_at=self._parse_datetime(payload.get("last_sign_in_at")),
        )

    def _map_tokens(self, payload: dict[str, Any]) -> AuthTokens:
        if "access_token" not in payload:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Missing access token")

        return AuthTokens(
            access_token=payload["access_token"],
            refresh_token=payload.get("refresh_token", ""),
            token_type=payload.get("token_type", "bearer"),
            expires_in=payload.get("expires_in"),
        )

    def _map_session(self, payload: dict[str, Any] | None) -> SessionMetadata | None:
        if not payload:
            return None
        expires_at_value = payload.get("expires_at")
        if expires_at_value is not None:
            expires_at = datetime.fromtimestamp(expires_at_value, tz=UTC)
        elif payload.get("expires_in"):
            expires_at = datetime.now(tz=UTC) + timedelta(seconds=payload["expires_in"])
        else:
            return None
        refresh_expires_at = None
        if payload.get("refresh_expires_in"):
            refresh_expires_at = expires_at + timedelta(seconds=payload["refresh_expires_in"])
        user_payload = payload.get("user")
        user_id = None
        if isinstance(user_payload, dict) and user_payload.get("id"):
            user_id = UUID(user_payload["id"])
        elif isinstance(user_payload, str):
            user_id = UUID(user_payload)
        if user_id is None:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Supabase response missing user identifier")
        return SessionMetadata(
            session_id=user_id,
            expires_at=expires_at,
            refresh_expires_at=refresh_expires_at,
        )

    @staticmethod
    def _parse_datetime(value: str | None) -> datetime | None:
        if not value:
            return None
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return None


__all__ = ["AuthService"]
