# handoff | opus46_web_engram-dev_001 | 2026-02-25
# model:claude-opus-4.6 | interface:claude-web | machine:HOME/BIGSPIDER via UDC

## accomplished
- committed+pushed epoch-002 completion (85c2503): session registry, W007, compact encoding, archive activation
- declared epoch-003 (8e204af): compact encoding primary, JSON to .audit, ~70% token savings on boot
- designed+deployed concurrency v1.0 (178a370): project isolation, session locks, shared append-only resources
- created .ai/ONBOARD.md: universal AI onboarding for any model/interface
- created .ai/CONCURRENCY.md: full multi-session protocol
- seeded 8 project buffers: aggdb, ocritd, cait, keywrds, ktreesn, engram-dev, _infra, _default
- added L024 (concurrency protocol)
- onboarded haiku45_vscode for aggdb work via user relay

## decisions made
- compact is primary, JSON is audit-only (epoch-003 defining characteristic)
- workflows stay JSON until count exceeds 15 (readability still matters at small scale)
- archive stays JSON-LD (indexed search benefits from structure)
- lock files are gitignored (ephemeral state, not history)
- session registry is the permanent record, locks are the live indicator
- project claim is exclusive-write: one owner at a time, read-anyone
- stale threshold: 4 hours without checkpoint = presumed dead
- global .ai/buffer becomes legacy/summary, project buffers are authoritative

## files created
- .ai/CONCURRENCY.md
- .ai/ONBOARD.md
- .ai/active/.gitkeep
- .ai/projects/{aggdb,ocritd,cait,keywrds,ktreesn,engram-dev,_infra,_default}/buffer
- engram/EPOCH_003_SUMMARY.md
- engram/learnings/consolidated_epoch-003

## files modified
- .ai/buffer (global, now summary/legacy)
- .ai/ENCODING.md (v1.1, added concurrency codes)
- .ai/protocol.jsonld (updated file refs for compact)
- engram/manifest.json (v3.0.0, epoch-003, concurrency refs, nextId L025)
- engram/session-registry.json (+this session)
- engram/learnings/consolidated_epoch-003 (+L024)
- .gitignore (+lock file exclusions)
- todo.json (closed #3,#13,#14; added #15,#16)

## files renamed
- .ai/buffer.compact -> .ai/buffer (promoted)
- .ai/buffer.jsonld -> .ai/buffer.jsonld.audit (demoted)
- engram/learnings/consolidated_epoch-002.json -> .audit (demoted)

## git state
- 3 commits pushed to origin/main: 85c2503, 8e204af, 178a370
- working tree clean after final commit

## for successor on engram-dev
- first real concurrency test is haiku45_vscode_aggdb_001 — observe its behavior
- bootstrap/claude_start.json still references old file paths (todo#15)
- stale lock cleanup not yet tested — first death under concurrency will be the test
- consider W008: concurrency-aware gravity check (project-scoped goal assessment)

## user state
- engaged, productive session. directing haiku in vscode simultaneously.
- asking right architectural questions. trusts the system enough to run concurrent AI.
- Helmer, ID. morning session.
