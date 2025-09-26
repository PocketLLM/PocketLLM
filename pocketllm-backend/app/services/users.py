"""User profile service."""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta
from uuid import UUID

from fastapi import HTTPException, status

from app.core.database import Database
from app.schemas.users import (
    CancelDeletionResponse,
    DeleteAccountResponse,
    OnboardingSurvey,
    UserProfile,
    UserProfileUpdate,
)

logger = logging.getLogger(__name__)


class UsersService:
    """Business logic for interacting with user profiles."""

    def __init__(self, database: Database) -> None:
        self._database = database

    async def _get_profile_record(self, user_id: UUID):
        record = await self._database.get_profile(user_id)
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
        return record

    async def get_profile(self, user_id: UUID) -> UserProfile:
        record = await self._get_profile_record(user_id)
        return UserProfile.model_validate(record)

    async def get_profile_by_id(self, user_id: UUID) -> UserProfile:
        """Fetch a profile by identifier."""

        return await self.get_profile(user_id)

    async def update_profile(self, user_id: UUID, payload: UserProfileUpdate) -> UserProfile:
        update_columns = {k: v for k, v in payload.model_dump().items() if v is not None}
        if not update_columns:
            return await self.get_profile(user_id)

        logger.debug("Updating profile", extra={"user_id": str(user_id), "fields": list(update_columns.keys())})
        record = await self._database.update_profile(user_id, update_columns)
        updated_profile = UserProfile.model_validate(record)
        logger.info(
            "Profile updated",
            extra={"user_id": str(user_id), "username": updated_profile.username},
        )
        return updated_profile

    async def complete_onboarding(self, user_id: UUID, payload: OnboardingSurvey) -> UserProfile:
        update_columns = payload.model_dump(
            exclude_none=True,
            exclude={"onboarding", "onboarding_responses"},
        )
        update_columns["survey_completed"] = payload.survey_completed
        update_columns["onboarding_responses"] = payload.resolved_onboarding_responses()
        logger.debug(
            "Completing onboarding",
            extra={
                "user_id": str(user_id),
                "survey_completed": payload.survey_completed,
                "fields": list(update_columns.keys()),
            },
        )
        record = await self._database.update_profile(user_id, update_columns)
        profile = UserProfile.model_validate(record)
        logger.info(
            "Onboarding completed",
            extra={"user_id": str(user_id), "survey_completed": profile.survey_completed},
        )
        return profile

    async def schedule_deletion(self, user_id: UUID, days_until_delete: int = 30) -> DeleteAccountResponse:
        schedule_for = datetime.now(tz=UTC) + timedelta(days=days_until_delete)
        record = await self._database.update_profile(
            user_id,
            {
                "deletion_status": "pending",
                "deletion_requested_at": datetime.now(tz=UTC).isoformat(),
                "deletion_scheduled_for": schedule_for.isoformat(),
            },
        )
        return DeleteAccountResponse(
            deletion_requested_at=record.get("deletion_requested_at"),
            deletion_scheduled_for=record.get("deletion_scheduled_for"),
        )

    async def cancel_deletion(self, user_id: UUID) -> CancelDeletionResponse:
        """Cancel a pending deletion request, if present."""

        existing = await self._get_profile_record(user_id)
        record = await self._database.update_profile(
            user_id,
            {
                "deletion_status": "active",
                "deletion_requested_at": None,
                "deletion_scheduled_for": None,
            },
        )
        return CancelDeletionResponse(
            canceled=existing["deletion_status"] == "pending",
            previous_deletion_requested_at=existing["deletion_requested_at"]
            if existing["deletion_status"] == "pending"
            else None,
            previous_deletion_scheduled_for=existing["deletion_scheduled_for"]
            if existing["deletion_status"] == "pending"
            else None,
            profile=UserProfile.model_validate(record),
        )

    async def cancel_deletion_if_pending(self, user_id: UUID) -> CancelDeletionResponse:
        """Cancel the scheduled deletion only when the account is pending deletion."""

        existing = await self._get_profile_record(user_id)
        if existing["deletion_status"] != "pending":
            return CancelDeletionResponse(
                canceled=False,
                previous_deletion_requested_at=None,
                previous_deletion_scheduled_for=None,
                profile=UserProfile.model_validate(existing),
            )

        record = await self._database.update_profile(
            user_id,
            {
                "deletion_status": "active",
                "deletion_requested_at": None,
                "deletion_scheduled_for": None,
            },
        )
        return CancelDeletionResponse(
            canceled=True,
            previous_deletion_requested_at=existing["deletion_requested_at"],
            previous_deletion_scheduled_for=existing["deletion_scheduled_for"],
            profile=UserProfile.model_validate(record),
        )


__all__ = ["UsersService"]
