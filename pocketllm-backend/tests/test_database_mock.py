"""Tests for the in-memory database fallback used in mock mode."""

from __future__ import annotations

import uuid

import pytest

from app.core.config import Settings
from app.core.database import Database


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
