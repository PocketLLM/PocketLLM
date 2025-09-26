"""Local development authentication store.

This module provides a minimal in-memory authentication backend that mimics the
shape of Supabase responses. It is designed to be used whenever Supabase is not
configured (for instance in local or CI environments) so that the PocketLLM
application can still sign users up and allow them to authenticate.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from threading import RLock
from typing import Dict, Tuple
from uuid import UUID, uuid4

from fastapi import HTTPException, status

from app.schemas.auth import AuthTokens, SessionMetadata, TokenPayload
from app.utils.security import hash_secret, verify_secret


@dataclass
class LocalAccount:
    """Representation of a locally managed user account."""

    id: UUID
    email: str
    password_hash: str
    full_name: str | None = None
    created_at: datetime = field(default_factory=lambda: datetime.now(tz=UTC))
    last_sign_in_at: datetime | None = None


class LocalAuthManager:
    """Simple thread-safe in-memory store for local authentication."""

    def __init__(self) -> None:
        self._accounts: Dict[str, LocalAccount] = {}
        self._access_tokens: Dict[str, Tuple[TokenPayload, datetime]] = {}
        self._refresh_tokens: Dict[str, Tuple[UUID, datetime]] = {}
        self._lock = RLock()

    def _normalise_email(self, email: str) -> str:
        return email.strip().lower()

    def register_account(self, email: str, password: str, full_name: str | None = None) -> LocalAccount:
        """Create a new account or raise an error if it already exists."""

        normalised = self._normalise_email(email)
        with self._lock:
            if normalised in self._accounts:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User already exists")
            account = LocalAccount(id=uuid4(), email=email.strip(), password_hash=hash_secret(password), full_name=full_name)
            self._accounts[normalised] = account
            return account

    def authenticate_account(self, email: str, password: str) -> LocalAccount:
        """Validate credentials and return the associated account."""

        normalised = self._normalise_email(email)
        with self._lock:
            account = self._accounts.get(normalised)
            if account is None or not verify_secret(password, account.password_hash):
                raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
            return account

    def issue_tokens(
        self,
        account: LocalAccount,
        *,
        access_minutes: int,
        refresh_minutes: int,
        audience: str,
    ) -> tuple[AuthTokens, SessionMetadata]:
        """Generate access and refresh tokens for ``account``."""

        now = datetime.now(tz=UTC)
        access_expires_at = now + timedelta(minutes=access_minutes)
        refresh_expires_at = now + timedelta(minutes=refresh_minutes)

        access_token = f"local.{uuid4()}"
        refresh_token = f"local-refresh.{uuid4()}"

        payload = TokenPayload(
            sub=account.id,
            email=account.email,
            role="authenticated",
            aud=audience,
            exp=access_expires_at,
            iat=now,
            iss="local-auth",
            session_id=account.id,
        )

        account.last_sign_in_at = now

        with self._lock:
            self._access_tokens[access_token] = (payload, access_expires_at)
            self._refresh_tokens[refresh_token] = (account.id, refresh_expires_at)

        tokens = AuthTokens(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=int(access_minutes * 60),
        )

        session = SessionMetadata(
            session_id=account.id,
            expires_at=access_expires_at,
            refresh_expires_at=refresh_expires_at,
        )

        return tokens, session

    def get_payload_for_token(self, token: str) -> TokenPayload | None:
        """Return the cached payload for ``token`` when available."""

        now = datetime.now(tz=UTC)
        with self._lock:
            payload = self._access_tokens.get(token)
            if payload is None:
                return None
            token_payload, expires_at = payload
            if expires_at < now:
                self._access_tokens.pop(token, None)
                return None
            return token_payload

    def revoke_access_token(self, token: str) -> None:
        """Invalidate a previously issued access token."""

        with self._lock:
            self._access_tokens.pop(token, None)


local_auth_manager = LocalAuthManager()


__all__ = ["LocalAuthManager", "LocalAccount", "local_auth_manager"]
