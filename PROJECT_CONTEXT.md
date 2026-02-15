# Project Context: ksnlabs Multi-Project Workspace

**Purpose**: Centralized development workspace and coordination hub for Idaho Geological Survey (IGS) research and public works projects.

**Last Updated**: February 15, 2026

---

## Overview

ksnlabs serves as a **coordination hub** for multiple IGS/KSN projects, providing:
- Cross-project scripts and utilities
- AI memory and session continuity (engram system)
- Shared documentation and templates
- Git version control for collaboration
- Knowledge accumulation across sessions

**Architecture**: Hybrid structure - ksnlabs coordinates, projects remain independent

---

## Active Projects (7)

### 1. aggdb / itdaggdb
**Location**: ` C:\dev\aggdb\`  
**Type**: Database project  
**Status**: 🟢 Active - **CRITICAL DEADLINE: Feb 20, 2026**  
**Grant**: RP-315 (,843, 30 months, FHWA-funded)  
**Objective**: GIS-based source management system for ITD aggregate materials  
**Partners**: Idaho Transportation Department & University of Idaho  

**Description**: Creating an integrated database and GIS system for managing aggregate material sources statewide. Point-centric three-entity model (Sites → Resources ← Sources) with QAMS qualification tracking.

### 2. ocritd
**Location**: ` C:\dev\ocritd\`  
**Type**: Python application - Document processing  
**Status**: 🟡 Stable (80% complete)  
**Objective**: Optical Character Recognition for ITD documents  

**Description**: Extract patterns from 40+ years of ITD test reports, plats, and permits. Modular architecture with plugin system, MSI packaging via WiX toolset. Critical for RP-315 data extraction.

**Build System**: BUILD.ps1, BUILD_ALL.ps1, VERIFY_BUILD.ps1  
**Packaging**: WiX 7.0 (MSI installer creation)  
**Dependencies**: BuildTools/artifacts/ (WiX packages)

### 3. cait
**Location**: ` C:\dev\cait\`  
**Type**: AI training framework  
**Status**: 🟡 Development (40% complete)  
**Objective**: License-free neural network for public works assistance  

**Description**: Training framework for developing AI models specific to public works and geological survey tasks. Includes venv management, training pipeline, model storage.

**Components**: training_framework.py, setup_ai_seed.ps1, training_config.yaml

### 4. keywrd
**Location**: ` C:\dev\keywrd\`  
**Type**: Keyword analysis tool  
**Status**: ⚪ Planned (10% complete)  
**Objective**: Central integration hub for all components  

**Description**: Keyword extraction and analysis system, intended to serve as integration point between ocritd, cait, and aggdb projects.

### 5. MSSQL15.KSN
**Location**: ` C:\dev\MSSQL15.KSN\`  
**Type**: SQL Server 2019 instance  
**Status**: 🟢 Running  
**Objective**: Development database server  

**Description**: Active SQL Server instance for database development and testing. **NEVER add to git** (protected by .gitignore).

### 6. SQLS2019
**Location**: ` C:\dev\SQLS2019\`  
**Type**: SQL Server 2019 instance  
**Status**: 🟢 Running  
**Objective**: Development database server  

**Description**: Active SQL Server instance for database development and testing. **NEVER add to git** (protected by .gitignore).

### 7. ksnlabs (This Repository)
**Location**: ` C:\dev\ksnlabs\`  
**Type**: Coordination hub and knowledge repository  
**Status**: 🟢 Active (100% - just completed git integration!)  
**Objective**: Multi-project coordination, AI collaboration, knowledge management  

**Description**: Central repository for cross-project scripts, documentation, engram knowledge system, and session continuity. Connected to GitHub for version control and collaboration.

---

## Repository Philosophy

### Hybrid Structure Rationale

**Why projects stay in C:\dev**:
1. **No disruption**: Projects with working build systems remain intact
2. **Flexibility**: Each project can have its own git repo if needed
3. **Safety**: Critical deadline (RP-315) won't be delayed by reorganization
4. **Gradual migration**: Projects can move into ksnlabs later if desired

**What ksnlabs provides**:
- Cross-project scripts and utilities
- AI memory and session continuity
- Shared documentation and templates
- Knowledge accumulation (engram system)
- Git version control

### Token Efficiency

**AI Memory System**:
- **Old approach**: ~22,500 tokens (markdown session notes)
- **New approach**: ~5,500 tokens (JSON-LD .ai/ system)
- **Savings**: 76% reduction in context loading

**Strategy**:
- Read operations: Cheaper (view existing files)
- Write operations: More expensive (creating/updating)
- Batch commits when possible, read frequently, write deliberately

### Session Continuity Strategy

1. **.ai/buffer.jsonld**: Immediate context (5k tokens, fast load)
2. **engram/session-handovers/**: Detailed session history (JSON files)
3. **SESSION_STATE.md**: Human-readable current status
4. **AI reads on session start**: Buffer → Latest handoff → Deep knowledge as needed

---

## File Organization

```
ksnlabs/
├── README.md                    # You're here
├── PROJECT_CONTEXT.md           # This file (deep background)
├── SESSION_STATE.md             # Current state, all projects
├── .gitignore                   # Comprehensive protection
│
├── .ai/                         # AI memory (JSON-LD, token-efficient)
│   ├── buffer.jsonld            # Working memory (5k tokens)
│   ├── engram.jsonld            # Long-term knowledge
│   ├── protocol.jsonld          # Handoff instructions
│   ├── architecture.md          # System documentation
│   └── quarantine/              # Untrusted AI contributions
│
├── engram/                      # Session continuity
│   ├── session-handovers/       # End-of-session JSON files
│   ├── workflows/               # Proven methods
│   ├── learnings/               # Extracted insights
│   └── benchmarks/              # Performance metrics
│
├── scripts/                     # Executable scripts
│   ├── system-admin/            # Windows, Linux, networking
│   ├── igs-workflows/           # IGS-specific (database, geospatial, etc.)
│   ├── development/             # Git helpers, environment setup
│   └── utilities/               # File management, automation
│
├── projects/                    # Project references
│   ├── README.md                # Documents actual project locations
│   ├── ocritd/                  # Links/docs for C:\dev\ocritd
│   ├── cait/                    # Links/docs for C:\dev\cait
│   └── ...
│
├── docs/                        # Documentation
│   ├── architecture/            # System design
│   ├── guides/                  # How-to guides
│   ├── references/              # Technical references
│   └── decisions/               # Architecture decision records
│
├── templates/                   # Reusable templates
└── tests/                       # Validation scripts
```

---

## Session Workflow (For AI)

### Starting a Session
1. Read ` .ai/buffer.jsonld` (immediate context, 5k tokens)
2. Read latest ` engram/session-handovers/{date}.json` (continuity)
3. Read ` SESSION_STATE.md` (human-readable status)
4. Lazy-load ` .ai/engram.jsonld` if deep knowledge needed
5. Proceed with work

### During Session
1. Work with files (local reads are cheap)
2. Create outputs
3. Document decisions in real-time
4. Note insights worth preserving

### Ending Session
1. Create session handoff in ` engram/session-handovers/`
2. Update ` .ai/buffer.jsonld` with new context
3. Update ` SESSION_STATE.md` with progress
4. Extract learnings to ` engram/learnings/` if applicable
5. Promote methods to ` engram/workflows/` if validated
6. Commit changes to git (batch if possible)

---

## Critical Tools

### SQL Database Management
**Location**: ` scripts/igs-workflows/database-management/`  
**Scripts**:
- ` export_database.ps1` - Backup databases to .bacpac files
- ` export_schema.ps1` - Export schema only (no data)
- ` import_database.ps1` - Restore databases from .bacpac

**Documentation**: ` docs/references/DATABASE_MANAGEMENT.md`  
**Use**: Essential for RP-315 database work, SQL Server backups

### Git Environment Setup
**Script**: ` C:\dev\Setup-GitEnv.ps1`  
**Purpose**: Configure git identity, SSH keys, credential manager  
**Status**: Already configured

### Claude Desktop Deployment
**Script**: ` scripts/system-admin/windows/deploy_claude_config.ps1`  
**Purpose**: Deploy Claude Desktop auto-load configuration  
**Documentation**: ` docs/guides/README_CLAUDE_START.md`

---

## Protected Content (Never in Git)

### Security (Credentials)
- ` C:\dev\ksnPWD/` - Password storage
- ` C:\dev\loginOwnership/` - Login credentials
- ` *.cer, *.key, *.pem, *.pfx` - Certificate files
- ` .env, *.secrets` - Environment secrets

### SQL Server Instances
- ` C:\dev\MSSQL15.KSN/` - SQL Server instance
- ` C:\dev\SQLS2019/` - SQL Server instance

### Build Artifacts
- ` C:\dev\BuildTools/artifacts/` - WiX toolset packages (53 files)
- ` C:\dev\wixSetup_MSIbuildTools/` - MSI build tools
- Project build outputs (dist/, build/, *.exe, *.msi)

### Archives (Old Versions)
- ` C:\dev\ocritd_archives/` - Old ocritd versions
- ` C:\dev\cait_vpast/` - Old cait versions
- ` C:\dev\ksnpy_archive/` - Archived Python scripts
- ` C:\dev\ocritd_v0.8.0_with_plugins/` - Preserved per user request

**All protected by**: ` .gitignore`

---

## Critical Deadlines

### RP-315 Database Design Presentation
**Date**: February 20, 2026 (5 days from now)  
**Status**: On track  
**Deliverable**: Database design presentation  
**Components**: Data dictionary, ERD diagram, SQL schema, sample queries

**Progress**:
- ✅ Three-entity model defined
- ✅ 81 database fields identified
- ✅ Point-centric architecture established
- 🔄 Data dictionary (next session)
- ⏳ ERD diagram
- ⏳ SQL schema
- ⏳ Sample queries

---

## For Future Migration

When migrating other projects to ksnlabs:
1. Create new directory in ` projects/`
2. Add project README.md with location/status
3. Update this PROJECT_CONTEXT.md
4. Update SESSION_STATE.md
5. Reference shared resources as needed
6. Consider if project should move into ` ksnlabs/` or stay independent

---

## License

**MIT License** for grant-funded work (RP-315, OCRITD publicly-funded components)  
**Proprietary** for IGS internal tools and workflows  
**See LICENSE file** for full details

---

## Technical Details

**Repository**: https://github.com/kawaisunn/ksnlabs  
**Owner**: kawaisunn  
**Primary Developer**: Christopher Tate (kawaisunn)  
**Email**: kawaisunn@gmail.com (GitHub: 261088879+kawaisunn@users.noreply.github.com)  
**AI Collaboration**: Claude (Anthropic)  

**Git Configuration**:
- Remote: ` git@github.com:kawaisunn/ksnlabs.git`
- Branch: master (local), main (remote)
- Credential Helper: manager-core (Windows)
- SSH Key: ` C:\Users\kawaisunn\.ssh\id_ed25519_kawaisunn`

**System**:
- OS: Windows
- Python: Custom offline environment
- SQL Server: 2019 (two instances)
- Build Tools: WiX 7.0, MSBuild, PowerShell

---

**Created**: 2026-02-13 (Session 01)  
**Updated**: 2026-02-15 (Git integration complete)  
**Projects**: 7 active  
**Structure**: Hybrid (coordination hub + independent projects)  
**Status**: Production-ready, git-connected, engram-enabled
