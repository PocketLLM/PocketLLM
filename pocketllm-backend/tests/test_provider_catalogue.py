import asyncio
from datetime import UTC, datetime
from types import SimpleNamespace
from typing import Any, AsyncIterator, Mapping
from uuid import uuid4

import httpx
import pytest

from app.core.config import Settings
from app.schemas.providers import ProviderConfiguration, ProviderModel
from app.services.providers import (
    ProviderClient,
    GroqProviderClient,
    GroqSDKService,
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


class RecordingProviderClient(ProviderClient):
    provider = "openai"
    default_base_url = "https://api.test"
    requires_api_key = False

    def __init__(
        self,
        settings: Settings,
        *,
        base_url: str | None = None,
        api_key: str | None = None,
        metadata: Mapping[str, Any] | None = None,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self.initialiser_calls.append(
            {
                "base_url": base_url,
                "api_key": api_key,
                "metadata": dict(metadata or {}),
            }
        )
        super().__init__(
            settings,
            base_url=base_url,
            api_key=api_key,
            metadata=metadata,
            transport=transport,
        )

    initialiser_calls: list[dict[str, Any]] = []

    async def list_models(self) -> list[ProviderModel]:
        return [ProviderModel(provider=self.provider, id="openai:test", name="OpenAI Test")]

    def _parse_models(self, payload: Any) -> list[ProviderModel]:  # pragma: no cover - unused
        return []


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
async def test_catalogue_requires_active_provider_configuration():
    RecordingProviderClient.initialiser_calls = []
    settings = Settings()
    catalogue = ProviderModelCatalogue(
        settings,
        client_factories={"openai": RecordingProviderClient},
    )
    configuration = ProviderConfiguration(
        id=uuid4(),
        user_id=uuid4(),
        provider="openai",
        display_name=None,
        base_url="https://custom.openai.test",
        metadata={"api_key": "user-key", "http_referer": "https://app.example"},
        api_key_preview="user****key",
        is_active=True,
        created_at=datetime.now(tz=UTC),
        updated_at=datetime.now(tz=UTC),
    )

    models = await catalogue.list_all_models([configuration])

    assert models[0].provider == "openai"
    assert RecordingProviderClient.initialiser_calls
    call = RecordingProviderClient.initialiser_calls[0]
    assert call["base_url"] == "https://custom.openai.test"
    assert call["api_key"] == "user-key"
    assert call["metadata"]["http_referer"] == "https://app.example"


@pytest.mark.asyncio
async def test_catalogue_skips_inactive_provider_configuration():
    RecordingProviderClient.initialiser_calls = []
    settings = Settings()
    catalogue = ProviderModelCatalogue(
        settings,
        client_factories={"openai": RecordingProviderClient},
    )
    inactive_configuration = ProviderConfiguration(
        id=uuid4(),
        user_id=uuid4(),
        provider="openai",
        display_name=None,
        base_url=None,
        metadata={"api_key": "user-key"},
        api_key_preview="user****key",
        is_active=False,
        created_at=datetime.now(tz=UTC),
        updated_at=datetime.now(tz=UTC),
    )

    models = await catalogue.list_all_models([inactive_configuration])

    assert models == []
    assert RecordingProviderClient.initialiser_calls == []


@pytest.mark.asyncio
async def test_catalogue_list_models_for_provider_requires_user_configuration(caplog):
    RecordingProviderClient.initialiser_calls = []
    settings = Settings()
    catalogue = ProviderModelCatalogue(
        settings,
        client_factories={"openai": RecordingProviderClient},
    )

    with caplog.at_level("WARNING"):
        models = await catalogue.list_models_for_provider("openai", [])

    assert models == []
    assert "not configured" in caplog.text


@pytest.mark.asyncio
async def test_catalogue_uses_environment_fallback_configuration(caplog):
    RecordingProviderClient.initialiser_calls = []
    settings = Settings(openai_api_key="env-key", openai_api_base="https://env.openai")
    catalogue = ProviderModelCatalogue(
        settings,
        client_factories={"openai": RecordingProviderClient},
    )

    with caplog.at_level("INFO"):
        models = await catalogue.list_models_for_provider("openai", [])

    assert len(models) == 1
    assert models[0].provider == "openai"
    assert RecordingProviderClient.initialiser_calls
    call = RecordingProviderClient.initialiser_calls[0]
    assert call["api_key"] == "env-key"
    assert call["base_url"] == "https://env.openai"
    assert "environment fallback" in caplog.text.lower()


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


class FakeGroqModelsResource:
    def __init__(self, payload: Any | Exception):
        self._payload = payload

    async def list(self) -> Any:
        if isinstance(self._payload, Exception):
            raise self._payload
        return self._payload


class FakeGroqClient:
    def __init__(self, payload: Any | Exception):
        self.models = FakeGroqModelsResource(payload)
        self.closed = False

    async def close(self) -> None:
        self.closed = True


class RecordingGroqClient:
    def __init__(self, stream_chunks: list[str] | None = None) -> None:
        self.stream_chunks = stream_chunks or []
        self.calls: list[tuple[str, Mapping[str, Any]]] = []
        self.chat = SimpleNamespace(
            completions=SimpleNamespace(create=self._chat_create)
        )
        self.responses = SimpleNamespace(create=self._responses_create)
        self.audio = SimpleNamespace(
            transcriptions=SimpleNamespace(create=self._transcriptions_create),
            translations=SimpleNamespace(create=self._translations_create),
            speech=SimpleNamespace(create=self._speech_create),
        )
        self._closed = False

    async def _chat_create(self, **kwargs: Any) -> Any:
        self.calls.append(("chat", kwargs))
        if kwargs.get("stream"):

            async def _stream() -> AsyncIterator[str]:
                for chunk in self.stream_chunks:
                    yield chunk

            return _stream()
        return {"id": "chat", "model": kwargs.get("model")}

    async def _responses_create(self, **kwargs: Any) -> Any:
        self.calls.append(("responses", kwargs))
        return {"id": "response", "model": kwargs.get("model")}

    async def _transcriptions_create(self, **kwargs: Any) -> Any:
        self.calls.append(("transcriptions", kwargs))
        return {"id": "transcription"}

    async def _translations_create(self, **kwargs: Any) -> Any:
        self.calls.append(("translations", kwargs))
        return {"id": "translation"}

    async def _speech_create(self, **kwargs: Any) -> Any:
        self.calls.append(("speech", kwargs))
        return {"id": "speech"}

    async def close(self) -> None:
        self._closed = True


@pytest.mark.asyncio
async def test_groq_provider_client_requires_api_key():
    factory_calls: list[Mapping[str, Any]] = []

    def factory(**kwargs: Any) -> FakeGroqClient:
        factory_calls.append(kwargs)
        return FakeGroqClient({"data": []})

    settings = Settings()
    client = GroqProviderClient(settings, client_factory=factory)

    models = await client.list_models()

    assert models == []
    assert factory_calls == []


@pytest.mark.asyncio
async def test_groq_provider_client_uses_sdk_payload(caplog):
    payload = {
        "data": [
            {
                "id": "llama-3.3-70b-versatile",
                "name": "LLaMA 3.3 70B Versatile",
                "context_window": 131072,
                "max_output_tokens": 32768,
                "active": True,
                "capabilities": {"reasoning": True},
            }
        ]
    }

    created_clients: list[FakeGroqClient] = []

    def factory(**kwargs: Any) -> FakeGroqClient:
        created_clients.append(FakeGroqClient(payload))
        return created_clients[-1]

    settings = Settings(groq_api_key="test-key", groq_api_base="https://custom.groq")
    client = GroqProviderClient(settings, client_factory=factory)

    models = await client.list_models()

    assert len(models) == 1
    model = models[0]
    assert model.id == "llama-3.3-70b-versatile"
    assert model.context_window == 131072
    assert model.max_output_tokens == 32768
    assert model.metadata == {"capabilities": {"reasoning": True}}
    assert created_clients and created_clients[0].closed is True


@pytest.mark.asyncio
async def test_groq_provider_client_handles_sdk_errors(caplog):
    error = RuntimeError("boom")

    def factory(**kwargs: Any) -> FakeGroqClient:
        return FakeGroqClient(error)

    settings = Settings(groq_api_key="test-key")
    client = GroqProviderClient(settings, client_factory=factory)

    with caplog.at_level("ERROR"):
        models = await client.list_models()

    assert models == []
    assert "Groq SDK request failed" in caplog.text or "Unexpected error" in caplog.text


@pytest.mark.asyncio
async def test_groq_sdk_service_invokes_official_client():
    created_clients: list[RecordingGroqClient] = []
    factory_kwargs: list[Mapping[str, Any]] = []

    def factory(**kwargs: Any) -> RecordingGroqClient:
        factory_kwargs.append(kwargs)
        client = RecordingGroqClient(stream_chunks=["chunk-1", "chunk-2"])
        created_clients.append(client)
        return client

    settings = Settings(groq_api_key="sdk-key")
    service = GroqSDKService(settings, client_factory=factory)

    chat = await service.create_chat_completion(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": "Hello"}],
    )
    assert chat["id"] == "chat"

    chunks: list[str] = []
    async for chunk in service.stream_chat_completion(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": "Stream"}],
    ):
        chunks.append(chunk)
    assert chunks == ["chunk-1", "chunk-2"]

    response = await service.create_response(model="moonshot", input="Hi")
    assert response["id"] == "response"

    transcription = await service.transcribe_audio(file="file", model="whisper-large-v3")
    assert transcription["id"] == "transcription"

    translation = await service.translate_audio(file="file", model="whisper-large-v3")
    assert translation["id"] == "translation"

    speech = await service.synthesize_speech(
        input_text="Hello", model="playai-tts", voice="Fritz-PlayAI"
    )
    assert speech["id"] == "speech"

    assert all(client._closed for client in created_clients)
    assert factory_kwargs and factory_kwargs[0]["api_key"] == "sdk-key"
    assert any(call[0] == "chat" for call in created_clients[0].calls)


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
