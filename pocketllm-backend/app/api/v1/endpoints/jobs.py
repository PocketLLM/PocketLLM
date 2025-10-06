"""Job management endpoints."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends

from app.api.deps import get_current_request_user, get_database_dependency, get_settings_dependency
from app.schemas.auth import TokenPayload
from app.schemas.jobs import (
    Job,
    JobCreateRequest,
    JobCreateResponse,
    JobEstimateRequest,
    JobEstimateResponse,
)
from app.services.jobs import JobsService

router = APIRouter(prefix="/jobs", tags=["jobs"])


@router.get("", response_model=list[Job], summary="Get user jobs")
async def list_jobs(
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> list[Job]:
    service = JobsService(settings=settings, database=database)
    return await service.list_jobs(user.sub)


@router.post("/image-generation", response_model=JobCreateResponse, summary="Create image generation job")
async def create_image_job(
    payload: JobCreateRequest,
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> JobCreateResponse:
    service = JobsService(settings=settings, database=database)
    return await service.create_image_job(user.sub, payload)


@router.get("/{job_id}", response_model=Job, summary="Get job by ID")
async def get_job(
    job_id: UUID,
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> Job:
    service = JobsService(settings=settings, database=database)
    return await service.get_job(user.sub, job_id)


@router.delete("/{job_id}", status_code=204, summary="Cancel/Delete job")
async def delete_job(
    job_id: UUID,
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> None:
    service = JobsService(settings=settings, database=database)
    await service.delete_job(user.sub, job_id)


@router.post("/{job_id}/retry", response_model=JobCreateResponse, summary="Retry failed job")
async def retry_job(
    job_id: UUID,
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> JobCreateResponse:
    service = JobsService(settings=settings, database=database)
    return await service.retry_job(user.sub, job_id)


@router.get("/image-generation/models", response_model=list[dict], summary="Get available image models")
async def get_image_models(
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> list[dict]:
    service = JobsService(settings=settings, database=database)
    return await service.get_available_image_models()


@router.post("/image-generation/estimate-cost", response_model=JobEstimateResponse, summary="Estimate image generation cost")
async def estimate_cost(
    payload: JobEstimateRequest,
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> JobEstimateResponse:
    service = JobsService(settings=settings, database=database)
    return await service.estimate_image_cost(payload)
