"""Notification preferences domain services."""

from __future__ import annotations

from uuid import UUID

from app.core.database import Database
from app.core.config import Settings
from app.schemas.notification_preferences import (
    NotificationPreferences,
    NotificationPreferencesUpdate,
)


class NotificationPreferencesService:
    """Encapsulates notification preferences logic shared across endpoints."""

    def __init__(self, settings: Settings, database: Database) -> None:
        self._settings = settings
        self._database = database

    async def get_notification_preferences(self, user_id: UUID) -> NotificationPreferences:
        """Get notification preferences for the given user."""
        rows = await self._database.select(
            "notification_preferences",
            filters={"user_id": str(user_id)},
            limit=1,
        )
        if not rows:
            # Create default preferences if they don't exist
            return await self.create_default_notification_preferences(user_id)
        return NotificationPreferences.model_validate(rows[0])

    async def create_default_notification_preferences(
        self, user_id: UUID
    ) -> NotificationPreferences:
        """Create default notification preferences for the given user."""
        row = await self._database.insert(
            "notification_preferences",
            {"user_id": str(user_id)},
        )
        return NotificationPreferences.model_validate(row)

    async def update_notification_preferences(
        self, user_id: UUID, payload: NotificationPreferencesUpdate
    ) -> NotificationPreferences:
        """Update notification preferences for the given user."""
        row = await self._database.update(
            "notification_preferences",
            payload.model_dump(),
            filters={"user_id": str(user_id)},
        )
        return NotificationPreferences.model_validate(row[0])
