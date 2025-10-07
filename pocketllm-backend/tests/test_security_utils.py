from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from uuid import uuid4

import jwt

from app.utils.security import decode_access_token


class _StubResponse:
    """Minimal stub emulating an ``httpx.Response`` for success cases."""

    def __init__(self, payload: dict[str, object]) -> None:
        self._payload = payload
        self.status_code = 200

    def raise_for_status(self) -> None:  # pragma: no cover - no-op for success
        return None

    def json(self) -> dict[str, object]:
        return dict(self._payload)


def test_decode_access_token_uses_supabase_verification(monkeypatch) -> None:
    """Fallback validation should succeed when the JWT secret is missing."""

    user_id = uuid4()
    issued_at = datetime.now(tz=UTC) - timedelta(minutes=1)
    expires_at = issued_at + timedelta(hours=1)

    token_payload = {
        "sub": str(user_id),
        "email": "user@example.com",
        "role": "authenticated",
        "aud": "authenticated",
        "iat": int(issued_at.timestamp()),
        "exp": int(expires_at.timestamp()),
        "iss": "https://example.supabase.co/auth/v1",
    }

    token = jwt.encode(token_payload, "arbitrary-secret", algorithm="HS256")

    supabase_user_payload = {
        "id": str(user_id),
        "email": "user@example.com",
        "role": "authenticated",
        "aud": "authenticated",
    }

    def _fake_get(url: str, *, headers: dict[str, str], timeout: float) -> _StubResponse:
        assert url == "https://example.supabase.co/auth/v1/user"
        assert "Authorization" in headers and headers["Authorization"].startswith("Bearer ")
        return _StubResponse(supabase_user_payload)

    monkeypatch.setattr("httpx.get", _fake_get)

    settings = SimpleNamespace(
        supabase_jwt_secret=None,
        supabase_url="https://example.supabase.co",
        supabase_anon_key="anon-key",
        supabase_service_role_key="service-role",
        token_algorithm="HS256",
        supabase_jwt_audience="authenticated",
    )

    payload = decode_access_token(token, settings)

    assert payload.sub == user_id
    assert payload.email == "user@example.com"
    assert payload.role == "authenticated"
    assert payload.aud == "authenticated"
    assert payload.exp == expires_at.replace(microsecond=0)
