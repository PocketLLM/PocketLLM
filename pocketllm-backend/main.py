"""FastAPI application entry point."""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.api import api_router
from app.core.config import get_settings
from app.core.database import close_database, connect_to_database
from app.core.logging import configure_logging
from app.core.middleware import LoggingMiddleware, RequestContextMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management."""

    settings = getattr(app.state, "settings", get_settings())
    if settings.environment.lower() == "test":
        yield
        return

    await connect_to_database()
    try:
        yield
    finally:
        await close_database()


def create_application() -> FastAPI:
    """Create and configure the FastAPI application."""

    settings = get_settings()
    configure_logging(settings)
    application = FastAPI(
        title=settings.app_name,
        version=settings.version,
        debug=settings.debug,
        lifespan=lifespan,
    )
    application.state.settings = settings

    application.add_middleware(RequestContextMiddleware)
    application.add_middleware(LoggingMiddleware)
    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.backend_cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    application.include_router(api_router, prefix=settings.api_v1_prefix)
    return application


app = create_application()
__all__ = ["app", "create_application"]
