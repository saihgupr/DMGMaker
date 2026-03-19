#!/bin/bash

# DMG Maker Deployment Script
# This script builds, bundles, signs, and packages DMG Maker into a distributable DMG.

set -e

APP_NAME="DMG Maker"
BUNDLE_ID="com.saihgupr.DMGMaker"
DIST_DIR="dist"
STAGING_DIR="$DIST_DIR/staging"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

# 1. Cleanup
echo "🧹 Cleaning up..."
rm -rf "$DIST_DIR"
mkdir -p "$STAGING_DIR"

# 2. Build for Universal (Intel + Apple Silicon)
echo "🏗️  Building $APP_NAME (Universal)..."
swift build -c release --arch arm64 --arch x86_64

# Get the binary path (SPM puts it here for universal builds)
BINARY_PATH=".build/apple/Products/Release/$APP_NAME"

if [ ! -f "$BINARY_PATH" ]; then
    # Fallback to single arch if universal build failed or produced different path
    echo "⚠️  Universal binary not found at $BINARY_PATH, trying default architecture..."
    swift build -c release
    BINARY_PATH=".build/release/$APP_NAME"
fi

# 3. Create App Bundle Structure
echo "📦 Creating App Bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Sources/DMGMaker/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "Sources/DMGMaker/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Copy SPM Resource Bundle (Required for Bundle.module to work)
echo "📦 Copying Resource Bundle..."
cp -R .build/apple/Products/Release/*.bundle "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || \
cp -R .build/release/*.bundle "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true

# 4. Codesigning
# Use identity from argument or environment if provided, otherwise Ad-Hoc
SIGNING_IDENTITY="${1:-"-"}"

echo "✍️  Signing with identity: $SIGNING_IDENTITY..."
codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"

# 5. Create DMG
echo "💿 Creating DMG..."
# We use swift run to call the CLI mode of our own app to build the DMG
# This ensures we use our own "No-Halo" trick and Mesh Gradients
swift run "$APP_NAME" --app "$APP_BUNDLE" --name "$APP_NAME"

# Move the resulting DMG to dist
mv "$DIST_DIR/$APP_NAME.dmg" "$DIST_DIR/$APP_NAME.dmg" 2>/dev/null || true

echo "✅ Deployment complete! Find your DMG in the $DIST_DIR folder."
echo "🔗 Next step: Notarize the DMG for public distribution."
echo "   xcrun notarytool submit $DIST_DIR/$APP_NAME.dmg --apple-id <your-email> --team-id <your-team-id> --wait"
