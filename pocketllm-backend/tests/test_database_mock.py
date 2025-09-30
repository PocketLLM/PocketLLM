import types
import uuid

import types
import uuid
from datetime import datetime, timezone

import pytest

from app.core.database import Database
from app.utils.serializers import serialize_dates_for_json


class StubSupabase:
    def __init__(self) -> None:
        self.client = object()
        self.test_connection_calls = 0
        self.upsert_profile_calls: list[tuple[str, dict[str, object]]] = []
        self.update_profile_calls: list[tuple[str, dict[str, object]]] = []
        self.select_calls: list[tuple[str, object, object, object]] = []
        self.insert_calls: list[tuple[str, dict[str, object]]] = []
        self.update_calls: list[tuple[str, dict[str, object], dict[str, object]]] = []
        self.delete_calls: list[tuple[str, dict[str, object]]] = []

    def test_connection(self) -> bool:
        self.test_connection_calls += 1
        return True

    def upsert_profile(self, user_id: str, payload: dict[str, object]) -> dict[str, object]:
        serialised = serialize_dates_for_json(dict(payload))
        self.upsert_profile_calls.append((user_id, serialised))
        return {"id": user_id, **serialised}

    def get_profile(self, user_id: str) -> dict[str, object] | None:
        return {"id": user_id, "email": "user@example.com"}

    def update_profile(self, user_id: str, payload: dict[str, object]) -> dict[str, object]:
        serialised = serialize_dates_for_json(dict(payload))
        self.update_profile_calls.append((user_id, serialised))
        return {"id": user_id, **serialised}

    def select(self, table: str, **kwargs) -> list[dict[str, object]]:
        self.select_calls.append((table, kwargs.get("filters"), kwargs.get("limit"), kwargs.get("order_by")))
        return [{"id": "123"}]

    def insert(self, table: str, data: dict[str, object] | list[dict[str, object]]) -> list[dict[str, object]]:
        if isinstance(data, list):
            payloads = [serialize_dates_for_json(dict(item)) for item in data]
        else:
            payloads = [serialize_dates_for_json(dict(data))]
        self.insert_calls.append((table, payloads[0]))
        return payloads

    def update(self, table: str, data: dict[str, object], *, filters: dict[str, object]) -> list[dict[str, object]]:
        serialised_data = serialize_dates_for_json(dict(data))
        serialised_filters = serialize_dates_for_json(dict(filters))
        self.update_calls.append((table, serialised_data, serialised_filters))
        return [{**serialised_filters, **serialised_data}]

    def upsert(self, table: str, data: dict[str, object], *, on_conflict: str | None = None) -> list[dict[str, object]]:
        return [serialize_dates_for_json(dict(data))]

    def delete(self, table: str, *, filters: dict[str, object]) -> list[dict[str, object]]:
        serialised_filters = serialize_dates_for_json(dict(filters))
        self.delete_calls.append((table, serialised_filters))
        return [{"id": serialised_filters.get("id", "123")}]


@pytest.fixture()
def database(monkeypatch: pytest.MonkeyPatch) -> tuple[Database, StubSupabase]:
    stub = StubSupabase()
    settings = types.SimpleNamespace()
    db = Database(settings=settings, supabase=stub)

    async def immediate_run(self: Database, func, *args, **kwargs):
        return func(*args, **kwargs)

    monkeypatch.setattr(db, "_run", types.MethodType(immediate_run, db))
    return db, stub


@pytest.mark.asyncio
async def test_upsert_profile_invokes_supabase(database: tuple[Database, StubSupabase]) -> None:
    db, stub = database
    user_id = uuid.uuid4()

    await db.upsert_profile(user_id, {"email": "user@example.com"})

    assert stub.upsert_profile_calls
    call_user_id, payload = stub.upsert_profile_calls[0]
    assert call_user_id == str(user_id)
    assert payload["email"] == "user@example.com"


@pytest.mark.asyncio
async def test_update_profile_serialises_datetime_values(database: tuple[Database, StubSupabase]) -> None:
    db, stub = database
    user_id = uuid.uuid4()

    await db.update_profile(user_id, {"trial_ends_at": datetime(2024, 5, 17, 12, 30, tzinfo=timezone.utc)})

    assert stub.update_profile_calls
    _, payload = stub.update_profile_calls[0]
    assert isinstance(payload["trial_ends_at"], str)


@pytest.mark.asyncio
async def test_select_passes_filters(database: tuple[Database, StubSupabase]) -> None:
    db, stub = database

    await db.select("chats", filters={"user_id": uuid.uuid4()})

    assert stub.select_calls
    table, filters, _, _ = stub.select_calls[0]
    assert table == "chats"
    assert isinstance(filters, dict)


@pytest.mark.asyncio
async def test_connect_validates_connection(database: tuple[Database, StubSupabase]) -> None:
    db, stub = database

    await db.connect()

    assert stub.test_connection_calls == 1
