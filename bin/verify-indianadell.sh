#!/usr/bin/env bash
#
# verify-indianadell.sh  (DragonSDR stub)
#
# Purpose: optional hook called by IndianaDell's bin/fix-indianadell.sh
#          when it wants to know the SDR/ham/HackRF stack status.
#
# This stub is intentionally minimal.  A full implementation lives in
# DragonSDR's own tooling (tools/install-suite.sh --verify-only or similar).
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

case "${1:-}" in
  --verify-only)
    # Real implementation would call:
    #   tools/install-suite.sh --verify-only
    # or iterate DragonSDR's package-lists.sh + bin/ launchers.
    # For now we simply report that DragonSDR decides its own completeness.
    echo "[DragonSDR] verify hook present (stub)"
    exit 0
    ;;
  *)
    echo "Usage: $0 --verify-only"
    exit 1
    ;;
esac
