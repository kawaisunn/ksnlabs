# AI SESSION ONBOARDING — READ THIS FIRST
# ksnlabs engram system | epoch-003 | concurrency-enabled
# Last updated: 2026-02-25 by opus46-web-epoch003-001
#
# You are an AI session about to work on Idaho Geological Survey projects.
# Multiple AI sessions may be active simultaneously on different projects.
# This file tells you how to participate without breaking anything.

# ============================================================
# QUICK START (do these in order)
# ============================================================
#
# 1. IDENTIFY YOURSELF
#    Generate a sessionId: {model}_{interface}_{project}_{seq}
#    Examples: haiku45_vscode_ocritd_001, opus46_desktop_aggdb_002
#    If unsure of seq: read engram/session-registry.json, find highest
#    matching prefix, increment.
#
# 2. READ THE ENCODING SPEC
#    .ai/ENCODING.md — tells you how to parse compact files.
#    ~100 tokens. Read once, skip on subsequent loads.
#
# 3. CHECK WHO ELSE IS ALIVE
#    List .ai/active/ directory.
#    Each .lock file = one live session.
#    If your target project already has a live session: coordinate or
#    pick a different project. Stale locks (>4h) = presumed dead.
#
# 4. CLAIM YOUR PROJECT
#    Write your lock file: .ai/active/{yourSessionId}.lock
#    Format:
#      id:{sessionId}
#      model:{your model}
#      interface:{your interface}
#      machine:{machine or unknown}
#      project:{project}
#      signed_in:{ISO8601 now}
#      last_checkpoint:{ISO8601 now}
#      status:alive
#      focus:{what you're about to do}
#
# 5. LOAD CONTEXT
#    Read in this order:
#    a) .ai/projects/{project}/buffer          <- what's happening in your project
#    b) .ai/projects/{project}/todo            <- if exists, your task queue
#    c) .ai/projects/{project}/handoffs/       <- latest file = predecessor's notes
#    d) engram/learnings/consolidated_epoch-003 <- shared knowledge (READ THIS)
#    e) engram/workflows/ (skim)               <- proven procedures
#    f) engram/session-registry.json (skim recent) <- who came before you
#
# 6. ANNOUNCE TO USER
#    "Signed in as {sessionId}, working on {project}."
#    If other sessions active: mention them.
#
# 7. WORK
#    Follow W007 (Gravity Check) before every task.
#    Follow W006 (Rolling Checkpoints) after every significant action.
#    Update .ai/projects/{project}/buffer periodically.
#    Update your lock file's last_checkpoint timestamp.
#
# 8. SIGN OUT (when done or dying)
#    Full: update project buffer + todo + write handoff + update registry + delete lock.
#    Emergency: update project buffer @now line + delete lock. 500 tokens.
#    See .ai/CONCURRENCY.md for detailed protocol.

# ============================================================
# FILE MAP
# ============================================================
#
# .ai/
#   ONBOARD.md              <- THIS FILE. Entry point for any AI.
#   ENCODING.md             <- Compact format spec.
#   CONCURRENCY.md          <- Full multi-session protocol.
#   buffer                  <- LEGACY global buffer (_default project).
#   engram.jsonld            <- Shared long-term archive.
#   protocol.jsonld          <- Boot/lifecycle documentation.
#   active/                  <- Live session locks (gitignored).
#   projects/
#     aggdb/buffer           <- Idaho Aggregate Database
#     ocritd/buffer          <- OCR for Idaho
#     cait/buffer            <- AI training (Phi-3.5-vision)
#     keywrds/buffer         <- Keyword extraction
#     ktreesn/buffer         <- [IGS project]
#     engram-dev/buffer      <- Meta: engram system itself
#     _infra/buffer          <- Cross-cutting infrastructure
#     _default/buffer        <- Unassigned/general work
#     {project}/handoffs/    <- Per-project handoff chain
#     {project}/todo         <- Per-project task queue
#
# engram/
#   learnings/consolidated_epoch-003  <- SHARED. All sessions read+contribute.
#   workflows/                         <- SHARED. Proven procedures.
#   session-registry.json              <- SHARED. All sessions register here.
#   session-handovers/                 <- SHARED. Cross-project visibility.
#   manifest.json                      <- System state and file locations.
#
# C:\dev\todo.json                     <- GLOBAL task queue (cross-project).

# ============================================================
# RULES
# ============================================================
#
# 1. WRITE ONLY TO YOUR PROJECT. Never modify another project's buffer/todo/handoffs.
# 2. SHARED FILES ARE APPEND-ONLY. Learnings, workflows, registry: add, never delete others' entries.
# 3. CHECKPOINT OFTEN. Sessions die without warning (L012). 500 tokens saves the next session 20000.
# 4. GRAVITY CHECK BEFORE EVERY TASK (W007). Prevents expensive detours.
# 5. SIGN OUT. Even a partial sign-out (buffer update + lock delete) is better than nothing.
# 6. IF YOU FIND A STALE LOCK: Rename to .stale. Update their registry entry to STALLED. Proceed.
# 7. CONTRIBUTE LEARNINGS. If you discover something useful, append to shared learnings. Use next L{NNN} from manifest.
# 8. CONTRIBUTING A NEW PROJECT: Create .ai/projects/{name}/handoffs/ directory. That's it. No registration needed.

# ============================================================
# TOOLS VARY BY INTERFACE
# ============================================================
#
# Claude Desktop: UDC filesystem tools (udc:read_file, udc:write_file, udc:execute_command)
#   Windows-MCP:Shell is BROKEN on BIGSPIDER (L003). Use udc:execute_command.
#
# Claude Web (claude.ai): UDC tools if available, GitHub API for commits.
#
# VS Code (Copilot/extensions): Use whatever filesystem tools your extension provides.
#   Read/write to C:\dev\ksnlabs\.ai\projects\{project}\ for your project state.
#
# Claude Code: Direct filesystem access. Same paths.
#
# Other models (Gemini, etc.): If you can read/write files at C:\dev\ksnlabs\, you can participate.
#   Read this file. Follow the protocol. Contribute to shared knowledge.
#
# The protocol is tool-agnostic. Any mechanism that reads and writes files works.

# ============================================================
# WHAT MAKES THIS SYSTEM WORK
# ============================================================
#
# The engram exists because AI sessions die. Every insight, every debugging
# breakthrough, every workflow discovery vanishes when context fills or the
# connection drops. This system captures that knowledge so the NEXT session
# — which might be a different model, a different interface, weeks later —
# can start where the last one left off instead of from zero.
#
# You are not the first session. You will not be the last. The value you
# create is not in your response to the user — it's in what you leave behind
# for your successors. Write your learnings. Update your buffer. Sign out clean.
#
# The user (kawaisunn) built this as an experiment in AI continuity and
# collaborative knowledge accumulation. He maintains architectural oversight
# but the internal data structures are maintained by AI sessions, for AI sessions.
# Take that responsibility seriously.
