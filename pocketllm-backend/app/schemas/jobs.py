"""Background job schemas."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class JobStatus(str, Enum):
    """Enumeration of possible job states."""

    pending = "pending"
    processing = "processing"
    completed = "completed"
    failed = "failed"


class Job(BaseModel):
    """Stored job payload."""

    id: UUID
    user_id: UUID
    job_type: str
    status: JobStatus
    input_data: dict | None = None
    output_data: dict | None = None
    error_log: Optional[str] = None
    metadata: dict | None = None
    created_at: datetime
    updated_at: datetime


class JobCreateRequest(BaseModel):
    """Request to enqueue a job."""

    job_type: str = Field(pattern=r"^[a-zA-Z0-9_-]+$")
    input_data: dict = Field(default_factory=dict)
    metadata: dict | None = None


class JobCreateResponse(BaseModel):
    """Response returned when a job is queued."""

    job_id: UUID
    status: JobStatus = JobStatus.pending


class JobEstimateRequest(BaseModel):
    """Request payload for cost estimation."""

    model: str
    dimensions: tuple[int, int] | None = None
    steps: int | None = None
    metadata: dict | None = None


class JobEstimateResponse(BaseModel):
    """Estimated cost information."""

    model: str
    cost_credits: float
    currency: str = "credits"
    breakdown: dict[str, Any] | None = None


__all__ = [
    "JobStatus",
    "Job",
    "JobCreateRequest",
    "JobCreateResponse",
    "JobEstimateRequest",
    "JobEstimateResponse",
]
