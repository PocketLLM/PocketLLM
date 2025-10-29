"""Ensure the models endpoint supports legacy filter syntax."""

from __future__ import annotations

import importlib.util
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path
from types import SimpleNamespace
from typing import Any
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.api.deps import (
    get_current_request_user,
    get_database_dependency,
    get_settings_dependency,
)
from app.schemas.auth import TokenPayload
from app.schemas.providers import ProviderModel, ProviderModelsResponse


def _load_app():
    project_root = Path(__file__).resolve().parents[1]
    module_path = project_root / "main.py"
    os.environ.setdefault("ENVIRONMENT", "test")
    spec = importlib.util.spec_from_file_location("pocketllm_backend.main", module_path)
    if spec is None or spec.loader is None:  # pragma: no cover - defensive
        raise RuntimeError("Failed to load FastAPI application")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.app


@pytest.fixture()
def client(monkeypatch):
    import app.api.v1.endpoints.models as models_endpoint

    app = _load_app()
    calls: list[dict[str, Any]] = []

    class StubProvidersService:
        def __init__(self, *args: Any, **kwargs: Any) -> None:  # pragma: no cover - simple stub
            pass

        async def get_provider_models(
            self,
            user_id,
            *,
            provider: str | None = None,
            name: str | None = None,
            model_id: str | None = None,
            query: str | None = None,
        ) -> ProviderModelsResponse:
            calls.append(
                {
                    "user_id": user_id,
                    "provider": provider,
                    "name": name,
                    "model_id": model_id,
                    "query": query,
                }
            )
            return ProviderModelsResponse(
                models=[
                    ProviderModel(
                        provider="imagerouter",
                        id="imagerouter-test",
                        name="ImageRouter Test",
                    )
                ],
                configured_providers=["imagerouter"],
            )

    monkeypatch.setattr(models_endpoint, "ProvidersService", StubProvidersService)

    async def override_current_user():
        return TokenPayload(
            sub=uuid4(),
            exp=datetime.now(timezone.utc) + timedelta(minutes=5),
        )

    async def override_settings():
        return SimpleNamespace()

    async def override_database():
        return SimpleNamespace()

    app.dependency_overrides[get_current_request_user] = override_current_user
    app.dependency_overrides[get_settings_dependency] = override_settings
    app.dependency_overrides[get_database_dependency] = override_database

    test_client = TestClient(app)
    try:
        yield test_client, calls
    finally:
        app.dependency_overrides.clear()


def test_models_endpoint_supports_legacy_filter_path(client):
    test_client, calls = client
    response = test_client.get("/v1/models&&provider=imagerouter")
    assert response.status_code == 200
    payload = response.json()
    assert payload["models"][0]["provider"] == "imagerouter"
    assert calls
    assert calls[-1]["provider"] == "imagerouter"


def test_legacy_filter_path_parses_optional_filters(client):
    test_client, calls = client
    response = test_client.get(
        "/v1/models&&provider=imagerouter&name=flux&model_id=flux-pro&query=flux"
    )
    assert response.status_code == 200
    assert calls
    last_call = calls[-1]
    assert last_call["provider"] == "imagerouter"
    assert last_call["name"] == "flux"
    assert last_call["model_id"] == "flux-pro"
    assert last_call["query"] == "flux"
