#!/usr/bin/env bash
# Launch LingBot-Map interactive viser demo (demo.py).
#
# Defaults suit thumper.local (TITAN Xp 12 GB): SDPA, CPU offload, lean scale frames.
#
# Usage:
#   ./tools/lingbot-map/serve.sh
#   ./tools/lingbot-map/serve.sh --image_folder /path/to/frames --mask_sky
#   LINGBOT_MAP_PORT=8081 ./tools/lingbot-map/serve.sh --video_path clip.mp4 --fps 5
set -euo pipefail

PREFIX="${LINGBOT_MAP_PREFIX:-$HOME/Data/lingbot-map}"
ENV_FILE="${LINGBOT_MAP_ENV:-$PREFIX/lingbot-map.env}"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a; source "$ENV_FILE"; set +a
fi

SRC="${LINGBOT_MAP_SRC:-$HOME/Documents/DragonSDR/Robbyant/lingbot-map}"
VENV="${LINGBOT_MAP_VENV:-$PREFIX/venv}"
MODEL="${LINGBOT_MAP_MODEL:-$PREFIX/models/lingbot-map-long.pt}"
PORT="${LINGBOT_MAP_PORT:-8080}"
# Extra defaults from env (word-split intentionally)
# shellcheck disable=SC2206
EXTRA=( ${LINGBOT_MAP_EXTRA_ARGS:---use_sdpa --offload_to_cpu --num_scale_frames 2 --camera_num_iterations 1} )

if [[ ! -x "$VENV/bin/python" ]]; then
  echo "ERROR: venv missing at $VENV — run tools/lingbot-map/install.sh first" >&2
  exit 1
fi
if [[ ! -f "$MODEL" ]]; then
  echo "ERROR: model not found: $MODEL" >&2
  echo "  run: tools/lingbot-map/install.sh --download-model long" >&2
  exit 1
fi
if [[ ! -f "$SRC/demo.py" ]]; then
  echo "ERROR: demo.py not found under $SRC" >&2
  exit 1
fi

# Default scene if caller passes no input flags
HAS_INPUT=0
for a in "$@"; do
  case "$a" in
    --image_folder|--video_path) HAS_INPUT=1 ;;
  esac
done

DEFAULT_SCENE=()
if [[ "$HAS_INPUT" -eq 0 ]]; then
  if [[ -d "$SRC/example/courthouse" ]]; then
    DEFAULT_SCENE=(--image_folder "$SRC/example/courthouse" --mask_sky)
  else
    echo "ERROR: no --image_folder/--video_path and no example/courthouse" >&2
    exit 1
  fi
fi

cd "$SRC"
export PYTHONUNBUFFERED=1
# Helpful for remote lab access; viser binds based on its own defaults + --port
echo "LingBot-Map demo → http://$(hostname -f 2>/dev/null || hostname):${PORT}/"
echo "  model=$MODEL"
echo "  src=$SRC"
echo "  python=$VENV/bin/python"

exec "$VENV/bin/python" demo.py \
  --model_path "$MODEL" \
  --port "$PORT" \
  "${EXTRA[@]}" \
  "${DEFAULT_SCENE[@]}" \
  "$@"
