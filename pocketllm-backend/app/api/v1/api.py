"""Version 1 API router."""

from __future__ import annotations

from fastapi import APIRouter

from .endpoints import auth, chats, default, jobs, models, providers, users

api_router = APIRouter()
api_router.include_router(default.router)
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(chats.router)
api_router.include_router(jobs.router)
api_router.include_router(providers.router)
api_router.include_router(models.router)

__all__ = ["api_router"]
