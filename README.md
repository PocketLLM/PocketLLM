# PocketLLM

PocketLLM is a cross-platform assistant that pairs a Flutter application with a FastAPI backend to deliver secure, low-latency access to large language models. Users can connect their own provider accounts, browse real-time catalogues, import models, and chat across mobile and desktop targets with a shared experience.

<p align="center">
  <img src="https://img.shields.io/badge/Status-Active_Development-blue?style=for-the-badge" alt="Development Status" />
  <img src="https://img.shields.io/badge/Framework-Flutter-02569B?style=for-the-badge&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Backend-FastAPI-109989?style=for-the-badge&logo=fastapi" alt="FastAPI" />
</p>

## Overview

PocketLLM focuses on three pillars:

1. **Unified catalogue** – aggregate models from OpenAI, Groq, OpenRouter, and ImageRouter using official SDKs with per-user API keys.
2. **Bring your own keys** – users activate providers securely; secrets are encrypted at rest and never fall back to environment credentials.
3. **Consistent chat experience** – Flutter renders the same responsive interface on Android, iOS, macOS, Windows, Linux, and the web.

The backend exposes REST APIs that the Flutter client consumes. A Supabase instance stores provider configurations, encrypted secrets, and chat history.

## Key Features

| Area | Highlights |
|------|------------|
| **Model management** | Dynamic `/v1/models` endpoint returns live catalogues with helpful status messaging when keys are missing or filters remove all results. Users can import, favourite, and set defaults. |
| **Provider operations** | Granular activation flows validate API keys with official SDKs, support base URL overrides, and expose a status dashboard. |
| **Chat experience** | Streaming responses, Markdown rendering, inline code blocks, and token accounting. |
| **Security** | Secrets encrypted using Fernet + project key, strict error messages when configuration is incomplete, and no environment fallback for user operations. |
| **Observability** | Structured logging across services and catalogue caching with per-provider metrics. |

## Architecture

```
PocketLLM
├── lib/                     # Flutter client (Riverpod, GoRouter, Material 3)
│   ├── component/           # Shared widgets and UI primitives
│   ├── pages/               # Screens including Library, API Keys, Chat
│   └── services/            # State management, API bridges, secure storage
├── pocketllm-backend/       # FastAPI application
│   ├── app/api/             # Versioned routes (/v1)
│   ├── app/services/        # Provider catalogue, auth, jobs, models
│   ├── app/utils/           # Crypto helpers, security utilities
│   └── database/            # Dataclasses mirroring Supabase tables
└── docs/                    # Operational guides and API references
```

## Prerequisites

| Component | Requirement |
|-----------|-------------|
| Flutter   | 3.19.6 (see [`AGENTS.md`](AGENTS.md) setup script) |
| Dart      | Included with Flutter SDK |
| Python    | 3.11+ for FastAPI backend |
| Node / pnpm | Optional for tooling around Supabase migrations |
| Supabase  | Service-role key and project URL configured in `.env` |

## Quick Start

### Backend

```bash
cd pocketllm-backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env  # configure Supabase credentials and ENCRYPTION_KEY
uvicorn main:app --reload
```

Key endpoint: `GET /v1/models`

```http
GET /v1/models
Authorization: Bearer <JWT>

{
  "models": [
    {
      "provider": "openai",
      "id": "gpt-4o",
      "name": "GPT-4 Omni",
      "metadata": {"owned_by": "openai"}
    }
  ],
  "message": null,
  "configured_providers": ["openai"],
  "missing_providers": ["groq", "openrouter", "imagerouter"]
}
```

When no API keys are stored the endpoint responds with an empty `models` array and a descriptive `message`, enabling the Flutter UI to prompt users to add credentials.

### Flutter Client

```bash
cd ..
flutter pub get
flutter run  # chooses a connected device or emulator
```

The API Keys page surfaces provider status, preview masks, and validation results. The Model Library consumes the unified `/v1/models` response and displays grouped catalogues with filtering options.

## Testing

| Layer | Command |
|-------|---------|
| Flutter | `flutter analyze && flutter test` |
| Backend | `cd pocketllm-backend && pytest` |

> **Note:** Some integration suites stub external SDKs; install `openai`, `groq`, and `openrouter` packages locally for full coverage.

## Documentation

- [`docs/api-documentation.md`](docs/api-documentation.md) – REST endpoints and schemas.
- [`docs/backend-guide.md`](docs/backend-guide.md) – Environment variables, Supabase integration, and deployment playbooks.
- [`docs/groq-guide.md`](docs/groq-guide.md) – Official SDK usage for catalogue, chat, audio, and reasoning APIs.
- [`docs/frontend_cleanup_tasks.md`](docs/frontend_cleanup_tasks.md) – Outstanding UI refinements.

## Contributing

Contributions are welcome! Please review [`CONTRIBUTING.md`](CONTRIBUTING.md) and ensure:

1. New features include unit or widget tests.
2. Backend changes run through `pytest` with optional SDKs installed.
3. Documentation and changelogs reflect API or workflow updates.
4. Secrets and API keys are never committed.

## License

PocketLLM is released under the [MIT License](LICENSE).

---

Have questions or ideas? Open an issue or join the discussion — we’d love to hear how you are using PocketLLM.
