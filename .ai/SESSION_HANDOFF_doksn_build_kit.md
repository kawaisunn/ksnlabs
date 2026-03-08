# SESSION HANDOFF — Doksn Build Kit + DC Stability
**Date**: 2026-03-07 (morning–afternoon)
**Session**: opus46-web-doksn-buildkit
**Model**: Claude Opus 4.6 on claude.ai (with DC MCP on BIGSPIDER)
**Machine**: BIGSPIDER (bigspider\kawaisunn)
**Next session pickup**: This file + doksn_build_kit.zip in chat outputs

---

## What Was Accomplished

### Doksn Build Kit — Consolidated Packaging Folder
Created a single-folder build kit for Doksn (MSI now, MSIX prep, keywrds standalone):

- **stage_all_deps.ps1**: Downloads ALL build deps to `C:\dev\ocritd\sandbox\staging\`
  - .NET 8.0.404 SDK, WiX v3.14 (was missing before!), Tesseract 5.3, Ghostscript 10.04
  - Poppler 24.08, LibreOffice 25.8.x, Windows SDK (for MSIX), Python wheels
  - Flags: `-SkipLarge` (skip LibreOffice), `-SkipMSIXPrep` (skip Windows SDK)

- **build_keywrds_portable.ps1**: Packages keywrds as standalone portable zip
  - Embedded Python 3.13 + `engine/keywards/` (10 modules) + subset wheels + launchers
  - Output: `C:\dev\ocritd\dist\keywrds_standalone_v0.8.0.zip`
  - No .NET, no admin, no install — unzip and run
  - Includes `run_keywrds.cmd` (double-click) and `run_keywrds.ps1` (PowerShell)

- **verify_build_env.ps1**: Pre-build sanity checker
  - Checks: .NET SDK, WiX, Python, Tesseract, Ghostscript, Poppler, source files,
    staged installers, MSIX tooling — reports pass/fail/warn for each

- **convert_msi_to_msix.ps1**: Future MSI→MSIX conversion
  - Generates AppxManifest.xml, creates MSIX layout, packages with makeappx.exe
  - Placeholder logo assets included (need replacing before distribution)
  - Self-signed cert instructions in docs/msix_prep.md

- **docs/msix_prep.md**: MSIX packaging guide
  - Two paths (MSIX Packaging Tool GUI vs makeappx CLI)
  - Code signing options (self-signed → UofI cert → CA cert)
  - Known gotchas (filesystem virtualization, external tool paths, subprocess calls)

### Deliverables
- **doksn_build_kit.zip**: Full scripts delivered via claude.ai file output
- **GitHub commits**: 3 commits to ksnlabs/main (9d668d7, f2a0559, 733d646)
  - `doksn-build-kit/` directory with README + script stubs + full stage_all_deps.ps1 + msix_prep.md
  - Repo has stubs referencing the zip for full script versions

### DC/MCP Stability Investigation
Spent significant session time diagnosing Desktop Commander reliability issues:

- **Root cause 1**: Running Claude Desktop as admin breaks MSIX config path resolution
  - `%LOCALAPPDATA%` resolves to different profile under elevation
  - Config at `%APPDATA%\Claude\` exists but MSIX virtualized path is empty
  - Fix: Don't run Claude Desktop as admin

- **Root cause 2**: DC `start_process` with default PowerShell shell times out
  - `list_sessions`, `list_directory` work but `start_process` hangs
  - Fix: Specify `shell: "cmd"` explicitly — cmd works reliably

- **Root cause 3**: DC `write_file` is unreliable regardless of path
  - Consistently times out; `read_file` also unreliable
  - Workaround: Use `start_process` with cmd for file operations, or paste manually

- **MSIX dual-path bug** (known from prior sessions, L003-adjacent):
  - Claude Desktop reads from: `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\`
  - NOT from `%APPDATA%\Claude\` (which "Edit Config" opens)
  - Config must exist at BOTH paths
  - `restart_claude.ps1` script written (needs manual paste to desktop)

---

## Immediate Next Steps

1. **Paste restart_claude.ps1 to desktop** (DC couldn't write it — see script in chat history)
2. **Run stage_all_deps.ps1** to download WiX v3.14 and Windows SDK to staging
3. **Run verify_build_env.ps1** to confirm everything is ready
4. **Run BUILD_ALL.ps1 -BuildMode Full** to produce MSI
5. **Run build_keywrds_portable.ps1** to produce keywrds standalone zip
6. **Test in sandbox**: `C:\dev\ocritd\sandbox\doksn_sandbox.wsb`

---

## New Learnings

- **L063**: Running Claude Desktop as admin breaks MCP config path resolution. The MSIX virtualized `%LOCALAPPDATA%` path changes under elevation. Always run non-admin.
- **L064**: DC `start_process` must use `shell: "cmd"` on BIGSPIDER. Default PowerShell hangs. File ops (`list_directory`) work regardless.
- **L065**: DC `write_file` and `read_file` are unreliable in this environment. Use `start_process` with cmd shell, GitHub API, or manual paste as fallback.
- **L066**: WiX v3.14 installer was missing from sandbox staging. Added to `stage_all_deps.ps1` as step [2/8]. URL: `https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314.exe`
- **L067**: keywrds can be packaged standalone without .NET — only needs embedded Python 3.13 + `engine/keywards/` + ~10 wheels (pydantic, rich, colorama, etc.)

---

## Git State

ksnlabs main: `733d646` — doksn-build-kit scripts + MSIX docs
No uncommitted local changes (all work was via GitHub API + claude.ai file output).

---

## DC Operational Notes for Next Session

- DC is alive but flaky. `list_sessions` responds; `list_directory` responds; `start_process` only works with `shell: "cmd"`
- `write_file` and `read_file` hang — use GitHub API or cmd echo workarounds
- Config is present at both MSIX paths (confirmed True)
- Running non-admin (confirmed working)
- If DC dies: full quit Claude Desktop → reopen (don't just kill node)
