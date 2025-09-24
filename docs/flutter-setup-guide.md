# Flutter Setup Guide for PocketLLM

This guide provides detailed instructions for setting up the Flutter development environment for the PocketLLM project on Windows, including all necessary Android tools and dependencies.

## 📋 Prerequisites

Before starting, ensure your system meets these requirements:
- Windows 10/11 (64-bit)
- At least 8GB RAM (16GB recommended)
- 10GB free disk space
- Internet connection

## 🛠️ Step-by-Step Installation

### 1. Install Git for Windows

1. Download Git from [https://git-scm.com/download/win](https://git-scm.com/download/win)
2. Run the installer with default settings
3. Verify installation:
   ```bash
   git --version
   ```

### 2. Install OpenJDK

1. Download OpenJDK 11 or later from [https://adoptium.net/](https://adoptium.net/)
2. Run the installer and follow the setup wizard
3. Add JAVA_HOME to your environment variables:
   - Open System Properties → Advanced → Environment Variables
   - Add new system variable:
     - Name: `JAVA_HOME`
     - Value: Path to your JDK installation (e.g., `C:\Program Files\Eclipse Adoptium\jdk-11.0.x-hotspot`)
4. Add Java to PATH:
   - Edit the PATH variable
   - Add: `%JAVA_HOME%\bin`
5. Verify installation:
   ```bash
   java -version
   javac -version
   ```

### 3. Install Android Studio

1. Download Android Studio from [https://developer.android.com/studio](https://developer.android.com/studio)
2. Run the installer and follow the setup wizard
3. During installation, ensure these components are selected:
   - Android SDK
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android Virtual Device (for emulator)

### 4. Configure Android SDK

1. Open Android Studio
2. Go to Settings → Appearance & Behavior → System Settings → Android SDK
3. In the SDK Platforms tab, select:
   - Android 13 (API Level 33) or latest
   - Android 12 (API Level 31) for backward compatibility
4. In the SDK Tools tab, ensure these are installed:
   - Android SDK Build-Tools
   - Android Emulator
   - Android SDK Platform-Tools
   - Intel x86 Emulator Accelerator (HAXM installer)
5. Note the Android SDK path (you'll need this for Flutter setup)

### 5. Install Flutter SDK

1. Download Flutter SDK from [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows)
2. Extract the zip file to a desired location (e.g., `C:\src\flutter`)
3. Add Flutter to your PATH:
   - Open System Properties → Advanced → Environment Variables
   - Edit the PATH system variable
   - Add the path to Flutter's bin directory (e.g., `C:\src\flutter\bin`)
4. Verify installation:
   ```bash
   flutter --version
   ```

### 6. Run Flutter Doctor

1. Open a new PowerShell or Command Prompt window
2. Run:
   ```bash
   flutter doctor
   ```
3. Address any issues reported by flutter doctor:
   - Install missing Android licenses:
     ```bash
     flutter doctor --android-licenses
     ```
   - Install Visual Studio tools if prompted

### 7. Install Visual Studio Code (Optional but Recommended)

1. Download VS Code from [https://code.visualstudio.com/](https://code.visualstudio.com/)
2. Install the Flutter extension:
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "Flutter" and install the official extension

### 8. Configure Android Device

#### Option A: Android Emulator

1. Open Android Studio
2. Go to Device Manager
3. Create a new virtual device:
   - Select a device definition (e.g., Pixel 4)
   - Select a system image (API 33 or latest)
   - Complete the wizard
4. Start the emulator from Device Manager

#### Option B: Physical Android Device

1. Enable Developer Options on your Android device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Go to Settings → Developer Options
   - Enable "USB Debugging"
3. Connect your device to your computer via USB
4. Accept the USB debugging authorization on your device

## 🚀 PocketLLM Project Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/pocketllm.git
cd pocketllm
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Setup

```bash
flutter doctor
```

Expected output should show:
- Flutter (Channel stable, 3.x.x, on Microsoft Windows)
- Android toolchain - develop for Android devices (Android SDK version xx.x.x)
- Chrome - develop for the web
- Android Studio (version)
- VS Code (if installed)

### 4. Run the Application

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d android
flutter run -d chrome

# Run with verbose output for debugging
flutter run -v
```

## 🔧 Troubleshooting Common Issues

### Issue: "No connected devices"

**Solution:**
1. Ensure your Android device is connected via USB
2. Check that USB debugging is enabled
3. Verify the device is recognized:
   ```bash
   adb devices
   ```
4. For emulators, ensure they are fully booted

### Issue: "Android license status unknown"

**Solution:**
```bash
flutter doctor --android-licenses
```
Accept all licenses when prompted.

### Issue: "Unable to locate Android SDK"

**Solution:**
1. Find your Android SDK path in Android Studio (Settings → Appearance & Behavior → System Settings → Android SDK)
2. Set the path manually:
   ```bash
   flutter config --android-sdk <path-to-sdk>
   ```

### Issue: "Gradle task assembleDebug failed"

**Solution:**
1. Clean the project:
   ```bash
   flutter clean
   flutter pub get
   ```
2. Ensure sufficient disk space and memory
3. Check for network connectivity issues

### Issue: "Dart SDK not found"

**Solution:**
1. Reinstall Flutter SDK
2. Ensure Flutter bin directory is in your PATH
3. Restart your terminal/command prompt

## 📱 Platform-Specific Considerations

### Android

- Minimum SDK version: Android 8.0 (API level 26)
- Target SDK version: Latest stable Android version
- Required permissions are specified in [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml)

### iOS (Mac Only)

PocketLLM can be developed for iOS, but requires a Mac with Xcode:
1. Install Xcode from the Mac App Store
2. Install Xcode command line tools:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
3. Run on iOS simulator:
   ```bash
   flutter run -d iPhone
   ```

### Web

PocketLLM supports web deployment:
```bash
flutter run -d chrome
```

### Desktop

PocketLLM supports desktop platforms:
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## 🛠️ Development Tools

### Useful Flutter Commands

```bash
# Check Flutter version and environment
flutter --version
flutter doctor

# List connected devices
flutter devices

# Get packages
flutter pub get

# Upgrade Flutter
flutter upgrade

# Clean build artifacts
flutter clean

# Analyze code
flutter analyze

# Format code
flutter format .

# Run tests
flutter test
```

### Debugging Tools

1. **Flutter DevTools**: 
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

2. **Android Debug Bridge (ADB)**:
   ```bash
   # View device logs
   adb logcat
   
   # Install APK
   adb install app.apk
   ```

## 🔒 Security Considerations

1. Never commit sensitive information (API keys, passwords) to the repository
2. Use environment variables or secure storage for sensitive data
3. Review permissions in AndroidManifest.xml
4. Follow Flutter security best practices

## 📚 Additional Resources

- [Flutter Official Documentation](https://docs.flutter.dev/)
- [Android Developer Guide](https://developer.android.com/guide)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [PocketLLM AGENTS.md](../AGENTS.md) - AI agent development guide

## 🔄 Keeping Your Environment Updated

1. Regularly update Flutter:
   ```bash
   flutter upgrade
   ```

2. Update Android Studio and SDKs through the IDE

3. Update project dependencies:
   ```bash
   flutter pub upgrade
   ```

4. Check for outdated packages:
   ```bash
   flutter pub outdated
   ```

By following this guide, you should have a fully functional development environment for PocketLLM. If you encounter any issues not covered here, please check the Flutter community forums or create an issue in the PocketLLM repository.