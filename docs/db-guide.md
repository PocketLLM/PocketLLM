Of course. Based on a detailed analysis of your PocketLLM project, here is a comprehensive report and roadmap for migrating the application to a robust, scalable backend using Supabase.

This guide covers the new architecture, a detailed database design with SQL schemas, a complete API and asynchronous job handling strategy, and a step-by-step plan for refactoring the Flutter application.

---

## PocketLLM Backend Migration & Architecture Report

This document outlines the plan for evolving PocketLLM from a local-first application to a powerful, cloud-backed service using Supabase. This migration will enable user accounts, cross-device data synchronization, and enhanced security.

### 1. Proposed Architecture: Flutter + Supabase

We will leverage the Supabase platform, which provides a complete backend-as-a-service solution, including a PostgreSQL database, authentication, file storage, and serverless functions (Edge Functions).

*   **Flutter Frontend:** The existing Flutter app will be refactored to communicate with Supabase. It will handle the UI and real-time data synchronization.
*   **Supabase Backend:**
    *   **Authentication:** Supabase Auth will manage user registration, login, and sessions, replacing the current local authentication system.
    *   **PostgreSQL Database:** A secure, managed Postgres database will store all application data, replacing `SharedPreferences` and local `sqflite`.
    *   **Storage:** Supabase Storage will be used to store user-uploaded files and generated images in a secure, bucket-based system.
    *   **Edge Functions (Node.js/Deno):** These serverless functions will be the core of our backend logic. They will act as a secure proxy between the Flutter app and third-party AI services (like OpenAI, Anthropic, Tavily, etc.). **This is critical for security, as it ensures no third-party API keys are ever exposed on the client-side.**

### 2. Database Design (Supabase/PostgreSQL)

The following schema is designed for scalability, security, and detailed metadata tracking.

#### **Table Schema**

| Table | Description |
| :--- | :--- |
| `profiles` | Stores public user data, linked one-to-one with Supabase's private `auth.users` table. |
| `model_configs` | Stores user-specific configurations for different AI model providers. API keys are stored encrypted. |
| `chats` | Stores metadata for each chat conversation. |
| `messages` | Contains the actual messages for each chat, including content and metadata. |
| `jobs` | A table to track the status and results of asynchronous background tasks. |

#### **Detailed Table Definitions & SQL Schema**

Here are the SQL `CREATE TABLE` statements to set up your database. You can execute these in the Supabase SQL Editor.

```sql
-- 1. PROFILES TABLE (for public user data)
-- This table is linked to the auth.users table and should be secured with RLS.
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  username TEXT UNIQUE,
  bio TEXT,
  date_of_birth DATE,
  profession TEXT,
  avatar_url TEXT,
  survey_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. MODEL CONFIGURATIONS TABLE
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
-- Add index for faster lookups
CREATE INDEX idx_model_configs_user_id ON public.model_configs(user_id);

-- 3. CHATS TABLE
CREATE TABLE public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  model_config_id UUID REFERENCES public.model_configs(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Add index for faster lookups
CREATE INDEX idx_chats_user_id ON public.chats(user_id);

-- 4. MESSAGES TABLE
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  metadata JSONB, -- For storing tokens, sources, errors, etc.
  created_at TIMESTAMPTZ DEFAULT NOW()
);
-- Add index for faster lookups
CREATE INDEX idx_messages_chat_id ON public.messages(chat_id);

-- 5. JOBS TABLE (for async tasks)
CREATE TYPE job_status AS ENUM ('pending', 'processing', 'completed', 'failed');
CREATE TABLE public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  job_type TEXT NOT NULL, -- e.g., 'image_generation', 'file_analysis'
  status job_status DEFAULT 'pending',
  input_data JSONB,
  output_data JSONB,
  error_log TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Add index for faster lookups
CREATE INDEX idx_jobs_user_id_status ON public.jobs(user_id, status);

```

#### **Row Level Security (RLS) Policies**

RLS is crucial for securing your data. These policies ensure that users can only access their own data.

```sql
-- Enable RLS for all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.model_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

-- Policies for PROFILES
CREATE POLICY "Users can view their own profile." ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Policies for MODEL_CONFIGS
CREATE POLICY "Users can manage their own model configs." ON public.model_configs FOR ALL USING (auth.uid() = user_id);

-- Policies for CHATS
CREATE POLICY "Users can manage their own chats." ON public.chats FOR ALL USING (auth.uid() = user_id);

-- Policies for MESSAGES
CREATE POLICY "Users can manage messages in their own chats." ON public.messages FOR ALL
USING (auth.uid() = (SELECT user_id FROM public.chats WHERE id = chat_id));

-- Policies for JOBS
CREATE POLICY "Users can manage their own jobs." ON public.jobs FOR ALL USING (auth.uid() = user_id);
```

### 3. Backend API & Asynchronous Jobs (Supabase Edge Functions)

The core logic will reside in serverless Edge Functions. This prevents exposing sensitive API keys and allows for complex, secure operations.

#### **Required Edge Functions**

1.  **`chat-request`**
    *   **Trigger:** HTTP POST request from the app.
    *   **Input:** `{ "chatId": "...", "prompt": "..." }`
    *   **Logic:**
        1.  Authenticates the user using the JWT from the request.
        2.  Fetches the corresponding chat and its associated `model_config`.
        3.  Retrieves the encrypted third-party API key from the `model_configs` table and decrypts it.
        4.  Constructs the appropriate request for the specified LLM provider (OpenAI, Anthropic, etc.).
        5.  Sends the request to the third-party API.
        6.  Receives the response from the LLM.
        7.  Creates a new message in the `messages` table with the assistant's response.
        8.  Updates the `updated_at` timestamp on the `chats` table.
        9.  Returns the new message to the client.
    *   **Error Handling:** Logs any errors from the third-party API into the `metadata` field of the new message.

2.  **`image-generation`**
    *   **Trigger:** HTTP POST request from the app.
    *   **Input:** `{ "prompt": "...", "modelId": "...", "quality": "...", "size": "..." }`
    *   **Logic:**
        1.  Creates a new entry in the `jobs` table with `status: 'pending'` and returns the `job_id` to the client immediately.
        2.  The function then proceeds asynchronously.
        3.  Retrieves the ImageRouter API key from a secure store (e.g., Supabase Vault).
        4.  Makes the generation request to the ImageRouter API.
        5.  On success, uploads the generated image to a Supabase Storage bucket.
        6.  Updates the `jobs` table entry with `status: 'completed'` and the URL of the stored image in `output_data`.
        7.  On failure, updates the `jobs` table with `status: 'failed'` and the error details in `error_log`.
    *   **Client-side:** The app polls the `jobs` table using the `job_id` to check for completion or failure.

### 4. Storage Management (Supabase Storage)

We will create a primary bucket for user-generated content.

*   **Bucket Name:** `user_assets`
*   **Folder Structure:** A structured path ensures data is organized and easy to secure.
    *   Profile Pictures: `public/avatars/{user_id}.png`
    *   Generated Images: `private/generated_images/{user_id}/{job_id}.png`
    *   Uploaded Files for Chat: `private/user_files/{user_id}/{chat_id}/{file_name}`
*   **Storage RLS Policies:**
    *   Allow public read access to the `public/` folder.
    *   Allow authenticated users to upload to their own `private/{user_id}/` folder.
    *   Allow authenticated users to read from their own `private/{user_id}/` folder.

### 5. Flutter App Refactoring Roadmap

The following is a guide to refactoring the existing services to use Supabase.

1.  **Setup `supabase-flutter`:**
    *   Add `supabase_flutter` to `pubspec.yaml`.
    *   Initialize Supabase in `lib/main.dart`:
        ```dart
        await Supabase.initialize(
          url: 'YOUR_SUPABASE_URL',
          anonKey: 'YOUR_SUPABASE_ANON_KEY',
        );
        ```

2.  **Refactor Authentication (`lib/services/auth_service.dart`, `lib/services/local_db_service.dart`)**:
    *   Remove `sqflite` and the local `users` table logic.
    *   Replace `_localDBService.register` with `Supabase.instance.client.auth.signUp`.
    *   Replace `_localDBService.login` with `Supabase.instance.client.auth.signInWithPassword`.
    *   Replace `_localDBService.logout` with `Supabase.instance.client.auth.signOut`.
    *   User profile data will be managed in the `profiles` table.

3.  **Refactor Chat History (`lib/services/chat_history_service.dart`)**:
    *   Remove `SharedPreferences` logic.
    *   `loadConversations`: Fetch from the `chats` table: `supabase.from('chats').select()`.
    *   `createConversation`: Insert into the `chats` table.
    *   `addMessageToConversation`: Insert into the `messages` table.
    *   Use Supabase Realtime Subscriptions to listen for new messages and update the UI automatically.

4.  **Refactor Model Management (`lib/services/model_service.dart`)**:
    *   `getSavedModels`: Fetch from the `model_configs` table.
    *   `saveModel`: `upsert` into the `model_configs` table.
    *   `deleteModel`: Delete from the `model_configs` table.
    *   `setDefaultModel`: This logic can be managed on the client or with a `is_default` flag in the `model_configs` table.

5.  **Refactor Core AI Logic (`lib/services/chat_service.dart`)**:
    *   Remove all direct HTTP calls to providers (OpenAI, Anthropic, etc.).
    *   Create a single function, e.g., `getBackendResponse`, that calls the `chat-request` Edge Function using `Supabase.instance.client.functions.invoke`.

6.  **Refactor Image Generation (`lib/services/image_router_service.dart`, `lib/component/image_generation_dialog.dart`)**:
    *   The `generateImage` function will now call the `image-generation` Edge Function.
    *   The dialog will show a loading state while polling the `jobs` table for the result.

By following this roadmap, you will successfully transform PocketLLM into a full-fledged, scalable, and secure AI application.