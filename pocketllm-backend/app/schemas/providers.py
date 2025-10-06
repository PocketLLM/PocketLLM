"""Provider configuration schemas."""

from __future__ import annotations

import json
from collections.abc import Mapping
from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, Field, model_validator


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

    @model_validator(mode="before")
    @classmethod
    def ensure_mapping(cls, data: object) -> object:
        """Coerce raw JSON strings into objects for compatibility."""

        if isinstance(data, str):
            try:
                data = json.loads(data)
            except json.JSONDecodeError as exc:  # pragma: no cover - defensive branch
                raise ValueError("Provider activation payload must be a JSON object.") from exc

        if isinstance(data, Mapping):
            # Convert arbitrary mapping implementations (e.g. FormData) to a
            # standard dictionary so that downstream validation works reliably.
            normalized: dict[str, Any] = {}
            for key, value in data.items():
                if isinstance(value, list) and len(value) == 1:
                    value = value[0]
                if isinstance(value, bytes):
                    value = value.decode()
                normalized[key] = value

            metadata = normalized.get("metadata")
            if isinstance(metadata, str):
                try:
                    normalized["metadata"] = json.loads(metadata)
                except json.JSONDecodeError as exc:
                    raise ValueError("Metadata must be a JSON object.") from exc
            return normalized

        raise ValueError("Provider activation payload must be a JSON object.")


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


class ProviderModelsResponse(BaseModel):
    """Envelope returned when listing models from configured providers."""

    models: list[ProviderModel] = Field(default_factory=list)
    message: Optional[str] = None
    configured_providers: list[str] = Field(default_factory=list)
    missing_providers: list[str] = Field(default_factory=list)


__all__ = [
    "ProviderModel",
    "ProviderConfiguration",
    "ProviderActivationRequest",
    "ProviderUpdateRequest",
    "ProviderActivationResponse",
    "ProviderStatus",
    "ProviderModelsResponse",
]
