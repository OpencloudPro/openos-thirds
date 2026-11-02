#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/OpenOSThirds.swift"
GEO="$ROOT/SnapGeometry.swift"
APP="$HOME/Applications/OpenOSThirds.app"
BIN="$APP/Contents/MacOS/OpenOSThirds"
PLIST="$HOME/Library/LaunchAgents/pro.openos.thirds.plist"
DOMAIN="gui/$(id -u)"
LABEL="$DOMAIN/pro.openos.thirds"

if [[ ! -f "$SRC" || ! -f "$GEO" ]]; then
  echo "missing $SRC or $GEO" >&2
  exit 1
fi

echo "=== stop ==="
launchctl bootout "$DOMAIN" "$PLIST" 2>/dev/null || true
launchctl bootout "$LABEL" 2>/dev/null || true
if pgrep -x OpenOSThirds >/dev/null 2>&1; then
  pkill -x OpenOSThirds || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x OpenOSThirds >/dev/null 2>&1 || break
    sleep 0.1
  done
fi
if pgrep -x OpenOSThirds >/dev/null 2>&1; then
  pkill -9 -x OpenOSThirds || true
  sleep 0.2
fi

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/openosthirds.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
STAGE_APP="$STAGE/OpenOSThirds.app"
mkdir -p "$STAGE_APP/Contents/MacOS" "$STAGE_APP/Contents/Resources" \
  "$HOME/Applications" "$HOME/Library/LaunchAgents"

cat > "$STAGE_APP/Contents/Info.plist" << 'PLIST'
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
xcrun swiftc -O -sdk "$(xcrun --show-sdk-path --sdk macosx)" \
  -o "$STAGE_APP/Contents/MacOS/OpenOSThirds" "$GEO" "$SRC"
chmod +x "$STAGE_APP/Contents/MacOS/OpenOSThirds"

# Bundle novo (inodes novos). Escrever por cima do binário em execução
# deixa o kernel com a assinatura antiga desse inode e o próximo spawn
# morre com SIGKILL / Launch Constraint Violation.
echo "=== install ==="
rm -rf "$APP"
ditto "$STAGE_APP" "$APP"
xattr -cr "$APP" 2>/dev/null || true
codesign --force --deep --sign - "$APP"

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

echo "=== launch ==="
if launchctl print "$LABEL" >/dev/null 2>&1; then
  launchctl kickstart -k "$LABEL"
else
  launchctl bootout "$DOMAIN" "$PLIST" 2>/dev/null || true
  launchctl bootstrap "$DOMAIN" "$PLIST"
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

print_out=""
running=0
for _ in 1 2 3 4 5 6 7 8; do
  print_out="$(launchctl print "$LABEL" 2>&1 || true)"
  if printf '%s\n' "$print_out" | grep -q 'state = spawn failed'; then
    printf '%s\n' "$print_out" >&2
    echo "launchctl: spawn failed" >&2
    exit 1
  fi
  if pgrep -x OpenOSThirds >/dev/null 2>&1; then
    running=1
    break
  fi
  sleep 0.25
done

echo "=== running ==="
if [[ "$running" -ne 1 ]]; then
  printf '%s\n' "$print_out" >&2
  echo "OpenOSThirds not running" >&2
  exit 1
fi
pgrep -lf OpenOSThirds
defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString
defaults read pro.openos.thirds zoneMode 2>/dev/null || echo "zoneMode auto"
echo "Acessibilidade: Definições do Sistema → Privacidade e Segurança → Acessibilidade → OpenOS Thirds"
echo "OK $APP"
