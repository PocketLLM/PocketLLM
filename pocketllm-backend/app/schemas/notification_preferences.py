"""Schemas for notification preferences."""

from __future__ import annotations

from pydantic import BaseModel


class NotificationPreferences(BaseModel):
    """Canonical representation of a notification preference."""

    notify_job_status: bool
    notify_account_alerts: bool
    notify_referral_rewards: bool
    notify_product_updates: bool


class NotificationPreferencesUpdate(BaseModel):
    """Payload used to update a notification preference."""

    notify_job_status: bool | None = None
    notify_account_alerts: bool | None = None
    notify_referral_rewards: bool | None = None
    notify_product_updates: bool | None = None
