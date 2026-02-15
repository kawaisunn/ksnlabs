# Project Context: ksnlabs Multi-Project Workspace

**Purpose**: Centralized development workspace for Idaho Geological Survey (IGS) projects with emphasis on AI collaboration, repeatable workflows, and knowledge accumulation.

**Last Updated**: 2026-02-15

---

## Repository Philosophy

### Hybrid Structure Approach

This repository uses a **hybrid structure** where ksnlabs serves as a **coordination hub** while actual projects remain independent:

- **ksnlabs/** = Git repository for coordination, scripts, documentation, engram
- **C:\dev\ocritd/** = Actual ocritd project (independent directory)
- **C:\dev\cait/** = Actual cait project (independent directory)
- **C:\dev\keywrd/** = Actual keywrd project (independent directory)
- **C:\dev\aggdb/** = Actual aggdb project (independent directory)

**Why Hybrid?**
1. No disruption to working projects during critical deadlines
2. Projects maintain their own build systems and workflows
3. ksnlabs provides cross-project coordination without containing everything
4. Gradual migration possible - projects can move into ksnlabs later if desired

---

## Active Projects (7)

### 1. aggdb / itdaggdb: ITD Aggregate Materials Database
**Status**: 🟢 Active (CRITICAL DEADLINE: Feb 20, 2026)  
**Location**: ` C:\dev\aggdb\`  
**Grant**: RP-315, \,843, 30 months, FHWA-funded  
**Objective**: GIS-based source management system for aggregate materials across Idaho

**Database Model**: Point-centric, three-entity architecture
- **SITE**: Discrete geographic location (point)
- **RESOURCE**: Material type/specification
- **SOURCE**: Site+Resource pairing (QAMS qualification)

**Deliverable**: Database design presentation Feb 20, 2026

---

### 2. OCRITD: Document Processing Engine
**Status**: 🟡 Stable (80% complete)  
**Location**: ` C:\dev\ocritd\`  
**Type**: Python application with MSI packaging  
**Objective**: Extract patterns from 40+ years of ITD test reports, plats, permits

**Features**:
- Optical Character Recognition (OCR)
- Pattern extraction from historical documents
- Build system with BUILD.ps1, BUILD_ALL.ps1
- MSI installer creation via WiX Toolset

**Critical for**: RP-315 database (provides historical data insights)

---

### 3. CAIT: AI Training Framework
**Status**: 🟡 Development (40% complete)  
**Location**: ` C:\dev\cait\`  
**Type**: Neural network training framework  
**Objective**: License-free neural network for public works assistance

**Features**:
- Custom training pipeline
- Virtual environment management
- Dependency tracking (requirements.txt)
- Training configuration (training_config.yaml)

---

### 4. KEYWRD: Keyword Analysis System
**Status**: ⚪ Planned (10% complete)  
**Location**: ` C:\dev\keywrd\`  
**Type**: Keyword extraction and analysis  
**Objective**: Integration hub for all components

---

### 5. ksnlabs: Coordination Hub
**Status**: 🟢 Active (100% - Just completed!)  
**Location**: ` C:\dev\ksnlabs\`  
**Type**: Git repository for multi-project coordination  
**Objective**: Provide cross-project scripts, documentation, engram knowledge

**GitHub**: https://github.com/kawaisunn/ksnlabs

---

### 6-7. SQL Server Instances
**Status**: 🟢 Running  
**Locations**:
- ` C:\dev\MSSQL15.KSN\` - SQL Server 2019 instance
- ` C:\dev\SQLS2019\` - SQL Server 2019 instance

**Purpose**: Database development and testing for RP-315

---

## Shared Resources

### SQL Database Management Tools
**Location**: ` scripts/igs-workflows/database-management/`  
**Tools**:
- ` export_database.ps1` - Backup SQL Server databases
- ` export_schema.ps1` - Export schema definitions
- ` import_database.ps1` - Restore databases

**Documentation**: ` docs/references/DATABASE_MANAGEMENT.md`

**Critical for**: RP-315 database backup/restore operations

---

### Claude Desktop Integration
**Location**: ` scripts/system-admin/windows/`  
**Tools**:
- ` deploy_claude_config.ps1` - Deploy Claude Desktop configuration

**Documentation**: ` docs/guides/README_CLAUDE_START.md`

**Purpose**: Automated Claude Desktop setup for AI collaboration

---

### Cross-Project Utilities
**Location**: ` scripts/utilities/`  
**Purpose**: Common scripts, helpers, automation tools shared across all projects

---

## AI Collaboration Framework

### Engram System (Dual Architecture)

**System 1: .ai/ (Token-Efficient)**
- Format: JSON-LD (machine-optimized)
- Token count: ~5,500 (76% reduction from markdown)
- Files: buffer.jsonld, engram.jsonld, protocol.jsonld
- Purpose: Fast session startup with minimal token usage

**System 2: engram/ (Comprehensive)**
- Format: Markdown + JSON (human-readable)
- Structure: 3-tier memory model
  - Tier 1: session-handovers/ (Episodic - 30 day retention)
  - Tier 2: learnings/ (Semantic - permanent insights)
  - Tier 3: workflows/ (Procedural - proven methods)

**Benefits**:
- 76% token reduction for AI context loading
- Complete session continuity
- Knowledge accumulation across sessions
- Human-reviewable audit trail

---

## Session Workflow (For AI)

### Starting a Session:
1. Read ` .ai/buffer.jsonld` (immediate context, 5k tokens)
2. Read latest ` engram/session-handovers/{date}.json` (continuity)
3. Load ` .ai/engram.jsonld` if deep knowledge needed (lazy-load)
4. Read ` SESSION_STATE.md` (human-readable overview)

### During Session:
1. Work with files in ` C:\dev\{project}\` (actual project locations)
2. Use ksnlabs for cross-project scripts and documentation
3. Document decisions in real-time

### Ending Session:
1. Create new session handoff in ` engram/session-handovers/`
2. Update ` .ai/buffer.jsonld` with new context
3. Extract learnings to ` engram/learnings/` if insights discovered
4. Update ` SESSION_STATE.md` with progress
5. Commit changes to GitHub

---

## Repository Organization

```
ksnlabs/
├── README.md                    # Overview and quick start
├── SESSION_STATE.md             # Current state, all projects
├── PROJECT_CONTEXT.md           # This file (deep background)
├── .gitignore                   # Security (credentials, SQL Server)
│
├── .ai/                         # JSON-LD memory architecture
│   ├── buffer.jsonld            # Working memory
│   ├── engram.jsonld            # Long-term knowledge
│   ├── protocol.jsonld          # AI handoff protocol
│   ├── architecture.md          # System documentation
│   └── quarantine/              # Untrusted AI contributions
│
├── engram/                      # Session continuity system
│   ├── session-handovers/       # Session JSON files
│   ├── workflows/               # Proven methods (Tier 3)
│   ├── learnings/               # Extracted insights (Tier 2)
│   └── benchmarks/              # Performance tracking
│
├── scripts/                     # Executable scripts
│   ├── system-admin/windows/    # Windows system administration
│   ├── igs-workflows/           # IGS-specific workflows
│   │   └── database-management/ # SQL Server tools (CRITICAL)
│   ├── development/             # Development helpers
│   └── utilities/               # Common utilities
│
├── projects/                    # Project references
│   └── README.md                # Documents actual locations
│
├── docs/                        # Documentation
│   ├── architecture/            # System design docs
│   ├── guides/                  # How-to guides
│   ├── references/              # Reference documentation
│   └── decisions/               # Architectural decisions
│
├── templates/                   # Reusable templates
│   └── project-structure/       # Project templates
│
└── tests/                       # Validation scripts
    ├── unit/
    └── integration/
```

---

## Critical Information

### Deadlines
- **RP-315 Database Design**: February 20, 2026 (5 days from git setup)

### Security
- **Credentials**: Never committed (protected by .gitignore)
- **SQL Server**: Instances excluded from git
- **Sensitive data**: All protected via .gitignore

### Backup Strategy
- **Primary**: 2TB external drive
- **Git**: Version control for scripts and documentation
- **SQL**: Database backup scripts in scripts/igs-workflows/database-management/

---

## Working with This Repository

### To work on a specific project:
```powershell
# Navigate to actual project directory
cd C:\dev\ocritd

# Work within project structure
.\BUILD.ps1
```

### To use cross-project tools:
```powershell
# Navigate to ksnlabs
cd C:\dev\ksnlabs

# Run utility scripts
.\scripts\igs-workflows\database-management\export_database.ps1

# Update session state
# Edit SESSION_STATE.md
```

### To start an AI collaboration session:
1. Navigate to ` C:\dev\ksnlabs`
2. Pull latest: ` git pull`
3. Review ` SESSION_STATE.md`
4. AI loads ` .ai/buffer.jsonld` for context
5. Proceed with work

---

## License

- **Grant-funded work** (RP-315, OCRITD): MIT License
- **IGS proprietary** (engram system): Internal use only
- See individual project licenses for specifics

---

## For Future Migration

When migrating other projects into ksnlabs:
1. Create new directory in ` projects/`
2. Move or reference actual project
3. Update this PROJECT_CONTEXT.md
4. Update SESSION_STATE.md
5. Commit changes

Projects may eventually:
- Move into ` ksnlabs/projects/{name}/` (monorepo)
- Get individual GitHub repositories (multi-repo)
- Stay as independent directories (hybrid - current approach)

---

**Repository**: https://github.com/kawaisunn/ksnlabs  
**Owner**: kawaisunn (Christopher Tate)  
**Email**: kawaisunn@gmail.com  
**Organization**: Idaho Geological Survey (IGS)  
**AI Collaboration**: Claude (Anthropic)  
**Updated**: 2026-02-15 (Git setup complete)
