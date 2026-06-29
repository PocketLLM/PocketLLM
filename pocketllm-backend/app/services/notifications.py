"""Notification domain services."""

from __future__ import annotations

from typing import Any
from uuid import UUID

from app.core.database import Database
from app.core.config import Settings
from app.schemas.notifications import Notification


class NotificationService:
    """Encapsulates notification logic shared across endpoints."""

    def __init__(self, settings: Settings, database: Database) -> None:
        self._settings = settings
        self._database = database

    async def list_notifications(self, user_id: UUID) -> list[Notification]:
        """List all notifications for the given user."""
        rows = await self._database.select(
            "notifications",
            filters={"user_id": str(user_id)},
            order_by=[("created_at", True)],
        )
        return [Notification.model_validate(row) for row in rows]

    async def mark_notification_as_read(
        self, user_id: UUID, notification_id: UUID
    ) -> Notification:
        """Mark a single notification as read."""
        row = await self._database.update(
            "notifications",
            {"is_read": True},
            filters={"id": str(notification_id), "user_id": str(user_id)},
        )
        return Notification.model_validate(row[0])

    async def mark_all_notifications_as_read(self, user_id: UUID) -> None:
        """Mark all notifications as read for the given user."""
        await self._database.update(
            "notifications",
            {"is_read": True},
            filters={"user_id": str(user_id)},
        )

    async def get_unread_notification_count(self, user_id: UUID) -> int:
        """Get the number of unread notifications for the given user."""
        rows = await self._database.select(
            "notifications",
            filters={"user_id": str(user_id), "is_read": False},
        )
        return len(rows)

    async def create_notification(
        self,
        user_id: UUID,
        notification_type: str,
        content_summary: str,
        entity_id: UUID | None = None,
        data: dict[str, Any] | None = None,
    ) -> None:
        """Create a new notification."""
        await self._database.insert(
            "notifications",
            {
                "user_id": str(user_id),
                "type": notification_type,
                "content_summary": content_summary,
                "entity_id": str(entity_id) if entity_id else None,
                "data": data,
            },
        )
