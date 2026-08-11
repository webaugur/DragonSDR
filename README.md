# DragonSDR

Thin meta-repo for a local collection of SDR tools, install helpers, and notes.

**This git tree does not vendor huge upstream clones.** Those live beside this repo on disk (or as optional checkouts). Install/runtime helpers for OpenWebRX are in a dedicated repo.

## Suite install (apt + HackRF/Mayhem + URH)

IndianaDell and other lab machines should install the SDR stack from **here**, not from workstation-specific repos.

```bash
# Full suite: apt SDR/ham, HackRF/Mayhem/URH, udev, + Renode/Velxio emulators (default on)
~/Documents/DragonSDR/bin/install-suite

# Variants
~/Documents/DragonSDR/bin/install-suite --verify-only
~/Documents/DragonSDR/bin/install-suite --apt-only
~/Documents/DragonSDR/bin/install-suite --emulators-only   # Renode + Velxio only
SKIP_HACKRF_BUILD=1 ~/Documents/DragonSDR/bin/install-suite
SKIP_HAM=1 ~/Documents/DragonSDR/bin/install-suite         # skip fldigi/wsjtx/etc.
SKIP_EMULATORS=1 ~/Documents/DragonSDR/bin/install-suite   # skip Renode/Velxio
SKIP_NEC=1 ~/Documents/DragonSDR/bin/install-suite         # skip nec2c/xnec2c
SKIP_RE=1 ~/Documents/DragonSDR/bin/install-suite          # skip FOSS RE tools
SKIP_SX1262_CHIRP=1 ~/Documents/DragonSDR/bin/install-suite  # skip ibelinp/SX1262_CHIRP
```

| Path | Role |
|------|------|
| `tools/install-suite.sh` | End-to-end suite installer |
| `tools/package-lists.sh` | Apt package arrays (`APT_SDR`, `APT_HAM`, `APT_RE`, …) |
| `tools/re/` | FOSS RE tools (radare2, binwalk, …) + optional $0 freeware notes |
| `tools/install-deps.sh` | Per-upstream compile/runtime deps |
| `hackrf/` | HackRF host tools, PortaPack Mayhem, URH workspace |
| `tools/emulators/` | Renode + Velxio (on by default with suite install) |
| `ibelinp/SX1262_CHIRP/` | SX1262 GPS-locked chirp radar notebook (**optional, default-on**) |
| `bin/hackrf-*`, `bin/urh` | Launchers for Mayhem / URH |
| `bin/renode`, `bin/velxio` | Embedded emulator launchers |
| `nec-tools/` | NEC-2 modeling ([webaugur/nec-tools](https://github.com/webaugur/nec-tools) private) |
| `mma-tools/` | MMANA-GAL (MININEC) Wine install, manuals, NearField Viewer |
| `bin/xnec2c`, `bin/nec2c`, `bin/nec2++` | Antenna NEC launchers |

```bash
source ~/Documents/DragonSDR/bin/hackrf-env
hackrf_info
~/Documents/DragonSDR/bin/urh
```

### Antenna modeling

```bash
# Native NEC-2 (default suite installs nec2c + xnec2c)
~/Documents/DragonSDR/nec-tools/install-nec.sh   # also builds necpp (nec2++)
~/Documents/DragonSDR/nec-tools/smoke-nec.sh     # P0–P3 smoke
python3 ~/Documents/DragonSDR/nec-tools/python/compare_engines.py \
  ~/Documents/DragonSDR/nec-tools/examples/dipole.nec
python3 ~/Documents/DragonSDR/nec-tools/python/maa_to_nec.py \
  ~/Documents/DragonSDR/nec-tools/examples/dipole.maa
python3 ~/Documents/DragonSDR/nec-tools/python/optimize_dipole.py --freq 14.1
python3 ~/Documents/DragonSDR/nec-tools/python/optimize_yagi.py --freq 146

# MMANA .maa libraries (GitHub + local MMANA ANT/)
~/Documents/DragonSDR/Models/Antenna/import-antenna-models.sh
# optional: --convert --index --link-wine

# MININEC / MMANA-GAL under Wine
~/Documents/DragonSDR/mma-tools/install/install-all.sh
```

## Repos (webaugur)

| Repo | Role |
|------|------|
| [webaugur/openwebrx](https://github.com/webaugur/openwebrx) `develop` | OpenWebRX fork: Leaflet maps by default, Google optional, importlib fix |
| [webaugur/openwebrx-local](https://github.com/webaugur/openwebrx-local) | Prefix install scripts, launcher, decoder one-shot build |
| [webaugur/DragonSDR](https://github.com/webaugur/DragonSDR) (this repo) | Index / layout / pointers only |
| [webaugur/SDRPlusPlus](https://github.com/webaugur/SDRPlusPlus) `dragonsdr-build-fixes` | SDR++ modern toolchain / decoder module fixes |
| [webaugur/sdrpp-vhfvoiceradio](https://github.com/webaugur/sdrpp-vhfvoiceradio) `dragonsdr-build-fixes` | NFM/DSD module build fixes |
| [webaugur/sdrpp-tetra-demodulator](https://github.com/webaugur/sdrpp-tetra-demodulator) `dragonsdr-build-fixes` | TETRA module CMake fixes |
| [webaugur/sdrpp-inmarsatc-demodulator](https://github.com/webaugur/sdrpp-inmarsatc-demodulator) `dragonsdr-build-fixes` | Inmarsat-C module CMake fixes |
| [webaugur/sdrpp_cospas_sarsat](https://github.com/webaugur/sdrpp_cospas_sarsat) `dragonsdr-build-fixes` | Cospas-Sarsat module fix |
| [webaugur/habdec](https://github.com/webaugur/habdec) `dragonsdr-build-fixes` | HAB RTTY decoder modern C++ fixes |
| [webaugur/ZeroMQPlugin](https://github.com/webaugur/ZeroMQPlugin) `dragonsdr-build-fixes` | SigDigger ZeroMQ plugin local path tweak |
| [webaugur/SigDigger](https://github.com/webaugur/SigDigger) | Existing SigDigger fork (build artifacts stay local) |
| [webaugur/radtel-950-pro](https://github.com/webaugur/radtel-950-pro) | Radtel RT-950 Pro tooling / experiments |
| [webaugur/lcarsde](https://github.com/webaugur/lcarsde) | LCARS desktop environment (task-oriented UI shell) |

## TUI utilities (Rust, optional checkouts)

Task-oriented / operator tooling to pair with SDR apps and lcarsde launchers.

| Tool | Upstream | Local path | Role |
|------|----------|------------|------|
| **binsider** | [orhun/binsider](https://github.com/orhun/binsider) | `orhun/binsider/` | ELF binary analysis TUI (RE companion to Ghidra) |
| **scope-tui** | [alemidev/scope-tui](https://github.com/alemidev/scope-tui) | `alemidev/scope-tui/` | Terminal oscilloscope / vectorscope / spectroscope (audio) |
| **openapi-tui** | [zaghaghi/openapi-tui](https://github.com/zaghaghi/openapi-tui) | `zaghaghi/openapi-tui/` | Browse & call OpenAPI-described HTTP APIs |
| **csvlens** | [YS-L/csvlens](https://github.com/YS-L/csvlens) | `YS-L/csvlens/` | Interactive CSV viewer / pager |

```bash
# clones (already laid out under DragonSDR)
git clone https://github.com/orhun/binsider.git orhun/binsider
git clone https://github.com/alemidev/scope-tui.git alemidev/scope-tui
git clone https://github.com/zaghaghi/openapi-tui.git zaghaghi/openapi-tui
git clone https://github.com/YS-L/csvlens.git YS-L/csvlens

# install to ~/.cargo/bin (needs recent Rust, e.g. 1.88+ for some crates)
cargo install --path orhun/binsider
cargo install --path alemidev/scope-tui
cargo install --path zaghaghi/openapi-tui
cargo install --path YS-L/csvlens
```

Ensure `~/.cargo/bin` is on `PATH`. Examples: `binsider ./some.elf`, `csvlens data.csv`, `openapi-tui -i openapi.yaml`, `scope-tui` (PipeWire/ALSA audio).

## 3D reconstruction (GPU service)

| Tool | Upstream | Local path | Runtime (Thumper) |
|------|----------|------------|-------------------|
| **LingBot-Map** | [Robbyant/lingbot-map](https://github.com/Robbyant/lingbot-map) | `Robbyant/lingbot-map/` | `~/Data/lingbot-map/` + viser `:8080` |

Streaming feed-forward 3D scene reconstruction from image folders or video. Needs CUDA GPU + ~5 GB checkpoint. Lab host **`user@thumper.local`** (TITAN Xp 12 GB, large `~/Data` pool) is the intended runtime.

```bash
# on thumper
cd ~/Documents/DragonSDR
./tools/lingbot-map/install.sh --download-model long
./tools/lingbot-map/serve.sh          # http://thumper.local:8080

# optional always-on viewer
cp tools/lingbot-map/lingbot-map.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now lingbot-map.service
```

Details, VRAM flags, and systemd notes: [`tools/lingbot-map/README.md`](tools/lingbot-map/README.md).

## Suggested disk layout

```text
~/Documents/DragonSDR/           # this meta-repo (thin + local trees)
  README.md
  bin/                           # install-suite, hackrf-*, urh
  tools/                         # install-suite.sh, package-lists, install-deps
  hackrf/                        # Mayhem/URH workspace (scripts tracked; repos local)
  openwebrx-local/               # clone of webaugur/openwebrx-local
  jketterl/openwebrx/            # clone of webaugur/openwebrx (develop)
  webaugur/radtel-950-pro/       # clone of webaugur/radtel-950-pro
  webaugur/lcarsde/              # LCARS DE (task UI)
  orhun/binsider/                # ELF TUI
  alemidev/scope-tui/            # audio scope TUI
  zaghaghi/openapi-tui/          # OpenAPI TUI
  YS-L/csvlens/                  # CSV TUI
  Robbyant/lingbot-map/          # streaming 3D recon (GPU; often only on Thumper)
  tools/lingbot-map/             # install + serve + systemd unit
  tools/emulators/               # Renode + Velxio installers / docs (suite default)
  tools/emulators/velxio/        # Velxio clone (gitignored bulk)
  ibelinp/SX1262_CHIRP/          # SX1262 chirp radar notes (suite default; gitignored)
  …other upstream trees…         # optional; gitignored here

~/Applications/OpenWebRX/        # runtime prefix (not in git)
  bin/ lib/ venv/ data/ openwebrx.conf
~/Applications/Renode/           # Renode portable (suite default)
~/Applications/Ghidra/           # Ghidra RE

# Thumper GPU runtime (not in git)
~/Data/lingbot-map/              # venv, models (~4.6G), outputs, lingbot-map.env
```

## OpenWebRX quick start

```bash
# helpers
git clone https://github.com/webaugur/openwebrx-local.git
# source (maps + fixes)
git clone -b develop https://github.com/webaugur/openwebrx.git jketterl/openwebrx

export OPENWEBRX_PREFIX=$HOME/Applications/OpenWebRX
# core connectors (needs csdr already in PREFIX)
./openwebrx-local/scripts/build-prefix-core.sh
# editable install
./openwebrx-local/scripts/install-openwebrx.sh "$(pwd)/jketterl/openwebrx"
# full mode stack (long)
./openwebrx-local/scripts/build-extra-decoders.sh

# run
./openwebrx-local/scripts/openwebrx-serve.sh
```

Desktop launcher should set `OPENWEBRX_PREFIX` and exec `openwebrx-local/scripts/openwebrx-serve.sh`.

## Applications (local installs)

Runtime prefixes under `~/Applications/` (not in git). Launchers set `LD_LIBRARY_PATH` / `PATH` for the prefix.

| App | Prefix | Launcher | Notes |
|-----|--------|----------|--------|
| OpenWebRX | `OpenWebRX/` | `openwebrx-local/scripts/openwebrx-serve.sh` | webaugur `develop` |
| SDR++ | `SDRPlusPlus/` | `sdrpp-launch.sh` | webaugur `dragonsdr-build-fixes` + community modules; see `MODULES.md` |
| SDRangel | `SDRangel/` | `sdrangel-launch.sh` | multi-device |
| SigDigger | `SigDigger/` | `SigDigger` wrapper | plugins via `SUSCAN_PLUGIN_PATH`; `BUILD.md` for OOT builds |
| habdec | `habdec/` | `habdec-launch.sh` | HAB RTTY; see `HAB.md` |
| AbracaDABra / qradiolink | respective dirs | `.desktop` | as installed |
| HackRF / Mayhem / URH | `hackrf/` | `bin/hackrf-*`, `bin/urh` | suite install; see `hackrf/MANIFEST.txt` |
| Radtel RT-950 Pro tools | (source) `webaugur/radtel-950-pro/` | — | HT / CPS tooling; see repo README |
| lcarsde | (source) `webaugur/lcarsde/` | — | LCARS desktop / task-oriented UI |
| binsider / scope-tui / openapi-tui / csvlens | cargo `~/.cargo/bin/` | from source trees above | Rust TUIs |
| Renode | `Renode/` | `bin/renode` | suite default; see `tools/emulators/` |
| Velxio | `tools/emulators/velxio/` | `bin/velxio` | suite default; Docker/npm for UI |
| LingBot-Map | `~/Data/lingbot-map/` (Thumper) | `tools/lingbot-map/serve.sh` | viser `:8080`; see `tools/lingbot-map/README.md` |

Generic helper: `openwebrx-local/scripts/app-launch.sh <PREFIX> <rel-bin>`.

### Device sharing

Only **one** process should open a given USB SDR at a time. Stop other SDR apps before starting another.

## Desktop (GNOME / Nautilus 50)

After changing `.desktop` files (on IndianaDell / Tower5810):

```bash
~/Documents/IndianaDell/scripts/gnome/fix-nautilus-desktop-launch.sh
~/Documents/IndianaDell/scripts/gnome/sync-desktop-icons.sh
```

## Called from IndianaDell

Workstation rebuild no longer vendors SDR apt lists or the HackRF tree. After core restore:

```bash
# From IndianaDell rebuild (default when DragonSDR is present)
#   or manually:
~/Documents/IndianaDell/bin/install-dragonsdr
# which runs:
~/Documents/DragonSDR/bin/install-suite
```

## Reverse engineering / disassembly

**Policy:** open-source / free-software tools are **suite defaults**; **$0 proprietary freeware** (IDA Free, Binary Ninja Free) is **opt-in only**; paid IDA/BN are out of scope.

| Default FOSS (`APT_RE`, unless `SKIP_RE=1`) | Role |
|---------------------------------------------|------|
| radare2 + iaito | CLI + GUI analysis |
| binwalk | Firmware carve/extract |
| capstone-tool (`cstool`) | Multi-arch disasm |
| gdb-multiarch | Multi-arch debug |
| edb-debugger | GUI debugger |
| nasm (`ndisasm`) | x86 flat disasm |
| objdump | Host binutils |

| Also FOSS lab tracks | Role |
|----------------------|------|
| Ghidra | Primary static RE / decompile |
| binsider | ELF TUI (`tools/re/install-re-tools.sh --cargo`) |
| Renode + GDB | Firmware emulation / step |

```bash
~/Documents/DragonSDR/tools/re/install-re-tools.sh --apt
~/Documents/DragonSDR/tools/re/smoke-re.sh
# Optional $0 proprietary (prints download instructions only):
~/Documents/DragonSDR/tools/re/install-re-tools.sh --ida-free
~/Documents/DragonSDR/tools/re/install-re-tools.sh --bn-free
```

Full matrix: `tools/re/README.md`

### Ghidra

- Install: `~/Applications/Ghidra/current` (12.1.2) + JDK 21  
- Launch: `~/Applications/Ghidra/ghidra-launch.sh`  
- Docs / plugins / scripts: `tools/ghidra/README.md`  
- Script Manager also loads `~/ghidra_scripts/` (LazyGhidra, findcrypt, ninja helpers, …)

## Embedded emulators (default suite option)

Velxio, Renode, and future emulators depend on a fully-offline QEMU build
(`lcgamboa/qemu` fork).  DragonSDR now treats this as a **soft required**
dependency (like Docker Compose):

- Builder: `tools/emulators/qemu-lcgamboa/build-all.sh`
- Pinned commit + target list live in the same directory.
- IndianaDell verification (`bin/fix-indianadell.sh --fix`) will see and
  optionally repair missing QEMU-lcgamboa via the DragonSDR hook.
- Output lands in `~/Applications/QEMU-lcgamboa/current/`.

Installed **by default** with `bin/install-suite` (opt out: `SKIP_EMULATORS=1`). Companion to Ghidra — simulate MCU/IoT boards without hardware.

| Tool | Role | Launch |
|------|------|--------|
| **Renode** | Multi-node system emulation, GDB, CI scripts | `bin/renode` → `~/Applications/Renode/` |
| **Velxio** | Local multi-board Arduino/ESP32/Pico simulator | `bin/velxio` (Docker/npm; tree under `tools/emulators/velxio/`) |

```bash
# Included in full suite install; or alone:
~/Documents/DragonSDR/bin/install-suite --emulators-only
~/Documents/DragonSDR/bin/renode
~/Documents/DragonSDR/bin/velxio
```

Docs: [`tools/emulators/README.md`](tools/emulators/README.md). **No Wokwi.**  
**ESP8266 note:** treat **ESP32 / ESP32-C3** as supported Wi‑Fi MCU targets; classic ESP8266 is not first-class in Renode/Velxio.

## SX1262 chirp radar (optional, installed by default)

[ibelinp/SX1262_CHIRP](https://github.com/ibelinp/SX1262_CHIRP) — experimenter’s notebook: use a Semtech **SX1262** as a GPSDO-locked linear-FM chirp source for coherent radar / dechirp work with an SDR.

| | |
|--|--|
| **Default** | Cloned by `bin/install-suite` → `ibelinp/SX1262_CHIRP/` |
| **Opt out** | `SKIP_SX1262_CHIRP=1` |
| **Tracked?** | No — under gitignored `ibelinp/` (local clone only) |
| **Plots** | `python3 ibelinp/SX1262_CHIRP/examples/chirp_plots.py` (needs `python3-numpy` / `scipy` / `matplotlib` from suite apt) |

```bash
# included in full suite install; or alone after clone:
git clone --depth 1 https://github.com/ibelinp/SX1262_CHIRP.git \
  ~/Documents/DragonSDR/ibelinp/SX1262_CHIRP
python3 ~/Documents/DragonSDR/ibelinp/SX1262_CHIRP/examples/chirp_plots.py
```

Read the upstream README for legal/safety notes before transmitting.

## License

Meta documentation: free to use.  
Each upstream project keeps its own license.
