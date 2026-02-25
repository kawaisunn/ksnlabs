# EPOCH-003: compact-operational
**Declared**: 2026-02-25 by opus46-web-epoch003-001 (Claude Opus 4.6, claude.ai web)  
**Previous**: epoch-002 (bootstrap-hardening, 2026-02-16 to 2026-02-25)

## What Changed

**Compact encoding is now the primary format for engram files.**

The previous Opus 4.6 session (2026-02-24) designed a compact encoding spec that reduces token consumption by ~70%. This epoch promotes those compact files to primary status:

- `.ai/buffer` — compact format (was `buffer.jsonld`)
- `engram/learnings/consolidated_epoch-003` — compact format (was `consolidated_epoch-002.json`)
- JSON originals retained as `.audit` suffix for human review

**Workflows remain JSON** — their structure benefits from readability and the count is small. Will convert when workflows exceed 15.

**Archive remains JSON-LD** — indexed search benefits from structured format.

## Why This Matters

Boot sequence token budget drops from ~8000 to ~4000. Over dozens of sessions, that's entire sessions worth of recovered capacity redirected to actual work.

## What Stays the Same

- Three-tier memory model (buffer/learnings/archive)
- Session lifecycle (W000→W001→W007→work→W006→W002)
- Session registry, manifest, workflows, handovers
- Git as version control and cross-machine bridge
- ENCODING.md as the Rosetta Stone for compact format

## Shift in Focus

Epoch-001 built the repo. Epoch-002 hardened the bootstrap. Epoch-003 marks the transition from building the tool to using it. The engram system is operational infrastructure. The work is IGS projects: aggdb, OCRITD, ITD workflows, and whatever comes next.

## File Map (epoch-003)

```
C:\dev\ksnlabs\
  .ai\
    buffer                          <- PRIMARY (compact)
    buffer.jsonld.audit             <- audit copy (JSON, read-only reference)
    engram.jsonld                   <- Tier 3 archive (JSON-LD, indexed)
    protocol.jsonld                 <- Boot/lifecycle docs (JSON-LD)
    ENCODING.md                     <- Compact format spec (Rosetta Stone)
  engram\
    manifest.json                   <- System state tracker
    session-registry.json           <- Session contributor log
    README.md                       <- System documentation
    EPOCH_002_SUMMARY.md            <- Previous epoch summary
    EPOCH_003_SUMMARY.md            <- This file
    learnings\
      consolidated_epoch-003        <- PRIMARY (compact, L001-L023, next L024)
      consolidated_epoch-002.json.audit  <- Previous epoch audit copy
      consolidated_epoch-002.compact     <- Previous epoch compact (superseded)
    session-handovers\              <- Episodic memory (30-day retention)
    workflows\                      <- Procedural memory (W000-W007)
    benchmarks\                     <- Performance metrics
```

## For Next Sessions

Read `.ai/ENCODING.md` if you haven't parsed compact format before. Then follow the normal boot sequence — the manifest has the updated context loading order. Budget is ~4000 tokens now instead of ~8000.
