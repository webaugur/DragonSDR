# RE package notes

## Default FOSS (APT_RE)

Tested on Ubuntu 26.04-class:

| Package | Version example |
|---------|-----------------|
| radare2 | 6.0.7 |
| iaito | 6.0.7 |
| binwalk | 2.4.x |
| capstone-tool | provides `cstool` |
| gdb-multiarch | 17.x |
| edb-debugger | universe |
| nasm | provides `ndisasm` |

## Not in default apt (this distro)

| Tool | Why | Opt-in |
|------|-----|--------|
| rizin / cutter | Not in Ubuntu 26.04 apt here | Upstream releases via manual install |
| retdec / snowman | Rarely packaged | Manual |
| llvm-objdump | Full `llvm` meta is large | Use host `objdump` / install `llvm-*-tools` if needed |

## Optional $0 proprietary

| Tool | URL | Notes |
|------|-----|--------|
| IDA Free | https://hex-rays.com/ida-free | Non-commercial; limited arches |
| Binary Ninja Free | https://binary.ninja/free/ | Non-commercial; limited arches; no full API |
| BN Cloud | https://cloud.binary.ninja/ | **Uploads binaries** — avoid private firmware |

Paid IDA / BN editions are out of scope for DragonSDR.
