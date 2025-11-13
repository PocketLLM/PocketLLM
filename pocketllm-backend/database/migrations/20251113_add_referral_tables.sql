-- PocketLLM migration: add tables for the referral system.
-- Run with: psql "$SUPABASE_DB_URL" -f database/migrations/20251113_add_referral_tables.sql

create table if not exists public.user_invite_codes (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    code text not null unique,
    created_at timestamptz not null default now(),
    max_uses integer not null default 5,
    uses_count integer not null default 0
);

create table if not exists public.referrals (
    id uuid primary key default gen_random_uuid(),
    referrer_id uuid not null references auth.users(id) on delete cascade,
    referred_id uuid references auth.users(id) on delete cascade,
    referred_email text not null,
    status text not null default 'pending' check (status in ('pending', 'complete')),
    created_at timestamptz not null default now(),
    accepted_at timestamptz,
    reward_status text not null default 'pending' check (reward_status in ('pending', 'fulfilled'))
);
