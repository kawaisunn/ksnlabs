# SESSION HANDOFF: 2026-03-22 Session D — Python Complete, TQDon Migration Next
## Machine: BIGSPIDER (Claude Desktop, Opus 4.6)
## Priority: READ THIS FIRST, then buffer.jsonld

---

## ACCOMPLISHMENTS THIS SESSION

### 1. DOCKSN Standalone Python 3.13.11 — COMPLETE
Location: `C:\dev\ocritd\runtime\python\`
97 packages installed across 4 tiers, ALL imports verified:

- **Tier 1 (Doc Processing)**: ocrmypdf 17.3.0, pdfplumber 0.11.9, pikepdf 10.3.0, pillow 12.1.1, python-docx 1.2.0, python-pptx 1.0.2, openpyxl 3.1.5, lxml 6.0.2, pydantic 2.12.5, rich 14.3.3 + deps
- **Tier 2 (Research Pipeline)**: scikit-learn 1.8.0, datasketch 1.9.0, dateparser 1.3.0, networkx 3.6.1, nltk 3.9.3, numpy 2.4.3, scipy 1.17.1, pandas 3.0.1
- **Tier 3 (ML/CAIT)**: torch 2.6.0+cu124, torchvision 0.21.0+cu124, torchaudio 2.6.0+cu124, transformers 5.3.0, accelerate 1.13.0, safetensors 0.7.0, bitsandbytes 0.49.2, peft 0.18.1, sentencepiece 0.2.1
- **Tier 4 (Utilities)**: tqdm 4.67.3, psutil 7.2.2, watchdog 6.0.0, python-dotenv 1.2.2, PyYAML 6.0.3, requests 2.32.5

CUDA confirmed: torch.cuda.is_available()=True, GPU=NVIDIA RTX A5000
NOTE: All torch/ML wheels were in pip HTTP cache from prior installs. No fresh download needed.

Requirements files committed and pushed:
- `C:\dev\ocritd\requirements-docksn-standalone.txt` (human-readable, 4 tiers)
- `C:\dev\ocritd\requirements-docksn-frozen.txt` (pip freeze, exact versions)

### 2. Windows Shell Folder Registry Fixes
- Downloads: `{374DE290...}` and `{7D83EE9B...}` → `D:\Downloads` (created, 47175 items copied)
- Documents: `Personal` and `{F42EE2D3...}` → `D:\Documents` (created, empty — content sort pending)
- Explorer restart or sign-out needed for full effect

### 3. Code State Issues Identified (NOT YET FIXED)
During pre-rename verification, found:
- `PythonRuntimeDetector.cs` still in `OCRITD.Launcher` namespace, references `_ocritd_runtime_info.json` (old name)
- `PythonRuntimeDetector.cs` is NOT referenced by any file in `doksn.Launcher` — dead code in old dir
- `requirements.lock` only lists 11 original doc-processing packages — stale, needs regeneration
- `_doksn_runtime_info.json` exists (new name) but `PythonRuntimeDetector.cs` looks for old name
- The Launcher's `EnsureWorkspaceAndVenv()` creates a venv per workspace and installs from wheelhouse — wheelhouse only has 44 doc-processing wheels, not the full 97

---

## CRITICAL CONTEXT: DO NOT LOSE THESE PROJECT OBJECTIVES

### DOCKSN Architecture (from ARCHITECTURE_v0.2.md + v0.3_addendum)
8-processor iterative pipeline: ktreesn → doksn → keywrds → datectx → dedup → reconstruct → cait → prefill
Ephemeral SQLite per processing job. Pedalboard/DAG pattern. Design-first approach.

### Active DOCKSN Components (separate repos, linked by MANIFEST.json concept)
- **ocritd** (→ doksn): `C:\dev\ocritd\` — core engine + GUI launcher. GitHub: kawaisunn/ocritd
- **Ktreesn**: `C:\dev\Ktreesn\` — PowerShell filesystem catalog. GitHub: kawaisunn/ktreesn
- **keywrds** (integrated): `C:\dev\ocritd\engine\keywards\` — keyword extraction
- **CAIT**: `C:\dev\cait\` — ML inference. Model weights at `C:\dev\cait\models\phi-3.5-vision\`
- **_DOCKSN**: `C:\dev\_DOCKSN\` — integration scripts, architecture docs, research
- **AggDB**: `C:\dev\ksnlabs\aggdb\` — FastAPI backend + HTML frontend
- **ksnlabs**: `C:\dev\ksnlabs\` — engram, coordination. GitHub: kawaisunn/ksnlabs

### Cross-Machine State (3 machines)
- BIGSPIDER (home): Primary dev. Python 3.13.11 now complete. RTX A5000.
- IGS-Intrusion (server): SQL Server, AggDB API, _DOCKSN git repo (no remote), nightly backups
- Antiquarian (IGS desk): RTX 4000 8GB, working copies via git pull
- Connectivity: Cisco AnyConnect VPN bidirectional. WinRM to Intrusion confirmed.
- Sync gap: No automatic cascade. Sync-Workspaces.ps1 has parse error. Every sync manual.

### Grant Pressure
Christopher is under pressure to show results. Pipeline must produce demonstrable output soon.

### Rename Status
- `RENAME_TO_DOKSN.ps1` exists (224 lines) but NEVER RUN
- Partial manual rename: both `src\doksn.Launcher\` and `src\OCRITD.Launcher\` exist
- Engine already renamed: `engine\doksn.py`
- 362 "ocritd" references in codebase (mostly stale docs/temp files)
- Rename must be done carefully — code state issues above need addressing first

---

## NEXT SESSION PRIORITIES (in order)

### A. TQDon Migration (NEW — discussed this session)
Migrate from Claude Desktop app to ToiQaDon as primary Claude interface. Benefits:
1. Control system prompt → force Lumo-only tools, eliminate DC hang issues
2. Kill Claude processes button (clean session starts)
3. Launch Claude button
4. Expanded verbose view (show all tool calls expanded, no collapsing)
5. "Queue next message" feature (type while Claude works, auto-sends when done)
6. Streamlined Lumo tool upgrades
Location: ToiQaDon = `C:\dev\lumo` on BIGSPIDER
Prior discussion of Lumo self-improvement in earlier sessions — check engram/session chats.
MCP config: Lumo + GitHub only. NO Desktop Commander.

### B. Rename ocritd → doksn (BLOCKED items must be fixed first)
1. Copy PythonRuntimeDetector.cs to doksn.Launcher, update namespace + JSON filename
2. Regenerate requirements.lock to include all 97 packages
3. Update wheelhouse (cache all wheels)
4. Run RENAME_TO_DOKSN.ps1 -DryRun, review, execute
5. Rebuild, test, commit, push
6. Rename GitHub repo
7. Rename local directory

### C. Cross-Machine Sync
Fix Sync-Workspaces.ps1, establish authority model, deploy to Intrusion and Antiquarian

### D. First Pipeline Run
15 real ITD site folders. Demonstrate DOCKSN produces usable output.

### E. CAIT Inference Test
Load Phi-3.5 via transformers, test date context classification, benchmark on A5000

---

## TODO (human action items)
- [ ] Sort mixed content in `D:\Desktop\Downloads` → move Documents stuff to `D:\Documents`
- [ ] Check `D:\Desktop\New folder` (4 DOCKSN .docx drafts) → move somewhere intentional
- [ ] Restart Explorer or sign out/in for registry changes to take effect
- [ ] Delete `D:\Desktop\Downloads` after confirming `D:\Downloads` works
- [ ] Bump Desktop Commander config: fileReadLineLimit=5000, fileWriteLineLimit=200

---

## GIT STATE AT HANDOFF
- **ksnlabs**: will be CLEAN after this handoff commit
- **ocritd**: CLEAN at a3e2d36 (requirements files committed and pushed)
- **ktreesn**: CLEAN at 267d1b6

---

## MCP TOOL NOTES FOR NEXT SESSION
- Desktop Commander hangs frequently on long operations and System32 binaries
- Lumo pwsh works reliably for most operations
- Lumo cmd shell required for: git (full path), pip (full path), python runtime
- Robocopy not callable from Lumo pwsh (System32 binary execution bug) — use cmd or manual terminal
- For large downloads/installs: pass command to Christopher's live terminal instead of MCP tools

---

## SESSION ARTIFACTS
- `C:\dev\ocritd\requirements-docksn-standalone.txt` (authoritative, 4-tier)
- `C:\dev\ocritd\requirements-docksn-frozen.txt` (pip freeze)
- `C:\dev\pip_torch_install.log` (torch install log)
- `C:\dev\ksnlabs\engram\session-handovers\2026-03-22_session-d_python-complete.md` (THIS FILE)
- Buffer v1.0.29

## LEARNINGS TO WRITE (next session, IDs L119-L122)
- L119: pip HTTP cache preserved torch+cu124 wheels — always check cache before downloading
- L120: Desktop Commander hangs on long ops and System32 binaries — prefer Lumo or manual terminal
- L121: TQDon as primary interface eliminates DC dependency, enables Lumo-only MCP config
- L122: Windows shell folder GUIDs: Downloads={374DE290...}+{7D83EE9B...}, Documents=Personal+{F42EE2D3...}
