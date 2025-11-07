#!/usr/bin/env bash
# PocketLLM workspace bootstrapper.
set -euo pipefail

have() {
  command -v "$1" >/dev/null 2>&1
}

WORKSPACE="${WORKSPACE:-$(pwd)}"
PUBSPEC_PATH="$(find "$WORKSPACE" -name pubspec.yaml -print -quit 2>/dev/null || true)"
if [[ -z "$PUBSPEC_PATH" ]]; then
  echo "[setup] Unable to locate pubspec.yaml within \$WORKSPACE ($WORKSPACE)." >&2
  exit 1
fi
PROJECT_DIR="$(dirname "$PUBSPEC_PATH")"
APP_NAME="$(basename "$PROJECT_DIR")"

echo "[setup] Preparing Flutter/Android environment for $APP_NAME"

FLUTTER_VERSION="${FLUTTER_VERSION:-3.19.6}"
FLUTTER_SDK_INSTALL_DIR="${FLUTTER_SDK_INSTALL_DIR:-$HOME/flutter}"
FLUTTER_TARBALL_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
OS_NAME="$(uname -s 2>/dev/null || echo unknown)"

if [[ ! -d "$FLUTTER_SDK_INSTALL_DIR" ]]; then
  if have curl && have tar; then
    echo "[setup] Downloading Flutter $FLUTTER_VERSION..."
    curl -sL "$FLUTTER_TARBALL_URL" | tar -xJ -C "$HOME"
  else
    echo "[setup] Skipping Flutter download (missing curl and/or tar)." >&2
  fi
else
  echo "[setup] Flutter SDK found at $FLUTTER_SDK_INSTALL_DIR"
fi

if have git; then
  git config --global --add safe.directory "$FLUTTER_SDK_INSTALL_DIR" >/dev/null 2>&1 || true
fi

export PATH="$FLUTTER_SDK_INSTALL_DIR/bin:$PATH"

if have flutter; then
  if have sudo && [[ -d /usr/local/bin ]]; then
    sudo ln -sf "$FLUTTER_SDK_INSTALL_DIR/bin/flutter" /usr/local/bin/flutter
    if have dart; then
      sudo ln -sf "$FLUTTER_SDK_INSTALL_DIR/bin/dart" /usr/local/bin/dart
    fi
  fi

  flutter --version
  if have dart; then
    dart --version
  fi

  flutter precache --linux --no-web --no-ios --no-android --no-windows --no-macos || true
else
  echo "[setup] flutter command not available on PATH; skipping precache." >&2
fi

if [[ "$OS_NAME" == "Linux" ]] && have apt-get; then
  ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/usr/lib/android-sdk}"
  if [[ ! -d "$ANDROID_SDK_ROOT" ]]; then
    echo "[setup] Installing Android command-line tools..."
    sudo apt-get update
    sudo apt-get install -y openjdk-17-jdk curl unzip wget
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11095708_latest.zip
    mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    unzip -q commandlinetools-linux-11095708_latest.zip -d "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    rm -f commandlinetools-linux-11095708_latest.zip
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
    export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"
    yes | flutter doctor --android-licenses || true
  else
    echo "[setup] Android SDK already present at $ANDROID_SDK_ROOT"
  fi
else
  echo "[setup] Skipping Android SDK install (requires Linux + apt-get)." >&2
fi

pushd "$PROJECT_DIR" >/dev/null
if have flutter; then
  flutter pub get
  flutter gen-l10n || true
fi

if have dart && have rg && rg --hidden --no-heading -l -g'*.dart' 'part .*\.g\.dart' lib >/dev/null 2>&1; then
  echo "[setup] Running build_runner for generated files..."
  dart run build_runner build --delete-conflicting-outputs --build-filter="lib/**"
fi
popd >/dev/null

echo "[setup] Environment ready for $APP_NAME"
