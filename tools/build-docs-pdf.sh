#!/usr/bin/env bash
# Rebuild DragonSDR-Documentation.pdf from Documentation/ sources.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
python3 << 'PY'
from pathlib import Path
from datetime import date
import subprocess
import re

ROOT = Path(".").resolve()
DOC = ROOT / "Documentation"
OUT_MD = DOC / "_combined_for_pdf.md"
OUT_PDF = ROOT / "DragonSDR-Documentation.pdf"

def shift_headings(text: str, by: int = 1) -> str:
    def repl(m):
        hashes, rest = m.group(1), m.group(2)
        return "#" * min(len(hashes) + by, 6) + rest
    return re.sub(r"^(#{1,6})(\s+.*)$", repl, text, flags=re.M)

def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")

priority = [
    "BatchDrake/sigutils",
    "BatchDrake/suscan",
    "BatchDrake/SuWidgets",
    "BatchDrake/SigDigger",
    "BatchDrake/AmateurDSN",
    "BatchDrake/APTPlugin",
    "BatchDrake/AntSDRPlugin",
    "BatchDrake/ZeroMQPlugin",
    "SoapySDR/SoapySDR",
    "gnuradio/volk",
    "gnuradio/gnuradio",
]

pkg_map = {f"{p.parent.name}/{p.stem}": p for p in sorted(DOC.glob("packages/*/*.md"))}
ordered_keys = [k for k in priority if k in pkg_map]
for k in sorted(pkg_map, key=str.lower):
    if k not in ordered_keys:
        ordered_keys.append(k)

parts = []
parts.append(f"""---
title: "DragonSDR Documentation"
subtitle: "Radio tooling suite — package notes, dependencies, and Ubuntu package lists"
author: "DragonSDR workspace"
date: "{date.today().isoformat()}"
---

# Overview

This document consolidates the DragonSDR suite documentation: suite-wide Ubuntu
package lists and per-package notes (identity, source dependencies, compile and
runtime packages, inventory notes).

Source files live under `Documentation/`. Install helper: `tools/install-deps.sh`.

""")

readme = re.sub(r"^#\s+.*\n+", "", read(DOC / "README.md"), count=1)
# Avoid recursive PDF link noise in the printed overview
readme = re.sub(r"\*\*Combined PDF.*\n(?:Regenerate with:.*\n)?", "", readme)
parts.append(shift_headings(readme, 1))
parts.append("\n\\newpage\n")

parts.append("# Ubuntu package lists\n")
parts.append(
    "These plaintext lists are the suite-wide inventories. "
    "Per-package subsets are documented later and also live under `tools/deps/`.\n"
)
for label, fname in [
    ("Compile packages", "ubuntu-packages-compile.txt"),
    ("Runtime packages", "ubuntu-packages-runtime.txt"),
]:
    parts.append(f"\n## {label}\n")
    parts.append(f"Source file: `Documentation/{fname}`\n")
    parts.append("```\n" + read(DOC / fname).rstrip() + "\n```\n")
    parts.append("\n\\newpage\n")

parts.append("# Package documentation\n")
parts.append(
    "One section per cloned repository. Order: SigDigger stack and plugins first, "
    "then remaining packages alphabetically.\n"
)
for key in ordered_keys:
    body = shift_headings(read(pkg_map[key]), 1)
    body = re.sub(r"^##\s+(.+)$", rf"## {key} — \1", body, count=1, flags=re.M)
    parts.append("\n" + body.rstrip() + "\n\n\\newpage\n")

OUT_MD.write_text("\n".join(parts), encoding="utf-8")
cmd = [
    "pandoc", str(OUT_MD), "-o", str(OUT_PDF),
    "--pdf-engine=xelatex", "--toc", "--toc-depth=3",
    "-V", "geometry:margin=1in",
    "-V", "colorlinks=true",
    "-V", "linkcolor=blue",
    "-V", "urlcolor=blue",
    "-V", "toccolor=black",
    "-V", "documentclass=report",
    "-V", "fontsize=11pt",
    "--highlight-style=tango",
    "-f", "markdown+raw_tex",
]
subprocess.run(cmd, check=True)
print(f"Wrote {OUT_PDF} ({OUT_PDF.stat().st_size} bytes)")
PY
