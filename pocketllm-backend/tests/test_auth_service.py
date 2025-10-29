import asyncio
import httpx
import pytest
from fastapi import HTTPException, status

from app.core.config import Settings
from app.services.auth import AuthService
from app.schemas.auth import SignInRequest


class DummyDatabase:
    async def upsert_profile(self, user_id, payload):  # pragma: no cover - test double
        return None

    async def get_profile(self, user_id):  # pragma: no cover - test double
        return None

    async def select(self, *args, **kwargs):  # pragma: no cover - compatibility stub
        return []


class FailingAsyncClient:
    def __init__(self, *args, **kwargs):
        pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, tb):
        return False

    async def post(self, *args, **kwargs):
        raise httpx.ConnectError(
            "Unable to resolve Supabase host",
            request=httpx.Request("POST", "https://project.supabase.co/auth/v1/token"),
        )


def test_sign_in_returns_service_unavailable_when_supabase_unreachable(monkeypatch):
    settings = Settings(
        supabase_url="https://project.supabase.co",
        supabase_anon_key="anon",
        supabase_service_role_key="service",
    )
    service = AuthService(settings=settings, database=DummyDatabase())

    monkeypatch.setattr(httpx, "AsyncClient", FailingAsyncClient)

    async def run() -> None:
        with pytest.raises(HTTPException) as exc_info:
            await service.sign_in(SignInRequest(email="user@example.com", password="secret"))

        assert exc_info.value.status_code == status.HTTP_503_SERVICE_UNAVAILABLE
        assert "temporarily unavailable" in exc_info.value.detail

    asyncio.run(run())
