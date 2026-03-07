# Doksn Build Kit
**Date**: 2026-03-07
**Author**: kawaisunn / IGS — AI-assisted (Claude Opus 4.6)
**Purpose**: Single folder containing everything needed to build Doksn (with cait + keywrds) as MSI, prep for MSIX, and package keywrds as a standalone portable zip — all on a clean Windows Sandbox.

---

## Folder Structure

```
doksn-build-kit/
├── README.md                      ← You are here
├── scripts/
│   ├── stage_all_deps.ps1         ← Run FIRST on host (downloads all installers)
│   ├── build_keywrds_portable.ps1 ← Packages keywrds as standalone zip
│   ├── verify_build_env.ps1       ← Sanity check: are all tools present?
│   └── convert_msi_to_msix.ps1    ← Future: MSI → MSIX conversion
└── docs/
    └── msix_prep.md               ← MSIX packaging guide + requirements
```

## Quick Start

### 1. Stage Dependencies (run on BIGSPIDER with internet)
```powershell
pwsh -ExecutionPolicy Bypass -File scripts\stage_all_deps.ps1
```

### 2. Build MSI (existing pipeline)
```powershell
cd C:\dev\ocritd
.\BUILD_ALL.ps1 -BuildMode Full
```

### 3. Build keywrds Standalone
```powershell
pwsh -ExecutionPolicy Bypass -File scripts\build_keywrds_portable.ps1
```
Output: `C:\dev\ocritd\dist\keywrds_standalone_v0.8.0.zip`

### 4. Test in Sandbox
```powershell
C:\dev\ocritd\sandbox\doksn_sandbox.wsb
```

### 5. MSIX (future)
See `docs/msix_prep.md`
