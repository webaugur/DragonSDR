#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/install-renode.sh"
"$HERE/install-velxio.sh"
echo
echo "Both emulator sidequests installed (see tools/emulators/README.md)."
