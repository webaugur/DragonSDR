#!/usr/bin/env bash
#
# install-re-tools.sh — FOSS RE tools (default) + optional $0 proprietary freeware
#
# Usage:
#   ./tools/re/install-re-tools.sh              # same as --apt
#   ./tools/re/install-re-tools.sh --apt
#   ./tools/re/install-re-tools.sh --cargo      # binsider if source tree present
#   ./tools/re/install-re-tools.sh --ida-free   # print IDA Free download (no auto-install)
#   ./tools/re/install-re-tools.sh --bn-free    # print BN Free download (no auto-install)
#   ./tools/re/install-re-tools.sh --all-foss   # apt + cargo
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../package-lists.sh
source "${ROOT}/tools/package-lists.sh"

DO_APT=0
DO_CARGO=0
DO_IDA=0
DO_BN=0
DO_DEFAULT=1

for arg in "$@"; do
  case "$arg" in
    --apt) DO_APT=1; DO_DEFAULT=0 ;;
    --cargo) DO_CARGO=1; DO_DEFAULT=0 ;;
    --ida-free) DO_IDA=1; DO_DEFAULT=0 ;;
    --bn-free) DO_BN=1; DO_DEFAULT=0 ;;
    --all-foss) DO_APT=1; DO_CARGO=1; DO_DEFAULT=0 ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

if [[ "$DO_DEFAULT" == 1 ]]; then
  DO_APT=1
fi

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

install_apt() {
  log "Installing FOSS RE packages: ${APT_RE[*]}"
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_RE[@]}"
  log "Done apt RE tools"
}

install_cargo() {
  local src="${ROOT}/orhun/binsider"
  if [[ ! -d "$src" ]]; then
    log "binsider source not found at $src — clone first:"
    log "  git clone https://github.com/orhun/binsider.git $src"
    return 0
  fi
  if ! command -v cargo >/dev/null 2>&1; then
    log "cargo not found; install Rust or skip --cargo"
    return 0
  fi
  log "cargo install --path $src"
  cargo install --path "$src"
  log "binsider → $(command -v binsider || echo '~/.cargo/bin/binsider')"
}

print_ida_free() {
  cat <<'EOF'
=== IDA Free (optional $0 proprietary — NOT suite default) ===

  URL:  https://hex-rays.com/ida-free
  License: non-commercial only; limited architectures
  Install: download from Hex-Rays, extract under ~/Applications/IDA-Free/ yourself
  DragonSDR will NOT auto-download proprietary installers.

  Prefer Ghidra + radare2 for lab work.
EOF
}

print_bn_free() {
  cat <<'EOF'
=== Binary Ninja Free (optional $0 proprietary — NOT suite default) ===

  Desktop Free: https://binary.ninja/free/
  Cloud Free:   https://cloud.binary.ninja/  (UPLOADS binaries — avoid private firmware)
  License: non-commercial / eval limits; Free desktop has arch/API limits
  Install: download from Vector 35 into ~/Applications/BinaryNinja-Free/ yourself
  DragonSDR will NOT auto-download proprietary installers.

  Prefer Ghidra + radare2 for lab work.
EOF
}

[[ "$DO_APT" == 1 ]] && install_apt
[[ "$DO_CARGO" == 1 ]] && install_cargo
[[ "$DO_IDA" == 1 ]] && print_ida_free
[[ "$DO_BN" == 1 ]] && print_bn_free

log "RE install finished. Smoke: ${SCRIPT_DIR}/smoke-re.sh"
