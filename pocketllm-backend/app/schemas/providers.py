"""Provider configuration schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class ProviderModel(BaseModel):
    """Available provider model metadata."""

    provider: str
    id: str
    name: str
    description: Optional[str] = None
    context_window: int | None = None
    max_output_tokens: int | None = None
    pricing: dict | None = None
    is_active: Optional[bool] = None
    metadata: dict | None = None


class ProviderConfiguration(BaseModel):
    """Stored provider configuration without sensitive data."""

    id: UUID
    user_id: UUID
    provider: str
    display_name: Optional[str] = None
    base_url: Optional[str] = None
    metadata: dict | None = None
    api_key_preview: Optional[str] = None
    is_active: bool
    has_api_key: bool
    created_at: datetime
    updated_at: datetime


class ProviderActivationRequest(BaseModel):
    """Payload to activate a provider."""

    provider: str
    api_key: str = Field(min_length=16)
    base_url: Optional[str] = None
    metadata: dict | None = None


class ProviderUpdateRequest(BaseModel):
    """Payload to update provider configuration."""

    display_name: Optional[str] = None
    base_url: Optional[str] = None
    metadata: dict | None = None
    api_key: Optional[str] = Field(default=None, min_length=16)
    is_active: Optional[bool] = None


class ProviderActivationResponse(BaseModel):
    """Response after activating a provider."""

    provider: ProviderConfiguration


class ProviderStatus(BaseModel):
    """Status information for each supported provider."""

    provider: str
    display_name: Optional[str] = None
    configured: bool
    is_active: bool
    has_api_key: bool
    api_key_preview: Optional[str] = None
    message: str


__all__ = [
    "ProviderModel",
    "ProviderConfiguration",
    "ProviderActivationRequest",
    "ProviderUpdateRequest",
    "ProviderActivationResponse",
    "ProviderStatus",
]
