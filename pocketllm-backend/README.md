# PocketLLM NestJS Backend

This is the **migrated NestJS backend** for PocketLLM, a chat application that integrates with multiple LLM providers (OpenAI, Anthropic, Ollama) and includes features like chat orchestration and image generation.

## 🚀 Migration Complete

This backend has been **successfully migrated from Fastify to NestJS** while maintaining:
- ✅ All existing functionality and API contracts
- ✅ Zod schema validation (as requested)
- ✅ Original folder structure with `api/v1` organization
- ✅ Supabase integration
- ✅ All external service providers (OpenAI, Anthropic, Ollama, ImageRouter)
- ✅ Standardized JSON response format
- ✅ Comprehensive error handling
- ✅ Swagger/OpenAPI documentation

## 📁 Project Structure

```
src/
├── main.ts                     # Application entry point
├── app.module.ts              # Root module
├── api/                       # API organization (as requested)
│   └── v1/
│       ├── v1.module.ts       # V1 API module
│       └── schemas/           # Zod validation schemas
│           ├── auth.schemas.ts
│           ├── users.schemas.ts
│           ├── chats.schemas.ts
│           └── jobs.schemas.ts
├── auth/                      # Authentication module
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── auth.module.ts
│   └── dto/                   # Legacy DTOs (kept for reference)
├── users/                     # User/Profile management
├── chats/                     # Chat functionality
├── jobs/                      # Background jobs (image generation)
├── providers/                 # External service integrations
│   ├── openai.service.ts
│   ├── anthropic.service.ts
│   ├── ollama.service.ts
│   ├── openrouter.service.ts
│   └── image-router.service.ts
├── provider-configs/          # Provider credential management APIs
├── models/                    # User-selectable model catalog APIs
├── common/                    # Shared utilities
│   ├── services/              # Supabase, encryption services
│   ├── interceptors/          # Response formatting
│   ├── filters/               # Exception handling
│   ├── pipes/                 # Zod validation pipes
│   └── middleware/            # Request ID middleware
└── config/                    # Configuration management
```

## 🛠️ Technology Stack

- **Runtime**: Node.js (migrated from Deno)
- **Framework**: NestJS (latest version)
- **Validation**: Zod schemas (as requested)
- **Database**: Supabase
- **Documentation**: Swagger/OpenAPI
- **External Services**: OpenAI, Anthropic, Ollama, ImageRouter

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Supabase account and project

### Installation

1. **Clone and install dependencies:**
```bash
cd pocketllm-backend
npm install
```

2. **Environment Setup:**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Required Environment Variables:**
```env
# Server Configuration
PORT=8000
NODE_ENV=development
CORS_ORIGIN=*

# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# Encryption
ENCRYPTION_KEY=a_strong_32_byte_secret_key_for_encrypting_api_keys

# Third-party attribution (required by OpenRouter)
OPENROUTER_APP_URL=https://your-app-domain.example
OPENROUTER_APP_NAME=PocketLLM
```

### Running the Application

```bash
# Development mode
npm run start:dev

# Production build
npm run build
npm run start:prod

# Debug mode
npm run start:debug
```

The server will start on `http://localhost:8000` with:
- 📚 API Documentation: `http://localhost:8000/api/docs`
- 🔗 API Base URL: `http://localhost:8000/v1`

## 📖 API Documentation

The API is fully documented with Swagger/OpenAPI. Once the server is running, visit:
`http://localhost:8000/api/docs`

### Key Endpoints

- **Authentication**: `/v1/auth/signup`, `/v1/auth/signin`
- **Users**: `/v1/users/profile`
- **Chats**: `/v1/chats`, `/v1/chats/:id/messages`
- **Providers**: `/v1/providers`, `/v1/providers/activate`, `/v1/providers/:provider`
- **Models**: `/v1/models`, `/v1/models/import`, `/v1/models/:modelId`
- **Jobs**: `/v1/jobs`, `/v1/jobs/image-generation`

### User Profile Endpoints

Profile operations are protected by the shared `SupabaseAuthGuard`, which verifies the Supabase JWT provided in the
`Authorization: Bearer <token>` header and populates `request.user` before controller logic executes. The same guard is reused
by the Chats and Jobs controllers so every user-scoped route enforces authenticated access.

- `GET /v1/users/profile` – Fetches the current user's profile row from the `profiles` table.
- `PUT /v1/users/profile` – Updates the authenticated user's profile data while handling duplicate usernames.
- `DELETE /v1/users/profile` – Permanently removes the Supabase user and cascades the related profile record.

The `UsersService` performs an additional user ID check and returns a `401 Unauthorized` response when the guard is bypassed or
an invalid token is supplied.

## 🔧 Key Features

### 1. **Zod Schema Validation**
All endpoints use Zod schemas for request validation:
```typescript
// Example: Auth signup schema
export const signUpSchema = {
  body: z.object({
    email: z.string().email('Invalid email format.'),
    password: z.string().min(8, 'Password must be at least 8 characters long.'),
  }),
};
```

### 2. **Standardized Response Format**
All API responses follow a consistent format:
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

### 3. **Multi-Provider AI Integration**
- **OpenAI**: GPT chat models
- **Anthropic**: Claude models
- **Ollama**: Local/self-hosted models
- **OpenRouter**: Unified access to community-hosted models
- **ImageRouter**: Image generation

### 5. **Secure Provider Credential Vault**
- Provider API keys are encrypted at rest and stored with salted hashes for tamper detection.
- Users can activate/deactivate providers, rotate credentials, and fetch available models on-demand.
- Dynamic model imports keep the application model selector in sync with active providers.

### 4. **Comprehensive Error Handling**
Global exception filters provide consistent error responses with proper HTTP status codes.

## 🧪 Testing

```bash
# Unit tests
npm run test

# E2E tests
npm run test:e2e

# Test coverage
npm run test:cov
```

## 📦 Building and Deployment

```bash
# Build for production
npm run build

# Start production server
npm run start:prod
```

## 🔒 Security Features

- JWT-based authentication via Supabase
- API key encryption for external services
- Request rate limiting (configurable)
- CORS protection
- Input validation and sanitization

## 🤝 Migration Notes

This backend maintains **100% API compatibility** with the original Fastify implementation while providing:

- Better TypeScript support with NestJS decorators
- Improved dependency injection
- Enhanced testing capabilities
- Automatic API documentation
- Better error handling and logging
- Modular architecture for easier maintenance

All existing frontend applications will continue to work without any changes.

## 📝 License

This project is licensed under the ISC License.
