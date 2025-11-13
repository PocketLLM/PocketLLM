import uuid
from collections import defaultdict
from datetime import UTC, datetime

import pytest
from fastapi import HTTPException

from app.core.config import Settings
from app.schemas.auth import AuthenticatedUser
from app.services.referrals import InviteApprovalContext, InviteReferralService


class FakeDatabase:
    def __init__(self, *, fail_profile_update: bool = False) -> None:
        self.tables: dict[str, list[dict[str, object]]] = defaultdict(list)
        self.profiles: dict[str, dict[str, object]] = {}
        self._fail_profile_update = fail_profile_update

    async def select(self, table: str, *, filters=None, limit=None, order_by=None):
        rows = self.tables[table]
        results = [
            row
            for row in rows
            if all(str(row.get(key)) == str(value) for key, value in (filters or {}).items())
        ]
        return results[:limit] if limit else results

    async def insert(self, table: str, data: dict[str, object]):
        record = dict(data)
        record.setdefault("id", uuid.uuid4())
        record.setdefault("created_at", datetime.now(tz=UTC))
        record.setdefault("updated_at", record["created_at"])
        record.setdefault("metadata", {})
        self.tables[table].append(record)
        return record

    async def update(self, table: str, data: dict[str, object], *, filters: dict[str, object]):
        updated: list[dict[str, object]] = []
        for row in self.tables[table]:
            if all(str(row.get(key)) == str(value) for key, value in filters.items()):
                row.update(data)
                row["updated_at"] = datetime.now(tz=UTC)
                updated.append(dict(row))
        return updated

    async def upsert(self, table: str, data: dict[str, object], *, on_conflict: str | None = None):
        filters = {column.strip(): data[column.strip()] for column in (on_conflict or "").split(",") if column.strip()}
        if filters:
            existing = await self.select(table, filters=filters, limit=1)
            if existing:
                return await self.update(table, data, filters={"id": existing[0]["id"]})
        inserted = await self.insert(table, data)
        return [inserted]

    async def update_profile(self, user_id, payload):
        if self._fail_profile_update:
            raise RuntimeError("Could not find the 'invite_status' column of 'profiles' in the schema cache")
        profile = self.profiles.get(str(user_id), {"id": str(user_id)})
        profile.update(payload)
        self.profiles[str(user_id)] = profile
        return profile

    async def get_profile(self, user_id):
        return self.profiles.get(str(user_id))


@pytest.mark.asyncio
async def test_enforce_signup_policy_allows_invite_code():
    database = FakeDatabase()
    code_id = uuid.uuid4()
    await database.insert(
        "invite_codes",
        {
            "id": code_id,
            "code": "HELLO123",
            "status": "active",
            "uses_count": 0,
            "max_uses": 5,
            "issued_by": str(uuid.uuid4()),
        },
    )
    service = InviteReferralService(settings=Settings(), database=database)

    context = await service.enforce_signup_policy("user@example.com", "hello123")

    assert context.mode == "invite"
    assert context.invite_record["id"] == code_id


@pytest.mark.asyncio
async def test_enforce_signup_policy_requires_invite_in_production():
    database = FakeDatabase()
    service = InviteReferralService(settings=Settings(environment="production"), database=database)

    with pytest.raises(HTTPException) as exc_info:
        await service.enforce_signup_policy("user@example.com", None)

    assert exc_info.value.status_code == 403


@pytest.mark.asyncio
async def test_handle_post_signup_consumes_invite_and_updates_profile():
    database = FakeDatabase()
    issuer_id = uuid.uuid4()
    invite_id = uuid.uuid4()
    invite_record = await database.insert(
        "invite_codes",
        {
            "id": invite_id,
            "code": "INVITER1",
            "status": "active",
            "uses_count": 0,
            "max_uses": 2,
            "issued_by": str(issuer_id),
        },
    )
    user_id = uuid.uuid4()
    service = InviteReferralService(settings=Settings(), database=database)
    user = AuthenticatedUser(id=user_id, email="friend@example.com", full_name="Friend")

    context = InviteApprovalContext(mode="invite", invite_record=invite_record)
    await service.handle_post_signup(user, user.email, context)

    updated_invite = database.tables["invite_codes"][0]
    assert updated_invite["uses_count"] == 1
    assert database.profiles[str(user_id)]["referral_code"] == "INVITER1"
    referrals = database.tables["referrals"]
    assert len(referrals) == 1
    assert referrals[0]["status"] == "joined"


@pytest.mark.asyncio
async def test_handle_post_signup_continues_when_profile_columns_missing():
    database = FakeDatabase(fail_profile_update=True)
    issuer_id = uuid.uuid4()
    invite_id = uuid.uuid4()
    invite_record = await database.insert(
        "invite_codes",
        {
            "id": invite_id,
            "code": "APPLY123",
            "status": "active",
            "uses_count": 0,
            "max_uses": 1,
            "issued_by": str(issuer_id),
        },
    )
    user_id = uuid.uuid4()
    service = InviteReferralService(settings=Settings(), database=database)
    user = AuthenticatedUser(id=user_id, email="friend@example.com", full_name="Friend")

    context = InviteApprovalContext(mode="invite", invite_record=invite_record)
    await service.handle_post_signup(user, user.email, context)

    # Profile update is skipped but referrals still record the join event
    assert str(user_id) not in database.profiles
    referrals = database.tables["referrals"]
    assert len(referrals) == 1
    assert referrals[0]["status"] == "joined"


@pytest.mark.asyncio
async def test_list_referrals_includes_share_link_and_metadata():
    database = FakeDatabase()
    user_id = uuid.uuid4()
    invite_id = uuid.uuid4()
    code = "SHARE42"
    await database.insert(
        "invite_codes",
        {
            "id": invite_id,
            "code": code,
            "status": "active",
            "uses_count": 1,
            "max_uses": 5,
            "issued_by": str(user_id),
        },
    )
    database.profiles[str(user_id)] = {"id": str(user_id), "invite_code": code}
    await database.insert(
        "referrals",
        {
            "invite_code_id": str(invite_id),
            "referrer_user_id": str(user_id),
            "referee_email": "friend@example.com",
            "status": "joined",
            "reward_status": "issued",
            "metadata": {"full_name": "Ana M", "message": "See you inside"},
            "accepted_at": datetime(2024, 5, 21, tzinfo=UTC),
        },
    )

    settings = Settings(referral_share_base_url="https://example.dev/download")
    service = InviteReferralService(settings=settings, database=database)

    response = await service.list_referrals(user_id)

    assert response.invite_link == "https://example.dev/download?invite_code=SHARE42"
    assert response.share_message and "SHARE42" in response.share_message
    assert response.referrals[0].full_name == "Ana M"
    assert response.referrals[0].message == "See you inside"
