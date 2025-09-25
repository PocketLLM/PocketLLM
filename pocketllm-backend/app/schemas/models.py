"""Model configuration schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class ModelSettings(BaseModel):
    """Additional provider specific configuration."""

    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: int | None = Field(default=2048, ge=16)
    top_p: float | None = Field(default=1.0, ge=0.0, le=1.0)
    frequency_penalty: float | None = Field(default=0.0, ge=0.0, le=2.0)
    presence_penalty: float | None = Field(default=0.0, ge=0.0, le=2.0)
    system_prompt: Optional[str] = None
    metadata: dict | None = None


class ModelConfiguration(BaseModel):
    """User specific model configuration."""

    id: UUID
    user_id: UUID
    provider_id: Optional[UUID] = None
    provider: str
    name: str
    model: str
    display_name: Optional[str] = None
    description: Optional[str] = None
    is_default: bool = False
    is_active: bool = True
    settings: ModelSettings
    created_at: datetime
    updated_at: datetime


class ModelCreateRequest(BaseModel):
    """Create a custom model configuration."""

    provider: str
    model: str
    name: str
    display_name: Optional[str] = None
    description: Optional[str] = None
    settings: ModelSettings = Field(default_factory=ModelSettings)


class ModelUpdateRequest(BaseModel):
    """Update an existing model configuration."""

    name: Optional[str] = None
    display_name: Optional[str] = None
    description: Optional[str] = None
    settings: Optional[ModelSettings] = None
    is_active: Optional[bool] = None


class ModelImportRequest(BaseModel):
    """Import provider models."""

    provider: str
    models: list[str] | None = None
    sync: bool = True


class ModelDefaultRequest(BaseModel):
    """Request to mark a model as default."""

    is_default: bool = True


__all__ = [
    "ModelSettings",
    "ModelConfiguration",
    "ModelCreateRequest",
    "ModelUpdateRequest",
    "ModelImportRequest",
    "ModelDefaultRequest",
]
