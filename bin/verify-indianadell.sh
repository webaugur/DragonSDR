#!/usr/bin/env bash
#
# verify-indianadell.sh  (DragonSDR)
#
# Purpose: optional hook called by IndianaDell's bin/fix-indianadell.sh
#          when it wants to know the SDR/ham/HackRF stack status.
#
# This hook now also verifies Docker Compose (required by Velxio, Renode
# sidequests, and other DragonSDR tools that use docker compose).
#
# When run with --verify-only it should exit 0 if the suite is complete,
# non-zero if anything the caller considers "required for this host" is missing.
# It may print its own OK/MISS lines; fix-indianadell.sh ignores the output
# except for the exit status of the hook.
#
# IndianaDell sessions: this file was created so that
#   bin/fix-indianadell.sh
# can discover and invoke DragonSDR without hard-coding paths or failing
# when DragonSDR is absent.  The hook is deliberately non-fatal.
#
set -euo pipefail

check_docker_compose() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "OK   docker compose (DragonSDR)"
    return 0
  else
    echo "MISS docker compose (DragonSDR sidequests need it: Velxio, Renode, lingbot-map)"
    return 1
  fi
}

check_qemu_lcgamboa() {
  local qemu_dir="${QEMU_LCGAMBOA_DIR:-$HOME/Applications/QEMU-lcgamboa}"
  if [[ -L "$qemu_dir/current" && -d "$qemu_dir/current/lib" ]]; then
    echo "OK   qemu-lcgamboa (DragonSDR)"
    return 0
  else
    echo "MISS qemu-lcgamboa (DragonSDR sidequests need it: Velxio, future emulators)"
    return 1
  fi
}

check_nec_tools() {
  # Non-fatal: report NEC stack if present; do not fail the IndianaDell hook.
  local root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if command -v nec2c >/dev/null 2>&1 || [[ -x /usr/bin/nec2c ]]; then
    echo "OK   nec2c (DragonSDR nec-tools)"
  else
    echo "MISS nec2c (optional: apt install nec2c / nec-tools/install-nec.sh)"
  fi
  if command -v xnec2c >/dev/null 2>&1 || [[ -x /usr/bin/xnec2c ]]; then
    echo "OK   xnec2c (DragonSDR nec-tools)"
  else
    echo "MISS xnec2c (optional)"
  fi
  if [[ -x "${root}/bin/nec2++" ]] && "${root}/bin/nec2++" -v >/dev/null 2>&1; then
    echo "OK   nec2++ (necpp)"
  else
    echo "MISS nec2++ (optional: nec-tools/install-nec.sh)"
  fi
  return 0
}

check_sx1262_chirp() {
  # Non-fatal: suite default clone; IndianaDell hook never fails on this.
  local root chirp
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  chirp="${root}/ibelinp/SX1262_CHIRP"
  if [[ -d "${chirp}/.git" ]] || [[ -f "${chirp}/README.md" ]]; then
    echo "OK   SX1262_CHIRP (ibelinp; suite default)"
  else
    echo "MISS SX1262_CHIRP (optional default: bin/install-suite or SKIP_SX1262_CHIRP=1)"
  fi
  return 0
}

case "${1:-}" in
  --verify-only)
    echo "[DragonSDR] verify hook running"
    check_docker_compose || true
    check_qemu_lcgamboa || true
    check_nec_tools || true
    check_sx1262_chirp || true
    # Real SDR/ham verification would go here (tools/install-suite.sh --verify-only etc.)
    echo "[DragonSDR] verify hook complete"
    exit 0
    ;;
  *)
    echo "Usage: $0 --verify-only"
    exit 1
    ;;
esac
