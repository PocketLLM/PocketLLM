"""Schemas for notifications."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel


class Notification(BaseModel):
    """Canonical representation of a notification."""

    id: UUID
    user_id: UUID
    type: str
    entity_id: UUID | None = None
    content_summary: str
    data: dict[str, Any] | None = None
    is_read: bool
    created_at: datetime


class NotificationUpdate(BaseModel):
    """Payload used to update a notification."""

    is_read: bool
