-- PocketLLM Supabase schema
-- Consolidated database objects required by the FastAPI backend.

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================
-- 1. Profiles
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  username TEXT UNIQUE,
  bio TEXT,
  date_of_birth DATE,
  age INTEGER CHECK (age IS NULL OR (age BETWEEN 13 AND 120)),
  profession TEXT,
  heard_from TEXT,
  avatar_url TEXT,
  invite_code TEXT UNIQUE,
  referred_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  referral_code TEXT,
  invite_status TEXT DEFAULT 'pending' CHECK (invite_status IN ('pending', 'invited', 'joined', 'revoked')),
  waitlist_status TEXT DEFAULT 'pending' CHECK (waitlist_status IN ('pending', 'approved', 'rejected', 'skipped')),
  waitlist_metadata JSONB DEFAULT '{}'::JSONB,
  waitlist_applied_at TIMESTAMPTZ,
  invite_approved_at TIMESTAMPTZ,
  survey_completed BOOLEAN DEFAULT FALSE,
  onboarding_responses JSONB,
  deletion_status TEXT DEFAULT 'active',
  deletion_requested_at TIMESTAMPTZ,
  deletion_scheduled_for TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================
-- 2. Providers
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  display_name TEXT,
  base_url TEXT,
  metadata JSONB,
  api_key_hash TEXT,
  api_key_preview TEXT,
  is_active BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, provider)
);

-- =====================================================================
-- 3. Model configurations
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.model_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES public.providers(id) ON DELETE SET NULL,
  provider TEXT NOT NULL,
  model TEXT NOT NULL,
  name TEXT NOT NULL,
  display_name TEXT,
  description TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  settings JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, provider, model)
);

-- =====================================================================
-- 4. Chats & messages
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  model_config_id UUID REFERENCES public.model_configs(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================
-- 5. Jobs
-- =====================================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_status') THEN
    CREATE TYPE job_status AS ENUM ('pending', 'processing', 'completed', 'failed');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  job_type TEXT NOT NULL,
  status job_status DEFAULT 'pending',
  input_data JSONB,
  output_data JSONB,
  error_log TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================
-- 6. Waitlist & referral system
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.waitlist_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  source TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  issued_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_for UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  max_uses INTEGER DEFAULT 1,
  uses_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'consumed', 'revoked')),
  expires_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.referral_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  occupation TEXT,
  motivation TEXT,
  use_case TEXT,
  links JSONB DEFAULT '[]'::JSONB,
  source TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','invited','converted','waitlisted')),
  metadata JSONB DEFAULT '{}'::JSONB,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  invite_code_id UUID REFERENCES public.invite_codes(id) ON DELETE SET NULL,
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_code_id UUID REFERENCES public.invite_codes(id) ON DELETE SET NULL,
  referrer_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  referee_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  referee_email TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','joined','rejected')),
  reward_status TEXT DEFAULT 'none' CHECK (reward_status IN ('none','pending','issued','revoked')),
  metadata JSONB DEFAULT '{}'::JSONB,
  accepted_at TIMESTAMPTZ,
  reward_issued_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(invite_code_id, referee_email)
);

CREATE TABLE IF NOT EXISTS public.referral_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referral_id UUID REFERENCES public.referrals(id) ON DELETE CASCADE,
  reward_type TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','approved','fulfilled','revoked')),
  amount NUMERIC(10,2),
  currency TEXT DEFAULT 'USD',
  metadata JSONB DEFAULT '{}'::JSONB,
  issued_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================
-- Triggers to keep updated_at accurate
-- =====================================================================
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.touch_updated_at();

CREATE TRIGGER trg_providers_updated
  BEFORE UPDATE ON public.providers
  FOR EACH ROW EXECUTE PROCEDURE public.touch_updated_at();

CREATE TRIGGER trg_model_configs_updated
  BEFORE UPDATE ON public.model_configs
  FOR EACH ROW EXECUTE PROCEDURE public.touch_updated_at();

CREATE TRIGGER trg_chats_updated
  BEFORE UPDATE ON public.chats
  FOR EACH ROW EXECUTE PROCEDURE public.touch_updated_at();

CREATE TRIGGER trg_jobs_updated
  BEFORE UPDATE ON public.jobs
  FOR EACH ROW EXECUTE PROCEDURE public.touch_updated_at();

-- =====================================================================
-- Indexes
-- =====================================================================
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_invite_code ON public.profiles(invite_code);
CREATE INDEX IF NOT EXISTS idx_model_configs_user_id ON public.model_configs(user_id);
CREATE INDEX IF NOT EXISTS idx_chats_user_id ON public.chats(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON public.messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_jobs_user_id_status ON public.jobs(user_id, status);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_referrals_invite_email ON public.referrals(invite_code_id, referee_email);

-- =====================================================================
-- Row Level Security Policies
-- =====================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.model_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.waitlist_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invite_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own profile" ON public.profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "Users manage own providers" ON public.providers FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own models" ON public.model_configs FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own chats" ON public.chats FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own messages" ON public.messages FOR ALL USING (
  auth.uid() = (SELECT user_id FROM public.chats WHERE id = chat_id)
);
CREATE POLICY "Users manage own jobs" ON public.jobs FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own invite codes" ON public.invite_codes FOR ALL USING (auth.uid() = issued_by);
CREATE POLICY "Users view own referral applications" ON public.referral_applications FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage their referrals" ON public.referrals FOR ALL USING (auth.uid() = referrer_user_id);
CREATE POLICY "Users inspect rewards" ON public.referral_rewards FOR SELECT USING (
  auth.uid() = (
    SELECT referrer_user_id FROM public.referrals WHERE id = referral_id
  )
);
