"""Agent registry endpoints."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_request_user, get_database_dependency, get_settings_dependency
from app.schemas.agents import AgentInfo, AgentListResponse, AgentRunRequest, AgentRunResponse
from app.schemas.auth import TokenPayload
from app.services.agents import AgentContext, build_agent_registry

router = APIRouter(prefix="/agents", tags=["agents"])
LOGGER = logging.getLogger("app.api.v1.agents")


@router.get("/list", response_model=AgentListResponse, summary="List available agents")
async def list_agents(
    database=Depends(get_database_dependency),
    settings=Depends(get_settings_dependency),
    _: TokenPayload = Depends(get_current_request_user),
) -> AgentListResponse:
    registry = build_agent_registry(settings, database)
    agents = [
        AgentInfo(name=agent.name, description=agent.description, capabilities=agent.capabilities)
        for agent in registry.list_agents()
    ]
    return AgentListResponse(agents=agents, discovered_components=registry.discovered_components)


@router.post("/run", response_model=AgentRunResponse, summary="Execute an agent")
async def run_agent(
    payload: AgentRunRequest,
    user: TokenPayload = Depends(get_current_request_user),
    database=Depends(get_database_dependency),
    settings=Depends(get_settings_dependency),
) -> AgentRunResponse:
    registry = build_agent_registry(settings, database)
    session_id = payload.session_id or str(user.sub)
    context = AgentContext(session_id=session_id, metadata=payload.metadata)
    try:
        result = await registry.run_agent(payload.agent, context, prompt=payload.prompt, task=payload.task)
    except KeyError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    LOGGER.info("Agent run completed", extra={"agent": payload.agent, "user_id": str(user.sub)})
    return AgentRunResponse(agent=payload.agent, output=result.output, data=result.data)


__all__ = ["router"]
