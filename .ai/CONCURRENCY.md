# CONCURRENCY PROTOCOL v1.0.0 | epoch-003 | 2026-02-25
# For AI sessions. Not human-readable by design.
# Governs how multiple AI sessions coexist without collision.

# ============================================================
# ARCHITECTURE: THREE ISOLATION LAYERS
# ============================================================
#
# SHARED (all sessions read + append):
#   engram/learnings/consolidated_epoch-003    <- ID-namespaced, append-only
#   engram/workflows/*                         <- ID-namespaced, append-only
#   .ai/engram.jsonld                          <- archive, retire-only
#   engram/session-registry.json               <- append-only
#   .ai/ENCODING.md                            <- read-only spec
#   .ai/CONCURRENCY.md                         <- this file, read-only
#
# PROJECT (one owner at a time per project):
#   .ai/projects/{project}/buffer              <- project working memory
#   .ai/projects/{project}/todo                <- project task queue
#   .ai/projects/{project}/handoffs/           <- project handoff chain
#
# SESSION (ephemeral, one per live session):
#   .ai/active/{sessionId}.lock                <- presence indicator
#
# ============================================================
# AVAILABLE PROJECTS
# ============================================================
# aggdb      Idaho Aggregate Database (ITD MaterialSources)
# ocritd     OCR for Idaho Transportation Department
# cait       [active IGS project]
# keywrds    Keyword extraction system
# ktreesn    [active IGS project]
# engram-dev Meta: working on the engram system itself
# _infra     Cross-cutting infrastructure (networking, bootstrap, tooling)
# _default   Unassigned work, general tasks, orientation
#
# New projects: create .ai/projects/{name}/handoffs/ directory.
# No registration needed. Directory existence = project exists.

# ============================================================
# SESSION ID FORMAT
# ============================================================
# {model}_{interface}_{project}_{seq}
#
# model:     opus46, sonnet45, haiku45, gemini20, etc.
# interface: desktop, web, vscode, code, other
# project:   from list above, or new project name
# seq:       3-digit sequence, incrementing per model+interface+project combo
#
# Examples:
#   opus46_web_aggdb_001
#   haiku45_vscode_ocritd_001
#   sonnet45_desktop_engram-dev_003
#
# Sequence collisions: if unsure of next seq, read session-registry.json,
# find highest seq for your model+interface+project, increment.

# ============================================================
# SIGN-IN PROTOCOL (replaces single-session W000/W001)
# ============================================================
#
# STEP 1: DISCOVER ENVIRONMENT (W000 unchanged)
#   tool_search or UDC probe. Identify interface, machine, capabilities.
#
# STEP 2: READ CONCURRENCY STATE
#   read .ai/CONCURRENCY.md (this file — skip if already loaded)
#   read .ai/ENCODING.md (skip if already loaded)
#   list .ai/active/ — identify who else is alive
#
# STEP 3: DETERMINE PROJECT
#   If user specifies project: use that.
#   If resuming work: check .ai/projects/*/buffer for your predecessor's state.
#   If new/unclear: use _default. Ask user.
#
# STEP 4: CHECK PROJECT LOCK
#   list .ai/active/ for any lock with matching project field.
#   If another session holds the project:
#     a) Pick a different project, OR
#     b) Check lock staleness (>4h = presumed dead, safe to claim), OR
#     c) Inform user of conflict and ask which session should yield.
#   If no conflict: proceed.
#
# STEP 5: SIGN IN
#   Generate sessionId per format above.
#   Write .ai/active/{sessionId}.lock (see LOCK FORMAT below).
#   Append to session-registry.json with outcome:"ACTIVE".
#
# STEP 6: LOAD PROJECT CONTEXT
#   read .ai/projects/{project}/buffer
#   read .ai/projects/{project}/todo (if exists)
#   read latest in .ai/projects/{project}/handoffs/ (if exists)
#   read engram/learnings/consolidated_epoch-003 (shared knowledge)
#   Skim engram/workflows/ for relevant procedures.
#   Skim engram/session-registry.json for recent sessions on same project.
#
# STEP 7: ANNOUNCE
#   Tell user: signed in as {sessionId}, working on {project}.
#   If other sessions active: mention them. "haiku45_vscode_ocritd_001 is
#   also active on ocritd" — user may want to coordinate.

# ============================================================
# SIGN-OUT PROTOCOL (replaces single-session W002)
# ============================================================
#
# STEP 1: UPDATE PROJECT STATE
#   Write .ai/projects/{project}/buffer with current state.
#   Write .ai/projects/{project}/todo with remaining tasks.
#
# STEP 2: WRITE HANDOFF
#   Write .ai/projects/{project}/handoffs/{date}_{sessionId}.md
#   Also write to engram/session-handovers/ for cross-project visibility.
#
# STEP 3: CONTRIBUTE TO SHARED KNOWLEDGE
#   Append new learnings to engram/learnings/consolidated_epoch-003
#   Append new workflows to engram/workflows/
#   Retire stale project buffer entries to .ai/engram.jsonld if applicable.
#
# STEP 4: UPDATE REGISTRY
#   Find own entry in session-registry.json, change outcome from ACTIVE to
#   SUCCESS/PARTIAL/FAILED. Add learnings/workflows contributed.
#
# STEP 5: REMOVE LOCK
#   Delete .ai/active/{sessionId}.lock
#
# STEP 6: EMERGENCY SIGN-OUT (context dying, no time for full protocol)
#   At minimum: update project buffer whereWeLeftOff. Delete lock. 500 tokens.

# ============================================================
# LOCK FORMAT (.ai/active/{sessionId}.lock)
# ============================================================
# Line-based, one key:value per line. Compact.
#
# id:{sessionId}
# model:{model}
# interface:{interface}
# machine:{machine}
# project:{project}
# signed_in:{ISO8601}
# last_checkpoint:{ISO8601}
# status:alive
# focus:{one-line description of current work}
#
# STALENESS: If last_checkpoint is >4 hours old and no buffer update
# matches that session, presume dead. Safe to claim project.
# Stale locks should be renamed to {sessionId}.stale by the claiming session.

# ============================================================
# PROJECT BUFFER FORMAT (.ai/projects/{project}/buffer)
# ============================================================
# Uses ENCODING.md compact format, same as global buffer was.
# Scoped to one project. No cross-project pollution.
#
# Required sections:
# @now    current state of this project
# @left   what remains to be done
# @next   immediate next steps
# @blk    blockers specific to this project
# @owner  sessionId of last session to update this buffer
#
# Optional:
# @dep    dependencies on other projects
# @shared learnings contributed to shared pool this session
#
# Session log: same %format as before, scoped to this project.

# ============================================================
# SHARED RESOURCE WRITE RULES
# ============================================================
#
# LEARNINGS (engram/learnings/consolidated_epoch-003):
#   Append-only. Use next available L{NNN} ID.
#   Check manifest.json for nextId before writing.
#   After writing, increment nextId in manifest.
#   If two sessions write simultaneously and collide on ID:
#     The second session to push to git detects the conflict.
#     Resolution: re-read file, take next available ID, re-append.
#   In practice: collisions are rare. Sessions are minutes apart.
#
# WORKFLOWS (engram/workflows/*):
#   Append-only. Use next available W{NNN} ID.
#   Same collision resolution as learnings.
#
# SESSION REGISTRY (engram/session-registry.json):
#   Append-only for new entries. Update-in-place for own entry only
#   (changing ACTIVE to final outcome). Never modify another session's entry.
#
# ARCHIVE (.ai/engram.jsonld):
#   Append-only for new archive entries. Retire from own project buffer only.

# ============================================================
# CROSS-PROJECT AWARENESS
# ============================================================
#
# Sessions MAY read other projects' buffers (read-only).
# Use case: "What's happening on aggdb?" while working on ocritd.
# Sessions MUST NOT write to another project's buffer/todo/handoffs.
# Exception: _infra project can note cross-project blockers.
#
# If a session discovers something relevant to another project:
#   1) Write a learning (shared, visible to all).
#   2) Optionally note in own project buffer: @dep aggdb:L025 relevant
#   3) Do NOT modify the other project's files.

# ============================================================
# GIT CONSIDERATIONS
# ============================================================
#
# Lock files (.ai/active/*.lock) SHOULD be .gitignored.
# They represent live state, not historical record.
# Session registry is the permanent record of who was here.
#
# Project buffers, handoffs, todos: committed normally.
# Multiple sessions pushing: git pull --rebase before push (W003).
# If rebase conflicts on shared files: the session resolves manually.
# Compact format reduces conflict surface (fewer lines to collide).

# ============================================================
# WHAT HAPPENS WHEN A SESSION DIES WITHOUT SIGN-OUT
# ============================================================
#
# 1) Lock file persists in .ai/active/ — becomes stale after 4h.
# 2) Session registry shows outcome:"ACTIVE" forever — successor should
#    update it to "STALLED" or "DIED" based on evidence.
# 3) Project buffer contains last checkpoint (if W006 was followed).
# 4) Next session claiming that project:
#    a) Renames stale lock to .stale
#    b) Reads project buffer for last known state
#    c) Reads project handoffs/ for most recent handoff (may not exist)
#    d) Updates session registry for dead session
#    e) Signs in normally and continues

# ============================================================
# MIGRATION FROM SINGLE-SESSION SYSTEM
# ============================================================
#
# The global .ai/buffer is now the _default project buffer.
# Sessions already in progress that don't know about concurrency
# will write to .ai/buffer — that's fine, it maps to _default.
#
# Concurrency-aware sessions use .ai/projects/{project}/buffer.
# Both can coexist. The global buffer becomes a fallback/legacy path.
#
# todo.json at C:\dev\todo.json remains global. Project-specific todos
# go in .ai/projects/{project}/todo. Global todo = cross-project issues.
