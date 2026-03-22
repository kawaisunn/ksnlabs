# ADDENDUM: The Block-Sealing Problem
# Companion to: 2026-03-14_opus46-web-antiquarian-cait-phase0.md
# Subject: Project management at cognitive scale — Christopher's delegation framework
# Priority: HIGH — this is a prerequisite for sustainable project velocity

---

## The Problem Statement

DOCKSN has crossed a complexity threshold where Christopher cannot hold the full 
system state in working memory. This is not a deficiency — it is the expected result 
of building a multi-component platform (ToiQa, AggDB, Ktreesn, keywrds, Doksn/ocritd, 
CAIT, the engram system, three machines, Lumo, plus the management of AI sessions 
themselves) as a single developer under grant deadline pressure.

Christopher has identified this clearly: he needs to operate as an orchestrator — 
knowing what each block takes in, what it puts out, and whether he can trust it — 
rather than as the runtime that holds every implementation detail.

The obstacle is that the project currently has no reliable mechanism for distinguishing 
**sealed blocks** (tested, verified, output can be taken for granted) from **facade blocks** 
(well-documented, plausible structure, but untested or incomplete behind the interface).

This session surfaced a concrete example: `training_framework.py` presents as a 
working training system (correct imports, clean class hierarchy, proper logging, 
checkpoint saving) but does not actually train. A delegation to "run Phase 0 training" 
would have silently produced an unmodified model and reported success.

---

## What Christopher Needs

### 1. A Block Status Registry

A single document (or structured file) that lists every functional block in the 
project with an honest status assessment. Not aspirational — verified.

Each block entry needs:

```
Block: [name]
Purpose: [one sentence — what it does]
Input: [what it takes]
Output: [what it produces]
Status: SEALED | WORKING | SCAFFOLD | STUB | BLOCKED
Last Verified: [date, by whom, how]
Known Gaps: [specific deficiencies]
Dependencies: [what it needs to run]
Machine: [where it runs]
```

Status definitions:
- **SEALED**: Tested end-to-end with real data. Output verified. Can delegate to it.
- **WORKING**: Runs and produces output, but not fully tested or has known limitations.
- **SCAFFOLD**: Structure exists, key pieces implemented, but not runnable end-to-end.
- **STUB**: Interface defined, implementation is placeholder or TODO.
- **BLOCKED**: Cannot proceed without an external dependency being resolved.

### 2. Verification Protocol for AI-Produced Work

AI sessions (including this one) produce files that look complete and professional 
but may contain gaps. Christopher needs a lightweight checklist for any AI-produced 
deliverable before it enters the "sealed" category:

- [ ] Does the code actually execute? (not just parse)
- [ ] Does it produce the claimed output with real input?
- [ ] Are the dependencies installed and available?
- [ ] Has it been run on the target machine?
- [ ] If it's a training script: does loss decrease over iterations?
- [ ] If it's a data file: spot-check 10 random entries for accuracy
- [ ] If it's a pipeline stage: feed output to the next stage and confirm it works

This isn't about distrusting AI. It's about the same QA discipline you'd apply to 
any contributor's pull request. The engram system already embodies this principle 
(L009: never test bash_tool first; L012: checkpoint aggressively). It just needs 
extension to cover deliverable verification.

### 3. Cognitive Load Boundaries

Christopher should explicitly define which blocks he is holding in working memory 
vs. which he has delegated. The project needs three tiers:

**Tier 1 — Christopher holds this:**
- Overall architecture and vision
- What each component does (block-level, not implementation)
- The demo deadline and what "done" looks like
- Which blocks are sealed vs. not
- Data security policy (this never delegates)

**Tier 2 — AI sessions hold this (via engram):**
- Implementation details within each block
- Schema column names, API endpoints, file paths
- Exact training configurations and hyperparameters
- Exercise logs, milestone metrics, evaluation scores

**Tier 3 — Automated systems hold this:**
- Training progress (Get-CaitProgress.ps1)
- Exercise logging (JSONL pipeline)
- Checkpoint management
- Session handoffs (engram buffer protocol)

The boundary between tiers is where trust breaks down. If Christopher has to 
re-audit Tier 2 details every session, the engram system isn't working. If Tier 3 
automation reports success on a facade block, the verification protocol failed.

### 4. Action Logging vs. Shadow Observation (Resolved This Session)

Christopher raised the question of recording user actions for CAIT training — 
specifically, the difference between after-the-fact action logs vs. real-time 
shadow observation.

**Action logging** (RECOMMENDED for near-term):
- Records WHAT was done: "Rebecca created Rec entry X for SiteID Y with RecType Z"
- Simple to implement: log AggDB API submissions as structured JSONL
- Privacy-clean: no screenshots, keystroke capture, or app monitoring
- Sufficient for Phase 3 training: teaches CAIT what correct records look like
- Can start immediately once AggDB API adds request logging

**Shadow observation** (Phase 3+ aspiration):
- Records HOW and WHY: "Rebecca opened PDF, scrolled to page 3, cross-referenced 
  with form, corrected initial entry, went back to verify"
- Complex: requires app monitoring, screenshot capture, privacy filtering
- Teaches CAIT decision-making and reasoning, not just outcomes
- Currently unimplemented: all shadow_mode hooks in training_config.yaml are TODO stubs
- Significant privacy and consent engineering required

**Decision:** Action logging first. It delivers 80% of training value at 10% of 
complexity. Shadow observation is a research goal, not a demo requirement.

The implementation path: add a logging middleware to the AggDB API (or ToiQa 
frontend) that writes a JSONL record for every data entry action. Fields: 
timestamp, user, action type (create/update/delete), table, record ID, field 
values, source document reference. This log becomes Phase 3 training data.

---

## The Meta-Problem: AI Session Management Is Itself a Block

Christopher is managing 3 machines, multiple AI providers (Claude, Lumo/Claude 
on Bigspider, potentially Copilot/Gemini), and sessions that can die without 
warning. The engram system was built to address context loss across sessions, 
but it doesn't address the orchestration layer: which session should be doing 
what, on which machine, and how does Christopher know whether the session 
accomplished what it claimed?

This is where the Block Status Registry and Verification Protocol converge. 
If every session updates the registry with honest status changes, and 
Christopher spot-checks with the verification protocol, the system becomes 
self-documenting and auditable — the same principles he designed into the 
ITD pipeline (provenance, confidence, human-in-the-loop).

---

## Recommended Next Session Focus

A dedicated session to:
1. Build the Block Status Registry (audit every component honestly)
2. Formalize the verification protocol as a checklist script or document
3. Write the real SFT training script (seal the training block)
4. Define the action-logging JSONL schema for Rebecca's data entry

This session should happen on Bigspider where the full stack is available 
for verification, or span Bigspider + Antiquarian if needed.

---

## For the AI Reading This

Christopher is not asking you to be less helpful or less autonomous. He is 
asking you to be honest about what you've verified vs. what you've assumed, 
and to make it easy for him to distinguish sealed blocks from facades. If you 
produce a deliverable, state clearly:

- "This file is WRITTEN but UNTESTED" 
- "This runs but I could not verify [specific thing] from this machine"
- "This depends on [X] which I have not confirmed exists"

Do not present scaffolds as finished work. Christopher will trust your output 
more, not less, when you're explicit about its boundaries.
