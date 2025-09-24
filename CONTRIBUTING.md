# Contributing to PocketLLM

Thank you for your interest in contributing to PocketLLM! This document provides guidelines and best practices for contributing to the project.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Community Guidelines](#community-guidelines)

## 🚀 Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/pocketllm.git
   ```
3. Create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 🛠️ Development Setup

### Flutter Frontend

1. Install Flutter SDK (version 3.0 or later)
2. Install dependencies:
   ```bash
   cd pocketllm
   flutter pub get
   ```
3. Verify setup:
   ```bash
   flutter doctor
   ```

### Backend (NestJS)

1. Install Node.js (version 18 or later)
2. Install dependencies:
   ```bash
   cd pocketllm-backend
   npm install
   ```
3. Set up environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

## 🎨 Code Style

### Flutter/Dart

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use `flutter format` to format code:
  ```bash
  flutter format .
  ```
- Keep functions small and focused
- Use meaningful variable and function names
- Add comments for complex logic

### TypeScript (Backend)

- Follow the [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
- Use Prettier for formatting:
  ```bash
  npm run format
  ```
- Use ESLint for linting:
  ```bash
  npm run lint
  ```

## 🔧 Making Changes

1. Make your changes in your feature branch
2. Follow the existing code style and patterns
3. Add or update tests as necessary
4. Update documentation if needed
5. Run all tests to ensure nothing is broken

### Git Commit Guidelines

- Use clear, descriptive commit messages
- Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification
- Example formats:
  - `feat: add new model provider integration`
  - `fix: resolve chat history loading issue`
  - `docs: update API documentation`
  - `test: add unit tests for chat service`

## 🧪 Testing

### Flutter Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/chat_service_test.dart
```

### Backend Tests

```bash
# Run all tests
npm run test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:cov
```

### Writing Tests

- Write unit tests for business logic
- Write widget tests for UI components
- Write integration tests for critical user flows
- Aim for high test coverage (80%+)

## 📚 Documentation

### Code Documentation

- Document all public APIs with clear comments
- Use Dart doc comments for Flutter code:
  ```dart
  /// A service that manages chat functionality.
  ///
  /// This service handles creating, updating, and deleting chats,
  /// as well as sending and receiving messages.
  class ChatService {
    // ...
  }
  ```
- Use JSDoc comments for TypeScript code:
  ```typescript
  /**
   * Creates a new chat session for a user.
   * @param userId - The ID of the user creating the chat
   * @param title - The title of the new chat
   * @returns The created chat object
   */
  ```

### Project Documentation

- Update README.md for major features
- Add new documentation files to the docs/ directory
- Keep the AGENTS.md file updated for AI agent guidance

## 📥 Pull Request Process

1. Ensure all tests pass
2. Update documentation as needed
3. Squash related commits for clarity
4. Submit pull request with clear description:
   - What changed and why
   - How to test the changes
   - Any breaking changes
5. Respond to feedback promptly
6. Wait for review and approval

### Pull Request Template

```markdown
## Description

Brief description of the changes and why they were made.

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Performance improvement

## Testing

- [ ] Tests pass locally
- [ ] Added new tests
- [ ] Updated existing tests

## Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings
```

## 👥 Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help others learn and grow
- Focus on the code, not the person

### Communication

- Use clear, professional language
- Explain technical concepts accessibly
- Be patient with newcomers
- Keep discussions focused and productive

## 🆘 Getting Help

If you need help:

1. Check existing issues and documentation
2. Join our community discussions
3. Ask questions in a clear, detailed manner
4. Provide relevant code snippets or error messages

## 🙏 Thank You!

Your contributions make PocketLLM better for everyone. Thank you for taking the time to contribute!