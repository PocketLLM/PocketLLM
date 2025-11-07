import json
import types
import uuid
from datetime import UTC, datetime

import httpx
import pytest
from fastapi import HTTPException

from app.schemas.chats import MessageCreate
from app.services.chats import ChatsService


class InMemoryChatDatabase:
    def __init__(self) -> None:
        self.tables: dict[str, list[dict[str, object]]] = {
            "model_configs": [],
            "providers": [],
            "chats": [],
            "messages": [],
        }

    async def select(self, table: str, *, filters=None, limit=None, order_by=None):
        rows = [
            row
            for row in self.tables.get(table, [])
            if self._matches(row, filters or {})
        ]
        if order_by:
            for order in order_by:
                key, reverse = self._parse_order(order)
                rows.sort(key=lambda item: item.get(key), reverse=reverse)
        if limit:
            rows = rows[:limit]
        return [dict(row) for row in rows]

    async def insert(self, table: str, data: dict[str, object]):
        record = dict(data)
        record.setdefault("id", uuid.uuid4())
        now = datetime.now(tz=UTC)
        record.setdefault("created_at", now)
        record.setdefault("updated_at", now)
        self.tables.setdefault(table, []).append(record)
        return dict(record)

    async def update(self, table: str, data: dict[str, object], *, filters: dict[str, object]):
        updated: list[dict[str, object]] = []
        for row in self.tables.get(table, []):
            if self._matches(row, filters):
                row.update(data)
                row["updated_at"] = datetime.now(tz=UTC)
                updated.append(dict(row))
        return updated

    async def delete(self, table: str, *, filters: dict[str, object]):
        before = len(self.tables.get(table, []))
        self.tables[table] = [
            row for row in self.tables.get(table, []) if not self._matches(row, filters)
        ]
        return [{}] if len(self.tables[table]) < before else []

    def _matches(self, row: dict[str, object], filters: dict[str, object]) -> bool:
        for key, value in filters.items():
            if str(row.get(key)) != str(value):
                return False
        return True

    def _parse_order(self, order: object) -> tuple[str, bool]:
        if isinstance(order, tuple):
            key, desc = order
            return str(key), bool(desc)
        if isinstance(order, str) and "." in order:
            key, direction = order.split(".", 1)
            return key, direction.lower() == "desc"
        return str(order), False


def _seed_database(database: InMemoryChatDatabase):
    user_id = uuid.uuid4()
    provider_id = uuid.uuid4()
    model_config_id = uuid.uuid4()
    chat_id = uuid.uuid4()

    database.tables["model_configs"].append(
        {
            "id": model_config_id,
            "user_id": user_id,
            "provider_id": provider_id,
            "provider": "openai",
            "model": "gpt-4o-mini",
            "name": "GPT-4o Mini",
            "display_name": "GPT-4o Mini",
            "description": None,
            "is_default": True,
            "is_active": True,
            "settings": {
                "temperature": 0.1,
                "max_tokens": 128,
            },
            "created_at": datetime.now(tz=UTC),
            "updated_at": datetime.now(tz=UTC),
        }
    )

    database.tables["providers"].append(
        {
            "id": provider_id,
            "user_id": user_id,
            "provider": "openai",
            "display_name": "OpenAI",
            "base_url": "https://api.openai.com/v1",
            "metadata": {},
            "api_key_hash": None,
            "api_key_preview": None,
            "api_key_encrypted": "cipher",
            "is_active": True,
            "created_at": datetime.now(tz=UTC),
            "updated_at": datetime.now(tz=UTC),
        }
    )

    database.tables["chats"].append(
        {
            "id": chat_id,
            "user_id": user_id,
            "title": "Test Chat",
            "model_config_id": model_config_id,
            "created_at": datetime.now(tz=UTC),
            "updated_at": datetime.now(tz=UTC),
        }
    )

    return chat_id, user_id


@pytest.mark.asyncio
async def test_create_message_invokes_provider(monkeypatch):
    database = InMemoryChatDatabase()
    chat_id, user_id = _seed_database(database)
    captured: dict[str, object] = {}

    async def handler(request: httpx.Request) -> httpx.Response:
        captured["url"] = str(request.url)
        captured["body"] = json.loads(request.content.decode())
        return httpx.Response(
            200,
            json={
                "choices": [
                    {
                        "message": {"content": "Assistant reply"},
                        "finish_reason": "stop",
                    }
                ],
                "usage": {"prompt_tokens": 10, "completion_tokens": 5},
            },
        )

    transport = httpx.MockTransport(handler)
    settings = types.SimpleNamespace(chat_completion_timeout_seconds=5)
    monkeypatch.setattr(
        "app.services.chats.decrypt_secret",
        lambda value, _: "sk-test",
    )

    service = ChatsService(
        database=database,
        settings=settings,
        http_transport=transport,
    )

    result = await service.create_message(
        chat_id,
        user_id,
        MessageCreate(content="Hello"),
    )

    assert result.role == "assistant"
    assert result.content == "Assistant reply"
    assert captured["body"]["messages"][-1]["content"] == "Hello"
    assert len(database.tables["messages"]) == 2


@pytest.mark.asyncio
async def test_streaming_not_supported(monkeypatch):
    database = InMemoryChatDatabase()
    chat_id, user_id = _seed_database(database)
    settings = types.SimpleNamespace()
    service = ChatsService(database=database, settings=settings)

    with pytest.raises(HTTPException) as exc:
        await service.create_message(
            chat_id,
            user_id,
            MessageCreate(content="hi", stream=True),
        )

    assert exc.value.status_code == 501
