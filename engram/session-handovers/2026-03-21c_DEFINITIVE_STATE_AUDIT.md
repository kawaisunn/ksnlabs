# SESSION HANDOFF: 2026-03-21c — DEFINITIVE STATE AUDIT
## Machine: BIGSPIDER (Claude Desktop, Opus 4.6)
## Priority: THIS IS THE AUTHORITATIVE STATE DOCUMENT. Read this FIRST.

---

## 1. PYTHON 3.13.11 — AUTHORITATIVE RUNTIME

### Location: `C:\dev\ocritd\runtime\python\`
(Will move to `C:\dev\doksn\runtime\python\` when directory rename completes)

### Version: Python 3.13.11 (embeddable, amd64)

**What WORKS:**
- python.exe → 3.13.11
- pip 26.0 (Scripts\pip.exe)
- virtualenv 20.36.1 (Scripts\virtualenv.exe) — stdlib `venv` is NOT available in embeddable. Use `virtualenv` instead.
- `import site` enabled in python313._pth
- sqlite3 3.50.4 (sqlite3.dll + _sqlite3.pyd present)
- _doksn_runtime_info.json confirms: pip=true, virtualenv=true, site=true

**44 packages installed — Doksn document processing ONLY:**
ocrmypdf, pdfplumber, pikepdf, pillow, python-docx, python-pptx, openpyxl,
lxml, pydantic, xlsxwriter, fpdf2, img2pdf, colorama, rich, plus deps.

**NOT installed — MUST be added for full DOCKSN capability:**
- torch==2.6.0+cu124 (CAIT inference — ~2.5GB from PyTorch index)
- torchvision==0.21.0+cu124
- torchaudio==2.6.0+cu124
- transformers (CAIT model loading)
- accelerate (CAIT inference optimization)
- safetensors (model weight loading)
- bitsandbytes (quantization)
- scikit-learn (TF-IDF for keywrds)
- datasketch (MinHash LSH for dedup)
- dateparser (date extraction for datectx)
- networkx (graph algorithms for reconstruct)
- nltk (NLP for keywrds)
- numpy, scipy (ML foundations — torch deps)
- peft (LoRA for CAIT fine-tuning)
- sentencepiece (tokenizer for Phi models)

**CRITICAL RULES FOR THIS PYTHON:**
1. NEVER add to system PATH. Self-contained.
2. ALWAYS invoke as `C:\dev\ocritd\runtime\python\python.exe` (or doksn after rename)
3. ALWAYS use `C:\dev\ocritd\runtime\python\Scripts\pip.exe` for installs
4. All wheels should be cached to `C:\dev\ocritd\wheelhouse\` after download
5. This ONE instance serves doksn + cait + keywrds + ktreesn
6. Included in MSIX build via wheelhouse for offline install

**Install command (when ready — needs Christopher's clearance for downloads):**
```
C:\dev\ocritd\runtime\python\Scripts\pip.exe install ^
  torch==2.6.0+cu124 torchvision==0.21.0+cu124 torchaudio==2.6.0+cu124 ^
  --extra-index-url https://download.pytorch.org/whl/cu124 ^
  && C:\dev\ocritd\runtime\python\Scripts\pip.exe install ^
  transformers accelerate safetensors bitsandbytes peft sentencepiece ^
  scikit-learn datasketch dateparser networkx nltk numpy scipy ^
  && C:\dev\ocritd\runtime\python\Scripts\pip.exe download ^
  torch==2.6.0+cu124 torchvision==0.21.0+cu124 torchaudio==2.6.0+cu124 ^
  transformers accelerate safetensors bitsandbytes peft sentencepiece ^
  scikit-learn datasketch dateparser networkx nltk ^
  --extra-index-url https://download.pytorch.org/whl/cu124 ^
  -d C:\dev\ocritd\wheelhouse
```

### GPU: NVIDIA RTX A5000, 24564 MiB, 24250 MiB free
CUDA available via nvidia-smi at C:\Windows\System32\nvidia-smi.exe
Torch+cu124 will use this GPU for CAIT inference once installed.

---

## 2. OCRITD → DOKSN RENAME — CURRENT STATE

### Rename script EXISTS but was NEVER RUN
`C:\dev\ocritd\RENAME_TO_DOKSN.ps1` — written 2026-03-02, 224 lines, comprehensive.
Has -DryRun mode. Handles C# source, namespaces, UI strings, env vars, paths,
build artifacts, folder rename, BUILD.ps1 references, documentation.

### Partial rename already happened manually:
- `src\doksn.Launcher\` EXISTS (7 files, Mar 9): csproj, MainForm.cs, Designer, Program.cs, LauncherSettings.cs, KtreesnBridge.cs, KtreesnModels.cs
- `src\OCRITD.Launcher\` STILL EXISTS (1 file): PythonRuntimeDetector.cs only
- Python engine already renamed: engine\doksn.py exists (not engine\ocritd.py)

### What the rename script will do (run with -DryRun first!):
1. Update C# namespaces OCRITD.Launcher → doksn.Launcher
2. Update UI strings, env vars, paths in all .cs files
3. Delete obj/ and bin/ build artifacts
4. Rename src\OCRITD.Launcher → src\doksn.Launcher (will SKIP — target already exists)
5. Update BUILD.ps1 and BUILD_ALL.ps1 references
6. Update documentation files

### What the rename script will NOT do (manual steps needed):
- Move PythonRuntimeDetector.cs from OCRITD.Launcher to doksn.Launcher
- Delete the empty OCRITD.Launcher directory
- Rename the GitHub repo (kawaisunn/ocritd → kawaisunn/doksn)
- Rename the local directory (C:\dev\ocritd → C:\dev\doksn)
- Update git remote URL
- Update all engram references (buffer, handoffs, learnings)
- Deploy rename to Intrusion and Antiquarian

### Recommended execution sequence:
```
1. Copy PythonRuntimeDetector.cs to doksn.Launcher
2. Run RENAME_TO_DOKSN.ps1 -DryRun (review output)
3. Run RENAME_TO_DOKSN.ps1 (execute)
4. Delete src\OCRITD.Launcher (now empty)
5. Rebuild: .\BUILD.ps1 -BuildGUI
6. Test launch
7. git add -A && git commit -m "rename: OCRITD -> Doksn complete"
8. Rename GitHub repo via API or web: ocritd → doksn
9. git remote set-url origin https://github.com/kawaisunn/doksn.git
10. git push
11. Rename local dir: Rename-Item C:\dev\ocritd C:\dev\doksn
12. Update all engram references
13. Deploy to Intrusion and Antiquarian via VPN
```

### 362 "ocritd" references found across codebase:
Most are in _temp/, build/tempbackupbuildfiles/, old documentation, and
stale handoff/vision documents. The rename script covers the critical C# source
and build files. Documentation files with "OCRITD" in their names should be
renamed or deleted if obsolete.

---

## 3. GIT STATE (BIGSPIDER)

### ksnlabs
- Remote: git@github.com:kawaisunn/ksnlabs.git
- DIRTY: buffer v1.0.24, research doc, this handoff, earlier handoff (2026-03-21c) uncommitted
- Needs: git add -A && git commit && git push

### ocritd
- Remote: https://github.com/kawaisunn/ocritd.git
- CLEAN at commit 407e926
- Branch: main
- GitHub repo name: ocritd (needs rename to doksn)

### ktreesn
- Remote: https://github.com/kawaisunn/ktreesn.git
- Clean at 267d1b6

### Git access on BIGSPIDER:
- git.exe at `C:\Program Files\Git\cmd\git.exe`
- NOT in MCP shell PATH — must use full path
- PowerShell piping with git.exe has quoting issues — use cmd shell for git

---

## 4. CROSS-MACHINE SYNC — THE GAP

**What was supposed to exist:** Automatic cascading sync across all 3 machines.

**What actually exists:**
- Sync-Workspaces.ps1 written but has parse error (inline version worked once)
- Setup-IntrusionRemoting.ps1 works (DPAPI credential at C:\dev\.credentials\intrusion_cred.xml)
- WinRM to Intrusion confirmed working at 50-67ms
- Antiquarian reachable via TCP (RDP 3389) but NOT via ICMP
- No automatic sync mechanism in place
- Every sync has been manual and one-off

**What needs to happen:**
1. Fix Sync-Workspaces.ps1
2. Establish authority model: which machine owns which files (L105)
3. Test bidirectional sync via VPN
4. Consider scheduled task for periodic sync

---

## 5. _DOCKSN INTEGRATION DIRECTORY

### Location: `C:\dev\_DOCKSN\`
Contains: Architecture docs (v0.1, v0.2, v0.3_addendum), OVERSIGHT1_PROJECT_MAP.md,
integration scripts (Bootstrap-Keywrds, Find-Duplicates, Initialize-DoksnOutput,
Start-CaitShadow, Package-Lumo), docs/figures/ with mermaid diagrams,
RESEARCH_Proven_Methods_20260321.md (written this session).

### This is NOT a git repo on BIGSPIDER.
It IS a git repo on Intrusion (commit 1d97eb8, 32 files, no remote).

---

## 6. OVERSIGHT1 PENDING ACTIONS (from paradigm shift session)

1. Christopher reads ARCHITECTURE_v0.2.md + v0.3_addendum ← DONE this session
2. Research proven methods ← DONE this session (382-line report)
3. Architecture revisions: shell preference (L114), ephemeral DBs (L115) ← CAPTURED in buffer v1.0.24
4. Iterate architecture doc until solid ← NEXT
5. Implementation — incremental, each step producing usable output ← BLOCKED on Python + rename
6. First working pipeline run on real ITD documents ← MILESTONE

---

## 7. CAIT STATUS ON BIGSPIDER

### Model weights: PRESENT
- Phi-3.5 Vision at C:\dev\cait\models\phi-3.5-vision\
- 2 safetensor shards + config + tokenizer

### Runtime: NOT READY
- torch not installed in deployable Python
- transformers not installed
- No venv exists (old pointer at C:\Users\kawaisunn\ksnlabs\venv_cait is stale)
- Ollama NOT installed (available via winget)

### CAIT's immediate application: datectx processor
- dateparser finds dates mechanically
- CAIT classifies what each date MEANS (test date, permit date, document date, etc.)
- Short context window, classification output — ideal local LLM task
- Requires: torch + transformers in deployable Python, OR Ollama as alternative

---

## 8. IMMEDIATE NEXT SESSION PRIORITIES (in order)

### A. Complete the ocritd → doksn rename on BIGSPIDER
1. Copy PythonRuntimeDetector.cs to doksn.Launcher
2. Run RENAME_TO_DOKSN.ps1 -DryRun, review
3. Run RENAME_TO_DOKSN.ps1 live
4. Delete empty OCRITD.Launcher dir
5. Rebuild and test
6. Git commit + push
7. Rename GitHub repo
8. Rename local C:\dev\ocritd → C:\dev\doksn

### B. Install ML dependencies into deployable Python
1. torch+cu124 (~2.5GB download)
2. transformers, accelerate, safetensors, bitsandbytes, peft, sentencepiece
3. scikit-learn, datasketch, dateparser, networkx, nltk
4. Cache all wheels to wheelhouse for MSIX packaging
5. Verify: torch.cuda.is_available() == True

### C. Sort out git
1. Commit ksnlabs (dirty: buffer, handoffs, research doc)
2. After rename: push doksn to renamed GitHub repo
3. Document git access pattern (full path to git.exe, cmd shell)

### D. Cross-machine deployment
1. Fix Sync-Workspaces.ps1
2. Deploy renamed doksn to Intrusion via WinRM
3. Verify Intrusion's Python runtime matches
4. Verify Antiquarian state

### E. First CAIT inference test
1. Load Phi-3.5 via transformers in deployable Python
2. Test date context classification on sample ITD text
3. Benchmark inference time and VRAM usage on A5000

---

## 9. SESSION ARTIFACTS THIS SESSION (2026-03-21c)

### Files created:
- C:\dev\_DOCKSN\docs\RESEARCH_Proven_Methods_20260321.md (382 lines)
- C:\dev\ksnlabs\engram\session-handovers\2026-03-21c_research_proven_methods.md
- C:\dev\ksnlabs\engram\session-handovers\2026-03-21c_DEFINITIVE_STATE_AUDIT.md (THIS FILE)

### Buffer: v1.0.24 — updated with shell preference, ephemeral DB revision, research status

### Learnings pending (not yet written to consolidated file):
- L114: Shell preference policy — pwsh.exe > powershell.exe > cmd.exe ALWAYS
- L115: Ephemeral databases — SQLite per processing job, created/destroyed with run
- L116: Deployable Python 3.13.11 is Doksn document-processing only — ML/CAIT/research stack not installed
- L117: stdlib venv unavailable in embeddable Python — use virtualenv package instead
- L118: RENAME_TO_DOKSN.ps1 exists since March 2, never executed — partial manual rename left both src dirs
