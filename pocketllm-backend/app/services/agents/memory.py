"""Persistence helpers for agent conversation memory."""

from __future__ import annotations

import json
import logging
from typing import Any

from app.core.database import Database

LOGGER = logging.getLogger("app.services.agents.memory")


class AgentMemoryStore:
    """Persist agent conversation state keyed by session and agent name."""

    _TABLE = "agent_memories"

    def __init__(self, database: Database) -> None:
        self._database = database

    async def load(self, owner_id: str, session_id: str, agent_key: str) -> dict[str, Any]:
        """Load the serialized memory state for ``agent_key`` within ``session_id``."""

        filters = {"owner_id": owner_id, "session_id": session_id, "agent_key": agent_key}
        records = await self._database.select(self._TABLE, filters=filters, limit=1)
        if not records:
            return {"messages": []}
        record = records[0]
        state = record.get("memory_state") or {}
        if isinstance(state, str):
            try:
                state = json.loads(state)
            except json.JSONDecodeError:
                LOGGER.warning(
                    "Unable to decode stored memory state for agent %s (session=%s)",
                    agent_key,
                    session_id,
                )
                state = {}
        if "messages" not in state:
            state["messages"] = []
        return state

    async def save(
        self, owner_id: str, session_id: str, agent_key: str, state: dict[str, Any]
    ) -> None:
        """Persist ``state`` for ``agent_key`` within ``session_id``."""

        payload = {
            "owner_id": owner_id,
            "session_id": session_id,
            "agent_key": agent_key,
            "memory_state": state,
        }
        await self._database.upsert(
            self._TABLE,
            payload,
            on_conflict="owner_id,session_id,agent_key",
        )

    async def reset(self, owner_id: str, session_id: str, agent_key: str) -> None:
        """Remove all stored messages for the given key."""

        filters = {"owner_id": owner_id, "session_id": session_id, "agent_key": agent_key}
        await self._database.delete(self._TABLE, filters=filters)


__all__ = ["AgentMemoryStore"]
