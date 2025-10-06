"""Unit tests for authentication schemas."""

from __future__ import annotations

from app.schemas.auth import SignUpRequest


def test_sign_up_request_accepts_name_alias() -> None:
    payload = SignUpRequest.model_validate(
        {"email": "user@example.com", "password": "password123", "name": "Example"}
    )

    assert payload.full_name == "Example"
