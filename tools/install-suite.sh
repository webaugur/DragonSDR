#!/usr/bin/env bash
# Install the DragonSDR suite: apt packages, HackRF/Mayhem workspace, URH venv.
#
# Usage:
#   ./tools/install-suite.sh                 # full suite
#   ./tools/install-suite.sh --verify-only
#   ./tools/install-suite.sh --apt-only
#   ./tools/install-suite.sh --hackrf-only
#   SKIP_HACKRF_BUILD=1 ./tools/install-suite.sh
#   SKIP_HAM=1 ./tools/install-suite.sh      # skip desktop ham apps
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

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }
die() { log "ERROR: $*"; exit 1; }

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \?//'
  exit "${1:-0}"
}

for arg in "$@"; do
  case "$arg" in
    --verify-only) VERIFY_ONLY=1 ;;
    --apt-only) APT_ONLY=1 ;;
    --hackrf-only) HACKRF_ONLY=1 ;;
    -h|--help) usage 0 ;;
    *) die "Unknown argument: $arg (try --help)" ;;
  esac
done

# shellcheck source=package-lists.sh
source "${SCRIPT_DIR}/package-lists.sh"

if [[ "${SKIP_HAM:-0}" == 1 ]]; then
  APT_SUITE=("${APT_SDR_BUILD[@]}" "${APT_SDR[@]}")
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
  [[ -x "${HACKRF_HOME}/venv-urh/bin/urh" ]] || { log "MISS: URH venv"; fail=1; }
  [[ -f "${HACKRF_HOME}/releases/FIRMWARE_mayhem_v2.4.0.zip" ]] || { log "MISS: Mayhem firmware zip"; fail=1; }
  [[ -d "${HACKRF_HOME}/sd-card/mayhem-v2.4.0/APPS" ]] || { log "MISS: Mayhem SD tree"; fail=1; }
  [[ -x "${HACKRF_HOME}/build/hackrf-tools/src/hackrf_sweep" ]] || { log "MISS: hackrf_sweep (built)"; fail=1; }
  if [[ "$fail" -eq 0 ]]; then
    log "All suite checks passed."
  else
    log "Some suite checks failed."
    return 1
  fi
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

if [[ "$HACKRF_ONLY" -eq 1 ]]; then
  install_hackrf
elif [[ "$APT_ONLY" -eq 1 ]]; then
  install_apt
else
  install_apt
  install_hackrf
fi

log "Verify"
if verify_suite; then
  log "Suite install complete."
  log "  source ${HACKRF_HOME}/scripts/env.sh"
  log "  ${ROOT}/bin/urh"
  log "  Full app stack (OpenWebRX, SDR++, …): see ${ROOT}/README.md"
else
  die "Install finished with verification failures — see $LOG"
fi
