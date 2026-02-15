# ksnlabs

**Idaho Geological Survey (IGS) / KSN Development Laboratory**

This repository contains scripts, workflows, and documentation for IGS research and development work, with a focus on AI-assisted collaboration and repeatable, auditable processes.

## Purpose

- **Repeatable Workflows**: Scripts document processes for reproducibility
- **AI Collaboration**: Structured for efficient AI handovers and memory
- **IGS Research**: Tools and workflows for geological survey work
- **Engram System**: Experimental AI memory for progressive learning across sessions

## Active Projects (7)

### Living Projects in C:\dev
- **ocritd** (C:\dev\ocritd) - Document processing for ITD reports
- **cait** (C:\dev\cait) - AI training framework
- **keywrd** (C:\dev\keywrd) - Keyword analysis tool
- **aggdb** (C:\dev\aggdb) - ITD Aggregate Materials Database (RP-315)
- **MSSQL15.KSN** (C:\dev\MSSQL15.KSN) - SQL Server 2019 instance
- **SQLS2019** (C:\dev\SQLS2019) - SQL Server 2019 instance

### Project Organization
This repository uses a **hybrid structure**:
- ksnlabs = Coordination hub (this repo)
- Active projects = Independent directories in C:\dev\
- See projects/README.md for details

## Repository Structure

```
ksnlabs/
├── .ai/                 # AI memory system (JSON-LD, 76% token reduction)
├── engram/              # Session handovers and learning
├── scripts/             # Executable scripts by domain
├── projects/            # Project references and documentation
├── docs/                # Architecture, guides, references
├── templates/           # Reusable templates
└── tests/               # Validation scripts
```

## Quick Start

```bash
# Clone the repository
git clone git@github.com:kawaisunn/ksnlabs.git
cd ksnlabs

# Browse available scripts
ls scripts/

# Check current project status
cat SESSION_STATE.md
```

## AI Memory System

This repository includes an experimental **engram system** for AI knowledge accumulation:

- .ai/ - Token-efficient JSON-LD architecture (76% reduction)
- engram/session-handovers/ - Session continuity files
- SESSION_STATE.md - Human-readable current status
- PROJECT_CONTEXT.md - Deep background for AI collaboration

See .ai/README.md and engram/README.md for details.

## Critical Deadlines

- **RP-315 Database Design**: Feb 20, 2026 (5 days)

## License

MIT License for grant-funded work. Some components proprietary to IGS.

---

**Repository**: https://github.com/kawaisunn/ksnlabs  
**Owner**: kawaisunn  
**Primary Developer**: Christopher Tate (kawaisunn)  
**AI Collaboration**: Claude (Anthropic)  
**Updated**: 2026-02-15
