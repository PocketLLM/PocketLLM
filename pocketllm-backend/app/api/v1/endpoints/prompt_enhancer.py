"""Prompt enhancer API endpoint."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends

from app.api.deps import get_current_request_user, get_database_dependency, get_settings_dependency
from app.schemas.agents import PromptEnhancerRequest, PromptEnhancerResponse
from app.schemas.auth import TokenPayload
from app.services.agents import AgentContext, AgentMemoryStore, PromptEnhancerAgent
from app.utils.rate_limit import RateLimiter

router = APIRouter(prefix="/prompt-enhancer", tags=["prompt-enhancer"])
LOGGER = logging.getLogger("app.api.v1.prompt_enhancer")
_RATE_LIMITER = RateLimiter(max_requests=10, window_seconds=60.0)


@router.post("/improve", response_model=PromptEnhancerResponse, summary="Enhance a prompt for a specific task")
async def improve_prompt(
    payload: PromptEnhancerRequest,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
    settings=Depends(get_settings_dependency),
) -> PromptEnhancerResponse:
    await _RATE_LIMITER.check(str(user.sub))
    session_id = payload.session_id or str(user.sub)
    LOGGER.info("Prompt enhancement requested", extra={"user_id": str(user.sub), "task": payload.task})

    memory_store = AgentMemoryStore(database)
    agent = PromptEnhancerAgent(settings, memory_store)
    context = AgentContext(session_id=session_id, metadata=payload.metadata)
    result = await agent.improve_prompt(context, task=payload.task, prompt=payload.prompt)

    return PromptEnhancerResponse(
        task=result.data.get("task", payload.task.lower()),
        enhanced_prompt=result.data.get("enhanced_prompt", result.output),
        guidance=result.data.get("guidance"),
        raw_response=result.data.get("raw_response"),
    )


__all__ = ["router"]
