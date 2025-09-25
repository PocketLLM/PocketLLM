"""Background job orchestration service."""

from __future__ import annotations

import asyncio
from dataclasses import dataclass
from typing import Any
from uuid import UUID

from fastapi import HTTPException, status

from app.core.config import Settings
from app.core.database import Database
from app.schemas.jobs import (
    Job,
    JobCreateRequest,
    JobCreateResponse,
    JobEstimateRequest,
    JobEstimateResponse,
    JobStatus,
)


@dataclass(slots=True)
class JobWorker:
    """Manages asynchronous job execution."""

    database: Database
    settings: Settings

    def __post_init__(self) -> None:
        self._tasks: set[asyncio.Task[Any]] = set()

    async def enqueue_image_generation(self, user_id: UUID, payload: JobCreateRequest) -> JobCreateResponse:
        record = await self.database.fetchrow(
            """
            INSERT INTO public.jobs (user_id, job_type, status, input_data, metadata)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
            """,
            user_id,
            payload.job_type,
            JobStatus.pending.value,
            payload.input_data,
            payload.metadata,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create job")

        job_id = UUID(str(record["id"]))
        task = asyncio.create_task(self._process_image_job(job_id))
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)
        return JobCreateResponse(job_id=job_id)

    async def _process_image_job(self, job_id: UUID) -> None:
        try:
            await self.database.execute(
                "UPDATE public.jobs SET status = $2, updated_at = NOW() WHERE id = $1",
                job_id,
                JobStatus.processing.value,
            )
            await asyncio.sleep(0.1)
            await self.database.execute(
                """
                UPDATE public.jobs
                SET status = $2,
                    output_data = jsonb_build_object('result', 'pending-delivery'),
                    updated_at = NOW()
                WHERE id = $1
                """,
                job_id,
                JobStatus.completed.value,
            )
        except Exception as exc:  # pragma: no cover - best effort logging
            await self.database.execute(
                "UPDATE public.jobs SET status = $2, error_log = $3, updated_at = NOW() WHERE id = $1",
                job_id,
                JobStatus.failed.value,
                str(exc),
            )


class JobsService:
    """High-level job operations."""

    def __init__(self, settings: Settings, database: Database) -> None:
        self._settings = settings
        self._database = database
        self._worker = JobWorker(database=database, settings=settings)

    async def list_jobs(self, user_id: UUID) -> list[Job]:
        records = await self._database.fetch(
            "SELECT * FROM public.jobs WHERE user_id = $1 ORDER BY created_at DESC",
            user_id,
        )
        return [Job.model_validate(dict(record)) for record in records]

    async def get_job(self, user_id: UUID, job_id: UUID) -> Job:
        record = await self._database.fetchrow(
            "SELECT * FROM public.jobs WHERE user_id = $1 AND id = $2",
            user_id,
            job_id,
        )
        if not record:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
        return Job.model_validate(dict(record))

    async def create_image_job(self, user_id: UUID, payload: JobCreateRequest) -> JobCreateResponse:
        if payload.job_type != "image_generation":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid job type")
        return await self._worker.enqueue_image_generation(user_id, payload)

    async def delete_job(self, user_id: UUID, job_id: UUID) -> None:
        result = await self._database.execute(
            "DELETE FROM public.jobs WHERE id = $1 AND user_id = $2",
            job_id,
            user_id,
        )
        affected = int(result.split()[-1]) if result else 0
        if affected == 0:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")

    async def retry_job(self, user_id: UUID, job_id: UUID) -> JobCreateResponse:
        job = await self.get_job(user_id, job_id)
        if job.status != JobStatus.failed:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only failed jobs can be retried")
        payload = JobCreateRequest(job_type=job.job_type, input_data=job.input_data or {}, metadata=job.metadata)
        return await self.create_image_job(user_id, payload)

    async def get_available_image_models(self) -> list[dict[str, Any]]:
        return [
            {"id": "stable-diffusion-xl", "name": "Stable Diffusion XL", "pricing": {"per_image": 2.5}},
            {"id": "dalle-3", "name": "DALL·E 3", "pricing": {"per_image": 3.0}},
        ]

    async def estimate_image_cost(self, payload: JobEstimateRequest) -> JobEstimateResponse:
        base_price = 2.5 if payload.model == "stable-diffusion-xl" else 3.0
        multiplier = 1.0
        if payload.dimensions:
            width, height = payload.dimensions
            multiplier += max(width * height / (1024 * 1024), 0)
        if payload.steps:
            multiplier += payload.steps / 50
        return JobEstimateResponse(model=payload.model, cost_credits=round(base_price * multiplier, 2))


__all__ = ["JobsService"]
