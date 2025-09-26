"""Chat service for managing conversations and messages."""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID

from fastapi import HTTPException, status

from app.core.database import Database
from app.schemas.chats import ChatCreate, ChatSummary, ChatUpdate, ChatWithMessages, Message, MessageCreate


class ChatsService:
    """Encapsulates chat related persistence logic."""

    def __init__(self, database: Database) -> None:
        self._database = database

    async def list_chats(self, user_id: UUID) -> list[ChatSummary]:
        records = await self._database.select(
            "chats",
            filters={"user_id": str(user_id)},
            order_by=[("updated_at", True)],
        )
        return [ChatSummary.model_validate(record) for record in records]

    async def create_chat(self, user_id: UUID, payload: ChatCreate) -> ChatSummary:
        record = await self._database.insert(
            "chats",
            {
                "user_id": str(user_id),
                "title": payload.title,
                "model_config_id": str(payload.model_config_id) if payload.model_config_id else None,
            },
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create chat")
        chat = ChatSummary.model_validate(record)
        if payload.initial_message:
            await self.create_message(chat.id, user_id, MessageCreate(content=payload.initial_message, role="user"))
        return chat

    async def get_chat(self, chat_id: UUID, user_id: UUID) -> ChatWithMessages:
        chat_records = await self._database.select(
            "chats",
            filters={"id": str(chat_id), "user_id": str(user_id)},
            limit=1,
        )
        if not chat_records:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")
        messages = await self.list_messages(chat_id, user_id)
        return ChatWithMessages(chat=ChatSummary.model_validate(chat_records[0]), messages=messages)

    async def update_chat(self, chat_id: UUID, user_id: UUID, payload: ChatUpdate) -> ChatSummary:
        updates = {k: v for k, v in payload.model_dump().items() if v is not None}
        if not updates:
            return await self._get_chat_summary(chat_id, user_id)
        updates["updated_at"] = datetime.now(tz=UTC).isoformat()
        records = await self._database.update(
            "chats",
            updates,
            filters={"id": str(chat_id), "user_id": str(user_id)},
        )
        if not records:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")
        return ChatSummary.model_validate(records[0])

    async def delete_chat(self, chat_id: UUID, user_id: UUID) -> None:
        deleted = await self._database.delete(
            "chats",
            filters={"id": str(chat_id), "user_id": str(user_id)},
        )
        if not deleted:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")

    async def create_message(self, chat_id: UUID, user_id: UUID, payload: MessageCreate) -> Message:
        chat_records = await self._database.select(
            "chats",
            filters={"id": str(chat_id), "user_id": str(user_id)},
            limit=1,
        )
        if not chat_records:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")
        record = await self._database.insert(
            "messages",
            {
                "chat_id": str(chat_id),
                "role": payload.role,
                "content": payload.content,
                "metadata": payload.metadata or {},
            },
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to store message")
        await self._database.update(
            "chats",
            {"updated_at": datetime.now(tz=UTC).isoformat()},
            filters={"id": str(chat_id)},
        )
        return Message.model_validate(record)

    async def list_messages(self, chat_id: UUID, user_id: UUID) -> list[Message]:
        chat_records = await self._database.select(
            "chats",
            filters={"id": str(chat_id), "user_id": str(user_id)},
            limit=1,
        )
        if not chat_records:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")
        records = await self._database.select(
            "messages",
            filters={"chat_id": str(chat_id)},
            order_by=["created_at.asc"],
        )
        return [Message.model_validate(record) for record in records]

    async def _get_chat_summary(self, chat_id: UUID, user_id: UUID) -> ChatSummary:
        records = await self._database.select(
            "chats",
            filters={"id": str(chat_id), "user_id": str(user_id)},
            limit=1,
        )
        if not records:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")
        return ChatSummary.model_validate(records[0])


__all__ = ["ChatsService"]
