# Embedded emulators (DragonSDR — on by default)

Companion track to **Ghidra** (`tools/ghidra/`): simulate MCU / IoT boards without hardware, debug firmware, and stage multi-node setups before flashing HackRF-adjacent gadgets, sensors, or radio-related ESP firmware.

**Suite integration:** `bin/install-suite` runs Renode + Velxio installers unless `SKIP_EMULATORS=1`. Standalone: `install-all.sh` or `install-suite --emulators-only`. **Wokwi is not used.**

| Tool | Upstream | Role |
|------|----------|------|
| **Renode** | [renode/renode](https://github.com/renode/renode) · [renode.io](https://renode.io/) | Antmicro open-source **system emulation** — multi-node, GDB, CI-friendly `.resc` scripts |
| **Velxio** | [davidmonterocrespo24/velxio](https://github.com/davidmonterocrespo24/velxio) · [velxio.dev](https://velxio.dev/) | Local/browser **multi-board** Arduino/ESP32/Pico/etc. simulator with interactive components |

## Board / SoC honesty (ESP8266)

| Family | Renode | Velxio |
|--------|--------|--------|
| **ESP32 / ESP32-S3** (Xtensa) | Good community / platform coverage; multi-node Wi‑Fi stories | Emulated (QEMU backend in v2) |
| **ESP32-C3** (RISC-V) | Growing RISC-V support | First-class in Velxio 2.x |
| **ESP8266** (Xtensa LX106) | **Limited / not first-class** — prefer ESP32 stand-in, or bring your own platform definition | **Not** classic 8266; use ESP32 / C3 for Wi‑Fi MCU workflows |

For “simulate ESP8266-class IoT” in the lab, treat **ESP32 / ESP32-C3** as the supported emulated targets, and use **real 8266 hardware** (or Ghidra on dumps) when the silicon must match exactly.

## Install locations

| Path | Contents |
|------|----------|
| `~/Applications/Renode/current` | Renode portable install (symlink) |
| `~/Applications/Renode/renode-launch.sh` | Launcher |
| `~/Documents/DragonSDR/tools/emulators/downloads/` | Upstream tarballs (gitignored bulk) |
| `~/Documents/DragonSDR/tools/emulators/velxio/` | Optional local clone of Velxio |
| `~/Documents/DragonSDR/tools/emulators/examples/` | Lab `.resc` / notes |
| `~/Documents/DragonSDR/bin/renode` · `bin/velxio` | Suite launchers |

## Quick install

```bash
# Preferred: full suite (emulators included by default)
~/Documents/DragonSDR/bin/install-suite

# Emulators only
~/Documents/DragonSDR/bin/install-suite --emulators-only
# or:
~/Documents/DragonSDR/tools/emulators/install-all.sh

# Opt out of emulators during suite install
SKIP_EMULATORS=1 ~/Documents/DragonSDR/bin/install-suite
```

## Launch

```bash
~/Documents/DragonSDR/bin/renode
# or
~/Applications/Renode/renode-launch.sh

~/Documents/DragonSDR/bin/velxio
# opens local stack if running, else prints URL / docker instructions
```

## Renode — first run

```bash
renode
# In the Monitor:
(monitor) include @scripts/single-node/stm32f4_discovery.resc
# or load a platform from Renode's built-in scripts/
```

GDB attach (typical):

```text
(machine-0) machine StartGdbServer 3333
# other terminal:
arm-none-eabi-gdb your.elf
(gdb) target remote :3333
```

Pair with Ghidra: reverse the same `.elf` / flash image under `tools/ghidra/`, then step in Renode.

## Velxio — first run

Velxio is primarily a **local web app** (frontend + backend). After `install-velxio.sh`:

```bash
cd ~/Documents/DragonSDR/tools/emulators/velxio
docker compose up
# or follow script output for npm/dev mode
```

Then open the printed URL (often `http://127.0.0.1:5173` or the compose-mapped port).  
Public hosted UI: [https://velxio.dev](https://velxio.dev) (lab preference: **local** clone for offline / private firmware).

## Lab use cases (SDR-adjacent)

- Firmware bring-up for ESP32-based telemetry / sensors before RF tests  
- Multi-node timing and protocol scripts in Renode (CI later)  
- Interactive Arduino/ESP sketches in Velxio without juggling boards  
- RE loop: **Ghidra** analyze ↔ **Renode** execute  

## Relation to other suite pieces

| Piece | Link |
|-------|------|
| Ghidra | `tools/ghidra/README.md` |
| Radtel / HT firmware | `webaugur/radtel-950-pro/` (ARM; Renode/Ghidra, not ESP) |
| HackRF / Mayhem | real RF hardware — emulators do **not** replace the SDR |

## License

Renode and Velxio keep their upstream licenses (see their repos). DragonSDR only ships install helpers and notes.
