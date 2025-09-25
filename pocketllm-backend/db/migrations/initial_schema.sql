-- =================================================================
-- 1. PROFILES TABLE (for public user data)
-- This table is linked to Supabase's private `auth.users` table.
-- =================================================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  username TEXT UNIQUE,
  bio TEXT,
  date_of_birth DATE,
  profession TEXT,
  heard_from TEXT,
  avatar_url TEXT,
  survey_completed BOOLEAN DEFAULT FALSE,
  deletion_status TEXT DEFAULT 'active',
  deletion_requested_at TIMESTAMPTZ,
  deletion_scheduled_for TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Helper function to automatically update `updated_at` timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update the `updated_at` column on any change
CREATE TRIGGER on_profiles_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- =================================================================
-- 2. MODEL CONFIGURATIONS TABLE
-- Stores user-specific settings for different AI providers.
-- =================================================================
CREATE TABLE public.model_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  provider TEXT NOT NULL,
  base_url TEXT,
  api_key_encrypted TEXT, -- API keys will be encrypted before storing
  model TEXT NOT NULL,
  system_prompt TEXT,
  temperature REAL DEFAULT 0.7,
  max_tokens INT DEFAULT 2048,
  top_p REAL DEFAULT 1.0,
  frequency_penalty REAL DEFAULT 0.0,
  presence_penalty REAL DEFAULT 0.0,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_model_configs_user_id ON public.model_configs(user_id);
CREATE TRIGGER on_model_configs_update
  BEFORE UPDATE ON public.model_configs
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- =================================================================
-- 3. CHATS TABLE
-- Stores metadata for each conversation.
-- =================================================================
CREATE TABLE public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  model_config_id UUID REFERENCES public.model_configs(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_chats_user_id ON public.chats(user_id);
CREATE TRIGGER on_chats_update
  BEFORE UPDATE ON public.chats
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- =================================================================
-- 4. MESSAGES TABLE
-- Stores the content of each message in a chat.
-- =================================================================
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  metadata JSONB, -- For storing tokens, sources, errors, etc.
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_messages_chat_id ON public.messages(chat_id);

-- =================================================================
-- 5. JOBS TABLE (for async tasks like image generation)
-- =================================================================
CREATE TYPE job_status AS ENUM ('pending', 'processing', 'completed', 'failed');
CREATE TABLE public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  job_type TEXT NOT NULL, -- e.g., 'image_generation', 'file_analysis'
  status job_status DEFAULT 'pending',
  input_data JSONB,
  output_data JSONB, -- For storing results, like a URL to a generated image
  error_log TEXT, -- Detailed error message if the job fails
  metadata JSONB, -- For tracking progress, retries, etc.
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_jobs_user_id_status ON public.jobs(user_id, status);
CREATE TRIGGER on_jobs_update
  BEFORE UPDATE ON public.jobs
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- =================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- This is crucial for securing user data.
-- =================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.model_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own data." ON public.profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "Users can manage their own model configs." ON public.model_configs FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own chats." ON public.chats FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage messages in their own chats." ON public.messages FOR ALL
USING (auth.uid() = (SELECT user_id FROM public.chats WHERE id = chat_id));
CREATE POLICY "Users can manage their own jobs." ON public.jobs FOR ALL USING (auth.uid() = user_id);
