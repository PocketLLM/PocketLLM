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

        await self._upsert_application_record(payload, normalized_email, metadata)

        return WaitlistEntry.model_validate(record)

    async def _upsert_application_record(
        self,
        payload: WaitlistEntryCreate,
        normalized_email: str,
        metadata: dict[str, Any],
    ) -> None:
        cleaned_links = None
        if payload.links:
            cleaned_links = [
                link.strip()
                for link in payload.links
                if isinstance(link, str) and link.strip()
            ]

        application_payload: dict[str, Any] = {
            "email": normalized_email,
            "full_name": payload.name.strip(),
            "occupation": payload.occupation.strip() if payload.occupation else None,
            "motivation": payload.motivation.strip() if payload.motivation else None,
            "use_case": payload.use_case.strip() if payload.use_case else None,
            "links": cleaned_links,
            "source": payload.source.strip() if payload.source else None,
            "metadata": metadata,
        }

        application_existing = await self._database.select(
            "referral_applications",
            filters={"email": normalized_email},
            limit=1,
        )

        if application_existing:
            await self._database.update(
                "referral_applications",
                application_payload,
                filters={"id": str(application_existing[0]["id"])},
            )
        else:
            application_payload["status"] = "pending"
            await self._database.insert("referral_applications", application_payload)


__all__ = ["WaitlistService"]
