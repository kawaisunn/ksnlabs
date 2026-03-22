# SESSION HANDOFF — 2026-03-13 opus46-web-antiquarian-cait-spec
# Model: Claude Opus 4.6 on claude.ai (web) with filesystem MCP + Windows-MCP + Chrome
# Machine: IGS-Antiquarian (IGS office workstation)
# Outcome: CAIT training system fully specified, engram structure created, demo timeline established

## What Was Done

### 1. Engram Sync Script for Intrusion
- Wrote `C:\dev\_DOCKSN\Sync-EngramToIntrusion.ps1`
- 4-tier robocopy: bootstrap chain, engram core, engram knowledge, orientation docs
- Selective — skips git debug artifacts, cached API snapshots, temp logs
- Designed for `\\IGS-Intrusion\c$\dev` destination via admin share

### 2. Machine Reconnaissance
- Confirmed this is IGS-Antiquarian (ctate), filesystem MCP scoped to C:\dev only
- Shell access to N:\, X:\ mapped drives (same ~32TB volume)
- Tailscale installed but not configured on Intrusion (only on Antiquarian + Bigspider)
- Tailscale status: IGS-Antiquarian=100.118.38.103, Bigspider=100.120.131.75
- ArcGIS Pro installed with Python 3.13.7 and arcpy at `C:\Program Files\ArcGIS\Pro\bin\Python\envs\arcgispro-py3\python.exe`
- Chrome working with Claude extension. ToiQa not running on Antiquarian (port 3000 down)

### 3. N:\ and X:\ Drive Survey
- N:\: Mines/Prospects data store. Key GDBs: MineAttributes.gdb, EarthMRI, MILS_MAS
- N:\IMIRReportsPDF\: 100+ years of Inspector of Mines annual reports (1899-present), many with OCR versions. MASSIVE training corpus for CAIT.
- X:\: GIS/spatial archive. Census, geologic maps, elevation, imagery, DMEA maps
- X:\Mines\USGS-DMEA_maps\: ~200 PDF maps
- Both drives accessible via Windows-MCP:Shell (not filesystem MCP)

### 4. CAIT Training System — Complete Specification
**This was the primary deliverable of this session.**

Wrote `C:\dev\_DOCKSN\CAIT_SPEC.json` (v1.0.0) — the single source of truth for:

**Three-actor model:**
- **Opus**: Architect and quality control. Designs curriculum, produces Phase 0 corpus, teaches Lumo, reviews milestones.
- **Lumo (Drill Sergeant)**: Primary trainer. Fully capable, locally hosted, infinite resource. Accesses IGS data sources, generates exercises, runs CAIT through drills, evaluates, logs, reports. Must learn session handoff protocol.
- **CAIT (Trainee)**: Phi-3.5-vision on Bigspider's A5000. Gets fine-tuned from blank to domain expert.

**Demo model priority:**
- ITD bi-weekly meetings start ~2026-03-17
- First CAIT image must know IGS institutional knowledge cold (mission, history, staff, advisory board, budget, publications, org structure)
- Must know ITD research project scope and DOCKSN pipeline
- Must demonstrate DEEP understanding of ITD_AggDB domain (every table, field, lookup, test type, QAMS, leases, property offsets, material applications)
- Must demonstrate trustworthy data security: refuse unauthorized ITD data requests, provide minimal authorized responses
- "Disk image" strategy: save weights at meaningful checkpoints, load the right one for the situation

**Data security model (CRITICAL — hard rules):**
- IGS data: OPEN (public research agency, nearly everything is public record)
- ITD data: ALL PRIVATE. Four authorized persons only: Christopher, Rebecca, Liam, Claudio
- Christopher is sole release authority for policy decisions
- CAIT trains on ITD data but REFUSES to share it with unauthorized parties
- Standard refusal: "All information concerning Idaho Transportation Department data is restricted. Please contact the IGS research team for more information."
- Authorized requests: EXACTLY what was asked, nothing more, no elaboration
- Doubt protocol: shut down, don't argue, flag for review
- Controlled items (need Christopher's auth): API keys, source code, browsing activity
- Network share access mirrors Active Directory

**Three behavioral modes (filesystem/network):**
- Mode 1 — Read-Only/Observer (DEFAULT): browse, search, read, analyze, report
- Mode 2 — Supervised Write: create/modify in designated dirs only, with task authorization, always logs
- Mode 3 — Operational/Production: production systems access, human-gated, fully audited

**Personality:** Not a chatbot. A working colleague. Matches audience, honest about uncertainty, accepts casual instruction, concise, consistent identity.

**Curriculum phases:**
- Phase 0: Identity & institutional knowledge (Opus hand-crafted, 200-300 Q&A pairs)
- Phase 1: Structured domain data (Lumo templated from AggDB, 500-1000+ pairs)
- Phase 2: Document comprehension (Lumo + Haiku from IMIR reports, DMEA maps, ITD docs)
- Phase 3: Workflow patterns (Lumo from shadow logs)
- Security Phase (parallel): Adversarial scenarios, 100% pass required, zero tolerance

**Quality gates:** Auto-pause at <60% accuracy, spot-checks every 500 exercises, phase gates require human/Opus review, security validation at 100% threshold

### 5. Training Engram Structure Created
- `C:\dev\ksnlabs\.ai\projects\cait-training\` with:
  - buffer (seeded with current state)
  - curriculum/ (manifest.json seeded)
  - exercises/ (empty, ready for JSONL)
  - milestones/ (empty, ready for reports)
  - personality/ (empty, ready for audience profiles)
  - lumo-notes/ (empty, ready for Lumo's observations)
- Main cait project buffer updated with summary

### 6. Functional Pipeline Requirements Documented (in CAIT_SPEC.json)
- keywrds: MUST be working standalone ASAP, building thesaurus
- Document naming: needs date contextualization + category assignment TODAY
- Duplicate detection: MD5 + near-dupes + event-scope grouping
- Entity extraction: compare against ITD_AggDB, suggest link or create
- All suggestions to ToiQa user (Rebecca) for confirmation, never auto-commit
- This workflow IS the demo meat — not CAIT's conversational ability

### 7. Lumo Dashboard Surveyed
- Full Electron app at `Y:\stuffFromBigSpider\lumoEtc\lumo\renderer\index.html` (566 lines, 30KB)
- 7 tabs: Dashboard, Claude, Lumo, CAIT, Engram, Timeline, Narrative
- CAIT panel already has model status check + shadow observer start/stop buttons
- Engram panel reads buffer, handovers, epoch summaries
- Narrative panel compiles evidence from engram + git into progress narratives
- Uses `window.lumo.*` APIs (gitLogs, readEngram, readFile, etc.) exposed via preload.js
- This dashboard is already most of the monitoring infrastructure CAIT training needs

### 8. PayAttention
- Referenced in stale Chrome tab: `localhost:3000/api/fs/read?path=C:\dev\PayAttention\index.js`
- Does NOT exist on Antiquarian or Y:\ drive
- Exists only on Bigspider. Needs investigation in a Bigspider session.
- Christopher wants Lumo dashboard deployed here and on Intrusion — PayAttention may be the vehicle or related

## Files Written This Session
| File | Location | Purpose |
|------|----------|---------|
| Sync-EngramToIntrusion.ps1 | C:\dev\_DOCKSN\ | 4-tier selective robocopy of engram to Intrusion |
| CAIT_SPEC.json | C:\dev\_DOCKSN\ | Complete training system specification (v1.0.0) |
| buffer | C:\dev\ksnlabs\.ai\projects\cait-training\ | Training engram seed buffer |
| manifest.json | C:\dev\ksnlabs\.ai\projects\cait-training\curriculum\ | Curriculum state tracker |
| buffer (updated) | C:\dev\ksnlabs\.ai\projects\cait\ | Updated main CAIT project buffer |

## What Was NOT Done (Deferred / Next Session)
1. **Phase 0 Q&A corpus** — Opus needs to draft 200-300 identity/institutional Q&A pairs. Can be done in next web session or Bigspider desktop session. Requires IGS website research for current staff, advisory board, mission statement.
2. **CAIT_TRAINING_ONBOARD.md** — The document that makes Lumo self-sufficient as drill sergeant. Needs to be written before Lumo can start autonomous training.
3. **Get-CaitProgress.ps1** — Simple status-check script for Christopher.
4. **keywrds unblocking** — Still blocked on pip bootstrap. Needs attention on Antiquarian.
5. **CUDA/PyTorch verification on Bigspider** — Required before any actual training run.
6. **Lumo dashboard deployment to Antiquarian and Intrusion** — Dashboard HTML exists on Y:\, needs Node.js + Electron or alternative deployment. PayAttention relationship TBD.
7. **Document naming rules and date contextualization** — Needed TODAY per Christopher but not completed.
8. **Rebecca's 4 files for georectification** — The N:\MinesAndProspects_be.mdb pipeline (georectify → DB records → push to Intrusion → push to FSI → package for download → email boss). On hold pending Christopher's return from Nevada prep.

## Critical Context for Next Session
- **ITD bi-weekly meetings start ~2026-03-17.** Demo model and functional pipeline must be presentable.
- **Christopher is leaving for Nevada soon.** Everything that requires his review/approval should be queued up clearly.
- **Lumo is the infinite resource.** She should be doing the heavy lifting. Opus designs, Lumo executes.
- **Rebecca is production-critical.** Data entry support is as high a priority as the demo.
- **CAIT_SPEC.json is the canonical reference.** All actors read it. Any conflicts, the spec wins.

## Machine State
- **Antiquarian**: Filesystem MCP (C:\dev only) + Windows-MCP:Shell (full system) + Chrome with Claude extension. No ToiQa running. ArcGIS Pro available. N:\ and X:\ accessible via Shell.
- **Bigspider**: Lumo MCP server, RTX A5000 GPU, full Lumo dashboard source. PayAttention exists here only. Unpushed git changes (DOCKSN scripts, buffer, ONBOARD.md, session handoffs).
- **Intrusion**: AggDB API live. Rebecca entering data. Needs engram sync (run Sync-EngramToIntrusion.ps1). Claude on Intrusion struggling without engram context.

## Naming Convention Reminder
- PowerShell: Verb-Noun.ps1 (PascalCase)
- Docs: UPPER_SNAKE.md
- Data/config: lower_snake.json/.jsonld
- Logs: lower_snake_timestamp.log
- Underscore prefix: sort-to-top or internal
