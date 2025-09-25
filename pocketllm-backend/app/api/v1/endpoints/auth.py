"""Authentication API endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials

from app.api.deps import get_database_dependency, get_settings_dependency, reusable_oauth2
from app.schemas.auth import SignInRequest, SignInResponse, SignOutResponse, SignUpRequest, SignUpResponse
from app.services.auth import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=SignUpResponse, summary="Sign up a new user")
async def sign_up(
    payload: SignUpRequest,
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> SignUpResponse:
    service = AuthService(settings=settings, database=database)
    return await service.sign_up(payload)


@router.post("/signin", response_model=SignInResponse, summary="Sign in an existing user")
async def sign_in(
    payload: SignInRequest,
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> SignInResponse:
    service = AuthService(settings=settings, database=database)
    return await service.sign_in(payload)


@router.post("/signout", response_model=SignOutResponse, summary="Sign out current user")
async def sign_out(
    credentials: HTTPAuthorizationCredentials | None = Depends(reusable_oauth2),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> SignOutResponse:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    service = AuthService(settings=settings, database=database)
    return await service.sign_out(credentials.credentials)
