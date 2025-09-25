"""Model configuration service."""

from __future__ import annotations

from typing import Any
from uuid import UUID

from fastapi import HTTPException, status

from app.core.database import Database
from app.schemas.models import (
    ModelConfiguration,
    ModelCreateRequest,
    ModelDefaultRequest,
    ModelImportRequest,
    ModelSettings,
    ModelUpdateRequest,
)


class ModelsService:
    """Persist model configurations tied to a user."""

    def __init__(self, database: Database) -> None:
        self._database = database

    async def list_models(self, user_id: UUID) -> list[ModelConfiguration]:
        records = await self._database.fetch(
            "SELECT * FROM public.model_configs WHERE user_id = $1 ORDER BY created_at DESC",
            user_id,
        )
        return [self._record_to_model(record) for record in records]

    async def get_model(self, user_id: UUID, model_id: UUID) -> ModelConfiguration:
        record = await self._database.fetchrow(
            "SELECT * FROM public.model_configs WHERE user_id = $1 AND id = $2",
            user_id,
            model_id,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Model not found")
        return self._record_to_model(record)

    async def create_model(self, user_id: UUID, payload: ModelCreateRequest) -> ModelConfiguration:
        record = await self._database.fetchrow(
            """
            INSERT INTO public.model_configs (user_id, provider, model, name, display_name, description, settings)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
            """,
            user_id,
            payload.provider,
            payload.model,
            payload.name,
            payload.display_name,
            payload.description,
            payload.settings.model_dump(),
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create model configuration")
        return self._record_to_model(record)

    async def update_model(self, user_id: UUID, model_id: UUID, payload: ModelUpdateRequest) -> ModelConfiguration:
        updates: dict[str, Any] = {}
        if payload.name is not None:
            updates["name"] = payload.name
        if payload.display_name is not None:
            updates["display_name"] = payload.display_name
        if payload.description is not None:
            updates["description"] = payload.description
        if payload.is_active is not None:
            updates["is_active"] = payload.is_active
        if payload.settings is not None:
            updates["settings"] = payload.settings.model_dump()
        if not updates:
            return await self.get_model(user_id, model_id)

        set_clause = ", ".join(f"{column} = ${idx}" for idx, column in enumerate(updates, start=3))
        query = f"""
        UPDATE public.model_configs
        SET {set_clause}, updated_at = NOW()
        WHERE user_id = $1 AND id = $2
        RETURNING *
        """
        values: list[Any] = [user_id, model_id, *updates.values()]
        record = await self._database.fetchrow(query, *values)
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Model not found")
        return self._record_to_model(record)

    async def delete_model(self, user_id: UUID, model_id: UUID) -> None:
        result = await self._database.execute(
            "DELETE FROM public.model_configs WHERE user_id = $1 AND id = $2",
            user_id,
            model_id,
        )
        affected = int(result.split()[-1]) if result else 0
        if affected == 0:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Model not found")

    async def import_models(self, user_id: UUID, payload: ModelImportRequest) -> list[ModelConfiguration]:
        models = payload.models or []
        created_models: list[ModelConfiguration] = []
        for model_name in models:
            request = ModelCreateRequest(
                provider=payload.provider,
                model=model_name,
                name=model_name,
                display_name=model_name.replace("-", " ").title(),
                settings=ModelSettings(),
            )
            created_models.append(await self.create_model(user_id, request))
        return created_models

    async def set_default_model(self, user_id: UUID, model_id: UUID, payload: ModelDefaultRequest) -> ModelConfiguration:
        await self._database.execute(
            "UPDATE public.model_configs SET is_default = FALSE WHERE user_id = $1",
            user_id,
        )
        record = await self._database.fetchrow(
            """
            UPDATE public.model_configs
            SET is_default = $3,
                updated_at = NOW()
            WHERE user_id = $1 AND id = $2
            RETURNING *
            """,
            user_id,
            model_id,
            payload.is_default,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Model not found")
        return self._record_to_model(record)

    def _record_to_model(self, record: Any) -> ModelConfiguration:
        data = dict(record)
        data["settings"] = ModelSettings.model_validate(data.get("settings") or {})
        return ModelConfiguration.model_validate(data)


__all__ = ["ModelsService"]
