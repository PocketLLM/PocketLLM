"""Default endpoints for health checking."""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends

from app.api.deps import get_settings_dependency
from app.core.config import Settings
from app.schemas.common import HealthResponse

router = APIRouter(tags=["default"])


@router.get("/", summary="Root endpoint")
async def root() -> dict[str, str]:
    return {"message": "PocketLLM backend is running"}


@router.get("/health", response_model=HealthResponse, summary="Health check")
async def health(settings: Settings = Depends(get_settings_dependency)) -> HealthResponse:
    return HealthResponse(status="ok", timestamp=datetime.now(tz=UTC), version=settings.version)
