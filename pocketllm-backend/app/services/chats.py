"""Chat service for managing conversations and messages."""

from __future__ import annotations

from uuid import UUID

from fastapi import HTTPException, status

from app.core.database import Database
from app.schemas.chats import ChatCreate, ChatSummary, ChatUpdate, ChatWithMessages, Message, MessageCreate


class ChatsService:
    """Encapsulates chat related persistence logic."""

    def __init__(self, database: Database) -> None:
        self._database = database

    async def list_chats(self, user_id: UUID) -> list[ChatSummary]:
        records = await self._database.fetch(
            "SELECT * FROM public.chats WHERE user_id = $1 ORDER BY updated_at DESC",
            user_id,
        )
        return [ChatSummary.model_validate(dict(record)) for record in records]

    async def create_chat(self, user_id: UUID, payload: ChatCreate) -> ChatSummary:
        record = await self._database.fetchrow(
            """
            INSERT INTO public.chats (user_id, title, model_config_id)
            VALUES ($1, $2, $3)
            RETURNING *
            """,
            user_id,
            payload.title,
            payload.model_config_id,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create chat")
        chat = ChatSummary.model_validate(dict(record))
        if payload.initial_message:
            await self.create_message(chat.id, user_id, MessageCreate(content=payload.initial_message, role="user"))
        return chat

    async def get_chat(self, chat_id: UUID, user_id: UUID) -> ChatWithMessages:
        chat_record = await self._database.fetchrow(
            "SELECT * FROM public.chats WHERE id = $1 AND user_id = $2",
            chat_id,
            user_id,
        )
        if not chat_record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")
        messages = await self.list_messages(chat_id, user_id)
        return ChatWithMessages(chat=ChatSummary.model_validate(dict(chat_record)), messages=messages)

    async def update_chat(self, chat_id: UUID, user_id: UUID, payload: ChatUpdate) -> ChatSummary:
        updates = {k: v for k, v in payload.model_dump().items() if v is not None}
        if not updates:
            return await self._get_chat_summary(chat_id, user_id)
        set_clause = ", ".join(f"{column} = ${idx}" for idx, column in enumerate(updates, start=3))
        query = f"""
        UPDATE public.chats
        SET {set_clause}, updated_at = NOW()
        WHERE id = $1 AND user_id = $2
        RETURNING *
        """
        values: list[object] = [chat_id, user_id, *updates.values()]
        record = await self._database.fetchrow(query, *values)
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")
        return ChatSummary.model_validate(dict(record))

    async def delete_chat(self, chat_id: UUID, user_id: UUID) -> None:
        result = await self._database.execute(
            "DELETE FROM public.chats WHERE id = $1 AND user_id = $2",
            chat_id,
            user_id,
        )
        affected = int(result.split()[-1]) if result else 0
        if affected == 0:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")

    async def create_message(self, chat_id: UUID, user_id: UUID, payload: MessageCreate) -> Message:
        chat = await self._database.fetchrow(
            "SELECT id FROM public.chats WHERE id = $1 AND user_id = $2",
            chat_id,
            user_id,
        )
        if not chat:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")
        record = await self._database.fetchrow(
            """
            INSERT INTO public.messages (chat_id, role, content, metadata)
            VALUES ($1, $2, $3, $4)
            RETURNING *
            """,
            chat_id,
            payload.role,
            payload.content,
            payload.metadata,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to store message")
        await self._database.execute(
            "UPDATE public.chats SET updated_at = NOW() WHERE id = $1",
            chat_id,
        )
        return Message.model_validate(dict(record))

    async def list_messages(self, chat_id: UUID, user_id: UUID) -> list[Message]:
        records = await self._database.fetch(
            """
            SELECT m.*
            FROM public.messages m
            JOIN public.chats c ON c.id = m.chat_id
            WHERE m.chat_id = $1 AND c.user_id = $2
            ORDER BY m.created_at ASC
            """,
            chat_id,
            user_id,
        )
        return [Message.model_validate(dict(record)) for record in records]

    async def _get_chat_summary(self, chat_id: UUID, user_id: UUID) -> ChatSummary:
        record = await self._database.fetchrow(
            "SELECT * FROM public.chats WHERE id = $1 AND user_id = $2",
            chat_id,
            user_id,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found")
        return ChatSummary.model_validate(dict(record))


__all__ = ["ChatsService"]
