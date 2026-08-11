# Antenna model sources

Imported by `import-antenna-models.sh`. Refresh dates are written when the script runs.

| Local directory | Upstream | Notes |
|-----------------|----------|--------|
| `bundled/` | Local MMANA-GAL Basic `ANT/` (Wine install) | Official ~400 models; copied only if install found |
| `handiko-AntennaFiles-OLD/` | https://github.com/handiko/AntennaFiles-OLD | Community MMANA `.maa` + some NEC |
| `handiko-Antenna-MMANA-NEC/` | https://github.com/handiko/Antenna-MMANA-NEC | Newer handiko models |
| `lonney9-Antenna-Models/` | https://github.com/lonney9/Antenna-Models | Ham antenna model collection |

## Policy

- Prefer **local fetch** over committing full trees (see `.gitignore`).
- Keep author/title lines inside each `.maa` file.
- Models are **not validated** by DragonSDR; MININEC (MMANA) ≠ NEC-2 results after conversion.
- Community repos: respect their README / license; personal/ham use only unless stated otherwise.

## Last import

_Run `./import-antenna-models.sh` to update this section automatically, or append notes below._

## Last successful import

- 2026-08-09T22:33Z (host Tower5810)
