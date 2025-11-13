-- PocketLLM migration: add tables for the notification system.
-- Run with: psql "$SUPABASE_DB_URL" -f database/migrations/20251113_add_notification_tables.sql

create table if not exists public.notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    type text not null,
    entity_id uuid,
    content_summary text not null,
    data jsonb,
    is_read boolean not null default false,
    created_at timestamptz not null default now()
);
