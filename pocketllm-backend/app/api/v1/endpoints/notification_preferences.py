"""Notification preferences endpoints."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends

from app.api.deps import (
    get_current_request_user,
    get_database_dependency,
    get_settings_dependency,
)
from app.schemas.auth import TokenPayload
from app.schemas.notification_preferences import (
    NotificationPreferences,
    NotificationPreferencesUpdate,
)
from app.services.notification_preferences import NotificationPreferencesService

router = APIRouter(prefix="/notification-preferences", tags=["notification-preferences"])


@router.get("", response_model=NotificationPreferences, summary="Get notification preferences for the current user")
async def get_notification_preferences(
    payload: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> NotificationPreferences:
    service = NotificationPreferencesService(settings=settings, database=database)
    return await service.get_notification_preferences(UUID(str(payload.sub)))


@router.put("", response_model=NotificationPreferences, summary="Update notification preferences for the current user")
async def update_notification_preferences(
    payload: NotificationPreferencesUpdate,
    user: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> NotificationPreferences:
    service = NotificationPreferencesService(settings=settings, database=database)
    return await service.update_notification_preferences(UUID(str(user.sub)), payload)
