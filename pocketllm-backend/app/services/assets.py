"""User asset storage helpers."""

from __future__ import annotations

import asyncio
import logging
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from uuid import UUID

from fastapi import HTTPException, UploadFile, status

from app.core.config import Settings
from app.core.database import Database
from app.database import db as supabase_db
from app.schemas.users import UserProfile

logger = logging.getLogger(__name__)


class UserAssetService:
    """Persist user-uploaded assets (avatars, attachments) to Supabase storage."""

    _MAX_AVATAR_BYTES = 5 * 1024 * 1024  # 5 MB
    _ALLOWED_EXTENSIONS = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".webp": "image/webp",
        ".heic": "image/heic",
    }

    def __init__(
        self,
        settings: Settings,
        database: Database,
        *,
        storage_client: Any | None = None,
    ) -> None:
        self._settings = settings
        self._database = database
        self._storage = storage_client or supabase_db.client.storage

    async def upload_avatar(self, user_id: UUID, upload: UploadFile) -> UserProfile:
        """Store the uploaded avatar and update the user's profile."""

        contents = await upload.read()
        if not contents:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Uploaded file is empty.")

        if len(contents) > self._MAX_AVATAR_BYTES:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="Avatar files must be 5 MB or smaller.",
            )

        extension = self._resolve_extension(upload.filename, upload.content_type)
        if extension is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unsupported image format. Use PNG, JPG, WEBP, or HEIC images.",
            )

        object_path = self._build_object_path(user_id, extension)
        bucket_name = self._settings.user_asset_bucket_name
        bucket = self._storage.from_(bucket_name)
        logger.debug("Uploading avatar to Supabase storage", extra={"path": object_path, "bucket": bucket_name})

        try:
            await asyncio.to_thread(
                bucket.upload,
                object_path,
                contents,
                {"content-type": self._ALLOWED_EXTENSIONS[extension], "upsert": True},
            )
        except Exception as exc:
            logger.exception("Failed to upload avatar to Supabase storage: %s", exc)
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Avatar upload failed.") from exc

        public_url = self._extract_public_url(bucket.get_public_url(object_path), object_path)
        logger.debug("Avatar uploaded", extra={"path": object_path, "url": public_url})

        record = await self._database.update_profile(user_id, {"avatar_url": public_url})
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found.")

        return UserProfile.model_validate(record)

    def _resolve_extension(self, filename: str | None, content_type: str | None) -> str | None:
        if filename:
            extension = Path(filename).suffix.lower()
            if extension in self._ALLOWED_EXTENSIONS:
                return extension

        if content_type:
            normalized = content_type.lower()
            for extension, mime in self._ALLOWED_EXTENSIONS.items():
                if mime == normalized:
                    return extension
        return None

    def _build_object_path(self, user_id: UUID, extension: str) -> str:
        timestamp = datetime.now(tz=UTC).strftime("%Y%m%d%H%M%S")
        return f"profiles/{user_id}/avatar-{timestamp}{extension}"

    def _extract_public_url(self, payload: Any, fallback_path: str) -> str:
        if isinstance(payload, str) and payload:
            return payload
        if isinstance(payload, dict):
            if "publicURL" in payload and payload["publicURL"]:
                return str(payload["publicURL"])
            data = payload.get("data")
            if isinstance(data, dict):
                if data.get("publicUrl"):
                    return str(data["publicUrl"])
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Unable to generate a public URL for {fallback_path}.",
        )


__all__ = ["UserAssetService"]
