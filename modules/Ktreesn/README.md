# Ktreesn Module

**Version**: 0.5.0  
**Author**: KSN / IGS-AI Collaboration  
**Requires**: PowerShell 7+

Structured filesystem mapping with GIS awareness and Doksn integration. Built for Idaho Geological Survey workflows.

## Quick Start

```powershell
# Import
Import-Module C:\dev\ksnlabs\modules\Ktreesn\Ktreesn.psd1

# Display tree (replaces the profile function)
t C:\GIS\Projects -g -i -d 3

# Get structured map
$map = Get-DirectoryMap C:\GIS\Archive -Geo
$map | Get-DirectoryMapSummary

# Check what Doksn has already processed
Get-DoksnProcessingStatus -InputPath Q:\Archive -Workspace C:\Users\ctate\Documents\doksn -Detailed

# Save snapshot, compare later
Export-DirectoryMap $map -Workspace C:\Users\ctate\Documents\doksn
# ... later ...
Compare-DirectoryMap -Before C:\workspace\maps\snap.json

# Track processing state
Set-DirectoryState Q:\Archive\Geology -State Pending -Workspace C:\doksn_ws
Get-DirectoryState Q:\Archive\Geology -Workspace C:\doksn_ws
```

## Functions

| Function | Alias | Purpose |
|----------|-------|---------|
| `Show-DirectoryTree` | `t` | Colorized console tree (display) |
| `Get-DirectoryMap` | `tmap` | Structured node tree (data layer) |
| `Get-DirectoryMapSummary` | — | Quick stats: counts, sizes, extensions |
| `Compare-DirectoryMap` | `tdiff` | Diff two snapshots: adds/removes/mods |
| `Get-DirectoryState` | `tstat` | Read processing state for a directory |
| `Set-DirectoryState` | — | Write/update state (Pending/Complete/Error/etc.) |
| `Export-DirectoryMap` | — | Save snapshot as .json, .md, or .txt |
| `Get-DoksnProcessingStatus` | — | Cross-ref input vs Doksn workspace outputs |

## Node Structure

Every node returned by `Get-DirectoryMap` has:

```
Name, FullPath, Type, Children, Size, FileCount, DirCount,
LastModified, Extension, Hash, IsSymlink, LinkTarget
```

Types: `Directory`, `File`, `GeoGroup`, `Geodatabase`, `Symlink`

GeoGroup nodes add: `GeoType` (Shapefile|Raster), `SidecarCount`, `Sidecars`

## Profile Migration

If upgrading from the `$PROFILE` function, remove `Get-Ktreesn` from your profile and add:

```powershell
Import-Module C:\dev\ksnlabs\modules\Ktreesn\Ktreesn.psd1
```

The `t` alias works identically. All existing flags (`-g`, `-f`, `-i`, `-d`, `-o`, `-fl`, `-limit`) are preserved.

## Doksn Integration

`Get-DoksnProcessingStatus` is designed for job setup in the Doksn Launcher mainform. It answers: "For this input directory and this workspace, what's already been mirrored, OCR'd, and JSON-extracted?"

The C# integration layer will call:
```
pwsh -NoProfile -Command "Import-Module ...; Get-DoksnProcessingStatus ... | ConvertTo-Json -Depth 5"
```
and deserialize the JSON result.

---
*KSN Labs / Idaho Geological Survey*
