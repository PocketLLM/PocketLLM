"""Model configuration endpoints."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends

from app.api.deps import get_current_request_user, get_database_dependency
from app.schemas.auth import TokenPayload
from app.schemas.models import (
    ModelConfiguration,
    ModelCreateRequest,
    ModelDefaultRequest,
    ModelImportRequest,
    ModelUpdateRequest,
)
from app.services.models import ModelsService

router = APIRouter(prefix="/models", tags=["models"])


@router.get("", response_model=list[ModelConfiguration], summary="List saved models")
async def list_models(
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> list[ModelConfiguration]:
    service = ModelsService(database=database)
    return await service.list_models(user.sub)


@router.post("", response_model=ModelConfiguration, summary="Create model configuration")
async def create_model(
    payload: ModelCreateRequest,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> ModelConfiguration:
    service = ModelsService(database=database)
    return await service.create_model(user.sub, payload)


@router.post("/import", response_model=list[ModelConfiguration], summary="Import models from provider")
async def import_models(
    payload: ModelImportRequest,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> list[ModelConfiguration]:
    service = ModelsService(database=database)
    return await service.import_models(user.sub, payload)


@router.get("/{model_id}", response_model=ModelConfiguration, summary="Get model details")
async def get_model(
    model_id: UUID,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> ModelConfiguration:
    service = ModelsService(database=database)
    return await service.get_model(user.sub, model_id)


@router.delete("/{model_id}", status_code=204, summary="Delete model")
async def delete_model(
    model_id: UUID,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> None:
    service = ModelsService(database=database)
    await service.delete_model(user.sub, model_id)


@router.post("/{model_id}/default", response_model=ModelConfiguration, summary="Set default model")
async def set_default_model(
    model_id: UUID,
    payload: ModelDefaultRequest,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> ModelConfiguration:
    service = ModelsService(database=database)
    return await service.set_default_model(user.sub, model_id, payload)


@router.put("/{model_id}", response_model=ModelConfiguration, summary="Update model")
async def update_model(
    model_id: UUID,
    payload: ModelUpdateRequest,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> ModelConfiguration:
    service = ModelsService(database=database)
    return await service.update_model(user.sub, model_id, payload)
