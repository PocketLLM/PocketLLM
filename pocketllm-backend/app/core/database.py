"""Database connection management for Supabase Postgres."""

from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import UTC, date, datetime
from typing import Any, AsyncIterator, Callable, Optional, Protocol
from uuid import UUID

import asyncpg
import httpx

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


class _BaseStore(Protocol):
    async def fetch(self, query: str, *args: Any) -> list[dict[str, Any]]: ...

    async def fetchrow(self, query: str, *args: Any) -> dict[str, Any] | None: ...

    async def fetchval(self, query: str, *args: Any) -> Any: ...

    async def execute(self, query: str, *args: Any) -> str: ...


class _MockConnection:
    """Lightweight stand-in for :class:`asyncpg.Connection`."""

    def __init__(self, store: _BaseStore) -> None:
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


class _SupabaseRestStore:
    """Fallback store that persists data using Supabase PostgREST."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        supabase_url = str(settings.supabase_url)
        self._base_url = supabase_url.rstrip("/") + "/rest/v1"
        self._headers = {
            "apikey": settings.supabase_service_role_key,
            "Authorization": f"Bearer {settings.supabase_service_role_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        self._logger = logging.getLogger(f"{__name__}.supabase")
        self._fallback = _InMemoryStore()
        self._rest_available = True

    async def _handle_failure(
        self,
        operation: str,
        query: str,
        args: tuple[Any, ...],
        error: Exception,
    ) -> Any:
        if self._rest_available:
            self._rest_available = False
            self._logger.warning(
                "Supabase REST %s failed (%s). Falling back to in-memory store.",
                operation,
                error,
                exc_info=True,
            )
        else:
            self._logger.debug(
                "Supabase REST %s still unavailable: %s",
                operation,
                error,
                exc_info=True,
            )
        if isinstance(error, httpx.HTTPError):
            self._logger.debug(
                "Supabase REST error response",
                extra={"query": query},
                exc_info=True,
            )
        fallback_method = getattr(self._fallback, operation)
        return await fallback_method(query, *args)

    async def fetch(self, query: str, *args: Any) -> list[dict[str, Any]]:
        if not self._rest_available:
            return await self._fallback.fetch(query, *args)
        try:
            row = await self.fetchrow(query, *args)
        except Exception as exc:  # pragma: no cover - network failures
            return await self._handle_failure("fetch", query, args, exc)
        return [row] if row else []

    async def fetchrow(self, query: str, *args: Any) -> dict[str, Any] | None:
        if not self._rest_available:
            return await self._fallback.fetchrow(query, *args)
        try:
            normalised = _normalise_query(query)
            if normalised.startswith("select * from public.profiles where id = $1"):
                return await self._get_profile(args[0])
            if normalised.startswith("update public.profiles set"):
                return await self._handle_update(query, *args)
            self._logger.warning(
                "Supabase REST store received unsupported fetchrow query: %s", query
            )
            return None
        except Exception as exc:  # pragma: no cover - network failures
            return await self._handle_failure("fetchrow", query, args, exc)

    async def fetchval(self, query: str, *args: Any) -> Any:
        if not self._rest_available:
            return await self._fallback.fetchval(query, *args)
        try:
            rows = await self.fetch(query, *args)
        except Exception as exc:  # pragma: no cover - network failures
            return await self._handle_failure("fetchval", query, args, exc)
        if not rows:
            return None
        return next(iter(rows[0].values()))

    async def execute(self, query: str, *args: Any) -> str:
        if not self._rest_available:
            return await self._fallback.execute(query, *args)
        try:
            normalised = _normalise_query(query)
            if normalised.startswith("insert into public.profiles"):
                await self._upsert_profile(query, *args)
                return "INSERT 0 1"
            if normalised.startswith("update public.profiles set"):
                await self._handle_update(query, *args)
                return "UPDATE 1"
            self._logger.warning(
                "Supabase REST store received unsupported execute query: %s", query
            )
            return ""
        except Exception as exc:  # pragma: no cover - network failures
            return await self._handle_failure("execute", query, args, exc)

    async def _get_profile(self, user_id: UUID) -> dict[str, Any] | None:
        params = {"id": f"eq.{user_id}", "limit": 1}
        data = await self._request("GET", "profiles", params=params)
        if not data:
            return None
        return data[0]

    async def _upsert_profile(self, query: str, *args: Any) -> None:
        columns_section = query.split("(", 1)[1].split(")", 1)[0]
        column_names = [column.strip() for column in columns_section.split(",") if column.strip()]
        values = dict(zip(column_names, args))
        user_id = values.get("id")
        existing: dict[str, Any] | None = None
        if user_id:
            user_uuid = UUID(str(user_id))
            existing = await self._get_profile(user_uuid)
        else:
            user_uuid = None

        if existing and values.get("full_name") is None and existing.get("full_name"):
            values.pop("full_name", None)

        now = datetime.now(tz=UTC)
        if existing:
            update_values = dict(values)
            update_values.pop("created_at", None)
            update_values.pop("id", None)
            update_values["updated_at"] = now
            payload = self._serialise_payload(update_values)
            payload = {k: v for k, v in payload.items() if v is not None}
            await self._request(
                "PATCH",
                "profiles",
                params={"id": f"eq.{user_uuid}"},
                json_payload=payload,
                prefer="return=minimal",
            )
            return

        insert_values = dict(values)
        insert_values.setdefault("created_at", now)
        insert_values.setdefault("updated_at", now)
        payload = self._serialise_payload(insert_values)
        payload = {k: v for k, v in payload.items() if v is not None}
        prefer_header = "resolution=merge-duplicates, return=minimal"

        try:
            await self._request(
                "POST",
                "profiles",
                params={"on_conflict": "id"},
                json_payload=payload,
                prefer=prefer_header,
            )
        except httpx.HTTPStatusError as exc:
            if user_uuid and self._should_retry_as_update(exc):
                self._logger.info(
                    "Supabase profile insert detected duplicate. Retrying with PATCH.",
                    extra={"user_id": str(user_uuid)},
                )
                update_values = dict(values)
                update_values.pop("created_at", None)
                update_values.pop("id", None)
                update_values["updated_at"] = datetime.now(tz=UTC)
                update_payload = self._serialise_payload(update_values)
                update_payload = {k: v for k, v in update_payload.items() if v is not None}
                await self._request(
                    "PATCH",
                    "profiles",
                    params={"id": f"eq.{user_uuid}"},
                    json_payload=update_payload,
                    prefer="return=minimal",
                )
                return
            raise

    async def _handle_update(self, query: str, *args: Any) -> dict[str, Any] | None:
        user_id = args[0]
        assignments = self._parse_assignments(query, args)
        payload = self._serialise_payload(assignments)
        prefer = "return=representation"
        data = await self._request(
            "PATCH",
            "profiles",
            params={"id": f"eq.{user_id}"},
            json_payload=payload,
            prefer=prefer,
        )
        if not data:
            return None
        record = data[0]
        normalised = _normalise_query(query)
        if "returning deletion_requested_at" in normalised and "returning *" not in normalised:
            return {
                "deletion_requested_at": record.get("deletion_requested_at"),
                "deletion_scheduled_for": record.get("deletion_scheduled_for"),
            }
        return record

    def _parse_assignments(self, query: str, args: Any) -> dict[str, Any]:
        set_clause = query.split("SET", 1)[1]
        if "WHERE" in set_clause:
            set_clause = set_clause.split("WHERE", 1)[0]
        assignments: dict[str, Any] = {}
        for part in set_clause.split(","):
            if "=" not in part:
                continue
            column, value_expr = part.split("=", 1)
            column = column.strip()
            value_expr = value_expr.strip()
            lowered = value_expr.lower()
            if lowered == "now()":
                assignments[column] = datetime.now(tz=UTC)
            elif lowered.startswith("$"):
                index = int(lowered[1:]) - 1
                assignments[column] = args[index]
            elif value_expr.startswith("'") and value_expr.endswith("'"):
                assignments[column] = value_expr.strip("'")
            else:
                assignments[column] = value_expr
        assignments.setdefault("updated_at", datetime.now(tz=UTC))
        return assignments

    def _serialise_payload(self, payload: dict[str, Any]) -> dict[str, Any]:
        serialised: dict[str, Any] = {}
        for key, value in payload.items():
            if value is None:
                continue
            if isinstance(value, datetime):
                serialised[key] = value.astimezone(UTC).isoformat()
            elif isinstance(value, date):
                serialised[key] = value.isoformat()
            elif isinstance(value, UUID):
                serialised[key] = str(value)
            else:
                serialised[key] = value
        return serialised

    def _should_retry_as_update(self, exc: httpx.HTTPStatusError) -> bool:
        if exc.response is None:
            return False
        if exc.response.status_code not in {400, 409}:
            return False
        try:
            data = exc.response.json()
        except ValueError:
            message = exc.response.text.lower()
            return "duplicate key value" in message or "already exists" in message

        def _normalise(value: Any) -> str:
            return str(value or "").lower()

        code = _normalise(data.get("code"))
        message = _normalise(data.get("message"))
        details = _normalise(data.get("details"))
        combined = " ".join(part for part in (message, details) if part)
        if code in {"23505", "pgrst204"}:
            return True
        return "duplicate key value" in combined or "already exists" in combined

    async def _request(
        self,
        method: str,
        resource: str,
        *,
        params: dict[str, Any] | None = None,
        json_payload: Any | None = None,
        prefer: str | None = None,
    ) -> Any:
        headers = dict(self._headers)
        if prefer:
            headers["Prefer"] = prefer
        url = f"{self._base_url}/{resource}"
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.request(
                method,
                url,
                params=params,
                json=json_payload,
                headers=headers,
            )
        try:
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:  # pragma: no cover - network errors handled at runtime
            self._logger.error(
                "Supabase REST request failed",
                extra={
                    "method": method,
                    "url": url,
                    "status_code": exc.response.status_code,
                    "body": exc.response.text,
                },
            )
            raise
        if not response.content:
            return None
        if response.headers.get("content-type", "").startswith("application/json"):
            return response.json()
        return None

class Database:
    """Async connection manager backed by :mod:`asyncpg`."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._pool: Optional[asyncpg.Pool] = None
        self._lock = asyncio.Lock()
        self._fallback_store: _BaseStore | None = None

    def _should_use_supabase_rest(self) -> bool:
        service_role = (self._settings.supabase_service_role_key or "").strip()
        supabase_url = str(self._settings.supabase_url)
        return (
            bool(service_role)
            and service_role.lower() != "service-role-placeholder"
            and "example.supabase.co" not in supabase_url
        )

    async def connect(self) -> None:
        """Create the connection pool if it has not been initialised."""

        if self._pool is not None:
            return

        async with self._lock:
            if self._pool is None:
                if not self._settings.database_url:
                    if self._fallback_store is None:
                        if self._should_use_supabase_rest():
                            logger.warning("Database URL missing. Using Supabase REST fallback store.")
                            self._fallback_store = _SupabaseRestStore(self._settings)
                        else:
                            logger.warning("Database URL is not configured. Running in mock mode.")
                            self._fallback_store = _InMemoryStore()
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
            if self._fallback_store is None:
                raise RuntimeError("Database is not configured. Cannot establish connection.")
            yield _MockConnection(self._fallback_store)
            return

        connection = await self._pool.acquire()
        try:
            yield connection
        finally:
            await self._pool.release(connection)

    @asynccontextmanager
    async def transaction(self) -> AsyncIterator[asyncpg.Connection]:
        """Acquire a connection and wrap calls in a transaction."""

        if self._pool is None and self._fallback_store is not None:
            async with _MockConnection(self._fallback_store).transaction() as connection:
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