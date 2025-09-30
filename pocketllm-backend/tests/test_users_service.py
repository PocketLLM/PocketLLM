import uuid
from datetime import UTC, datetime, timedelta

import pytest

from app.schemas.users import DeleteAccountResponse
from app.services.users import UsersService


class StubDatabase:
    def __init__(self, responses):
        self._responses = list(responses)
        self.queries = []

    async def fetchrow(self, query: str, *args):
        self.queries.append((query.strip(), args))
        if not self._responses:
            return None
        return self._responses.pop(0)

    async def execute(self, query: str, *args):  # pragma: no cover - not used in these tests
        self.queries.append((query.strip(), args))
        return "EXECUTED"


@pytest.mark.asyncio
async def test_cancel_deletion_if_pending_clears_schedule():
    user_id = uuid.uuid4()
    now = datetime.now(tz=UTC)
    future = now + timedelta(days=30)

    pending_record = {
        "id": user_id,
        "email": "user@example.com",
        "full_name": None,
        "username": None,
        "bio": None,
        "date_of_birth": None,
        "age": None,
        "profession": None,
        "heard_from": None,
        "avatar_url": None,
        "survey_completed": False,
        "onboarding_responses": None,
        "deletion_status": "pending",
        "deletion_requested_at": now,
        "deletion_scheduled_for": future,
        "created_at": now,
        "updated_at": now,
    }

    updated_record = {**pending_record, "deletion_status": "active", "deletion_requested_at": None, "deletion_scheduled_for": None}

    database = StubDatabase([pending_record, updated_record])
    service = UsersService(database=database)

    response = await service.cancel_deletion_if_pending(user_id)

    assert response.canceled is True
    assert response.previous_deletion_scheduled_for == future
    assert response.previous_deletion_requested_at == now
    assert response.profile.deletion_status == "active"
    assert response.profile.deletion_scheduled_for is None


@pytest.mark.asyncio
async def test_cancel_deletion_if_pending_returns_existing_profile_when_active():
    user_id = uuid.uuid4()
    now = datetime.now(tz=UTC)
    active_record = {
        "id": user_id,
        "email": "user@example.com",
        "full_name": None,
        "username": None,
        "bio": None,
        "date_of_birth": None,
        "age": None,
        "profession": None,
        "heard_from": None,
        "avatar_url": None,
        "survey_completed": True,
        "onboarding_responses": None,
        "deletion_status": "active",
        "deletion_requested_at": None,
        "deletion_scheduled_for": None,
        "created_at": now,
        "updated_at": now,
    }

    database = StubDatabase([active_record])
    service = UsersService(database=database)

    response = await service.cancel_deletion_if_pending(user_id)

    assert response.canceled is False
    assert response.previous_deletion_scheduled_for is None
    assert response.profile.deletion_status == "active"


@pytest.mark.asyncio
async def test_schedule_deletion_marks_pending_and_returns_deadline():
    user_id = uuid.uuid4()
    now = datetime.now(tz=UTC)
    scheduled_for = now + timedelta(days=30)

    scheduled_record = {
        "deletion_requested_at": now,
        "deletion_scheduled_for": scheduled_for,
    }

    database = StubDatabase([scheduled_record])
    service = UsersService(database=database)

    response = await service.schedule_deletion(user_id)

    assert isinstance(response, DeleteAccountResponse)
    assert response.status == "pending"
    assert response.deletion_scheduled_for == scheduled_for
    assert response.deletion_requested_at == now
