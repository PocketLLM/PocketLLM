-- PocketLLM migration: add tables for the notification settings.
-- Run with: psql "$SUPABASE_DB_URL" -f database/migrations/20251113_add_notification_settings_table.sql

create table if not exists public.notification_preferences (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    notify_job_status boolean not null default true,
    notify_account_alerts boolean not null default true,
    notify_referral_rewards boolean not null default true,
    notify_product_updates boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
