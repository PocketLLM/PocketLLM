"""User profile service."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import UUID

from fastapi import HTTPException, status

from app.core.database import Database
from app.schemas.users import DeleteAccountResponse, OnboardingSurvey, UserProfile, UserProfileUpdate


class UsersService:
    """Business logic for interacting with user profiles."""

    def __init__(self, database: Database) -> None:
        self._database = database

    async def get_profile(self, user_id: UUID) -> UserProfile:
        record = await self._database.fetchrow(
            "SELECT * FROM public.profiles WHERE id = $1",
            user_id,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
        return UserProfile.model_validate(dict(record))

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
            SET deletion_status = 'scheduled',
                deletion_requested_at = NOW(),
                deletion_scheduled_for = $2,
                updated_at = NOW()
            WHERE id = $1
            RETURNING deletion_scheduled_for
            """,
            user_id,
            schedule_for,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
        return DeleteAccountResponse(deletion_scheduled_for=record["deletion_scheduled_for"])


__all__ = ["UsersService"]
