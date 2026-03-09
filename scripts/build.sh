#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="vrew"
ARCHIVE_PATH="$PROJECT_DIR/build/vrew.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
ZIP_NAME="vrew.zip"

echo "🍺 Building Vrew..."

rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"

xcodebuild archive \
  -project "$PROJECT_DIR/vrew.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  | xcpretty 2>/dev/null || true

APP_PATH=$(find "$ARCHIVE_PATH" -name "*.app" | head -1)

if [ -z "$APP_PATH" ]; then
  echo "❌ Build failed — .app not found in archive"
  exit 1
fi

cp -R "$APP_PATH" "$PROJECT_DIR/build/vrew.app"

cd "$PROJECT_DIR/build"
ditto -c -k --sequesterRsrc --keepParent vrew.app "$ZIP_NAME"

echo ""
echo "✅ Done!"
echo "   App:  build/vrew.app"
echo "   ZIP:  build/$ZIP_NAME"
echo ""
echo "To remove the Gatekeeper warning on other Macs:"
echo "   xattr -cr /Applications/vrew.app"
