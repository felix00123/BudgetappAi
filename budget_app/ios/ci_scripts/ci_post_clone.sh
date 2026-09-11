#!/bin/sh

# Fail this script if any subcommand fails.
set -e

echo "==> Starting ci_post_clone.sh"
echo "CI_PRIMARY_REPOSITORY_PATH=$CI_PRIMARY_REPOSITORY_PATH"

# Flutter app lives in budget_app/ (repo root is BudgetappAi).
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-.}"
if [ -f "$REPO_ROOT/budget_app/pubspec.yaml" ]; then
  APP_ROOT="$REPO_ROOT/budget_app"
elif [ -f "$REPO_ROOT/pubspec.yaml" ]; then
  APP_ROOT="$REPO_ROOT"
else
  echo "ERROR: could not find Flutter pubspec.yaml under $REPO_ROOT"
  exit 1
fi

echo "APP_ROOT=$APP_ROOT"
cd "$APP_ROOT"

# Xcode Cloud often uses a shallow clone; Flutter needs remote refs.
git -C "$REPO_ROOT" fetch --unshallow 2>/dev/null || true
git -C "$REPO_ROOT" fetch origin main 2>/dev/null || true

# Install a pinned Flutter SDK (same as Mi Callcenter RD / local machine).
FLUTTER_VERSION="3.41.7"
FLUTTER_ZIP="flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip"

echo "==> Downloading Flutter ${FLUTTER_VERSION}"
curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/${FLUTTER_ZIP}" -o "/tmp/${FLUTTER_ZIP}"
rm -rf "$HOME/flutter"
unzip -q "/tmp/${FLUTTER_ZIP}" -d "$HOME"
export PATH="$PATH:$HOME/flutter/bin"

echo "==> Flutter version"
flutter --version

echo "==> Precache iOS artifacts"
flutter precache --ios

echo "==> Disable Swift Package Manager (use CocoaPods)"
flutter config --no-enable-swift-package-manager || true

echo "==> flutter pub get"
flutter pub get

echo "==> Generate iOS build config (debug + release for Cloud Build vs Archive)"
BUILD_NUMBER="${CI_BUILD_NUMBER:-1}"
BUILD_NAME="${FLUTTER_BUILD_NAME:-1.0.0}"
echo "CI_BUILD_NUMBER=$BUILD_NUMBER"
echo "BUILD_NAME=$BUILD_NAME"

# Optional OAuth client IDs (configure as Xcode Cloud environment variables / secrets).
DART_DEFINES=""
if [ -n "${GOOGLE_OAUTH_CLIENT_ID:-}" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=GOOGLE_OAUTH_CLIENT_ID=$GOOGLE_OAUTH_CLIENT_ID"
fi
if [ -n "${GOOGLE_OAUTH_SERVER_CLIENT_ID:-}" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=$GOOGLE_OAUTH_SERVER_CLIENT_ID"
fi
if [ -n "${MICROSOFT_CLIENT_ID:-}" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=MICROSOFT_CLIENT_ID=$MICROSOFT_CLIENT_ID"
fi

# shellcheck disable=SC2086
flutter build ios --debug --no-codesign --config-only --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER" $DART_DEFINES
# shellcheck disable=SC2086
flutter build ios --release --no-codesign --config-only --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER" $DART_DEFINES

echo "==> Install CocoaPods"
export HOMEBREW_NO_AUTO_UPDATE=1
if ! command -v pod >/dev/null 2>&1; then
  brew install cocoapods
fi
pod --version

echo "==> pod install"
cd ios
pod install

echo "==> ci_post_clone.sh finished"
exit 0
