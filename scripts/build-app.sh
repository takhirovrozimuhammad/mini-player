#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This build must run on macOS with Apple Command Line Tools." >&2
  exit 1
fi
if ! xcrun --find swift >/dev/null 2>&1; then
  echo "Install Apple Command Line Tools: xcode-select --install" >&2
  exit 1
fi
swift build -c release
APP="$PWD/dist/GlassNeedle.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/GlassNeedle "$APP/Contents/MacOS/GlassNeedle"
cp Info.plist "$APP/Contents/Info.plist"
if [[ -d Resources/AppIcon.iconset ]] && command -v iconutil >/dev/null 2>&1; then
  iconutil -c icns Resources/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
fi
chmod +x "$APP/Contents/MacOS/GlassNeedle"
codesign --force --sign - "$APP"
echo "App ready: $APP"
