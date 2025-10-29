import logging
import os
import sys
import types

if "supabase" not in sys.modules:
    supabase_stub = types.ModuleType("supabase")

    class _StubQuery:
        def select(self, *args, **kwargs):  # type: ignore[no-untyped-def]
            return self

        def limit(self, *args, **kwargs):  # type: ignore[no-untyped-def]
            return self

        def execute(self):  # type: ignore[no-untyped-def]
            return types.SimpleNamespace(data=[])

    class _StubClient:
        def table(self, *_args, **_kwargs):  # type: ignore[no-untyped-def]
            return _StubQuery()

    def _create_client_stub(*_args, **_kwargs):  # type: ignore[no-untyped-def]
        return _StubClient()

    supabase_stub.Client = _StubClient
    supabase_stub.create_client = _create_client_stub
    sys.modules["supabase"] = supabase_stub

os.environ.setdefault("SUPABASE_URL", "https://example.supabase.co")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "service-role-key")

from app.database.connection import SupabaseDatabase


def _dummy_supabase() -> SupabaseDatabase:
    instance = object.__new__(SupabaseDatabase)
    return instance  # type: ignore[return-value]


class _RecordingClient:
    def __init__(self, *, fail_on_conflict: bool = False) -> None:
        self.fail_on_conflict = fail_on_conflict
        self.table_calls: list[str] = []
        self.upsert_calls: list[dict[str, object]] = []
        self.kwarg_calls: list[dict[str, object]] = []
        self.on_conflict_calls: list[str] = []
        self._payload: object | None = None

    def table(self, name: str) -> "_RecordingClient":
        self.table_calls.append(name)
        return self

    def upsert(self, payload, **kwargs):  # type: ignore[no-untyped-def]
        if self.fail_on_conflict and kwargs:
            raise TypeError("upsert() got an unexpected keyword argument 'on_conflict'")
        self.upsert_calls.append(payload)
        self.kwarg_calls.append(kwargs)
        self._payload = payload
        return self

    def on_conflict(self, target):  # type: ignore[no-untyped-def]
        self.on_conflict_calls.append(target)
        return self

    def execute(self):  # type: ignore[no-untyped-def]
        payload = self._payload
        if isinstance(payload, list):
            data = payload
        elif payload is None:
            data = []
        else:
            data = [payload]
        return types.SimpleNamespace(data=data)


def test_normalise_order_with_tuple() -> None:
    supabase = _dummy_supabase()
    result = SupabaseDatabase._normalise_order(supabase, [("created_at", True)])
    assert result == [("created_at", True)]


def test_normalise_order_with_string() -> None:
    supabase = _dummy_supabase()
    result = SupabaseDatabase._normalise_order(supabase, "updated_at.asc")
    assert result == [("updated_at", False)]


def test_normalise_order_with_dict() -> None:
    supabase = _dummy_supabase()
    result = SupabaseDatabase._normalise_order(
        supabase,
        {"column": "created_at", "ascending": False},
    )
    assert result == [("created_at", True)]


def test_upsert_passes_on_conflict_keyword(caplog) -> None:  # type: ignore[no-untyped-def]
    supabase = _dummy_supabase()
    client = _RecordingClient()
    supabase._client = client  # type: ignore[attr-defined]
    supabase._initialised = True  # type: ignore[attr-defined]

    caplog.set_level(logging.INFO)
    result = SupabaseDatabase.upsert(
        supabase,
        "providers",
        {"id": "123", "provider": "openai"},
        on_conflict="user_id,provider",
    )

    assert client.table_calls == ["providers"]
    assert client.kwarg_calls[0]["on_conflict"] == "user_id,provider"
    assert result == [{"id": "123", "provider": "openai"}]


def test_upsert_falls_back_when_on_conflict_unavailable(caplog) -> None:  # type: ignore[no-untyped-def]
    supabase = _dummy_supabase()
    client = _RecordingClient(fail_on_conflict=True)
    supabase._client = client  # type: ignore[attr-defined]
    supabase._initialised = True  # type: ignore[attr-defined]

    caplog.set_level(logging.WARNING, logger="app.database.connection")
    result = SupabaseDatabase.upsert(
        supabase,
        "providers",
        {"id": "456", "provider": "anthropic"},
        on_conflict="user_id,provider",
    )

    # The first attempt raises a TypeError which triggers a second call that
    # chains ``.on_conflict()`` instead of passing the keyword directly.
    assert client.kwarg_calls[-1] == {}
    assert client.on_conflict_calls == ["user_id,provider"]
    assert result == [{"id": "456", "provider": "anthropic"}]
    assert "retrying with chained on_conflict()" in caplog.text


def test_test_connection_respects_skip_environment(monkeypatch, caplog) -> None:  # type: ignore[no-untyped-def]
    supabase = _dummy_supabase()
    supabase._initialised = True  # type: ignore[attr-defined]

    called = False

    def _fake_test_connection(self):  # type: ignore[no-untyped-def]
        nonlocal called
        called = True
        return False

    monkeypatch.setattr(SupabaseDatabase, "_test_connection", _fake_test_connection)
    monkeypatch.setenv("SUPABASE_SKIP_CONNECTION_TEST", "true")

    caplog.set_level(logging.DEBUG, logger="app.database.connection")
    try:
        assert supabase.test_connection() is True
        assert called is False
        assert "skipping supabase test_connection" in caplog.text.lower()
    finally:
        monkeypatch.delenv("SUPABASE_SKIP_CONNECTION_TEST", raising=False)
