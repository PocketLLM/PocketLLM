# Database Schema Overview

The PocketLLM backend relies on Supabase Postgres with row-level security. The key tables are summarised below:

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `profiles` | Public user profile metadata synced with `auth.users`. | `id`, `email`, `full_name`, invite/referral fields, waitlist status, deletion metadata |
| `providers` | Stores third-party provider credentials per user. | `provider`, `api_key_hash`, `api_key_preview`, `metadata`, `is_active` |
| `model_configs` | User-specific model configuration presets. | `provider`, `model`, `settings`, `is_default`, `is_active` |
| `chats` | Chat sessions for each user. | `model_config_id`, `title`, timestamps |
| `messages` | Messages inside a chat. | `chat_id`, `role`, `content`, `metadata` |
| `jobs` | Background work items (image generation, file processing, etc.). | `job_type`, `status`, `input_data`, `output_data`, `error_log` |
| `waitlist_entries` | De-duplicated records for waitlist sign-ups. | `email`, `full_name`, `source`, `metadata` |
| `invite_codes` | Canonical store of invite/referral codes and usage counts. | `code`, `issued_by`, `max_uses`, `status`, `uses_count` |
| `referral_applications` | Structured waitlist applications for admin review. | `email`, `occupation`, `motivation`, `status`, `metadata` |
| `referrals` | Links a referrer’s code to invited teammates. | `referrer_user_id`, `referee_email`, `status`, `reward_status` |
| `referral_rewards` | Tracks incentives unlocked from referrals. | `referral_id`, `reward_type`, `status`, `amount` |

All tables use UUID primary keys and update their `updated_at` timestamp via a trigger. Row-level security enforces per-user isolation;
clients must present valid Supabase access tokens for queries executed through PostgREST.

See [`schema.sql`](schema.sql) for the canonical DDL.
