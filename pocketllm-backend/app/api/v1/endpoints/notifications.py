"""Notification center endpoints."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, status

from app.api.deps import (
    get_current_request_user,
    get_database_dependency,
    get_settings_dependency,
)
from app.schemas.auth import TokenPayload
from app.schemas.notifications import (
    Notification,
    NotificationUpdate,
)
from app.services.notifications import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=list[Notification], summary="List notifications for the current user")
async def list_notifications(
    payload: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> list[Notification]:
    service = NotificationService(settings=settings, database=database)
    return await service.list_notifications(UUID(str(payload.sub)))


@router.patch("/{notification_id}/read", response_model=Notification, summary="Mark a notification as read")
async def mark_notification_as_read(
    notification_id: UUID,
    payload: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> Notification:
    service = NotificationService(settings=settings, database=database)
    return await service.mark_notification_as_read(UUID(str(payload.sub)), notification_id)


@router.post("/mark-all-read", summary="Mark all notifications as read")
async def mark_all_notifications_as_read(
    payload: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
):
    service = NotificationService(settings=settings, database=database)
    await service.mark_all_notifications_as_read(UUID(str(payload.sub)))
    return {"message": "All notifications marked as read"}


@router.get("/unread-count", summary="Get the number of unread notifications")
async def get_unread_notification_count(
    payload: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
):
    service = NotificationService(settings=settings, database=database)
    count = await service.get_unread_notification_count(UUID(str(payload.sub)))
    return {"count": count}
