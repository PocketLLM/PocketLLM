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
        record = await self._database.fetchrow(
            """
            INSERT INTO public.providers (user_id, provider, base_url, metadata, api_key_hash, api_key_preview, is_active)
            VALUES ($1, $2, $3, $4, $5, $6, TRUE)
            ON CONFLICT (user_id, provider) DO UPDATE SET
                base_url = EXCLUDED.base_url,
                metadata = EXCLUDED.metadata,
                api_key_hash = EXCLUDED.api_key_hash,
                api_key_preview = EXCLUDED.api_key_preview,
                is_active = TRUE,
                updated_at = NOW()
            RETURNING *
            """,
            user_id,
            payload.provider,
            payload.base_url,
            payload.metadata,
            api_key_hash,
            api_key_preview,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to save provider")
        provider = ProviderRecord.from_mapping(dict(record)).to_schema()
        return ProviderActivationResponse(provider=provider)

    async def update_provider(self, user_id: UUID, provider: str, payload: ProviderUpdateRequest) -> ProviderConfiguration:
        updates: dict[str, Any] = {k: v for k, v in payload.model_dump().items() if v is not None}
        if "api_key" in updates:
            api_key = updates.pop("api_key")
            updates.update({"api_key_hash": hash_secret(api_key), "api_key_preview": mask_secret(api_key)})
        if not updates:
            record = await self._database.fetchrow(
                "SELECT * FROM public.providers WHERE user_id = $1 AND provider = $2",
                user_id,
                provider,
            )
            if not record:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Provider not found")
            return ProviderRecord.from_mapping(dict(record)).to_schema()

        set_clause = ", ".join(f"{column} = ${idx}" for idx, column in enumerate(updates, start=3))
        query = f"""
        UPDATE public.providers
        SET {set_clause}, updated_at = NOW()
        WHERE user_id = $1 AND provider = $2
        RETURNING *
        """
        values: list[Any] = [user_id, provider, *updates.values()]
        record = await self._database.fetchrow(query, *values)
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Provider not found")
        return ProviderRecord.from_mapping(dict(record)).to_schema()

    async def deactivate_provider(self, user_id: UUID, provider: str) -> None:
        result = await self._database.execute(
            "UPDATE public.providers SET is_active = FALSE, updated_at = NOW() WHERE user_id = $1 AND provider = $2",
            user_id,
            provider,
        )
        affected = int(result.split()[-1]) if result else 0
        if affected == 0:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Provider not found")

    async def get_provider_models(
        self,
        user_id: UUID,
        provider: str | None = None,
    ) -> list[ProviderModel]:
        records = await self._fetch_provider_records(user_id)
        if provider is None:
            return await self._catalogue.list_all_models(records)
        return await self._catalogue.list_models_for_provider(provider, records)

    async def _fetch_provider_records(self, user_id: UUID) -> list[ProviderRecord]:
        records = await self._database.fetch(
            "SELECT * FROM public.providers WHERE user_id = $1 ORDER BY created_at DESC",
            user_id,
        )
        return [ProviderRecord.from_mapping(dict(record)) for record in records]


__all__ = ["ProvidersService"]
