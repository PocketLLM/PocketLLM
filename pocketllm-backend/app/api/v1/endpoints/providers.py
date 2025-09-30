"""Provider endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.api.deps import get_current_request_user, get_database_dependency, get_settings_dependency
from app.schemas.auth import TokenPayload
from app.schemas.providers import (
    ProviderActivationRequest,
    ProviderActivationResponse,
    ProviderConfiguration,
    ProviderModelsResponse,
    ProviderStatus,
    ProviderUpdateRequest,
)
from app.services.provider_configs import ProvidersService

router = APIRouter(prefix="/providers", tags=["providers"])


@router.get("", response_model=list[ProviderConfiguration], summary="List configured providers")
async def list_providers(
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> list[ProviderConfiguration]:
    service = ProvidersService(settings=settings, database=database)
    return await service.list_providers(user.sub)


@router.get("/status", response_model=list[ProviderStatus], summary="Get provider configuration status")
async def provider_status(
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> list[ProviderStatus]:
    service = ProvidersService(settings=settings, database=database)
    return await service.list_provider_statuses(user.sub)


@router.post("/activate", response_model=ProviderActivationResponse, summary="Activate provider")
async def activate_provider(
    payload: ProviderActivationRequest,
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> ProviderActivationResponse:
    service = ProvidersService(settings=settings, database=database)
    return await service.activate_provider(user.sub, payload)


@router.patch("/{provider}", response_model=ProviderConfiguration, summary="Update provider configuration")
async def update_provider(
    provider: str,
    payload: ProviderUpdateRequest,
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> ProviderConfiguration:
    service = ProvidersService(settings=settings, database=database)
    return await service.update_provider(user.sub, provider, payload)


@router.delete("/{provider}", status_code=204, summary="Deactivate provider")
async def deactivate_provider(
    provider: str,
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> None:
    service = ProvidersService(settings=settings, database=database)
    await service.deactivate_provider(user.sub, provider)


@router.get("/{provider}/models", response_model=ProviderModelsResponse, summary="List available provider models")
async def list_provider_models(
    provider: str,
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> ProviderModelsResponse:
    service = ProvidersService(settings=settings, database=database)
    return await service.get_provider_models(user.sub, provider)
