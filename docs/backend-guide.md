Of course. Here is a detailed report on the necessary changes to create a database-backed backend for your PocketLLM project, including API design and a database schema.

## Project Analysis and Backend Migration Plan for PocketLLM

### 1. Project Overview

PocketLLM is a cross-platform AI chat application built with Flutter. Its core strength lies in its ability to interact with various Large Language Models (LLMs), either by running them locally on a device (via Ollama in Termux) or by connecting to external providers like OpenAI, Anthropic, and others.

Currently, the application relies heavily on local storage (`shared_preferences`, `sqflite`, `flutter_secure_storage`) for managing user data, chat history, and model configurations. While this is effective for a standalone, offline-first application, moving to a centralized backend will enable cross-device synchronization, more robust data management, and enhanced security.

This report outlines the steps and design considerations for migrating PocketLLM to a client-server architecture with a Flutter frontend and a NestJS/Node.js backend.

### Unified Catalogue Workflow (FastAPI implementation)

The current FastAPI backend ships with a consolidated model catalogue pipeline:

1. Provider records are read from Supabase and decrypted per user request.
2. `ProvidersService.get_provider_models` verifies an API key exists for each provider before instantiating SDK clients—environment fallbacks are intentionally disabled.
3. `ProviderModelCatalogue` fans out to OpenAI, Groq, OpenRouter, and ImageRouter using their official Python SDKs, applying caching and structured logging.
4. Responses are wrapped in `ProviderModelsResponse`, exposing the aggregated `models` list along with helpful `message`, `configured_providers`, and `missing_providers` fields so the Flutter UI can prompt users to add credentials when necessary.

Both `GET /v1/models` and `GET /v1/providers/{provider}/models` rely on this workflow, guaranteeing consistent behaviour regardless of whether the UI requests a specific provider or the entire catalogue.

### 2. Proposed Architecture

The new architecture will consist of:

*   **Flutter Frontend:** The existing application will be refactored to act as a client. It will handle the UI and user interactions, but all data persistence and business logic will be offloaded to the backend via API calls.
*   **NestJS/Node.js Backend:** A new backend server will be created to manage:
    *   User authentication and sessions.
    *   Database interactions (storing and retrieving all application data).
    *   Proxying requests to third-party LLM providers. This is crucial for security, as it keeps provider API keys off the client devices.
*   **Database:** A relational database (like PostgreSQL or MySQL) will be used to store all application data.

### 3. API Endpoint Design

Below is a proposed set of RESTful API endpoints that the backend will need to expose.

#### 3.1. Authentication (`/auth`)

Handles user registration, login, and session management.

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/auth/register` | Creates a new user account. |
| `POST` | `/auth/login` | Authenticates a user and returns a session token (e.g., JWT). |
| `POST` | `/auth/logout` | Invalidates the user's session token. |
| `GET` | `/auth/me` | Retrieves the profile of the currently authenticated user. |

#### 3.2. Users (`/users`)

Manages user profile information.

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/users/:id` | Retrieves a user's public profile. |
| `PATCH` | `/users/me` | Updates the authenticated user's profile information. |

#### 3.3. Model Configurations (`/model-configs`)

Manages the user's saved LLM provider configurations.

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/model-configs` | Creates a new model configuration for the user. |
| `GET` | `/model-configs` | Retrieves all model configurations for the user. |
| `GET` | `/model-configs/:id` | Retrieves a single model configuration. |
| `PATCH` | `/model-configs/:id` | Updates an existing model configuration. |
| `DELETE` | `/model-configs/:id` | Deletes a model configuration. |

#### 3.4. Chat (`/chats`)

Manages chat conversations and messages.

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/chats` | Creates a new chat conversation. |
| `GET` | `/chats` | Retrieves all of the user's chat conversations (metadata only). |
| `GET` | `/chats/:id` | Retrieves a single conversation, including all of its messages. |
| `POST` | `/chats/:id/messages` | Sends a new message to a conversation. The backend will then proxy this request to the appropriate LLM provider. |
| `DELETE` | `/chats/:id` | Deletes a conversation and all of its messages. |

#### 3.5. Image Generation (`/images`)

Proxies requests to the ImageRouter service.

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/images/generations` | Generates an image based on a prompt, proxying the request to ImageRouter. |

### 4. Database Design

A relational database is recommended. The following schema outlines the necessary tables, columns, and relationships.

#### `users`

Stores user account and profile information.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY | Unique identifier for the user. |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | User's email address. |
| `password_hash` | VARCHAR(255) | NOT NULL | Hashed password. |
| `full_name` | VARCHAR(255) | | User's full name. |
| `username` | VARCHAR(255) | UNIQUE | User's chosen username. |
| `bio` | TEXT | | A short biography of the user. |
| `date_of_birth` | DATE | | User's date of birth. |
| `profession` | VARCHAR(255) | | User's profession. |
| `avatar_url` | VARCHAR(255) | | URL to the user's profile picture. |
| `created_at` | TIMESTAMP | NOT NULL | Timestamp of account creation. |
| `updated_at` | TIMESTAMP | NOT NULL | Timestamp of the last profile update. |

#### `model_configs`

Stores user-defined configurations for different LLM providers.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY | Unique identifier for the configuration. |
| `user_id` | UUID | FOREIGN KEY (users.id) | The user who owns this configuration. |
| `name` | VARCHAR(255) | NOT NULL | A user-friendly name for the configuration. |
| `provider` | VARCHAR(50) | NOT NULL | The LLM provider (e.g., 'openai', 'ollama'). |
| `base_url` | VARCHAR(255) | NOT NULL | The base URL for the provider's API. |
| `api_key_encrypted` | TEXT | | The encrypted API key for the provider. |
| `model` | VARCHAR(255) | NOT NULL | The specific model to be used (e.g., 'gpt-4'). |
| `system_prompt` | TEXT | | A custom system prompt for the model. |
| `temperature` | FLOAT | | The temperature setting for the model. |
| `created_at` | TIMESTAMP | NOT NULL | Timestamp of configuration creation. |
| `updated_at` | TIMESTAMP | NOT NULL | Timestamp of the last configuration update. |

#### `chats`

Stores metadata for each chat conversation.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY | Unique identifier for the chat. |
| `user_id` | UUID | FOREIGN KEY (users.id) | The user who owns this chat. |
| `model_config_id` | UUID | FOREIGN KEY (model\_configs.id) | The model configuration used for this chat. |
| `title` | VARCHAR(255) | NOT NULL | A title for the chat, generated from the first message. |
| `created_at` | TIMESTAMP | NOT NULL | Timestamp of chat creation. |
| `updated_at` | TIMESTAMP | NOT NULL | Timestamp of the last message in the chat. |

#### `messages`

Stores individual messages within each chat.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY | Unique identifier for the message. |
| `chat_id` | UUID | FOREIGN KEY (chats.id) | The chat this message belongs to. |
| `content` | TEXT | NOT NULL | The text content of the message. |
| `role` | VARCHAR(50) | NOT NULL | The role of the message sender ('user' or 'assistant'). |
| `timestamp` | TIMESTAMP | NOT NULL | Timestamp of when the message was created. |
| `metadata` | JSONB | | Additional data, such as sources, errors, or token counts. |

### 5. Refactoring Plan for the Flutter App

To integrate with the new backend, the following services and components in the Flutter app will need to be refactored:

*   **`lib/services/local_db_service.dart` and `lib/services/auth_service.dart`**: These will be replaced with a new `ApiService` that handles all communication with the backend. Authentication logic will involve storing a session token (JWT) and sending it with each request.

*   **`lib/services/chat_history_service.dart`**: Instead of reading from/writing to `shared_preferences`, this service will make API calls to the `/chats` endpoints on the backend.

*   **`lib/services/model_service.dart`**: This service will be updated to fetch, create, update, and delete model configurations via the `/model-configs` API endpoints.

*   **`lib/services/chat_service.dart`**: The logic for communicating with different LLM providers will be removed. Instead, it will make a single API call to the backend's `/chats/:id/messages` endpoint, sending the user's message and letting the backend handle the rest.

*   **`lib/services/image_router_service.dart`**: This will be refactored to call the `/images/generations` endpoint on your backend instead of directly calling the ImageRouter API.

*   **UI Components (`lib/pages/` and `lib/component/`)**: Pages like `ProfileSettingsPage`, `ModelSettingsPage`, and `ChatInterface` will need to be updated to use the new `ApiService` for all data operations. State management will need to handle loading, error, and success states for API calls.

By following this plan, you can successfully migrate PocketLLM to a more scalable, secure, and feature-rich client-server architecture.