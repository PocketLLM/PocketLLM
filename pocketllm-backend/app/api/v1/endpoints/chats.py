"""Chat endpoints."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends

from app.api.deps import (
    get_current_request_user,
    get_database_dependency,
    get_settings_dependency,
)
from app.schemas.auth import TokenPayload
from app.schemas.chats import ChatCreate, ChatSummary, ChatUpdate, ChatWithMessages, Message, MessageCreate
from app.services.chats import ChatsService

router = APIRouter(prefix="/chats", tags=["chats"])


@router.get("", response_model=list[ChatSummary], summary="Get user chats")
async def list_chats(
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
    settings=Depends(get_settings_dependency),
) -> list[ChatSummary]:
    service = ChatsService(database=database, settings=settings)
    return await service.list_chats(user.sub)


@router.post("", response_model=ChatSummary, summary="Create a new chat")
async def create_chat(
    payload: ChatCreate,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
    settings=Depends(get_settings_dependency),
) -> ChatSummary:
    service = ChatsService(database=database, settings=settings)
    return await service.create_chat(user.sub, payload)


@router.get("/{chat_id}", response_model=ChatWithMessages, summary="Get chat by ID")
async def get_chat(
    chat_id: UUID,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
    settings=Depends(get_settings_dependency),
) -> ChatWithMessages:
    service = ChatsService(database=database, settings=settings)
    return await service.get_chat(chat_id, user.sub)


@router.put("/{chat_id}", response_model=ChatSummary, summary="Update chat")
async def update_chat(
    chat_id: UUID,
    payload: ChatUpdate,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
    settings=Depends(get_settings_dependency),
) -> ChatSummary:
    service = ChatsService(database=database, settings=settings)
    return await service.update_chat(chat_id, user.sub, payload)


@router.delete("/{chat_id}", status_code=204, summary="Delete chat")
async def delete_chat(
    chat_id: UUID,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
    settings=Depends(get_settings_dependency),
) -> None:
    service = ChatsService(database=database, settings=settings)
    await service.delete_chat(chat_id, user.sub)


@router.post("/{chat_id}/messages", response_model=Message, summary="Send message")
async def create_message(
    chat_id: UUID,
    payload: MessageCreate,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
    settings=Depends(get_settings_dependency),
) -> Message:
    service = ChatsService(database=database, settings=settings)
    return await service.create_message(chat_id, user.sub, payload)


@router.get("/{chat_id}/messages", response_model=list[Message], summary="Get chat messages")
async def list_messages(
    chat_id: UUID,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
    settings=Depends(get_settings_dependency),
) -> list[Message]:
    service = ChatsService(database=database, settings=settings)
    return await service.list_messages(chat_id, user.sub)
