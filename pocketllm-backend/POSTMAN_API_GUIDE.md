# PocketLLM API - Postman Testing Guide

## Base URL
```
http://localhost:8000/v1
```
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

4. **🤖 Models (8 endpoints)**
   - `GET /v1/models` - Get available models
   - `GET /v1/models/user` - Get user model configurations
   - `POST /v1/models/user` - Save user model configuration
   - `PUT /v1/models/user/{configId}` - Update user model configuration
   - `DELETE /v1/models/user/{configId}` - Delete user model configuration
   - `POST /v1/models/test` - Test model configuration
   - `GET /v1/models/providers` - Get supported providers
   - `GET /v1/models/providers/{provider}/models` - Get models for provider

5. **🎨 Jobs/Image Generation (7 endpoints)**
   - `GET /v1/jobs` - Get user jobs
   - `POST /v1/jobs/image-generation` - Create image generation job
   - `GET /v1/jobs/{jobId}` - Get job by ID
   - `DELETE /v1/jobs/{jobId}` - Cancel/Delete job
   - `POST /v1/jobs/{jobId}/retry` - Retry failed job
   - `GET /v1/jobs/image-generation/models` - Get available image models
   - `POST /v1/jobs/image-generation/estimate-cost` - Estimate image generation cost

6. **🔍 Embeddings (9 endpoints)**
   - `POST /v1/embeddings/generate` - Generate embeddings
   - `POST /v1/embeddings/search` - Search embeddings
   - `GET /v1/embeddings/collections` - Get embedding collections
   - `POST /v1/embeddings/collections` - Create embedding collection
   - `GET /v1/embeddings/collections/{collectionId}` - Get collection embeddings
   - `DELETE /v1/embeddings/collections/{collectionId}` - Delete collection
   - `GET /v1/embeddings/{embeddingId}` - Get embedding by ID
   - `DELETE /v1/embeddings/{embeddingId}` - Delete embedding
   - `GET /v1/embeddings/models/available` - Get available embedding models

### 📋 **Each Endpoint Includes:**

- **Group classification** (auth, users, chats, models, jobs, embeddings)
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

## 🤖 Models

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
      "id": "gpt-4",
      "name": "GPT-4",
      "description": "Most capable GPT model",
      "requiresApiKey": true
    },
    {
      "id": "claude-3-sonnet",
      "name": "Claude 3 Sonnet",
      "description": "Anthropic's balanced model",
      "requiresApiKey": true
    }
  ]
}
```

### GET /v1/models/user
**Group:** models
**URL:** `http://localhost:8000/v1/models/user`

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
      "name": "My GPT-4 Config",
      "provider": "openai",
      "model": "gpt-4",
      "api_key": "sk-...",
      "system_prompt": "You are a helpful assistant",
      "temperature": 0.7,
      "max_tokens": 1000,
      "is_default": true,
      "created_at": "2023-10-27T10:00:00.000Z",
      "updated_at": "2023-10-27T10:00:00.000Z"
    }
  ]
}
```

### POST /v1/models/user
**Group:** models
**URL:** `http://localhost:8000/v1/models/user`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
```json
{
  "name": "My GPT-4 Config",
  "provider": "openai",
  "model": "gpt-4",
  "apiKey": "sk-...",
  "systemPrompt": "You are a helpful assistant",
  "temperature": 0.7,
  "maxTokens": 1000,
  "isDefault": true
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "name": "My GPT-4 Config",
    "provider": "openai",
    "model": "gpt-4",
    "api_key": "sk-...",
    "system_prompt": "You are a helpful assistant",
    "temperature": 0.7,
    "max_tokens": 1000,
    "is_default": true,
    "created_at": "2023-10-27T10:00:00.000Z",
    "updated_at": "2023-10-27T10:00:00.000Z"
  }
}
```

### PUT /v1/models/user/{configId}
**Group:** models
**URL:** `http://localhost:8000/v1/models/user/uuid-here`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
```json
{
  "name": "Updated GPT-4 Config",
  "temperature": 0.8,
  "maxTokens": 1500
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "name": "Updated GPT-4 Config",
    "provider": "openai",
    "model": "gpt-4",
    "temperature": 0.8,
    "max_tokens": 1500,
    "updated_at": "2023-10-27T11:00:00.000Z"
  }
}
```

### DELETE /v1/models/user/{configId}
**Group:** models
**URL:** `http://localhost:8000/v1/models/user/uuid-here`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Model configuration deleted successfully"
  }
}
```

### POST /v1/models/test
**Group:** models
**URL:** `http://localhost:8000/v1/models/test`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
```json
{
  "provider": "openai",
  "model": "gpt-4",
  "apiKey": "sk-...",
  "systemPrompt": "You are a helpful assistant",
  "testPrompt": "Say hello",
  "temperature": 0.7,
  "maxTokens": 100
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "testResult": "Hello! How can I assist you today?",
    "responseTime": 1234,
    "tokenCount": 8
  }
}
```

### GET /v1/models/providers
**Group:** models
**URL:** `http://localhost:8000/v1/models/providers`

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
      "id": "openai",
      "name": "OpenAI",
      "models": [
        {
          "id": "gpt-4",
          "name": "GPT-4",
          "description": "Most capable GPT model",
          "requiresApiKey": true
        }
      ]
    },
    {
      "id": "anthropic",
      "name": "Anthropic",
      "models": [
        {
          "id": "claude-3-sonnet",
          "name": "Claude 3 Sonnet",
          "description": "Balanced model for most tasks",
          "requiresApiKey": true
        }
      ]
    }
  ]
}
```

### GET /v1/models/providers/{provider}/models
**Group:** models
**URL:** `http://localhost:8000/v1/models/providers/openai/models`

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
      "id": "gpt-4",
      "name": "GPT-4",
      "description": "Most capable GPT model",
      "requiresApiKey": true
    },
    {
      "id": "gpt-3.5-turbo",
      "name": "GPT-3.5 Turbo",
      "description": "Fast and efficient model",
      "requiresApiKey": true
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

## 🔍 Embeddings

### POST /v1/embeddings/generate
**Group:** embeddings
**URL:** `http://localhost:8000/v1/embeddings/generate`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
```json
{
  "text": "This is a sample text to generate embeddings for",
  "model": "text-embedding-3-large",
  "collectionId": "uuid-optional",
  "apiKey": "sk-...",
  "metadata": {
    "source": "user_input",
    "category": "general"
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
    "collection_id": "uuid",
    "text": "This is a sample text to generate embeddings for",
    "model": "text-embedding-3-large",
    "embedding": [0.1, 0.2, 0.3, "...1536 dimensions"],
    "metadata": {
      "source": "user_input",
      "category": "general"
    },
    "token_count": 12,
    "created_at": "2023-10-27T10:00:00.000Z"
  }
}
```

### POST /v1/embeddings/search
**Group:** embeddings
**URL:** `http://localhost:8000/v1/embeddings/search`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
```json
{
  "query": "Find similar text about machine learning",
  "model": "text-embedding-3-large",
  "collectionId": "uuid-optional",
  "apiKey": "sk-...",
  "limit": 10,
  "threshold": 0.8
}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "text": "Machine learning is a subset of artificial intelligence",
      "metadata": {
        "source": "document",
        "category": "ai"
      },
      "similarity": 0.95,
      "created_at": "2023-10-27T09:00:00.000Z"
    },
    {
      "id": "uuid",
      "text": "Deep learning algorithms are powerful tools",
      "metadata": {
        "source": "article",
        "category": "tech"
      },
      "similarity": 0.87,
      "created_at": "2023-10-27T08:00:00.000Z"
    }
  ]
}
```

### GET /v1/embeddings/collections
**Group:** embeddings
**URL:** `http://localhost:8000/v1/embeddings/collections`

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
      "name": "My Documents",
      "description": "Collection of my personal documents",
      "metadata": {
        "category": "personal"
      },
      "embedding_count": 25,
      "created_at": "2023-10-27T10:00:00.000Z",
      "updated_at": "2023-10-27T10:00:00.000Z"
    }
  ]
}
```

### POST /v1/embeddings/collections
**Group:** embeddings
**URL:** `http://localhost:8000/v1/embeddings/collections`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
```json
{
  "name": "Research Papers",
  "description": "Collection of AI research papers",
  "metadata": {
    "category": "research",
    "topic": "artificial_intelligence"
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
    "name": "Research Papers",
    "description": "Collection of AI research papers",
    "metadata": {
      "category": "research",
      "topic": "artificial_intelligence"
    },
    "embedding_count": 0,
    "created_at": "2023-10-27T10:00:00.000Z",
    "updated_at": "2023-10-27T10:00:00.000Z"
  }
}
```

### GET /v1/embeddings/collections/{collectionId}
**Group:** embeddings
**URL:** `http://localhost:8000/v1/embeddings/collections/uuid-here?limit=10&offset=0`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
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
      "collection_id": "uuid",
      "text": "Sample text in collection",
      "model": "text-embedding-3-large",
      "embedding": [0.1, 0.2, 0.3, "..."],
      "metadata": {
        "source": "document"
      },
      "token_count": 5,
      "created_at": "2023-10-27T10:00:00.000Z"
    }
  ]
}
```

### DELETE /v1/embeddings/collections/{collectionId}
**Group:** embeddings
**URL:** `http://localhost:8000/v1/embeddings/collections/uuid-here`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Collection and all embeddings deleted successfully"
  }
}
```

### GET /v1/embeddings/{embeddingId}
**Group:** embeddings
**URL:** `http://localhost:8000/v1/embeddings/uuid-here`

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
    "collection_id": "uuid",
    "text": "Sample embedding text",
    "model": "text-embedding-3-large",
    "embedding": [0.1, 0.2, 0.3, "...1536 dimensions"],
    "metadata": {
      "source": "user_input"
    },
    "token_count": 4,
    "created_at": "2023-10-27T10:00:00.000Z"
  }
}
```

### DELETE /v1/embeddings/{embeddingId}
**Group:** embeddings
**URL:** `http://localhost:8000/v1/embeddings/uuid-here`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Embedding deleted successfully"
  }
}
```

### GET /v1/embeddings/models/available
**Group:** embeddings
**URL:** `http://localhost:8000/v1/embeddings/models/available`

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
      "name": "text-embedding-3-large",
      "provider": "openai",
      "dimensions": 3072,
      "maxTokens": 8191,
      "pricing": 0.00013
    },
    {
      "name": "text-embedding-3-small",
      "provider": "openai",
      "dimensions": 1536,
      "maxTokens": 8191,
      "pricing": 0.00002
    },
    {
      "name": "text-embedding-ada-002",
      "provider": "openai",
      "dimensions": 1536,
      "maxTokens": 8191,
      "pricing": 0.0001
    }
  ]
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
