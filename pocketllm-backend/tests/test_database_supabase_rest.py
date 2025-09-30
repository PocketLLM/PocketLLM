from app.database.connection import SupabaseDatabase


def _dummy_supabase() -> SupabaseDatabase:
    instance = object.__new__(SupabaseDatabase)
    return instance  # type: ignore[return-value]


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
