#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/OpenOSThirds.swift"
APP="$HOME/Applications/OpenOSThirds.app"
BIN="$APP/Contents/MacOS/OpenOSThirds"
PLIST="$HOME/Library/LaunchAgents/pro.openos.thirds.plist"
LABEL="gui/$(id -u)/pro.openos.thirds"

if [[ ! -f "$SRC" ]]; then
  echo "missing $SRC" >&2
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
  <string>3</string>
  <key>CFBundleShortVersionString</key>
  <string>1.2</string>
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
xcrun swiftc -O -sdk "$(xcrun --show-sdk-path --sdk macosx)" -o "$BIN" "$SRC"
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

RECT=""
if [[ -d /Applications/Rectangle.app ]]; then
  RECT="/Applications/Rectangle.app"
elif [[ -d "$HOME/Applications/Rectangle.app" ]]; then
  RECT="$HOME/Applications/Rectangle.app"
fi
if [[ -n "$RECT" ]]; then
  defaults write com.knollsoft.Rectangle windowSnapping -int 1
  defaults write com.knollsoft.Rectangle launchOnLogin -bool true
  defaults write com.knollsoft.Rectangle firstThird -dict keyCode -int 18 modifierFlags -int 786432
  defaults write com.knollsoft.Rectangle centerThird -dict keyCode -int 19 modifierFlags -int 786432
  defaults write com.knollsoft.Rectangle lastThird -dict keyCode -int 20 modifierFlags -int 786432
  open -a "$RECT" || true
  osascript -e "tell application \"System Events\"
    set names to name of every login item
    if names does not contain \"Rectangle\" then
      make login item at end with properties {path:\"$RECT\", hidden:false}
    end if
  end tell" >/dev/null 2>&1 || true
fi

if [[ -n "${ZONE_MODE:-}" ]]; then
  defaults write pro.openos.thirds zoneMode "$ZONE_MODE"
  echo "=== zoneMode $ZONE_MODE ==="
fi

sleep 0.6
echo "=== running ==="
pgrep -lf OpenOSThirds || echo "OpenOSThirds not running"
defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString
defaults read pro.openos.thirds zoneMode 2>/dev/null || echo "zoneMode auto"
echo "OK $APP"
