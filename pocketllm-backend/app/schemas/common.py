"""Common reusable schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """Health check payload."""

    status: str = "ok"
    timestamp: datetime
    version: str


class PaginatedResponse(BaseModel):
    """Generic pagination envelope."""

    items: list[Any]
    total: int
    limit: int
    offset: int


__all__ = ["HealthResponse", "PaginatedResponse"]
