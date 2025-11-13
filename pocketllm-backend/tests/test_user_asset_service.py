import io
import uuid
from datetime import UTC, datetime

import pytest
from fastapi import UploadFile
from starlette.datastructures import Headers

from app.core.config import Settings
from app.services.assets import UserAssetService


class _FakeBucket:
    def __init__(self):
        self.uploads: list[tuple[str, bytes, dict]] = []

    def upload(self, path: str, data: bytes, options: dict) -> None:
        self.uploads.append((path, data, options))

    def get_public_url(self, path: str) -> dict:
        return {"publicURL": f"https://cdn.example.dev/{path}"}


class _FakeStorageClient:
    def __init__(self):
        self.bucket = _FakeBucket()
        self.bucket_name = None

    def from_(self, bucket_name: str) -> _FakeBucket:
        self.bucket_name = bucket_name
        return self.bucket


class _FakeDatabase:
    def __init__(self):
        self.updates: dict[str, dict] = {}

    async def update_profile(self, user_id, payload: dict):
        self.updates[str(user_id)] = payload
        now = datetime.now(tz=UTC).isoformat()
        return {
            "id": str(user_id),
            "email": "demo@example.com",
            "invite_status": "pending",
            "waitlist_status": "pending",
            "survey_completed": False,
            "deletion_status": "active",
            "created_at": now,
            "updated_at": now,
            "avatar_url": payload["avatar_url"],
        }


@pytest.mark.asyncio
async def test_upload_avatar_updates_profile_and_returns_profile():
    storage = _FakeStorageClient()
    database = _FakeDatabase()
    settings = Settings(user_asset_bucket_name="user-assets-integration")

    service = UserAssetService(settings=settings, database=database, storage_client=storage)

    upload = UploadFile(
        filename="avatar.png",
        file=io.BytesIO(b"binary-avatar"),
        headers=Headers({"content-type": "image/png"}),
    )

    user_id = uuid.uuid4()
    profile = await service.upload_avatar(user_id, upload)

    assert storage.bucket.uploads, "Avatar should be written to Supabase storage"
    assert database.updates[str(user_id)]["avatar_url"].startswith("https://cdn.example.dev/")
    assert profile.avatar_url == database.updates[str(user_id)]["avatar_url"]
