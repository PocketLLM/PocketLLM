"""Chat and message schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field


MessageRole = Literal["user", "assistant", "system"]


class ChatSummary(BaseModel):
    """Metadata describing a chat thread."""

    id: UUID
    user_id: UUID
    title: str
    model_config_id: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime


class ChatCreate(BaseModel):
    """Request payload for creating a chat."""

    title: str = Field(default="Untitled chat", max_length=120)
    model_config_id: Optional[UUID] = None
    initial_message: Optional[str] = None


class ChatUpdate(BaseModel):
    """Request payload for updating chat metadata."""

    title: Optional[str] = Field(default=None, max_length=120)
    model_config_id: Optional[UUID] = None


class Message(BaseModel):
    """Chat message representation."""

    id: UUID
    chat_id: UUID
    role: MessageRole
    content: str
    metadata: dict | None = None
    created_at: datetime


class MessageCreate(BaseModel):
    """Payload for sending a new chat message."""

    role: MessageRole = "user"
    content: str = Field(min_length=1)
    metadata: dict | None = None
    stream: bool = False


class ChatWithMessages(BaseModel):
    """Chat detail including messages."""

    chat: ChatSummary
    messages: list[Message]


__all__ = [
    "MessageRole",
    "ChatSummary",
    "ChatCreate",
    "ChatUpdate",
    "Message",
    "MessageCreate",
    "ChatWithMessages",
]
