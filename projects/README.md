# Projects Directory

This directory contains references to IGS/KSN projects.

## Hybrid Structure Approach

**Important**: Most projects live in ` C:\dev\{project}\` as independent directories with their own build systems and workflows. This repository (ksnlabs) serves as a **coordination hub**, providing:

- Cross-project scripts and utilities
- Session continuity and engram knowledge
- Shared documentation and templates
- Git version control for collaboration

## Active Projects

### ocritd
**Location**: ` C:\dev\ocritd\`  
**Type**: Python application - Document processing  
**Status**: Active development  
**Description**: Optical Character Recognition for ITD documents, extracting patterns from 40+ years of test reports, plats, and permits

### cait
**Location**: ` C:\dev\cait\`  
**Type**: AI training framework  
**Status**: Active development  
**Description**: License-free neural network training for public works assistance

### keywrd
**Location**: ` C:\dev\keywrd\`  
**Type**: Keyword analysis tool  
**Status**: Active development  
**Description**: Keyword extraction and analysis system

### aggdb / itdaggdb
**Location**: ` C:\dev\aggdb\`  
**Type**: Database project (RP-315)  
**Status**: Active - **CRITICAL DEADLINE: Feb 20, 2026**  
**Description**: ITD Aggregate Materials Database - GIS-based source management system

### SQL Server Instances
**Locations**:
- ` C:\dev\MSSQL15.KSN\` - SQL Server 2019 instance
- ` C:\dev\SQLS2019\` - SQL Server 2019 instance

**Status**: Active  
**Description**: Database server instances for development work

## Working with Projects

### To work on a specific project:

```powershell
# Navigate to the actual project directory
cd C:\dev\ocritd

# Work within that project's structure
.\BUILD.ps1

# Use project-specific tools
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

## Why This Structure?

1. **No disruption**: Projects with working build systems stay intact
2. **Flexibility**: Each project can have its own git repo if needed
3. **Coordination**: ksnlabs provides shared resources without containing everything
4. **Gradual migration**: Projects can be moved into ksnlabs later if desired

## Future Options

Projects may eventually:
- Move into ` ksnlabs/projects/{name}/` (monorepo approach)
- Get individual GitHub repositories (multi-repo approach)
- Stay as independent directories (current hybrid approach)

Decision pending workflow evaluation and user preference.

---

**Updated**: 2026-02-15  
**Structure**: Hybrid (ksnlabs = hub, projects = independent)
