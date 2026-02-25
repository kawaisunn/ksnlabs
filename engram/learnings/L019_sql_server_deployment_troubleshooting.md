# L019: SQL Server Database Deployment from Specification

**Category:** Database Design & Deployment  
**Date:** 2026-02-17  
**Context:** RP-315 ITD Material Source Database  
**Status:** Production-ready  

## What We Learned

Successfully deployed a complete SQL Server database from Excel specification through iterative troubleshooting:

### 1. SQL Server Data Path Discovery
- **Problem:** Assumed SQL Server data in `C:\Program Files\Microsoft SQL Server\MSSQL15.KSN\MSSQL\DATA\`
- **Reality:** User's instance stored data in `C:\dev\MSSQL15.KSN\MSSQL\DATA\`
- **Solution:** Query `sys.master_files WHERE database_id = 1` to find actual data paths
- **Lesson:** Never assume SQL Server paths - query the system catalog

### 2. Computed Column Requirements
- **Problem:** `CREATE TABLE` failed with "incorrect SET options" for computed column
- **Root Cause:** Persisted computed columns require `QUOTED_IDENTIFIER ON`
- **Solution:** Add `SET QUOTED_IDENTIFIER ON;` at script beginning
- **Lesson:** SQL Server is strict about SET options for indexed/computed columns

### 3. Foreign Key Data Type Matching
- **Problem:** FK constraint failed: "not the same length or scale"
- **Root Cause:** `LU_Owner.OwnerCode VARCHAR(50)` vs `Source.Owner VARCHAR(100)`
- **Solution:** Changed all FK columns to match PK size exactly (VARCHAR(50))
- **Lesson:** FK and PK must match EXACTLY - not just compatible types

### 4. Incremental Deployment Strategy
- **User Insight:** "Get everything setup first then make a list of things to modify"
- **Approach:** Deploy working database → verify → then refine naming/structure
- **Result:** Database operational within 2 hours despite 3 technical issues
- **Lesson:** Working > perfect. Iterate from functional baseline.

### 5. User Verification Catches Errors
- **My Error:** Repeatedly stated "11 tables (5 core + 6 lookups)"
- **Reality:** 10 tables (4 core + 6 lookups)
- **User Caught:** Listed all tables and corrected count
- **Lesson:** User verification is essential - AI can propagate counting errors

## Technical Implementation

**Database Created:**
- Name: ITD_MaterialSources
- Server: BIGSPIDER\KSN (home), portable to IGS domain
- Tables: 10 (4 core + 6 lookups)
- Fields: 81 mapped from ITD specification
- Lookups: 73 pre-populated values
- Test Types: 30 standards (Idaho, AASHTO, ASTM, CRD)

**Schema Features:**
- Normalized 3NF design
- Computed columns (e.g., DifferenceBtwAreaAndPlat)
- 7 foreign key relationships
- Audit trails (CreatedBy, CreatedDate)
- ArcGIS SDE compatible (Site table ready for SHAPE geometry)
- Temporal test result tracking

**Files Created:**
```
C:\dev\aggdb\
├── sql\
│   ├── 00_Deploy_All.ps1         # Automated deployment
│   ├── 01_Create_Database.sql    # DB creation with correct path
│   ├── 02_Create_Schema.sql      # All tables & data
│   └── 03_Fix_Owner.sql          # (obsolete - fixed in main)
├── QUICK_START.txt               # User instructions
├── MANIFEST.txt                  # File inventory
└── SESSION_SUMMARY.md            # Complete documentation
```

## Deployment Script Success

PowerShell script handles:
- Drop existing database (SET SINGLE_USER for active connections)
- Create new database with correct data path
- Execute schema script with all lookups
- Verify success/failure with exit codes
- Support both home (default) and IGS (-IGS flag) deployments

**Command:** `.\00_Deploy_All.ps1` or `.\00_Deploy_All.ps1 -IGS`

## Known Issues Deferred

**Naming Review Needed:**
- User established terminology: Site (location), Source (qualification), Resource (material)
- Current schema has naming conflicts: `Site.Source_No`, `Source.Source_Name`
- Decision: Deploy functional database first, refine naming in follow-up session

## Application to Future Work

**When deploying SQL Server databases:**
1. Query system catalogs for paths, don't assume
2. Set all required SET options at script start
3. Verify FK/PK data types match exactly (including size)
4. Test deployment script iteratively
5. Accept user verification and corrections
6. Deploy working version before perfecting naming
7. Document all path/configuration specifics
8. Create portable deployment scripts (home + remote)

**Token Efficiency:**
- Write files directly to disk vs through UI
- Use UDC tools instead of bash when on Windows
- Batch file creation when possible

## Related Learnings

- L001: Version control discipline
- L007: Script-based repeatability
- L010: User feedback integration
- W000: Bootstrap protocol (engram system)

## Success Metrics

✅ Database deployed in single command  
✅ User verified table creation  
✅ All FK relationships working  
✅ 73 lookup values populated  
✅ Scripts portable to IGS workstation  
✅ Feb 20 deadline achievable (4 days remaining)
