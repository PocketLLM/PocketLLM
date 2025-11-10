## 🎯 AGENT INSTRUCTIONS

### For AI Agents Working on This Project

**ALWAYS follow these instructions:**

1. **SETUP FLUTTER ENVIRONMENT FIRST**: Before starting any task, ensure the Flutter development environment is properly set up:
   ```bash
   # Run the setup script
   ./setup.sh
   ```

2. **RUN FLUTTER TESTS BEFORE SUBMITTING**: Always run Flutter tests before submitting any changes:
   ```bash
   flutter test
   ```

3. **ENSURE PRODUCTION-READY CODE**: All code must be production-ready:
   - Follow Dart/TypeScript best practices
   - Include proper error handling
   - Add comprehensive logging
   - Write unit tests for all new functionality
   - Ensure code passes all linting rules

4. **UPDATE DOCUMENTATION**: Always update relevant documentation when making changes:
   - Update AGENTS.md with any structural changes
   - Update README.md for major features
   - Update API documentation for endpoint changes
   - Add code comments for complex logic

5. **BUILD VERIFICATION**: Run build verification before submitting:
   ```bash
   # Flutter verification
   flutter analyze
   flutter test
   flutter build apk --debug
   
   # Backend verification (if applicable)
   npm test
   npm run build
   ```

6. **MAINTAIN CLEAN CODE**: Keep the codebase clean and maintainable:
   - Follow existing code patterns
   - Use meaningful variable and function names
   - Keep functions small and focused
   - Add proper type annotations
   - Remove unused code and dependencies

7. **SECURITY CONSIDERATIONS**: Always consider security:
   - Validate all user inputs
   - Use secure storage for sensitive data
   - Follow authentication and authorization best practices
   - Keep dependencies updated

8. **PUBSPEC DEPENDENCY STYLE**: When adding new dependencies to `pubspec.yaml`,
   list only the package name followed by a colon (no explicit version
   constraints). This keeps the project aligned with the team's dependency
   management approach.

**Onboarding Flow Notes**

- Render onboarding content directly on the page—avoid wrapping steps in card-like
  containers—and preserve smooth animations for screen transitions and progress
  indicators.
- Do not require provider/API key setup during onboarding; clearly communicate
  that configuration can happen later in Settings.
- The gated onboarding flow now relies on `/v1/auth/validate-invite-code`,
  `/v1/waitlist`, and `/v1/referral/*` endpoints—never short-circuit these checks
  with local state.

**Remember**: The goal is to maintain a high-quality, production-ready codebase that is well-documented and thoroughly tested.

### Chat Architecture Notes

- `ChatHistoryService` now syncs directly with the backend `/v1/chats` APIs. Avoid writing new persistence code that touches `SharedPreferences` for conversation data.
- `ChatInterface` composes its message list and composer through the helper parts in `chat_interface_input.dart`; prefer extending those modules instead of adding more inline UI to `chat_interface.dart`.
- All chat messages must flow through the backend so they remain available across devices—use `RemoteChatService` for new frontend/chat features.
```
