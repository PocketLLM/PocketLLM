"""Authentication API endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials

from app.api.deps import get_database_dependency, get_settings_dependency, reusable_oauth2
from app.schemas.auth import (
    AuthFeatureAvailabilityResponse,
    MagicLinkRequest,
    OAuthProviderRequest,
    PhoneOtpRequest,
    RefreshTokenRequest,
    RefreshTokenResponse,
    SignInRequest,
    SignInResponse,
    SignOutResponse,
    SignUpRequest,
    SignUpResponse,
)
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


@router.post("/refresh", response_model=RefreshTokenResponse, summary="Refresh access token")
async def refresh_token(
    payload: RefreshTokenRequest,
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> RefreshTokenResponse:
    service = AuthService(settings=settings, database=database)
    return await service.refresh_token(payload)


@router.post(
    "/signin/magic-link",
    response_model=AuthFeatureAvailabilityResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Request a passwordless sign-in link",
)
async def request_magic_link(payload: MagicLinkRequest) -> AuthFeatureAvailabilityResponse:
    return AuthFeatureAvailabilityResponse(
        feature="magic_link",
        message="Passwordless email authentication is coming soon. Enable the beta waitlist from the dashboard to be notified.",
    )


@router.post(
    "/signin/otp",
    response_model=AuthFeatureAvailabilityResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Request an SMS OTP sign-in",
)
async def request_phone_otp(payload: PhoneOtpRequest) -> AuthFeatureAvailabilityResponse:
    return AuthFeatureAvailabilityResponse(
        feature="sms_otp",
        message="SMS based sign-in is coming soon. Configure your Twilio credentials in Supabase to unlock early access.",
    )


@router.post(
    "/signin/oauth",
    response_model=AuthFeatureAvailabilityResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Initiate an OAuth sign-in flow",
)
async def initiate_oauth_sign_in(payload: OAuthProviderRequest) -> AuthFeatureAvailabilityResponse:
    provider = payload.provider.lower()
    return AuthFeatureAvailabilityResponse(
        feature=f"oauth:{provider}",
        message=(
            "Third-party OAuth sign-in is coming soon. Configure the provider in Supabase Auth settings to receive launch updates."
        ),
    )
