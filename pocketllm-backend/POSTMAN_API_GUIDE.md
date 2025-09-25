# PocketLLM API - Postman Testing Guide

## Base URL
```
http://localhost:8000/v1
```

## 🚀 Getting Started

Follow these steps to prepare the NestJS backend before exercising the API collection:

1. **Install dependencies**
   ```bash
   cd pocketllm-backend
   npm install
   ```
2. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   Update `.env` with your Supabase project URL and service role key (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`) and set an `ENCRYPTION_KEY` for securing provider API keys.
3. **Run the development server**
   ```bash
   npm run start:dev
   ```
   The REST API will be available at `http://localhost:8000/v1` and Swagger documentation at `http://localhost:8000/docs` (the legacy path `http://localhost:8000/api/docs` remains available).
4. **Authenticate requests**
   Use `POST /v1/auth/signin` to obtain an access token and send it in the `Authorization: Bearer <token>` header when calling protected routes. The Users, Chats, and Jobs controllers are guarded by the Supabase JWT so every request must include a valid token.

I've created a comprehensive API documentation guide for Postman testing. Let me create a summary of what was accomplished:

## 📋 **Complete API Documentation Created!**

I've created a comprehensive **Postman API Testing Guide** (`POSTMAN_API_GUIDE.md`) that includes:

### ✅ **All Endpoints Documented:**

1. **🔐 Authentication (2 endpoints)**
   - `POST /v1/auth/signup` - Sign up new user
   - `POST /v1/auth/signin` - Sign in existing user

2. **👤 Users (3 endpoints)**
   - `GET /v1/users/profile` - Get user profile
   - `PUT /v1/users/profile` - Update user profile  
   - `DELETE /v1/users/profile` - Delete user account

3. **💬 Chats (7 endpoints)**
   - `GET /v1/chats` - Get user chats
   - `POST /v1/chats` - Create new chat
   - `GET /v1/chats/{chatId}` - Get chat by ID
   - `PUT /v1/chats/{chatId}` - Update chat
   - `DELETE /v1/chats/{chatId}` - Delete chat
   - `POST /v1/chats/{chatId}/messages` - Send message
   - `GET /v1/chats/{chatId}/messages` - Get chat messages

4. **🎨 Jobs/Image Generation (7 endpoints)**
   - `GET /v1/jobs` - Get user jobs
   - `POST /v1/jobs/image-generation` - Create image generation job
   - `GET /v1/jobs/{jobId}` - Get job by ID
   - `DELETE /v1/jobs/{jobId}` - Cancel/Delete job
   - `POST /v1/jobs/{jobId}/retry` - Retry failed job
   - `GET /v1/jobs/image-generation/models` - Get available image models
   - `POST /v1/jobs/image-generation/estimate-cost` - Estimate image generation cost

5. **🧩 Models (5 endpoints)**
   - `GET /v1/models` - List saved models
   - `POST /v1/models/import` - Import models from a provider
   - `GET /v1/models/{modelId}` - Get model details
   - `DELETE /v1/models/{modelId}` - Delete a model
   - `POST /v1/models/{modelId}/default` - Set workspace default model

6. **🔌 Providers (5 endpoints)**
   - `GET /v1/providers` - List configured providers
   - `POST /v1/providers/activate` - Create or update provider credentials
   - `PATCH /v1/providers/{provider}` - Update provider metadata or keys
   - `DELETE /v1/providers/{provider}` - Deactivate provider and remove keys
   - `GET /v1/providers/{provider}/models` - Fetch available provider models



### 📋 **Each Endpoint Includes:**

- **Group classification** (auth, users, chats, jobs, models, providers)
- **Complete URL** with base URL
- **HTTP method** (GET, POST, PUT, DELETE)
- **Required headers** (Authorization, Content-Type)
- **Request body examples** (JSON format)
- **Response examples** (success cases)
- **Query parameters** where applicable
- **URL parameters** where applicable

### 🔧 **Additional Features:**

- **Authentication flow** instructions
- **Common headers** reference
- **Error response format** examples
- **HTTP status codes** reference
- **Testing notes** for Postman usage

### 🚀 **Ready for Postman Testing:**

You can now:
1. **Import the endpoints** into Postman collections
2. **Test each endpoint** with the provided examples
3. **Follow the authentication flow** to get access tokens
4. **Use the exact request/response formats** shown in the guide

The documentation follows your requested format with **Group**, **URL**, **Body**, and **Response** sections for easy Postman testing! 🎉

## Response Format
All API responses follow this standardized format:
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

---

## 🔐 Authentication

### POST /v1/auth/signup
**Group:** auth  
**URL:** `http://localhost:8000/v1/auth/signup`

**Body (JSON):**
```json
{
  "email": "user@example.com",
  "password": "password123"
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

### POST /v1/auth/signin
**Group:** auth  
**URL:** `http://localhost:8000/v1/auth/signin`

**Body (JSON):**
```json
{
  "email": "user@example.com",
  "password": "password123"
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

---

## 👤 Users

> **Note:** These profile operations execute behind the `SupabaseAuthGuard`, which resolves the authenticated Supabase user into `request.user.id`. Always supply a valid JWT via the `Authorization: Bearer <token>` header so the backend can resolve the correct profile record.

### GET /v1/users/profile
**Group:** users  
**URL:** `http://localhost:8000/v1/users/profile`

**Headers:**
```
Authorization: Bearer <access_token>
```

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

### PUT /v1/users/profile
**Group:** users  
**URL:** `http://localhost:8000/v1/users/profile`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
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

### DELETE /v1/users/profile
**Group:** users  
**URL:** `http://localhost:8000/v1/users/profile`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "User account deleted successfully"
  }
}
```

---

## 💬 Chats

### GET /v1/chats
**Group:** chats  
**URL:** `http://localhost:8000/v1/chats`

**Headers:**
```
Authorization: Bearer <access_token>
```

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

### POST /v1/chats
**Group:** chats  
**URL:** `http://localhost:8000/v1/chats`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
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

### GET /v1/chats/{chatId}
**Group:** chats  
**URL:** `http://localhost:8000/v1/chats/uuid-here`

**Headers:**
```
Authorization: Bearer <access_token>
```

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

### PUT /v1/chats/{chatId}
**Group:** chats  
**URL:** `http://localhost:8000/v1/chats/uuid-here`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
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

### DELETE /v1/chats/{chatId}
**Group:** chats  
**URL:** `http://localhost:8000/v1/chats/uuid-here`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Chat deleted successfully"
  }
}
```

### POST /v1/chats/{chatId}/messages
**Group:** chats
**URL:** `http://localhost:8000/v1/chats/uuid-here/messages`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
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

### GET /v1/chats/{chatId}/messages
**Group:** chats
**URL:** `http://localhost:8000/v1/chats/uuid-here/messages?limit=50&offset=0`

**Headers:**
```
Authorization: Bearer <access_token>
```

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

---

## 🎨 Jobs (Image Generation)

### GET /v1/jobs
**Group:** jobs
**URL:** `http://localhost:8000/v1/jobs?status=completed&limit=10`

**Headers:**
```
Authorization: Bearer <access_token>
```

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

### POST /v1/jobs/image-generation
**Group:** jobs
**URL:** `http://localhost:8000/v1/jobs/image-generation`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
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

### GET /v1/jobs/{jobId}
**Group:** jobs
**URL:** `http://localhost:8000/v1/jobs/uuid-here`

**Headers:**
```
Authorization: Bearer <access_token>
```

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

### DELETE /v1/jobs/{jobId}
**Group:** jobs
**URL:** `http://localhost:8000/v1/jobs/uuid-here`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Job cancelled/deleted successfully"
  }
}
```

### POST /v1/jobs/{jobId}/retry
**Group:** jobs
**URL:** `http://localhost:8000/v1/jobs/uuid-here/retry`

**Headers:**
```
Authorization: Bearer <access_token>
```

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

### GET /v1/jobs/image-generation/models
**Group:** jobs
**URL:** `http://localhost:8000/v1/jobs/image-generation/models`

**Headers:**
```
Authorization: Bearer <access_token>
```

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

### POST /v1/jobs/image-generation/estimate-cost
**Group:** jobs
**URL:** `http://localhost:8000/v1/jobs/image-generation/estimate-cost`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
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

---

## 🧩 Models

### GET /v1/models
**Group:** models
**URL:** `http://localhost:8000/v1/models`

**Headers:**
```
Authorization: Bearer <access_token>
```

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
  ]
}
```

### POST /v1/models/import
**Group:** models
**URL:** `http://localhost:8000/v1/models/import`

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "provider": "openrouter",
  "providerId": "uuid",
  "sharedSettings": {
    "temperature": 0.7
  },
  "selections": [
    {
      "id": "openrouter/gpt-4o-mini",
      "name": "GPT-4o Mini"
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
      "isDefault": false
    }
  ]
}
```

### GET /v1/models/{modelId}
**Group:** models
**URL:** `http://localhost:8000/v1/models/{modelId}`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "GPT-4o Mini",
    "provider": "openrouter",
    "model": "openrouter/gpt-4o-mini",
    "temperature": 0.7,
    "systemPrompt": "You are a helpful assistant."
  }
}
```

### DELETE /v1/models/{modelId}
**Group:** models
**URL:** `http://localhost:8000/v1/models/{modelId}`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Model deleted successfully"
  }
}
```

### POST /v1/models/{modelId}/default
**Group:** models
**URL:** `http://localhost:8000/v1/models/{modelId}/default`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "defaultModelId": "uuid"
  }
}
```

---

## 🔌 Providers

### GET /v1/providers
**Group:** providers
**URL:** `http://localhost:8000/v1/providers`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "provider": "openrouter",
      "displayName": "OpenRouter",
      "isActive": true,
      "hasApiKey": true,
      "apiKeyPreview": "xxxx",
      "baseUrl": "https://openrouter.ai/api"
    }
  ]
}
```

### POST /v1/providers/activate
**Group:** providers
**URL:** `http://localhost:8000/v1/providers/activate`

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "provider": "openrouter",
  "apiKey": "sk-or-123",
  "baseUrl": "https://openrouter.ai/api"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "provider": "openrouter",
    "displayName": "OpenRouter",
    "isActive": true,
    "hasApiKey": true,
    "apiKeyPreview": "0123"
  }
}
```

### PATCH /v1/providers/{provider}
**Group:** providers
**URL:** `http://localhost:8000/v1/providers/{provider}`

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "displayName": "OpenRouter (Primary)",
  "isActive": true
}
```

### DELETE /v1/providers/{provider}
**Group:** providers
**URL:** `http://localhost:8000/v1/providers/{provider}`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Provider deactivated"
  }
}
```

### GET /v1/providers/{provider}/models
**Group:** providers
**URL:** `http://localhost:8000/v1/providers/{provider}/models`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
```
search (optional): Filter models by ID, name, or description
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "openrouter/gpt-4o-mini",
      "name": "GPT-4o Mini",
      "description": "Fast reasoning tuned for chat"
    }
  ]
}
```

> **Provider Codes:** `openai`, `anthropic`, `ollama`, `openrouter`

---

## 📝 Testing Notes

### Authentication Flow
1. **Sign up**: `POST /v1/auth/signup`
2. **Sign in**: `POST /v1/auth/signin`
3. **Copy access_token** from response
4. **Use token** in Authorization header for all other requests

### Common Headers
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

### Error Responses
All errors follow the same format:
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

### Status Codes
- **200**: Success
- **201**: Created
- **400**: Bad Request (validation errors)
- **401**: Unauthorized (missing/invalid token)
- **403**: Forbidden
- **404**: Not Found
- **500**: Internal Server Error

### Mobile Device Connectivity
When running the Flutter client on a physical device while the backend is hosted on your development machine:

1. Confirm both devices share the same Wi‑Fi/LAN and the backend is reachable at `http://<computer-ip>:8000/docs` (or `http://<computer-ip>:8000/api/docs`).
2. Launch Flutter with a LAN override so API calls target your desktop instead of `localhost`:
   ```bash
   flutter run --dart-define=POCKETLLM_BACKEND_URL=http://<computer-ip>:8000/v1
   ```
3. Trigger Sign Up or Sign In in the app and watch the NestJS console for `/v1/auth/signup` or `/v1/auth/signin` log entries to verify traffic is flowing.

Replace `<computer-ip>` with the IPv4 address reported by `ipconfig` (Windows) or `ifconfig`/`ip addr` (macOS/Linux).
