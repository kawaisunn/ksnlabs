# Database Management for ksnlabs

## Overview

GitHub **cannot host live SQL Server databases**. Instead, use one of these approaches:

## Recommended Approaches

### Option 1: Schema Version Control (Best for Most Cases)

**Store in GitHub:**
- SQL schema scripts (tables, views, procedures)
- Migration scripts
- Seed/test data scripts

**Local database instances:**
- Home: `localhost\SQLEXPRESS` → `itdaggdb_dev`
- IGS: `localhost\SQLEXPRESS` → `itdaggdb_dev`

**Workflow:**
```powershell
# Export schema to version control
.\export_schema.ps1

# Commit schema changes
git add schema/
git commit -m "Updated schema: added xyz table"
git push

# On other machine: pull and apply
git pull
sqlcmd -S localhost\SQLEXPRESS -d itdaggdb_dev -i "schema\apply_schema.sql"
```

**Pros:**
- Version controlled schema changes
- Small file sizes (text files)
- Clear change history
- Easy to review diffs

**Cons:**
- Data not included (only schema)
- Must manually sync test data

---

### Option 2: .bacpac Export/Import (For Data Sharing)

**Use when:**
- Need to share database WITH data
- Setting up new dev environment
- Creating snapshots for testing

**Workflow:**
```powershell
# Export database (schema + data)
.\export_database.ps1

# Check file size
# If < 100MB, can commit to Git
# If > 100MB, use network share or Tailscale

# On other machine
.\import_database.ps1 -BackupFile "exports\itdaggdb_2026-02-14.bacpac"
```

**Pros:**
- Complete database copy (schema + data)
- Portable between instances

**Cons:**
- Large file sizes (may exceed GitHub limits)
- Binary files (can't see diffs)
- Not suitable for frequent updates

---

### Option 3: Tailscale + Direct Connection (Best for Active Dev)

**Setup:**
1. Install Tailscale on both machines
2. Enable SQL Server remote connections
3. Connect directly over Tailscale VPN

**Home SQL Server:**
- Tailscale IP: `100.64.x.x`
- Instance: `100.64.x.x\SQLEXPRESS`

**From IGS workstation:**
```
Server: 100.64.x.x\SQLEXPRESS
Database: itdaggdb_dev
Authentication: Windows (if same domain) or SQL Auth
```

**Pros:**
- Live shared database
- No export/import needed
- Real-time collaboration
- GitHub still stores schema for version control

**Cons:**
- Requires Tailscale setup
- Both machines must be online
- Potential network latency

---

## File Size Limits

**GitHub:**
- Recommended: < 50MB per file
- Hard limit: 100MB per file
- Use Git LFS for 100MB-5GB files

**Typical .bacpac sizes:**
- Empty schema: < 1MB ✅
- Small test DB: 5-20MB ✅
- Medium DB: 50-200MB ⚠️ (consider schema-only)
- Large DB: 500MB+ ❌ (use Tailscale or network share)

---

## Recommended Strategy for ksnlabs

**Store in GitHub (always):**
```
projects/itdaggdb/
├── schema/
│   ├── tables/
│   ├── views/
│   ├── procedures/
│   └── apply_schema.sql
├── migrations/
│   ├── 001_initial.sql
│   └── 002_add_features.sql
├── seed-data/
│   └── test_data.sql
└── scripts/
    ├── export_schema.ps1
    ├── export_database.ps1
    └── import_database.ps1
```

**Store locally (not in Git):**
- Large .bacpac files (> 100MB)
- Database .mdf/.ldf files
- Frequent snapshots

**Share via Tailscale:**
- Active development databases
- Real-time testing

---

## Scripts Provided

### export_schema.ps1
Exports database schema to version-controlled SQL files.

**Usage:**
```powershell
.\export_schema.ps1 -ServerInstance "localhost\SQLEXPRESS" -Database "itdaggdb_dev"
```

**Output:**
- `schema/tables/*.sql`
- `schema/views/*.sql`
- `schema/procedures/*.sql`
- `schema/apply_schema.sql` (master script)

---

### export_database.ps1
Exports complete database (schema + data) as .bacpac.

**Usage:**
```powershell
.\export_database.ps1 -ServerInstance "localhost\SQLEXPRESS" -Database "itdaggdb_dev"
```

**Output:**
- `exports/itdaggdb_YYYY-MM-DD_HHMMSS.bacpac`

**Warnings:**
- Alerts if file > 100MB (GitHub limit)
- Recommends alternatives for large files

---

### import_database.ps1
Imports .bacpac file to create/restore database.

**Usage:**
```powershell
.\import_database.ps1 -BackupFile "exports\itdaggdb_2026-02-14.bacpac" -ServerInstance "localhost\SQLEXPRESS"
```

---

## Typical Workflows

### Daily Development (Schema Changes)
```powershell
# Make schema changes in SSMS
# Export to version control
.\export_schema.ps1

# Commit
git add schema/
git commit -m "Added customer_notes table"
git push

# On other machine
git pull
sqlcmd -S localhost\SQLEXPRESS -d itdaggdb_dev -i "schema\apply_schema.sql"
```

### Weekly Snapshot (Schema + Data)
```powershell
# Export full database
.\export_database.ps1

# If small enough, commit
git add exports/itdaggdb_YYYY-MM-DD.bacpac
git commit -m "Weekly snapshot with test data"
git push

# Or store on network share if too large
```

### New Environment Setup
```powershell
# Clone repo
git clone https://github.com/kawaisunn/ksnlabs.git

# Create database
sqlcmd -S localhost\SQLEXPRESS -Q "CREATE DATABASE itdaggdb_dev"

# Apply schema
sqlcmd -S localhost\SQLEXPRESS -d itdaggdb_dev -i "schema\apply_schema.sql"

# Or restore from .bacpac
.\import_database.ps1 -BackupFile "exports\itdaggdb_latest.bacpac"
```

---

## Next Steps

1. **Choose your primary approach** (recommend: Schema + Tailscale)
2. **Set up Tailscale** for remote SQL access
3. **Export initial schema** to establish baseline
4. **Commit to GitHub** for version control
5. **Document connection strings** in project README

---

**Created:** 2026-02-14  
**Author:** KSN/IGS - AI-assisted development
