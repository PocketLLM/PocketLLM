"""User profile schemas."""

from __future__ import annotations

from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class UserProfile(BaseModel):
    """Publicly exposed profile information."""

    id: UUID
    email: EmailStr
    full_name: Optional[str] = None
    username: Optional[str] = Field(default=None, max_length=40)
    bio: Optional[str] = None
    date_of_birth: Optional[date] = None
    age: Optional[int] = Field(default=None, ge=13, le=120)
    profession: Optional[str] = None
    heard_from: Optional[str] = None
    avatar_url: Optional[str] = None
    survey_completed: bool = False
    onboarding_responses: dict | None = None
    deletion_status: str = "active"
    deletion_requested_at: datetime | None = None
    deletion_scheduled_for: datetime | None = None
    created_at: datetime
    updated_at: datetime


class UserProfileUpdate(BaseModel):
    """Payload used to update a profile."""

    full_name: Optional[str] = Field(default=None, max_length=120)
    username: Optional[str] = Field(default=None, max_length=40)
    bio: Optional[str] = Field(default=None, max_length=500)
    date_of_birth: Optional[date] = None
    age: Optional[int] = Field(default=None, ge=13, le=120)
    profession: Optional[str] = Field(default=None, max_length=120)
    heard_from: Optional[str] = Field(default=None, max_length=120)
    avatar_url: Optional[str] = None


class OnboardingSurvey(BaseModel):
    """Onboarding metadata submitted by the user."""

    survey_completed: bool = True
    onboarding_responses: dict


class DeleteAccountResponse(BaseModel):
    """Response when scheduling account deletion."""

    status: str = "pending"
    deletion_requested_at: datetime
    deletion_scheduled_for: datetime


class CancelDeletionResponse(BaseModel):
    """Response when cancelling a scheduled deletion."""

    canceled: bool
    profile: UserProfile
    previous_deletion_requested_at: datetime | None = None
    previous_deletion_scheduled_for: datetime | None = None


__all__ = [
    "UserProfile",
    "UserProfileUpdate",
    "OnboardingSurvey",
    "DeleteAccountResponse",
    "CancelDeletionResponse",
]
