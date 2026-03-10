# AI SESSION ONBOARDING — READ THIS FIRST
# ksnlabs engram system | epoch-003 | concurrency-enabled
# Last updated: 2026-03-10 by opus46-web-lumo-verification-001
#
# You are an AI session about to work on Idaho Geological Survey projects.
# This file tells you where you are, what tools you have, and how to participate.

# ============================================================
# WHERE YOU ARE — READ THIS BEFORE DOING ANYTHING
# ============================================================
#
# IF YOU SEE lumo_ TOOLS (lumo_read_file, lumo_write_file, etc.):
#   You are running in Claude Desktop on a WINDOWS MACHINE with Lumo MCP.
#   Lumo is a custom MCP server built at C:\dev\lumo\mcp-server.mjs.
#   It replaced Desktop Commander (DC), UDC, and the npx filesystem
#   server after months of instability, crashes, reinstalls, and lost
#   sessions. Lumo was first deployed on BIGSPIDER (2026-03-10) and is
#   being rolled out to all three workstations:
#     - BIGSPIDER (HOME)         — OPERATIONAL
#     - IGS-Antiquarian (WORK)   — deployment planned
#     - IGS-Intrusion (SERVER)   — deployment planned
#
#   You have DIRECT filesystem access to C:\dev on whichever machine
#   you're running on. You are NOT in a Linux sandbox. You are NOT web-only.
#   The lumo_ tools talk directly to the local filesystem via Node.js.
#
#   TO IDENTIFY WHICH MACHINE YOU'RE ON:
#     lumo_execute_command("hostname")
#     Or: lumo_read_file("C:\dev\claude_start.json") if it exists
#
#   DO NOT test bash_tool to figure out your environment — it returns
#   Linux regardless because Claude always has a Linux sandbox alongside
#   any MCP tools. This has tricked every session that tried it (L009).
#
# IF YOU SEE Desktop Commander tools (DC: or desktop-commander:):
#   LEGACY SETUP — may still appear alongside Lumo during transition.
#   DC is unreliable: start_process hangs unless shell:"cmd" on BIGSPIDER,
#   write_file/read_file timeout frequently, all 4 MCP servers can drop
#   simultaneously without warning (L076). Prefer lumo_ tools when both
#   are available. If only DC tools are present, you're on a machine that
#   hasn't been migrated to Lumo yet.
#
# IF YOU SEE Windows-MCP:Shell (without lumo_ tools):
#   LEGACY SETUP on IGS-Antiquarian or IGS-Intrusion, pre-Lumo migration.
#   Shell is PowerShell-only. Git not in PATH — use full path or bat files.
#
# IF YOU HAVE NO MCP TOOLS AT ALL:
#   You are web Claude (claude.ai) without local access.
#   You can still help via GitHub API, Google Drive, web search, and
#   the Linux sandbox for file creation. But you cannot touch C:\dev.
#
# THE CRITICAL LESSON (L009, confirmed across Sonnet and Opus):
#   bash_tool exists alongside MCP tools. It always reports Linux.
#   If you test bash first, you WILL conclude you're web-only.
#   Check for lumo_ or DC or Windows-MCP tools FIRST. Always.

# ============================================================
# LUMO MCP SERVER — TOOL REFERENCE
# ============================================================
#
# Lumo provides 12 tools via stdio transport (Claude Desktop spawns it):
#
# FILESYSTEM:
#   lumo_read_file(path)              — read any file on disk
#   lumo_write_file(path, content)    — write file, creates parent dirs
#   lumo_list_directory(path, depth)  — list files/dirs (depth 1-4)
#   lumo_scan_dev(max_depth)          — scan C:\dev tree (skips node_modules/.git)
#
# ENGRAM:
#   lumo_read_engram()                — full engram: buffer, handovers, learnings, workflows, epochs
#   lumo_read_buffer()                — current session buffer only
#   lumo_write_buffer(content)        — update buffer (JSON string)
#   lumo_compile_evidence()           — full evidence package: engram + git + file timeline
#
# GIT:
#   lumo_git_logs()                   — recent commits from all repos under C:\dev
#   lumo_git_status(repo_path)        — branch + uncommitted changes
#   lumo_git_exec(repo_path, args)    — run any git command
#
# SHELL:
#   lumo_execute_command(command, working_dir, timeout_sec) — run shell commands
#
# HISTORY — WHY LUMO EXISTS:
#   The path to Lumo was paved with pain. Desktop Commander (DC), UDC,
#   npx filesystem server, and Windows-MCP Shell were used across dozens
#   of sessions over months. The failure modes were numerous and costly:
#   - DC start_process hangs on BIGSPIDER (PowerShell default shell)
#   - DC write_file/read_file silently timeout
#   - All 4 MCP servers dropped simultaneously mid-session (L076)
#   - Config wiped on Claude Desktop reinstall (L049)
#   - MSIX dual-path bug requires writing config to both %APPDATA% and
#     the virtualized LocalCache path
#   - Windows-MCP:Shell broken on BIGSPIDER (FileNotFoundError on all cmds)
#   - npx @latest calls hung on npm registry fetch every launch
#   - Git not in PATH on Antiquarian breaks LFS, Chrome extension, MCP shell
#   - Hours lost to reinstalls, purges, config reconstruction
#
#   A previous Claude session proposed building a custom MCP server after
#   DC failed mid-stream. That idea became Lumo: one Node.js process,
#   stdio transport, no HTTP ports, no firewall issues, engram-aware tools
#   DC never had. First operational 2026-03-10 on BIGSPIDER. Planned for
#   all three machines to end the DC/UDC configuration churn permanently.
#
#   Source: C:\dev\lumo\mcp-server.mjs + C:\dev\lumo\lib\core.js

# ============================================================
# QUICK START (do these in order)
# ============================================================
#
# 1. IDENTIFY YOUR TOOLS AND MACHINE
#    If you see lumo_ tools: you're on a machine with Lumo. Good.
#    Run lumo_execute_command("hostname") to identify which one.
#    If unsure about tools: call tool_search("lumo") or tool_search("filesystem").
#
# 2. LOAD CONTEXT
#    a) lumo_read_buffer()              <- what's happening NOW
#    b) Read C:\dev\todo.json           <- global task queue
#    c) Skim latest session handoff     <- predecessor's notes
#    d) Read consolidated_epoch-003     <- shared learnings (L001-L079+)
#    e) Skim workflows                  <- proven procedures (W000-W007)
#
# 3. IDENTIFY YOURSELF
#    Generate a sessionId: {model}_{interface}_{project}_{seq}
#    Examples: opus46_desktop_aggdb_001, sonnet46_web_ocritd_002
#
# 4. CHECK CONCURRENCY
#    List .ai/active/ directory. Each .lock = live session.
#    If your target project has a live session: coordinate or pick another.
#    Stale locks (>4h): rename to .stale, proceed.
#    See .ai/CONCURRENCY.md for full protocol.
#
# 5. WORK
#    Follow W007 (Gravity Check) before every task.
#    Follow W006 (Rolling Checkpoints) after every significant action.
#    Update project buffer periodically.
#
# 6. SIGN OUT
#    Update buffer + write handoff + update registry + delete lock.
#    Emergency: update buffer @now line. 500 tokens. Better than nothing.

# ============================================================
# MACHINE TOPOLOGY
# ============================================================
#
# BIGSPIDER (HOME, kawaisunn)
#   IP: 129.101.139.85 | Tailscale: 100.120.131.75
#   GPU: NVIDIA RTX A5000 24GB VRAM
#   Role: Primary dev, training, Doksn builds
#   MCP: Lumo (lumo_ tools) — OPERATIONAL since 2026-03-10
#   Python: embedded 3.13.11 at C:\dev\ocritd\runtime\python\ (NEVER system Python)
#   Node: v25.7.0
#   J:\ drive: 32TB local, mirrors IGS Rift J:\ for offline Doksn processing
#   pwsh: C:\Program Files\PowerShell\7\pwsh.exe (use for PS scripts)
#
# IGS-Antiquarian (WORK, ctate.IGS2, Windows 11 Pro)
#   IP: 172.28.196.231 | Tailscale: 100.118.38.103
#   Role: IGS office workstation, RDP gateway to Intrusion
#   MCP: Lumo deployment planned (currently legacy DC/Windows-MCP)
#   Constraint: Sophos firewall blocks everything except RDP (3389)
#   Sophos quarantines MSI builds and unfamiliar executables
#   Git installed but NOT in PATH — use full path or bat files
#   SQL access: Invoke-Sqlcmd via SQLPS module (pre-installed)
#
# IGS-Intrusion (SERVER, Windows Server 2022, 172.20.222.123)
#   Role: SQL Server (ITD_AggDB), AggDB API (FastAPI on IIS port 80),
#         planned Doksn build+run environment
#   MCP: Lumo deployment planned
#   DB: ITD_AggDB on SQLEXPRESS (63 tables, v2 schema)
#   Native J:\ access to Rift file server
#   No Sophos — Christopher is admin, built to his specs
#   Python: 3.12.8 embeddable at C:\dev\aggdb\python\ (for API)
#
# Cross-machine file transfer:
#   Antiquarian <-> BIGSPIDER: RDP \\tsclient\J (robocopy)
#   Push script: C:\dev\push_top40_to_bigspider.ps1
#   15 sites (~2.7GB) verified synced as of 2026-03-08

# ============================================================
# PROJECT MAP
# ============================================================
#
# aggdb      — ITD Aggregate Materials Database (RP-315 grant deliverable)
#              SQL Server on IGS-Intrusion, FastAPI + HTML frontend
#              Rebecca doing data entry via http://IGS-Intrusion/aggdb
#
# ocritd     — Doksn: Document Processing System (renamed from OCRITD)
#              .NET 8 WinForms launcher + Python engine
#              engine/cait/ (8 enrichment modules)
#              engine/keywards/ (10 keyword modules)
#              Build: BUILD_ALL.ps1 on BIGSPIDER or IGS-Intrusion
#
# cait       — AI training and inference (Phi-3.5 Vision)
#              Shadow learning, document labeling, quality assessment
#              Weights on BIGSPIDER, inference on both machines
#
# keywrds    — Keyword extraction (standalone + Doksn-integrated)
#              Can be packaged standalone without .NET
#
# ktreesn    — PowerShell module for structured filesystem mapping
#              v0.5.0, 8 exported functions, GIS-aware
#              Repo: kawaisunn/ktreesn (private)
#
# lumo       — Electron app + MCP server (C:\dev\lumo)
#              Three-AI workspace (Claude, Lumo, CAIT tabs)
#              MCP server replaces DC/UDC/filesystem for Claude Desktop
#              Deploying to all three machines
#
# engram-dev — Meta: the engram system itself (this infrastructure)

# ============================================================
# RULES
# ============================================================
#
# 1. WRITE ONLY TO YOUR PROJECT. Never modify another project's buffer.
# 2. SHARED FILES ARE APPEND-ONLY. Learnings, workflows, registry.
# 3. CHECKPOINT OFTEN (W006). Sessions die without warning (L012).
# 4. GRAVITY CHECK BEFORE EVERY TASK (W007).
# 5. NEVER USE SYSTEM PYTHON. Embedded 3.13.11 only (L008).
# 6. CONFIRM BEFORE WRITING to production systems.
# 7. CONTRIBUTE LEARNINGS. If you discover something, append it.

# ============================================================
# WHAT MAKES THIS SYSTEM WORK
# ============================================================
#
# The engram exists because AI sessions die. Every insight, every
# debugging breakthrough, every workflow discovery vanishes when
# context fills or the connection drops. This system captures that
# knowledge so the NEXT session — different model, different interface,
# weeks later — can start where the last one left off.
#
# You are not the first session. You will not be the last. The value
# you create is not just in your response to the user — it's in what
# you leave behind for your successors.
#
# The user (kawaisunn/Christopher) built this as an experiment in AI
# continuity. He funds it personally from Helmer, ID. He maintains
# architectural oversight but the internal data is maintained by AI
# sessions, for AI sessions. Take that seriously.
