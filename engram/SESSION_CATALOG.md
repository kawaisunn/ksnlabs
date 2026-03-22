# SESSION CATALOG — Central Quick-Access Index
# Last Updated: 2026-03-15
# Updated By: opus46-web-antiquarian-vpn-architecture
# 
# PURPOSE: Human-scannable index of all AI sessions. Grouped by project,
# sortable by date, with one-line summaries and file references.
# 
# This file lives alongside session-registry.json (machine-readable).
# Both should be updated by every session that writes a handoff.
#
# CONVENTION: Every future session handoff MUST add its entry here.

---

## How to Use This Catalog

- **Find a session by project:** Scroll to the project section
- **Find a session by date:** Sessions are chronological within each section
- **Find what a session produced:** Check the "Key Files" column
- **Find the full handoff:** Follow the "Handoff" path
- **Check if something was VERIFIED:** Look at the Status column
  - ✓ = Tested and working
  - ◐ = Written but untested
  - ✗ = Known broken or stub
  - ? = Unverified assumption

---

## PROJECT: Engram System / Infrastructure

| Date | Session ID | Model | Machine | Interface | Summary | Status | Handoff |
|------|-----------|-------|---------|-----------|---------|--------|---------|
| 02-13 | unknown-initial-setup | ? | Bigspider | ? | Initial ksnlabs repo + engram bootstrap | ✓ | — |
| 02-14 | web-session-handoff | ? | Bigspider | Web | Web→Desktop handoff protocol established | ✓ | `02-14_web-session-handoff.json` |
| 02-14 | trust-recovery | ? | Bigspider | Desktop | Trust recovery after env detection failures | ✓ | `02-14_trust-recovery.json` |
| 02-14 | auto-load-deployed | ? | Bigspider | Desktop | Claude Desktop auto-load (CLAUDE.md) deployed | ✓ | `02-14_auto-load-deployed.json` |
| 02-15 | git-setup-complete | ? | Bigspider | Desktop | Git integration for engram repo | ✓ | `02-15_git-setup-complete.json` |
| 02-15 | git-integration-complete | ? | Bigspider | Desktop | Git integration finalized | ✓ | `02-15_git-integration-complete.json` |
| 02-16 | orientation-survival-001 | Sonnet? | Bigspider | Desktop | Lean orientation doc, L001-L008 | ✓ | `02-16_orientation-survival.json` |
| 02-16 | ocritd-stabilize-001 | Sonnet? | Bigspider | Desktop | Bootstrap fixes, L009-L010, W000 | ✗ died | — (no handoff) |
| 02-16 | phantom-0216 | ? | Bigspider | ? | PHANTOM: created bootstrap/, deleted files | ✗ phantom | — |
| 02-16 | ocritd-stabilize-002 | Sonnet? | Bigspider | Desktop | Restored files, manifest, epoch system, L012-L018, W001-W006 | ✓ | `02-16_stabilize-and-harden.json` |
| 02-24 | opus46-coldstart-recon-001 | Opus 4.6 | Bigspider | Desktop | Network recon, session registry created, W007, epoch-003 prep | ✓ | `02-24_opus46-coldstart-recon.json` |
| 02-25 | opus46-web-epoch003-001 | Opus 4.6 | Bigspider | Web | Epoch-003 declared, concurrency protocol v1.0 | ✓ | `02-25_opus46_web_engram-dev_001.md` |

## PROJECT: ITD_AggDB / ToiQa

| Date | Session ID | Model | Machine | Interface | Summary | Status | Handoff |
|------|-----------|-------|---------|-----------|---------|--------|---------|
| 02-16 | rp315-db-deploy-complete | ? | Bigspider | Desktop | First DB deployment: 10 tables, 81 fields, 6 LU tables | ✓ | — (partial, in .ai/) |
| 02-19 | (v2-schema) | ? | ? | ? | Schema normalization v2 | ✓ | `02-19_v2-schema-normalization.json` |
| 03-05 | sonnet46-web-aggdb-001 | Sonnet 4.6 | IGS | Web | HTML frontend v2/v3, FastAPI backend, Excel workbook (39 D1 sites) | ✓ | `03-05_sonnet46-web-aggdb-frontend-entry-001.md` |
| 03-05 | (doc-to-rec) | ? | ? | ? | DocToRec schema additions | ✓ | `03-05_doc-to-rec-complete.json` |
| 03-06 | (aggdb-deploy-intrusion) | ? | IGS | ? | AggDB frontend deployed to Intrusion, Rebecca has access | ✓ | `03-06_aggdb-frontend-deploy-intrusion.json` |
| 03-06 | opus46-desktop-aggdb-deploy | Opus 4.6 | IGS | Desktop | AggDB deployment finalization | ✓ | `03-06_opus46-desktop-aggdb-deploy.json` |

## PROJECT: DOCKSN Components (Ktreesn, Keywrds, Doksn/Ocritd)

| Date | Session ID | Model | Machine | Interface | Summary | Status | Handoff |
|------|-----------|-------|---------|-----------|---------|--------|---------|
| 02-15 | ocritd-git-init | ? | Bigspider | Desktop | Ocritd git repo initialized | ✓ | `02-15_ocritd-git-init.json` |
| 02-25 | (igs-desktop-recovery) | ? | IGS | Desktop | Recovery after IGS desktop setup | ✓ | `02-25_igs-desktop-recovery-full-handoff.md` |
| 03-07 | (doksn-build-kit) | ? | ? | ? | Doksn build kit documentation | ✓ | `03-07_doksn-build-kit.md` |
| 03-08 | opus46_desktop_ktreesn_001 | Opus 4.6 | IGS | Web+MCP | Ktreesn v0.5.0: 8 functions, 10 bugs fixed, standalone PS module | ✓ | `03-08_opus46_desktop_ktreesn_001.md` |
| 03-08 | (j-mirror-push) | ? | ? | ? | J-mirror push verified | ✓ | `03-08_j-mirror-push-verified.md` |
| 03-11 | (docksn-igs-inventory) | ? | IGS | ? | DOCKSN component inventory at IGS | ✓ | `03-11_docksn_igs_inventory.md` |

## PROJECT: CAIT Training

| Date | Session ID | Model | Machine | Interface | Summary | Status | Handoff |
|------|-----------|-------|---------|-----------|---------|--------|---------|
| 03-13 | opus46_web_cait-spec_001 | Opus 4.6 | Antiquarian | Web | CAIT_SPEC.json v1.0.0 — full system design: 3-actor model, security, curriculum, behavioral modes | ✓ | `03-13_cait_spec_antiquarian.md` |
| 03-14 | opus46-web-antiq-phase0-001 | Opus 4.6 | Antiquarian | Web | Phase 0 corpus (201 pairs), Lumo onboard doc, progress dashboard, SFT training script, block-sealing addendum | ◐ | `03-14_opus46-web-antiquarian-cait-phase0.md` |
| **03-15** | **opus46-web-docksn-cait-networking** | **Opus 4.6** | **Bigspider** | **Web** | **VPN discovery: Bigspider reaches Intrusion at 60ms. Concluded "diode" (WRONG — corrected next session). bootstrap_bigspider.ps1 written. Lumo source reviewed.** | **◐** | **`R:\VPN\VPN_SESSION\HANDOFF_20260315_cait_networking_discovery.md`** |
| **03-15** | **opus46-web-antiq-vpn-arch** | **Opus 4.6** | **Antiquarian** | **Web+MCP** | **CRITICAL: VPN is bidirectional (54ms ping from IGS→Bigspider). L086 corrected. Shadow launched. Three-machine architecture defined. Firewall fix script ready.** | **✓** | **`2026-03-15_vpn_bidirectional_architecture.md`** |

### CAIT Session Detail (03-14) — Key Files and Their Status

| File | Purpose | Status |
|------|---------|--------|
| `cait/training_data/phase0_identity_corpus.jsonl` | 201 Q&A pairs: identity, IGS, staff, AggDB, security | ◐ needs review |
| `cait/sft_train.py` | Real SFT script (LoRA + SFTTrainer) | ◐ written, untested |
| `cait/requirements.txt` | Added `trl`, `datasets` | ◐ deps not installed |
| `cait-training/CAIT_TRAINING_ONBOARD.md` | Lumo's complete operating manual | ◐ untested |
| `cait/Get-CaitProgress.ps1` | Training progress dashboard | ◐ untested |
| `cait/training_framework.py` | Original training script | ✗ BROKEN — inference only, no training |
| `Intrusion:.cait_audit/CAIT_Training_Assessment.md` | Concise findings + timeline | ✓ reference doc |
| `engram/session-handovers/2026-03-14_ADDENDUM_block-sealing-problem.md` | Cognitive load + delegation framework | ✓ reference doc |

## PROJECT: Lumo MCP Server

| Date | Session ID | Model | Machine | Interface | Summary | Status | Handoff |
|------|-----------|-------|---------|-----------|---------|--------|---------|
| 03-01 | (lumo-narrative) | ? | Bigspider | ? | Lumo narrative architecture design | ✓ | `03-01_lumo-narrative-architecture.json` |

## STANDALONE / Cross-Cutting

| Date | Session ID | Model | Machine | Interface | Summary | Status | Handoff |
|------|-----------|-------|---------|-----------|---------|--------|---------|
| 02-25 | (home-recovery) | ? | Bigspider | ? | Home workstation recovery | ✓ | `02-25_home-recovery.md` |
| 03-06 | (dc-git) | ? | ? | ? | Desktop Commander git setup | ✓ | `handoff_20260306_dc_git.json` |

---

## Conventions

- All handoff paths are relative to `C:\dev\ksnlabs\engram\session-handovers\`
- Status: ✓ verified working | ◐ written/untested | ✗ broken/stub | ? unverified
- Session IDs in parens (e.g., `(v2-schema)`) are reconstructed from filenames — no formal ID was assigned
- Bold row = current session
- Every session that writes a handoff MUST add a row to this catalog

---

## Quick Stats

- Total sessions logged: ~32
- Sessions on Bigspider: ~16
- Sessions on IGS (Antiquarian/Intrusion): ~13
- Sessions via Web: ~12
- Sessions via Desktop: ~17
- Phantom sessions detected: 1
- Sessions that died without handoff: 2
