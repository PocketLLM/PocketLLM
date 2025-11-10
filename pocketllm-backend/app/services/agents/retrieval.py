"""Retrieval agent built with LangChain's RetrievalQA."""

from __future__ import annotations

import logging
from typing import Any, Iterable

from langchain.chains import RetrievalQA
from langchain_core.documents import Document
from langchain_core.language_models.llms import LLM
from langchain_core.outputs import LLMResult
from langchain_core.retrievers import BaseRetriever

from .base import AgentContext, AgentRunResult, BaseConversationalAgent
from .memory import AgentMemoryStore

LOGGER = logging.getLogger("app.services.agents.retrieval")


class _SessionMemoryRetriever(BaseRetriever):
    """Retriever that sources context from persisted agent memory."""

    def __init__(self, memory_store: AgentMemoryStore, agent_key: str) -> None:
        super().__init__()
        self._memory_store = memory_store
        self._agent_key = agent_key
        self.session_id: str | None = None

    async def _aget_relevant_documents(self, query: str) -> list[Document]:
        if not self.session_id:
            raise RuntimeError("Session ID must be set before calling the retriever")
        state = await self._memory_store.load(self.session_id, self._agent_key)
        corpus: Iterable[str] = state.get("knowledge_base", []) or []
        if not corpus:
            corpus = ["No prior knowledge is stored for this session. Respond based on the query context only."]
        documents = [Document(page_content=text) for text in corpus]
        LOGGER.debug("Retrieved %d context documents for query", len(documents))
        return documents

    def _get_relevant_documents(self, query: str) -> list[Document]:  # pragma: no cover - sync bridge
        import asyncio

        try:
            asyncio.get_running_loop()
        except RuntimeError:
            return asyncio.run(self._aget_relevant_documents(query))
        LOGGER.debug("Synchronous retrieval requested inside running loop; returning cached context only")
        return []


class _DeterministicLLM(LLM):
    """Deterministic LLM used to keep RetrievalQA operational without external APIs."""

    def __init__(self) -> None:
        super().__init__()

    @property
    def _llm_type(self) -> str:
        return "pocketllm-retrieval"

    def _call(self, prompt: str, stop: list[str] | None = None) -> str:
        suffix = "" if not stop else f" (stopped on: {', '.join(stop)})"
        return f"Knowledge-grounded response:{suffix}\n{prompt.strip()}"

    async def _acall(self, prompt: str, stop: list[str] | None = None) -> str:
        return self._call(prompt, stop=stop)

    def _generate(self, prompts: list[str], stop: list[str] | None = None) -> LLMResult:
        generations = [[self._call(prompt, stop=stop)] for prompt in prompts]
        return LLMResult(generations=[[{"text": text} for text in row] for row in generations])


class RetrievalAgent(BaseConversationalAgent):
    """LangChain RetrievalQA agent with persistent memory."""

    def __init__(self, memory_store: AgentMemoryStore) -> None:
        super().__init__(
            name="retrieval",
            description="Answers questions using persisted session knowledge and RetrievalQA.",
            capabilities=["retrieval", "contextual_reasoning", "memory_augmented_responses"],
            memory_store=memory_store,
        )
        self._retriever = _SessionMemoryRetriever(memory_store, self._name)
        self._llm = _DeterministicLLM()

    async def run(self, context: AgentContext, *, prompt: str, **_: Any) -> AgentRunResult:
        memory = await self._load_history(context.session_id)
        self._retriever.session_id = context.session_id
        chain = RetrievalQA.from_chain_type(llm=self._llm, retriever=self._retriever, chain_type="stuff")
        response = await chain.acall({"query": prompt})
        answer = response.get("result") or response.get("output_text") or ""
        sources = response.get("source_documents", [])

        extra_state = await self._memory_store.load(context.session_id, self._name)
        knowledge_base: list[str] = list(extra_state.get("knowledge_base", []))
        knowledge_base.append(prompt)

        memory.chat_memory.add_user_message(prompt)
        memory.chat_memory.add_ai_message(answer)
        await self._persist_history(
            context.session_id,
            memory.chat_memory,
            extra={"knowledge_base": knowledge_base},
        )

        return AgentRunResult(
            output=answer,
            data={
                "sources": [doc.page_content for doc in sources] if sources else knowledge_base,
                "prompt": prompt,
            },
        )


__all__ = ["RetrievalAgent"]
