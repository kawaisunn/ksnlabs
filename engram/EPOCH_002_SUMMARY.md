# Engram System — Epoch 002: Bootstrap Hardening
**Date**: February 16, 2026  
**For**: kawaisunn (human reference document)

---

## What Happened Today

Three AI sessions worked on the OCRITD project today. Two died without
writing handoffs. One (a "phantom") left changes on disk but no record
of itself. This document summarizes what was accomplished, what was lost,
and what was built to prevent it from happening again.

### Session Timeline

**Session 1** (orientation-survival-001): Survived orientation, fixed version
typos, created the lean `_AI_ORIENTATION.md`, pushed to GitHub. Wrote a
proper handoff. This session worked correctly.

**Session 2** (ocritd-stabilize-001): Fixed bootstrap files (`claude_start.json`,
`.CLAUDE_VERIFY`, `CLAUDE.md`), added critical learnings about the bash_tool
trap, created the W000 environment discovery workflow. Was moving fast and
making good progress. Died mid-conversation without writing a handoff.

**Phantom Session**: Existed between Session 2's death and Session 3. Created
the `ksnlabs/bootstrap/` deployment directory (useful), added `.gitattributes`
for LFS, deleted two files. Wrote no handoff at all. Evidence found only
through `git status`.

**Session 3** (ocritd-stabilize-002, current): Restored deleted files,
consolidated learnings, introduced the manifest/epoch system, established
checkpoint discipline. This document is part of its output.

---

## What's In The Engram Now

### Learnings (18 total, in `consolidated_epoch-002.json`)
The hard-won knowledge. Key highlights:

- **L001-L003**: MCP Shell quirks (git stdout, PATH resets, PowerShell only)
- **L005**: Orientation kills sessions — be surgical
- **L008**: System Python != embedded Python (3.14/3.11 vs 3.13.11)
- **L009**: bash_tool reports Linux even when Windows MCP tools are available
- **L012-L014**: Sessions die without warning — checkpoint everything
- **L017**: If the user slows you down, listen
- **L018**: Learning IDs must be globally unique (the problem that prompted this consolidation)

### Workflows (7 total, W000-W006)
The procedures:

- **W000**: Environment discovery — tool_search before anything
- **W001**: Context loading — buffer, todo, latest learnings
- **W002**: Session shutdown — update everything (but you may not reach this)
- **W003**: Git operations — use udc:execute_command
- **W004**: Error discovery — log in todo.json, move on
- **W005**: IGS workstation deployment — copy from bootstrap/
- **W006**: Rolling checkpoints — write breadcrumbs every 15 min (NEW)

### Manifest (`manifest.json`)
The new tracking system. Lists every authoritative file, its location,
its role, and which epoch it belongs to. Any session can run the health
check to verify system integrity in under 500 tokens.

---

## The Bootstrap System (Simplified)

Three layers, each simpler than the last:

**Layer 1 — Project Settings** (`_AI_ORIENTATION.md`)  
Loaded automatically by claude.ai. A thin pointer (~400 tokens) that says
"run tool_search, then read claude_start.json." Shared across both
workstations because it's tied to your account, not the machine.

**Layer 2 — Machine Config** (`claude_start.json`)  
Lives at `C:\dev\claude_start.json` on each workstation. Contains the
verification protocol and context loading sequence. Template in
`ksnlabs/bootstrap/` — copy to each machine, edit the machine name.

**Layer 3 — Failsafe Trigger**  
You say "wake up" or "bootstrap." The AI runs the tool_search sequence
regardless of what it thinks it is. No files needed.

If everything is broken: `_AI_ORIENTATION.md` in project settings has
the GitHub repo URLs. Clone fresh and rebuild.

---

## What Needs Your Attention

1. **Project settings are already correct.** The `_AI_ORIENTATION.md` you
   uploaded is the current version. No action needed.

2. **IGS deployment.** When you're next at IGS, pull the ksnlabs repo and
   copy `bootstrap/*` files to `C:\dev\`. Edit `claude_start.json` to say
   `"machine": "IGS"`. That's it.

3. **Git commit.** The ksnlabs repo has uncommitted changes (this session's
   work). When ready:
   ```
   cd C:\dev\ksnlabs
   git add -A
   git commit -m "Epoch 002: bootstrap hardening, manifest, consolidated learnings"
   git push
   ```

---

## File Structure (Current)

```
C:\dev\ksnlabs\
  .ai\
    buffer.jsonld              <- Working memory (updated every checkpoint)
    engram.jsonld              <- Long-term memory (stub, not yet populated)
    protocol.jsonld            <- Boot instructions
  bootstrap\                   <- Deployment templates for new machines
    .claude\CLAUDE.md
    .CLAUDE_VERIFY
    claude_start.json
  engram\
    manifest.json              <- NEW: system state tracker, epoch registry
    README.md                  <- System documentation
    benchmarks\                <- (empty)
    learnings\
      consolidated_epoch-002.json  <- Authoritative: L001-L018
      archive\                     <- Superseded files (audit trail)
    session-handovers\
      2026-02-14_*.json (5 files)
      2026-02-15_*.json (3 files)
      2026-02-16_orientation-survival.json
    workflows\
      2026-02-16_session-and-git-workflows.json  <- W000-W006
```

---

## On the Epoch/Manifest Idea

Your instinct about versioning and manifests is sound. What we have now is
a starting point — epochs as named snapshots, a manifest that tracks
authoritative files, and archived superseded files for audit. The hashing
piece (content hashes for integrity validation) and the restoration
capability (invoke a past epoch) are logical next steps but not urgent.
The current system solves the immediate problems: ID collisions, stale
file confusion, and "is everything consistent?" validation.

The naming convention is now: `consolidated_epoch-NNN.json` for learnings,
workflows keep their descriptive names, and the manifest is the source of
truth for what's current.

---

**Epoch**: 002 — bootstrap-hardening  
**Status**: Stable  
**Next learning ID**: L019  
**Next workflow ID**: W007
