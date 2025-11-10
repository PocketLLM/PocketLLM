"""Authentication API endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
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
from app.schemas.referrals import InviteCodeValidationRequest, InviteCodeValidationResponse
from app.services.referrals import InviteReferralService
from app.services.auth import AuthService
from app.utils.auth_cookies import (
    clear_auth_cookies,
    get_access_token_from_request,
    get_refresh_token_from_request,
    set_auth_cookies,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=SignUpResponse, summary="Sign up a new user")
async def sign_up(
    payload: SignUpRequest,
    response: Response,
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> SignUpResponse:
    service = AuthService(settings=settings, database=database)
    result = await service.sign_up(payload)
    if result.tokens and result.session:
        set_auth_cookies(response, result.tokens, result.session, settings)
    return result


@router.post("/signin", response_model=SignInResponse, summary="Sign in an existing user")
async def sign_in(
    payload: SignInRequest,
    response: Response,
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> SignInResponse:
    service = AuthService(settings=settings, database=database)
    result = await service.sign_in(payload)
    set_auth_cookies(response, result.tokens, result.session, settings)
    return result


@router.post("/signout", response_model=SignOutResponse, summary="Sign out current user")
async def sign_out(
    request: Request,
    response: Response,
    credentials: HTTPAuthorizationCredentials | None = Depends(reusable_oauth2),
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> SignOutResponse:
    token = credentials.credentials.strip() if credentials and credentials.credentials else ""
    if not token:
        cookie_token = get_access_token_from_request(request)
        token = cookie_token or ""
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    service = AuthService(settings=settings, database=database)
    result = await service.sign_out(token)
    clear_auth_cookies(response)
    return result


@router.post("/refresh", response_model=RefreshTokenResponse, summary="Refresh access token")
async def refresh_token(
    payload: RefreshTokenRequest,
    request: Request,
    response: Response,
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> RefreshTokenResponse:
    service = AuthService(settings=settings, database=database)
    refresh_value = (payload.refresh_token or "").strip()
    if not refresh_value:
        cookie_token = get_refresh_token_from_request(request)
        if cookie_token:
            refresh_value = cookie_token
    if not refresh_value:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token required")

    refreshed = await service.refresh_token(RefreshTokenRequest(refresh_token=refresh_value))
    set_auth_cookies(response, refreshed.tokens, refreshed.session, settings)
    return refreshed


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


@router.post(
    "/validate-invite-code",
    response_model=InviteCodeValidationResponse,
    summary="Validate an invite or referral code before signup",
)
async def validate_invite_code_endpoint(
    payload: InviteCodeValidationRequest,
    settings=Depends(get_settings_dependency),
    database=Depends(get_database_dependency),
) -> InviteCodeValidationResponse:
    service = InviteReferralService(settings=settings, database=database)
    return await service.build_validation_response(payload.code)
