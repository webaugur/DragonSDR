#!/usr/bin/env bash
#
# install-deps.sh — Install Ubuntu packages required for a DragonSDR repo.
#
# Usage:
#   ./tools/install-deps.sh <org/repo>              # install compile (+ runtime) deps
#   ./tools/install-deps.sh --compile <org/repo>    # compile/dev packages only
#   ./tools/install-deps.sh --runtime <org/repo>    # runtime packages only
#   ./tools/install-deps.sh --dry-run <org/repo>    # print packages, do not install
#   ./tools/install-deps.sh --list                  # list known package keys
#   ./tools/install-deps.sh --all                   # install suite-wide compile+runtime lists
#   ./tools/install-deps.sh --all --compile         # suite-wide compile list only
#   ./tools/install-deps.sh --all --runtime         # suite-wide runtime list only
#
# Package keys match the local tree layout (e.g. BatchDrake/SigDigger).
# Dependency files live in tools/deps/<org>-<repo>.{compile,runtime}
# Suite-wide lists: Documentation/ubuntu-packages-{compile,runtime}.txt
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEPS_DIR="${SCRIPT_DIR}/deps"
DOC_DIR="${ROOT_DIR}/Documentation"

MODE="both"       # both | compile | runtime
DRY_RUN=0
DO_ALL=0
DO_LIST=0
TARGET=""

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \?//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --compile) MODE="compile"; shift ;;
    --runtime) MODE="runtime"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --all) DO_ALL=1; shift ;;
    --list) DO_LIST=1; shift ;;
    -*)
      echo "Unknown option: $1" >&2
      usage 1
      ;;
    *)
      if [[ -n "${TARGET}" ]]; then
        echo "Unexpected extra argument: $1" >&2
        usage 1
      fi
      TARGET="$1"
      shift
      ;;
  esac
done

# Convert deps key (org-repo with hyphens) back to org/repo by matching the local tree.
key_to_path() {
  local key="$1"
  local parts IFS='-'
  read -r -a parts <<< "$key"
  local i org repo
  for ((i = 1; i < ${#parts[@]}; i++)); do
    org="$(IFS='-'; echo "${parts[*]:0:i}")"
    repo="$(IFS='-'; echo "${parts[*]:i}")"
    if [[ -d "${ROOT_DIR}/${org}/${repo}" ]] || [[ -f "${DOC_DIR}/packages/${org}/${repo}.md" ]]; then
      echo "${org}/${repo}"
      return 0
    fi
  done
  # Fallback: first hyphen only
  echo "${key/-//}"
}

normalize_key() {
  # Accept: BatchDrake/SigDigger, BatchDrake-SigDigger, SigDigger (unique basename)
  local raw="$1"
  raw="${raw#./}"
  raw="${raw%/}"

  if [[ -f "${DEPS_DIR}/${raw//\//-}.compile" || -f "${DEPS_DIR}/${raw//\//-}.runtime" ]]; then
    echo "${raw//\//-}"
    return 0
  fi

  # Basename-only match if unique
  local matches=()
  local f base path
  for f in "${DEPS_DIR}"/*.compile; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f" .compile)"
    path="$(key_to_path "$base")"
    if [[ "${path##*/}" == "$raw" || "${base}" == "$raw" ]]; then
      matches+=("$base")
    fi
  done

  if [[ ${#matches[@]} -eq 1 ]]; then
    echo "${matches[0]}"
    return 0
  elif [[ ${#matches[@]} -gt 1 ]]; then
    echo "Ambiguous package name '${raw}'. Matches:" >&2
    for base in "${matches[@]}"; do
      printf '  %s\n' "$(key_to_path "$base")" >&2
    done
    return 1
  fi

  echo "No dependency list for '${raw}'." >&2
  echo "Run: $0 --list" >&2
  return 1
}

list_packages() {
  local f base
  echo "Known package keys (org/repo):"
  for f in "${DEPS_DIR}"/*.compile; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f" .compile)"
    printf '  %s\n' "$(key_to_path "$base")"
  done | sort -u
}

read_pkg_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  # Strip comments and blanks
  grep -vE '^\s*(#|$)' "$file" || true
}

collect_from_key() {
  local key="$1"
  local pkgs=()
  local p

  if [[ "$MODE" == "compile" || "$MODE" == "both" ]]; then
    while IFS= read -r p; do
      [[ -n "$p" ]] && pkgs+=("$p")
    done < <(read_pkg_file "${DEPS_DIR}/${key}.compile")
  fi
  if [[ "$MODE" == "runtime" || "$MODE" == "both" ]]; then
    while IFS= read -r p; do
      [[ -n "$p" ]] && pkgs+=("$p")
    done < <(read_pkg_file "${DEPS_DIR}/${key}.runtime")
  fi

  # De-duplicate while preserving order
  local seen="" out=()
  for p in "${pkgs[@]+"${pkgs[@]}"}"; do
    if [[ " ${seen} " != *" ${p} "* ]]; then
      out+=("$p")
      seen+=" ${p}"
    fi
  done
  printf '%s\n' "${out[@]+"${out[@]}"}"
}

collect_suite() {
  local pkgs=()
  local p
  if [[ "$MODE" == "compile" || "$MODE" == "both" ]]; then
    while IFS= read -r p; do
      [[ -n "$p" ]] && pkgs+=("$p")
    done < <(read_pkg_file "${DOC_DIR}/ubuntu-packages-compile.txt")
  fi
  if [[ "$MODE" == "runtime" || "$MODE" == "both" ]]; then
    while IFS= read -r p; do
      [[ -n "$p" ]] && pkgs+=("$p")
    done < <(read_pkg_file "${DOC_DIR}/ubuntu-packages-runtime.txt")
  fi
  local seen="" out=()
  for p in "${pkgs[@]+"${pkgs[@]}"}"; do
    if [[ " ${seen} " != *" ${p} "* ]]; then
      out+=("$p")
      seen+=" ${p}"
    fi
  done
  printf '%s\n' "${out[@]+"${out[@]}"}"
}

install_packages() {
  local -a pkgs=("$@")
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    echo "No packages to install."
    return 0
  fi

  echo "Packages (${#pkgs[@]}):"
  printf '  %s\n' "${pkgs[@]}"
  echo

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] sudo apt-get install -y ${pkgs[*]}"
    return 0
  fi

  if [[ "$(id -u)" -eq 0 ]]; then
    apt-get update
    apt-get install -y "${pkgs[@]}"
  else
    sudo apt-get update
    sudo apt-get install -y "${pkgs[@]}"
  fi
}

if [[ "$DO_LIST" -eq 1 ]]; then
  list_packages
  exit 0
fi

if [[ "$DO_ALL" -eq 1 ]]; then
  mapfile -t PKGS < <(collect_suite)
  install_packages "${PKGS[@]+"${PKGS[@]}"}"
  exit 0
fi

if [[ -z "${TARGET}" ]]; then
  echo "Error: specify <org/repo> or --all or --list" >&2
  usage 1
fi

KEY="$(normalize_key "${TARGET}")"
mapfile -t PKGS < <(collect_from_key "${KEY}")

# SigDigger stack also needs source deps built first — remind the user.
case "${KEY}" in
  BatchDrake-SigDigger|BatchDrake-SuWidgets|BatchDrake-AmateurDSN|BatchDrake-APTPlugin|BatchDrake-AntSDRPlugin|BatchDrake-ZeroMQPlugin)
    echo "Note: ${TARGET} also requires built/installed source libraries:"
    echo "  BatchDrake/sigutils → BatchDrake/suscan → BatchDrake/SuWidgets → BatchDrake/SigDigger"
    echo "  (plugins need SigDigger headers installed system-wide or via PREFIX)"
    echo
    ;;
  BatchDrake-suscan)
    echo "Note: suscan requires BatchDrake/sigutils to be built and installed first."
    echo
    ;;
esac

install_packages "${PKGS[@]+"${PKGS[@]}"}"
