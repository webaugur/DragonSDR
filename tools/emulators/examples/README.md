# Emulator examples (lab)

## Renode

After `install-renode.sh`, try built-in demos from the Renode tree:

```bash
~/Applications/Renode/renode-launch.sh
```

In the Monitor, tab-complete `include @scripts/` for single-node and multi-node samples.

Minimal smoke (headless-ish quit):

```bash
~/Documents/DragonSDR/bin/renode -e "quit"
```

### ESP notes

- Prefer **ESP32** platforms / community scripts when simulating Wi‑Fi MCU firmware.
- Classic **ESP8266** is not a first-class Renode product demo; use real silicon or an ESP32 stand-in for protocol work.

## Velxio

```bash
~/Documents/DragonSDR/bin/velxio
```

Pick ESP32 / ESP32-C3 boards in the UI for IoT-class workflows.

## Ghidra pairing

1. Load firmware in Ghidra (`tools/ghidra/README.md`).  
2. Build or extract the same image for Renode / flash layout.  
3. GDB from Renode ↔ symbols from the ELF you reverse.
