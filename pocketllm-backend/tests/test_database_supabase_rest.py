"""Tests for the Supabase REST fallback store."""

from __future__ import annotations

from uuid import UUID

import pytest

httpx = pytest.importorskip("httpx")

from app.core.config import Settings
from app.core.database import _SupabaseRestStore


@pytest.mark.asyncio
async def test_upsert_profile_creates_new_record(monkeypatch):
    settings = Settings(
        supabase_url="https://example.supabase.co",
        supabase_service_role_key="service-role-test-key",
    )
    store = _SupabaseRestStore(settings)

    captured: dict[str, object] = {}

    async def fake_get_profile(user_id: UUID):  # pragma: no cover - patched in test
        captured["looked_up"] = user_id
        return None

    async def fake_request(method: str, resource: str, **kwargs):  # pragma: no cover - patched in test
        captured["method"] = method
        captured["resource"] = resource
        captured["kwargs"] = kwargs
        return None

    monkeypatch.setattr(store, "_get_profile", fake_get_profile)
    monkeypatch.setattr(store, "_request", fake_request)

    user_id = UUID("8fcae76c-1114-4147-b519-b87154abcf35")
    query = """
    INSERT INTO public.profiles (id, email, full_name)
    VALUES ($1, $2, $3)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name)
    """

    await store._upsert_profile(query, user_id, "user@example.com", "Test User")

    assert captured["method"] == "POST"
    assert captured["resource"] == "profiles"
    kwargs = captured["kwargs"]
    assert kwargs["prefer"] == "return=minimal"
    assert kwargs.get("params") is None
    payload = kwargs["json_payload"]
    assert payload["id"] == str(user_id)
    assert payload["email"] == "user@example.com"
    assert payload["full_name"] == "Test User"
    assert "created_at" in payload
    assert "updated_at" in payload


@pytest.mark.asyncio
async def test_upsert_profile_updates_existing_record(monkeypatch):
    settings = Settings(
        supabase_url="https://example.supabase.co",
        supabase_service_role_key="service-role-test-key",
    )
    store = _SupabaseRestStore(settings)

    calls: list[dict[str, object]] = []

    async def fake_get_profile(user_id: UUID):  # pragma: no cover - patched in test
        return {"id": str(user_id), "full_name": "Existing Name"}

    async def fake_request(method: str, resource: str, **kwargs):  # pragma: no cover - patched in test
        calls.append({"method": method, "resource": resource, "kwargs": kwargs})
        return None

    monkeypatch.setattr(store, "_get_profile", fake_get_profile)
    monkeypatch.setattr(store, "_request", fake_request)

    user_id = UUID("11111111-2222-3333-4444-555555555555")
    query = """
    INSERT INTO public.profiles (id, email, full_name)
    VALUES ($1, $2, $3)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name)
    """

    await store._upsert_profile(query, user_id, "new@example.com", None)

    assert calls, "Expected the Supabase REST store to issue a request"
    call = calls[0]
    assert call["method"] == "PATCH"
    assert call["resource"] == "profiles"
    kwargs = call["kwargs"]
    assert kwargs["params"] == {"id": f"eq.{user_id}"}
    assert kwargs["prefer"] == "return=minimal"
    payload = kwargs["json_payload"]
    assert payload["email"] == "new@example.com"
    assert "id" not in payload
    assert "created_at" not in payload
    assert "full_name" not in payload
    assert "updated_at" in payload
    # Ensure the updated_at value is an ISO formatted timestamp
    assert "T" in payload["updated_at"]