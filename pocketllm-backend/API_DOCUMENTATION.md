# PocketLLM API Documentation

The FastAPI backend exposes versioned endpoints under the `/v1` prefix. All protected endpoints require a Supabase JWT access token
in the `Authorization: Bearer <token>` header.

## Authentication

### `POST /v1/auth/signup`
Register a new user through Supabase GoTrue.
- **Body:** `SignUpRequest { email, password, full_name? }`
- **Response:** `SignUpResponse { user, tokens, session?, account_status }`
  - `account_status` surfaces deletion metadata (`deletion_scheduled`, `deletion_canceled`, `previous_deletion_*`).

### `POST /v1/auth/signin`
Authenticate an existing user with email/password credentials.
- **Body:** `SignInRequest { email, password }`
- **Response:** `SignInResponse { user, tokens, session, account_status }`
  - When an account deletion was previously scheduled the backend automatically cancels it and flags `account_status.deletion_canceled = true` while preserving historical timestamps.

### `POST /v1/auth/signout`
Invalidate the current session using the provided access token.
- **Headers:** `Authorization: Bearer <access_token>`
- **Response:** `SignOutResponse`

### `POST /v1/auth/signin/magic-link`
Placeholder endpoint announcing the upcoming passwordless email flow.
- **Body:** `MagicLinkRequest { email }`
- **Response:** `AuthFeatureAvailabilityResponse { feature="magic_link", status="coming_soon", message }`

### `POST /v1/auth/signin/otp`
Placeholder endpoint for SMS one-time-passcode sign-in.
- **Body:** `PhoneOtpRequest { phone }`
- **Response:** `AuthFeatureAvailabilityResponse { feature="sms_otp", status="coming_soon", message }`

### `POST /v1/auth/signin/oauth`
Placeholder endpoint for third-party OAuth provider flows.
- **Body:** `OAuthProviderRequest { provider }`
- **Response:** `AuthFeatureAvailabilityResponse { feature="oauth:<provider>", status="coming_soon", message }`

## Users

### `GET /v1/users/profile`
Fetch the authenticated user's profile.
- **Response:** `UserProfile`

### `PUT /v1/users/profile`
Update profile attributes such as name, username, and avatar.
- **Body:** `UserProfileUpdate`
- **Response:** `UserProfile`

### `DELETE /v1/users/profile`
Schedule account deletion after a 30 day grace period.
- **Response:** `DeleteAccountResponse { status="pending", deletion_requested_at, deletion_scheduled_for }`

### `POST /v1/users/profile/deletion/cancel`
Cancel a scheduled deletion. Automatically invoked during sign-in and exposed for manual recovery.
- **Response:** `CancelDeletionResponse { canceled, profile, previous_deletion_requested_at?, previous_deletion_scheduled_for? }`

### `POST /v1/users/profile/onboarding`
Persist onboarding questionnaire results.
- **Body:** `OnboardingSurvey`
- **Response:** `UserProfile`

### `GET /v1/users/{userId}`
Fetch a profile by identifier. For security the caller must match the requested `userId`.
- **Response:** `UserProfile`

## Chats

### `GET /v1/chats`
List chats for the authenticated user.
- **Response:** `ChatSummary[]`

### `POST /v1/chats`
Create a new chat. Optionally seeds the conversation with an initial user message.
- **Body:** `ChatCreate { title?, model_config_id?, initial_message? }`
- **Response:** `ChatSummary`

### `GET /v1/chats/{chatId}`
Retrieve chat metadata along with ordered messages.
- **Response:** `ChatWithMessages`

### `PUT /v1/chats/{chatId}`
Rename a chat or change the associated model configuration.
- **Body:** `ChatUpdate`
- **Response:** `ChatSummary`

### `DELETE /v1/chats/{chatId}`
Delete a chat and cascade delete messages.

### `POST /v1/chats/{chatId}/messages`
Append a new message to a chat.
- **Body:** `MessageCreate`
- **Response:** `Message`

### `GET /v1/chats/{chatId}/messages`
List messages for a chat.
- **Response:** `Message[]`

## Jobs

### `GET /v1/jobs`
Return background jobs created by the user.
- **Response:** `Job[]`

### `POST /v1/jobs/image-generation`
Queue an image generation job.
- **Body:** `JobCreateRequest { job_type="image_generation", input_data, metadata? }`
- **Response:** `JobCreateResponse { job_id, status }`

### `GET /v1/jobs/{jobId}`
Retrieve job status and result payload.
- **Response:** `Job`

### `DELETE /v1/jobs/{jobId}`
Cancel or remove a job record.

### `POST /v1/jobs/{jobId}/retry`
Re-enqueue a failed job.
- **Response:** `JobCreateResponse`

### `GET /v1/jobs/image-generation/models`
List supported image generation models and pricing details.
- **Response:** `Array<ProviderModel>`

### `POST /v1/jobs/image-generation/estimate-cost`
Estimate the cost of an image generation job.
- **Body:** `JobEstimateRequest`
- **Response:** `JobEstimateResponse`

## Providers

### `GET /v1/providers`
List provider configurations for the current user.
- **Response:** `ProviderConfiguration[]`

### `POST /v1/providers/activate`
Activate or update a provider with credentials.
- **Body:** `ProviderActivationRequest`
- **Response:** `ProviderActivationResponse`

### `PATCH /v1/providers/{provider}`
Update provider metadata or rotate credentials.
- **Body:** `ProviderUpdateRequest`
- **Response:** `ProviderConfiguration`

### `DELETE /v1/providers/{provider}`
Deactivate a provider without removing history.

### `GET /v1/providers/{provider}/models`
Fetch provider specific model catalogue.
- **Response:** `ProviderModel[]`

## Models

### `GET /v1/models`
Aggregate model catalogues from every configured provider.
- **Response:** `ProviderModel[]`

### `GET /v1/models/saved`
List stored model configurations for the authenticated user.
- **Response:** `ModelConfiguration[]`

### `POST /v1/models/import`
Bulk import provider models.
- **Body:** `ModelImportRequest`
- **Response:** `ModelConfiguration[]`

### `GET /v1/models/{modelId}`
Retrieve model details.
- **Response:** `ModelConfiguration`

### `DELETE /v1/models/{modelId}`
Delete a saved model configuration.

### `POST /v1/models/{modelId}/default`
Mark a configuration as the default model for the user.
- **Body:** `ModelDefaultRequest`
- **Response:** `ModelConfiguration`

## Default

### `GET /`
Simple status message.

### `GET /health`
Health probe returning API version and uptime state.

Refer to [`api_structure.json`](api_structure.json) for a machine-readable representation of the routes and to the FastAPI-generated
OpenAPI specification at `/openapi.json`.
