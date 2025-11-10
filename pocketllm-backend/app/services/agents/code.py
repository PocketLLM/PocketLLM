"""Code agent powered by LangChain utilities."""

from __future__ import annotations

import logging
from typing import Any

from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate
from langchain.tools.python.tool import PythonREPLTool

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
    """Generates implementation plans and executes quick Python checks."""

    def __init__(self, memory_store: AgentMemoryStore) -> None:
        super().__init__(
            name="code",
            description="Creates coding plans and can execute lightweight Python REPL checks.",
            capabilities=["code_planning", "edge_case_generation", "python_repl_testing"],
            memory_store=memory_store,
        )
        self._planner = LLMChain(llm=_DeterministicLLM(), prompt=_PLAN_PROMPT)
        self._python_tool = PythonREPLTool()

    async def run(self, context: AgentContext, *, prompt: str, **_: Any) -> AgentRunResult:
        memory = await self._load_history(context.session_id)
        plan = await self._planner.apredict(requirements=prompt)
        tests = context.metadata.get("tests", [])
        tool_results: list[dict[str, Any]] = []

        for test in tests:
            try:
                output = self._python_tool.run(test)
                tool_results.append({"input": test, "output": output})
            except Exception as exc:  # pragma: no cover - execution failure branch
                LOGGER.warning("Python tool execution failed: %s", exc)
                tool_results.append({"input": test, "error": str(exc)})

        memory.chat_memory.add_user_message(prompt)
        summary = plan if not tool_results else f"{plan}\n\nTool Results:\n" + "\n".join(
            f"- {item.get('input')}: {item.get('output') or item.get('error')}" for item in tool_results
        )
        memory.chat_memory.add_ai_message(summary)
        await self._persist_history(context.session_id, memory.chat_memory, extra={"tool_runs": tool_results})

        return AgentRunResult(
            output=plan,
            data={
                "plan": plan,
                "tool_runs": tool_results,
            },
        )


__all__ = ["CodeAgent"]
