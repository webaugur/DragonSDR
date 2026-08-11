#!/usr/bin/env bash
# Smoke FOSS RE tools only (suite default set).
set -euo pipefail

fail=0
check() {
  local c="$1"
  if command -v "$c" >/dev/null 2>&1; then
    echo "OK   $c ($(command -v "$c"))"
  else
    echo "MISS $c"
    fail=1
  fi
}

echo "=== FOSS RE smoke (default suite tools) ==="
check radare2
check r2
check iaito
check binwalk
check cstool
check gdb-multiarch
check ndisasm
if command -v edb >/dev/null 2>&1 || command -v edb-debugger >/dev/null 2>&1; then
  echo "OK   edb"
else
  echo "MISS edb"
  fail=1
fi
check objdump

echo "=== Soft (not required for smoke exit) ==="
command -v binsider >/dev/null 2>&1 && echo "OK   binsider" || echo "SOFT binsider"
[[ -x "${HOME}/Applications/Ghidra/ghidra-launch.sh" || -d "${HOME}/Applications/Ghidra/current" ]] \
  && echo "OK   Ghidra layout" || echo "SOFT Ghidra"
command -v renode >/dev/null 2>&1 || [[ -x "${HOME}/Applications/Renode/renode-launch.sh" ]] \
  && echo "OK   Renode layout" || echo "SOFT Renode"

echo "=== versions (best effort) ==="
r2 -v 2>&1 | head -1 || true
binwalk --help 2>&1 | head -1 || true
cstool -v 2>&1 | head -1 || true
gdb-multiarch --version 2>&1 | head -1 || true
ndisasm -v 2>&1 | head -1 || true

exit "$fail"
