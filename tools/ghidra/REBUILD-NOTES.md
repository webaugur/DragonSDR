# Extension rebuild notes (Ghidra 12.1.2)

**Host Ghidra:** `~/Applications/Ghidra/current` → **12.1.2 PUBLIC**  
**JDK:** 21 (`JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`)  
**Gradle:** 8.14.3 (`~/Applications/gradle-8.14.3/`)

## Built successfully

### Ghidrathon (mandiant) — **12.1.2**

| | |
|--|--|
| Source | https://github.com/mandiant/Ghidrathon (`main` @ build time; needs `PluginCategoryNames.COMMON` for Ghidra 12) |
| Jep | `jep==4.2.0` in venv `tools/ghidra/build/ghidrathon-venv` |
| Dist zip | `tools/ghidra/extensions/ghidra_12.1.2_PUBLIC_20260811_Ghidrathon.zip` |
| Installed | `~/Applications/Ghidra/current/Ghidra/Extensions/Ghidrathon/` |
| Configure | `tools/ghidra/build/ghidrathon-venv/bin/python tools/ghidra/build/Ghidrathon/util/ghidrathon_configure.py $GHIDRA_INSTALL_DIR` |

**Rebuild:**

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH="$JAVA_HOME/bin:$HOME/Applications/gradle-8.14.3/bin:$PATH"
export GHIDRA_INSTALL_DIR=$HOME/Applications/Ghidra/current
cd ~/Documents/DragonSDR/tools/ghidra/build/Ghidrathon
# copy jep jar into lib/ (path may vary by Python version):
find ../ghidrathon-venv -name 'jep-*.jar' -exec cp {} lib/ \;
gradle -PGHIDRA_INSTALL_DIR="$GHIDRA_INSTALL_DIR" buildExtension
```

**Note:** v4.0.0 tag still uses removed `PluginCategoryNames.INTERPRETERS`; **main** uses `COMMON`. Build from `main`, not the old tag.

Restart Ghidra after install/configure. Window → **Ghidrathon**.

---

## C++ class / RTTI recovery (use stock Ghidra — no community extension)

**Do not install** [astrelsky/Ghidra-Cpp-Class-Analyzer](https://github.com/astrelsky/Ghidra-Cpp-Class-Analyzer). That project is **archived EOL (2023-10-01)**, last shipped for Ghidra **10.2.x**, and does **not** build against 12.1.2 (API breaks: `OpenMode`, `ManagerDB.programReady`, `DomainObjectClosedListener`, RTTI model APIs, etc.). DragonSDR no longer ships its zips or source tree.

NSA Ghidra already ships RTTI analyzers and class-recovery scripts. Use those instead.

### 1. Auto-analysis (before the scripts)

1. Import the binary and run **Analysis → Auto Analyze…** as usual.
2. Ensure compiler-specific RTTI analyzers are enabled when present, for example:
   - **Windows x86 PE RTTI Analyzer** (MSVC / PE with RTTI)
   - GCC/Itanium-style typeinfo handling runs via related analyzers / DWARF when available
3. Prefer a **freshly analyzed** program (minimal prior manual markup). PDB or DWARF, if available, improves member recovery.

Auto analysis places RTTI symbols under **Symbol Tree** (type descriptors, complete object locators / typeinfo, vftables). That alone is often enough to navigate inheritance and demangled names.

### 2. Recover classes from RTTI (main workflow)

**Script Manager → category `C++` → `RecoverClassesFromRTTIScript.java`**

Shipped under:

```text
~/Applications/Ghidra/current/Ghidra/Features/Decompiler/ghidra_scripts/RecoverClassesFromRTTIScript.java
```

Helpers live in `…/ghidra_scripts/classrecovery/` (`RTTIWindowsClassRecoverer`, `RTTIGccClassRecoverer`, …).

**What it does** (from the script header / upstream notes):

- Walks RTTI to recover hierarchy, inheritance kind, constructors/destructors, class data types, vftables
- Uses **PDB** member types when present; otherwise decompiler store info (may leave `undefined` placeholders)
- Bookmarks constructors/destructors (when enabled)
- Optionally graphs hierarchies, prints/exports class definitions

**Flags** at the top of the script (edit then re-run if needed):

| Flag | Typical lab default | Purpose |
|------|---------------------|---------|
| `FIXUP_PROGRAM` | `true` | Find missing RTTI / undissassembled ctor/dtor bytes |
| `BOOKMARK_FOUND_FUNCTIONS` | `true` | Bookmark ctors/dtors |
| `MAKE_VFUNCTIONS_THISCALLS` | `true` | Mark virtuals as `__thiscall` |
| `PRINT_COUNTS` | `true` | Console summary counts |
| `PRINT_*` / `OUTPUT_*` | `false` | Verbose class dumps / files |
| `GRAPH_CLASS_HIERARCHIES` | `false` | Show inheritance graph when done |

**Where to inspect results:**

| View | What you get |
|------|----------------|
| **Symbol Tree → Classes** | Class namespaces, methods, vftable(s) |
| **Data Type Manager → \<program\> → ClassDataTypes → \<class\>** | Recovered class structures |
| Decompiler | Hover `this` / improved layouts after recovery |
| Bookmarks | Constructor / destructor hits |

**Caveats (upstream):**

- Prototype; type layout / default vfunction names may change in future Ghidra releases
- **Windows (MSVC) recovery is more complete** than **GCC**, which is still limited (esp. virtual inheritance; DWARF helps)
- Best on **fresh** analysis; heavy prior markup is less tested
- On Windows PE, if RTTI was not already applied, the script can run the **RTTIAnalyzer** first

### 3. Keep signatures and definitions in sync after manual edits

After `RecoverClassesFromRTTIScript`, if you change virtual function signatures or data-type definitions:

| Script | When to run |
|--------|-------------|
| `ApplyClassFunctionSignatureUpdatesScript.java` | You edited a **listing** virtual function signature → push to class function definitions / related vftables. Cursor on the changed function. Optional: Script Manager **In Tool** → menupath **Scripts.ApplyClassFunctionSignatures**, key **Shift+S**. |
| `ApplyClassFunctionDefinitionUpdatesScript.java` | You edited **Data Type Manager** function definitions → push back to listing / related parent-child virtuals. Cursor on a member of the class. Optional: **Scripts.ApplyClassFunctionDefinitions**, key **Shift+D**. |

Both require that vftable structures were originally applied by `RecoverClassesFromRTTIScript`.

### 4. Manual C++ markup (when RTTI is stripped)

If the binary has **no RTTI** (common on release firmware / `-fno-rtti`):

1. Find constructors (write to vptr early; often paired with `operator new`).
2. Set calling convention to **`__thiscall`** (or platform equivalent) on instance methods.
3. In the decompiler, right-click the first parameter → **Auto Create Class** (or build a structure and assign as `this` type).
4. Grow the structure from decompiler field use; assign vftable pointers to named pointer-to-function tables as you identify them.

Stock Ghidra will not invent full hierarchies without RTTI or DWARF/PDB; this is expected.

### 5. Headless sketch

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
GHIDRA=~/Applications/Ghidra/current
"$GHIDRA/support/analyzeHeadless" /tmp/ghidra_projects MyCpp \
  -import /path/to/binary \
  -analysisTimeoutPerFile 600 \
  -postScript RecoverClassesFromRTTIScript.java
```

Ensure auto-analysis has finished (or use default analysis) so RTTI structures exist before the post-script. Increase decompiler timeout in tool options for large C++ binaries if recovery stalls.

### 6. Further upstream reading

- Script sources under `Ghidra/Features/Decompiler/ghidra_scripts/` (especially `RecoverClassesFromRTTIScript.java` header comments)
- [NSA Ghidra discussion: RTTI Analysis #3213](https://github.com/NationalSecurityAgency/ghidra/discussions/3213) (design notes from Ghidra maintainers + historical Cpp Class Analyzer context)
- Related issues around class recovery / DWARF / PDB as they land in release notes for your Ghidra version

---

## Related version-matched downloads (no rebuild needed)

| Plugin | 12.1.2 asset |
|--------|----------------|
| FindCrypt (preferred) | [GhidraFindcrypt v3.1.9](https://github.com/antoniovazquezblanco/GhidraFindcrypt/releases/tag/v3.1.9) `ghidra_12.1.2_PUBLIC_20260608_GhidraFindcrypt.zip` |
| GhidraMCP | [1.4](https://github.com/LaurieWired/GhidraMCP/releases/tag/1.4) `GhidraMCP-release-1-4.zip` |
| wasm | closest [12.0](https://github.com/nneonneo/ghidra-wasm-plugin/releases/tag/v2.4.0); rebuild for 12.1.2 if issues |
