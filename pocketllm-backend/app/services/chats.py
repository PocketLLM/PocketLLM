"""Chat service for managing conversations, messages, and model interactions."""

from __future__ import annotations

import logging
from dataclasses import replace
from datetime import UTC, datetime
from typing import Any, Iterable
from uuid import UUID

import httpx
from fastapi import HTTPException, status

from app.core.config import Settings
from app.core.database import Database
from app.schemas.chats import (
    ChatCreate,
    ChatSummary,
    ChatUpdate,
    ChatWithMessages,
    Message,
    MessageCreate,
)
from app.schemas.models import ModelSettings
from app.utils import decrypt_secret
from database import ModelConfigRecord, ProviderRecord

_DEFAULT_PROVIDER_BASE_URLS: dict[str, str] = {
    "openai": "https://api.openai.com/v1",
    "groq": "https://api.groq.com/openai/v1",
    "openrouter": "https://openrouter.ai/api/v1",
    "imagerouter": "https://api.imagerouter.io/v1/openai",
}


class ChatsService:
    """Encapsulates chat related persistence and provider orchestration logic."""

    def __init__(
        self,
        database: Database,
        settings: Settings,
        *,
        http_transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self._database = database
        self._settings = settings
        self._http_transport = http_transport
        self._logger = logging.getLogger("app.services.chats")
        self._request_timeout = float(
            getattr(settings, "chat_completion_timeout_seconds", 60.0)
        )

    async def list_chats(self, user_id: UUID) -> list[ChatSummary]:
        records = await self._database.select(
            "chats",
            filters={"user_id": str(user_id)},
            order_by=[("updated_at", True)],
        )
        return [ChatSummary.model_validate(record) for record in records]

    async def create_chat(self, user_id: UUID, payload: ChatCreate) -> ChatSummary:
        model_config_id = payload.model_config_id
        if model_config_id is None:
            model = await self._get_default_model_config(user_id)
            model_config_id = model.id
        else:
            await self._assert_model_config(user_id, model_config_id)

        record = await self._database.insert(
            "chats",
            {
                "user_id": str(user_id),
                "title": payload.title,
                "model_config_id": str(model_config_id),
            },
        )
        if not record:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create chat",
            )

        chat = ChatSummary.model_validate(record)
        if payload.initial_message:
            await self.create_message(
                chat.id,
                user_id,
                MessageCreate(content=payload.initial_message, role="user"),
            )
        return chat

    async def get_chat(self, chat_id: UUID, user_id: UUID) -> ChatWithMessages:
        chat_records = await self._database.select(
            "chats",
            filters={"id": str(chat_id), "user_id": str(user_id)},
            limit=1,
        )
        if not chat_records:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found"
            )
        messages = await self.list_messages(chat_id, user_id)
        return ChatWithMessages(
            chat=ChatSummary.model_validate(chat_records[0]), messages=messages
        )

    async def update_chat(
        self, chat_id: UUID, user_id: UUID, payload: ChatUpdate
    ) -> ChatSummary:
        updates = {
            k: v for k, v in payload.model_dump().items() if v is not None
        }
        if payload.model_config_id is not None:
            await self._assert_model_config(user_id, payload.model_config_id)

        if not updates:
            return await self._get_chat_summary(chat_id, user_id)

        updates["updated_at"] = datetime.now(tz=UTC).isoformat()
        records = await self._database.update(
            "chats",
            updates,
            filters={"id": str(chat_id), "user_id": str(user_id)},
        )
        if not records:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found"
            )
        return ChatSummary.model_validate(records[0])

    async def delete_chat(self, chat_id: UUID, user_id: UUID) -> None:
        deleted = await self._database.delete(
            "chats",
            filters={"id": str(chat_id), "user_id": str(user_id)},
        )
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found"
            )

    async def create_message(
        self, chat_id: UUID, user_id: UUID, payload: MessageCreate
    ) -> Message:
        if payload.stream:
            raise HTTPException(
                status_code=status.HTTP_501_NOT_IMPLEMENTED,
                detail="Streaming is not supported yet.",
            )

        chat_record = await self._get_chat_record(chat_id, user_id)
        model_config = await self._resolve_model_configuration(chat_record, user_id)
        stored_message = await self._store_message(
            chat_id, payload.role, payload.content, payload.metadata
        )
        if payload.role != "user":
            await self._touch_chat(chat_id)
            return stored_message

        system_settings = ModelSettings.model_validate(model_config.settings)
        provider_record = await self._resolve_provider_record(user_id, model_config)
        prompt_messages = await self._build_prompt_messages(
            chat_id, user_id, system_settings
        )
        assistant_message = await self._request_and_store_completion(
            chat_id,
            model_config,
            provider_record,
            prompt_messages,
        )
        await self._touch_chat(chat_id)
        return assistant_message

    async def list_messages(self, chat_id: UUID, user_id: UUID) -> list[Message]:
        chat_records = await self._database.select(
            "chats",
            filters={"id": str(chat_id), "user_id": str(user_id)},
            limit=1,
        )
        if not chat_records:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found"
            )
        records = await self._database.select(
            "messages",
            filters={"chat_id": str(chat_id)},
            order_by=["created_at.asc"],
        )
        return [Message.model_validate(record) for record in records]

    async def _get_chat_summary(
        self, chat_id: UUID, user_id: UUID
    ) -> ChatSummary:
        records = await self._database.select(
            "chats",
            filters={"id": str(chat_id), "user_id": str(user_id)},
            limit=1,
        )
        if not records:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found"
            )
        return ChatSummary.model_validate(records[0])

    async def _get_chat_record(self, chat_id: UUID, user_id: UUID) -> dict[str, Any]:
        records = await self._database.select(
            "chats",
            filters={"id": str(chat_id), "user_id": str(user_id)},
            limit=1,
        )
        if not records:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found"
            )
        return records[0]

    async def _store_message(
        self,
        chat_id: UUID,
        role: str,
        content: str,
        metadata: dict | None,
    ) -> Message:
        record = await self._database.insert(
            "messages",
            {
                "chat_id": str(chat_id),
                "role": role,
                "content": content,
                "metadata": metadata or {},
            },
        )
        if not record:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to store message",
            )
        return Message.model_validate(record)

    async def _resolve_model_configuration(
        self, chat_record: dict[str, Any], user_id: UUID
    ) -> ModelConfigRecord:
        model_config_id = chat_record.get("model_config_id")
        if model_config_id:
            return await self._fetch_model_config(user_id, UUID(str(model_config_id)))

        model = await self._get_default_model_config(user_id)
        await self._database.update(
            "chats",
            {"model_config_id": str(model.id)},
            filters={"id": str(chat_record["id"])},
        )
        return model

    async def _fetch_model_config(
        self, user_id: UUID, model_config_id: UUID
    ) -> ModelConfigRecord:
        records = await self._database.select(
            "model_configs",
            filters={"id": str(model_config_id), "user_id": str(user_id)},
            limit=1,
        )
        if not records:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Model configuration not found"
            )
        return ModelConfigRecord.from_mapping(records[0])

    async def _get_default_model_config(self, user_id: UUID) -> ModelConfigRecord:
        records = await self._database.select(
            "model_configs",
            filters={"user_id": str(user_id), "is_default": True},
            limit=1,
        )
        if not records:
            records = await self._database.select(
                "model_configs",
                filters={"user_id": str(user_id)},
                order_by=[("updated_at", True)],
                limit=1,
            )
        if not records:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Please configure at least one model before starting a chat.",
            )
        return ModelConfigRecord.from_mapping(records[0])

    async def _assert_model_config(
        self, user_id: UUID, model_config_id: UUID
    ) -> None:
        await self._fetch_model_config(user_id, model_config_id)

    async def _resolve_provider_record(
        self, user_id: UUID, model_config: ModelConfigRecord
    ) -> ProviderRecord:
        filters: dict[str, Any] = {"user_id": str(user_id)}
        if model_config.provider_id:
            filters["id"] = str(model_config.provider_id)
        else:
            filters["provider"] = model_config.provider

        records = await self._database.select(
            "providers",
            filters=filters,
            limit=1,
        )
        if not records:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Provider '{model_config.provider}' is not configured.",
            )

        provider_record = ProviderRecord.from_mapping(records[0])
        api_key = provider_record.api_key
        if not api_key and provider_record.api_key_encrypted:
            api_key = decrypt_secret(provider_record.api_key_encrypted, self._settings)
        if not api_key and provider_record.api_key_hash:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Provider '{provider_record.provider}' is missing an API key.",
            )
        return replace(provider_record, api_key=api_key)

    async def _build_prompt_messages(
        self,
        chat_id: UUID,
        user_id: UUID,
        settings: ModelSettings,
    ) -> list[dict[str, str]]:
        messages: list[dict[str, str]] = []
        if settings.system_prompt:
            messages.append({"role": "system", "content": settings.system_prompt})

        history = await self.list_messages(chat_id, user_id)
        for entry in history:
            messages.append({"role": entry.role, "content": entry.content})
        return messages

    async def _request_and_store_completion(
        self,
        chat_id: UUID,
        model_config: ModelConfigRecord,
        provider_record: ProviderRecord,
        messages: list[dict[str, str]],
    ) -> Message:
        payload = self._build_completion_payload(model_config, messages)
        response = await self._execute_completion_request(provider_record, payload)
        content, response_metadata = self._extract_completion_content(
            response, provider_record.provider, model_config.model
        )
        return await self._store_message(
            chat_id,
            "assistant",
            content,
            response_metadata,
        )

    def _build_completion_payload(
        self, model_config: ModelConfigRecord, messages: list[dict[str, str]]
    ) -> dict[str, Any]:
        settings = ModelSettings.model_validate(model_config.settings)
        payload: dict[str, Any] = {
            "model": model_config.model,
            "messages": messages,
            "temperature": settings.temperature,
        }
        if settings.max_tokens:
            payload["max_tokens"] = settings.max_tokens
        if settings.top_p is not None:
            payload["top_p"] = settings.top_p
        if settings.frequency_penalty is not None:
            payload["frequency_penalty"] = settings.frequency_penalty
        if settings.presence_penalty is not None:
            payload["presence_penalty"] = settings.presence_penalty
        if settings.metadata:
            payload.update(settings.metadata)
        return payload

    async def _execute_completion_request(
        self, provider: ProviderRecord, payload: dict[str, Any]
    ) -> dict[str, Any]:
        url = self._resolve_completion_url(provider)
        headers = self._build_provider_headers(provider)

        try:
            async with httpx.AsyncClient(
                timeout=self._request_timeout,
                transport=self._http_transport,
            ) as client:
                response = await client.post(url, headers=headers, json=payload)
        except httpx.HTTPError as exc:  # pragma: no cover - network errors
            self._logger.error("Provider request failed: %s", exc)
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Upstream provider request failed.",
            ) from exc

        if response.status_code >= 400:
            self._logger.error(
                "Provider %s responded with HTTP %s: %s",
                provider.provider,
                response.status_code,
                response.text,
            )
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Provider responded with HTTP {response.status_code}.",
            )
        return response.json()

    def _extract_completion_content(
        self, payload: dict[str, Any], provider: str, model: str
    ) -> tuple[str, dict[str, Any]]:
        choices = payload.get("choices")
        if not isinstance(choices, Iterable):
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Provider response missing choices.",
            )
        first_choice = next(iter(choices), None)
        if not isinstance(first_choice, dict):
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Provider response missing message content.",
            )
        message_payload = first_choice.get("message") or {}
        content = message_payload.get("content")
        if isinstance(content, list):
            content = "".join(
                fragment.get("text", "")
                for fragment in content
                if isinstance(fragment, dict)
            )
        if not isinstance(content, str) or not content.strip():
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Provider response missing assistant content.",
            )
        metadata = {
            "provider": provider,
            "model": model,
            "finish_reason": first_choice.get("finish_reason"),
            "usage": payload.get("usage"),
        }
        return content.strip(), metadata

    def _resolve_completion_url(self, provider: ProviderRecord) -> str:
        base_url = (
            provider.base_url
            or getattr(self._settings, f"{provider.provider.lower()}_api_base", None)
            or _DEFAULT_PROVIDER_BASE_URLS.get(provider.provider.lower())
        )
        if not base_url:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"No base URL configured for provider '{provider.provider}'.",
            )
        if base_url.lower().endswith("/chat/completions"):
            return base_url
        return f"{base_url.rstrip('/')}/chat/completions"

    def _build_provider_headers(self, provider: ProviderRecord) -> dict[str, str]:
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        if provider.api_key:
            headers["Authorization"] = f"Bearer {provider.api_key}"
        metadata = provider.metadata or {}
        extra_headers = metadata.get("headers")
        if isinstance(extra_headers, dict):
            headers.update({str(k): str(v) for k, v in extra_headers.items()})
        if provider.provider.lower() == "openrouter":
            referer = metadata.get("http_referer") or metadata.get("referer")
            title = metadata.get("x_title") or metadata.get("app_name")
            if referer:
                headers.setdefault("HTTP-Referer", str(referer))
            if title:
                headers.setdefault("X-Title", str(title))
        return headers

    async def _touch_chat(self, chat_id: UUID) -> None:
        await self._database.update(
            "chats",
            {"updated_at": datetime.now(tz=UTC).isoformat()},
            filters={"id": str(chat_id)},
        )


__all__ = ["ChatsService"]
