# PocketLLM API Documentation

This document provides comprehensive documentation for the PocketLLM backend API, built with NestJS. The API follows RESTful principles and provides endpoints for authentication, user management, chat functionality, and background jobs.

## 🏗️ Architecture Overview

The backend is structured as a NestJS application with the following key modules:

- **Auth Module**: User authentication and authorization
- **Users Module**: User profile management
- **Chats Module**: Chat sessions and message handling
- **Jobs Module**: Background task processing (image generation)
- **Providers Module**: Integration with AI providers (OpenAI, Anthropic, Ollama)

## 🌐 Base URL

```
http://localhost:8000/v1
```

For production deployments, replace `localhost:8000` with your server address.

## 🔐 Authentication

All protected endpoints require a valid JWT token in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

### Sign Up

**POST** `/auth/signup`

Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "created_at": "2023-10-27T10:00:00.000Z",
      "aud": "authenticated",
      "role": "authenticated"
    },
    "session": null,
    "message": "User created successfully. Please sign in to get a session."
  }
}
```

### Sign In

**POST** `/auth/signin`

Authenticate a user and obtain an access token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "created_at": "2023-10-27T10:00:00.000Z"
    },
    "session": {
      "access_token": "jwt_token_here",
      "refresh_token": "refresh_token_here",
      "expires_in": 3600,
      "token_type": "bearer"
    }
  }
}
```

## 👤 Users

User profile operations require authentication.

### Get User Profile

**GET** `/users/profile`

Retrieve the authenticated user's profile information.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "full_name": "John Doe",
    "username": "johndoe",
    "bio": "Software developer",
    "date_of_birth": "1990-01-01",
    "profession": "Developer",
    "avatar_url": "https://example.com/avatar.jpg",
    "survey_completed": true,
    "created_at": "2023-10-27T10:00:00.000Z",
    "updated_at": "2023-10-27T10:00:00.000Z"
  }
}
```

### Update User Profile

**PUT** `/users/profile`

Update the authenticated user's profile information.

**Request Body:**
```json
{
  "full_name": "John Doe Updated",
  "username": "johndoe_new",
  "bio": "Senior Software Developer",
  "date_of_birth": "1990-01-01",
  "profession": "Senior Developer",
  "avatar_url": "https://example.com/new_avatar.jpg",
  "survey_completed": true
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "full_name": "John Doe Updated",
    "username": "johndoe_new",
    "bio": "Senior Software Developer",
    "date_of_birth": "1990-01-01",
    "profession": "Senior Developer",
    "avatar_url": "https://example.com/new_avatar.jpg",
    "survey_completed": true,
    "created_at": "2023-10-27T10:00:00.000Z",
    "updated_at": "2023-10-27T11:00:00.000Z"
  }
}
```

### Delete User Profile

**DELETE** `/users/profile`

Permanently delete the authenticated user's account and all associated data.

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "User account deleted successfully"
  }
}
```

## 💬 Chats

Chat operations require authentication and are scoped to the authenticated user.

### List User Chats

**GET** `/chats`

Retrieve all chats for the authenticated user.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "title": "My Chat",
      "model_config": {
        "provider": "openai",
        "model": "gpt-4",
        "apiKey": "sk-...",
        "systemPrompt": "You are a helpful assistant",
        "temperature": 0.7,
        "maxTokens": 1000
      },
      "created_at": "2023-10-27T10:00:00.000Z",
      "updated_at": "2023-10-27T10:00:00.000Z"
    }
  ]
}
```

### Create New Chat

**POST** `/chats`

Create a new chat session.

**Request Body:**
```json
{
  "title": "New Chat",
  "model_config": {
    "provider": "openai",
    "model": "gpt-4",
    "apiKey": "sk-...",
    "systemPrompt": "You are a helpful assistant",
    "temperature": 0.7,
    "maxTokens": 1000
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "title": "New Chat",
    "model_config": {
      "provider": "openai",
      "model": "gpt-4",
      "apiKey": "sk-...",
      "systemPrompt": "You are a helpful assistant",
      "temperature": 0.7,
      "maxTokens": 1000
    },
    "created_at": "2023-10-27T10:00:00.000Z",
    "updated_at": "2023-10-27T10:00:00.000Z"
  }
}
```

### Get Chat Details

**GET** `/chats/{chatId}`

Retrieve details of a specific chat.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "title": "My Chat",
    "model_config": {
      "provider": "openai",
      "model": "gpt-4"
    },
    "created_at": "2023-10-27T10:00:00.000Z",
    "updated_at": "2023-10-27T10:00:00.000Z"
  }
}
```

### Update Chat

**PUT** `/chats/{chatId}`

Update a chat's title or model configuration.

**Request Body:**
```json
{
  "title": "Updated Chat Title",
  "model_config": {
    "provider": "anthropic",
    "model": "claude-3-sonnet",
    "apiKey": "sk-...",
    "temperature": 0.5
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "title": "Updated Chat Title",
    "model_config": {
      "provider": "anthropic",
      "model": "claude-3-sonnet",
      "temperature": 0.5
    },
    "created_at": "2023-10-27T10:00:00.000Z",
    "updated_at": "2023-10-27T11:00:00.000Z"
  }
}
```

### Delete Chat

**DELETE** `/chats/{chatId}`

Permanently delete a chat and all its messages.

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Chat deleted successfully"
  }
}
```

### Send Message

**POST** `/chats/{chatId}/messages`

Send a message in a chat and receive the AI response.

**Request Body:**
```json
{
  "content": "Hello, how are you?",
  "model_config": {
    "provider": "openai",
    "model": "gpt-4",
    "apiKey": "sk-...",
    "systemPrompt": "You are a helpful assistant",
    "temperature": 0.7,
    "maxTokens": 1000
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "userMessage": {
      "id": "uuid",
      "chat_id": "uuid",
      "content": "Hello, how are you?",
      "role": "user",
      "created_at": "2023-10-27T10:00:00.000Z"
    },
    "assistantMessage": {
      "id": "uuid",
      "chat_id": "uuid",
      "content": "Hello! I'm doing well, thank you for asking. How can I help you today?",
      "role": "assistant",
      "created_at": "2023-10-27T10:00:01.000Z"
    }
  }
}
```

### Get Chat Messages

**GET** `/chats/{chatId}/messages?limit=50&offset=0`

Retrieve messages from a specific chat.

**Query Parameters:**
- `limit` (optional): Maximum number of messages (default: 50, max: 100)
- `offset` (optional): Number of messages to skip (default: 0)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "chat_id": "uuid",
      "content": "Hello, how are you?",
      "role": "user",
      "created_at": "2023-10-27T10:00:00.000Z"
    },
    {
      "id": "uuid",
      "chat_id": "uuid",
      "content": "Hello! I'm doing well, thank you for asking.",
      "role": "assistant",
      "created_at": "2023-10-27T10:00:01.000Z"
    }
  ]
}
```

## 🎨 Jobs (Image Generation)

Job operations require authentication and are scoped to the authenticated user.

### List User Jobs

**GET** `/jobs?status=completed&limit=10`

Retrieve background jobs for the authenticated user.

**Query Parameters:**
- `status` (optional): pending, processing, completed, failed, cancelled
- `type` (optional): image_generation
- `limit` (optional): Max 100, default 50
- `offset` (optional): Default 0

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "type": "image_generation",
      "status": "completed",
      "parameters": {
        "prompt": "A beautiful sunset",
        "model": "dall-e-3",
        "size": "1024x1024",
        "quality": "hd"
      },
      "result": {
        "imageUrl": "https://example.com/image.png",
        "revisedPrompt": "A beautiful sunset over mountains"
      },
      "estimated_cost": 0.04,
      "actual_cost": 0.04,
      "created_at": "2023-10-27T10:00:00.000Z",
      "completed_at": "2023-10-27T10:01:00.000Z"
    }
  ]
}
```

### Create Image Generation Job

**POST** `/jobs/image-generation`

Create a new image generation job.

**Request Body:**
```json
{
  "prompt": "A beautiful sunset over mountains",
  "model": "dall-e-3",
  "size": "1024x1024",
  "quality": "hd",
  "style": "vivid",
  "n": 1
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "type": "image_generation",
    "status": "pending",
    "parameters": {
      "prompt": "A beautiful sunset over mountains",
      "model": "dall-e-3",
      "size": "1024x1024",
      "quality": "hd",
      "style": "vivid",
      "n": 1
    },
    "estimated_cost": 0.04,
    "created_at": "2023-10-27T10:00:00.000Z"
  }
}
```

### Get Job Details

**GET** `/jobs/{jobId}`

Retrieve details of a specific job.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "type": "image_generation",
    "status": "completed",
    "parameters": {
      "prompt": "A beautiful sunset over mountains",
      "model": "dall-e-3",
      "size": "1024x1024"
    },
    "result": {
      "imageUrl": "https://example.com/image.png",
      "revisedPrompt": "A beautiful sunset over mountains with golden light"
    },
    "estimated_cost": 0.04,
    "actual_cost": 0.04,
    "created_at": "2023-10-27T10:00:00.000Z",
    "completed_at": "2023-10-27T10:01:00.000Z"
  }
}
```

### Cancel/Delete Job

**DELETE** `/jobs/{jobId}`

Cancel or delete a job.

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Job cancelled/deleted successfully"
  }
}
```

### Retry Job

**POST** `/jobs/{jobId}/retry`

Retry a failed job.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "pending",
    "message": "Job queued for retry"
  }
}
```

### Get Available Image Models

**GET** `/jobs/image-generation/models`

Retrieve available image generation models and their capabilities.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "name": "dall-e-3",
      "provider": "openai",
      "sizes": ["1024x1024", "1792x1024", "1024x1792"],
      "quality": ["standard", "hd"],
      "pricing": {
        "1024x1024_standard": 0.04,
        "1024x1024_hd": 0.08,
        "1792x1024_standard": 0.08,
        "1792x1024_hd": 0.12
      }
    },
    {
      "name": "dall-e-2",
      "provider": "openai",
      "sizes": ["256x256", "512x512", "1024x1024"],
      "quality": ["standard"],
      "pricing": {
        "256x256": 0.016,
        "512x512": 0.018,
        "1024x1024": 0.02
      }
    }
  ]
}
```

### Estimate Image Generation Cost

**POST** `/jobs/image-generation/estimate-cost`

Estimate the cost of an image generation request.

**Request Body:**
```json
{
  "model": "dall-e-3",
  "size": "1024x1024",
  "quality": "hd",
  "n": 2
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "estimatedCost": 0.16,
    "currency": "USD",
    "breakdown": {
      "model": "dall-e-3",
      "size": "1024x1024",
      "quality": "hd",
      "quantity": 2,
      "unitCost": 0.08
    }
  }
}
```

## 📡 Response Format

All API responses follow a standardized format:

**Success Response:**
```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "metadata": {
    "timestamp": "2023-10-27T10:00:00.000Z",
    "requestId": "uuid-v4-string",
    "processingTime": 123.45
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "data": null,
  "error": {
    "message": "Error description here"
  },
  "metadata": {
    "timestamp": "2023-10-27T10:00:00.000Z",
    "requestId": "uuid",
    "processingTime": 123.45
  }
}
```

## 🧩 Model Management

Model operations require authentication. All responses follow the standard envelope documented above.

### List Saved Models

**GET** `/models`

Retrieve all models imported into the authenticated user's workspace.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "GPT-4 Preview",
      "provider": "openrouter",
      "model": "openrouter/gpt-4o-mini",
      "baseUrl": "https://openrouter.ai/api",
      "isDefault": true,
      "metadata": {
        "description": "Balanced reasoning + speed"
      },
      "createdAt": "2024-02-15T10:00:00.000Z",
      "updatedAt": "2024-02-18T12:00:00.000Z"
    }
  ],
  "error": null,
  "metadata": {
    "requestId": "uuid",
    "timestamp": "2024-02-18T12:01:00.000Z"
  }
}
```

### Import Models From a Provider

**POST** `/models/import`

Import one or more provider models into the user's workspace.

**Request Body:**
```json
{
  "provider": "openrouter",
  "providerId": "uuid",
  "sharedSettings": {
    "temperature": 0.7,
    "systemPrompt": "You are a helpful assistant."
  },
  "selections": [
    {
      "id": "openrouter/gpt-4o-mini",
      "name": "GPT-4o Mini",
      "description": "Fast reasoning tuned for chat"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "GPT-4o Mini",
      "provider": "openrouter",
      "model": "openrouter/gpt-4o-mini",
      "isDefault": false,
      "createdAt": "2024-02-18T12:05:00.000Z",
      "updatedAt": "2024-02-18T12:05:00.000Z"
    }
  ]
}
```

### Get Model Details

**GET** `/models/{modelId}`

Return a single saved model configuration.

### Delete Model

**DELETE** `/models/{modelId}`

Remove a saved model. The backend will automatically choose a fallback default if the deleted model was marked as default.

### Set Default Model

**POST** `/models/{modelId}/default`

Mark the supplied model as the workspace default. The backend ensures only one default exists at a time and updates cached model metadata accordingly.

---

## 🔌 Provider Integrations

Provider configuration endpoints manage API credentials and fetch remote catalog metadata. All routes require authentication and resolve the provider code via the path parameter.

### List Providers

**GET** `/providers`

Return every provider configured for the authenticated user. Each record indicates whether credentials are active and whether an API key preview is available.

### Activate or Create Provider Credentials

**POST** `/providers/activate`

**Request Body:**
```json
{
  "provider": "openrouter",
  "apiKey": "sk-or-xxx",
  "baseUrl": "https://openrouter.ai/api",
  "metadata": {
    "defaultModel": "gpt-4o-mini"
  }
}
```

The backend encrypts the API key, stores a secure hash preview, and upserts the provider record.

### Update Provider Configuration

**PATCH** `/providers/{provider}`

Supply any subset of fields (`apiKey`, `baseUrl`, `metadata`, `displayName`, `isActive`). Passing `apiKey: null` removes stored credentials.

### Deactivate Provider

**DELETE** `/providers/{provider}`

Marks the provider inactive and erases stored API key material.

### List Provider Models

**GET** `/providers/{provider}/models`

Fetch the catalog of available models from the remote provider configuration. Supports an optional `search` query parameter for client-side filtering.

---

## 📱 Testing With a Mobile Device

To exercise the NestJS backend from a physical phone or tablet:

1. **Ensure both devices share a network.** Connect the development machine running `npm run start:dev` and the mobile device to the same Wi‑Fi/LAN.
2. **Expose the backend on the LAN.** The NestJS server already listens on `0.0.0.0`; confirm it is reachable by visiting `http://<your-computer-ip>:8000/api/docs` from another device.
3. **Run Flutter with the LAN URL.** When launching the app, override the backend base URL so API calls target your desktop instead of `localhost`:
   ```bash
   flutter run --dart-define=POCKETLLM_BACKEND_URL=http://<your-computer-ip>:8000/v1
   ```
   Replace `<your-computer-ip>` with the IPv4 address shown by `ipconfig` (Windows) or `ifconfig`/`ip addr` (macOS/Linux).
4. **Verify authentication calls.** After the app starts, the Sign In and Sign Up flows will send requests to the configured backend URL. Monitor the NestJS console logs to confirm the `/v1/auth/signup` and `/v1/auth/signin` handlers execute when you tap the respective buttons in the mobile UI.

If the device cannot reach the backend, double-check VPNs or firewalls, and ensure the mobile network does not isolate clients (some public hotspots do).

---

## 🚨 Error Handling

The API uses standard HTTP status codes:

- **200**: Success
- **201**: Created
- **400**: Bad Request (validation errors)
- **401**: Unauthorized (missing/invalid token)
- **403**: Forbidden
- **404**: Not Found
- **500**: Internal Server Error

## 🔒 Security

- All API communication should use HTTPS in production
- Authentication tokens expire after 1 hour
- API keys are encrypted before storage
- Rate limiting is implemented to prevent abuse
- Input validation is performed on all endpoints

## 🧪 Testing

For testing the API, you can use:

1. **Postman**: Import the collection from [POSTMAN_API_GUIDE.md](../pocketllm-backend/POSTMAN_API_GUIDE.md)
2. **curl**: Command-line HTTP client
3. **Swagger UI**: Available at `http://localhost:8000/api/docs` when the server is running

## 📚 Additional Resources

- [Backend README](../pocketllm-backend/README.md)
- [Postman API Guide](../pocketllm-backend/POSTMAN_API_GUIDE.md)
- [Database Schema](../pocketllm-backend/db/migrations/initial_schema.sql)