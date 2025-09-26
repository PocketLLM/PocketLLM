"""Database connection management for Supabase Postgres."""

from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import UTC, date, datetime
from typing import Any, AsyncIterator, Callable, Optional
from uuid import UUID

import asyncpg

from .config import Settings, get_settings

logger = logging.getLogger(__name__)


def _normalise_query(query: str) -> str:
    """Return a normalised representation of the SQL statement."""

    return " ".join(query.strip().lower().split())


@dataclass
class _ProfileRecord:
    """In-memory representation of a row in ``public.profiles``."""

    id: UUID
    email: str = ""
    full_name: str | None = None
    username: str | None = None
    bio: str | None = None
    date_of_birth: date | None = None
    age: int | None = None
    profession: str | None = None
    heard_from: str | None = None
    avatar_url: str | None = None
    survey_completed: bool = False
    onboarding_responses: dict | None = None
    deletion_status: str = "active"
    deletion_requested_at: datetime | None = None
    deletion_scheduled_for: datetime | None = None
    created_at: datetime = field(default_factory=lambda: datetime.now(tz=UTC))
    updated_at: datetime = field(default_factory=lambda: datetime.now(tz=UTC))

    def as_dict(self) -> dict[str, Any]:
        """Return a mutable dictionary copy of the record."""

        return {
            "id": self.id,
            "email": self.email,
            "full_name": self.full_name,
            "username": self.username,
            "bio": self.bio,
            "date_of_birth": self.date_of_birth,
            "age": self.age,
            "profession": self.profession,
            "heard_from": self.heard_from,
            "avatar_url": self.avatar_url,
            "survey_completed": self.survey_completed,
            "onboarding_responses": self.onboarding_responses,
            "deletion_status": self.deletion_status,
            "deletion_requested_at": self.deletion_requested_at,
            "deletion_scheduled_for": self.deletion_scheduled_for,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
        }


class _MockConnection:
    """Lightweight stand-in for :class:`asyncpg.Connection`."""

    def __init__(self, store: "_InMemoryStore") -> None:
        self._store = store

    async def fetch(self, query: str, *args: Any) -> list[dict[str, Any]]:
        return await self._store.fetch(query, *args)

    async def fetchrow(self, query: str, *args: Any) -> dict[str, Any] | None:
        return await self._store.fetchrow(query, *args)

    async def fetchval(self, query: str, *args: Any) -> Any:
        return await self._store.fetchval(query, *args)

    async def execute(self, query: str, *args: Any) -> str:
        return await self._store.execute(query, *args)

    @asynccontextmanager
    async def transaction(self) -> AsyncIterator["_MockConnection"]:
        yield self


class _InMemoryStore:
    """In-memory fallback implementation when Postgres is unavailable."""

    def __init__(self) -> None:
        self._profiles: dict[UUID, _ProfileRecord] = {}

    async def fetch(self, query: str, *args: Any) -> list[dict[str, Any]]:
        row = await self.fetchrow(query, *args)
        return [row] if row else []

    async def fetchrow(self, query: str, *args: Any) -> dict[str, Any] | None:
        normalised = _normalise_query(query)
        if normalised.startswith("select * from public.profiles where id = $1"):
            profile = self._profiles.get(args[0])
            return profile.as_dict() if profile else None
        if normalised.startswith("update public.profiles set"):
            return await self._handle_profiles_update(query, *args)
        logger.warning("Mock database received unsupported fetchrow query: %s", query)
        return None

    async def fetchval(self, query: str, *args: Any) -> Any:
        rows = await self.fetch(query, *args)
        if not rows:
            return None
        return next(iter(rows[0].values()))

    async def execute(self, query: str, *args: Any) -> str:
        normalised = _normalise_query(query)
        if normalised.startswith("insert into public.profiles"):
            await self._upsert_profile(query, *args)
            return "INSERT 0 1"
        if normalised.startswith("update public.profiles set"):
            await self._handle_profiles_update(query, *args)
            return "UPDATE 1"
        logger.warning("Mock database received unsupported execute query: %s", query)
        return ""

    async def _upsert_profile(self, query: str, *args: Any) -> None:
        columns_section = query.split("(", 1)[1].split(")", 1)[0]
        column_names = [column.strip() for column in columns_section.split(",") if column.strip()]
        values = dict(zip(column_names, args))
        user_id: UUID = values["id"]
        now = datetime.now(tz=UTC)
        record = self._profiles.get(user_id)
        if record is None:
            record = _ProfileRecord(
                id=user_id,
                email=values.get("email", ""),
                full_name=values.get("full_name"),
            )
            record.created_at = now
            record.updated_at = now
            self._profiles[user_id] = record
        else:
            if "email" in values and values["email"]:
                record.email = values["email"]
            if "full_name" in values and values["full_name"] is not None:
                record.full_name = values["full_name"]
            record.updated_at = now

    async def _handle_profiles_update(self, query: str, *args: Any) -> dict[str, Any] | None:
        normalised = _normalise_query(query)
        user_id: UUID = args[0]
        record = self._profiles.get(user_id)
        if record is None:
            return None
        now = datetime.now(tz=UTC)

        if "set survey_completed = $2" in normalised:
            record.survey_completed = bool(args[1])
            record.onboarding_responses = args[2]
            record.updated_at = now
            return record.as_dict()

        if "set deletion_status = 'pending'" in normalised:
            record.deletion_status = "pending"
            record.deletion_requested_at = now
            record.deletion_scheduled_for = args[1]
            record.updated_at = now
            return {
                "deletion_requested_at": record.deletion_requested_at,
                "deletion_scheduled_for": record.deletion_scheduled_for,
            }

        if "set deletion_status = 'active'" in normalised and "$2" not in normalised:
            record.deletion_status = "active"
            record.deletion_requested_at = None
            record.deletion_scheduled_for = None
            record.updated_at = now
            return record.as_dict()

        set_clause = query.split("SET", 1)[1].split("updated_at", 1)[0]
        columns = [part.split("=")[0].strip() for part in set_clause.split(",") if "=" in part]
        for column, value in zip(columns, args[1:]):
            setattr(record, column, value)
        record.updated_at = now
        return record.as_dict()


class Database:
    """Async connection manager backed by :mod:`asyncpg`."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._pool: Optional[asyncpg.Pool] = None
        self._lock = asyncio.Lock()
        self._mock_store: _InMemoryStore | None = None

    async def connect(self) -> None:
        """Create the connection pool if it has not been initialised."""

        if self._pool is not None:
            return

        async with self._lock:
            if self._pool is None:
                if not self._settings.database_url:
                    if self._mock_store is None:
                        self._mock_store = _InMemoryStore()
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

        if self._pool is None:
            if self._mock_store is None:
                raise RuntimeError("Database is not configured. Cannot establish connection.")
            yield _MockConnection(self._mock_store)
            return

        connection = await self._pool.acquire()
        try:
            yield connection
        finally:
            await self._pool.release(connection)

    @asynccontextmanager
    async def transaction(self) -> AsyncIterator[asyncpg.Connection]:
        """Acquire a connection and wrap calls in a transaction."""

        if self._pool is None and self._mock_store is not None:
            async with _MockConnection(self._mock_store).transaction() as connection:
                yield connection
            return

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