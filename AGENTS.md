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

## Desktop launchers in ~/Applications

After creating or modifying any `.desktop` files under `~/Applications/`:

1. Run `~/Documents/IndianaDell/scripts/gnome/fix-nautilus-desktop-launch.sh`
   (restores double-click execution via the xdg-desktop-launch MIME handler).
2. Run `~/Documents/IndianaDell/scripts/gnome/sync-desktop-icons.sh --dir ~/Applications`
   (sets `metadata::custom-icon` from each file’s `Icon=` line so Nautilus shows branded icons).

Both scripts are required; the launcher fix alone does not update icon metadata.

## QEMU-lcgamboa shared-library builder — regression cost note (2026-07-25)

**Explicit requirement (repeatedly stated):**  
The DragonSDR QEMU builder (`tools/emulators/qemu-lcgamboa/build-all.sh`) must produce `libqemu-<arch>.so` shared libraries for **every** architecture listed in `targets.txt` in a single build run.  
- `xtensa` and `riscv32` must come from the `lcgamboa/picsimlab-esp32` fork’s own `build_libqemu-esp32.sh` (Velxio / picsimlab API compatibility).  
- All other architectures must also produce working `.so` files at equal priority — no deferral, no fallback to plain `qemu-system-<arch>` executables.

**Observed regressions:**  
Multiple times the implementation regressed to building normal executables for non-ESP targets or marking shared-library support as “future work.” These changes directly violated the stated requirement.

**Impact:**  
These regressions have wasted nearly a quarter of the user’s week and incurred real monetary cost. Future sessions must treat the full shared-library requirement as non-negotiable and must not weaken or defer it when implementation difficulties arise.