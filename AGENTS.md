# Agent instructions (DragonSDR)

## Pull requests

- **Do not open, create, or draft GitHub pull requests** unless the user **explicitly** asks (e.g. “open a PR”, “create a PR”, “PR this”).
- Pushing branches to `webaugur/*` remotes is fine when the user wants changes saved.
- Prefer branch push + status summary over PR creation by default.

## Thumper GPU / LingBot-Map

Lab host **`user@thumper.local`** runs NVIDIA TITAN Xp. Dual-card power/clock locks, weak-cooler policy, and host inventory:

→ **`~/Documents/IndianaDell/docs/thumper-gpu.md`** (also IndianaDell `AGENTS.md`)

LingBot-Map install/serve: `tools/lingbot-map/README.md` and `~/Data/lingbot-map/` on Thumper.

## Lab AI assistant / Home Assistant (not this repo)

Voice C&C, KMC/Tuya lamps, and Thumper **McFloater master node** live in:

→ **`~/Documents/McFloater`** (`docs/thumper-master-node.md`, `deploy/thumper/`)

Do **not** add Home Assistant or smart-home stacks under DragonSDR.

---

## IndianaDell integration note (2026-07-, created by Grok session)

`bin/verify-indianadell.sh` (stub) was added so that
`~/Documents/IndianaDell/bin/fix-indianadell.sh --fix`
can discover and optionally invoke DragonSDR verification without
hard-coding paths or making the check fatal when DragonSDR is absent.
The hook is deliberately non-fatal and only called when the file is
executable.  Real SDR/ham/HackRF verification still lives in
`tools/install-suite.sh` (or `tools/package-lists.sh`).  Future sessions
that expand DragonSDR verification should keep the same filename so the
IndianaDell hook continues to work.