"""Code agent powered by LangChain utilities."""

from __future__ import annotations

import logging
from typing import Any

from langchain_classic.chains import LLMChain
from langchain_classic.prompts import PromptTemplate

from .base import AgentContext, AgentRunResult, BaseConversationalAgent
from .memory import AgentMemoryStore
from .retrieval import _DeterministicLLM

LOGGER = logging.getLogger("app.services.agents.code")

_PLAN_PROMPT = PromptTemplate(
    input_variables=["requirements"],
    template=(
        "You are a senior software engineer. Transform the raw request into a structured implementation plan. "
        "Outline language, dependencies, edge cases, and tests.\n\nRequest:\n{requirements}\n\nPlan:"
    ),
)


class CodeAgent(BaseConversationalAgent):
    """Generates implementation plans without executing untrusted code."""

    def __init__(self, memory_store: AgentMemoryStore) -> None:
        super().__init__(
            name="code",
            description="Creates coding plans and surfaces suggested manual checks.",
            capabilities=["code_planning", "edge_case_generation"],
            memory_store=memory_store,
        )
        self._planner = LLMChain(llm=_DeterministicLLM(), prompt=_PLAN_PROMPT)

    async def run(self, context: AgentContext, *, prompt: str, **_: Any) -> AgentRunResult:
        memory = await self._load_history(context)
        plan = await self._planner.apredict(requirements=prompt)
        tests = context.metadata.get("tests", [])
        tool_results: list[dict[str, Any]] = []
        if tests:
            LOGGER.warning(
                "Ignoring %d requested Python test(s) for session %s; remote execution is disabled",
                len(tests),
                context.session_id,
            )

        memory.chat_memory.add_user_message(prompt)
        summary = plan
        memory.chat_memory.add_ai_message(summary)
        await self._persist_history(context, memory.chat_memory, extra={"tool_runs": tool_results})

        return AgentRunResult(
            output=plan,
            data={
                "plan": plan,
                "tool_runs": tool_results,
            },
        )


__all__ = ["CodeAgent"]
