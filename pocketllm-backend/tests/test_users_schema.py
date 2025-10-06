from __future__ import annotations

from app.schemas.users import OnboardingDetails, OnboardingSurvey


def test_onboarding_survey_uses_nested_payload() -> None:
    survey = OnboardingSurvey(
        full_name="Jane Doe",
        onboarding={
            "primary_goal": "Ship faster",
            "interests": ["Automation", "Productivity"],
            "experience_level": "Intermediate",
        },
    )

    responses = survey.resolved_onboarding_responses()

    assert responses["primary_goal"] == "Ship faster"
    assert responses["interests"] == ["Automation", "Productivity"]
    assert responses["experience_level"] == "Intermediate"


def test_onboarding_survey_prefers_explicit_responses() -> None:
    survey = OnboardingSurvey(
        onboarding_responses={"primary_goal": "Draft reports"},
        onboarding=OnboardingDetails(primary_goal="Should be ignored"),
    )

    responses = survey.resolved_onboarding_responses()

    assert responses == {"primary_goal": "Draft reports"}
