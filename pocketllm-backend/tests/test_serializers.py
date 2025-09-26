from datetime import date, datetime, timezone

from app.utils.serializers import serialize_dates_for_json


def test_serialize_dates_for_json_handles_nested_structures() -> None:
    payload = {
        "created_at": datetime(2024, 1, 2, 3, 4, 5, tzinfo=timezone.utc),
        "profile": {
            "birthday": date(1990, 7, 21),
            "aliases": ["Tester", date(2000, 1, 1)],
        },
        "events": (
            datetime(2023, 5, 6, 7, 8, 9),
            {"completed_at": datetime(2023, 5, 6, 7, 8, 9)},
        ),
    }

    serialised = serialize_dates_for_json(payload)

    assert serialised["created_at"] == "2024-01-02T03:04:05+00:00"
    assert serialised["profile"]["birthday"] == "1990-07-21"
    assert serialised["profile"]["aliases"][1] == "2000-01-01"
    assert serialised["events"][0] == "2023-05-06T07:08:09"
    assert serialised["events"][1]["completed_at"] == "2023-05-06T07:08:09"


def test_serialize_dates_for_json_returns_other_values_unchanged() -> None:
    payload = {"count": 5, "flag": False, "notes": ["keep", 10]}

    serialised = serialize_dates_for_json(payload)

    assert serialised == payload
