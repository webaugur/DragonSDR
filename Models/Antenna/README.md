# Models/Antenna — MMANA `.maa` libraries

Local library of **MMANA-GAL antenna models** for DragonSDR, usable with:

1. **MMANA-GAL** (Wine) under `mma-tools/`
2. **NEC-2** tools via `nec-tools/python/maa_to_nec.py`

Full upstream trees are **fetched on demand** (not committed by default).

## Quick start

```bash
cd ~/Documents/DragonSDR/Models/Antenna

# Fetch GitHub libraries + copy official ANT/ if MMANA is installed
./import-antenna-models.sh

# GitHub only / MMANA only / also convert to .nec / rebuild index
./import-antenna-models.sh --github
./import-antenna-models.sh --from-mmana
./import-antenna-models.sh --github --convert --index
```

## Layout

| Path | Contents |
|------|----------|
| `bundled/` | Copy of local MMANA `ANT/` (when Wine install exists) |
| `handiko-AntennaFiles-OLD/` | Community `.maa` from handiko |
| `handiko-Antenna-MMANA-NEC/` | Newer handiko models |
| `lonney9-Antenna-Models/` | lonney9 collection |
| `converted/nec/` | Optional bulk NEC decks (`--convert`) |
| `index.csv` | Generated catalog (`--index`) |
| `_upstream/` | Raw git clones (staging) |

See [SOURCES.md](SOURCES.md) for URLs and policy.

## Open in MMANA-GAL

```bash
# After mma-tools Wine install:
# File → Open → browse to:
#   ~/Documents/DragonSDR/Models/Antenna/bundled/...
# or any handiko/lonney9 .maa

# Optional: expose library inside the Wine app tree
./import-antenna-models.sh --link-wine
```

## Convert one model to NEC-2

```bash
python3 ~/Documents/DragonSDR/nec-tools/python/maa_to_nec.py \
  Models/Antenna/handiko-AntennaFiles-OLD/some.maa \
  -o /tmp/model.nec

~/Documents/DragonSDR/bin/nec2c -i/tmp/model.nec
~/Documents/DragonSDR/bin/xnec2c /tmp/model.nec
```

Bulk:

```bash
./import-antenna-models.sh --convert --index
```

**Note:** Classic `nec2c` aborts if the **input path is very long**. Copy or symlink deep library paths to `/tmp/model.nec` before running `nec2c`, or open the file in **xnec2c** / use a short working directory.

## Warnings

- Many community models are experimental; check dimensions and ground settings.
- Conversion to NEC is **best-effort** (loads / complex ground incomplete) — see `nec-tools/docs/maa-to-nec.md`.
- **xnec2c “Theta > 90 with ground”:** old converted files used a full-sphere RP with ground. Re-run:
  ```bash
  maa-to-nec path/to/model.maa -o /tmp/model.nec   # ground models get θ≤90 RP
  # or refresh library converts:
  ./import-antenna-models.sh --convert
  ```
- Do not redistribute commercial PRO-only content.
