"""Agent registry and orchestrator utilities."""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Iterable

from app.core.config import Settings
from app.core.database import Database

from .base import AgentContext, AgentMetadata, AgentRunResult, BaseConversationalAgent
from .code import CodeAgent
from .image import ImageAgent
from .memory import AgentMemoryStore
from .prompt_enhancer import PromptEnhancerAgent
from .retrieval import RetrievalAgent
from .workflow import WorkflowAgent

LOGGER = logging.getLogger("app.services.agents.registry")


class AgentRegistry:
    """Holds all configured agents and exposes orchestration helpers."""

    def __init__(
        self,
        agents: Iterable[BaseConversationalAgent],
        *,
        discovered_components: dict[str, list[str]] | None = None,
    ) -> None:
        self._agents = {agent.metadata.name: agent for agent in agents}
        self._discovered = discovered_components or {}

    @property
    def discovered_components(self) -> dict[str, list[str]]:
        return self._discovered

    def list_agents(self) -> list[AgentMetadata]:
        return [agent.metadata for agent in self._agents.values()]

    async def run_agent(
        self,
        agent_name: str,
        context: AgentContext,
        *,
        prompt: str,
        task: str | None = None,
    ) -> AgentRunResult:
        agent = self._agents.get(agent_name)
        if not agent:
            raise KeyError(f"Agent '{agent_name}' is not registered")
        LOGGER.debug("Running agent %s for session %s", agent_name, context.session_id)
        return await agent.run(context, prompt=prompt, task=task)


def build_agent_registry(settings: Settings, database: Database) -> AgentRegistry:
    """Instantiate all agents sharing a common memory store."""

    memory_store = AgentMemoryStore(database)
    prompt_agent = PromptEnhancerAgent(settings, memory_store)
    retrieval_agent = RetrievalAgent(memory_store)
    code_agent = CodeAgent(memory_store)
    image_agent = ImageAgent(memory_store)
    workflow_agent = WorkflowAgent(
        memory_store,
        prompt_agent=prompt_agent,
        retrieval_agent=retrieval_agent,
        code_agent=code_agent,
        image_agent=image_agent,
    )
    agents: list[BaseConversationalAgent] = [
        prompt_agent,
        retrieval_agent,
        code_agent,
        image_agent,
        workflow_agent,
    ]
    discovered = _discover_langchain_components(settings)
    return AgentRegistry(agents, discovered_components=discovered)


def _discover_langchain_components(settings: Settings) -> dict[str, list[str]]:
    docs_path = Path("docs/langchain")
    if not docs_path.exists():
        alternative = Path("D:/Projects/pocketllm/docs/langchain")
        if alternative.exists():
            docs_path = alternative
    tools: set[str] = set()
    agents: set[str] = set()
    if docs_path.exists():
        for path in docs_path.glob("*.md"):
            try:
                contents = path.read_text(encoding="utf-8")
            except OSError:
                continue
            for line in contents.splitlines():
                line = line.strip()
                if line.lower().startswith("### "):
                    heading = line[4:].strip()
                    lowered = heading.lower()
                    if "tool" in lowered:
                        tools.add(heading)
                    if any(keyword in lowered for keyword in ("agent", "chain")):
                        agents.add(heading)
    discovered: dict[str, list[str]] = {}
    if tools:
        discovered["tools"] = sorted(tools)
    if agents:
        discovered["agents"] = sorted(agents)
    return discovered


__all__ = ["AgentRegistry", "build_agent_registry"]
