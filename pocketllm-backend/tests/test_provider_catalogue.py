import asyncio

import httpx
import pytest

from app.core.config import Settings
from app.schemas.providers import ProviderModel
from app.services.providers import (
    GroqProviderClient,
    OpenAIProviderClient,
    OpenRouterProviderClient,
    ProviderModelCatalogue,
)


class StubProviderClient:
    def __init__(self, provider: str, models: list[ProviderModel] | None = None, error: Exception | None = None):
        self.provider = provider
        self._models = models or []
        self._error = error

    async def list_models(self) -> list[ProviderModel]:
        if self._error:
            raise self._error
        await asyncio.sleep(0)
        return self._models


@pytest.mark.asyncio
async def test_catalogue_aggregates_models():
    settings = Settings()
    openai_model = ProviderModel(provider="openai", id="gpt-4o", name="GPT-4o")
    groq_model = ProviderModel(provider="groq", id="llama", name="Llama")
    catalogue = ProviderModelCatalogue(settings, clients=[
        StubProviderClient("openai", [openai_model]),
        StubProviderClient("groq", [groq_model]),
    ])

    models = await catalogue.list_all_models()

    assert {model.id for model in models} == {"gpt-4o", "llama"}
    assert {model.provider for model in models} == {"openai", "groq"}


@pytest.mark.asyncio
async def test_catalogue_filters_by_provider():
    settings = Settings()
    catalogue = ProviderModelCatalogue(settings, clients=[
        StubProviderClient("openai", [ProviderModel(provider="openai", id="gpt", name="GPT")]),
        StubProviderClient("groq", [ProviderModel(provider="groq", id="groq-1", name="Groq")]),
    ])

    groq_models = await catalogue.list_models_for_provider("groq")

    assert len(groq_models) == 1
    assert groq_models[0].provider == "groq"
    assert groq_models[0].id == "groq-1"


@pytest.mark.asyncio
async def test_catalogue_handles_provider_errors(caplog):
    settings = Settings()
    catalogue = ProviderModelCatalogue(settings, clients=[
        StubProviderClient("openrouter", error=RuntimeError("boom"))
    ])

    with caplog.at_level("ERROR"):
        models = await catalogue.list_all_models()

    assert models == []
    assert any("openrouter" in message for message in caplog.text.splitlines())


@pytest.mark.asyncio
async def test_openai_provider_client_parses_response():
    async def handler(request: httpx.Request) -> httpx.Response:  # pragma: no cover - simple mock
        assert request.headers["Authorization"].startswith("Bearer test-key")
        payload = {"data": [{"id": "gpt-test", "name": "GPT Test", "context_window": 1024}]}
        return httpx.Response(status_code=200, json=payload)

    settings = Settings(openai_api_key="test-key")
    client = OpenAIProviderClient(settings, transport=httpx.MockTransport(handler))

    models = await client.list_models()

    assert len(models) == 1
    model = models[0]
    assert model.provider == "openai"
    assert model.id == "gpt-test"
    assert model.context_window == 1024


@pytest.mark.asyncio
async def test_groq_provider_client_requires_api_key():
    settings = Settings()
    client = GroqProviderClient(settings)

    models = await client.list_models()

    assert models == []


@pytest.mark.asyncio
async def test_openrouter_provider_client_includes_headers():
    async def handler(request: httpx.Request) -> httpx.Response:
        assert request.headers["Authorization"].startswith("Bearer router-key")
        assert request.headers["HTTP-Referer"] == "https://example.com"
        assert request.headers["X-Title"] == "PocketLLM"
        return httpx.Response(status_code=200, json={"data": []})

    settings = Settings(
        openrouter_api_key="router-key",
        openrouter_app_url="https://example.com",
        openrouter_app_name="PocketLLM",
    )
    client = OpenRouterProviderClient(settings, transport=httpx.MockTransport(handler))

    models = await client.list_models()

    assert models == []
