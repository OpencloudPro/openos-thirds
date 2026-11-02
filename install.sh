#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/OpenOSThirds.swift"
GEO="$ROOT/SnapGeometry.swift"
APP="$HOME/Applications/OpenOSThirds.app"
BIN="$APP/Contents/MacOS/OpenOSThirds"
PLIST="$HOME/Library/LaunchAgents/pro.openos.thirds.plist"
LABEL="gui/$(id -u)/pro.openos.thirds"

if [[ ! -f "$SRC" || ! -f "$GEO" ]]; then
  echo "missing $SRC or $GEO" >&2
  exit 1
fi

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$HOME/Library/LaunchAgents"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>pro.openos.thirds</string>
  <key>CFBundleName</key>
  <string>OpenOS Thirds</string>
  <key>CFBundleDisplayName</key>
  <string>OpenOS Thirds</string>
  <key>CFBundleExecutable</key>
  <string>OpenOSThirds</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>7</string>
  <key>CFBundleShortVersionString</key>
  <string>1.6</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "=== compile ==="
xcrun swiftc -O -sdk "$(xcrun --show-sdk-path --sdk macosx)" -o "$BIN" "$GEO" "$SRC"
chmod +x "$BIN"
xattr -cr "$APP" 2>/dev/null || true
codesign --force --deep --sign - "$APP" >/dev/null

cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>pro.openos.thirds</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <false/>
</dict>
</plist>
EOF

if launchctl print "$LABEL" >/dev/null 2>&1; then
  launchctl kickstart -k "$LABEL"
else
  launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"
  launchctl enable "$LABEL"
  launchctl kickstart -k "$LABEL"
fi

if [[ -n "${ZONE_MODE:-}" ]]; then
  defaults write pro.openos.thirds zoneMode "$ZONE_MODE"
  echo "=== zoneMode $ZONE_MODE ==="
fi
if [[ -n "${SHOW_RAIL:-}" ]]; then
  case "$SHOW_RAIL" in
    1|true|TRUE|yes|YES|on|ON) rail=true ;;
    *) rail=false ;;
  esac
  defaults write pro.openos.thirds showRail -bool "$rail"
  echo "=== showRail $rail ==="
fi

sleep 0.6
echo "=== running ==="
pgrep -lf OpenOSThirds || echo "OpenOSThirds not running"
defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString
defaults read pro.openos.thirds zoneMode 2>/dev/null || echo "zoneMode auto"
echo "Acessibilidade: Definições do Sistema → Privacidade e Segurança → Acessibilidade → OpenOS Thirds"
echo "OK $APP"
