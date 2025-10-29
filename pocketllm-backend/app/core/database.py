"""Asynchronous adapter for the Supabase Python SDK."""

from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager
from functools import partial
from typing import TYPE_CHECKING, Any, AsyncIterator, Callable, Dict, Iterable, List, Optional
from uuid import UUID

if TYPE_CHECKING:  # pragma: no cover - typing helper
    from app.core.config import Settings
    from app.database.connection import SupabaseDatabase
else:  # pragma: no cover - fallback for runtime without config dependency
    Settings = Any  # type: ignore[misc,assignment]
    SupabaseDatabase = Any  # type: ignore[misc,assignment]

logger = logging.getLogger(__name__)


class Database:
    """Async wrapper that delegates all operations to Supabase."""

    def __init__(self, settings: "Settings", supabase: "SupabaseDatabase" | None = None) -> None:
        self._settings = settings
        self._supabase = _resolve_supabase(supabase)

    # ------------------------------------------------------------------
    # Lifecycle management
    # ------------------------------------------------------------------
    async def connect(self) -> None:
        """Validate the Supabase connection."""

        await self._run(self._ensure_client_ready)

    async def disconnect(self) -> None:  # pragma: no cover - included for symmetry
        """Supabase connections are stateless; nothing to close."""

    def _ensure_client_ready(self) -> None:
        self._supabase.client
        if getattr(self._supabase, "_connection_verified", False):
            return

        if getattr(self._supabase, "_allow_unverified_connection", False):
            logger.debug(
                "Supabase connectivity was not verified during startup but strict startup is disabled; skipping additional validation."
            )
            return

        if not self._supabase.test_connection():
            diagnostics = getattr(self._supabase, "_last_connection_error", None)
            message = (
                diagnostics.get("message")
                if isinstance(diagnostics, dict) and diagnostics.get("message")
                else "Supabase connection validation failed"
            )
            raise RuntimeError(message)

    # ------------------------------------------------------------------
    # Context helpers
    # ------------------------------------------------------------------
    @asynccontextmanager
    async def connection(self) -> AsyncIterator["Database"]:
        """Yield ``self`` to mirror the previous asyncpg interface."""

        await self.connect()
        yield self

    @asynccontextmanager
    async def transaction(self) -> AsyncIterator["Database"]:
        """Transactions are handled server-side by Supabase."""

        await self.connect()
        yield self

    # ------------------------------------------------------------------
    # Profile helpers
    # ------------------------------------------------------------------
    async def get_profile(self, user_id: UUID | str) -> Optional[Dict[str, Any]]:
        return await self._run(self._supabase.get_profile, str(user_id))

    async def upsert_profile(self, user_id: UUID | str, payload: Dict[str, Any]) -> Dict[str, Any]:
        return await self._run(self._supabase.upsert_profile, str(user_id), payload)

    async def update_profile(self, user_id: UUID | str, payload: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        return await self._run(self._supabase.update_profile, str(user_id), payload)

    # ------------------------------------------------------------------
    # Generic CRUD helpers
    # ------------------------------------------------------------------
    async def select(
        self,
        table: str,
        *,
        columns: str = "*",
        filters: Optional[Dict[str, Any]] = None,
        limit: Optional[int] = None,
        order_by: Optional[Iterable[Any]] = None,
    ) -> List[Dict[str, Any]]:
        order_param = None
        if isinstance(order_by, str):
            order_param = order_by
        elif order_by is not None:
            order_param = list(order_by)

        return await self._run(
            self._supabase.select,
            table,
            columns=columns,
            filters=self._stringify_filters(filters),
            limit=limit,
            order_by=order_param,
        )

    async def insert(self, table: str, data: Dict[str, Any]) -> Dict[str, Any]:
        records = await self._run(self._supabase.insert, table, data)
        if not records:
            raise RuntimeError(f"Insert into {table} returned no data")
        return records[0]

    async def insert_many(self, table: str, data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        return await self._run(self._supabase.insert, table, data)

    async def update(self, table: str, data: Dict[str, Any], *, filters: Dict[str, Any]) -> List[Dict[str, Any]]:
        return await self._run(
            self._supabase.update,
            table,
            data,
            filters=self._stringify_filters(filters),
        )

    async def upsert(
        self,
        table: str,
        data: Dict[str, Any],
        *,
        on_conflict: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        return await self._run(self._supabase.upsert, table, data, on_conflict=on_conflict)

    async def delete(self, table: str, *, filters: Dict[str, Any]) -> List[Dict[str, Any]]:
        return await self._run(
            self._supabase.delete,
            table,
            filters=self._stringify_filters(filters),
        )

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    async def _run(self, func: Callable[..., Any], *args: Any, **kwargs: Any) -> Any:
        loop = asyncio.get_running_loop()
        bound = partial(func, *args, **kwargs)
        return await loop.run_in_executor(None, bound)

    def _stringify_filters(self, filters: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
        if filters is None:
            return None
        return {key: str(value) if isinstance(value, UUID) else value for key, value in filters.items()}


_database_instance: Database | None = None


def get_database(settings: "Settings" | None = None) -> Database:
    """Return a singleton :class:`Database` instance."""

    global _database_instance
    if _database_instance is None:
        if settings is None:
            from app.core.config import get_settings

            settings = get_settings()
        _database_instance = Database(settings)
    return _database_instance


async def connect_to_database() -> None:
    """Initialise the global Supabase client."""

    await get_database().connect()


async def close_database() -> None:
    """Compatibility shim for the previous interface."""

    await get_database().disconnect()


async def run_db_task(task: Callable[["Database"], Any]) -> Any:
    """Execute ``task`` with a connected :class:`Database` instance."""

    database = get_database()
    await database.connect()
    return await task(database)


def _load_supabase_default() -> "SupabaseDatabase":
    from app.database import db

    return db


def _resolve_supabase(supabase: "SupabaseDatabase" | None) -> "SupabaseDatabase":
    if supabase is not None:
        return supabase
    return _load_supabase_default()


__all__ = [
    "Database",
    "connect_to_database",
    "close_database",
    "get_database",
    "run_db_task",
]
