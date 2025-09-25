"""Database connection management for Supabase Postgres."""

from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager
from typing import Any, AsyncIterator, Callable, Optional

import asyncpg

from .config import Settings, get_settings

logger = logging.getLogger(__name__)


class Database:
    """Async connection manager backed by :mod:`asyncpg`."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._pool: Optional[asyncpg.Pool] = None
        self._lock = asyncio.Lock()

    async def connect(self) -> None:
        """Create the connection pool if it has not been initialised."""

        if self._pool is not None:
            return

        async with self._lock:
            if self._pool is None:
                if not self._settings.database_url:
                    logger.warning("Database URL is not configured. Running in mock mode.")
                    return
                self._pool = await asyncpg.create_pool(
                    dsn=self._settings.database_url,
                    min_size=self._settings.database_pool_min_size,
                    max_size=self._settings.database_pool_max_size,
                    command_timeout=self._settings.database_statement_timeout / 1000,
                )

    async def disconnect(self) -> None:
        """Close the connection pool."""

        if self._pool is None:
            return

        async with self._lock:
            if self._pool is not None:
                await self._pool.close()
                self._pool = None

    @asynccontextmanager
    async def connection(self) -> AsyncIterator[asyncpg.Connection]:
        """Acquire a database connection for the duration of the context."""

        if self._pool is None:
            await self.connect()

        # If we're in mock mode (no database URL), yield a mock connection
        if self._pool is None:
            raise RuntimeError("Database is not configured. Cannot establish connection.")
            
        assert self._pool is not None, "Database pool is not initialised"
        connection = await self._pool.acquire()
        try:
            yield connection
        finally:
            await self._pool.release(connection)

    @asynccontextmanager
    async def transaction(self) -> AsyncIterator[asyncpg.Connection]:
        """Acquire a connection and wrap calls in a transaction."""

        async with self.connection() as connection:
            async with connection.transaction():
                yield connection

    async def fetch(self, query: str, *args: Any) -> list[asyncpg.Record]:
        async with self.connection() as connection:
            return await connection.fetch(query, *args)

    async def fetchrow(self, query: str, *args: Any) -> asyncpg.Record | None:
        async with self.connection() as connection:
            return await connection.fetchrow(query, *args)

    async def fetchval(self, query: str, *args: Any) -> Any:
        async with self.connection() as connection:
            return await connection.fetchval(query, *args)

    async def execute(self, query: str, *args: Any) -> str:
        async with self.connection() as connection:
            return await connection.execute(query, *args)


_database_instance: Database | None = None


def get_database(settings: Settings | None = None) -> Database:
    """Return a singleton :class:`Database` instance."""

    global _database_instance
    if _database_instance is None:
        resolved_settings = settings or get_settings()
        _database_instance = Database(resolved_settings)
    return _database_instance


async def connect_to_database() -> None:
    """Initialise the global database pool."""

    try:
        await get_database().connect()
    except Exception as e:
        logger.warning(f"Failed to connect to database: {e}. Running in mock mode.")


async def close_database() -> None:
    """Close the global database pool."""

    await get_database().disconnect()


async def run_db_task(task: Callable[[asyncpg.Connection], Any]) -> Any:
    """Helper to run an operation with a managed connection."""

    database = get_database()
    async with database.connection() as connection:
        return await task(connection)


__all__ = [
    "Database",
    "connect_to_database",
    "close_database",
    "get_database",
    "run_db_task",
]