# SESSION HANDOFF — Ktreesn Debug + Git Hygiene
**Date**: 2026-03-09
**Session**: claude.ai web — ktreesn debug, git remediation
**Model**: Claude Opus 4.6
**Machine**: BIGSPIDER (via Desktop Commander MCP, partial — DC became unresponsive late session)

---

## What Was Accomplished

### 1. Ktreesn Profile Function — Full Bug Audit
Analyzed the old standalone `Get-Ktreesn` function from `$PROFILE` (the one attached to this Claude Project). Found and documented 9 issues:

**Bugs identified:**
- `-Geo` parameter never declared in param block (geo mode completely broken)
- Box-drawing chars corrupted (mojibaked UTF-8 literals)
- Compound sidecar extensions (.shp.xml, .aux.xml) never match via GetExtension()
- Write-Log pipeline suppression uses wrong scope ($MyInvocation inside nested function)
- ANSI codes written to file exports (no stripping)
- Non-sidecar files in geo groups silently dropped

**Missing functionality:**
- `$MaxFilesConsole` declared but never implemented
- `$cLink` / symlink detection — color defined, never used
- `$ShowDate` only worked on directories, not files
- `$shownParams` defined then ignored in header
- Minimal comment-based help (no parameter docs, no examples)

**NOTE**: This profile function is OBSOLETE. The canonical Ktreesn is the module at `C:\dev\Ktreesn\Ktreesn.psm1` (v0.6.1). The project-attached profile should be replaced with `Import-Module C:\dev\Ktreesn\Ktreesn.psd1` or removed entirely.

A fixed standalone version was generated but is superseded by the module. Discard it.

### 2. Git Remediation — All Repos Resolved

**ocritd**: Was 2 commits behind remote. Pulled `3da5bf6` (Ktreesn launcher integration). Now synced. All 7 launcher files present including KtreesnBridge.cs and KtreesnModels.cs.

**Ktreesn**: Stale `.git/AUTO_MERGE` artifact deleted. Was already synced at `83bb9a0`.

**ksnlabs**: Was 2 commits behind remote. Pulled `175d328`. Verify-GitState.ps1 committed via GitHub API (`4a91b21`). **Local needs `git pull` next session** to pick up the API commit.

All three repos pruned (`git gc --prune=now`). Zero dangling objects remain.

### 3. Verify-GitState.ps1 — Session Git Hygiene Tool
New script at `ksnlabs/scripts/utilities/Verify-GitState.ps1`.

**What it checks per repo:**
- Working tree cleanliness (uncommitted changes)
- Sync status (ahead/behind remote, with SHA comparison)
- Stale merge artifacts (MERGE_HEAD, AUTO_MERGE, REBASE_HEAD, rebase-merge/)
- Stash entries
- Object store integrity (git fsck --full, skippable with -Quick)

**Flags:**
- `-Fix`: Auto-pull behind repos, auto-push ahead repos, delete stale artifacts
- `-Quick`: Skip fsck for faster checks

**Policy (enforced going forward):**
Run `Verify-GitState.ps1` at session start AND session end. All issues resolved immediately. No deferred git actions.

---

## Git State at Handoff

| Repo | Branch | Local SHA | Remote SHA | Status |
|------|--------|-----------|------------|--------|
| ocritd | main | `3da5bf6` | `3da5bf6` | Synced |
| ktreesn | main | `83bb9a0` | `83bb9a0` | Synced |
| ksnlabs | main | `175d328` (local) | `4a91b21` (remote) | **Local 1 behind — needs git pull** |

---

## Immediate Next Steps for Next Session

1. **`git pull` ksnlabs** — picks up Verify-GitState.ps1 from API commit
2. **Run `Verify-GitState.ps1`** — confirm all green
3. **Doksn mainform build** — `dotnet build` the launcher, test Ktreesn integration buttons:
   - Check Status (calls Get-DoksnProcessingStatus via KtreesnBridge)
   - Dir Summary (calls Get-DirectoryMap | Get-DirectoryMapSummary)
4. **Update $PROFILE** — replace old Get-Ktreesn function with `Import-Module C:\dev\Ktreesn\Ktreesn.psd1`
5. **Update Claude Project** — the attached `Microsoft.PowerShell_profile.ps1` is stale/obsolete

---

## DC Notes (Desktop Commander Reliability)

- `start_process` with shell `cmd` works for simple commands
- Commit messages with special chars (em dashes, quotes) cause `git commit -m` to fail in cmd shell — pathspecs get split on spaces
- Workaround: use GitHub API for commits, or write a .bat file and execute it
- DC became fully unresponsive late in session (read_multiple_files, start_process all returning no result)
- When DC hangs, pivot to GitHub API for any remaining git operations

---

## Learnings

- **L072**: DC cmd shell splits git commit messages on spaces when they contain unicode or special chars. Use GitHub API (`github:create_or_update_file`) for reliable commits from Claude sessions.
- **L073**: `git stash` returns exit code 0 with "No local changes to save" when tree is clean — doesn't block subsequent commands but `stash pop` will fail. Check for dirty tree first.
- **L074**: Git hygiene debt compounds exponentially. A 2-commit lag becomes merge conflicts becomes hours of manual resolution. The Verify-GitState.ps1 policy prevents this.

---

## Key File Locations

| File | Path | Status |
|------|------|--------|
| Verify-GitState.ps1 | `C:\dev\ksnlabs\scripts\utilities\` | On disk (DC wrote) + GitHub (`4a91b21`) |
| Ktreesn module | `C:\dev\Ktreesn\Ktreesn.psm1` | v0.6.1, synced |
| Ktreesn staged | `C:\dev\ocritd\runtime\modules\Ktreesn\` | psm1 + psd1 present |
| Launcher source | `C:\dev\ocritd\src\doksn.Launcher\` | 7 files, synced at `3da5bf6` |
| This handoff | `C:\dev\ksnlabs\.ai\SESSION_HANDOFF_git_hygiene.md` | GitHub |

@owner opus46-web-2026-03-09-git-hygiene
