"""Invite and referral domain services."""

from __future__ import annotations

import secrets
import string
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any, Dict, Literal, Sequence
from uuid import UUID

from fastapi import HTTPException, status

from app.core.config import Settings
from app.core.database import Database
from app.schemas.auth import AuthenticatedUser
from app.schemas.referrals import (
    InviteCodeInfo,
    InviteCodeValidationResponse,
    ReferralListItem,
    ReferralListResponse,
    ReferralSendRequest,
    ReferralSendResponse,
    ReferralStats,
)


InviteApprovalMode = Literal["invite", "waitlist", "bypass"]


@dataclass(slots=True)
class InviteApprovalContext:
    """Captures how a signup request satisfied the gating rules."""

    mode: InviteApprovalMode
    invite_record: Dict[str, Any] | None = None
    application_record: Dict[str, Any] | None = None


class InviteReferralService:
    """Encapsulates invite/referral logic shared across endpoints."""

    def __init__(self, settings: Settings, database: Database) -> None:
        self._settings = settings
        self._database = database

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    async def enforce_signup_policy(self, email: str, invite_code: str | None) -> InviteApprovalContext:
        """Ensure a signup attempt is backed by a valid invite or approval."""

        normalized_email = self._normalize_email(email)
        normalized_code = invite_code.strip() if invite_code else None

        if normalized_code:
            record = await self.validate_invite_code(normalized_code, require_active=True)
            return InviteApprovalContext(mode="invite", invite_record=record)

        application = await self._get_approved_application(normalized_email)
        if application:
            return InviteApprovalContext(mode="waitlist", application_record=application)

        if self._settings.environment.lower() in {"development", "test"}:
            return InviteApprovalContext(mode="bypass")

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="An invite code or approved waitlist application is required to create an account.",
        )

    async def handle_post_signup(
        self,
        user: AuthenticatedUser,
        email: str,
        approval: InviteApprovalContext | None,
    ) -> None:
        """Apply referral metadata after Supabase has created the account."""

        if approval is None:
            return

        updates: Dict[str, Any] = {}

        if approval.mode == "invite" and approval.invite_record:
            await self._mark_invite_consumed(approval.invite_record, user.id, email)
            updates.update(
                {
                    "invite_status": "joined",
                    "referral_code": approval.invite_record["code"],
                    "referred_by": approval.invite_record.get("issued_by"),
                    "invite_approved_at": datetime.now(tz=UTC).isoformat(),
                }
            )
        elif approval.mode == "waitlist" and approval.application_record:
            await self._mark_application_converted(approval.application_record, user.id)
            updates.update(
                {
                    "waitlist_status": "approved",
                    "waitlist_metadata": approval.application_record.get("metadata") or {},
                    "waitlist_applied_at": approval.application_record.get("applied_at"),
                    "invite_status": "invited",
                }
            )
        else:
            updates["invite_status"] = "pending"

        if updates:
            await self._database.update_profile(user.id, updates)

    async def validate_invite_code(self, code: str, *, require_active: bool = False) -> Dict[str, Any]:
        """Load an invite code record and optionally ensure it is usable."""

        normalized = self._normalize_code(code)
        records = await self._database.select(
            "invite_codes",
            filters={"code": normalized},
            limit=1,
        )
        if not records:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite code not found")

        record = records[0]
        if require_active and not self._is_code_active(record):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invite code is no longer active")
        return record

    async def build_validation_response(self, code: str) -> InviteCodeValidationResponse:
        """Return a DTO describing the state of an invite code."""

        record = await self.validate_invite_code(code, require_active=False)
        info = self._map_invite_info(record)
        status_label = "active" if self._is_code_active(record) else record.get("status", "unknown")
        message = None
        if not self._is_code_active(record):
            message = "Invite code is inactive or expired."
        return InviteCodeValidationResponse(valid=message is None, status=status_label, message=message, code=info)

    async def ensure_personal_invite_code(self, user_id: UUID, *, max_uses: int = 50) -> Dict[str, Any]:
        """Ensure the given user has a personal invite code (create when missing)."""

        profile = await self._database.get_profile(user_id)
        existing_code = (profile or {}).get("invite_code")
        if existing_code:
            try:
                return await self.validate_invite_code(existing_code, require_active=False)
            except HTTPException:
                pass

        record = await self._issue_new_code(user_id=user_id, max_uses=max_uses)
        await self._database.update_profile(user_id, {"invite_code": record["code"]})
        return record

    async def send_invite(self, user_id: UUID, payload: ReferralSendRequest) -> ReferralSendResponse:
        """Create or update a referral row for the target email."""

        invite = await self.ensure_personal_invite_code(user_id)
        normalized_email = self._normalize_email(payload.email)

        metadata: Dict[str, Any] = {}
        if payload.full_name:
            metadata["full_name"] = payload.full_name
        if payload.message:
            metadata["message"] = payload.message

        data = {
            "invite_code_id": str(invite["id"]),
            "referrer_user_id": str(user_id),
            "referee_email": normalized_email,
            "status": "pending",
            "metadata": metadata,
        }

        record = await self._database.upsert(
            "referrals",
            data,
            on_conflict="invite_code_id,referee_email",
        )
        referral = record[0] if isinstance(record, list) else record
        return ReferralSendResponse(
            referral_id=UUID(referral["id"]),
            invite_code=invite["code"],
            status=referral.get("status", "pending"),
        )

    async def list_referrals(self, user_id: UUID) -> ReferralListResponse:
        """Return the caller's invite code plus referral stats."""

        invite = await self.ensure_personal_invite_code(user_id)
        rows = await self._database.select(
            "referrals",
            filters={"referrer_user_id": str(user_id)},
            order_by=[("created_at", True)],
        )

        items: list[ReferralListItem] = []
        total_joined = 0
        rewards_issued = 0

        for row in rows:
            accepted_at = row.get("accepted_at")
            status_value = row.get("status", "pending")
            reward_status = row.get("reward_status", "none")
            if status_value == "joined":
                total_joined += 1
            if reward_status in {"issued", "fulfilled"}:
                rewards_issued += 1

            items.append(
                ReferralListItem(
                    referral_id=UUID(str(row["id"])),
                    email=row["referee_email"],
                    status=status_value,
                    reward_status=reward_status,
                    created_at=self._parse_datetime(row.get("created_at")),
                    accepted_at=self._parse_datetime(accepted_at),
                )
            )

        stats = ReferralStats(
            total_sent=len(items),
            total_joined=total_joined,
            pending=len([item for item in items if item.status == "pending"]),
            rewards_issued=rewards_issued,
        )

        info = self._map_invite_info(invite)
        return ReferralListResponse(
            invite_code=info.code,
            max_uses=info.max_uses,
            uses_count=info.uses_count,
            remaining_uses=info.remaining_uses,
            referrals=items,
            stats=stats,
        )

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    async def _get_approved_application(self, email: str) -> Dict[str, Any] | None:
        records = await self._database.select(
            "referral_applications",
            filters={"email": email},
            limit=1,
        )
        if not records:
            return None
        record = records[0]
        if record.get("status") in {"approved", "invited"}:
            return record
        return None

    async def _mark_invite_consumed(
        self,
        invite_record: Dict[str, Any],
        referee_user_id: UUID,
        referee_email: str,
    ) -> None:
        invite_id = invite_record["id"]
        max_uses = invite_record.get("max_uses") or 1
        uses_count = invite_record.get("uses_count") or 0
        new_count = int(uses_count) + 1
        status_value = invite_record.get("status", "active")

        if new_count >= max_uses and status_value == "active":
            status_value = "consumed"

        await self._database.update(
            "invite_codes",
            {"uses_count": new_count, "status": status_value},
            filters={"id": str(invite_id)},
        )

        await self._mark_referral_joined(invite_record, referee_user_id, referee_email)

    async def _mark_referral_joined(
        self,
        invite_record: Dict[str, Any],
        referee_user_id: UUID,
        referee_email: str,
    ) -> None:
        normalized_email = self._normalize_email(referee_email)
        invite_id = str(invite_record["id"])
        now_iso = datetime.now(tz=UTC).isoformat()

        existing = await self._database.select(
            "referrals",
            filters={
                "invite_code_id": invite_id,
                "referee_email": normalized_email,
            },
            limit=1,
        )

        if existing:
            await self._database.update(
                "referrals",
                {
                    "status": "joined",
                    "referee_user_id": str(referee_user_id),
                    "accepted_at": now_iso,
                },
                filters={"id": str(existing[0]["id"])},
            )
            return

        await self._database.insert(
            "referrals",
            {
                "invite_code_id": invite_id,
                "referrer_user_id": invite_record.get("issued_by"),
                "referee_user_id": str(referee_user_id),
                "referee_email": normalized_email,
                "status": "joined",
                "accepted_at": now_iso,
                "metadata": {},
            },
        )

    async def _mark_application_converted(self, application: Dict[str, Any], user_id: UUID) -> None:
        await self._database.update(
            "referral_applications",
            {
                "status": "converted",
                "user_id": str(user_id),
                "processed_at": datetime.now(tz=UTC).isoformat(),
            },
            filters={"id": str(application["id"])},
        )

    async def _issue_new_code(self, *, user_id: UUID, max_uses: int) -> Dict[str, Any]:
        attempts = 0
        last_error: Exception | None = None

        while attempts < 5:
            attempts += 1
            candidate = self._generate_code()
            try:
                record = await self._database.insert(
                    "invite_codes",
                    {
                        "code": candidate,
                        "issued_by": str(user_id),
                        "max_uses": max_uses,
                        "status": "active",
                        "metadata": {"type": "personal"},
                    },
                )
                return record
            except Exception as exc:  # pragma: no cover - unique violation handled by retry
                last_error = exc

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate a unique invite code",
        ) from last_error

    def _map_invite_info(self, record: Dict[str, Any]) -> InviteCodeInfo:
        uses_count = int(record.get("uses_count") or 0)
        max_uses = int(record.get("max_uses") or 0)
        remaining = max(max_uses - uses_count, 0) if max_uses else None
        expires_at = self._parse_datetime(record.get("expires_at"))
        return InviteCodeInfo(
            id=UUID(str(record["id"])),
            code=record["code"],
            status=record.get("status", "active"),
            max_uses=max_uses or 0,
            uses_count=uses_count,
            remaining_uses=remaining,
            expires_at=expires_at,
        )

    def _is_code_active(self, record: Dict[str, Any]) -> bool:
        status_value = (record.get("status") or "active").lower()
        if status_value not in {"active"}:
            return False
        expires_at = self._parse_datetime(record.get("expires_at"))
        if expires_at and expires_at < datetime.now(tz=UTC):
            return False
        max_uses = int(record.get("max_uses") or 0)
        uses_count = int(record.get("uses_count") or 0)
        if max_uses and uses_count >= max_uses:
            return False
        return True

    def _normalize_email(self, email: str) -> str:
        return email.strip().lower()

    def _normalize_code(self, code: str) -> str:
        return code.strip().upper()

    def _generate_code(self, length: int = 8) -> str:
        alphabet = string.ascii_uppercase + string.digits
        return "".join(secrets.choice(alphabet) for _ in range(length))

    def _parse_datetime(self, value: Any) -> datetime | None:
        if not value:
            return None
        if isinstance(value, datetime):
            return value if value.tzinfo else value.replace(tzinfo=UTC)
        try:
            parsed = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=UTC)
            return parsed
        except ValueError:
            return None


__all__ = ["InviteReferralService", "InviteApprovalContext"]
