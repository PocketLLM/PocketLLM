"""Invite and referral domain services."""

from __future__ import annotations

import secrets
import string
import logging
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse
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


logger = logging.getLogger(__name__)


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
    async def enforce_signup_policy(self, email: str, invite_code: str | None) -> InviteApprovalContext | None:
        """Ensure a signup attempt is backed by a valid invite or approval."""
        normalized_email = self._normalize_email(email)
        normalized_code = self._normalize_code(invite_code) if invite_code else None

        if normalized_code:
            record = await self.validate_invite_code(normalized_code, require_active=True)
            return InviteApprovalContext(mode="invite", invite_record=record)

        if not getattr(self._settings, "invite_code_required", True):
            return None

        if self._settings.environment.lower() in {"development", "test"}:
            return None

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "message": "No invite code provided. Apply for an invite to continue.",
                "code": "invite_required",
            },
        )

    async def handle_post_signup(
        self,
        user: AuthenticatedUser,
        email: str,
        approval: InviteApprovalContext | None,
    ) -> None:
        """Apply referral metadata after Supabase has created the account."""
        if approval is None or approval.mode != "invite" or not approval.invite_record:
            return

        invite_record = approval.invite_record
        referrer_id = invite_record.get("user_id")
        if not referrer_id:
            return

        # Update the referral status
        await self._database.update(
            "referrals",
            {
                "status": "complete",
                "referred_id": str(user.id),
                "accepted_at": datetime.now(tz=UTC).isoformat(),
            },
            filters={"referrer_id": str(referrer_id), "referred_email": self._normalize_email(email)},
        )

        # Update the uses_count of the invite code
        await self._database.update(
            "user_invite_codes",
            {"uses_count": invite_record.get("uses_count", 0) + 1},
            filters={"id": invite_record["id"]},
        )
        try:
            await self._database.update_profile(
                user.id, {"referral_code": self._normalize_code(invite_record["code"])}
            )
        except Exception:
            logger.exception("Failed to update profile with referral code")

    async def validate_invite_code(self, code: str, *, require_active: bool = False) -> Dict[str, Any]:
        """Load an invite code record and optionally ensure it is usable."""
        normalized = self._normalize_code(code)
        records = await self._database.select(
            "user_invite_codes",
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
        is_active = self._is_code_active(record)
        status_label = "active" if is_active else "inactive"
        message = None
        if not is_active:
            message = "Invite code is inactive or expired."
        return InviteCodeValidationResponse(valid=is_active, status=status_label, message=message, code=info)

    async def ensure_personal_invite_code(self, user_id: UUID, *, max_uses: int = 5) -> Dict[str, Any]:
        """Ensure the given user has a personal invite code (create when missing)."""
        records = await self._database.select(
            "user_invite_codes",
            filters={"user_id": str(user_id)},
            limit=1,
        )
        if records:
            return records[0]

        return await self._issue_new_code(user_id=user_id, max_uses=max_uses)

    async def send_invite(self, user_id: UUID, payload: ReferralSendRequest) -> ReferralSendResponse:
        """Create or update a referral row for the target email."""
        invite = await self.ensure_personal_invite_code(user_id)
        normalized_email = self._normalize_email(payload.email)

        data = {
            "referrer_id": str(user_id),
            "referred_email": normalized_email,
        }

        record = await self._database.insert("referrals", data)
        return ReferralSendResponse(
            referral_id=record["id"],
            invite_code=invite["code"],
            status=record["status"],
        )

    async def list_referrals(self, user_id: UUID) -> ReferralListResponse:
        """Return the caller's invite code plus referral stats."""
        invite = await self.ensure_personal_invite_code(user_id)
        rows = await self._database.select(
            "referrals",
            filters={"referrer_id": str(user_id)},
            order_by=[("created_at", True)],
        )

        items: list[ReferralListItem] = []
        for row in rows:
            items.append(
                ReferralListItem(
                    referral_id=row["id"],
                    email=row["referred_email"],
                    status=row["status"],
                    reward_status=row["reward_status"],
                    created_at=row["created_at"],
                    accepted_at=row.get("accepted_at"),
                )
            )

        stats = ReferralStats(
            total_sent=len(items),
            total_joined=len([item for item in items if item.status == "complete"]),
            pending=len([item for item in items if item.status == "pending"]),
            rewards_issued=len([item for item in items if item.reward_status == "fulfilled"]),
        )

        invite_link = self._build_invite_link(invite["code"])
        share_message = self._compose_share_message(invite["code"], invite_link)
        return ReferralListResponse(
            invite_code=invite["code"],
            max_uses=invite["max_uses"],
            uses_count=invite["uses_count"],
            remaining_uses=invite["max_uses"] - invite["uses_count"],
            invite_link=invite_link,
            share_message=share_message,
            referrals=items,
            stats=stats,
        )

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    async def _issue_new_code(self, *, user_id: UUID, max_uses: int) -> Dict[str, Any]:
        """Generate a new unique invite code for a user."""
        attempts = 0
        last_error: Exception | None = None

        prefix = "POCKET-"
        code_length = 6

        while attempts < 5:
            attempts += 1
            random_part = "".join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(code_length))
            candidate = f"{prefix}{random_part}"

            try:
                record = await self._database.insert(
                    "user_invite_codes",
                    {
                        "user_id": str(user_id),
                        "code": candidate,
                        "max_uses": max_uses,
                        "uses_count": 0,
                    },
                )
                return record
            except Exception as exc:
                last_error = exc

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate a unique invite code",
        ) from last_error

    def _map_invite_info(self, record: Dict[str, Any]) -> InviteCodeInfo:
        uses_count = int(record.get("uses_count") or 0)
        max_uses = int(record.get("max_uses") or 0)
        remaining = max(max_uses - uses_count, 0)
        return InviteCodeInfo(
            id=UUID(str(record["id"])),
            code=record["code"],
            max_uses=max_uses,
            uses_count=uses_count,
            remaining_uses=remaining,
        )

    def _is_code_active(self, record: Dict[str, Any]) -> bool:
        """Check if an invite code is still active."""
        uses_count = record.get("uses_count", 0)
        max_uses = record.get("max_uses", 0)
        return uses_count < max_uses

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

    def _build_invite_link(self, code: str) -> str:
        raw_base = getattr(self._settings, "referral_share_base_url", None) or getattr(self._settings, "backend_base_url", "")
        base = str(raw_base)
        normalized = base.strip() or "https://pocketllm.ai/download"
        parsed = urlparse(normalized)
        query = dict(parse_qsl(parsed.query, keep_blank_values=True))
        query["invite_code"] = code
        new_query = urlencode(query)
        rebuilt = parsed._replace(query=new_query)
        return urlunparse(rebuilt)

    def _compose_share_message(self, code: str, link: str) -> str:
        app_name = getattr(self._settings, "app_name", "PocketLLM")
        return f"Join me on {app_name} with my invite code {code}: {link}"


__all__ = ["InviteReferralService", "InviteApprovalContext"]
