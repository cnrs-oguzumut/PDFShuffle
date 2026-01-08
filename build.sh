#!/bin/bash

set -e

echo "Building PDFShuffle..."

# Clean build
rm -rf .build

# Build release binary
swift build -c release

# Create app bundle structure
APP_NAME="PDFShuffle"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp ".build/release/PDFShuffle" "$MACOS_DIR/"

# Copy icon (if exists)
if [ -f "assets/icon.icns" ]; then
    cp "assets/icon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>PDFShuffle</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.pdfgenie.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>PDFShuffle</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
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
</dict>
</plist>
EOF

# Sign the app (for local use)
codesign --force --sign - --deep "$APP_BUNDLE"

echo "Build complete: $APP_BUNDLE"
