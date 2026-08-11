#!/usr/bin/env bash
# Install Velxio into ~/Applications/Velxio (DragonSDR sidequest, matching Renode/Ghidra pattern).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="${VELXIO_PREFIX:-$HOME/Applications/Velxio}"
REPO="${VELXIO_REPO:-https://github.com/davidmonterocrespo24/velxio.git}"

mkdir -p "$APP"

DEST="$APP/velxio"
if [[ -d "$DEST/.git" ]]; then
  echo "Updating $DEST"
  git -C "$DEST" fetch --depth 1 origin
  git -C "$DEST" reset --hard origin/HEAD 2>/dev/null \
    || git -C "$DEST" pull --ff-only || true
else
  echo "Cloning $REPO → $DEST"
  git clone --depth 1 "$REPO" "$DEST"
fi

# Launcher script inside the install prefix
LAUNCH="$APP/velxio-launch.sh"
cat >"$LAUNCH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
VELXIO="$ROOT/velxio"

if [[ ! -d "$VELXIO" ]]; then
  echo "Velxio not found under $ROOT" >&2
  exit 1
fi

cd "$VELXIO"

# Prefer docker compose if available
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  if [[ -f docker-compose.yml ]] || [[ -f compose.yml ]]; then
    echo "Starting Velxio via docker compose (foreground Ctrl+C to stop)…"
    if docker compose version >/dev/null 2>&1; then
      exec docker compose up --build
    elif command -v docker-compose >/dev/null 2>&1; then
      exec docker-compose up --build
    fi
  fi
fi

# npm/dev fallback
if [[ -f package.json ]] && command -v npm >/dev/null 2>&1; then
  if [[ ! -d node_modules ]]; then
    echo "npm install (first run)…"
    npm install
  fi
  echo "Starting Velxio via npm (see package.json scripts)…"
  if npm run | grep -q 'dev'; then
    exec npm run dev
  fi
  if npm run | grep -q 'start'; then
    exec npm start
  fi
fi

cat <<HINT
Velxio is installed at:
  $VELXIO

Could not auto-start (need Docker with compose, or Node/npm).

Docker Compose is provided by the IndianaDell verification tooling:
  ~/Documents/IndianaDell/bin/fix-indianadell.sh --fix
  (installs docker.io + docker-compose-v2 as a soft dependency)

Options:
  1) Docker (recommended for full stack):
       cd $VELXIO && docker compose up --build
  2) Follow upstream README for local backend/frontend.
  3) Hosted UI (not offline): https://velxio.dev

ESP8266: Velxio targets ESP32 / ESP32-C3 (and other boards), not classic ESP8266.
HINT
exit 1
EOF
chmod +x "$LAUNCH"

# Desktop launcher in ~/Applications/ root (matching AbracaDABra.desktop etc.)
DESKTOP="$HOME/Applications/Velxio.desktop"
cat >"$DESKTOP" <<EOF
[Desktop Entry]
Name=Velxio
Comment=Embedded device emulator / circuit simulator (Velxio)
Exec=$LAUNCH
Path=$APP
Icon=$APP/velxio-icon-64.svg
Terminal=true
Type=Application
Categories=Development;Electronics;Emulator;
EOF

# Suite bin wrapper (project convenience)
SUITE_BIN="$ROOT/bin/velxio"
cat >"$SUITE_BIN" <<EOF
#!/usr/bin/env bash
exec "\${VELXIO_LAUNCH:-\$HOME/Applications/Velxio/velxio-launch.sh}" "\$@"
EOF
chmod +x "$SUITE_BIN"

# Ensure offline QEMU-lcgamboa libs exist (soft requirement for Velxio Docker image)
QEMU_BUILDER="$ROOT/tools/emulators/qemu-lcgamboa/build-all.sh"
if [[ -x "$QEMU_BUILDER" ]]; then
  echo "Ensuring QEMU-lcgamboa libraries (required for Velxio offline Docker build)..."
  "$QEMU_BUILDER" || echo "  [warn] QEMU build failed or incomplete — Velxio Docker image may need network or license key"
fi

echo
echo "Velxio ready under ~/Applications/Velxio/"
echo "  source:  $DEST"
echo "  launch:  $LAUNCH"
echo "  or:      $SUITE_BIN"
echo "  docs:    $ROOT/tools/emulators/README.md"
echo
echo "Note: full local stack usually needs Docker (compose) or Node."
echo "      ESP Wi‑Fi MCU simulation → ESP32 / ESP32-C3 in Velxio, not classic ESP8266."
echo "      QEMU-lcgamboa (offline) is declared as a soft DragonSDR dependency."