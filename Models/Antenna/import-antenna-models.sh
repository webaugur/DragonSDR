#!/usr/bin/env bash
#
# import-antenna-models.sh — fetch MMANA .maa libraries into Models/Antenna/
#
# Usage:
#   ./import-antenna-models.sh              # github + from-mmana if available
#   ./import-antenna-models.sh --github
#   ./import-antenna-models.sh --from-mmana
#   ./import-antenna-models.sh --convert --index
#   ./import-antenna-models.sh --link-wine
#   ./import-antenna-models.sh --all
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
UPSTREAM="${SCRIPT_DIR}/_upstream"
FAIL_LOG="${SCRIPT_DIR}/import-failures.log"
MAA_TO_NEC="${ROOT}/nec-tools/python/maa_to_nec.py"

DO_GITHUB=0
DO_MMANA=0
DO_CONVERT=0
DO_INDEX=0
DO_LINK=0
DO_DEFAULT=1

for arg in "$@"; do
  case "$arg" in
    --github) DO_GITHUB=1; DO_DEFAULT=0 ;;
    --from-mmana) DO_MMANA=1; DO_DEFAULT=0 ;;
    --convert) DO_CONVERT=1; DO_DEFAULT=0 ;;
    --index) DO_INDEX=1; DO_DEFAULT=0 ;;
    --link-wine) DO_LINK=1; DO_DEFAULT=0 ;;
    --all)
      DO_GITHUB=1
      DO_MMANA=1
      DO_CONVERT=1
      DO_INDEX=1
      DO_LINK=1
      DO_DEFAULT=0
      ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ "$DO_DEFAULT" == 1 ]]; then
  DO_GITHUB=1
  DO_MMANA=1
  DO_INDEX=1
fi

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

# name|git_url
GITHUB_LIBS=(
  "handiko-AntennaFiles-OLD|https://github.com/handiko/AntennaFiles-OLD.git"
  "handiko-Antenna-MMANA-NEC|https://github.com/handiko/Antenna-MMANA-NEC.git"
  "lonney9-Antenna-Models|https://github.com/lonney9/Antenna-Models.git"
)

find_mmana_ant() {
  local cand
  for cand in \
    "${HOME}/Applications/MMANA-GAL-3.5/drive_c/MMANA-GALBasic3/ANT" \
    "${HOME}/Applications/MMANA-GAL-3.5/drive_c/MMANA-GAL/ANT" \
    "${ROOT}/mma-tools/MMANA-GALBasic3/ANT"; do
    if [[ -d "$cand" ]]; then
      echo "$cand"
      return 0
    fi
  done
  # last resort: search under Wine prefix
  if [[ -d "${HOME}/Applications/MMANA-GAL-3.5/drive_c" ]]; then
    find "${HOME}/Applications/MMANA-GAL-3.5/drive_c" -type d -name ANT 2>/dev/null | head -1
  fi
}

clone_or_update() {
  local name="$1" url="$2"
  local dest="${UPSTREAM}/${name}"
  mkdir -p "$UPSTREAM"
  if [[ -d "${dest}/.git" ]]; then
    log "Updating ${name}"
    git -C "$dest" pull --ff-only 2>/dev/null || git -C "$dest" fetch --depth 1 origin 2>/dev/null || true
  else
    log "Cloning ${name}"
    git clone --depth 1 "$url" "$dest"
  fi
}

sync_maa_from_tree() {
  local name="$1" src="$2"
  local dest="${SCRIPT_DIR}/${name}"
  mkdir -p "$dest"
  # Copy only model files; preserve relative paths
  local count=0
  while IFS= read -r -d '' f; do
    rel="${f#"${src}/"}"
    mkdir -p "${dest}/$(dirname "$rel")"
    cp -n "$f" "${dest}/${rel}" 2>/dev/null || cp "$f" "${dest}/${rel}"
    count=$((count + 1))
  done < <(find "$src" -type f \( -iname '*.maa' -o -iname '*.nec' \) -print0 2>/dev/null)
  log "  ${name}: ${count} model files → ${dest}"
}

import_github() {
  log "=== GitHub libraries ==="
  local entry name url
  for entry in "${GITHUB_LIBS[@]}"; do
    name="${entry%%|*}"
    url="${entry#*|}"
    clone_or_update "$name" "$url"
    sync_maa_from_tree "$name" "${UPSTREAM}/${name}"
  done
}

import_mmana() {
  log "=== Bundled MMANA ANT/ ==="
  local ant
  ant="$(find_mmana_ant || true)"
  if [[ -z "${ant:-}" || ! -d "$ant" ]]; then
    log "No MMANA ANT/ found (install MMANA-GAL via mma-tools first)"
    return 0
  fi
  log "Source: $ant"
  mkdir -p "${SCRIPT_DIR}/bundled"
  rsync -a --delete \
    --include='*/' \
    --include='*.maa' --include='*.MAA' \
    --include='*.nec' --include='*.NEC' \
    --exclude='*' \
    "${ant}/" "${SCRIPT_DIR}/bundled/" 2>/dev/null \
    || {
      # fallback without rsync filters
      find "$ant" -type f \( -iname '*.maa' -o -iname '*.nec' \) -print0 \
        | while IFS= read -r -d '' f; do
            rel="${f#"${ant}/"}"
            mkdir -p "${SCRIPT_DIR}/bundled/$(dirname "$rel")"
            cp "$f" "${SCRIPT_DIR}/bundled/${rel}"
          done
    }
  local n
  n="$(find "${SCRIPT_DIR}/bundled" -type f -iname '*.maa' 2>/dev/null | wc -l)"
  log "  bundled/: ${n} .maa files"
}

convert_all() {
  log "=== Convert .maa → .nec ==="
  if [[ ! -f "$MAA_TO_NEC" ]]; then
    log "ERROR: maa_to_nec.py not found at $MAA_TO_NEC"
    return 1
  fi
  : >"$FAIL_LOG"
  local ok=0 fail=0
  while IFS= read -r -d '' maa; do
    rel="${maa#"${SCRIPT_DIR}/"}"
    # skip staging and already-converted
    [[ "$rel" == _upstream/* ]] && continue
    [[ "$rel" == converted/* ]] && continue
    # strip any extension once → single .nec (avoid .nec.nec)
    base="${rel%.*}"
    out="${SCRIPT_DIR}/converted/nec/${base}.nec"
    mkdir -p "$(dirname "$out")"
    if python3 "$MAA_TO_NEC" "$maa" -o "$out" --no-pattern >/dev/null 2>>"$FAIL_LOG"; then
      ok=$((ok + 1))
    else
      echo "FAIL $maa" >>"$FAIL_LOG"
      fail=$((fail + 1))
      rm -f "$out"
    fi
  done < <(find "${SCRIPT_DIR}" -type f -iname '*.maa' -print0 2>/dev/null)
  log "  convert: ok=${ok} fail=${fail} (see import-failures.log)"
}

build_index() {
  log "=== index.csv ==="
  local idx="${SCRIPT_DIR}/index.csv"
  echo "path,source,freq_mhz,n_wires,size_bytes" >"$idx"
  python3 - <<'PY' "$SCRIPT_DIR" "$idx"
import csv, sys
from pathlib import Path

root = Path(sys.argv[1])
idx_path = Path(sys.argv[2])
sys.path.insert(0, str(root.parents[1] / "nec-tools" / "python"))

try:
    from maa_to_nec import parse_maa
except Exception:
    parse_maa = None

rows = []
for maa in sorted(root.rglob("*.maa")):
    rel = maa.relative_to(root).as_posix()
    if rel.startswith("_upstream/") or rel.startswith("converted/"):
        continue
    source = rel.split("/", 1)[0] if "/" in rel else "."
    freq, nw = "", ""
    if parse_maa:
        try:
            raw = maa.read_bytes()
            try:
                text = raw.decode("utf-8")
            except UnicodeDecodeError:
                text = raw.decode("cp1251", errors="replace")
            model = parse_maa(text)
            freq = f"{model.freq_mhz:g}"
            nw = str(len(model.wires))
        except Exception:
            pass
    rows.append((rel, source, freq, nw, str(maa.stat().st_size)))

with idx_path.open("a", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    for r in rows:
        w.writerow(r)
print(f"  indexed {len(rows)} .maa files")
PY
}

link_wine() {
  log "=== Wine ANT/DragonSDR symlink ==="
  local ant
  ant="$(find_mmana_ant || true)"
  if [[ -z "${ant:-}" ]]; then
    log "No MMANA ANT/ — skip --link-wine"
    return 0
  fi
  local link="${ant}/DragonSDR"
  ln -sfn "${SCRIPT_DIR}" "$link"
  log "  $link → ${SCRIPT_DIR}"
}

append_sources_stamp() {
  local stamp
  stamp="$(date -u +%Y-%m-%dT%H:%MZ)"
  if ! grep -q "Last successful import:" "${SCRIPT_DIR}/SOURCES.md" 2>/dev/null; then
    printf '\n## Last successful import\n\n- %s (host %s)\n' "$stamp" "$(hostname 2>/dev/null || echo unknown)" \
      >>"${SCRIPT_DIR}/SOURCES.md"
  else
    # replace last import line block simply by appending
    printf -- '- %s (host %s)\n' "$stamp" "$(hostname 2>/dev/null || echo unknown)" \
      >>"${SCRIPT_DIR}/SOURCES.md"
  fi
}

# --- main ---
log "Models/Antenna import  ROOT=$ROOT"

[[ "$DO_GITHUB" == 1 ]] && import_github
[[ "$DO_MMANA" == 1 ]] && import_mmana
[[ "$DO_CONVERT" == 1 ]] && convert_all
[[ "$DO_INDEX" == 1 ]] && build_index
[[ "$DO_LINK" == 1 ]] && link_wine

append_sources_stamp

total="$(find "${SCRIPT_DIR}" -type f -iname '*.maa' ! -path '*/_upstream/*' ! -path '*/converted/*' 2>/dev/null | wc -l)"
log "Done. Total .maa outside _upstream/converted: ${total}"
log "See README.md for open-in-MMANA and NEC convert usage."
