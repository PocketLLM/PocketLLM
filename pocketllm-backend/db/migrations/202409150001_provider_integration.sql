-- Provider integration schema changes

-- 1. Providers table to store provider credentials and metadata
CREATE TABLE IF NOT EXISTS public.providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  display_name TEXT,
  base_url TEXT,
  metadata JSONB,
  api_key_encrypted TEXT,
  api_key_hash TEXT,
  api_key_preview TEXT,
  is_active BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_providers_user_provider ON public.providers(user_id, provider);

DROP TRIGGER IF EXISTS on_providers_update ON public.providers;
CREATE TRIGGER on_providers_update
  BEFORE UPDATE ON public.providers
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

ALTER TABLE public.providers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their providers." ON public.providers;
CREATE POLICY "Users can manage their providers." ON public.providers
  FOR ALL USING (auth.uid() = user_id);

-- 2. Model configuration enhancements
ALTER TABLE public.model_configs
  ADD COLUMN IF NOT EXISTS provider_id UUID REFERENCES public.providers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS display_name TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS metadata JSONB,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS settings JSONB;

ALTER TABLE public.model_configs
  DROP COLUMN IF EXISTS api_key_encrypted;

CREATE UNIQUE INDEX IF NOT EXISTS idx_model_configs_user_provider_model
  ON public.model_configs(user_id, provider, model);

-- 3. Chats table should rely on foreign key to model configs
ALTER TABLE public.chats
  ADD COLUMN IF NOT EXISTS model_config_id UUID REFERENCES public.model_configs(id) ON DELETE SET NULL;

ALTER TABLE public.chats
  DROP COLUMN IF EXISTS model_config;

