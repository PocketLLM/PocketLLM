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
    invite_code: Optional[str] = None
    referral_code: Optional[str] = None
    referred_by: Optional[UUID] = None
    invite_status: str = "pending"
    waitlist_status: str = "pending"
    waitlist_metadata: dict | None = None
    waitlist_applied_at: datetime | None = None
    invite_approved_at: datetime | None = None
    survey_completed: bool = False
    onboarding_responses: dict | None = None
    preferences: dict | None = None
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
    preferences: dict | None = None


class OnboardingDetails(BaseModel):
    """Structured answers captured during onboarding."""

    primary_goal: Optional[str] = None
    interests: list[str] | None = None
    experience_level: Optional[str] = None
    usage_frequency: Optional[str] = None
    other_notes: Optional[str] = None


class OnboardingSurvey(UserProfileUpdate):
    """Onboarding metadata submitted by the user."""

    survey_completed: bool = True
    onboarding: OnboardingDetails | dict | None = None
    onboarding_responses: dict | None = None

    def resolved_onboarding_responses(self) -> dict:
        """Return the onboarding answers as a serialisable dictionary."""

        if self.onboarding_responses is not None:
            return self.onboarding_responses
        if self.onboarding is None:
            return {}
        if isinstance(self.onboarding, dict):
            return self.onboarding
        return self.onboarding.model_dump(exclude_none=True)


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
