# Engram Compact Encoding: Token Efficiency Experiment
# Testing: current JSON vs compact AI-native format
# Method: write the same information both ways, count tokens

# ============================================
# SAMPLE 1: A single learning entry
# ============================================

# --- CURRENT FORMAT (JSON) ---
CURRENT_JSON = '''
    {
      "id": "L019",
      "category": "session-integrity",
      "title": "Rapid sequential tool calls are a session-killing pattern",
      "detail": "Chaining 8+ tool calls in quick succession (e.g., port scanning, multi-file reads, network probes) consumes resources faster than the session can sustain. The session stalls or dies. Pattern: recon enthusiasm -> tool chain -> stall -> user recovers or session lost. Mitigation: batch where possible, pause between chains, checkpoint findings between probe sequences. One finding, one breadcrumb.",
      "confidence": "confirmed-by-self-inflicted-stall",
      "severity": "high",
      "origin": "opus46-coldstart-recon-001"
    }
'''

# --- COMPACT FORMAT ---
COMPACT = '''L019:si:!h:opus46-coldstart-recon-001
Rapid sequential tool calls kill sessions
8+ chained calls->stall/death. Batch,pause,checkpoint between. 1 finding=1 breadcrumb.'''

# ============================================
# SAMPLE 2: Buffer immediate context
# ============================================

CURRENT_BUFFER = '''
  "immediateContext": {
    "whatWeWereWorkingOn": "Network reconnaissance for cross-workstation access (BIGSPIDER <-> IGS)",
    "whyItMatters": "User splits time equally between home (BIGSPIDER) and IGS office (igs-antiquarian). Claude Desktop config only covers local filesystem. Extending access through RDP would enable AI-assisted work on IGS resources without being physically present.",
    "whereWeLeftOff": "Engram structural overhaul COMPLETE. Created: session registry, W007 Gravity Check, archive mechanism in engram.jsonld (retired rp315 to A001). Rewrote: protocol.jsonld (v2.0.0), README (v2.0.0). Updated: workflows (W001/W002 + W007), manifest. Still pending from earlier: RDP drive redirection config for IGS access.",
    "whatComesNext": "1) Configure RDP drive redirection on existing connection. 2) Test tsclient C access from IGS RDP session. 3) Consider adding mapped drive path to claude_desktop_config.json filesystem server. 4) Resume aggdb/OCRITD work from todo queue.",
    "urgency": "MEDIUM — infrastructure improvement, not deadline-driven",
    "blockers": ["Sophos firewall blocks everything except RDP to IGS", "Windows-MCP:Shell completely broken on BIGSPIDER"],
    "tokenStatus": "session recovering from stall, moderate overhead remaining"
  }
'''

COMPACT_BUFFER = '''@now net-recon BIGSPIDER<->IGS + engram overhaul done
@why user 50/50 home/IGS, need remote file access
@left engram v2 COMPLETE(registry,W007,archive,protocol,README). pending:RDP drive redir
@next RDP-drive-redir > test \\tsclient\C > claude config > resume aggdb/ocritd
@urg MED infra
@blk Sophos(all except 3389) Shell-MCP(broken)
@tkn low-moderate'''

# ============================================
# SAMPLE 3: Session registry entry
# ============================================

CURRENT_REGISTRY = '''
    {
      "sessionId": "opus46-coldstart-recon-001",
      "date": "2026-02-24",
      "model": "claude-opus-4.6",
      "interface": "claude-desktop",
      "machine": "HOME",
      "bootProtocol": "none-then-manual",
      "handoffWritten": "yes",
      "focus": "Cold-start orientation, IGS network reconnaissance, engram system contribution and structural improvements",
      "outcome": "PARTIAL",
      "learningsContributed": ["L019", "L020", "L021", "L022", "L023"],
      "workflowsContributed": ["W007"],
      "notes": "First Opus 4.6 session. Started with bash_tool (L009 violation), user corrected."
    }
'''

COMPACT_REGISTRY = '''opus46-coldstart-recon-001|2026-02-24|opus4.6|desktop|HOME|boot:none>manual|handoff:y|PARTIAL
focus:coldstart+IGS-recon+engram-overhaul
+L019-L023,+W007
note:1st opus4.6. L009 violation(bash first),user corrected'''

print("Samples ready for token counting")
