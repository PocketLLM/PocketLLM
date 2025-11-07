import uuid
from datetime import UTC, datetime

import pytest

from app.schemas.waitlist import WaitlistEntryCreate
from app.services.waitlist import WaitlistService


class InMemoryDatabase:
    def __init__(self) -> None:
        self.rows: list[dict[str, object]] = []

    async def select(self, table: str, *, filters=None, limit=None, order_by=None):
        matches = [
            row
            for row in self.rows
            if all(str(row.get(key)) == str(value) for key, value in (filters or {}).items())
        ]
        return matches[:limit] if limit else matches

    async def insert(self, table: str, data: dict[str, object]):
        record = dict(data)
        record["id"] = uuid.uuid4()
        record["created_at"] = datetime.now(tz=UTC)
        record["updated_at"] = record["created_at"]
        self.rows.append(record)
        return record

    async def update(self, table: str, data: dict[str, object], *, filters: dict[str, object]):
        updated: list[dict[str, object]] = []
        for row in self.rows:
            if all(str(row.get(key)) == str(value) for key, value in filters.items()):
                row.update(data)
                row["updated_at"] = datetime.now(tz=UTC)
                updated.append(dict(row))
        return updated


@pytest.mark.asyncio
async def test_join_waitlist_inserts_new_record():
    database = InMemoryDatabase()
    service = WaitlistService(database=database)

    payload = WaitlistEntryCreate(name="Jane", email="Jane@example.com", source="site")
    entry = await service.join_waitlist(payload)

    assert entry.email == "jane@example.com"
    assert entry.name == "Jane"
    assert len(database.rows) == 1


@pytest.mark.asyncio
async def test_join_waitlist_updates_existing_entry():
    database = InMemoryDatabase()
    existing = {
        "id": uuid.uuid4(),
        "email": "jane@example.com",
        "full_name": "Jane",
        "source": "site",
        "metadata": {},
        "created_at": datetime.now(tz=UTC),
        "updated_at": datetime.now(tz=UTC),
    }
    database.rows.append(existing)
    service = WaitlistService(database=database)

    payload = WaitlistEntryCreate(
        name="Jane Doe",
        email="Jane@Example.com",
        source="widget",
        metadata={"utm": "abc"},
    )
    entry = await service.join_waitlist(payload)

    assert entry.name == "Jane Doe"
    assert entry.source == "widget"
    assert len(database.rows) == 1
