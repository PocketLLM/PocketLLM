# PocketLLM API Documentation

Welcome to the PocketLLM backend API documentation. This document provides detailed information about all available endpoints, including request formats, response structures, and examples.

## Base URL

All API endpoints are prefixed with `/v1`. The full URL will depend on where the Supabase Edge Function is hosted. For local development, it will be `http://localhost:PORT/v1`.

## Standard Response Format

All API responses, both success and error, follow a standardized JSON format:

```json
{
  "success": true,
  "data": { ... } | null,
  "error": { "message": "..." } | null,
  "metadata": {
    "timestamp": "2023-10-27T10:00:00.000Z",
    "requestId": "uuid-v4-string",
    "processingTime": 123.45
  }
}
```

---

## 1. Authentication

These endpoints handle user registration and login.

### Sign Up

-   **Request:** `POST /v1/auth/signup`
-   **Description:** Creates a new user account. Supabase may require email confirmation depending on project settings.
-   **Authentication:** `Public`
-   **Request Body:**
    ```json
    {
      "email": "user@example.com",
      "password": "a-strong-password"
    }
    ```
-   **Example Request (cURL):**
    ```bash
    curl -X POST http://localhost:PORT/v1/auth/signup \
    -H "Content-Type: application/json" \
    -d '{"email": "user@example.com", "password": "a-strong-password"}'
    ```
-   **Example Success Response (201 Created):**
    ```json
    {
        "success": true,
        "data": {
            "user": { "id": "...", "email": "user@example.com", ... },
            "session": { "access_token": "...", ... }
        },
        "error": null,
        "metadata": { ... }
    }
    ```

### Sign In

-   **Request:** `POST /v1/auth/signin`
-   **Description:** Logs in a user and returns a JWT session.
-   **Authentication:** `Public`
-   **Request Body:**
    ```json
    {
      "email": "user@example.com",
      "password": "a-strong-password"
    }
    ```
-   **Example Request (cURL):**
    ```bash
    curl -X POST http://localhost:PORT/v1/auth/signin \
    -H "Content-Type: application/json" \
    -d '{"email": "user@example.com", "password": "a-strong-password"}'
    ```
-   **Example Success Response (200 OK):**
    ```json
    {
        "success": true,
        "data": {
            "user": { "id": "...", "email": "user@example.com", ... },
            "session": { "access_token": "...", ... }
        },
        "error": null,
        "metadata": { ... }
    }
    ```
-   **Example Error Response (401 Unauthorized):**
    ```json
    {
        "success": false,
        "data": null,
        "error": { "message": "Invalid login credentials" },
        "metadata": { ... }
    }
    ```

### OAuth "Coming Soon"

-   **Request:** `GET /v1/auth/google`, `GET /v1/auth/github`, etc.
-   **Description:** Placeholder endpoints for future OAuth integration.
-   **Authentication:** `Public`
-   **Example Error Response (501 Not Implemented):**
    ```json
    {
        "success": false,
        "data": null,
        "error": { "message": "OAuth integration is coming soon." },
        "metadata": { ... }
    }
    ```

---

## 2. User Profile

These endpoints manage user profile data.

### Get My Profile

-   **Request:** `GET /v1/profiles/me`
-   **Description:** Retrieves the profile of the currently authenticated user.
-   **Authentication:** `Required (Bearer Token)`
-   **Example Success Response (200 OK):**
    ```json
    {
        "success": true,
        "data": {
            "id": "uuid",
            "full_name": "Jane Doe",
            "username": "janedoe",
            "bio": "Software Engineer",
            ...
        },
        "error": null,
        "metadata": { ... }
    }
    ```

### Update My Profile

-   **Request:** `PUT /v1/profiles/me`
-   **Description:** Updates the profile of the currently authenticated user. All fields are optional.
-   **Authentication:** `Required (Bearer Token)`
-   **Request Body:**
    ```json
    {
      "full_name": "Jane Doe Updated",
      "bio": "Senior Software Engineer"
    }
    ```
-   **Example Success Response (200 OK):**
    ```json
    {
        "success": true,
        "data": {
            "id": "uuid",
            "full_name": "Jane Doe Updated",
            "username": "janedoe",
            "bio": "Senior Software Engineer",
            ...
        },
        "error": null,
        "metadata": { ... }
    }
    ```

### Delete My Profile

-   **Request:** `DELETE /v1/profiles/me`
-   **Description:** Permanently deletes the user's account and all associated data.
-   **Authentication:** `Required (Bearer Token)`
-   **Example Success Response (200 OK):**
    ```json
    {
        "success": true,
        "data": {
            "message": "User account permanently deleted."
        },
        "error": null,
        "metadata": { ... }
    }
    ```

---

## 3. Ollama Integration

### List Local Models

-   **Request:** `GET /v1/ollama/models`
-   **Description:** Lists all models available on the user's default Ollama instance.
-   **Authentication:** `Required (Bearer Token)`
-   **Example Success Response (200 OK):**
    ```json
    {
        "success": true,
        "data": {
            "models": [
                {
                    "name": "llama3:latest",
                    "modified_at": "...",
                    "size": 3825819519,
                    ...
                }
            ]
        },
        "error": null,
        "metadata": { ... }
    }
    ```

### Get Model Information

-   **Request:** `GET /v1/ollama/models/:modelName`
-   **Description:** Shows detailed information for a specific model from the user's default Ollama instance.
-   **Authentication:** `Required (Bearer Token)`
-   **Example Success Response (200 OK):**
    ```json
    {
        "success": true,
        "data": {
            "modelfile": "...",
            "parameters": "...",
            ...
        },
        "error": null,
        "metadata": { ... }
    }
    ```

### Chat Completion (Streaming)

-   **Request:** `POST /v1/chats/:chatId/messages`
-   **Description:** Sends a prompt to a chat. If the chat's model provider is 'ollama', it will stream the response using Server-Sent Events (SSE).
-   **Authentication:** `Required (Bearer Token)`
-   **Response Format:** The response is a stream of `text/event-stream` data. Each event is a JSON object.
    -   **Content chunks:** `data: {"content": "some text"}`
    -   **Final event:** `data: {"done": true}`
-   **Note:** The controller handles saving the user's prompt and the assistant's full response to the database automatically.

### Generate Embeddings

-   **Request:** `POST /v1/ollama/embeddings`
-   **Description:** Generates embeddings for a given input string or array of strings using a specified Ollama model configuration.
-   **Authentication:** `Required (Bearer Token)`
-   **Request Body:**
    ```json
    {
      "model_config_id": "uuid-of-ollama-config",
      "input": "This is a test sentence."
    }
    ```
-   **Example Success Response (200 OK):**
    ```json
    {
        "success": true,
        "data": {
            "embeddings": [
                [0.1, 0.2, 0.3, ...]
            ]
        },
        "error": null,
        "metadata": { ... }
    }
    ```

---

## 4. Model Configurations

These endpoints manage user-specific model configurations stored in our database.

-   `POST /v1/model-configs`: Create a new model configuration.
-   `GET /v1/model-configs`: List all of the user's model configurations.
-   `GET /v1/model-configs/:id`: Get a specific model configuration.
-   `PATCH /v1/model-configs/:id`: Update a model configuration.
-   `DELETE /v1/model-configs/:id`: Delete a model configuration.

*(These are existing endpoints, documented here for completeness. The request/response formats follow the standard structure.)*
