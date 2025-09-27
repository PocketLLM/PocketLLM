"""Provider configuration management service."""

from __future__ import annotations

from typing import Any
from uuid import UUID

from fastapi import HTTPException, status

from app.core.config import Settings
from app.core.database import Database
from database import ProviderRecord
from app.schemas.providers import (
    ProviderActivationRequest,
    ProviderActivationResponse,
    ProviderConfiguration,
    ProviderModel,
    ProviderUpdateRequest,
)
from app.services.providers import ProviderModelCatalogue
from app.utils.security import hash_secret, mask_secret


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

    async def list_providers(self, user_id: UUID) -> list[ProviderConfiguration]:
        records = await self._fetch_provider_records(user_id)
        return [record.to_schema() for record in records]

    async def activate_provider(
        self,
        user_id: UUID,
        payload: ProviderActivationRequest,
    ) -> ProviderActivationResponse:
        api_key_hash = hash_secret(payload.api_key)
        api_key_preview = mask_secret(payload.api_key)
        provider_payload = {
            "user_id": str(user_id),
            "provider": payload.provider,
            "base_url": payload.base_url,
            "metadata": payload.metadata or {},
            "api_key_hash": api_key_hash,
            "api_key_preview": api_key_preview,
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
        updates: dict[str, Any] = {k: v for k, v in payload.model_dump().items() if v is not None}
        if "api_key" in updates:
            api_key = updates.pop("api_key")
            updates.update({"api_key_hash": hash_secret(api_key), "api_key_preview": mask_secret(api_key)})
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
    ) -> list[ProviderModel]:
        records = await self._fetch_provider_records(user_id)
        if provider is None:
            models = await self._catalogue.list_all_models(records)
        else:
            models = await self._catalogue.list_models_for_provider(provider, records)
        return self._filter_models(models, name=name, model_id=model_id, query=query)

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
        return [ProviderRecord.from_mapping(record) for record in records]


__all__ = ["ProvidersService"]
