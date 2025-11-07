"""Service layer for waitlist operations."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status

from app.core.database import Database
from app.schemas.waitlist import WaitlistEntry, WaitlistEntryCreate


class WaitlistService:
    """Persist waitlist submissions with simple de-duplication."""

    def __init__(self, database: Database) -> None:
        self._database = database

    async def join_waitlist(self, payload: WaitlistEntryCreate) -> WaitlistEntry:
        normalized_email = payload.email.strip().lower()

        existing = await self._database.select(
            "waitlist_entries",
            filters={"email": normalized_email},
            limit=1,
        )

        metadata = payload.metadata or {}
        data: dict[str, Any] = {
            "email": normalized_email,
            "full_name": payload.name.strip(),
            "source": payload.source.strip() if payload.source else None,
            "metadata": metadata,
        }

        if existing:
            entry_id = existing[0]["id"]
            updated = await self._database.update(
                "waitlist_entries",
                data,
                filters={"id": str(entry_id)},
            )
            if not updated:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to update waitlist entry",
                )
            record = updated[0]
        else:
            record = await self._database.insert("waitlist_entries", data)

        return WaitlistEntry.model_validate(record)


__all__ = ["WaitlistService"]
