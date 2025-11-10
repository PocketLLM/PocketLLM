# PocketLLM Python Backend

This folder contains the FastAPI-based backend for PocketLLM. It replaces the previous NestJS implementation and exposes the same
set of capabilities while integrating directly with Supabase for authentication, persistence, file storage, and background job
management.

## Features

- **FastAPI + Pydantic** application with modular routers and service layer.
- **Supabase Postgres** access through an asynchronous connection pool and secure GoTrue authentication flows.
- **Domain-driven modules** for authentication, users, chats, jobs, providers, and model management.
- **Background job orchestration** with async workers storing status updates in the `jobs` table.
- **Provider-aware chat runtime** that stores chat sessions/messages and streams prompts through the user's configured OpenAI-compatible provider.
- **Public waitlist endpoint** (`POST /v1/waitlist`) to collect marketing sign-ups from the marketing site.
- **Structured logging** and request correlation via custom middleware.
- **Extensible schema definitions** for future agents, tools, and async processes.

## Getting Started

### 1. Install dependencies

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

direct run: `cd pocketllm-backend; venv/Scripts/activate; python -m uvicorn main:app --reload`
### 2. Configure environment variables

Create a `.env` file (or update environment variables) with the following keys:

```ini
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_DB_URL=postgresql+asyncpg://<user>:<password>@<host>:5432/postgres
SUPABASE_JWT_SECRET=<jwt-secret>
ENCRYPTION_KEY=<fernet-key-or-32-char-secret>
LOG_LEVEL=INFO
# Optional: bypass the Supabase connectivity check when running offline/local tests
SUPABASE_SKIP_CONNECTION_TEST=false
# Optional: continue booting when Supabase is unreachable (defaults to false)
SUPABASE_STRICT_STARTUP=false
# Optional: control whether invite codes are required for signup (defaults to true)
INVITE_CODE=True
```

Refer to [`API_DOCUMENTATION.md`](API_DOCUMENTATION.md) for the full list of optional settings.

You can generate a compliant encryption key in two ways:

- Use a Fernet key (recommended): `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`
- Provide any 32-character string (for example, `export ENCRYPTION_KEY=$(openssl rand -hex 16 | cut -c1-32)`).

If a raw 32-character string is supplied, the backend will automatically derive a Fernet-compatible key internally.

When developing locally without network access to Supabase you can set
`SUPABASE_SKIP_CONNECTION_TEST=true`. This allows the API server to boot
without performing the startup connectivity probe while keeping runtime
behaviour unchanged for production deployments. If the connectivity check
fails, the backend now logs detailed diagnostics (including DNS resolution
results) and continues to start unless `SUPABASE_STRICT_STARTUP` is set to a
truthy value, in which case the application exits immediately. This makes it
easy to run the API offline while still enforcing strict guarantees in staging
or production.

### 3. Initialise the database schema

Run the SQL statements in [`database/schema.sql`](database/schema.sql) against your Supabase/Postgres instance. The schema ships
with primary keys, foreign keys, row-level security, triggers, and indexes tailored for PocketLLM's services, and can be applied
multiple times safely.

### 4. Launch the API

```bash
uvicorn main:app --reload --port 8000
```

The hosted API is available at `https://pocket-llm-api.vercel.app`. OpenAPI documentation is exposed at `/docs`.

### 5. Run tests

```bash
pytest
```

### Activating a provider

Send JSON to `/v1/providers/activate` using the `application/json` content type. Raw JSON strings are also accepted, but must
represent a valid JSON object. For example, to activate Groq with a custom timeout configuration:

```bash
curl \
  -X POST http://127.0.0.1:8000/v1/providers/activate \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "groq",
    "api_key": "gsk_your_api_key_here",
    "base_url": "https://api.groq.com",
    "metadata": {
      "timeout": 30,
      "max_retries": 2
    }
  }'
```

Providing the bare domain is sufficient—the backend automatically adds Groq's
`/openai/v1` compatibility prefix for HTTP calls while stripping it for the
official SDK.

If you construct the request body dynamically (for example, in Postman), ensure the body is sent as JSON rather than plain text.

## Project Structure

```text
app/
  api/               # FastAPI routers (v1)
  core/              # Configuration, database, middleware, logging
  schemas/           # Pydantic models grouped by domain
  services/          # Business logic interacting with Supabase
  utils/             # Shared helpers
database/            # Database schema
main.py              # Application entrypoint
requirements.txt     # Python dependencies
tests/               # Pytest-based regression tests
```

## Supabase Integration Overview

- **Authentication** is handled via Supabase GoTrue endpoints using the service role key.
- **Profiles, chats, messages, jobs, providers, and models** are stored in Postgres tables with row-level security enabled.
- **Encryption** of provider API keys uses bcrypt hashing for server-side verification. Secrets themselves should be stored using
  Supabase Vault or an external secrets manager.
- **Background jobs** update their status in the `jobs` table, enabling clients to poll `/v1/jobs/{jobId}`.

## Development Guidelines

- Keep service layer side-effect free; interact with external systems in dedicated modules.
- Always validate inbound payloads using the Pydantic schemas in `app/schemas`.
- Use dependency injection via `app/api/deps.py` for settings, database connections, and authentication context.
- Extend the API by adding new endpoints under `app/api/v1/endpoints` and exposing them via `app/api/v1/api.py`.

For detailed endpoint descriptions and request/response contracts, see [`API_DOCUMENTATION.md`](API_DOCUMENTATION.md).
