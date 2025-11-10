"""Schemas for waitlist operations."""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class WaitlistEntryCreate(BaseModel):
    """Incoming payload for joining the waitlist."""

    name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    occupation: Optional[str] = Field(default=None, max_length=120)
    motivation: Optional[str] = Field(
        default=None,
        max_length=800,
        description="Why the applicant wants access to PocketLLM.",
    )
    use_case: Optional[str] = Field(
        default=None,
        max_length=800,
        description="How the applicant plans to use PocketLLM.",
    )
    links: Optional[list[str]] = Field(
        default=None,
        description="Portfolio, LinkedIn, or project links supplied by the applicant.",
    )
    source: Optional[str] = Field(
        default=None,
        max_length=120,
        description="Optional context (e.g., marketing site, onboarding) for analytics.",
    )
    metadata: dict | None = Field(
        default=None, description="Additional optional context such as UTM parameters."
    )


class WaitlistEntry(BaseModel):
    """Public waitlist record returned to clients."""

    id: UUID
    name: Optional[str] = Field(default=None, alias="full_name")
    email: EmailStr
    source: Optional[str] = None
    metadata: dict | None = None
    created_at: datetime

    model_config = ConfigDict(populate_by_name=True)


__all__ = ["WaitlistEntry", "WaitlistEntryCreate"]
