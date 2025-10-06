"""Model configuration service."""

from __future__ import annotations

from uuid import UUID

from fastapi import HTTPException, status

from app.core.database import Database
from database import ModelConfigRecord
from app.schemas.models import (
    ModelConfiguration,
    ModelDefaultRequest,
    ModelImportRequest,
    ModelSettings,
)


class ModelsService:
    """Persist model configurations tied to a user."""

    def __init__(self, database: Database) -> None:
        self._database = database

    async def list_models(self, user_id: UUID) -> list[ModelConfiguration]:
        records = await self._database.select(
            "model_configs",
            filters={"user_id": str(user_id)},
            order_by=[("created_at", True)],
        )
        return [self._record_to_model(record) for record in records]

    async def get_model(self, user_id: UUID, model_id: UUID) -> ModelConfiguration:
        records = await self._database.select(
            "model_configs",
            filters={"user_id": str(user_id), "id": str(model_id)},
            limit=1,
        )
        if not records:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Model not found")
        return self._record_to_model(records[0])

    async def delete_model(self, user_id: UUID, model_id: UUID) -> None:
        deleted = await self._database.delete(
            "model_configs",
            filters={"user_id": str(user_id), "id": str(model_id)},
        )
        if not deleted:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Model not found")

    async def import_models(self, user_id: UUID, payload: ModelImportRequest) -> list[ModelConfiguration]:
        models = payload.models or []
        created_models: list[ModelConfiguration] = []
        for model_name in models:
            settings = ModelSettings()
            created_models.append(
                await self._insert_model_configuration(
                    user_id=user_id,
                    provider=payload.provider,
                    model=model_name,
                    name=model_name,
                    display_name=model_name.replace("-", " ").title(),
                    description=None,
                    settings=settings,
                )
            )
        return created_models

    async def set_default_model(self, user_id: UUID, model_id: UUID, payload: ModelDefaultRequest) -> ModelConfiguration:
        await self._database.update(
            "model_configs",
            {"is_default": False},
            filters={"user_id": str(user_id)},
        )
        updated = await self._database.update(
            "model_configs",
            {"is_default": payload.is_default},
            filters={"user_id": str(user_id), "id": str(model_id)},
        )
        if not updated:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Model not found")
        return self._record_to_model(updated[0])

    def _record_to_model(self, record: dict[str, object]) -> ModelConfiguration:
        data = dict(record)
        model_record = ModelConfigRecord.from_mapping(data)
        return model_record.to_schema()

    async def _insert_model_configuration(
        self,
        *,
        user_id: UUID,
        provider: str,
        model: str,
        name: str,
        display_name: str | None,
        description: str | None,
        settings: ModelSettings,
    ) -> ModelConfiguration:
        payload = {
            "user_id": str(user_id),
            "provider": provider,
            "model": model,
            "name": name,
            "display_name": display_name,
            "description": description,
            "settings": settings.model_dump(),
            "is_active": True,
        }
        records = await self._database.insert_many("model_configs", [payload])
        if not records:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create model configuration",
            )
        return self._record_to_model(records[0])


__all__ = ["ModelsService"]
