# LingBot-Map (DragonSDR)

[Robbyant/lingbot-map](https://github.com/Robbyant/lingbot-map) — feed-forward **streaming 3D reconstruction** (Geometric Context Transformer). Interactive viewer via [viser](https://github.com/nerfstudio-project/viser) on port **8080**.

## Why Thumper

Inference needs a CUDA GPU and multi‑GB checkpoints (~4.6 GB each). Lab host **`thumper.local`** (`user@thumper.local`) has:

**Lab GPU policy / dual-card power locks:** see IndianaDell  
[`docs/thumper-gpu.md`](../../../IndianaDell/docs/thumper-gpu.md)  
(or on GitHub: `webaugur/IndianaDell` → `docs/thumper-gpu.md`). Prefer `CUDA_VISIBLE_DEVICES=0` for this demo if a second, poorly cooled TITAN Xp is installed.

| Resource | Value |
|----------|--------|
| GPU | NVIDIA TITAN Xp **12 GB** |
| Driver | 535.x (max reported CUDA **12.2**) |
| Disk for models | `~/Data` (ZFS, ~1.4 TB free) |
| Source tree | `~/Documents/DragonSDR/Robbyant/lingbot-map` |

Official upstream pins **PyTorch 2.8 + CUDA 12.8**. That needs a newer driver than Thumper’s 535, so our installer uses **torch 2.5.1 + cu121** and **`--use_sdpa`** (FlashInfer is optional / may not help on Pascal).

## Layout

```text
~/Documents/DragonSDR/
  Robbyant/lingbot-map/          # git clone (gitignored bulk)
  tools/lingbot-map/
    install.sh                   # venv + torch + pip -e + optional HF download
    serve.sh                     # demo.py launcher
    lingbot-map.service          # systemd --user unit
    README.md

~/Data/lingbot-map/              # runtime prefix (not in git)
  venv/
  models/lingbot-map-long.pt
  outputs/
  logs/
  lingbot-map.env
```

## Install on Thumper

```bash
ssh user@thumper.local
cd ~/Documents/DragonSDR

# ensure tools are present (rsync backup or git pull)
./tools/lingbot-map/install.sh --download-model long
```

Re-run `install.sh` to update the clone and reinstall editable package.

## Run once (interactive)

```bash
./tools/lingbot-map/serve.sh
# open http://thumper.local:8080

# custom sequence
./tools/lingbot-map/serve.sh --image_folder /path/to/frames --mask_sky
./tools/lingbot-map/serve.sh --video_path /path/to/clip.mp4 --fps 5 --mode windowed
```

Default scene is upstream `example/courthouse` with sky masking.

## Upload video / image sequences

There is **no browser upload** in the viser demo. Put media on Thumper’s disk, then point `serve.sh` at it.

**Drop folder:** `~/Data/lingbot-map/inputs/`

```bash
# from your laptop / Tower5810
scp mywalk.mp4 user@thumper.local:Data/lingbot-map/inputs/
# or a folder of frames (jpg/png)
rsync -aH ./frames/ user@thumper.local:Data/lingbot-map/inputs/mywalk_frames/

# on thumper — stop any previous demo first
pkill -f 'demo.py' || true
cd ~/Documents/DragonSDR

# video (fps = sample rate into the model, not source FPS)
./tools/lingbot-map/serve.sh \
  --video_path ~/Data/lingbot-map/inputs/mywalk.mp4 \
  --fps 5 \
  --first_k 120

# long clip: windowed mode
./tools/lingbot-map/serve.sh \
  --video_path ~/Data/lingbot-map/inputs/mywalk.mp4 \
  --fps 5 --mode windowed --window_size 64 --keyframe_interval 2

# pre-extracted frames
./tools/lingbot-map/serve.sh \
  --image_folder ~/Data/lingbot-map/inputs/mywalk_frames \
  --mask_sky
```

Tips for the TITAN Xp (12 GB): start with `--first_k 60` or `--fps 3` / `--stride 2` before full sequences. Outdoor scenes: add `--mask_sky`.

## systemd user service

```bash
mkdir -p ~/.config/systemd/user
cp ~/Documents/DragonSDR/tools/lingbot-map/lingbot-map.service \
   ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now lingbot-map.service
systemctl --user status lingbot-map.service
journalctl --user -u lingbot-map.service -f
```

Linger (survive logout):

```bash
sudo loginctl enable-linger "$USER"
```

Edit env without changing the unit:

```bash
$EDITOR ~/Data/lingbot-map/lingbot-map.env
systemctl --user restart lingbot-map.service
```

## VRAM tips (12 GB)

`lingbot-map.env` defaults:

- `--use_sdpa` — no FlashInfer
- `--offload_to_cpu` — keep predictions off GPU
- `--num_scale_frames 2` — lower activation peak
- `--camera_num_iterations 1` — faster camera head

If OOM: raise `--keyframe_interval`, use `--mode windowed`, lower image rate (`--fps` / `--stride`), or try the balanced checkpoint instead of `long`.

## Models

| Key | File | Notes |
|-----|------|--------|
| `long` | `lingbot-map-long.pt` | Best for long sequences (default service) |
| `balanced` | `lingbot-map.pt` | Paper / benchmark default |
| `stage1` | `lingbot-map-stage1.pt` | VGGT-style bidirectional |

From [Hugging Face `robbyant/lingbot-map`](https://huggingface.co/robbyant/lingbot-map).
