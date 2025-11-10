"""Base primitives for conversational agents."""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any, Iterable

from langchain_core.chat_history import BaseChatMessageHistory, InMemoryChatMessageHistory
from langchain_core.messages import AIMessage, BaseMessage, HumanMessage, SystemMessage

# Always define our fallback class
class _FallbackConversationBufferMemory:
    """Minimal stand-in when langchain.memory is unavailable."""

    def __init__(self, *, return_messages: bool = True) -> None:
        if not return_messages:
            raise ValueError("PocketLLM agents require return_messages=True for memory persistence.")
        self._chat_memory: BaseChatMessageHistory = InMemoryChatMessageHistory()

    @property
    def chat_memory(self) -> BaseChatMessageHistory:
        return self._chat_memory

    @chat_memory.setter
    def chat_memory(self, history: BaseChatMessageHistory) -> None:
        self._chat_memory = history

# Try to import the actual class and use it, otherwise use our fallback
try:
    from langchain_classic.memory import ConversationBufferMemory
except ModuleNotFoundError:  # pragma: no cover - fallback for new LangChain modular releases
    ConversationBufferMemory = _FallbackConversationBufferMemory

from .memory import AgentMemoryStore

LOGGER = logging.getLogger("app.services.agents.base")


@dataclass(slots=True)
class AgentMetadata:
    """Metadata describing an agent for registry listings."""

    name: str
    description: str
    capabilities: list[str]


@dataclass(slots=True)
class AgentContext:
    """Execution context supplied when running an agent."""

    session_id: str
    user_id: str
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class AgentRunResult:
    """Structured response returned by an agent run."""

    output: str
    data: dict[str, Any]


class BaseConversationalAgent:
    """Convenience wrapper around LangChain memory utilities."""

    def __init__(self, *, name: str, description: str, capabilities: Iterable[str], memory_store: AgentMemoryStore) -> None:
        self._name = name
        self._description = description
        self._capabilities = list(capabilities)
        self._memory_store = memory_store

    @property
    def metadata(self) -> AgentMetadata:
        return AgentMetadata(self._name, self._description, list(self._capabilities))

    async def _load_history(self, context: AgentContext) -> Any:
        state = await self._memory_store.load(context.user_id, context.session_id, self._name)
        history = _deserialize_history(state.get("messages", []))
        buffer = ConversationBufferMemory(return_messages=True)
        buffer.chat_memory = history
        return buffer

    async def _persist_history(
        self,
        context: AgentContext,
        history: BaseChatMessageHistory,
        *,
        extra: dict[str, Any] | None = None,
    ) -> None:
        payload: dict[str, Any] = {"messages": _serialize_history(history.messages)}
        if extra:
            payload.update(extra)
        await self._memory_store.save(context.user_id, context.session_id, self._name, payload)

    async def run(self, context: AgentContext, *, prompt: str, **kwargs: Any) -> AgentRunResult:  # pragma: no cover - interface
        raise NotImplementedError


def _deserialize_history(serialized: Iterable[dict[str, Any]]) -> InMemoryChatMessageHistory:
    history = InMemoryChatMessageHistory()
    for message in serialized:
        role = message.get("type") or message.get("role")
        content = message.get("content", "")
        if role == "system":
            history.add_message(SystemMessage(content=content))
        elif role in {"assistant", "ai"}:
            history.add_message(AIMessage(content=content))
        else:
            history.add_message(HumanMessage(content=content))
    return history


def _serialize_history(messages: Iterable[BaseMessage]) -> list[dict[str, Any]]:
    payload: list[dict[str, Any]] = []
    for message in messages:
        payload.append({"type": message.type, "content": message.content})
    return payload


__all__ = [
    "AgentContext",
    "AgentMetadata",
    "AgentRunResult",
    "BaseConversationalAgent",
]