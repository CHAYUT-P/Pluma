#!/bin/bash
set -e

APP_NAME="Pluma"
EXECUTABLE_NAME="Pluma"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
INSTALL_DIR="/Applications"

# --keep-local  → leave the bundle in the project folder too (default: /Applications only)
KEEP_LOCAL=false
for arg in "$@"; do
    case "$arg" in
        --keep-local) KEEP_LOCAL=true ;;
    esac
done

echo "🔨 Building ${APP_NAME} in Release mode..."
swift build -c release

echo "📦 Creating macOS App Bundle: ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}" "TechniArt.app" "CanvaNative.app"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${BUILD_DIR}/${EXECUTABLE_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Bundle the MCP server so the AI-bridge config works from /Applications
cp "scripts/pluma_mcp_server.py" "${RESOURCES_DIR}/pluma_mcp_server.py"

# Create Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.pluma.studio</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>Pluma</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Remove quarantine and sign bundle
xattr -cr "${APP_BUNDLE}" || true
codesign --force --deep --sign - "${APP_BUNDLE}" 2>/dev/null || true

echo "✅ App bundle created and signed successfully"

# Install to /Applications so Spotlight/Launchpad/Dock show exactly ONE Pluma.
# Quit a running instance first so the bundle can be replaced cleanly.
osascript -e 'quit app "Pluma"' >/dev/null 2>&1 || true
sleep 1
rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
cp -R "${APP_BUNDLE}" "${INSTALL_DIR}/${APP_BUNDLE}"
xattr -cr "${INSTALL_DIR}/${APP_BUNDLE}" || true

if [ "$KEEP_LOCAL" = false ]; then
    rm -rf "${APP_BUNDLE}"
    echo "📦 Installed to ${INSTALL_DIR}/${APP_BUNDLE} (single copy — no duplicates in Spotlight)"
else
    echo "📦 Installed to ${INSTALL_DIR}/${APP_BUNDLE} + kept local ./${APP_BUNDLE}"
fi
echo "🚀 Launch it from Launchpad/Spotlight, or run: open ${INSTALL_DIR}/${APP_BUNDLE}"
