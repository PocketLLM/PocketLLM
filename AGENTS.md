

I'll analyze your current AGENTS.md file and enhance it with best practices based on my research. Here's an improved version:

```markdown
# AGENTS.md - PocketLLM Development Guide

This document provides comprehensive guidance for AI agents (like OpenAI Codex) working with the PocketLLM codebase. It explains the project structure, development environment setup, build processes, and key workflows.

## 📁 Project Structure Overview

PocketLLM is a cross-platform AI chat application with a Flutter frontend and NestJS backend:

```
pocketllm/
├── lib/                    # Flutter frontend source code
│   ├── component/          # UI components and screens
│   ├── services/           # Business logic and state management
│   ├── models/             # Data models
│   ├── pages/              # Main application pages
│   └── main.dart           # Application entry point
├── pocketllm-backend/      # NestJS backend
│   ├── src/                # Backend source code
│   │   ├── api/            # API versioning and schemas
│   │   ├── auth/           # Authentication module
│   │   ├── users/          # User management
│   │   ├── chats/          # Chat functionality
│   │   ├── jobs/           # Background jobs
│   │   ├── providers/      # AI provider integrations
│   │   └── common/         # Shared utilities
│   ├── db/                 # Database migrations
│   └── POSTMAN_API_GUIDE.md # API documentation
├── docs/                   # Documentation files
├── test/                   # Test files
├── android/                # Android-specific files
├── ios/                    # iOS-specific files
├── web/                    # Web-specific files
└── README.md               # Project overview
```

## 🛠️ Development Environment Setup

### Flutter Development Environment in Codex

#### Setup Script
Create a `setup.sh` script in the project root for Codex environment:

```bash
#!/bin/bash
set -euxo pipefail

# Environment variables
WORKSPACE="${WORKSPACE:-/workspace}"
PROJECT_DIR="$(grep -Rl --include=pubspec.yaml -e 'sdk:[[:space:]]*flutter' "$WORKSPACE" | head -n1 | xargs dirname)"
APP_NAME="$(basename "$PROJECT_DIR")"

# 1. Install Flutter SDK
FLUTTER_VERSION="3.32.2"
FLUTTER_SDK_INSTALL_DIR="$HOME/flutter"
FLUTTER_TARBALL_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

if [[ ! -d "$FLUTTER_SDK_INSTALL_DIR" ]]; then
    echo "📦 Downloading Flutter $FLUTTER_VERSION..."
    curl -sL "$FLUTTER_TARBALL_URL" | tar -xJ -C "$HOME"
else
    echo "⚠️ Flutter cache found at $FLUTTER_SDK_INSTALL_DIR"
fi

# Fix git ownership issues
git config --global --add safe.directory "$FLUTTER_SDK_INSTALL_DIR"

# 2. Add Flutter and Dart to PATH
export PATH="$FLUTTER_SDK_INSTALL_DIR/bin:$PATH"
sudo ln -sf "$FLUTTER_SDK_INSTALL_DIR/bin/flutter" /usr/local/bin/flutter
sudo ln -sf "$FLUTTER_SDK_INSTALL_DIR/bin/dart" /usr/local/bin/dart

# Verify installation
flutter --version
dart --version

# 3. Pre-cache Flutter components
flutter precache --linux --no-web --no-ios --no-android --no-windows --no-macos

# 4. Install Android SDK (required for Flutter Android builds)
ANDROID_SDK_ROOT="/usr/lib/android-sdk"
if [[ ! -d "$ANDROID_SDK_ROOT" ]]; then
    echo "📦 Installing Android SDK..."
    apt-get update && apt-get install -y openjdk-17-jdk
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11095708_latest.zip
    mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    unzip -q commandlinetools-linux-11095708_latest.zip -d "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    rm commandlinetools-linux-11095708_latest.zip
    
    # Set Android environment variables
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"
    
    # Accept Android licenses
    echo "y" | flutter doctor --android-licenses
fi

# 5. Install project dependencies
cd "$PROJECT_DIR"
flutter pub get

# 6. Generate localization files
flutter gen-l10n

# 7. Run build_runner if needed
if grep -R --include='*.dart' -e 'part .*\.g\.dart' lib >/dev/null; then
    dart run build_runner build --delete-conflicting-outputs --build-filter="lib/**"
fi

echo "✅ Setup completed for $APP_NAME"
```

### Flutter Development Environment (Windows)

1. **Install Prerequisites:**
   - Git for Windows
   - Android Studio
   - Visual Studio Code with Flutter extension
   - OpenJDK 11 or later

2. **Install Flutter SDK:**
   ```bash
   # Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
   # Extract to C:\src\flutter
   # Add C:\src\flutter\bin to your PATH environment variable
   ```

3. **Verify Installation:**
   ```bash
   flutter doctor
   ```

4. **Set up Android Development:**
   - Open Android Studio
   - Install Android SDK tools
   - Configure Android emulator or connect physical device

5. **Install Project Dependencies:**
   ```bash
   cd pocketllm
   flutter pub get
   ```

### Backend Development Environment

1. **Install Node.js:**
   - Download and install Node.js 18+ from https://nodejs.org/

2. **Install Dependencies:**
   ```bash
   cd pocketllm-backend
   npm install
   ```

3. **Configure Environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

## 🚀 Build and Run Commands

### Flutter Application

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d android
flutter run -d chrome

# Build for release
flutter build apk
flutter build web
```

### Backend Server

```bash
# Development mode with hot reload
npm run start:dev

# Production build
npm run build
npm run start:prod
```

## 🧪 Testing

### Flutter Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/model_state_test.dart
```

### Backend Tests

```bash
# Run unit tests
npm run test

# Run tests with coverage
npm run test:cov
```

## 📖 Codebase Navigation

### Key Flutter Components

- [lib/main.dart](lib/main.dart) - Application entry point
- [lib/component/chat_interface.dart](lib/component/chat_interface.dart) - Main chat UI
- [lib/services/chat_service.dart](lib/services/chat_service.dart) - Chat business logic
- [lib/services/model_service.dart](lib/services/model_service.dart) - Model management
- [lib/component/model_selector.dart](lib/component/model_selector.dart) - Model selection UI

### Key Backend Modules

- [pocketllm-backend/src/main.ts](pocketllm-backend/src/main.ts) - Server entry point
- [pocketllm-backend/src/api/v1/](pocketllm-backend/src/api/v1/) - API endpoints
- [pocketllm-backend/src/auth/](pocketllm-backend/src/auth/) - Authentication
- [pocketllm-backend/src/chats/](pocketllm-backend/src/chats/) - Chat functionality
- [pocketllm-backend/src/providers/](pocketllm-backend/src/providers/) - AI provider integrations

## 🔌 API Integration

The backend provides a RESTful API documented in [POSTMAN_API_GUIDE.md](pocketllm-backend/POSTMAN_API_GUIDE.md).

Key endpoints:
- Authentication: `/v1/auth/signup`, `/v1/auth/signin`
- User profiles: `/v1/users/profile`
- Chats: `/v1/chats`, `/v1/chats/{chatId}/messages`
- Jobs: `/v1/jobs/image-generation`

All API responses follow a standardized format:
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

## 🗃️ Database Schema

The project uses Supabase (PostgreSQL) with the following key tables:
- `profiles` - User profile information
- `model_configs` - AI model configurations
- `chats` - Chat sessions
- `messages` - Individual chat messages
- `jobs` - Background tasks (image generation)

See [initial_schema.sql](pocketllm-backend/db/migrations/initial_schema.sql) for complete schema.

## 🎯 Development Workflows

### Adding a New Feature

1. Create a new branch: `git checkout -b feature/new-feature-name`
2. Implement the feature following existing patterns
3. Write tests for new functionality
4. Update documentation if needed
5. Run all tests: `flutter test` and `npm run test`
6. Create a pull request

### Fixing a Bug

1. Create a new branch: `git checkout -b fix/bug-description`
2. Identify the root cause
3. Implement the fix
4. Add tests to prevent regression
5. Verify the fix works
6. Create a pull request

### Adding a New AI Provider

1. **Review Documentation**: First thoroughly read the provider documentation in `docs/` directory:
   - [docs/ollama-guide.md](docs/ollama-guide.md)
   - [docs/openrouter-guide.md](docs/openrouter-guide.md)

2. **Backend Implementation**:
   - Create a new service in [pocketllm-backend/src/providers/](pocketllm-backend/src/providers/)
   - Follow the pattern of existing providers (openai.service.ts, anthropic.service.ts)
   - Add provider to [pocketllm-backend/src/providers/providers.module.ts](pocketllm-backend/src/providers/providers.module.ts)

3. **Database Updates**:
   - Create migration for provider configuration storage
   - Ensure API keys are hashed before storage
   - Add provider to database schema if needed

4. **Frontend Implementation**:
   - Update model selection in [lib/component/model_selector.dart](lib/component/model_selector.dart)
   - Add provider to settings page for API key configuration
   - Implement model details bottom sheet when a model is clicked

5. **Testing**:
   - Write unit tests for new provider service
   - Test integration with existing chat functionality
   - Verify model listing and selection works correctly

## 📚 Documentation Updates

### Required Documentation Maintenance

When making changes to the codebase:

1. **Update AGENTS.md**: Keep this file current with any structural changes
2. **Update README.md**: For major features or changes to project overview
3. **Update POSTMAN_API_GUIDE.md**: For any API changes or new endpoints
4. **Update Provider Guides**: If adding or modifying provider implementations
5. **Update Code Comments**: Ensure all new code is properly documented

### Documentation Standards

- **Dart**: Use `///` for public API documentation
- **TypeScript**: Use JSDoc comments for functions and classes
- **SQL**: Comment complex queries and schema changes
- **Markdown**: Follow existing formatting and structure

## 🔧 Build Verification

### Pre-commit Checklist

Before committing changes, run these verification steps:

```bash
#!/bin/bash
echo "🔍 Running build verification..."

# Flutter checks
echo "📱 Checking Flutter project..."
cd pocketllm
flutter analyze
flutter test
flutter build apk --debug

# Backend checks
echo "🔧 Checking backend..."
cd ../pocketllm-backend
npm install
npm test

echo "✅ Build verification complete!"
```

### Flutter Build Verification

```bash
# 1. Analyze code for issues
flutter analyze

# 2. Run tests
flutter test

# 3. Check formatting
dart format --set-exit-if-changed .

# 4. Build APK (for Android)
flutter build apk --debug

# 5. Check for dependency issues
flutter pub deps
```

### Backend Build Verification

```bash
# 1. Install dependencies
npm install

# 2. Run tests
npm test

# 3. Check TypeScript compilation
npm run build

# 4. Lint code
npm run lint
```

## 🔌 Provider Implementation Guide

### Ollama Provider Implementation

1. **Review Documentation**: Read [docs/ollama-guide.md](docs/ollama-guide.md) thoroughly

2. **Backend Implementation**:
   ```typescript
   // Create pocketllm-backend/src/providers/ollama.service.ts
   // Implement chat completion and model listing endpoints
   // Follow pattern from existing providers
   ```

3. **Database Schema**:
   ```sql
   -- Add to migrations
   ALTER TABLE model_configs 
   ADD COLUMN provider_type VARCHAR(32) DEFAULT 'openai';
   
   -- Create table for Ollama-specific configurations
   CREATE TABLE ollama_configs (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
     base_url VARCHAR(255) NOT NULL,
     api_key_hash VARCHAR(255) NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

4. **Frontend Implementation**:
   - Add Ollama provider to settings page
   - Implement API key configuration with secure storage
   - Update model selector to fetch models from Ollama

### OpenRouter Provider Implementation

1. **Review Documentation**: Read [docs/openrouter-guide.md](docs/openrouter-guide.md) thoroughly

2. **Backend Implementation**:
   ```typescript
   // Create pocketllm-backend/src/providers/openrouter.service.ts
   // Implement chat completion and model listing endpoints
   // Follow pattern from existing providers
   ```

3. **Database Schema**:
   ```sql
   -- Create table for OpenRouter-specific configurations
   CREATE TABLE openrouter_configs (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
     api_key_hash VARCHAR(255) NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

4. **Frontend Implementation**:
   - Add OpenRouter provider to settings page
   - Implement API key configuration with secure storage
   - Update model selector to fetch models from OpenRouter

## 🔧 Troubleshooting

### Common Flutter Issues

- **"No connected devices"**: Ensure emulator is running or device is connected with USB debugging enabled
- **Build failures**: Run `flutter clean` and `flutter pub get`
- **Dependency issues**: Check version compatibility in [pubspec.yaml](pubspec.yaml)

### Common Backend Issues

- **"Module not found"**: Run `npm install` to install missing dependencies
- **Database connection errors**: Verify .env configuration
- **Port conflicts**: Change PORT in .env file

## 🤝 Contributing Guidelines

1. Follow the existing code style and patterns
2. Write clear, descriptive commit messages
3. Include tests for new functionality
4. Update documentation when making changes
5. Ensure all tests pass before submitting pull requests

## 📞 Support

For questions about the codebase, refer to:
- Project maintainers listed in [README.md](README.md)
- Existing issues on GitHub
- Code comments and documentation
```

This enhanced AGENTS.md file includes:

1. **Detailed setup script** for Flutter in Codex environments
2. **Specific implementation guides** for Ollama and OpenRouter providers
3. **Clear documentation maintenance requirements**
4. **Build verification steps** for both frontend and backend
5. **Database schema examples** for new providers
6. **Pre-commit checklist** to ensure code quality

The file now provides more comprehensive guidance for AI agents working on your PocketLLM project, especially for implementing the new providers you mentioned.