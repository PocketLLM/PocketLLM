"""User profile endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.api.deps import get_current_request_user, get_database_dependency
from app.schemas.auth import TokenPayload
from app.schemas.users import DeleteAccountResponse, OnboardingSurvey, UserProfile, UserProfileUpdate
from app.services.users import UsersService

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/profile", response_model=UserProfile, summary="Get user profile")
async def get_profile(
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> UserProfile:
    service = UsersService(database=database)
    return await service.get_profile(user.sub)


@router.put("/profile", response_model=UserProfile, summary="Update user profile")
async def update_profile(
    payload: UserProfileUpdate,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> UserProfile:
    service = UsersService(database=database)
    return await service.update_profile(user.sub, payload)


@router.delete("/profile", response_model=DeleteAccountResponse, summary="Delete user account")
async def delete_profile(
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> DeleteAccountResponse:
    service = UsersService(database=database)
    return await service.schedule_deletion(user.sub)


@router.post("/profile/onboarding", response_model=UserProfile, summary="Complete onboarding survey")
async def complete_onboarding(
    payload: OnboardingSurvey,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
) -> UserProfile:
    service = UsersService(database=database)
    return await service.complete_onboarding(user.sub, payload)
