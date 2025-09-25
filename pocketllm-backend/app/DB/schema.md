# Database Schema Overview

The PocketLLM backend relies on Supabase Postgres with row-level security. The key tables are summarised below:

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `profiles` | Public user profile metadata synced with `auth.users`. | `id`, `email`, `full_name`, `survey_completed`, `onboarding_responses`, deletion fields |
| `providers` | Stores third-party provider credentials per user. | `provider`, `api_key_hash`, `api_key_preview`, `metadata`, `is_active` |
| `model_configs` | User-specific model configuration presets. | `provider`, `model`, `settings`, `is_default`, `is_active` |
| `chats` | Chat sessions for each user. | `model_config_id`, `title`, timestamps |
| `messages` | Messages inside a chat. | `chat_id`, `role`, `content`, `metadata` |
| `jobs` | Background work items (image generation, file processing, etc.). | `job_type`, `status`, `input_data`, `output_data`, `error_log` |

All tables use UUID primary keys and update their `updated_at` timestamp via a trigger. Row-level security enforces per-user isolation;
clients must present valid Supabase access tokens for queries executed through PostgREST.

See [`schema.sql`](schema.sql) for the canonical DDL.
