# Reverse engineering tools (DragonSDR)

## Policy

| Category | Suite default? | Examples |
|----------|----------------|----------|
| **Open source / free software** | **Yes** | Ghidra, radare2, iaito, binwalk, Capstone, gdb-multiarch, edb, nasm/ndisasm, binsider, Renode |
| **$0 proprietary freeware** | **No** (opt-in only) | IDA Free, Binary Ninja Free (desktop) |
| **Paid commercial** | **Out of scope** | IDA Pro/Home paid, BN Commercial/Ultimate, etc. |

**Binary Ninja Cloud** is free but uploads binaries — **not recommended** for private firmware; doc link only.

## Default FOSS apt set (`APT_RE`)

Installed by `bin/install-suite` unless `SKIP_RE=1`:

| Package | Commands |
|---------|----------|
| radare2 | `r2`, `radare2` |
| iaito | `iaito` |
| binwalk | `binwalk` |
| capstone-tool | `cstool` |
| gdb-multiarch | `gdb-multiarch` |
| edb-debugger | `edb` |
| nasm | `ndisasm`, `nasm` |

Also part of the lab RE story (separate tracks):

- **Ghidra** — `tools/ghidra/`, `~/Applications/Ghidra/`
- **binsider** — cargo (`orhun/binsider/`)
- **objdump** — host `binutils` (via build deps)
- **Renode + GDB** — `tools/emulators/`

## Install

```bash
# Full suite (includes APT_RE)
~/Documents/DragonSDR/bin/install-suite

# RE apt packages only
~/Documents/DragonSDR/tools/re/install-re-tools.sh --apt

# binsider via cargo (if tree present)
~/Documents/DragonSDR/tools/re/install-re-tools.sh --cargo

# Optional $0 proprietary (not default; read license warnings)
~/Documents/DragonSDR/tools/re/install-re-tools.sh --ida-free   # prints download instructions
~/Documents/DragonSDR/tools/re/install-re-tools.sh --bn-free    # prints download instructions

# Smoke FOSS tools
~/Documents/DragonSDR/tools/re/smoke-re.sh
```

## Related docs

- Ghidra: `tools/ghidra/README.md`
- Radtel r2 workflow: `webaugur/radtel-950-pro/docs/rizin_setup.md`
