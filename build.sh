#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
STAGE="$(mktemp -d -t videomenu-build)"
trap 'rm -rf "$STAGE"' EXIT
BUNDLE="$STAGE/VideoMenu.app"
export CLANG_MODULE_CACHE_PATH="$STAGE/modules"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
xcrun swiftc -target "$(uname -m)-apple-macosx13.0" -module-cache-path "$STAGE/modules" -swift-version 5 source/Host.swift -o "$BUNDLE/Contents/MacOS/VideoMenuHost"
xcrun swiftc -target "$(uname -m)-apple-macosx13.0" -module-cache-path "$STAGE/modules" -swift-version 5 source/Setup.swift -o "$BUNDLE/Contents/MacOS/VideoMenuSetup"
cp source/ExtensionID.txt "$BUNDLE/Contents/Resources/extension-id.txt"
cat > "$BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>VideoMenuSetup</string><key>CFBundleIdentifier</key><string>local.videomenu.setup</string><key>CFBundleName</key><string>VideoMenu</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>2</string><key>CFBundleShortVersionString</key><string>0.2.0</string><key>LSMinimumSystemVersion</key><string>13.0</string><key>NSPrincipalClass</key><string>NSApplication</string><key>LSUIElement</key><true/></dict></plist>
PLIST
codesign --force --sign - "$BUNDLE/Contents/MacOS/VideoMenuHost"
codesign --force --sign - "$BUNDLE"
codesign --verify --deep --strict "$BUNDLE"
# Preserve executable bits without carrying cloud-provider Finder metadata.
/usr/bin/ditto --norsrc "$BUNDLE" VideoMenu.app
printf 'Built VideoMenu.app. Open it to install the native helper.\n'
