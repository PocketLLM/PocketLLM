"""Model configuration endpoints."""

from __future__ import annotations

from urllib.parse import parse_qs
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.api.deps import (
    get_current_request_user,
    get_database_dependency,
    get_settings_dependency,
)
from app.schemas.auth import TokenPayload
from app.schemas.models import (
    ModelConfiguration,
    ModelDefaultRequest,
    ModelImportRequest,
)
from app.schemas.providers import ProviderModelsResponse
from app.services.models import ModelsService
from app.services.provider_configs import ProvidersService

router = APIRouter(prefix="/models", tags=["models"])


@router.get("", response_model=ProviderModelsResponse, summary="List provider models")
async def list_models(
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
    provider: str | None = Query(default=None, description="Filter models by provider identifier"),
    name: str | None = Query(default=None, description="Case-insensitive substring filter applied to model names"),
    model_id: str | None = Query(default=None, description="Case-insensitive substring filter applied to model identifiers"),
    query: str | None = Query(default=None, description="Free text search across model id, name, and description"),
) -> ProviderModelsResponse:
    return await _resolve_models_response(
        user,
        settings,
        database,
        provider=provider,
        name=name,
        model_id=model_id,
        query=query,
    )


@router.get(
    "&&{filters:path}",
    response_model=ProviderModelsResponse,
    include_in_schema=False,
    summary="List provider models (legacy filter syntax)",
)
async def list_models_with_legacy_filters(
    filters: str,
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> ProviderModelsResponse:
    """Support clients that append filters using ``&&`` instead of ``?``."""

    parsed_filters = parse_qs(filters, keep_blank_values=False)

    return await _resolve_models_response(
        user,
        settings,
        database,
        provider=_first_query_value(parsed_filters, "provider"),
        name=_first_query_value(parsed_filters, "name"),
        model_id=_first_query_value(parsed_filters, "model_id"),
        query=_first_query_value(parsed_filters, "query"),
    )


@router.get("/saved", response_model=list[ModelConfiguration], summary="List saved models")
async def list_saved_models(
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> list[ModelConfiguration]:
    service = ModelsService(database=database)
    return await service.list_models(user.sub)


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


async def _resolve_models_response(
    user: TokenPayload,
    settings,
    database,
    *,
    provider: str | None = None,
    name: str | None = None,
    model_id: str | None = None,
    query: str | None = None,
) -> ProviderModelsResponse:
    service = ProvidersService(settings=settings, database=database)
    return await service.get_provider_models(
        user.sub,
        provider=provider,
        name=name,
        model_id=model_id,
        query=query,
    )


def _first_query_value(parameters: dict[str, list[str]], key: str) -> str | None:
    """Return the first non-empty value for ``key`` from parsed query parameters."""

    values = parameters.get(key)
    if not values:
        return None
    for value in values:
        candidate = value.strip()
        if candidate:
            return candidate
    return None


@router.post("/{model_id}/default", response_model=ModelConfiguration, summary="Set default model")
async def set_default_model(
    model_id: UUID,
    payload: ModelDefaultRequest,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> ModelConfiguration:
    service = ModelsService(database=database)
    return await service.set_default_model(user.sub, model_id, payload)
