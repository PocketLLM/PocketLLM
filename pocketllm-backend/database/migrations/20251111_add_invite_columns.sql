-- PocketLLM migration: ensure invite/waitlist columns exist on profiles.
-- Run with: psql "$SUPABASE_DB_URL" -f database/migrations/20251111_add_invite_columns.sql

alter table public.profiles
    add column if not exists invite_status text
        default 'pending'
        check (invite_status in ('pending', 'invited', 'joined', 'revoked'));

alter table public.profiles
    add column if not exists waitlist_status text
        default 'pending'
        check (waitlist_status in ('pending', 'approved', 'rejected', 'skipped'));

alter table public.profiles
    add column if not exists waitlist_metadata jsonb
        default '{}'::jsonb;

alter table public.profiles
    add column if not exists waitlist_applied_at timestamptz;

alter table public.profiles
    add column if not exists invite_approved_at timestamptz;

update public.profiles
set invite_status = coalesce(invite_status, 'pending');

update public.profiles
set waitlist_status = coalesce(waitlist_status, 'pending');

update public.profiles
set waitlist_metadata = coalesce(waitlist_metadata, '{}'::jsonb)
where waitlist_metadata is null;
