#!/bin/bash
# Singlish LK — Release Build & Archive Script
# Usage: ./build-release.sh
# Requires: Xcode CLI tools, valid Apple Developer signing identity

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_FILE="$PROJECT_DIR/Singlish Pro.xcodeproj"
SCHEME="Singlish Pro"
ARCHIVE_PATH="$PROJECT_DIR/build/SinglishLK.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"

echo "🔧 Singlish LK Release Build"
echo "============================"
echo ""

# Step 1: Clean build directory
echo "🗑️  Cleaning build directory..."
rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"

# Step 2: Create ExportOptions.plist if it doesn't exist
if [ ! -f "$EXPORT_OPTIONS" ]; then
    echo "📝 Creating ExportOptions.plist..."
    cat > "$EXPORT_OPTIONS" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
PLIST
    echo "⚠️  Edit ExportOptions.plist and replace YOUR_TEAM_ID with your Apple Developer Team ID"
fi

# Step 3: List available schemes
echo ""
echo "📋 Available schemes:"
xcodebuild -project "$PROJECT_FILE" -list | grep "Schemes" -A 10

# Step 4: Archive
echo ""
echo "📦 Archiving for App Store..."
xcodebuild archive \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    -quiet \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=YES \
    CODE_SIGNING_REQUIRED=YES \
    -allowProvisioningUpdates \
    || { echo "❌ Archive failed! Make sure you have a valid signing identity configured."; exit 1; }

echo ""
echo "✅ Archive created at: $ARCHIVE_PATH"
echo ""
echo "📤 Next steps:"
echo "   1. Open Xcode → Window → Organizer"
echo "   2. Select the Singlish LK archive"
echo "   3. Click 'Distribute App' → 'App Store Connect'"
echo ""
echo "   Or export via CLI:"
echo "   xcodebuild -exportArchive \\"
echo "       -archivePath '$ARCHIVE_PATH' \\"
echo "       -exportPath '$EXPORT_PATH' \\"
echo "       -exportOptionsPlist '$EXPORT_OPTIONS'"
echo ""
echo "🎉 Ready for App Store submission!"
