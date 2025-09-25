"""User profile service."""

from __future__ import annotations

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


class UsersService:
    """Business logic for interacting with user profiles."""

    def __init__(self, database: Database) -> None:
        self._database = database

    async def _get_profile_record(self, user_id: UUID):
        record = await self._database.fetchrow(
            "SELECT * FROM public.profiles WHERE id = $1",
            user_id,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
        return record

    async def get_profile(self, user_id: UUID) -> UserProfile:
        record = await self._get_profile_record(user_id)
        return UserProfile.model_validate(dict(record))

    async def get_profile_by_id(self, user_id: UUID) -> UserProfile:
        """Fetch a profile by identifier."""

        return await self.get_profile(user_id)

    async def update_profile(self, user_id: UUID, payload: UserProfileUpdate) -> UserProfile:
        update_columns = {k: v for k, v in payload.model_dump().items() if v is not None}
        if not update_columns:
            return await self.get_profile(user_id)

        set_clauses = ", ".join(f"{column} = ${idx}" for idx, column in enumerate(update_columns, start=2))
        query = f"""
        UPDATE public.profiles
        SET {set_clauses}, updated_at = NOW()
        WHERE id = $1
        RETURNING *
        """
        values = [user_id, *update_columns.values()]
        record = await self._database.fetchrow(query, *values)
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
        return UserProfile.model_validate(dict(record))

    async def complete_onboarding(self, user_id: UUID, payload: OnboardingSurvey) -> UserProfile:
        record = await self._database.fetchrow(
            """
            UPDATE public.profiles
            SET survey_completed = $2,
                onboarding_responses = $3,
                updated_at = NOW()
            WHERE id = $1
            RETURNING *
            """,
            user_id,
            payload.survey_completed,
            payload.onboarding_responses,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
        return UserProfile.model_validate(dict(record))

    async def schedule_deletion(self, user_id: UUID, days_until_delete: int = 30) -> DeleteAccountResponse:
        schedule_for = datetime.now(tz=UTC) + timedelta(days=days_until_delete)
        record = await self._database.fetchrow(
            """
            UPDATE public.profiles
            SET deletion_status = 'pending',
                deletion_requested_at = NOW(),
                deletion_scheduled_for = $2,
                updated_at = NOW()
            WHERE id = $1
            RETURNING deletion_requested_at, deletion_scheduled_for
            """,
            user_id,
            schedule_for,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
        return DeleteAccountResponse(
            deletion_requested_at=record["deletion_requested_at"],
            deletion_scheduled_for=record["deletion_scheduled_for"],
        )

    async def cancel_deletion(self, user_id: UUID) -> CancelDeletionResponse:
        """Cancel a pending deletion request, if present."""

        existing = await self._get_profile_record(user_id)
        record = await self._database.fetchrow(
            """
            UPDATE public.profiles
            SET deletion_status = 'active',
                deletion_requested_at = NULL,
                deletion_scheduled_for = NULL,
                updated_at = NOW()
            WHERE id = $1
            RETURNING *
            """,
            user_id,
        )
        return CancelDeletionResponse(
            canceled=existing["deletion_status"] == "pending",
            previous_deletion_requested_at=existing["deletion_requested_at"]
            if existing["deletion_status"] == "pending"
            else None,
            previous_deletion_scheduled_for=existing["deletion_scheduled_for"]
            if existing["deletion_status"] == "pending"
            else None,
            profile=UserProfile.model_validate(dict(record)),
        )

    async def cancel_deletion_if_pending(self, user_id: UUID) -> CancelDeletionResponse:
        """Cancel the scheduled deletion only when the account is pending deletion."""

        existing = await self._get_profile_record(user_id)
        if existing["deletion_status"] != "pending":
            return CancelDeletionResponse(
                canceled=False,
                previous_deletion_requested_at=None,
                previous_deletion_scheduled_for=None,
                profile=UserProfile.model_validate(dict(existing)),
            )

        record = await self._database.fetchrow(
            """
            UPDATE public.profiles
            SET deletion_status = 'active',
                deletion_requested_at = NULL,
                deletion_scheduled_for = NULL,
                updated_at = NOW()
            WHERE id = $1
            RETURNING *
            """,
            user_id,
        )
        return CancelDeletionResponse(
            canceled=True,
            previous_deletion_requested_at=existing["deletion_requested_at"],
            previous_deletion_scheduled_for=existing["deletion_scheduled_for"],
            profile=UserProfile.model_validate(dict(record)),
        )


__all__ = ["UsersService"]
