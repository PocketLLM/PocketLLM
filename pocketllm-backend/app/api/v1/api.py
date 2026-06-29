"""Version 1 API router."""

from __future__ import annotations

from fastapi import APIRouter

from .endpoints import (
    agents,
    auth,
    chats,
    default,
    jobs,
    models,
    notifications,
    notification_preferences,
    prompt_enhancer,
    providers,
    referral,
    users,
    waitlist,
)

api_router = APIRouter()
api_router.include_router(default.router)
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(chats.router)
api_router.include_router(jobs.router)
api_router.include_router(providers.router)
api_router.include_router(models.router)
api_router.include_router(waitlist.router)
api_router.include_router(referral.router)
api_router.include_router(agents.router)
api_router.include_router(prompt_enhancer.router)
api_router.include_router(notifications.router)
api_router.include_router(notification_preferences.router)

__all__ = ["api_router"]
