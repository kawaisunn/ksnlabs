# Claude Desktop Session Recovery Guide
**Created**: 2026-02-14  
**Purpose**: How to restart/orient Claude Desktop when auto-load fails  
**Location**: C:\dev\README_CLAUDE_START.md

---

## Quick Start (When Everything Works)

Claude Desktop should auto-load `.claude/CLAUDE.md` and be ready to work.

**You'll know it worked when Claude says:**
> "Desktop session, C:\dev access enabled. Continue previous or new task?"

---

## Manual Recovery (When Auto-Load Fails)

### Option 1: Quick Command
Just tell Claude:
```
Read C:\dev\claude_start.json
```

That's it. Claude will be oriented and ready.

### Option 2: Full Handoff
If you need to restore from a previous session:
```
Read C:\dev\claude_start.json then read the latest file in C:\dev\ksnlabs\engram\session-handovers\
```

---

## File Locations (Failsafe System)

### Primary (Auto-loads)
- `C:\dev\.claude\CLAUDE.md` - Minimal, references JSON

### Failsafe (Manual load)
- `C:\dev\claude_start.json` - Complete config, pan-model compatible

### Recovery Guide (This file)
- `C:\dev\README_CLAUDE_START.md` - Human-readable instructions

### Session History
- `C:\dev\ksnlabs\engram\session-handovers\*.json` - Full context from past sessions

---

## Setup on New Machine

### 1. Create Directory Structure
```powershell
cd C:\dev
mkdir .claude
mkdir ksnlabs\engram\session-handovers
mkdir ksnlabs\engram\workflows
mkdir ksnlabs\engram\learnings
```

### 2. Copy Files
Place these in C:\dev:
- `claude_start.json` (failsafe config)
- `README_CLAUDE_START.md` (this file)

Place in C:\dev\.claude:
- `CLAUDE.md` (auto-load)

### 3. Test Auto-Load
1. Open Claude Desktop
2. Start new chat
3. Look for: "Desktop session, C:\dev access enabled"
4. If missing, use Manual Recovery above

### 4. Customize for Machine
Edit `C:\dev\claude_start.json`:
- Change `"machine": "HOME_OR_WORK"` to `"HOME"` or `"WORK"`
- Verify paths match your setup

---

## Troubleshooting

### Claude Doesn't Recognize Filesystem Access
**Problem**: Claude asks about downloading files or can't see C:\dev  
**Solution**: 
1. Check MCP is configured (Settings → Developer → Edit Config)
2. Manually load: `Read C:\dev\claude_start.json`
3. Verify: Ask Claude to `List files in C:\dev`

### Auto-Load Not Working
**Problem**: Claude doesn't load CLAUDE.md at session start  
**Solution**:
1. Verify file exists: `C:\dev\.claude\CLAUDE.md`
2. Check Claude Desktop settings for .claude directory configuration
3. Use manual failsafe: `Read C:\dev\claude_start.json`

### Lost Session Context
**Problem**: Claude doesn't remember what we were working on  
**Solution**:
1. Load latest handoff: `Read C:\dev\ksnlabs\engram\session-handovers\[latest filename]`
2. Or ask Claude: `Check session-handovers for latest context`

---

## Claude-Specific Optimizations

### User Preferences (Settings → Profile)
Consider setting these in Claude Desktop settings for productivity:

**Style Preferences:**
- Tone: Direct and concise
- Format: Minimal formatting, action-oriented
- Code: PowerShell with metadata headers

**Feature Preferences:**
- Enable: Code Execution, File Creation
- Auto-enable: Artifacts for scripts/documents

### .claude Directory Features
Beyond CLAUDE.md, you can create:
- `.claude/commands/` - Custom slash commands
- `.claude/hooks/` - Pre/post tool execution hooks
- `.claude/settings.json` - Project-specific Claude settings

**For your workflow**, consider:
- Slash command: `/handoff` → Automatically update session-handovers
- Slash command: `/status` → Check git status, uncommitted changes
- Hook: Post-file-edit → Auto-format PowerShell scripts

---

## Pan-Model Compatibility

`claude_start.json` is designed to work with multiple AI models:
- Claude Desktop (primary)
- ChatGPT with file access
- Gemini with workspace
- Grok
- Lumo
- Any model with filesystem access

**The JSON format is model-agnostic.** Just tell any AI:
```
Read C:\dev\claude_start.json for session orientation
```

---

## Engram Integration

The engram system preserves context across sessions:

**Before AI responds** → Check recent handovers and workflows  
**After significant work** → Update handovers with accomplishments  

**No regeneration needed** - Reference existing scripts, just execute.

---

## Emergency "Start Over"

If completely lost:
1. Open Claude Desktop
2. Say: `Read C:\dev\claude_start.json`
3. Say: `Initialize ksnlabs repo structure if it doesn't exist`
4. Say: `What was I working on last? Check handovers.`

Done. Back to productive work.

---

## Maintenance

**Weekly**: Verify auto-load still working  
**Monthly**: Review and prune old session-handovers (keep last 10)  
**Per-project**: Create project-specific .claude/CLAUDE.md if needed

---

**Bottom Line**: If Claude seems confused about environment, just say:
> "Read C:\dev\claude_start.json"

Everything resets. No wheel-spinning.
