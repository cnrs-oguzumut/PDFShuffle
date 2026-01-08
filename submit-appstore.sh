#!/bin/bash

set -e

# Configuration
APP_NAME="PDFShuffle"
BUNDLE_ID="com.pdfgenie.app"
VERSION="1.0.0"
BUILD_NUMBER="2"
TEAM_ID="UM63FN2P72"

# Signing identities (from your certificates)
APP_SIGNING_IDENTITY="3rd Party Mac Developer Application: Lale Taneri (UM63FN2P72)"
INSTALLER_SIGNING_IDENTITY="3rd Party Mac Developer Installer: Lale Taneri (UM63FN2P72)"

echo "========================================="
echo "Building PDFShuffle for App Store"
echo "========================================="

# Clean previous builds
rm -rf .build
rm -rf build
rm -rf export

# Build release binary
echo "Building release binary..."
swift build -c release

# Create app bundle structure
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p export

# Copy binary
cp ".build/release/PDFShuffle" "$MACOS_DIR/"

# Copy icon
if [ -f "assets/icon.icns" ]; then
    cp "assets/icon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>PDF Document</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.adobe.pdf</string>
            </array>
        </dict>
    </array>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Lale Taneri. All rights reserved.</string>
</dict>
</plist>
EOF

echo ""
echo "Signing app bundle for App Store with entitlements..."
codesign --deep --force --options runtime --entitlements PDFShuffle.entitlements --sign "$APP_SIGNING_IDENTITY" "$APP_BUNDLE"

echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo ""
echo "Creating PKG for App Store..."
productbuild --component "$APP_BUNDLE" /Applications \
    --sign "$INSTALLER_SIGNING_IDENTITY" \
    "export/PDFShuffle.pkg"

echo ""
echo "========================================="
echo "Build Complete!"
echo "========================================="
echo ""
echo "PKG file ready at: export/PDFShuffle.pkg"
echo ""
echo "Next step: Upload to App Store Connect"
echo ""
echo "You need:"
echo "1. Your Apple ID email"
echo "2. App-specific password (generate at appleid.apple.com)"
echo ""
echo "Then run:"
echo "  xcrun altool --upload-app --type macos --file export/PDFShuffle.pkg \\"
echo "    --username YOUR_APPLE_ID_EMAIL \\"
echo "    --password YOUR_APP_SPECIFIC_PASSWORD"
echo ""
