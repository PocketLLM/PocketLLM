# PocketLLM Backend

This is the backend server for the PocketLLM Flutter application. It's built with Fastify and Deno, and it uses Supabase for the database and authentication, and integrates with Ollama for LLM functionality.

## Project Structure

The backend code is organized to separate concerns, making it easier to maintain and extend.

-   `src/api`: Contains the core Fastify application.
    -   `index.ts`: The main server entry point where plugins, hooks, and routes are registered.
    -   `routes/`: Defines the API endpoints. Each file corresponds to a feature area (e.g., `auth.ts`, `profiles.ts`).
    -   `v1/controllers/`: Contains the business logic for each route.
    -   `v1/schemas/`: Contains Zod schemas for validating request bodies and responses.
-   `src/shared`: Contains code shared across different parts of the application.
    -   `providers/`: Logic for communicating with third-party services like OpenAI, Anthropic, and Ollama.
    -   `utils/`: Shared utilities for handling responses, errors, and encryption.
-   `db/migrations`: Contains SQL scripts for database setup and migrations.

## Getting Started

### Prerequisites

-   [Deno](https://deno.land/) installed on your machine. You can install it for windows by running `irm https://deno.land/install.ps1 | iex` and for mac/linux by running `curl -fsSL https://deno.land/install.sh | sh`
-   A Supabase project. You can create one for free at [supabase.com](https://supabase.com).

### 1. Environment Setup

You'll need to provide your Supabase credentials to the application via environment variables.

1.  Create a file named `.env` in this directory (`pocketllm-backend`).
2.  Add the following variables to the `.env` file, replacing the placeholders with your actual Supabase project keys:

    ```sh
    # Found in your Supabase project's API settings
    SUPABASE_URL=your_supabase_project_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
    ```

### 2. Database Setup

The initial database schema needs to be applied to your Supabase project.

1.  In your Supabase project dashboard, go to the **SQL Editor**.
2.  Click on **New query**.
3.  Open the `db/migrations/initial_schema.sql` file from this repository.
4.  Copy the entire content of the SQL file, paste it into the Supabase SQL Editor, and click **RUN**.

This will create all the necessary tables (`profiles`, `model_configs`, etc.), functions, and row-level security policies.

### 3. Running the Server

The server is designed to be run as a Supabase Edge Function, but you can run it locally for development.

From within the `pocketllm-backend` directory, run:
```bash
deno run --allow-net --allow-env --allow-read --env-file=.env src/api/index.ts
```
This command starts the server, allowing it to access the network (for Supabase/Ollama), read environment variables (from your `.env` file), and read files from the filesystem.

## Development Guidelines

### Adding a New Endpoint

To add a new feature endpoint (e.g., `/v1/new-feature`), follow this pattern:

1.  **Schema:** Add request/response validation schemas to the relevant file in `src/api/v1/schemas/`.
2.  **Controller:** Implement the business logic for the endpoint in a handler function in `src/api/v1/controllers/`.
3.  **Route:** Define the endpoint path and connect it to the schema and controller in `src/api/routes/`.
4.  **Register:** Import and register the new route in `src/api/index.ts`. Ensure you place it inside the authenticated block if it's a protected route.
