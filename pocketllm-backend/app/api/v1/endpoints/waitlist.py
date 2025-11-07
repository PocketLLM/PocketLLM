"""Public waitlist endpoint."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.api.deps import get_database_dependency
from app.schemas.waitlist import WaitlistEntry, WaitlistEntryCreate
from app.services.waitlist import WaitlistService

router = APIRouter(prefix="/waitlist", tags=["waitlist"])


@router.post("", response_model=WaitlistEntry, status_code=201, summary="Join waitlist")
async def join_waitlist(
    payload: WaitlistEntryCreate,
    database=Depends(get_database_dependency),
) -> WaitlistEntry:
    service = WaitlistService(database=database)
    return await service.join_waitlist(payload)


__all__ = ["router"]
