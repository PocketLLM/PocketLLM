## Setup Script for Flutter and Android Development in Codex

```bash
#!/bin/bash
set -euxo pipefail

# Environment variables
WORKSPACE="${WORKSPACE:-/workspace}"
PROJECT_DIR="$(grep -Rl --include=pubspec.yaml -e 'sdk:[[:space:]]*flutter' "$WORKSPACE" | head -n1 | xargs dirname)"
APP_NAME="$(basename "$PROJECT_DIR")"

echo "🚀 Setting up Flutter and Android development environment for $APP_NAME"

# 1. Install Flutter SDK
FLUTTER_VERSION="3.19.6"
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

**Remember**: The goal is to maintain a high-quality, production-ready codebase that is well-documented and thoroughly tested.
```
