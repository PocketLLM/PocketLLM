"""Dataclasses representing rows from persistent storage."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any, Mapping
from uuid import UUID


@dataclass(frozen=True)
class ProviderRecord:
    """In-memory representation of a provider configuration row."""

    id: UUID
    user_id: UUID
    provider: str
    display_name: str | None
    base_url: str | None
    metadata: dict | None
    api_key_hash: str | None
    api_key_preview: str | None
    api_key_encrypted: str | None
    api_key: str | None = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_mapping(cls, data: Mapping[str, Any]) -> "ProviderRecord":
        return cls(
            id=data["id"],
            user_id=data["user_id"],
            provider=data["provider"],
            display_name=data.get("display_name"),
            base_url=data.get("base_url"),
            metadata=dict(data.get("metadata") or {}),
            api_key_hash=data.get("api_key_hash"),
            api_key_preview=data.get("api_key_preview"),
            api_key_encrypted=data.get("api_key_encrypted"),
            api_key=None,
            is_active=bool(data.get("is_active", False)),
            created_at=data["created_at"],
            updated_at=data["updated_at"],
        )

    def to_schema(self):  # pragma: no cover - thin wrapper
        from app.schemas.providers import ProviderConfiguration

        return ProviderConfiguration.model_validate(
            {
                "id": self.id,
                "user_id": self.user_id,
                "provider": self.provider,
                "display_name": self.display_name,
                "base_url": self.base_url,
                "metadata": self.metadata,
                "api_key_preview": self.api_key_preview,
                "is_active": self.is_active,
                "has_api_key": bool(self.api_key),
                "created_at": self.created_at,
                "updated_at": self.updated_at,
            }
        )


@dataclass(frozen=True)
class ModelConfigRecord:
    """In-memory representation of a model configuration row."""

    id: UUID
    user_id: UUID
    provider_id: UUID | None
    provider: str
    model: str
    name: str
    display_name: str | None
    description: str | None
    is_default: bool
    is_active: bool
    settings: dict
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_mapping(cls, data: Mapping[str, Any]) -> "ModelConfigRecord":
        return cls(
            id=data["id"],
            user_id=data["user_id"],
            provider_id=data.get("provider_id"),
            provider=data["provider"],
            model=data["model"],
            name=data["name"],
            display_name=data.get("display_name"),
            description=data.get("description"),
            is_default=bool(data.get("is_default", False)),
            is_active=bool(data.get("is_active", True)),
            settings=dict(data.get("settings") or {}),
            created_at=data["created_at"],
            updated_at=data["updated_at"],
        )

    def to_schema(self):  # pragma: no cover - thin wrapper
        from app.schemas.models import ModelConfiguration, ModelSettings

        return ModelConfiguration(
            id=self.id,
            user_id=self.user_id,
            provider_id=self.provider_id,
            provider=self.provider,
            model=self.model,
            name=self.name,
            display_name=self.display_name,
            description=self.description,
            is_default=self.is_default,
            is_active=self.is_active,
            settings=ModelSettings.model_validate(self.settings),
            created_at=self.created_at,
            updated_at=self.updated_at,
        )


__all__ = ["ProviderRecord", "ModelConfigRecord"]
