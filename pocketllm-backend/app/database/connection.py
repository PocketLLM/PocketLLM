"""
MANDATORY: Single database connection using ONLY official Supabase SDK.
ZERO fallbacks, ZERO alternatives, ZERO local storage.
"""

from __future__ import annotations

import json
import logging
import os
from datetime import datetime
from typing import Any, Dict, List, Optional, Sequence, Union

from dotenv import load_dotenv
from postgrest.exceptions import APIError
from supabase import Client, create_client

from app.utils.serializers import serialize_dates_for_json

logger = logging.getLogger(__name__)

# Load environment variables from a `.env` file if present so that runtime
# processes (including the development server reloader) have access to the
# Supabase credentials before the singleton initialises.
_ENV_LOADED = load_dotenv(override=False)
if _ENV_LOADED:
    logger.info("✅ Loaded environment variables from .env file")


class SupabaseDatabase:
    """ENFORCED: Official Supabase SDK ONLY implementation."""

    _instance: Optional["SupabaseDatabase"] = None
    _client: Optional[Client] = None

    def __new__(cls) -> "SupabaseDatabase":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self) -> None:
        if getattr(self, "_initialised", False):
            return
        self._initialised = True
        self._setup_connection()

    # ------------------------------------------------------------------
    # Connection management
    # ------------------------------------------------------------------
    def _setup_connection(self) -> None:
        """Initialise the client using ONLY the official Supabase SDK."""

        try:
            url = os.getenv("DATABASE_URL") or os.getenv("SUPABASE_URL")
            service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_SERVICE_ROLE")
            public_key = os.getenv("SUPABASE_PUBLIC_KEY") or os.getenv("SUPABASE_ANON_KEY")
            key = service_key or public_key

            if not url or not key:
                logger.critical("❌ FATAL: Missing Supabase credentials - APPLICATION CANNOT START")
                raise ValueError(
                    "CRITICAL: Missing Supabase credentials. "
                    "DATABASE_URL and a Supabase key are REQUIRED. "
                    "Provide SUPABASE_SERVICE_ROLE_KEY (preferred) or SUPABASE_PUBLIC_KEY. "
                    "NO fallback options available."
                )

            self._client = create_client(url, key)

            if service_key:
                logger.info("✅ USING SERVICE-ROLE Supabase credentials for SDK client")

            if not self._test_connection():
                logger.critical("❌ FATAL: Supabase connection test failed - APPLICATION CANNOT START")
                raise ConnectionError("Supabase connection test failed - NO fallback available")

            logger.info("✅ VERIFIED: Official Supabase SDK connection established")
        except Exception as exc:  # pragma: no cover - critical path
            logger.critical("❌ FATAL: Supabase connection failed: %s", exc)
            logger.critical("🚨 NO FALLBACK OPTIONS - APPLICATION MUST NOT START")
            raise

    def _test_connection(self) -> bool:
        """Perform a lightweight query to validate connectivity."""

        try:
            assert self._client is not None
            self._client.table("profiles").select("id").limit(1).execute()
            return True
        except Exception as exc:  # pragma: no cover - diagnostic helper
            logger.error("❌ Connection test failed: %s", exc)
            return False

    @property
    def client(self) -> Client:
        if self._client is None:
            logger.critical("❌ FATAL: No Supabase client available")
            raise RuntimeError("No Supabase client - application cannot continue")
        return self._client

    # ------------------------------------------------------------------
    # Logging helpers
    # ------------------------------------------------------------------
    def _log_operation(
        self,
        operation: str,
        table: str,
        *,
        data: Any = None,
        filters: Optional[Dict[str, Any]] = None,
    ) -> None:
        log_data = {
            "operation": operation,
            "table": table,
            "timestamp": datetime.utcnow().isoformat(),
            "has_data": data is not None,
            "has_filters": filters is not None,
        }
        logger.info("🔄 DB_OPERATION: %s", json.dumps(log_data))

    # ------------------------------------------------------------------
    # Profile helpers
    # ------------------------------------------------------------------
    def upsert_profile(self, user_id: str, profile_data: Dict[str, Any]) -> Dict[str, Any]:
        self._log_operation("upsert_profile", "profiles", data=profile_data, filters={"user_id": user_id})

        try:
            payload = {
                "id": user_id,
                **profile_data,
                "updated_at": datetime.utcnow(),
            }
            payload = self._serialise_for_supabase(payload)
            result = (
                self.client
                .table("profiles")
                .upsert(payload, on_conflict="id")
                .execute()
            )
            if not result.data:
                logger.error("❌ CRITICAL: Profile upsert returned no data for user %s", user_id)
                raise RuntimeError(f"Profile upsert failed for user {user_id} - NO fallback available")

            record = result.data[0]
            self._verify_persistence("profiles", record.get("id", user_id))
            logger.info("✅ VERIFIED: Profile persisted to Supabase for user %s", user_id)
            return record
        except Exception as exc:
            logger.critical("❌ CRITICAL: Profile upsert failed for user %s: %s", user_id, exc)
            logger.critical("🚨 NO FALLBACK - Operation must be retried or fail")
            raise

    def get_profile(self, user_id: str) -> Optional[Dict[str, Any]]:
        self._log_operation("get_profile", "profiles", filters={"user_id": user_id})

        try:
            result = (
                self.client
                .table("profiles")
                .select("*")
                .eq("id", user_id)
                .single()
                .execute()
            )
            logger.info("✅ Profile retrieved from Supabase for user %s", user_id)
            return result.data if result.data else None
        except APIError as exc:
            if "PGRST116" in str(exc):
                logger.info("ℹ️ No profile found in Supabase for user %s", user_id)
                return None
            logger.error("❌ Error retrieving profile for user %s: %s", user_id, exc)
            raise
        except Exception as exc:
            logger.critical("❌ CRITICAL: Unexpected error retrieving profile for user %s: %s", user_id, exc)
            raise

    def update_profile(self, user_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        self._log_operation("update_profile", "profiles", data=updates, filters={"user_id": user_id})

        try:
            payload = {**updates, "updated_at": datetime.utcnow()}
            payload = self._serialise_for_supabase(payload)
            result = (
                self.client
                .table("profiles")
                .update(payload)
                .eq("id", user_id)
                .execute()
            )
            if not result.data:
                logger.info("ℹ️ No profile found to update for user %s", user_id)
                return None

            record = result.data[0]
            logger.info("✅ Profile updated successfully for user %s", user_id)
            return record
        except Exception as exc:
            logger.critical("❌ CRITICAL: Error updating profile for user %s: %s", user_id, exc)
            raise

    def _verify_persistence(self, table: str, record_id: Any) -> None:
        try:
            result = (
                self.client
                .table(table)
                .select("id")
                .eq("id", record_id)
                .execute()
            )
            if not result.data:
                logger.critical(
                    "❌ CRITICAL: Data NOT persisted - %s:%s not found in Supabase", table, record_id
                )
                raise RuntimeError(f"Data persistence verification failed for {table}:{record_id}")
            logger.info("✅ VERIFIED: Data persisted in Supabase - %s:%s", table, record_id)
        except Exception as exc:
            logger.critical("❌ CRITICAL: Persistence verification failed: %s", exc)
            raise

    # ------------------------------------------------------------------
    # Generic CRUD helpers
    # ------------------------------------------------------------------
    def select(
        self,
        table: str,
        *,
        columns: str = "*",
        filters: Optional[Dict[str, Any]] = None,
        limit: Optional[int] = None,
        order_by: Optional[Union[str, Sequence[Union[str, tuple[str, bool], Dict[str, Any]]]]] = None,
    ) -> List[Dict[str, Any]]:
        self._log_operation("select", table, filters=filters)

        try:
            serialised_filters = self._serialise_for_supabase(filters) if filters else None

            query = self.client.table(table).select(columns)
            if filters:
                for key, value in serialised_filters.items():
                    query = query.eq(key, value)

            for column, descending in self._normalise_order(order_by):
                query = query.order(column, desc=descending)

            if limit is not None:
                query = query.limit(limit)

            result = query.execute()
            logger.info("✅ Selected %s records from %s", len(result.data or []), table)
            return result.data or []
        except Exception as exc:
            logger.critical("❌ CRITICAL: Select failed for %s: %s", table, exc)
            raise

    def insert(self, table: str, data: Union[Dict[str, Any], List[Dict[str, Any]]]) -> List[Dict[str, Any]]:
        self._log_operation("insert", table, data=data)

        try:
            payload = self._serialise_for_supabase(data)
            result = self.client.table(table).insert(payload).execute()
            if not result.data:
                logger.critical("❌ CRITICAL: Insert failed for %s - no data returned", table)
                raise RuntimeError(f"Insert operation failed for {table}")

            records = result.data
            if isinstance(payload, dict) and "id" in payload:
                self._verify_persistence(table, payload["id"])
            logger.info("✅ VERIFIED: Inserted %s records into %s", len(records), table)
            return records
        except Exception as exc:
            logger.critical("❌ CRITICAL: Insert failed for %s: %s", table, exc)
            raise

    def update(
        self,
        table: str,
        data: Dict[str, Any],
        *,
        filters: Dict[str, Any],
    ) -> List[Dict[str, Any]]:
        self._log_operation("update", table, data=data, filters=filters)

        try:
            payload = self._serialise_for_supabase(data)
            serialised_filters = self._serialise_for_supabase(filters)

            query = self.client.table(table).update(payload)
            for key, value in serialised_filters.items():
                query = query.eq(key, value)
            result = query.execute()
            logger.info("✅ Updated %s records in %s", len(result.data or []), table)
            return result.data or []
        except Exception as exc:
            logger.critical("❌ CRITICAL: Update failed for %s: %s", table, exc)
            raise

    def upsert(
        self,
        table: str,
        data: Union[Dict[str, Any], List[Dict[str, Any]]],
        *,
        on_conflict: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        self._log_operation("upsert", table, data=data)

        try:
            payload = self._serialise_for_supabase(data)
            upsert_kwargs: Dict[str, Any] = {}
            if on_conflict:
                upsert_kwargs["on_conflict"] = on_conflict

            try:
                query = self.client.table(table).upsert(payload, **upsert_kwargs)
            except TypeError as exc:
                # Older versions of the Supabase SDK did not expose the
                # ``on_conflict`` keyword argument. These clients instead
                # require chaining ``.on_conflict()`` after the upsert call.
                if on_conflict and "on_conflict" in str(exc):
                    logger.warning(
                        "Supabase client does not support on_conflict keyword; retrying with chained on_conflict()."
                    )
                    legacy_query = self.client.table(table).upsert(payload)
                    if not hasattr(legacy_query, "on_conflict"):
                        raise
                    query = legacy_query.on_conflict(on_conflict)
                else:
                    raise

            result = query.execute()
            if not result.data:
                logger.critical("❌ CRITICAL: Upsert failed for %s - no data returned", table)
                raise RuntimeError(f"Upsert operation failed for {table}")
            logger.info("✅ VERIFIED: Upserted %s records in %s", len(result.data), table)
            return result.data
        except Exception as exc:
            logger.critical("❌ CRITICAL: Upsert failed for %s: %s", table, exc)
            raise

    def delete(self, table: str, *, filters: Dict[str, Any]) -> List[Dict[str, Any]]:
        self._log_operation("delete", table, filters=filters)

        try:
            serialised_filters = self._serialise_for_supabase(filters)

            query = self.client.table(table)
            for key, value in serialised_filters.items():
                query = query.eq(key, value)
            result = query.delete().execute()
            logger.info("✅ Deleted records from %s", table)
            return result.data or []
        except Exception as exc:
            logger.critical("❌ CRITICAL: Delete failed for %s: %s", table, exc)
            raise

    def test_connection(self) -> bool:
        return self._test_connection()

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _normalise_order(
        self,
        order_by: Optional[Union[str, Sequence[Union[str, tuple[str, bool], Dict[str, Any]]]]],
    ) -> List[tuple[str, bool]]:
        if not order_by:
            return []

        entries: Sequence[Union[str, tuple[str, bool], Dict[str, Any]]]
        if isinstance(order_by, (str, tuple, dict)):
            entries = (order_by,)  # type: ignore[assignment]
        else:
            entries = order_by

        normalised: List[tuple[str, bool]] = []
        for entry in entries:
            column: Optional[str] = None
            descending = False
            if isinstance(entry, tuple):
                column = str(entry[0])
                descending = bool(entry[1])
            elif isinstance(entry, dict):
                column = str(entry.get("column")) if entry.get("column") else None
                descending = not bool(entry.get("ascending", True))
            else:
                token = str(entry).replace(":", ".")
                if token.lower().endswith(".desc"):
                    column = token.rsplit(".", 1)[0]
                    descending = True
                elif token.lower().endswith(".asc"):
                    column = token.rsplit(".", 1)[0]
                else:
                    column = token
            if column:
                normalised.append((column, descending))
        return normalised

    def _serialise_for_supabase(self, value: Any) -> Any:
        if value is None:
            return None
        return serialize_dates_for_json(value)


db = SupabaseDatabase()

__all__ = ["SupabaseDatabase", "db"]
