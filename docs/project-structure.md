# PocketLLM Project Structure

This document provides a comprehensive overview of the PocketLLM project structure, explaining the purpose of each directory and key files.

## 📁 Root Directory Structure

```
pocketllm/
├── android/                # Android-specific configuration and build files
├── assets/                 # Application assets (images, animations, etc.)
├── docs/                   # Project documentation
├── ios/                    # iOS-specific configuration and build files
├── lib/                    # Flutter application source code
├── linux/                  # Linux-specific build files
├── macos/                  # macOS-specific build files
├── pocketllm-backend/      # NestJS backend application
├── test/                   # Automated tests
├── web/                    # Web-specific configuration
├── windows/                # Windows-specific build files
├── AGENTS.md              # AI agent development guide
├── CONTRIBUTING.md        # Contribution guidelines
├── README.md              # Project overview
└── pubspec.yaml           # Flutter project configuration
```

## 📱 Flutter Frontend (lib/)

The Flutter frontend is organized into several key directories:

```
lib/
├── component/             # UI components and screens
│   ├── appbar/            # Custom app bar components
│   ├── onboarding_screens/ # Onboarding flow screens
│   └── ...                # Other UI components
├── models/                # Data models and entities
├── pages/                 # Main application pages
│   ├── auth/              # Authentication flow pages
│   ├── settings/          # Settings pages
│   └── ...                # Other main pages
├── services/              # Business logic and state management
├── theme/                 # Design tokens and shared theme definitions
├── widgets/               # Reusable widgets
└── main.dart              # Application entry point
```

### Component Directory

The [component/](../lib/component/) directory contains UI components and screens:

- [chat_interface.dart](../lib/component/chat_interface.dart) - Main chat interface with message display and input
- [model_selector.dart](../lib/component/model_selector.dart) - Model selection UI with provider integration
- [home_screen.dart](../lib/component/home_screen.dart) - Main application screen after login
- [splash_screen.dart](../lib/component/splash_screen.dart) - Initial loading screen
- [sidebar.dart](../lib/component/sidebar.dart) - Navigation sidebar component

### Models Directory

The [models/](../lib/models/) directory contains data models:

- [user_profile.dart](../lib/models/user_profile.dart) - User profile data structure

### Pages Directory

The [pages/](../lib/pages/) directory contains main application pages:

- [auth/](../lib/pages/auth/) - Authentication flow pages
- [settings_page.dart](../lib/pages/settings_page.dart) - Main settings page
- [config_page.dart](../lib/pages/config_page.dart) - Configuration management page

### Services Directory

The [services/](../lib/services/) directory contains business logic and state management:

- [chat_service.dart](../lib/services/chat_service.dart) - Chat functionality and message handling
- [model_service.dart](../lib/services/model_service.dart) - Model management and provider integration
- [auth_state.dart](../lib/services/auth_state.dart) - Authentication state management
- [model_state.dart](../lib/services/model_state.dart) - Model state management
- [secure_storage_service.dart](../lib/services/secure_storage_service.dart) - Secure data storage
- [pocket_llm_service.dart](../lib/services/pocket_llm_service.dart) - Core application service

### Theme Directory

The [theme/](../lib/theme/) directory centralizes design tokens and reusable
palettes:

- [app_colors.dart](../lib/theme/app_colors.dart) - Brand color tokens and
  canonical light/dark/high-contrast schemes used by the theme service

### Widgets Directory

The [widgets/](../lib/widgets/) directory contains reusable UI widgets:

- [clear_text_field.dart](../lib/widgets/clear_text_field.dart) - Text field with clear button

## 🖥️ Backend (pocketllm-backend/)

The backend is built with NestJS and follows a modular architecture:

```
pocketllm-backend/
├── src/                   # Source code
│   ├── api/               # API versioning and schemas
│   ├── auth/              # Authentication module
│   ├── users/             # User management module
│   ├── chats/             # Chat functionality module
│   ├── jobs/              # Background jobs module
│   ├── providers/         # AI provider integrations
│   ├── common/            # Shared utilities and middleware
│   ├── config/            # Configuration management
│   ├── app.module.ts      # Root module
│   └── main.ts            # Application entry point
├── db/                    # Database migrations
├── test/                  # Backend tests
├── POSTMAN_API_GUIDE.md   # API documentation for Postman
└── README.md              # Backend overview
```

### API Directory

The [api/](../pocketllm-backend/src/api/) directory handles API versioning:

- [v1/](../pocketllm-backend/src/api/v1/) - Version 1 of the API
  - [schemas/](../pocketllm-backend/src/api/v1/schemas/) - Zod validation schemas

### Auth Module

The [auth/](../pocketllm-backend/src/auth/) directory handles user authentication:

- [auth.controller.ts](../pocketllm-backend/src/auth/auth.controller.ts) - Authentication endpoints
- [auth.service.ts](../pocketllm-backend/src/auth/auth.service.ts) - Authentication business logic
- [dto/](../pocketllm-backend/src/auth/dto/) - Data transfer objects for authentication

### Users Module

The [users/](../pocketllm-backend/src/users/) directory manages user profiles:

- [users.controller.ts](../pocketllm-backend/src/users/users.controller.ts) - User profile endpoints
- [users.service.ts](../pocketllm-backend/src/users/users.service.ts) - User profile business logic

### Chats Module

The [chats/](../pocketllm-backend/src/chats/) directory handles chat functionality:

- [chats.controller.ts](../pocketllm-backend/src/chats/chats.controller.ts) - Chat endpoints
- [chats.service.ts](../pocketllm-backend/src/chats/chats.service.ts) - Chat business logic

### Jobs Module

The [jobs/](../pocketllm-backend/src/jobs/) directory manages background tasks:

- [jobs.controller.ts](../pocketllm-backend/src/jobs/jobs.controller.ts) - Job endpoints
- [jobs.service.ts](../pocketllm-backend/src/jobs/jobs.service.ts) - Job business logic

### Providers Module

The [providers/](../pocketllm-backend/src/providers/) directory integrates with AI providers:

- [openai.service.ts](../pocketllm-backend/src/providers/openai.service.ts) - OpenAI integration
- [anthropic.service.ts](../pocketllm-backend/src/providers/anthropic.service.ts) - Anthropic integration
- [ollama.service.ts](../pocketllm-backend/src/providers/ollama.service.ts) - Ollama integration
- [image-router.service.ts](../pocketllm-backend/src/providers/image-router.service.ts) - Image generation routing

### Common Module

The [common/](../pocketllm-backend/src/common/) directory contains shared utilities:

- [services/](../pocketllm-backend/src/common/services/) - Shared services (Supabase, encryption)
- [interceptors/](../pocketllm-backend/src/common/interceptors/) - Response formatting
- [filters/](../pocketllm-backend/src/common/filters/) - Exception handling
- [pipes/](../pocketllm-backend/src/common/pipes/) - Validation pipes
- [middleware/](../pocketllm-backend/src/common/middleware/) - Request middleware

### Config Module

The [config/](../pocketllm-backend/src/config/) directory handles application configuration:

- [configuration.ts](../pocketllm-backend/src/config/configuration.ts) - Configuration definition
- [validation.ts](../pocketllm-backend/src/config/validation.ts) - Configuration validation

## 🧪 Testing (test/)

The [test/](../test/) directory contains automated tests:

```
test/
├── component/             # Component tests
├── services/              # Service tests
└── widget_test.dart       # Widget tests
```

## 📚 Documentation (docs/)

The [docs/](../docs/) directory contains project documentation:

- [backend-guide.md](backend-guide.md) - Backend development guide
- [db-guide.md](db-guide.md) - Database guide
- [imagerouter.md](imagerouter.md) - Image router documentation
- [ollama-guide.md](ollama-guide.md) - Ollama integration guide
- [openrouter-guide.md](openrouter-guide.md) - OpenRouter integration guide
- [flutter-setup-guide.md](flutter-setup-guide.md) - Flutter development setup guide
- [api-documentation.md](api-documentation.md) - Comprehensive API documentation
- [project-structure.md](project-structure.md) - This document

## 📱 Platform-Specific Directories

### Android (android/)

Contains Android-specific configuration and build files:

- [app/build.gradle.kts](../android/app/build.gradle.kts) - Android app build configuration
- [src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) - Android manifest

### iOS (ios/)

Contains iOS-specific configuration and build files:

- [Runner.xcodeproj](../ios/Runner.xcodeproj) - Xcode project file
- [Runner/Info.plist](../ios/Runner/Info.plist) - iOS app configuration

### Web (web/)

Contains web-specific configuration:

- [index.html](../web/index.html) - Web app entry point
- [manifest.json](../web/manifest.json) - Web app manifest

### Desktop (linux/, macos/, windows/)

Contain platform-specific build files for desktop deployment.

## ⚙️ Configuration Files

### Flutter Configuration

- [pubspec.yaml](../pubspec.yaml) - Flutter project dependencies and configuration
- [analysis_options.yaml](../analysis_options.yaml) - Dart code analysis options
- [flutter_launcher_icons.yaml](../flutter_launcher_icons.yaml) - App icon configuration

### Backend Configuration

- [package.json](../pocketllm-backend/package.json) - Node.js dependencies and scripts
- [tsconfig.json](../pocketllm-backend/tsconfig.json) - TypeScript configuration
- [.env.example](../pocketllm-backend/.env.example) - Environment variable template

## 🎯 Key Entry Points

### Frontend

- [lib/main.dart](../lib/main.dart) - Main application entry point
- [lib/component/home_screen.dart](../lib/component/home_screen.dart) - Main application screen

### Backend

- [pocketllm-backend/src/main.ts](../pocketllm-backend/src/main.ts) - Server entry point
- [pocketllm-backend/src/app.module.ts](../pocketllm-backend/src/app.module.ts) - Root module

## 🔄 Data Flow

1. **User Interface**: Flutter components in [lib/component/](../lib/component/)
2. **State Management**: Services in [lib/services/](../lib/services/)
3. **API Communication**: HTTP requests to backend endpoints
4. **Backend Processing**: NestJS controllers and services
5. **Data Storage**: Supabase database operations
6. **AI Integration**: Provider services in [pocketllm-backend/src/providers/](../pocketllm-backend/src/providers/)

## 🛠️ Development Workflows

### Adding New Features

1. **Frontend**: Create new components in [lib/component/](../lib/component/) or modify existing ones
2. **State Management**: Add or update services in [lib/services/](../lib/services/)
3. **Backend**: Create new modules in [pocketllm-backend/src/](../pocketllm-backend/src/)
4. **API**: Define new endpoints in the appropriate controller
5. **Database**: Update schema in [pocketllm-backend/db/migrations/](../pocketllm-backend/db/migrations/)
6. **Documentation**: Update relevant documentation files

### Testing

1. **Unit Tests**: Add tests in [test/](../test/) directory
2. **Integration Tests**: Test API endpoints
3. **UI Tests**: Test Flutter components and widgets

## 📈 Performance Considerations

- **Frontend**: Optimize widget rebuilds and state management
- **Backend**: Implement efficient database queries and caching
- **Network**: Minimize API calls and implement pagination
- **Storage**: Use secure storage for sensitive data

This document provides a comprehensive overview of the PocketLLM project structure. For more detailed information about specific components or modules, refer to the individual documentation files in the [docs/](../docs/) directory.