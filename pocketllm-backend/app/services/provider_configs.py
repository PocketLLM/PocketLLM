"""Provider configuration management service."""

from __future__ import annotations

import logging
from dataclasses import replace
from typing import Any
from uuid import UUID

from fastapi import HTTPException, status

from app.core.config import Settings
from app.core.database import Database
from app.schemas.providers import (
    ProviderActivationRequest,
    ProviderActivationResponse,
    ProviderConfiguration,
    ProviderModel,
    ProviderModelsResponse,
    ProviderStatus,
    ProviderUpdateRequest,
)
from app.services.api_keys import APIKeyValidationService
from app.services.providers import ProviderModelCatalogue
from app.utils import decrypt_secret, encrypt_secret
from app.utils.security import hash_secret, mask_secret
from database import ProviderRecord


class ProvidersService:
    """Manage provider credentials and metadata."""

    def __init__(
        self,
        settings: Settings,
        database: Database,
        *,
        catalogue: ProviderModelCatalogue | None = None,
    ) -> None:
        self._settings = settings
        self._database = database
        self._catalogue = catalogue or ProviderModelCatalogue(settings)
        self._validator = APIKeyValidationService(settings)
        self._logger = logging.getLogger("app.services.provider_configs")

    async def list_providers(self, user_id: UUID) -> list[ProviderConfiguration]:
        records = await self._fetch_provider_records(user_id)
        return [record.to_schema() for record in records]

    async def activate_provider(
        self,
        user_id: UUID,
        payload: ProviderActivationRequest,
    ) -> ProviderActivationResponse:
        try:
            await self._validator.validate(
                payload.provider,
                payload.api_key,
                base_url=payload.base_url,
                metadata=payload.metadata,
            )
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
        except RuntimeError as exc:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc)) from exc

        api_key_hash = hash_secret(payload.api_key)
        api_key_preview = mask_secret(payload.api_key)
        api_key_encrypted = encrypt_secret(payload.api_key, self._settings)
        provider_payload = {
            "user_id": str(user_id),
            "provider": payload.provider,
            "base_url": payload.base_url,
            "metadata": payload.metadata or {},
            "api_key_hash": api_key_hash,
            "api_key_preview": api_key_preview,
            "api_key_encrypted": api_key_encrypted,
            "is_active": True,
        }
        records = await self._database.upsert(
            "providers",
            provider_payload,
            on_conflict="user_id,provider",
        )
        if not records:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to save provider")
        provider = ProviderRecord.from_mapping(records[0]).to_schema()
        return ProviderActivationResponse(provider=provider)

    async def update_provider(self, user_id: UUID, provider: str, payload: ProviderUpdateRequest) -> ProviderConfiguration:
        provided_fields = payload.model_dump(exclude_unset=True)
        updates: dict[str, Any] = {
            key: value for key, value in payload.model_dump().items() if value is not None and key != "api_key"
        }
        if "api_key" in provided_fields:
            api_key = provided_fields.get("api_key")
            if api_key is None:
                updates.update(
                    {
                        "api_key_hash": None,
                        "api_key_preview": None,
                        "api_key_encrypted": None,
                    }
                )
            else:
                try:
                    await self._validator.validate(
                        provider,
                        api_key,
                        base_url=payload.base_url,
                        metadata=payload.metadata,
                    )
                except ValueError as exc:
                    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
                except RuntimeError as exc:
                    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc)) from exc

                updates.update(
                    {
                        "api_key_hash": hash_secret(api_key),
                        "api_key_preview": mask_secret(api_key),
                        "api_key_encrypted": encrypt_secret(api_key, self._settings),
                    }
                )
        if not updates:
            records = await self._database.select(
                "providers",
                filters={"user_id": str(user_id), "provider": provider},
                limit=1,
            )
            if not records:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Provider not found")
            return ProviderRecord.from_mapping(records[0]).to_schema()

        records = await self._database.update(
            "providers",
            updates,
            filters={"user_id": str(user_id), "provider": provider},
        )
        if not records:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Provider not found")
        return ProviderRecord.from_mapping(records[0]).to_schema()

    async def deactivate_provider(self, user_id: UUID, provider: str) -> None:
        updated = await self._database.update(
            "providers",
            {"is_active": False},
            filters={"user_id": str(user_id), "provider": provider},
        )
        if not updated:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Provider not found")

    async def get_provider_models(
        self,
        user_id: UUID,
        provider: str | None = None,
        *,
        name: str | None = None,
        model_id: str | None = None,
        query: str | None = None,
    ) -> ProviderModelsResponse:
        records = await self._fetch_provider_records(user_id)
        active_configs = [record for record in records if record.is_active and record.api_key]
        active_provider_keys = {record.provider.lower(): record.provider for record in active_configs}
        configured_provider_names = [record.provider for record in active_configs]
        missing_providers = [
            provider_name
            for provider_name in _SUPPORTED_PROVIDERS
            if provider_name not in active_provider_keys
        ]

        if provider is not None:
            provider_key = provider.lower()
            active_for_provider = [
                record for record in active_configs if record.provider.lower() == provider_key
            ]
            if not active_for_provider:
                message = (
                    f"Provider '{provider}' is not configured. Add a valid API key to query models."
                )
                missing = sorted(set(missing_providers + [provider_key]))
                return ProviderModelsResponse(
                    models=[],
                    message=message,
                    configured_providers=sorted(configured_provider_names),
                    missing_providers=missing,
                )

            models = await self._catalogue.list_models_for_provider(provider, active_for_provider)
            filtered = self._filter_models(models, name=name, model_id=model_id, query=query)
            message = None
            if not filtered:
                message = (
                    "No models matched the supplied filters."
                    if models
                    else f"No models were returned by provider '{provider_key}'."
                )
            remaining_missing = [p for p in missing_providers if p != provider_key]
            return ProviderModelsResponse(
                models=filtered,
                message=message,
                configured_providers=sorted(configured_provider_names),
                missing_providers=sorted(remaining_missing),
            )

        if not active_configs:
            configured = [record.provider for record in records if record.is_active]
            message = (
                "No providers are configured with API keys. Add a provider API key to fetch models."
            )
            return ProviderModelsResponse(
                models=[],
                message=message,
                configured_providers=sorted(configured),
                missing_providers=sorted(_SUPPORTED_PROVIDERS.keys()),
            )

        models = await self._catalogue.list_all_models(active_configs)
        filtered = self._filter_models(models, name=name, model_id=model_id, query=query)
        message = None
        if not filtered:
            message = (
                "No models matched the supplied filters."
                if models
                else "No models were returned by the configured providers."
            )
        return ProviderModelsResponse(
            models=filtered,
            message=message,
            configured_providers=sorted(configured_provider_names),
            missing_providers=sorted(missing_providers),
        )

    async def list_provider_statuses(self, user_id: UUID) -> list[ProviderStatus]:
        records = await self._fetch_provider_records(user_id)
        indexed = {record.provider.lower(): record for record in records}
        statuses: list[ProviderStatus] = []
        for provider, info in _SUPPORTED_PROVIDERS.items():
            record = indexed.get(provider)
            configured = bool(record and record.is_active)
            has_key = bool(record and record.api_key)
            message: str
            if record is None:
                message = "Provider is not configured. Add an API key to enable it."
            elif not has_key:
                message = "API key missing or invalid. Update the credentials to enable this provider."
            elif not record.is_active:
                message = "Provider is disabled. Activate it to query models."
            else:
                message = "Provider is configured and ready to use."
            statuses.append(
                ProviderStatus(
                    provider=provider,
                    display_name=info["name"],
                    configured=configured,
                    is_active=bool(record and record.is_active),
                    has_api_key=has_key,
                    api_key_preview=record.api_key_preview if record else None,
                    message=message,
                )
            )
        return statuses

    def _filter_models(
        self,
        models: list[ProviderModel],
        *,
        name: str | None = None,
        model_id: str | None = None,
        query: str | None = None,
    ) -> list[ProviderModel]:
        if not any([name, model_id, query]):
            return models

        name_filter = name.lower() if name else None
        id_filter = model_id.lower() if model_id else None
        query_filter = query.lower() if query else None

        def _matches(model: ProviderModel) -> bool:
            if name_filter and name_filter not in model.name.lower():
                return False
            if id_filter and id_filter not in model.id.lower():
                return False
            if query_filter:
                haystacks = [model.name, model.id]
                if model.description:
                    haystacks.append(model.description)
                if model.metadata:
                    haystacks.append(str(model.metadata))
                if not any(query_filter in text.lower() for text in haystacks if isinstance(text, str)):
                    return False
            return True

        return [model for model in models if _matches(model)]

    async def _fetch_provider_records(self, user_id: UUID) -> list[ProviderRecord]:
        records = await self._database.select(
            "providers",
            filters={"user_id": str(user_id)},
            order_by=[("created_at", True)],
        )
        decrypted: list[ProviderRecord] = []
        for record in records:
            provider_record = ProviderRecord.from_mapping(record)
            api_key: str | None = None
            if provider_record.api_key_encrypted:
                try:
                    api_key = decrypt_secret(provider_record.api_key_encrypted, self._settings)
                except RuntimeError as exc:
                    self._logger.error(
                        "Failed to decrypt API key for provider %s: %s", provider_record.provider, exc
                    )
            decrypted.append(replace(provider_record, api_key=api_key))
        return decrypted


__all__ = ["ProvidersService"]


_SUPPORTED_PROVIDERS: dict[str, dict[str, str]] = {
    "openai": {"name": "OpenAI"},
    "groq": {"name": "Groq"},
    "openrouter": {"name": "OpenRouter"},
    "imagerouter": {"name": "ImageRouter"},
}
