#!/bin/sh

# Runs immediately before xcodebuild. Must match Build (Debug) vs Archive (Release).
set -e

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-.}"
if [ -f "$REPO_ROOT/budget_app/pubspec.yaml" ]; then
  APP_ROOT="$REPO_ROOT/budget_app"
elif [ -f "$REPO_ROOT/pubspec.yaml" ]; then
  APP_ROOT="$REPO_ROOT"
else
  echo "ERROR: could not find Flutter pubspec.yaml under $REPO_ROOT"
  exit 1
fi

cd "$APP_ROOT"
export PATH="$PATH:$HOME/flutter/bin"

BUILD_NUMBER="${CI_BUILD_NUMBER:-1}"
BUILD_NAME="${FLUTTER_BUILD_NAME:-1.0.0}"
ACTION="${CI_XCODEBUILD_ACTION:-build}"
CONFIG="${CONFIGURATION:-}"

echo "==> ci_pre_xcodebuild.sh"
echo "APP_ROOT=$APP_ROOT"
echo "CI_XCODEBUILD_ACTION=$ACTION"
echo "CONFIGURATION=$CONFIG"
echo "CI_BUILD_NUMBER=$BUILD_NUMBER"
echo "BUILD_NAME=$BUILD_NAME"

if [ "$ACTION" = "archive" ] || [ "$CONFIG" = "Release" ] || [ "$CONFIG" = "Profile" ]; then
  MODE=release
else
  MODE=debug
fi

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

echo "==> flutter build ios --$MODE --config-only"
# shellcheck disable=SC2086
flutter build ios --"$MODE" --no-codesign --config-only --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER" $DART_DEFINES

cd ios
if command -v agvtool >/dev/null 2>&1; then
  agvtool new-version -all "$BUILD_NUMBER" || true
fi

exit 0
