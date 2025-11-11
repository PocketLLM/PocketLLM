-- PocketLLM Supabase schema
-- Safe to run multiple times; objects are created only when absent.

-- -----------------------------------------------------------------------------
-- Extensions
-- -----------------------------------------------------------------------------
create schema if not exists extensions;
create extension if not exists "pgcrypto" with schema extensions;

-- -----------------------------------------------------------------------------
-- Helper functions
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at := timezone('utc', now());
    return new;
end;
$$;

create or replace function public.tg_require_authenticated()
returns trigger
language plpgsql
as $$
begin
    if auth.role() = 'anon' then
        raise exception 'Anonymous role cannot modify this table';
    end if;
    return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Profiles
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    email text not null,
    full_name text,
    username text unique,
    bio text,
    date_of_birth date,
    age integer check (age is null or (age between 13 and 120)),
    profession text,
    heard_from text,
    avatar_url text,
    invite_code text,
    referred_by uuid references public.profiles (id) on delete set null,
    referral_code text,
    invite_status text not null default 'pending' check (invite_status in ('pending', 'invited', 'joined', 'revoked')),
    waitlist_status text not null default 'pending' check (waitlist_status in ('pending', 'approved', 'rejected', 'skipped')),
    waitlist_metadata jsonb not null default '{}'::jsonb,
    waitlist_applied_at timestamptz,
    invite_approved_at timestamptz,
    survey_completed boolean not null default false,
    onboarding_responses jsonb not null default '{}'::jsonb,
    deletion_status text not null default 'active',
    deletion_requested_at timestamptz,
    deletion_scheduled_for timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists profiles_email_key on public.profiles (email);
create unique index if not exists profiles_invite_code_key on public.profiles (invite_code) where invite_code is not null;

alter table public.profiles enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'profiles' and policyname = 'profiles_select'
    ) then
        create policy profiles_select on public.profiles
            for select using (auth.uid() = id);
    end if;

    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'profiles' and policyname = 'profiles_insert'
    ) then
        create policy profiles_insert on public.profiles
            for insert with check (auth.uid() = id);
    end if;

    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'profiles' and policyname = 'profiles_update'
    ) then
        create policy profiles_update on public.profiles
            for update using (auth.uid() = id) with check (auth.uid() = id);
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_profiles_updated_at'
    ) then
        create trigger set_profiles_updated_at
            before update on public.profiles
            for each row execute function public.set_updated_at();
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Provider configurations
-- -----------------------------------------------------------------------------
create table if not exists public.providers (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    provider text not null,
    display_name text,
    base_url text,
    metadata jsonb not null default '{}'::jsonb,
    api_key_hash text,
    api_key_preview text,
    api_key_encrypted text,
    is_active boolean not null default false,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint providers_user_provider_key unique (user_id, provider)
);

create index if not exists providers_user_id_idx on public.providers (user_id);

alter table public.providers enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'providers' and policyname = 'providers_access'
    ) then
        create policy providers_access on public.providers
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_providers_updated_at'
    ) then
        create trigger set_providers_updated_at
            before update on public.providers
            for each row execute function public.set_updated_at();
    end if;

    if not exists (
        select 1 from pg_trigger where tgname = 'require_authenticated_providers'
    ) then
        create trigger require_authenticated_providers
            before insert or update on public.providers
            for each row execute function public.tg_require_authenticated();
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Model configurations
-- -----------------------------------------------------------------------------
create table if not exists public.model_configs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    provider_id uuid references public.providers (id) on delete set null,
    provider text not null,
    model text not null,
    name text not null,
    display_name text,
    description text,
    is_default boolean not null default false,
    is_active boolean not null default true,
    settings jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists model_configs_user_name_key on public.model_configs (user_id, name);
create index if not exists model_configs_user_provider_idx on public.model_configs (user_id, provider);

alter table public.model_configs enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'model_configs' and policyname = 'model_configs_access'
    ) then
        create policy model_configs_access on public.model_configs
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_model_configs_updated_at'
    ) then
        create trigger set_model_configs_updated_at
            before update on public.model_configs
            for each row execute function public.set_updated_at();
    end if;

    if not exists (
        select 1 from pg_trigger where tgname = 'require_authenticated_model_configs'
    ) then
        create trigger require_authenticated_model_configs
            before insert or update on public.model_configs
            for each row execute function public.tg_require_authenticated();
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Agent memory store
-- -----------------------------------------------------------------------------
create table if not exists public.agent_memories (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    session_id text not null,
    agent_key text not null,
    memory_state jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint agent_memories_session_agent_key unique (owner_id, session_id, agent_key)
);

create index if not exists agent_memories_session_idx on public.agent_memories (owner_id, session_id);

alter table public.agent_memories enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'agent_memories' and policyname = 'agent_memories_access'
    ) then
        create policy agent_memories_access on public.agent_memories
            using (auth.uid() = owner_id)
            with check (auth.uid() = owner_id);
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_agent_memories_updated_at'
    ) then
        create trigger set_agent_memories_updated_at
            before update on public.agent_memories
            for each row execute function public.set_updated_at();
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'require_authenticated_agent_memories'
    ) then
        create trigger require_authenticated_agent_memories
            before insert or update on public.agent_memories
            for each row execute function public.tg_require_authenticated();
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Chats
-- -----------------------------------------------------------------------------
create table if not exists public.chats (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    model_config_id uuid references public.model_configs (id) on delete set null,
    title text not null default 'Untitled chat',
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists chats_user_id_idx on public.chats (user_id);
create index if not exists chats_user_updated_at_idx on public.chats (user_id, updated_at desc);

alter table public.chats enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'chats' and policyname = 'chats_access'
    ) then
        create policy chats_access on public.chats
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_chats_updated_at'
    ) then
        create trigger set_chats_updated_at
            before update on public.chats
            for each row execute function public.set_updated_at();
    end if;

    if not exists (
        select 1 from pg_trigger where tgname = 'require_authenticated_chats'
    ) then
        create trigger require_authenticated_chats
            before insert or update on public.chats
            for each row execute function public.tg_require_authenticated();
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Messages
-- -----------------------------------------------------------------------------
create table if not exists public.messages (
    id uuid primary key default gen_random_uuid(),
    chat_id uuid not null references public.chats (id) on delete cascade,
    role text not null check (role in ('user', 'assistant', 'system')),
    content text not null,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc', now())
);

create index if not exists messages_chat_id_idx on public.messages (chat_id);
create index if not exists messages_chat_created_idx on public.messages (chat_id, created_at);

alter table public.messages enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'messages' and policyname = 'messages_select'
    ) then
        create policy messages_select on public.messages
            for select using (
                exists (
                    select 1
                    from public.chats c
                    where c.id = messages.chat_id
                      and c.user_id = auth.uid()
                )
            );
    end if;

    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'messages' and policyname = 'messages_insert'
    ) then
        create policy messages_insert on public.messages
            for insert with check (
                exists (
                    select 1
                    from public.chats c
                    where c.id = messages.chat_id
                      and c.user_id = auth.uid()
                )
            );
    end if;

    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'messages' and policyname = 'messages_delete'
    ) then
        create policy messages_delete on public.messages
            for delete using (
                exists (
                    select 1
                    from public.chats c
                    where c.id = messages.chat_id
                      and c.user_id = auth.uid()
                )
            );
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'require_authenticated_messages'
    ) then
        create trigger require_authenticated_messages
            before insert on public.messages
            for each row execute function public.tg_require_authenticated();
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Jobs
-- -----------------------------------------------------------------------------
create table if not exists public.jobs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    job_type text not null,
    status text not null,
    input_data jsonb not null default '{}'::jsonb,
    output_data jsonb,
    metadata jsonb not null default '{}'::jsonb,
    error_log text,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists jobs_user_id_idx on public.jobs (user_id);
create index if not exists jobs_user_status_idx on public.jobs (user_id, status);

alter table public.jobs enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'jobs' and policyname = 'jobs_access'
    ) then
        create policy jobs_access on public.jobs
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_jobs_updated_at'
    ) then
        create trigger set_jobs_updated_at
            before update on public.jobs
            for each row execute function public.set_updated_at();
    end if;

    if not exists (
        select 1 from pg_trigger where tgname = 'require_authenticated_jobs'
    ) then
        create trigger require_authenticated_jobs
            before insert on public.jobs
            for each row execute function public.tg_require_authenticated();
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- User sessions
-- -----------------------------------------------------------------------------
create table if not exists public.user_sessions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc', now()),
    expires_at timestamptz not null
);

create index if not exists user_sessions_user_idx on public.user_sessions (user_id, expires_at);

alter table public.user_sessions enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'user_sessions' and policyname = 'user_sessions_access'
    ) then
        create policy user_sessions_access on public.user_sessions
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Waitlist entries
-- -----------------------------------------------------------------------------
create table if not exists public.waitlist_entries (
    id uuid primary key default gen_random_uuid(),
    email text not null,
    full_name text,
    source text,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists waitlist_entries_email_key on public.waitlist_entries (email);
create index if not exists waitlist_entries_created_idx on public.waitlist_entries (created_at desc);

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_waitlist_entries_updated_at'
    ) then
        create trigger set_waitlist_entries_updated_at
            before update on public.waitlist_entries
            for each row execute function public.set_updated_at();
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Invite codes
-- -----------------------------------------------------------------------------
create table if not exists public.invite_codes (
    id uuid primary key default gen_random_uuid(),
    code text not null,
    issued_by uuid references auth.users (id) on delete set null,
    created_for uuid references auth.users (id) on delete set null,
    max_uses integer not null default 1,
    uses_count integer not null default 0 check (uses_count >= 0),
    status text not null default 'active' check (status in ('active', 'consumed', 'revoked')),
    expires_at timestamptz,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint invite_codes_usage check (uses_count <= max_uses)
);

create unique index if not exists invite_codes_code_key on public.invite_codes (code);
create index if not exists invite_codes_issuer_idx on public.invite_codes (issued_by);

alter table public.invite_codes enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'invite_codes' and policyname = 'invite_codes_access'
    ) then
        create policy invite_codes_access on public.invite_codes
            using (auth.uid() = issued_by or auth.uid() = created_for)
            with check (auth.uid() = issued_by);
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_invite_codes_updated_at'
    ) then
        create trigger set_invite_codes_updated_at
            before update on public.invite_codes
            for each row execute function public.set_updated_at();
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Referral applications (waitlist)
-- -----------------------------------------------------------------------------
create table if not exists public.referral_applications (
    id uuid primary key default gen_random_uuid(),
    email text not null,
    full_name text,
    occupation text,
    motivation text,
    use_case text,
    links jsonb not null default '[]'::jsonb,
    source text,
    status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'invited', 'converted', 'waitlisted')),
    metadata jsonb not null default '{}'::jsonb,
    user_id uuid references auth.users (id) on delete set null,
    invite_code_id uuid references public.invite_codes (id) on delete set null,
    applied_at timestamptz not null default timezone('utc', now()),
    processed_at timestamptz,
    notes text,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists referral_applications_email_key on public.referral_applications (email);
create index if not exists referral_applications_status_idx on public.referral_applications (status);

alter table public.referral_applications enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'referral_applications' and policyname = 'referral_applications_access'
    ) then
        create policy referral_applications_access on public.referral_applications
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_referral_applications_updated_at'
    ) then
        create trigger set_referral_applications_updated_at
            before update on public.referral_applications
            for each row execute function public.set_updated_at();
    end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Referrals & rewards
-- -----------------------------------------------------------------------------
create table if not exists public.referrals (
    id uuid primary key default gen_random_uuid(),
    invite_code_id uuid references public.invite_codes (id) on delete set null,
    referrer_user_id uuid references auth.users (id) on delete set null,
    referee_user_id uuid references auth.users (id) on delete set null,
    referee_email text not null,
    status text not null default 'pending' check (status in ('pending', 'joined', 'rejected')),
    reward_status text not null default 'none' check (reward_status in ('none', 'pending', 'issued', 'revoked')),
    metadata jsonb not null default '{}'::jsonb,
    accepted_at timestamptz,
    reward_issued_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists referrals_invite_email_key on public.referrals (invite_code_id, lower(referee_email));
create index if not exists referrals_referrer_idx on public.referrals (referrer_user_id);

alter table public.referrals enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'referrals' and policyname = 'referrals_access'
    ) then
        create policy referrals_access on public.referrals
            using (auth.uid() = referrer_user_id or auth.uid() = referee_user_id)
            with check (auth.uid() = referrer_user_id);
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_referrals_updated_at'
    ) then
        create trigger set_referrals_updated_at
            before update on public.referrals
            for each row execute function public.set_updated_at();
    end if;
end;
$$;

create table if not exists public.referral_rewards (
    id uuid primary key default gen_random_uuid(),
    referral_id uuid not null references public.referrals (id) on delete cascade,
    reward_type text not null,
    status text not null default 'pending' check (status in ('pending', 'approved', 'fulfilled', 'revoked')),
    amount numeric(10, 2),
    currency text default 'USD',
    metadata jsonb not null default '{}'::jsonb,
    issued_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists referral_rewards_referral_idx on public.referral_rewards (referral_id);

alter table public.referral_rewards enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies where schemaname = 'public' and tablename = 'referral_rewards' and policyname = 'referral_rewards_access'
    ) then
        create policy referral_rewards_access on public.referral_rewards
            using (
                auth.uid() = (
                    select referrer_user_id from public.referrals where id = referral_id
                )
            );
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'set_referral_rewards_updated_at'
    ) then
        create trigger set_referral_rewards_updated_at
            before update on public.referral_rewards
            for each row execute function public.set_updated_at();
    end if;
end;
$$;

do $$
begin
    if not exists (
        select 1 from pg_trigger where tgname = 'require_authenticated_user_sessions'
    ) then
        create trigger require_authenticated_user_sessions
            before insert on public.user_sessions
            for each row execute function public.tg_require_authenticated();
    end if;
end;
$$;
