# DragonSDR

Thin meta-repo for a local collection of SDR tools, install helpers, and notes.

**This git tree does not vendor huge upstream clones.** Those live beside this repo on disk (or as optional checkouts). Install/runtime helpers for OpenWebRX are in a dedicated repo.

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

## Suggested disk layout

```text
~/Documents/DragonSDR/           # this meta-repo (thin)
  README.md
  openwebrx-local/               # clone of webaugur/openwebrx-local
  jketterl/openwebrx/            # clone of webaugur/openwebrx (develop)
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

Typical desktop apps under `~/Applications/` (not tracked here):

OpenWebRX, SDR++, SDRangel, AbracaDABra, qradiolink, habdec, SigDigger, HackRF tools, …

## Desktop (GNOME / Nautilus 50)

After changing `.desktop` files:

```bash
~/Documents/IndianaDell/scripts/gnome/fix-nautilus-desktop-launch.sh
~/Documents/IndianaDell/scripts/gnome/sync-desktop-icons.sh
```

## License

Meta documentation: free to use.  
Each upstream project keeps its own license.
