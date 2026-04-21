#!/usr/bin/env bash
# Build, sign, package as DMG and notarize LinkUnbound.app for distribution.
#
# Required env vars (load from .env or your shell):
#   APPLE_ID                  Apple ID email (e.g. you@example.com)
#   APPLE_APP_PASSWORD        App-specific password from appleid.apple.com
#   APPLE_TEAM_ID             10-char Team ID (e.g. TFKDH6LAD4)
# Optional:
#   SIGN_IDENTITY             Override codesign identity. Default: first
#                             "Developer ID Application" in the login keychain.
#   VERSION                   Override pubspec version (e.g. 2.0.0-beta.1)
#   SKIP_NOTARIZE=1           Build + sign + DMG only, no notarization.
#
# Usage:
#   ./scripts/build_macos_dmg.sh
#
# Output: apps/linkunbound/dist/LinkUnbound_<version>_universal.dmg

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/apps/linkunbound"
APP_NAME="LinkUnbound"
APP_PATH="$APP_DIR/build/macos/Build/Products/Release/${APP_NAME}.app"
ENTITLEMENTS="$APP_DIR/macos/Runner/Release.entitlements"
DIST_DIR="$APP_DIR/dist"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "::error:: required command not found: $1"
    exit 1
  fi
}

require flutter
require codesign
require xcrun

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "create-dmg not found. Installing via Homebrew..."
  brew install create-dmg
fi

VERSION="${VERSION:-$(grep '^version:' "$APP_DIR/pubspec.yaml" | awk '{print $2}')}"
BUILD_NAME="${VERSION%-*}"
BUILD_NUMBER=$(echo "$BUILD_NAME" | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')

echo "==> Version: $VERSION  Build: $BUILD_NAME ($BUILD_NUMBER)"

SIGN_IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F'"' '{print $2}')}"
if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "::error:: no 'Developer ID Application' identity found in keychain."
  echo "Available identities:"
  security find-identity -v -p codesigning
  exit 1
fi
echo "==> Signing identity: $SIGN_IDENTITY"

echo "==> Refreshing CocoaPods..."
rm -f "$APP_DIR/macos/Podfile.lock"
( cd "$APP_DIR/macos" && pod install --repo-update )

echo "==> Building release (universal)..."
( cd "$APP_DIR" && flutter build macos --release \
    --build-name="$BUILD_NAME" \
    --build-number="$BUILD_NUMBER" \
    --dart-define="APP_VERSION=$VERSION" )

echo "==> Verifying universal binary..."
ARCHS=$(lipo -archs "$APP_PATH/Contents/MacOS/$APP_NAME")
echo "Architectures: $ARCHS"
if [[ "$ARCHS" != *"x86_64"* ]] || [[ "$ARCHS" != *"arm64"* ]]; then
  echo "::error:: expected universal binary (x86_64 + arm64), got: $ARCHS"
  exit 1
fi

echo "==> Signing .app with Hardened Runtime..."
codesign --deep --force --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --sign "$SIGN_IDENTITY" \
  "$APP_PATH"

codesign --verify --deep --strict "$APP_PATH"
echo "==> .app signature verified."

mkdir -p "$DIST_DIR"
DMG_NAME="${APP_NAME}_${VERSION}_universal.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
rm -f "$DMG_PATH"

echo "==> Creating DMG..."
create-dmg \
  --volname "$APP_NAME" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 80 \
  --icon "${APP_NAME}.app" 180 190 \
  --app-drop-link 480 190 \
  --hide-extension "${APP_NAME}.app" \
  --no-internet-enable \
  "$DMG_PATH" \
  "$APP_PATH" \
  || true

if [[ ! -f "$DMG_PATH" ]]; then
  echo "::error:: DMG was not created"
  exit 1
fi

echo "==> DMG created: $DMG_NAME ($(du -h "$DMG_PATH" | cut -f1))"

echo "==> Signing DMG..."
codesign --force --sign "$SIGN_IDENTITY" "$DMG_PATH"
codesign --verify "$DMG_PATH"

if [[ "${SKIP_NOTARIZE:-0}" == "1" ]]; then
  echo "==> SKIP_NOTARIZE=1, skipping notarization."
  echo "==> Done: $DMG_PATH"
  exit 0
fi

: "${APPLE_ID:?APPLE_ID not set}"
: "${APPLE_APP_PASSWORD:?APPLE_APP_PASSWORD not set}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID not set}"

echo "==> Submitting for notarization (this may take several minutes)..."
xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait \
  --timeout 1200

echo "==> Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo "==> Verifying notarization..."
spctl --assess --type open --context context:primary-signature "$DMG_PATH"

echo "==> Done: $DMG_PATH"
