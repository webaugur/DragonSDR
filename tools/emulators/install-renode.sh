#!/usr/bin/env bash
# Install Renode portable into ~/Applications/Renode (DragonSDR sidequest).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="${RENODE_PREFIX:-$HOME/Applications/Renode}"
DL="${RENODE_DOWNLOAD_DIR:-$ROOT/tools/emulators/downloads}"
# Stable portable (Mono-free .NET portable preferred when available)
VERSION="${RENODE_VERSION:-1.16.1}"
BASE_URL="${RENODE_BASE_URL:-https://github.com/renode/renode/releases/download/v${VERSION}}"
# Prefer portable-dotnet for modern Linux; fallback portable
ASSET="${RENODE_ASSET:-renode-${VERSION}.linux-portable-dotnet.tar.gz}"
ASSET_FALLBACK="renode-${VERSION}.linux-portable.tar.gz"

mkdir -p "$APP" "$DL"

download() {
  local url="$1" out="$2"
  if [[ -f "$out" ]]; then
    echo "Using existing $out"
    return 0
  fi
  echo "Downloading $url"
  curl -fL --retry 3 -o "$out.partial" "$url"
  mv "$out.partial" "$out"
}

TAR="$DL/$ASSET"
if ! download "$BASE_URL/$ASSET" "$TAR" 2>/dev/null; then
  echo "Primary asset failed; trying $ASSET_FALLBACK"
  ASSET="$ASSET_FALLBACK"
  TAR="$DL/$ASSET"
  download "$BASE_URL/$ASSET" "$TAR"
fi

DEST="$APP/renode-${VERSION}"
if [[ -d "$DEST" && -x "$DEST/renode" ]]; then
  echo "Already installed: $DEST"
else
  echo "Extracting to $DEST"
  rm -rf "$DEST"
  mkdir -p "$DEST"
  tar xf "$TAR" -C "$DEST" --strip-components=1
fi

ln -sfn "$DEST" "$APP/current"

LAUNCH="$APP/renode-launch.sh"
cat >"$LAUNCH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
export PATH="$ROOT/current:$PATH"
# Prefer current tree
if [[ -x "$ROOT/current/renode" ]]; then
  exec "$ROOT/current/renode" "$@"
fi
if [[ -x "$ROOT/current/bin/renode" ]]; then
  exec "$ROOT/current/bin/renode" "$@"
fi
echo "renode binary not found under $ROOT/current" >&2
exit 1
EOF
chmod +x "$LAUNCH"

# Desktop launcher in ~/Applications/ root (matching AbracaDABra.desktop etc.)
DESKTOP="$HOME/Applications/Renode.desktop"
cat >"$DESKTOP" <<EOF
[Desktop Entry]
Name=Renode
Comment=Embedded systems simulator (Renode $VERSION)
Exec=$LAUNCH
Path=$APP
Icon=$APP/renode-icon-64.svg
Terminal=true
Type=Application
Categories=Development;Electronics;Emulator;
EOF

# Suite bin wrapper
SUITE_BIN="$ROOT/bin/renode"
cat >"$SUITE_BIN" <<EOF
#!/usr/bin/env bash
exec "\${RENODE_LAUNCH:-\$HOME/Applications/Renode/renode-launch.sh}" "\$@"
EOF
chmod +x "$SUITE_BIN"

echo
echo "Renode $VERSION ready."
echo "  launch: $LAUNCH"
echo "  or:     $SUITE_BIN"
echo "  smoke:  $SUITE_BIN --version 2>/dev/null || $SUITE_BIN -e 'quit' || true"
echo
# Best-effort smoke
if "$LAUNCH" --help >/dev/null 2>&1 || "$LAUNCH" -e "quit" >/dev/null 2>&1; then
  echo "Smoke: OK"
else
  echo "Smoke: run manually once (GUI/Monitor may need display)."
fi
