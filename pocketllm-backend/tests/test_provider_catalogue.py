import asyncio
from datetime import UTC, datetime
from types import SimpleNamespace
from typing import Any, AsyncIterator, Iterator, Mapping
from uuid import UUID, uuid4

import pytest

httpx = pytest.importorskip("httpx")

from app.schemas.providers import ProviderModel
from app.services.provider_configs import ProvidersService
from app.services.providers import (
    ProviderClient,
    GroqProviderClient,
    GroqSDKService,
    OpenAIProviderClient,
    OpenRouterProviderClient,
    ProviderModelCatalogue,
)
from database import ProviderRecord


@pytest.fixture(autouse=True)
def clear_provider_catalogue_cache() -> Iterator[None]:
    ProviderModelCatalogue.clear_cache()
    yield
    ProviderModelCatalogue.clear_cache()


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
        transport: Any | None = None,
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


class RecordingOpenAIClient:
    def __init__(self, payload: Any) -> None:
        self._payload = payload
        self.models = SimpleNamespace(list=self._list)
        self.closed = False

    async def _list(self) -> Any:
        return self._payload

    async def close(self) -> None:
        self.closed = True


class RecordingOpenRouterClient:
    def __init__(self, payload: Any) -> None:
        self._payload = payload
        self.models = SimpleNamespace(list=self._list)
        self.closed = False

    async def _list(self) -> Any:
        return self._payload

    async def close(self) -> None:
        self.closed = True


def make_settings(**overrides: Any) -> SimpleNamespace:
    defaults = {
        "openai_api_key": None,
        "openai_api_base": None,
        "groq_api_key": None,
        "groq_api_base": None,
        "openrouter_api_key": None,
        "openrouter_api_base": None,
        "openrouter_app_url": None,
        "openrouter_app_name": None,
        "provider_catalogue_cache_ttl": 0,
    }
    defaults.update(overrides)
    return SimpleNamespace(**defaults)


def make_provider_record(
    *,
    provider: str,
    user_id: UUID | None = None,
    api_key: str = "user-api-key",
    base_url: str | None = None,
    metadata: Mapping[str, Any] | None = None,
    is_active: bool = True,
) -> ProviderRecord:
    user = user_id or uuid4()
    now = datetime.now(tz=UTC)
    return ProviderRecord(
        id=uuid4(),
        user_id=user,
        provider=provider,
        display_name=None,
        base_url=base_url,
        metadata=dict(metadata or {}),
        api_key_hash="hash",
        api_key_preview="user****key",
        api_key_encrypted="encrypted",
        api_key=api_key,
        is_active=is_active,
        created_at=now,
        updated_at=now,
    )


class FakeCatalogue:
    def __init__(self, models: list[ProviderModel]) -> None:
        self._models = list(models)
        self.calls: list[tuple[str, Any]] = []

    async def list_all_models(self, providers: Any = None) -> list[ProviderModel]:
        self.calls.append(("all", providers))
        return list(self._models)

    async def list_models_for_provider(self, provider: str, providers: Any = None) -> list[ProviderModel]:
        self.calls.append((provider, providers))
        provider_key = provider.lower()
        return [model for model in self._models if model.provider.lower() == provider_key]


class FakeDatabase:
    async def select(self, *args: Any, **kwargs: Any) -> list[Mapping[str, Any]]:
        return []


@pytest.mark.asyncio
async def test_catalogue_aggregates_models():
    settings = make_settings()
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
    settings = make_settings()
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
    settings = make_settings()
    catalogue = ProviderModelCatalogue(settings, clients=[
        StubProviderClient("openrouter", error=RuntimeError("boom"))
    ])

    with caplog.at_level("ERROR"):
        models = await catalogue.list_all_models()

    assert models == []
    assert any("openrouter" in message for message in caplog.text.splitlines())


@pytest.mark.asyncio
async def test_catalogue_uses_cache_for_repeated_requests():
    class CountingClient:
        def __init__(self) -> None:
            self.provider = "openai"
            self.base_url = "https://example.test"
            self.metadata = {}
            self.calls = 0

        async def list_models(self) -> list[ProviderModel]:
            self.calls += 1
            await asyncio.sleep(0)
            return [ProviderModel(provider="openai", id="cached", name="Cached Model")]

    client = CountingClient()
    settings = make_settings(provider_catalogue_cache_ttl=300)
    catalogue = ProviderModelCatalogue(settings, clients=[client])

    first = await catalogue.list_all_models()
    second = await catalogue.list_all_models()

    assert first == second
    assert client.calls == 1


@pytest.mark.asyncio
async def test_catalogue_requires_active_provider_configuration():
    RecordingProviderClient.initialiser_calls = []
    settings = make_settings()
    catalogue = ProviderModelCatalogue(
        settings,
        client_factories={"openai": RecordingProviderClient},
    )
    configuration = SimpleNamespace(
        provider="openai",
        is_active=True,
        base_url="https://custom.openai.test",
        metadata={"http_referer": "https://app.example"},
        api_key="user-key",
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
    settings = make_settings()
    catalogue = ProviderModelCatalogue(
        settings,
        client_factories={"openai": RecordingProviderClient},
    )
    inactive_configuration = SimpleNamespace(
        provider="openai",
        is_active=False,
        base_url=None,
        metadata={},
        api_key="user-key",
    )

    models = await catalogue.list_all_models([inactive_configuration])

    assert models == []
    assert RecordingProviderClient.initialiser_calls == []


@pytest.mark.asyncio
async def test_catalogue_list_models_for_provider_requires_user_configuration(caplog):
    RecordingProviderClient.initialiser_calls = []
    settings = make_settings()
    catalogue = ProviderModelCatalogue(
        settings,
        client_factories={"openai": RecordingProviderClient},
    )

    with caplog.at_level("WARNING"):
        models = await catalogue.list_models_for_provider("openai", [])

    assert models == []
    assert "not configured" in caplog.text


@pytest.mark.asyncio
async def test_openai_provider_client_parses_response():
    payload = {"data": [{"id": "gpt-test", "name": "GPT Test", "context_window": 1024}]}
    factory_kwargs: list[Mapping[str, Any]] = []
    created_clients: list[RecordingOpenAIClient] = []

    def factory(**kwargs: Any) -> RecordingOpenAIClient:
        factory_kwargs.append(kwargs)
        client = RecordingOpenAIClient(payload)
        created_clients.append(client)
        return client

    settings = make_settings()
    client = OpenAIProviderClient(
        settings,
        api_key="test-key",
        base_url="https://custom.openai",
        client_factory=factory,
    )

    models = await client.list_models()

    assert len(models) == 1
    model = models[0]
    assert model.provider == "openai"
    assert model.id == "gpt-test"
    assert model.context_window == 1024
    assert created_clients and created_clients[0].closed is True
    assert factory_kwargs and factory_kwargs[0]["api_key"] == "test-key"
    assert factory_kwargs[0]["base_url"] == "https://custom.openai"


@pytest.mark.asyncio
async def test_openai_provider_client_requires_sdk_when_unavailable(monkeypatch, caplog):
    monkeypatch.setattr("app.services.providers.openai.AsyncOpenAI", None, raising=False)
    captured_requests: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:  # pragma: no cover - should not be called
        captured_requests.append(request)
        return httpx.Response(500)

    transport = httpx.MockTransport(handler)
    settings = make_settings()
    client = OpenAIProviderClient(settings, api_key="fallback-key", transport=transport)

    with caplog.at_level("ERROR"):
        models = await client.list_models()

    assert models == []
    assert captured_requests == []
    assert "cannot list models" in caplog.text.lower()


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

    settings = make_settings()
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

    settings = make_settings(groq_api_key="test-key", groq_api_base="https://custom.groq")
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

    settings = make_settings(groq_api_key="test-key")
    client = GroqProviderClient(settings, client_factory=factory)

    with caplog.at_level("ERROR"):
        models = await client.list_models()

    assert models == []
    assert "Groq SDK request failed" in caplog.text or "Unexpected error" in caplog.text


@pytest.mark.asyncio
async def test_groq_provider_client_requires_sdk_when_unavailable(monkeypatch, caplog):
    monkeypatch.setattr("app.services.providers.groq.AsyncGroq", None, raising=False)
    captured_requests: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:  # pragma: no cover - should not be called
        captured_requests.append(request)
        return httpx.Response(500)

    transport = httpx.MockTransport(handler)
    settings = make_settings(groq_api_key="groq-key")
    client = GroqProviderClient(settings, transport=transport)

    with caplog.at_level("ERROR"):
        models = await client.list_models()

    assert models == []
    assert captured_requests == []
    assert "cannot list models" in caplog.text.lower()


@pytest.mark.asyncio
async def test_groq_sdk_service_invokes_official_client():
    created_clients: list[RecordingGroqClient] = []
    factory_kwargs: list[Mapping[str, Any]] = []

    def factory(**kwargs: Any) -> RecordingGroqClient:
        factory_kwargs.append(kwargs)
        client = RecordingGroqClient(stream_chunks=["chunk-1", "chunk-2"])
        created_clients.append(client)
        return client

    settings = make_settings(groq_api_key="sdk-key")
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
    payload = {"data": []}
    factory_kwargs: list[Mapping[str, Any]] = []
    created_clients: list[RecordingOpenRouterClient] = []

    def factory(**kwargs: Any) -> RecordingOpenRouterClient:
        factory_kwargs.append(kwargs)
        client = RecordingOpenRouterClient(payload)
        created_clients.append(client)
        return client

    settings = make_settings(
        openrouter_api_key="router-key",
        openrouter_app_url="https://example.com",
        openrouter_app_name="PocketLLM",
    )
    client = OpenRouterProviderClient(settings, client_factory=factory)

    models = await client.list_models()

    assert models == []
    assert created_clients and created_clients[0].closed is True
    assert factory_kwargs and factory_kwargs[0]["api_key"] == "router-key"
    headers = factory_kwargs[0]["default_headers"]
    assert headers["HTTP-Referer"] == "https://example.com"
    assert headers["X-Title"] == "PocketLLM"


@pytest.mark.asyncio
async def test_openrouter_provider_client_requires_sdk_when_unavailable(monkeypatch, caplog):
    monkeypatch.setattr("app.services.providers.openrouter.AsyncOpenRouter", None, raising=False)
    captured_requests: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:  # pragma: no cover - should not be called
        captured_requests.append(request)
        return httpx.Response(500)

    transport = httpx.MockTransport(handler)
    settings = make_settings(
        openrouter_api_key="router-key",
        openrouter_app_url="https://example.com",
        openrouter_app_name="PocketLLM",
    )
    client = OpenRouterProviderClient(settings, transport=transport)

    with caplog.at_level("ERROR"):
        models = await client.list_models()

    assert models == []
    assert captured_requests == []
    assert "cannot list models" in caplog.text.lower()


@pytest.mark.asyncio
async def test_providers_service_filters_models_by_attributes():
    models = [
        ProviderModel(
            provider="openai",
            id="gpt-4o",
            name="GPT-4 Omni",
            description="General purpose assistant",
        ),
        ProviderModel(
            provider="groq",
            id="llama-guard",
            name="LLaMA Guard",
            description="Moderation model",
            metadata={"capabilities": ["moderation"]},
        ),
    ]
    settings = make_settings()
    service = ProvidersService(settings, database=FakeDatabase(), catalogue=FakeCatalogue(models))
    user_id = uuid4()

    provider_records = [
        make_provider_record(provider="openai", user_id=user_id),
        make_provider_record(provider="groq", user_id=user_id),
    ]

    async def stub_fetch(_: UUID) -> list[ProviderRecord]:
        return provider_records

    service._fetch_provider_records = stub_fetch  # type: ignore[assignment]

    moderation = await service.get_provider_models(user_id, query="moderation")
    assert [model.id for model in moderation.models] == ["llama-guard"]

    gpt_match = await service.get_provider_models(user_id, name="gpt-4")
    assert [model.id for model in gpt_match.models] == ["gpt-4o"]

    guard_match = await service.get_provider_models(user_id, model_id="guard")
    assert [model.id for model in guard_match.models] == ["llama-guard"]


@pytest.mark.asyncio
async def test_providers_service_respects_provider_parameter():
    models = [
        ProviderModel(provider="openai", id="gpt-4o", name="GPT-4 Omni"),
        ProviderModel(provider="groq", id="llama-guard", name="LLaMA Guard"),
    ]
    catalogue = FakeCatalogue(models)
    settings = make_settings()
    service = ProvidersService(settings, database=FakeDatabase(), catalogue=catalogue)
    user_id = uuid4()

    provider_records = [make_provider_record(provider="groq", user_id=user_id, api_key="groq-key")]

    async def stub_fetch(_: UUID) -> list[ProviderRecord]:
        return provider_records

    service._fetch_provider_records = stub_fetch  # type: ignore[assignment]

    groq_models = await service.get_provider_models(user_id, provider="groq")

    assert [model.provider for model in groq_models.models] == ["groq"]
    assert catalogue.calls and catalogue.calls[0][0] == "groq"


@pytest.mark.asyncio
async def test_providers_service_requires_user_configuration_for_all_models():
    settings = make_settings()
    service = ProvidersService(settings, database=FakeDatabase(), catalogue=FakeCatalogue([]))
    user_id = uuid4()

    async def stub_fetch(_: UUID) -> list[ProviderRecord]:
        return []

    service._fetch_provider_records = stub_fetch  # type: ignore[assignment]

    response = await service.get_provider_models(user_id)

    assert response.models == []
    assert response.message and "No providers" in response.message
    assert set(response.missing_providers) == {"openai", "groq", "openrouter", "imagerouter"}


@pytest.mark.asyncio
async def test_providers_service_requires_provider_configuration_for_specific_provider():
    settings = make_settings()
    service = ProvidersService(settings, database=FakeDatabase(), catalogue=FakeCatalogue([]))
    user_id = uuid4()

    provider_records = [make_provider_record(provider="openai", user_id=user_id)]

    async def stub_fetch(_: UUID) -> list[ProviderRecord]:
        return provider_records

    service._fetch_provider_records = stub_fetch  # type: ignore[assignment]

    response = await service.get_provider_models(user_id, provider="groq")

    assert response.models == []
    assert response.message and "not configured" in response.message
    assert "groq" in response.missing_providers
