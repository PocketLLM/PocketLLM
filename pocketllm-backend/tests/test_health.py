"""Basic health endpoint tests."""

from __future__ import annotations

import importlib.util
import os
from pathlib import Path

from fastapi.testclient import TestClient


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


app = _load_app()

client = TestClient(app)


def test_health_endpoint() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert "version" in payload


def test_root_endpoint() -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["message"].startswith("PocketLLM backend")
