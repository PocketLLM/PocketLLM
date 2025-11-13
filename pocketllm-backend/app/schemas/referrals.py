"""Schemas for invite codes, referrals, and referral rewards."""

from __future__ import annotations

from datetime import datetime
from typing import List
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, constr


class InviteCodeValidationRequest(BaseModel):
    """Payload used to validate an invite/referral code."""

    code: constr(strip_whitespace=True, min_length=5)  # type: ignore[valid-type]


class InviteCodeInfo(BaseModel):
    """Canonical representation of an invite code."""

    id: UUID
    code: str
    status: str
    max_uses: int
    uses_count: int
    remaining_uses: int | None = None
    expires_at: datetime | None = None


class InviteCodeValidationResponse(BaseModel):
    """Response after validating an invite code."""

    valid: bool = True
    status: str
    message: str | None = None
    code: InviteCodeInfo


class ReferralSendRequest(BaseModel):
    """Request body for issuing a new invite/referral."""

    email: EmailStr
    full_name: str | None = Field(default=None, max_length=120)
    message: str | None = Field(default=None, max_length=500)


class ReferralSendResponse(BaseModel):
    """Response payload after sending an invite."""

    referral_id: UUID
    invite_code: str
    status: str


class ReferralListItem(BaseModel):
    """Individual referral detail exposed to the client."""

    referral_id: UUID
    email: EmailStr
    status: str
    reward_status: str
    created_at: datetime
    accepted_at: datetime | None = None
    full_name: str | None = Field(default=None, max_length=120)
    message: str | None = Field(default=None, max_length=500)


class ReferralStats(BaseModel):
    """Aggregate stats for a referrer."""

    total_sent: int = 0
    total_joined: int = 0
    pending: int = 0
    rewards_issued: int = 0


class ReferralListResponse(BaseModel):
    """Envelope returned by `/v1/referral/list`."""

    invite_code: str
    max_uses: int
    uses_count: int
    remaining_uses: int | None = None
    invite_link: str | None = None
    share_message: str | None = None
    referrals: List[ReferralListItem] = Field(default_factory=list)
    stats: ReferralStats = Field(default_factory=ReferralStats)


__all__ = [
    "InviteCodeValidationRequest",
    "InviteCodeValidationResponse",
    "InviteCodeInfo",
    "ReferralSendRequest",
    "ReferralSendResponse",
    "ReferralListItem",
    "ReferralStats",
    "ReferralListResponse",
]
