#!/bin/bash
# Singlish LK — Release Readiness Check
# Run this before submitting to App Store

PASS=0
WARN=0
FAIL=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

echo "🔍 Singlish LK Release Readiness Check"
echo "======================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo "📁 Project Structure"
echo "--------------------"

[ -f "$PROJECT_DIR/Singlish Pro/Singlish_ProApp.swift" ] && pass "Main app entry point exists" || fail "Main app entry point missing"
[ -f "$PROJECT_DIR/Singlish Pro/ContentView.swift" ] && pass "ContentView exists" || fail "ContentView missing"
[ -f "$PROJECT_DIR/Singlish Pro/SettingsView.swift" ] && pass "SettingsView exists" || fail "SettingsView missing"
[ -f "$PROJECT_DIR/Singlish Pro/PrivacyInfo.xcprivacy" ] && pass "Privacy manifest exists" || fail "Privacy manifest missing (required for App Store)"
[ -f "$PROJECT_DIR/SinglishKeyboard/KeyboardViewController.swift" ] && pass "Keyboard extension exists" || fail "Keyboard extension missing"
[ -f "$PROJECT_DIR/Shared/SinglishEngine.swift" ] && pass "Shared engine exists" || fail "Shared engine missing"
[ -f "$PROJECT_DIR/Shared/KeyboardSettings.swift" ] && pass "Shared settings exist" || fail "Shared settings missing"

echo ""
echo "🎨 Assets"
echo "---------"

ICON_DIR="$PROJECT_DIR/Singlish Pro/Assets.xcassets/AppIcon.appiconset"
if [ -d "$ICON_DIR" ]; then
    ICON_FILES=$(find "$ICON_DIR" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$ICON_FILES" -gt 0 ]; then
        HAS_LARGE=$(find "$ICON_DIR" \( -name "1024*.png" -o -name "AppIcon*.png" -o -name "app-icon*.png" \) 2>/dev/null | wc -l | tr -d ' ')
        if [ "$HAS_LARGE" -gt 0 ]; then
            pass "App icon present ($ICON_FILES images)"
        else
            warn "App icon present but no 1024x1024 App Store icon found"
        fi
    else
        fail "App icon images missing from AppIcon.appiconset"
    fi
else
    fail "AppIcon.appiconset directory missing"
fi

[ -d "$PROJECT_DIR/SinglishKeyboard/Assets.xcassets/KeyboardLogo.imageset" ] && pass "Keyboard logo asset exists" || warn "Keyboard logo missing"

echo ""
echo "⚙️  Build Configuration"
echo "-----------------------"

[ -f "$PROJECT_DIR/Singlish Pro.xcodeproj/project.pbxproj" ] && pass "Xcode project file exists" || fail "Xcode project file missing"

VERSION=$(grep -m1 "MARKETING_VERSION" "$PROJECT_DIR/Singlish Pro.xcodeproj/project.pbxproj" | grep -o '[0-9]\+\.[0-9]\+')
if [ -n "$VERSION" ]; then
    pass "Marketing version: $VERSION"
else
    warn "Marketing version not found"
fi

BUNDLE_ID=$(grep -m1 "PRODUCT_BUNDLE_IDENTIFIER.*KDJ" "$PROJECT_DIR/Singlish Pro.xcodeproj/project.pbxproj" | grep -o 'KDJ\.[A-Za-z0-9-]*' | head -1)
if [ -n "$BUNDLE_ID" ]; then
    pass "Bundle ID: $BUNDLE_ID"
else
    fail "Bundle ID not found"
fi

echo ""
echo "🔒 Privacy & Compliance"
echo "-----------------------"

if [ -f "$PROJECT_DIR/Singlish Pro/PrivacyInfo.xcprivacy" ]; then
    if grep -q "NSPrivacyTracking" "$PROJECT_DIR/Singlish Pro/PrivacyInfo.xcprivacy"; then
        pass "NSPrivacyTracking declared in PrivacyInfo.xcprivacy"
    else
        fail "NSPrivacyTracking not found in PrivacyInfo.xcprivacy"
    fi
fi

if grep -rq "API_KEY\|SECRET\|TOKEN\|PASSWORD" "$PROJECT_DIR/Singlish Pro" "$PROJECT_DIR/Shared" "$PROJECT_DIR/SinglishKeyboard" --include="*.swift" 2>/dev/null; then
    fail "Potential hardcoded secrets found in source files"
else
    pass "No hardcoded secrets detected"
fi

DEBUG_COUNT=$(grep -r "print(" "$PROJECT_DIR/Singlish Pro" "$PROJECT_DIR/Shared" "$PROJECT_DIR/SinglishKeyboard" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
if [ "$DEBUG_COUNT" -eq 0 ]; then
    pass "No debug print statements found"
else
    warn "$DEBUG_COUNT debug print statement(s) found in source files"
fi

echo ""
echo "📋 Build Test"
echo "-------------"

echo "  Building for simulator (debug)..."
if xcodebuild -project "$PROJECT_DIR/Singlish Pro.xcodeproj" \
    -scheme "Singlish Pro" \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -quiet build >/dev/null 2>&1; then
    pass "Debug build succeeded"
else
    fail "Debug build failed — fix errors before archiving"
fi

echo ""
echo "======================================="
echo "Results: ✅ $PASS passed  ⚠️  $WARN warnings  ❌ $FAIL failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "❌ Fix the failed checks before submitting to App Store"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo "⚠️  Warnings found — review before submission"
    exit 0
else
    echo "🎉 All checks passed! Ready to archive for App Store."
    exit 0
fi
