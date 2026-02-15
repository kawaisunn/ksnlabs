# Engram: AI Knowledge Management System

**Purpose**: Accumulate and preserve knowledge across AI collaboration sessions

## Dual System Architecture

This repository uses TWO complementary memory systems:

### System 1: .ai/ (JSON-LD, Token-Efficient)
**Location**: ` .ai/`  
**Format**: JSON-LD (machine-optimized)  
**Purpose**: Token-efficient context loading  
**Token Count**: ~5,500 (76% reduction from markdown)

**Files**:
- ` buffer.jsonld` - Working memory (immediate context)
- ` engram.jsonld` - Long-term memory (lazy-loaded)
- ` protocol.jsonld` - AI handoff instructions
- ` architecture.md` - System documentation

**Use Case**: Fast session startup with minimal tokens

### System 2: engram/ (Session Handoffs, Proven)
**Location**: ` engram/`  
**Format**: Markdown + JSON (human-readable, detailed)  
**Purpose**: Comprehensive session continuity  

**Subdirectories**:
- ` session-handovers/` - End-of-session JSON files (Tier 1: Episodic)
- ` learnings/` - Extracted insights and patterns (Tier 2: Semantic)
- ` workflows/` - Proven methods and procedures (Tier 3: Procedural)
- ` benchmarks/` - Performance metrics and comparisons

**Use Case**: Detailed session history, audit trail, human review

## How They Work Together

**Session Start**:
1. AI loads ` .ai/buffer.jsonld` (5k tokens, immediate context)
2. AI lazy-loads ` .ai/engram.jsonld` if needed (deeper knowledge)
3. AI reads latest ` session-handovers/{date}.json` for continuity

**Session Work**:
- AI accumulates knowledge in working memory
- Decisions documented in real-time

**Session End**:
1. AI creates new session handoff in ` session-handovers/`
2. AI updates ` .ai/buffer.jsonld` with new context
3. AI extracts learnings to ` learnings/` if insights discovered
4. AI promotes proven methods to ` workflows/` if validated
5. Old buffer entries archived to ` .ai/engram.jsonld` (>3 sessions)

## 3-Tier Memory Model

### Tier 1: Session Handovers (Episodic Memory)
**Retention**: 30 days  
**Content**: What happened in each session  
**Format**: JSON files with timestamps  
**Location**: ` session-handovers/`

Example: ` 2026-02-15_git-setup-complete.json`

### Tier 2: Learnings (Semantic Memory)
**Retention**: Permanent  
**Content**: Extracted insights, "what we learned"  
**Format**: Markdown documents  
**Location**: ` learnings/`

Example: ` 20260215_hybrid-git-framework-pattern.md`

### Tier 3: Workflows (Procedural Memory)
**Retention**: Permanent  
**Content**: Proven methods, "how to do X"  
**Format**: Executable scripts + documentation  
**Location**: ` workflows/`

Example**: ` git-setup-procedure.md`, ` backup-before-changes.ps1`

## Benefits

1. **Token Efficiency**: 76% reduction via .ai/ JSON-LD
2. **Session Continuity**: Comprehensive handoffs preserve context
3. **Knowledge Accumulation**: Insights don't get lost
4. **Audit Trail**: Every session documented
5. **Progressive Learning**: AI gets better over time
6. **Human Oversight**: Learnings reviewable by humans

## For AI

**On session start**:
- Read ` .ai/buffer.jsonld` first (fastest context)
- Read latest ` session-handovers/{date}.json` for continuity
- Load ` .ai/engram.jsonld` only if deep knowledge needed

**During session**:
- Document decisions in real-time
- Note insights worth preserving
- Identify proven methods

**On session end**:
- Create new session handoff JSON
- Update buffer with new context
- Extract learnings if applicable
- Promote workflows if validated

## For Humans

**To review recent work**:
- Read ` SESSION_STATE.md` (high-level)
- Browse ` session-handovers/` (detailed history)

**To understand insights**:
- Browse ` learnings/` directory

**To reuse methods**:
- Check ` workflows/` for proven procedures
- Execute scripts or follow documentation

**To verify AI performance**:
- Review ` benchmarks/` for metrics

---

**System Version**: 1.0.0  
**Created**: 2026-02-13  
**Updated**: 2026-02-15  
**Hybrid Architecture**: .ai/ (efficiency) + engram/ (completeness)
