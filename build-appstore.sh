#!/bin/bash

set -e

echo "Building PDFShuffle for App Store submission..."

# Configuration
APP_NAME="PDFShuffle"
BUNDLE_ID="com.pdfgenie.app"
VERSION="1.0.0"
BUILD_NUMBER="2"

# Clean build
rm -rf .build
rm -rf build

# Build release binary
swift build -c release

# Create app bundle structure
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp ".build/release/PDFShuffle" "$MACOS_DIR/"

# Copy icon
if [ -f "assets/icon.icns" ]; then
    cp "assets/icon.icns" "$RESOURCES_DIR/AppIcon.icns"
else
    echo "Warning: Icon file not found at assets/icon.icns"
fi

# Create Info.plist with proper configuration
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

# Sign the app with Developer ID
echo ""
echo "Signing app..."
echo "Available signing identities:"
security find-identity -v -p codesigning

echo ""
echo "To sign and submit to App Store:"
echo ""
echo "1. Sign the app:"
echo "   codesign --deep --force --verify --verbose --sign \"Developer ID Application: YOUR NAME\" \"$APP_BUNDLE\""
echo ""
echo "2. Verify signature:"
echo "   codesign --verify --deep --strict --verbose=2 \"$APP_BUNDLE\""
echo ""
echo "3. Create PKG installer:"
echo "   productbuild --sign \"Developer ID Installer: YOUR NAME\" --component \"$APP_BUNDLE\" /Applications build/PDFShuffle.pkg"
echo ""
echo "4. Notarize (required for distribution):"
echo "   xcrun notarytool submit build/PDFShuffle.pkg --apple-id YOUR_EMAIL --password YOUR_APP_SPECIFIC_PASSWORD --team-id YOUR_TEAM_ID --wait"
echo ""
echo "5. Staple notarization:"
echo "   xcrun stapler staple build/PDFShuffle.pkg"
echo ""
echo "6. Upload to App Store Connect:"
echo "   xcrun altool --upload-app --type macos --file build/PDFShuffle.pkg --username YOUR_EMAIL --password YOUR_APP_SPECIFIC_PASSWORD"
echo ""
echo "App bundle created at: $APP_BUNDLE"
