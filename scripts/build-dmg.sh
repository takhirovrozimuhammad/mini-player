#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: GlassNeedle's .dmg must be created on macOS (hdiutil + Xcode required)." >&2
  exit 1
fi
for program in hdiutil ditto; do
  if ! command -v "$program" >/dev/null 2>&1; then
    echo "ERROR: Missing $program" >&2
    exit 1
  fi
done
bash scripts/build-app.sh
APP="${PWD}/dist/GlassNeedle.app"
if [[ ! -x "$APP/Contents/MacOS/GlassNeedle" ]]; then
  echo 'ERROR: Build did not produce a runnable executable.' >&2
  exit 1
fi
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/GlassNeedle-DMG.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
# Keep the .app intact; Finder drag-to-Applications convenience.
ditto "$APP" "$STAGE/GlassNeedle.app"
ln -s /Applications "$STAGE/Applications"
mkdir -p dist
hdiutil create -volname "GlassNeedle" -srcfolder "$STAGE" -ov -format UDZO -imagekey zlib-level=9 "${PWD}/dist/GlassNeedle-v0.1.0-macOS.dmg"
ditto -c -k --sequesterRsrc --keepParent "$APP" "${PWD}/dist/GlassNeedle-v0.1.0-macOS.zip"
(
  cd dist
  shasum -a 256 GlassNeedle-v0.1.0-macOS.dmg > SHA256SUMS.txt
  shasum -a 256 GlassNeedle-v0.1.0-macOS.zip >> SHA256SUMS.txt
)
echo "Created dist/GlassNeedle-v0.1.0-macOS.dmg (ad-hoc signed, NOT notarized)"
