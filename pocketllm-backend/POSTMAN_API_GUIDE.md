# PocketLLM API - Postman Testing Guide

## Base URL
```
http://localhost:8000/v1
```
## 🚀 Getting Started

Follow these steps to run the NestJS backend locally before testing the API in Postman:

1. **Install dependencies**
   ```bash
   cd pocketllm-backend
   npm install
   ```
2. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Update .env with your Supabase credentials and desired PORT/CORS values
   ```
3. **Start the development server**
   ```bash
   npm run start:dev
   ```
4. The API will be available at `http://localhost:8000/v1` and interactive Swagger docs at `http://localhost:8000/api/docs`.

## 📋 Endpoint Overview

The backend currently exposes the following authenticated endpoint groups:

- **🔐 Authentication (2 endpoints)**
  - `POST /v1/auth/signup` – Sign up new user
  - `POST /v1/auth/signin` – Sign in existing user

- **👤 Users (3 endpoints)**
  - `GET /v1/users/profile` – Get user profile
  - `PUT /v1/users/profile` – Update user profile
  - `DELETE /v1/users/profile` – Delete user account

- **💬 Chats (7 endpoints)**
  - `GET /v1/chats` – Get user chats
  - `POST /v1/chats` – Create new chat
  - `GET /v1/chats/{chatId}` – Get chat by ID
  - `PUT /v1/chats/{chatId}` – Update chat
  - `DELETE /v1/chats/{chatId}` – Delete chat
  - `POST /v1/chats/{chatId}/messages` – Send message
  - `GET /v1/chats/{chatId}/messages` – Get chat messages

- **🎨 Jobs/Image Generation (7 endpoints)**
  - `GET /v1/jobs` – Get user jobs
  - `POST /v1/jobs/image-generation` – Create image generation job
  - `GET /v1/jobs/{jobId}` – Get job by ID
  - `DELETE /v1/jobs/{jobId}` – Cancel/Delete job
  - `POST /v1/jobs/{jobId}/retry` – Retry failed job
  - `GET /v1/jobs/image-generation/models` – Get available image models
  - `POST /v1/jobs/image-generation/estimate-cost` – Estimate image generation cost

### 📋 **Each Endpoint Includes:**

- **Group classification** (auth, users, chats, jobs)
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
