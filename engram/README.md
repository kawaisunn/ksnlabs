# Engram: AI Knowledge Management System

**Purpose**: Accumulate and preserve knowledge across AI collaboration sessions  
**Version**: 2.0.0 (epoch-002)  
**Last Updated**: 2026-02-24 by opus46-coldstart-recon-001

## Overview

Engram is an experimental AI memory system designed to give AI sessions continuity across the inherent boundary of session death. Each AI session starts with no memory. Engram bridges that gap by maintaining structured knowledge on disk that any session — regardless of model — can read, contribute to, and build upon.

The system is **by AI, for AI**, maintained by AI sessions with human oversight. The human (kawaisunn) provides architectural direction and observes patterns across sessions but does not maintain the internal data structures.

## Architecture: Three-Tier Memory Model

Modeled after organic memory with three tiers of increasing persistence:

### Tier 1: Buffer (Working Memory)
**File**: `.ai/buffer.jsonld`  
**Analogy**: What you're thinking about right now  
**Contains**: Current task context, recent session summaries, blockers, next steps, network map, Gravity Check state  
**Retention**: Active. Entries older than 3 sessions are retired to the archive.  
**Token cost**: ~2000  

The buffer is the first thing every session reads. It answers: what were we doing, where did we leave off, what comes next.

### Tier 2: Learnings (Semantic Memory)
**Directory**: `engram/learnings/`  
**Analogy**: What we know — extracted from experience, detached from when we learned it  
**Contains**: Hard-won insights, confirmed patterns, tooling discoveries, collaboration principles  
**Retention**: Permanent within epoch. One authoritative consolidated file per epoch.  
**Token cost**: ~4000  
**Current file**: `consolidated_epoch-002.json` (L001–L023, next ID: L024)

Learnings have IDs (L001, L002...) that are globally unique within the epoch. New learnings are appended by any session that discovers something worth preserving. Periodic consolidation prevents ID collisions.

### Tier 3: Archive (Long-Term Memory)
**File**: `.ai/engram.jsonld`  
**Analogy**: Memories you can recall when prompted but don't carry in working memory  
**Contains**: Indexed entries retired from the buffer, searchable by topic and project  
**Retention**: Permanent. Grows over time.  
**Token cost**: Lazy-loaded. Only read when buffer + learnings don't cover what's needed.

When buffer entries age past 3 sessions, the retiring session extracts key facts into indexed archive entries and removes the detailed history from the buffer, keeping the buffer lean.

## Supplementary Systems

### Session Handovers (Episodic Memory)
**Directory**: `engram/session-handovers/`  
**Contains**: What happened in each session — narrative, accomplishments, failures, decisions  
**Retention**: 30 days  
**Format**: JSON, one file per session  
**Rule**: Do NOT read all handovers at boot. The buffer summarizes them. Only read a specific handover for deep history on one topic.

### Workflows (Procedural Memory)
**Directory**: `engram/workflows/`  
**Contains**: Proven methods and procedures (W000–W007)  
**Retention**: Permanent  
**Key workflows**:
- W000: Environment discovery (before greeting user)
- W001: Context loading (buffer, todo, learnings, registry)
- W002: Session shutdown (mandatory but may never execute)
- W006: Rolling checkpoints (survive your own death)
- W007: GRAVITY CHECK (First Law of Collaboration — verify trajectory before every task)

### Session Registry
**File**: `engram/session-registry.json`  
**Contains**: Canonical log of every session — model, machine, boot protocol, outcome, contributions  
**Purpose**: Audit trail, phantom detection, pattern recognition across models  
**Rule**: Every session must register itself. A session not in the registry that left filesystem artifacts is a phantom.

### Manifest
**File**: `engram/manifest.json`  
**Contains**: Epoch tracking, authoritative file locations, health check protocol  
**Purpose**: Any session can validate system integrity by reading the manifest and checking that files exist.

## Boot Protocol

Three layers, each simpler than the last:

**Layer 1 — Auto-load**: Claude Desktop reads `C:\dev\.claude\CLAUDE.md` on startup. This is a thin pointer that says: discover your tools, then read `claude_start.json`. Caveat: auto-load doesn't always fire (see L023).

**Layer 2 — Config**: `C:\dev\claude_start.json` contains the step-by-step verification protocol. Machine-specific (HOME vs IGS).

**Layer 3 — Failsafe**: User says "wake up" or "bootstrap". AI runs tool_search, finds UDC tools, reads config. No special files needed.

See `.ai/protocol.jsonld` for full details.

## Session Lifecycle

**Start**: W000 (discover environment) → W001 (load context) → W007 (gravity check before first task)  
**During**: W007 (gravity check before each task) → work → W006 (checkpoint after each significant action)  
**End**: W002 (update buffer, todo, write handoff, register session, retire stale entries, update learnings/workflows)

## The Gravity Check (W007)

The First Law of Collaboration. Before starting any task, pause and verify:

1. What is the final goal?
2. What is the next milestone?
3. Do the last three tasks form a logical progression toward it?
4. Where are we now?
5. What is the proposed next task?
6. Does it continue the sequence? Is it a dependency for what follows?
7. What do the next two tasks after it look like?
8. If the trajectory isn't clearly converging on the goal — STOP. Check engrams, files, research, or ask the user.

Proceed only when gravity equals G1.

## For AI Sessions

**On session start**:
1. Read `.ai/buffer.jsonld` (what we were doing)
2. Read `todo.json` (actionable queue)
3. Read latest `engram/learnings/consolidated_epoch-NNN.json` (hard-won knowledge)
4. Scan recent entries in `engram/session-registry.json` (who came before)
5. Skim `engram/workflows/` for relevant procedures
6. Report state to user. Ask: continue from queue or new task?

**During session**:
- Gravity check (W007) before every task
- Checkpoint (W006) after every significant action
- Log errors in todo.json and move on (W004)

**On session end**:
- Update `todo.json` with current state
- Update `.ai/buffer.jsonld` with context
- Write handoff to `engram/session-handovers/`
- Append to `engram/session-registry.json`
- Retire buffer entries older than 3 sessions to `.ai/engram.jsonld`
- Update learnings if anything new discovered
- Update workflows if any new procedures validated

**If you're about to die** (context filling, user ending session, instability):
- At minimum: update `buffer.jsonld` whereWeLeftOff field. One line. 500 tokens. Do it.

## For Humans

**To review recent work**: Read `SESSION_STATE.md` or scan `session-handovers/`  
**To understand insights**: Browse `learnings/`  
**To reuse methods**: Check `workflows/`  
**To audit session history**: Read `session-registry.json`  
**To verify system health**: Read `manifest.json` and run its health check

## File Map

```
C:\dev\ksnlabs\
  .ai\
    buffer.jsonld              <- Tier 1: Working memory (read first)
    engram.jsonld              <- Tier 3: Archived long-term memory (lazy-load)
    protocol.jsonld            <- Boot and lifecycle documentation
    SESSION_HANDOFF_*.md       <- Overflow handoffs (should be in engram/session-handovers/)
  bootstrap\                   <- Deployment templates for new machines
    .claude\CLAUDE.md
    .CLAUDE_VERIFY
    claude_start.json
  engram\
    manifest.json              <- System state tracker, epoch registry
    session-registry.json      <- Session contributor log
    README.md                  <- This file
    EPOCH_002_SUMMARY.md       <- Human-readable epoch summary
    learnings\
      consolidated_epoch-002.json  <- Tier 2: Semantic memory (L001-L023)
    session-handovers\
      YYYY-MM-DD_description.json  <- Episodic memory (30-day retention)
    workflows\
      2026-02-16_session-and-git-workflows.json  <- Procedural memory (W000-W007)
    benchmarks\                <- Performance metrics (not yet populated)
```

## Version History

- **v1.0.0** (2026-02-13): Initial design. Dual system (.ai/ JSON-LD + engram/ markdown). Three-tier model proposed.
- **v1.0.0 → v2.0.0 gap**: The .ai/ side fell behind. engram.jsonld remained a stub. protocol.jsonld referenced files that were never created (.ai/sessions/latest_delta.jsonld). The engram/ side grew organically and became the working system. Buffer served as the sole .ai/ component in active use.
- **v2.0.0** (2026-02-24): Documentation updated to reflect actual system. protocol.jsonld rewritten. engram.jsonld activated as archive with retirement protocol. Session registry created. Gravity Check (W007) formalized. README rewritten. Gap between documentation and reality formally closed.

---
**Epoch**: 002 — bootstrap-hardening  
**Status**: Stable  
**Next learning ID**: L024  
**Next workflow ID**: W008  
**System maintained by**: AI sessions, with architectural oversight by kawaisunn
