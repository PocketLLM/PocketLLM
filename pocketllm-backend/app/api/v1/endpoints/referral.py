"""Referral center endpoints."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, status

from app.api.deps import (
    get_current_request_user,
    get_database_dependency,
    get_settings_dependency,
)
from app.schemas.auth import TokenPayload
from app.schemas.referrals import (
    ReferralListResponse,
    ReferralSendRequest,
    ReferralSendResponse,
)
from app.services.referrals import InviteReferralService

router = APIRouter(prefix="/referral", tags=["referral"])


@router.get("/list", response_model=ReferralListResponse, summary="List referral stats for the current user")
async def list_referrals(
    payload: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> ReferralListResponse:
    service = InviteReferralService(settings=settings, database=database)
    return await service.list_referrals(UUID(str(payload.sub)))


@router.post(
    "/send",
    response_model=ReferralSendResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Issue a new invite/referral code to a teammate",
)
async def send_referral(
    request: ReferralSendRequest,
    payload: TokenPayload = Depends(get_current_request_user),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> ReferralSendResponse:
    service = InviteReferralService(settings=settings, database=database)
    return await service.send_invite(UUID(str(payload.sub)), request)


__all__ = ["router"]
