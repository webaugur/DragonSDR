# DragonSDR

Thin meta-repo for a local collection of SDR tools, install helpers, and notes.

**This git tree does not vendor huge upstream clones.** Those live beside this repo on disk (or as optional checkouts). Install/runtime helpers for OpenWebRX are in a dedicated repo.

## Suite install (apt + HackRF/Mayhem + URH)

IndianaDell and other lab machines should install the SDR stack from **here**, not from workstation-specific repos.

```bash
# Full suite: apt SDR/ham packages, HackRF host build, Mayhem assets, URH venv, udev
~/Documents/DragonSDR/bin/install-suite

# Variants
~/Documents/DragonSDR/bin/install-suite --verify-only
~/Documents/DragonSDR/bin/install-suite --apt-only
SKIP_HACKRF_BUILD=1 ~/Documents/DragonSDR/bin/install-suite
SKIP_HAM=1 ~/Documents/DragonSDR/bin/install-suite   # skip fldigi/wsjtx/etc.
```

| Path | Role |
|------|------|
| `tools/install-suite.sh` | End-to-end suite installer |
| `tools/package-lists.sh` | Apt package arrays (`APT_SDR`, `APT_HAM`, …) |
| `tools/install-deps.sh` | Per-upstream compile/runtime deps |
| `hackrf/` | HackRF host tools, PortaPack Mayhem, URH workspace |
| `bin/hackrf-*`, `bin/urh` | Launchers for Mayhem / URH |

```bash
source ~/Documents/DragonSDR/bin/hackrf-env
hackrf_info
~/Documents/DragonSDR/bin/urh
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
  …other upstream trees…         # optional; gitignored here

~/Applications/OpenWebRX/        # runtime prefix (not in git)
  bin/ lib/ venv/ data/ openwebrx.conf
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

## Ghidra (RE)

- Install: `~/Applications/Ghidra/current` (12.1.2) + JDK 21  
- Launch: `~/Applications/Ghidra/ghidra-launch.sh`  
- Docs / plugins / scripts: `tools/ghidra/README.md`  
- Script Manager also loads `~/ghidra_scripts/` (LazyGhidra, findcrypt, ninja helpers, …)

## License

Meta documentation: free to use.  
Each upstream project keeps its own license.
