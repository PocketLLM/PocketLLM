"""LangGraph workflow agent that composes multiple specialists."""

from __future__ import annotations

import logging
from typing import Any, TypedDict

from langgraph.graph import END, StateGraph

from .base import AgentContext, AgentRunResult, BaseConversationalAgent
from .memory import AgentMemoryStore
from .prompt_enhancer import PromptEnhancerAgent
from .retrieval import RetrievalAgent
from .code import CodeAgent
from .image import ImageAgent

LOGGER = logging.getLogger("app.services.agents.workflow")


class WorkflowState(TypedDict, total=False):
    task: str
    prompt: str
    enhanced_prompt: str | None
    result: str | None
    metadata: dict[str, Any]


class WorkflowAgent(BaseConversationalAgent):
    """Coordinates specialised agents through a LangGraph workflow."""

    def __init__(
        self,
        memory_store: AgentMemoryStore,
        *,
        prompt_agent: PromptEnhancerAgent,
        retrieval_agent: RetrievalAgent,
        code_agent: CodeAgent,
        image_agent: ImageAgent,
    ) -> None:
        super().__init__(
            name="workflow",
            description="Multi-step coordinator that enhances prompts and dispatches to specialist agents.",
            capabilities=["prompt_enhancement", "task_routing", "multi_agent_execution"],
            memory_store=memory_store,
        )
        self._prompt_agent = prompt_agent
        self._retrieval_agent = retrieval_agent
        self._code_agent = code_agent
        self._image_agent = image_agent
        self._graph = self._build_graph()

    def _build_graph(self) -> Any:
        graph: StateGraph[WorkflowState] = StateGraph(WorkflowState)
        graph.add_node("enhance", self._enhance_node)
        graph.add_node("execute", self._execute_node)
        graph.set_entry_point("enhance")
        graph.add_edge("enhance", "execute")
        graph.add_edge("execute", END)
        return graph.compile()

    async def run(self, context: AgentContext, *, prompt: str, task: str | None = None, **_: Any) -> AgentRunResult:
        memory = await self._load_history(context)
        workflow_task = (task or context.metadata.get("task") or "writing").lower()
        initial_state: WorkflowState = {
            "task": workflow_task,
            "prompt": prompt,
            "metadata": {},
        }
        config = {"configurable": {"agent_context": context}}
        result_state: WorkflowState = await self._graph.ainvoke(initial_state, config=config)

        final_output = result_state.get("result") or result_state.get("enhanced_prompt") or ""
        memory.chat_memory.add_user_message(prompt)
        memory.chat_memory.add_ai_message(final_output)
        await self._persist_history(context, memory.chat_memory, extra={"workflow": result_state})
        return AgentRunResult(output=final_output, data=result_state)

    async def _enhance_node(self, state: WorkflowState, config: dict[str, Any]) -> WorkflowState:
        context: AgentContext = config.get("configurable", {}).get("agent_context")
        prompt = state["prompt"]
        task = state["task"]
        LOGGER.debug("WorkflowAgent: enhancing prompt for task %s", task)
        result = await self._prompt_agent.run(context, prompt=prompt, task=task)
        metadata = dict(state.get("metadata") or {})
        metadata["enhancement"] = result.data
        return {"enhanced_prompt": result.output, "metadata": metadata}

    async def _execute_node(self, state: WorkflowState, config: dict[str, Any]) -> WorkflowState:
        context: AgentContext = config.get("configurable", {}).get("agent_context")
        task = state.get("task", "writing")
        prompt = state.get("enhanced_prompt") or state.get("prompt") or ""
        LOGGER.debug("WorkflowAgent: executing task %s", task)
        if task == "maths":
            downstream = await self._retrieval_agent.run(context, prompt=prompt)
        elif task == "code":
            downstream = await self._code_agent.run(context, prompt=prompt)
        elif task == "image_generation":
            downstream = await self._image_agent.run(context, prompt=prompt)
        elif task == "summarization":
            downstream = await self._retrieval_agent.run(context, prompt=prompt)
        else:
            downstream = await self._prompt_agent.run(context, prompt=prompt, task="writing")
        metadata = dict(state.get("metadata") or {})
        metadata["execution"] = downstream.data
        return {"result": downstream.output, "metadata": metadata}


__all__ = ["WorkflowAgent", "WorkflowState"]
