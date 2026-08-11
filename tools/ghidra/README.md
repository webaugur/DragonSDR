# Ghidra for DragonSDR

## Lab RE stack

| Tool | Role |
|------|------|
| **Ghidra** (this tree) | Primary static RE / decompile |
| **radare2** + **iaito** | CLI + GUI (suite default; see `tools/re/`) |
| **binwalk**, **cstool**, **ndisasm**, **edb**, **gdb-multiarch** | FOSS suite defaults (`APT_RE`) |
| **binsider** | ELF TUI companion (`orhun/binsider/`) |
| **objdump** | CLI disasm (binutils) |
| **Renode + GDB** | Dynamic debug with static RE |

**Policy:** FOSS tools are suite defaults. **$0 proprietary freeware** (IDA Free, Binary Ninja Free) is opt-in only via `tools/re/install-re-tools.sh`. Paid IDA/BN are out of scope.

See **`tools/re/README.md`** for install, smoke, and package notes.

## Install locations

| Path | Contents |
|------|----------|
| `~/Applications/Ghidra/current` | **Ghidra 12.1.2 PUBLIC** (symlink) |
| `~/Applications/Ghidra/ghidra-launch.sh` | Launcher (forces **JDK 21**) |
| `~/Documents/DragonSDR/tools/ghidra/downloads/` | Upstream Ghidra zip |
| `~/Documents/DragonSDR/tools/ghidra/extensions/` | Downloaded extension zips |
| `~/Applications/Ghidra/current/Ghidra/Extensions/` | **Installed** extensions |
| `~/Documents/DragonSDR/tools/ghidra/scripts/` | Cloned script collections |
| `~/ghidra_scripts/` | Symlinks for Ghidra Script Manager |

## Launch

```bash
~/Applications/Ghidra/ghidra-launch.sh
```

First run: if prompted to configure new extensions, enable the ones you want (Jython, MachineLearning, GhidraMCP, wasm, etc.).

## Official extensions installed (from Ghidra 12.1.2 bundle)

- **Jython** — Python 2.7 scripting in Ghidra  
- **MachineLearning** — ML-assisted analysis  
- **GnuDisassembler**  
- **BSimElasticPlugin** — BSim similarity (Elastic)  
- **Lisa**, **SampleTablePlugin**, **SleighDevTools**  
- **SymbolicSummaryZ3**  
- sample / bundle_examples  

## Community extensions installed

- **GhidraMCP** (LaurieWired) — MCP bridge for AI-assisted RE  
- **ghidra-wasm-plugin** — WebAssembly support  

> Note: Many older FindCrypt / CppClassAnalyzer release zips target Ghidra 10.x and may **not** load on 12.1.2. Sources are kept under `scripts/` for rebuild if needed.

## Script collections (in Script Manager via `~/ghidra_scripts`)

- LazyGhidra (Allsafe)  
- AllsafeGhidraScripts  
- ghidraninja_scripts  
- mich (0x6d696368) ghidra_scripts  
- ghidra-findcrypt source  
- Ghidrathon source (Mandiant; needs build for full Py3 — optional)

## RT-950 Pro workflow

1. Start Ghidra with the launcher above.  
2. New project → import  
   `~/Documents/DragonSDR/webaugur/radtel-950-pro/firmware/decrypted_v0.29.bin`  
3. Language: **ARM Cortex little-endian 32-bit**, base **`0x08000000`**, analyze.  
4. See also `webaugur/radtel-950-pro/docs/rizin_setup.md` and `docs/re_status.md`.

## Headless example

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
~/Applications/Ghidra/current/support/analyzeHeadless \
  /tmp/ghidra_projects RT950 \
  -import ~/Documents/DragonSDR/webaugur/radtel-950-pro/firmware/decrypted_v0.29.bin \
  -processor ARM:LE:32:Cortex \
  -loader BinaryLoader -loader-baseAddr 0x08000000 \
  -analysisTimeoutPerFile 600
```
