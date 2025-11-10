"""Pydantic schemas for agent APIs."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field


class PromptEnhancerRequest(BaseModel):
    """Payload for improving a prompt."""

    prompt: str = Field(min_length=1)
    task: str = Field(default="writing")
    session_id: str | None = Field(default=None, description="Session identifier for memory persistence")
    metadata: dict[str, Any] = Field(default_factory=dict)


class PromptEnhancerResponse(BaseModel):
    """Response with an enhanced prompt."""

    task: str
    enhanced_prompt: str
    guidance: str | None = None
    raw_response: str | None = None


class AgentInfo(BaseModel):
    """Metadata about a registered agent."""

    name: str
    description: str
    capabilities: list[str]


class AgentListResponse(BaseModel):
    """List of all agents and discovered components."""

    agents: list[AgentInfo]
    discovered_components: dict[str, list[str]] | None = None


class AgentRunRequest(BaseModel):
    """Payload for executing a specific agent."""

    agent: str
    prompt: str = Field(min_length=1)
    task: str | None = None
    session_id: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


class AgentRunResponse(BaseModel):
    """Result of executing an agent."""

    agent: str
    output: str
    data: dict[str, Any]


__all__ = [
    "PromptEnhancerRequest",
    "PromptEnhancerResponse",
    "AgentInfo",
    "AgentListResponse",
    "AgentRunRequest",
    "AgentRunResponse",
]
