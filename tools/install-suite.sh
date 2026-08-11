#!/usr/bin/env bash
# Install the DragonSDR suite: apt packages, HackRF/Mayhem workspace, URH venv,
# and (by default) embedded emulators Renode + Velxio.
#
# Usage:
#   ./tools/install-suite.sh                 # full suite (includes emulators)
#   ./tools/install-suite.sh --verify-only
#   ./tools/install-suite.sh --apt-only
#   ./tools/install-suite.sh --hackrf-only
#   ./tools/install-suite.sh --emulators-only
#   SKIP_HACKRF_BUILD=1 ./tools/install-suite.sh
#   SKIP_HAM=1 ./tools/install-suite.sh      # skip desktop ham apps
#   SKIP_EMULATORS=1 ./tools/install-suite.sh  # skip Renode/Velxio
#   SKIP_NEC=1 ./tools/install-suite.sh      # skip nec2c/xnec2c
#   SKIP_RE=1 ./tools/install-suite.sh       # skip FOSS RE tools (radare2, binwalk, …)
#
# Environment:
#   DRAGONSDR_ROOT  Override root (default: parent of tools/)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT="${DRAGONSDR_ROOT:-$ROOT}"
HACKRF_HOME="${ROOT}/hackrf"
LOG="${ROOT}/tools/last-install-suite.log"

VERIFY_ONLY=0
APT_ONLY=0
HACKRF_ONLY=0
EMULATORS_ONLY=0

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }
die() { log "ERROR: $*"; exit 1; }

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \?//'
  exit "${1:-0}"
}

for arg in "$@"; do
  case "$arg" in
    --verify-only) VERIFY_ONLY=1 ;;
    --apt-only) APT_ONLY=1 ;;
    --hackrf-only) HACKRF_ONLY=1 ;;
    --emulators-only) EMULATORS_ONLY=1 ;;
    -h|--help) usage 0 ;;
    *) die "Unknown argument: $arg (try --help)" ;;
  esac
done

# shellcheck source=package-lists.sh
source "${SCRIPT_DIR}/package-lists.sh"

# Rebuild APT_SUITE from components so SKIP_* flags compose cleanly.
APT_SUITE=("${APT_SDR_BUILD[@]}" "${APT_SDR[@]}")
if [[ "${SKIP_HAM:-0}" != 1 ]]; then
  APT_SUITE+=("${APT_HAM[@]}")
fi
if [[ "${SKIP_NEC:-0}" != 1 ]]; then
  APT_SUITE+=("${APT_NEC[@]}")
fi
if [[ "${SKIP_RE:-0}" != 1 ]]; then
  APT_SUITE+=("${APT_RE[@]}")
fi

verify_suite() {
  local fail=0
  log "=== Verification (ROOT=$ROOT) ==="
  for p in "${APT_SUITE[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed'; then
      log "MISS apt: $p"
      fail=1
    fi
  done
  for c in gnuradio-config-info grcc gqrx hackrf_info inspectrum; do
    command -v "$c" >/dev/null || { log "MISS cmd: $c"; fail=1; }
  done
  if [[ "${SKIP_HAM:-0}" != 1 ]]; then
    for c in fldigi wsjtx chirpw; do
      command -v "$c" >/dev/null || { log "MISS cmd: $c"; fail=1; }
    done
  fi
  if [[ "${SKIP_NEC:-0}" != 1 ]]; then
    for c in nec2c xnec2c; do
      command -v "$c" >/dev/null || { log "MISS cmd: $c (NEC)"; fail=1; }
    done
    [[ -x "${ROOT}/bin/nec2c" ]] || { log "MISS: bin/nec2c"; fail=1; }
    [[ -x "${ROOT}/bin/xnec2c" ]] || { log "MISS: bin/xnec2c"; fail=1; }
  fi
  if [[ "${SKIP_RE:-0}" != 1 ]]; then
    for c in radare2 r2 iaito binwalk cstool gdb-multiarch ndisasm; do
      command -v "$c" >/dev/null || { log "MISS cmd: $c (RE/FOSS)"; fail=1; }
    done
    # edb binary name varies
    if ! command -v edb >/dev/null 2>&1 && ! command -v edb-debugger >/dev/null 2>&1; then
      log "MISS cmd: edb (RE/FOSS)"
      fail=1
    fi
    # Soft checks (not fatal)
    command -v binsider >/dev/null 2>&1 || log "SOFT: binsider not on PATH (cargo install; tools/re/install-re-tools.sh --cargo)"
    [[ -x "${HOME}/Applications/Ghidra/ghidra-launch.sh" ]] \
      || [[ -d "${HOME}/Applications/Ghidra/current" ]] \
      || log "SOFT: Ghidra not under ~/Applications/Ghidra (see tools/ghidra/README.md)"
  fi
  [[ -x "${HACKRF_HOME}/venv-urh/bin/urh" ]] || { log "MISS: URH venv"; fail=1; }
  [[ -f "${HACKRF_HOME}/releases/FIRMWARE_mayhem_v2.4.0.zip" ]] || { log "MISS: Mayhem firmware zip"; fail=1; }
  [[ -d "${HACKRF_HOME}/sd-card/mayhem-v2.4.0/APPS" ]] || { log "MISS: Mayhem SD tree"; fail=1; }
  [[ -x "${HACKRF_HOME}/build/hackrf-tools/src/hackrf_sweep" ]] || { log "MISS: hackrf_sweep (built)"; fail=1; }
  if [[ "${SKIP_EMULATORS:-0}" != 1 ]]; then
    if [[ -x "${HOME}/Applications/Renode/renode-launch.sh" ]] \
      || [[ -x "${HOME}/Applications/Renode/current/renode" ]]; then
      log "OK: Renode"
    else
      log "MISS: Renode (run tools/emulators/install-renode.sh)"
      fail=1
    fi
    [[ -x "${ROOT}/bin/renode" ]] || { log "MISS: bin/renode"; fail=1; }
    if [[ -d "${ROOT}/tools/emulators/velxio/.git" ]] || [[ -d "${ROOT}/tools/emulators/velxio/package.json" ]]; then
      log "OK: Velxio tree"
    else
      log "MISS: Velxio clone (run tools/emulators/install-velxio.sh)"
      fail=1
    fi
    [[ -x "${ROOT}/bin/velxio" ]] || { log "MISS: bin/velxio"; fail=1; }

    # QEMU-lcgamboa is a soft DragonSDR dependency (offline Velxio Docker builds, future emulators)
    local qemu_dir="${QEMU_LCGAMBOA_DIR:-$HOME/Applications/QEMU-lcgamboa}"
    if [[ -L "$qemu_dir/current" && -d "$qemu_dir/current/lib" ]]; then
      log "OK: QEMU-lcgamboa"
    else
      log "MISS: QEMU-lcgamboa (soft — run tools/emulators/qemu-lcgamboa/build-all.sh)"
      # non-fatal; Velxio can fall back to license key or network download
    fi
  fi
  if [[ "$fail" -eq 0 ]]; then
    log "All suite checks passed."
  else
    log "Some suite checks failed."
    return 1
  fi
}

install_emulators() {
  log "Embedded emulators (Renode + Velxio) — on by default"
  chmod +x "${ROOT}/tools/emulators/install-"*.sh 2>/dev/null || true
  # Non-fatal soft fail for network blips: record status, still verify later
  if ! "${ROOT}/tools/emulators/install-renode.sh" 2>&1 | tee -a "$LOG"; then
    log "WARN: Renode install reported errors (see log)"
  fi
  if ! "${ROOT}/tools/emulators/install-velxio.sh" 2>&1 | tee -a "$LOG"; then
    log "WARN: Velxio install reported errors (see log)"
  fi
  log "  launch: ${ROOT}/bin/renode"
  log "  launch: ${ROOT}/bin/velxio"
  log "  docs:   ${ROOT}/tools/emulators/README.md"
}

install_apt() {
  command -v apt-get >/dev/null || die "apt-get not found — is this Ubuntu/Debian?"
  [[ "$(id -u)" -eq 0 ]] && die "Run as normal user; script will call sudo for apt."

  export DEBIAN_FRONTEND=noninteractive
  if [[ "${SKIP_HAM:-0}" != 1 ]]; then
    echo 'xastir xastir/install-setuid boolean false' | sudo debconf-set-selections
  fi

  log "apt update"
  sudo apt-get update -qq

  log "Installing suite packages (${#APT_SUITE[@]})"
  sudo apt-get install -y "${APT_SUITE[@]}"
}

clone_if_missing() {
  local url="$1" name="$2"
  if [[ -d "${HACKRF_HOME}/repos/${name}/.git" ]]; then
    log "  skip clone $name"
  else
    git clone --depth 1 "$url" "${HACKRF_HOME}/repos/${name}"
  fi
}

install_hackrf() {
  mkdir -p "${HACKRF_HOME}/repos" "${HACKRF_HOME}/releases" "${HACKRF_HOME}/sd-card"

  log "Clone HackRF / Mayhem / URH / hacktv repos"
  clone_if_missing https://github.com/greatscottgadgets/hackrf.git hackrf
  clone_if_missing https://github.com/portapack-mayhem/mayhem-firmware.git mayhem-firmware
  clone_if_missing https://github.com/sharebrained/portapack-hackrf.git portapack-hackrf
  clone_if_missing https://github.com/jopohl/urh.git urh
  clone_if_missing https://github.com/fsphil/hacktv.git hacktv
  if [[ ! -f "${HACKRF_HOME}/repos/mayhem-firmware/hackrf/firmware/CMakeLists.txt" ]]; then
    git -C "${HACKRF_HOME}/repos/mayhem-firmware" submodule update --init --recursive
  fi

  if [[ "${SKIP_HACKRF_BUILD:-0}" != 1 ]]; then
    log "Build HackRF host tools"
    # Always start from a clean build tree to avoid stale CMakeCache.txt
    # from a previous build in a different source tree (e.g. IndianaDell).
    rm -rf "${HACKRF_HOME}/build"
    mkdir -p "${HACKRF_HOME}/build"
    cmake -S "${HACKRF_HOME}/repos/hackrf/host" -B "${HACKRF_HOME}/build" \
      -DCMAKE_INSTALL_PREFIX="${HACKRF_HOME}/local"
    cmake --build "${HACKRF_HOME}/build" -j"$(nproc)"
  fi

  log "Mayhem firmware + SD card assets"
  chmod +x "${HACKRF_HOME}/scripts/"*.sh 2>/dev/null || true
  "${HACKRF_HOME}/scripts/download-mayhem.sh" 2>&1 | tee -a "$LOG"
  "${HACKRF_HOME}/scripts/prepare-sdcard.sh" 2>&1 | tee -a "$LOG"

  log "URH virtualenv"
  if [[ ! -x "${HACKRF_HOME}/venv-urh/bin/urh" ]]; then
    python3 -m venv "${HACKRF_HOME}/venv-urh"
    "${HACKRF_HOME}/venv-urh/bin/pip" install -U pip wheel
    "${HACKRF_HOME}/venv-urh/bin/pip" install urh
  else
    log "  URH venv already present"
  fi

  log "udev rules"
  "${HACKRF_HOME}/scripts/setup-udev.sh" 2>&1 | tee -a "$LOG"
}

if [[ "$VERIFY_ONLY" -eq 1 ]]; then
  : >"$LOG"
  verify_suite
  exit $?
fi

: >"$LOG"
log "DragonSDR suite install starting (ROOT=$ROOT)"

if [[ "$EMULATORS_ONLY" -eq 1 ]]; then
  install_emulators
elif [[ "$HACKRF_ONLY" -eq 1 ]]; then
  install_hackrf
elif [[ "$APT_ONLY" -eq 1 ]]; then
  install_apt
else
  install_apt
  install_hackrf
  if [[ "${SKIP_EMULATORS:-0}" != 1 ]]; then
    install_emulators
  else
    log "SKIP_EMULATORS=1 — skipping Renode/Velxio"
  fi
fi

log "Verify"
if verify_suite; then
  log "Suite install complete."
  log "  source ${HACKRF_HOME}/scripts/env.sh"
  log "  ${ROOT}/bin/urh"
  if [[ "${SKIP_EMULATORS:-0}" != 1 ]]; then
    log "  ${ROOT}/bin/renode"
    log "  ${ROOT}/bin/velxio"
  fi
  log "  Full app stack (OpenWebRX, SDR++, …): see ${ROOT}/README.md"
else
  die "Install finished with verification failures — see $LOG"
fi
