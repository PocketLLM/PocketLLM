"""Tests for the in-memory database fallback used in mock mode."""

from __future__ import annotations

import types
import uuid

import pytest

from app.core.config import Settings
from app.core.database import Database, _SupabaseRestStore


INSERT_PROFILE_QUERY = """
INSERT INTO public.profiles (id, email, full_name)
VALUES ($1, $2, $3)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
    updated_at = NOW()
"""

SELECT_PROFILE_QUERY = "SELECT * FROM public.profiles WHERE id = $1"

COMPLETE_ONBOARDING_QUERY = """
UPDATE public.profiles
SET survey_completed = $2,
    onboarding_responses = $3,
    updated_at = NOW()
WHERE id = $1
RETURNING *
"""


@pytest.mark.asyncio
async def test_mock_database_upsert_and_fetch_profile() -> None:
    settings = Settings(database_url=None)
    database = Database(settings=settings)
    user_id = uuid.uuid4()

    await database.execute(INSERT_PROFILE_QUERY, user_id, "user@example.com", "Test User")
    record = await database.fetchrow(SELECT_PROFILE_QUERY, user_id)

    assert record is not None
    assert record["email"] == "user@example.com"
    assert record["full_name"] == "Test User"
    assert record["survey_completed"] is False


@pytest.mark.asyncio
async def test_mock_database_updates_onboarding_fields() -> None:
    settings = Settings(database_url=None)
    database = Database(settings=settings)
    user_id = uuid.uuid4()

    await database.execute(INSERT_PROFILE_QUERY, user_id, "user@example.com", "Test User")
    await database.fetchrow(COMPLETE_ONBOARDING_QUERY, user_id, True, {"step": "done"})

    record = await database.fetchrow(SELECT_PROFILE_QUERY, user_id)
    assert record is not None
    assert record["survey_completed"] is True
    assert record["onboarding_responses"] == {"step": "done"}


@pytest.mark.asyncio
async def test_supabase_rest_upsert_uses_on_conflict(monkeypatch: pytest.MonkeyPatch) -> None:
    settings = Settings(
        supabase_service_role_key="service-role-test",
        database_url=None,
    )
    store = _SupabaseRestStore(settings)

    calls: list[dict[str, object]] = []

    async def fake_request(
        self,
        method: str,
        resource: str,
        *,
        params: dict[str, object] | None = None,
        json_payload: object | None = None,
        prefer: str | None = None,
    ) -> list[dict[str, object]]:
        calls.append(
            {
                "method": method,
                "resource": resource,
                "params": params,
                "json_payload": json_payload,
                "prefer": prefer,
            }
        )
        if method == "GET":
            return []
        return []

    monkeypatch.setattr(
        store,
        "_request",
        types.MethodType(fake_request, store),
    )

    user_id = uuid.uuid4()
    await store._upsert_profile(INSERT_PROFILE_QUERY, user_id, "user@example.com", "Test User")

    post_calls = [call for call in calls if call["method"] == "POST"]
    assert post_calls, "POST request was not recorded"
    assert post_calls[0]["params"] == {"on_conflict": "id"}
