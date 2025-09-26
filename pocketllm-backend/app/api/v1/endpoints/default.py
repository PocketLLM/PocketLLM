"""Default endpoints for health checking."""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse, JSONResponse

from app.api.deps import get_settings_dependency
from app.core.config import Settings
from app.schemas.common import HealthResponse
from app.utils.html_templates import render_health_page, render_root_page

router = APIRouter(tags=["default"])


def _wants_html(request: Request) -> bool:
    """Determine whether the client prefers an HTML response."""

    accept_header = request.headers.get("accept", "").lower()
    return "text/html" in accept_header or "*/*" == accept_header.strip()


@router.get("/", summary="Root endpoint")
async def root(request: Request) -> JSONResponse | HTMLResponse:
    """Display a friendly landing page for the backend root endpoint."""

    if _wants_html(request):
        return HTMLResponse(content=render_root_page(), status_code=200)

    return JSONResponse({"message": "PocketLLM backend is running"})


@router.get("/health", response_model=HealthResponse, summary="Health check")
async def health(
    request: Request, settings: Settings = Depends(get_settings_dependency)
) -> HealthResponse | HTMLResponse:
    """Return health status information in JSON or HTML depending on the client."""

    payload = HealthResponse(
        status="ok", timestamp=datetime.now(tz=UTC), version=settings.version
    )

    if _wants_html(request):
        return HTMLResponse(content=render_health_page(payload), status_code=200)

    return payload
