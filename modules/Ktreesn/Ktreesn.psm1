#Requires -Version 7.0
<#
.SYNOPSIS
    Ktreesn — Structured filesystem mapping with GIS awareness and Doksn integration.

.DESCRIPTION
    PowerShell module providing:
      - Structured directory scanning returning queryable node objects
      - GIS-aware grouping (shapefiles, georasters, geodatabases)
      - Snapshot persistence and diffing (what changed between scans)
      - Processing state tracking (Pending/Processing/Complete/Error)
      - Doksn workspace cross-referencing (what's been OCR'd, what hasn't)
      - Colorized tree display for terminal use

    Designed for Idaho Geological Survey workflows.

.NOTES
    Module : Ktreesn
    Version: 0.5.0
    Author : KSN / IGS-AI Collaboration
#>

# ═══════════════════════════════════════════════════════════════
# CONSTANTS & SIDECAR DEFINITIONS
# ═══════════════════════════════════════════════════════════════

$script:StateFileName = '_ktreesn_state.json'
$script:SnapshotDir   = 'maps'

# Shapefile sidecars (simple + compound extensions)
$script:ShpSidecarSimple   = @('.shx', '.dbf', '.prj', '.cpg', '.sbn', '.sbx')
$script:ShpSidecarCompound = @('.shp.xml', '.dbf.xml')

# Raster sidecars
$script:RasterSidecarSimple   = @('.tfw', '.tifw', '.tiffw', '.aux', '.ovr',
                                   '.rrd', '.tab', '.wld', '.prj')
$script:RasterSidecarCompound = @('.aux.xml')

$script:MainRasterExts = @('.tif', '.tiff', '.img', '.ecw', '.jp2', '.asc', '.bil')
$script:GenericSidecar = '.xml'

# Processing states
enum KtreesnState {
    Unknown
    Pending
    Scanning
    Processing
    Complete
    Error
    Skipped
}

# ═══════════════════════════════════════════════════════════════
# HELPER FUNCTIONS (private)
# ═══════════════════════════════════════════════════════════════

function Get-CompoundExtension {
    [OutputType([string])]
    param([string]$Name)
    $parts = $Name.Split('.')
    if ($parts.Count -ge 3) {
        return '.' + ($parts[-2] + '.' + $parts[-1]).ToLower()
    }
    return [IO.Path]::GetExtension($Name).ToLower()
}

function Test-ShapefileSidecar {
    [OutputType([bool])]
    param([string]$Name)
    $compound = Get-CompoundExtension $Name
    if ($script:ShpSidecarCompound -contains $compound) { return $true }
    $simple = [IO.Path]::GetExtension($Name).ToLower()
    if ($script:ShpSidecarSimple -contains $simple) { return $true }
    if ($simple -eq $script:GenericSidecar) { return $true }
    return $false
}

function Test-RasterSidecar {
    [OutputType([bool])]
    param([string]$Name)
    $compound = Get-CompoundExtension $Name
    if ($script:RasterSidecarCompound -contains $compound) { return $true }
    $simple = [IO.Path]::GetExtension($Name).ToLower()
    if ($script:RasterSidecarSimple -contains $simple) { return $true }
    if ($simple -eq $script:GenericSidecar) { return $true }
    return $false
}

function Get-HumanSize {
    [OutputType([string])]
    param([long]$Bytes)
    if     ($Bytes -ge 1GB) { '{0:N2} GB' -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { '{0:N2} MB' -f ($Bytes / 1MB) }
    elseif ($Bytes -ge 1KB) { '{0:N1} KB' -f ($Bytes / 1KB) }
    else                    { "$Bytes B" }
}

function Test-IsSymlink {
    [OutputType([bool])]
    param([System.IO.FileSystemInfo]$Item)
    return ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
}

function Get-FileHash256 {
    [OutputType([string])]
    param([string]$Path)
    try {
        $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop
        return $hash.Hash
    }
    catch { return $null }
}

# ═══════════════════════════════════════════════════════════════
# GET-DIRECTORYMAP — Core structured scanner
# ═══════════════════════════════════════════════════════════════

function Get-DirectoryMap {
    <#
    .SYNOPSIS
        Scan a directory and return a structured node tree.

    .DESCRIPTION
        Returns a hierarchy of [PSCustomObject] nodes representing the directory
        structure.  Each node has: Name, FullPath, Type (Directory|File|GeoGroup|
        Geodatabase|Symlink), Children, Size, LastModified, Extension, and
        optional GeoGroup metadata.

        In -Geo mode, shapefiles and georasters are collapsed with their sidecars
        into GeoGroup nodes showing combined size and sidecar count.

    .PARAMETER Path
        Root directory to scan.

    .PARAMETER Depth
        Maximum recursion depth. Default: 10.

    .PARAMETER Geo
        Enable GIS-aware grouping of shapefiles and georasters.

    .PARAMETER IncludeHash
        Compute SHA-256 hash for each file (slower but enables duplicate detection).

    .PARAMETER Filter
        Wildcard filter for filenames. Default: * (all).

    .OUTPUTS
        PSCustomObject — root KtreesnNode with Children array.

    .EXAMPLE
        $map = Get-DirectoryMap C:\GIS\Projects -Geo -Depth 3
        $map.Children | Where-Object Type -eq 'GeoGroup'

    .EXAMPLE
        $map = Get-DirectoryMap D:\Archive -IncludeHash
        # Find duplicates
        $map | Get-DirectoryMapSummary
    #>
    [CmdletBinding()]
    [Alias('tmap')]
    param(
        [Parameter(Position = 0, ValueFromPipeline)]
        [string] $Path = '.',

        [Alias('d')]
        [int] $Depth = 10,

        [Alias('g')]
        [switch] $Geo,

        [switch] $IncludeHash,

        [Alias('fl')]
        [string] $Filter = '*'
    )

    process {
        $root = Get-Item -LiteralPath $Path -ErrorAction Stop
        if (-not $root.PSIsContainer) {
            Write-Error "Path '$Path' is not a directory."
            return
        }

        $progressId = 43
        Write-Progress -Id $progressId -Activity 'Mapping directory' -Status $root.FullName -PercentComplete 0

        $rootNode = Build-NodeRecursive -Dir $root -DepthLeft $Depth -Geo:$Geo `
                        -IncludeHash:$IncludeHash -Filter $Filter -ProgressId $progressId

        Write-Progress -Id $progressId -Activity 'Mapping directory' -Completed

        # Stamp metadata on root
        $rootNode | Add-Member -NotePropertyName 'ScanTime'  -NotePropertyValue ([datetime]::UtcNow) -Force
        $rootNode | Add-Member -NotePropertyName 'ScanDepth' -NotePropertyValue $Depth -Force
        $rootNode | Add-Member -NotePropertyName 'GeoMode'   -NotePropertyValue $Geo.IsPresent -Force

        return $rootNode
    }
}

function Build-NodeRecursive {
    [CmdletBinding()]
    param(
        [IO.DirectoryInfo] $Dir,
        [int]    $DepthLeft,
        [switch] $Geo,
        [switch] $IncludeHash,
        [string] $Filter,
        [int]    $ProgressId
    )

    # Create directory node
    $node = [PSCustomObject]@{
        Name         = $Dir.Name
        FullPath     = $Dir.FullName
        Type         = if ($Dir.Name -like '*.gdb' -and $Geo) { 'Geodatabase' }
                       elseif (Test-IsSymlink $Dir) { 'Symlink' }
                       else { 'Directory' }
        Children     = [System.Collections.Generic.List[object]]::new()
        Size         = [long]0
        FileCount    = [int]0
        DirCount     = [int]0
        LastModified = $Dir.LastWriteTime
        Extension    = $null
        Hash         = $null
        IsSymlink    = (Test-IsSymlink $Dir)
        LinkTarget   = if (Test-IsSymlink $Dir) { try { $Dir.LinkTarget } catch { $null } } else { $null }
    }

    # Don't recurse into geodatabases or symlinks, or if depth exhausted
    if ($node.Type -eq 'Geodatabase' -or $node.IsSymlink -or $DepthLeft -le 0) {
        # For geodatabases, count internal files for size reporting
        if ($node.Type -eq 'Geodatabase') {
            try {
                $gdbFiles = Get-ChildItem -LiteralPath $Dir.FullName -Recurse -File -ErrorAction SilentlyContinue
                $node.Size = ($gdbFiles | Measure-Object -Property Length -Sum).Sum
                $node.FileCount = $gdbFiles.Count
            } catch {}
        }
        return $node
    }

    Write-Progress -Id $ProgressId -Activity 'Mapping directory' -Status $Dir.FullName

    $all      = Get-ChildItem -LiteralPath $Dir.FullName -Force -ErrorAction SilentlyContinue
    $folders  = @($all | Where-Object { $_.PSIsContainer } | Sort-Object Name)
    $filesRaw = @($all | Where-Object { -not $_.PSIsContainer })

    # ── Process subdirectories ────────────────────────────────
    foreach ($subDir in $folders) {
        $childNode = Build-NodeRecursive -Dir $subDir -DepthLeft ($DepthLeft - 1) `
                         -Geo:$Geo -IncludeHash:$IncludeHash -Filter $Filter `
                         -ProgressId $ProgressId
        $node.Children.Add($childNode)
        $node.Size      += $childNode.Size
        $node.FileCount += $childNode.FileCount
        $node.DirCount  += 1 + $childNode.DirCount
    }

    # ── Process files ─────────────────────────────────────────
    if ($Geo) {
        # Group by base name for geo-collapsing
        $fileGroups = @{}
        foreach ($f in $filesRaw) {
            $baseName = [IO.Path]::GetFileNameWithoutExtension($f.Name)
            $compound = Get-CompoundExtension $f.Name
            if ($compound -ne [IO.Path]::GetExtension($f.Name).ToLower()) {
                $baseName = [IO.Path]::GetFileNameWithoutExtension($baseName)
            }
            if (-not $fileGroups.ContainsKey($baseName)) {
                $fileGroups[$baseName] = [System.Collections.Generic.List[object]]::new()
            }
            $fileGroups[$baseName].Add($f)
        }

        foreach ($base in ($fileGroups.Keys | Sort-Object)) {
            $group = $fileGroups[$base]
            $potentialMains = @($group | Where-Object {
                $_.Extension.ToLower() -in (@('.shp') + $script:MainRasterExts)
            })

            if ($potentialMains.Count -gt 0) {
                $main = ($potentialMains | Where-Object { $_.Extension -eq '.shp' } |
                         Select-Object -First 1)
                if (-not $main) { $main = $potentialMains[0] }

                $isShp = $main.Extension -eq '.shp'
                $sidecars = @($group | Where-Object {
                    $_ -ne $main -and (
                        if ($isShp) { Test-ShapefileSidecar $_.Name }
                        else        { Test-RasterSidecar   $_.Name }
                    )
                })

                $totalSize = $main.Length
                foreach ($sc in $sidecars) { $totalSize += $sc.Length }

                if ($Filter -eq '*' -or $main.Name -like $Filter) {
                    $geoNode = [PSCustomObject]@{
                        Name         = $main.Name
                        FullPath     = $main.FullName
                        Type         = 'GeoGroup'
                        Children     = $null
                        Size         = $totalSize
                        FileCount    = 1 + $sidecars.Count
                        DirCount     = 0
                        LastModified = $main.LastWriteTime
                        Extension    = $main.Extension.ToLower()
                        Hash         = if ($IncludeHash) { Get-FileHash256 $main.FullName } else { $null }
                        IsSymlink    = $false
                        LinkTarget   = $null
                        GeoType      = if ($isShp) { 'Shapefile' } else { 'Raster' }
                        SidecarCount = $sidecars.Count
                        Sidecars     = @($sidecars | ForEach-Object { $_.Name })
                    }
                    $node.Children.Add($geoNode)
                    $node.Size      += $totalSize
                    $node.FileCount += 1 + $sidecars.Count
                }

                # Leftovers (not main, not sidecar)
                $leftovers = @($group | Where-Object { $_ -ne $main -and $_ -notin $sidecars })
                foreach ($f in $leftovers) {
                    if ($Filter -eq '*' -or $f.Name -like $Filter) {
                        $node.Children.Add((New-FileNode -File $f -IncludeHash:$IncludeHash))
                        $node.Size      += $f.Length
                        $node.FileCount += 1
                    }
                }
            }
            else {
                foreach ($f in $group) {
                    if ($Filter -eq '*' -or $f.Name -like $Filter) {
                        $node.Children.Add((New-FileNode -File $f -IncludeHash:$IncludeHash))
                        $node.Size      += $f.Length
                        $node.FileCount += 1
                    }
                }
            }
        }
    }
    else {
        # Non-geo: simple file listing
        foreach ($f in ($filesRaw | Where-Object { $_.Name -like $Filter } | Sort-Object Name)) {
            $node.Children.Add((New-FileNode -File $f -IncludeHash:$IncludeHash))
            $node.Size      += $f.Length
            $node.FileCount += 1
        }
    }

    return $node
}

function New-FileNode {
    param(
        [System.IO.FileInfo] $File,
        [switch] $IncludeHash
    )

    [PSCustomObject]@{
        Name         = $File.Name
        FullPath     = $File.FullName
        Type         = if (Test-IsSymlink $File) { 'Symlink' } else { 'File' }
        Children     = $null
        Size         = $File.Length
        FileCount    = 1
        DirCount     = 0
        LastModified = $File.LastWriteTime
        Extension    = $File.Extension.ToLower()
        Hash         = if ($IncludeHash) { Get-FileHash256 $File.FullName } else { $null }
        IsSymlink    = (Test-IsSymlink $File)
        LinkTarget   = if (Test-IsSymlink $File) { try { $File.LinkTarget } catch { $null } } else { $null }
    }
}


# ═══════════════════════════════════════════════════════════════
# GET-DIRECTORYMAPSUMMARY — Quick stats for job setup
# ═══════════════════════════════════════════════════════════════

function Get-DirectoryMapSummary {
    <#
    .SYNOPSIS
        Generate a quick summary of a directory map for job setup review.

    .DESCRIPTION
        Takes a KtreesnNode (from Get-DirectoryMap) and produces a summary object
        with total sizes, file counts by type, geo dataset counts, and other
        metadata useful when setting up a Doksn processing job.

    .PARAMETER Map
        A KtreesnNode object returned by Get-DirectoryMap.

    .EXAMPLE
        Get-DirectoryMap C:\GIS\Archive -Geo | Get-DirectoryMapSummary
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject] $Map
    )

    process {
        $allNodes  = Flatten-Nodes $Map
        $files     = @($allNodes | Where-Object { $_.Type -eq 'File' })
        $geoGroups = @($allNodes | Where-Object { $_.Type -eq 'GeoGroup' })
        $gdbs      = @($allNodes | Where-Object { $_.Type -eq 'Geodatabase' })
        $dirs      = @($allNodes | Where-Object { $_.Type -eq 'Directory' })
        $symlinks  = @($allNodes | Where-Object { $_.IsSymlink })

        # Extension breakdown
        $extBreakdown = @{}
        foreach ($f in $files) {
            $ext = if ($f.Extension) { $f.Extension } else { '(none)' }
            if (-not $extBreakdown.ContainsKey($ext)) {
                $extBreakdown[$ext] = @{ Count = 0; Size = [long]0 }
            }
            $extBreakdown[$ext].Count++
            $extBreakdown[$ext].Size += $f.Size
        }

        $extSummary = $extBreakdown.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending |
            ForEach-Object {
                [PSCustomObject]@{
                    Extension = $_.Key
                    Count     = $_.Value.Count
                    Size      = Get-HumanSize $_.Value.Size
                    SizeBytes = $_.Value.Size
                }
            }

        [PSCustomObject]@{
            RootPath       = $Map.FullPath
            ScanTime       = $Map.ScanTime
            GeoMode        = $Map.GeoMode
            TotalSize      = Get-HumanSize $Map.Size
            TotalSizeBytes = $Map.Size
            Directories    = $dirs.Count
            Files          = $files.Count
            GeoGroups      = $geoGroups.Count
            Geodatabases   = $gdbs.Count
            Symlinks       = $symlinks.Count
            Shapefiles     = @($geoGroups | Where-Object GeoType -eq 'Shapefile').Count
            Rasters        = @($geoGroups | Where-Object GeoType -eq 'Raster').Count
            ByExtension    = $extSummary
            MapExists      = $true
        }
    }
}

function Flatten-Nodes {
    <# Recursively flatten a node tree into a flat list #>
    param([PSCustomObject]$Node)

    $Node  # emit self
    if ($Node.Children) {
        foreach ($child in $Node.Children) {
            Flatten-Nodes $child
        }
    }
}


# ═══════════════════════════════════════════════════════════════
# COMPARE-DIRECTORYMAP — Snapshot diffing
# ═══════════════════════════════════════════════════════════════

function Compare-DirectoryMap {
    <#
    .SYNOPSIS
        Compare two directory map snapshots and report differences.

    .DESCRIPTION
        Takes a -Before and -After map (or a -Before snapshot file + -Path to
        do a live rescan) and returns adds, removes, and modifications.

    .PARAMETER Before
        The earlier snapshot (PSCustomObject from Get-DirectoryMap, or path to
        a saved .json snapshot).

    .PARAMETER After
        The later snapshot. If omitted, a live scan of -Before's root is performed.

    .PARAMETER Path
        If -Before is a snapshot file and you want to rescan a different path.

    .EXAMPLE
        $snap1 = Get-DirectoryMap C:\Data -Geo
        # ... time passes, files change ...
        $snap2 = Get-DirectoryMap C:\Data -Geo
        Compare-DirectoryMap -Before $snap1 -After $snap2

    .EXAMPLE
        # Compare against saved snapshot
        Compare-DirectoryMap -Before C:\workspace\maps\snap_20260308.json
    #>
    [CmdletBinding()]
    [Alias('tdiff')]
    param(
        [Parameter(Mandatory, Position = 0)]
        $Before,

        [Parameter(Position = 1)]
        $After
    )

    # Resolve Before
    if ($Before -is [string]) {
        if (Test-Path $Before) {
            $Before = Get-Content -LiteralPath $Before -Raw | ConvertFrom-Json
        } else {
            Write-Error "Snapshot file not found: $Before"
            return
        }
    }

    # Resolve After — rescan if not provided
    if (-not $After) {
        Write-Host "No -After provided. Performing live rescan of $($Before.FullPath)..."
        $scanParams = @{ Path = $Before.FullPath; Depth = $Before.ScanDepth }
        if ($Before.GeoMode) { $scanParams['Geo'] = $true }
        $After = Get-DirectoryMap @scanParams
    }
    elseif ($After -is [string] -and (Test-Path $After)) {
        $After = Get-Content -LiteralPath $After -Raw | ConvertFrom-Json
    }

    # Flatten both into path-keyed lookup
    $beforeFlat = @{}
    Flatten-Nodes $Before | ForEach-Object { $beforeFlat[$_.FullPath] = $_ }

    $afterFlat = @{}
    Flatten-Nodes $After | ForEach-Object { $afterFlat[$_.FullPath] = $_ }

    $added    = [System.Collections.Generic.List[object]]::new()
    $removed  = [System.Collections.Generic.List[object]]::new()
    $modified = [System.Collections.Generic.List[object]]::new()

    # Find added and modified
    foreach ($path in $afterFlat.Keys) {
        if (-not $beforeFlat.ContainsKey($path)) {
            $added.Add($afterFlat[$path])
        }
        elseif ($afterFlat[$path].Type -in @('File','GeoGroup')) {
            $b = $beforeFlat[$path]
            $a = $afterFlat[$path]
            if ($a.Size -ne $b.Size -or $a.LastModified -ne $b.LastModified) {
                $modified.Add([PSCustomObject]@{
                    FullPath        = $path
                    Name            = $a.Name
                    Type            = $a.Type
                    SizeBefore      = $b.Size
                    SizeAfter       = $a.Size
                    ModifiedBefore  = $b.LastModified
                    ModifiedAfter   = $a.LastModified
                })
            }
        }
    }

    # Find removed
    foreach ($path in $beforeFlat.Keys) {
        if (-not $afterFlat.ContainsKey($path)) {
            $removed.Add($beforeFlat[$path])
        }
    }

    [PSCustomObject]@{
        BeforeRoot  = $Before.FullPath
        AfterRoot   = $After.FullPath
        BeforeTime  = $Before.ScanTime
        AfterTime   = $After.ScanTime
        Added       = $added
        Removed     = $removed
        Modified    = $modified
        AddedCount  = $added.Count
        RemovedCount = $removed.Count
        ModifiedCount = $modified.Count
        HasChanges  = ($added.Count + $removed.Count + $modified.Count) -gt 0
    }
}


# ═══════════════════════════════════════════════════════════════
# STATE TRACKING — Get/Set-DirectoryState
# ═══════════════════════════════════════════════════════════════

function Get-DirectoryState {
    <#
    .SYNOPSIS
        Read the processing state for a directory from its state sidecar file.

    .DESCRIPTION
        Looks for _ktreesn_state.json in the target directory (or a specified
        workspace maps/ directory).  Returns the state object with per-path
        status, timestamps, and notes.

    .PARAMETER Path
        Directory to check for state.

    .PARAMETER Workspace
        Doksn workspace root.  If provided, state is read from
        workspace/maps/<sanitized-path>/_ktreesn_state.json instead of from
        the source directory itself.

    .EXAMPLE
        Get-DirectoryState C:\GIS\Archive

    .EXAMPLE
        Get-DirectoryState C:\GIS\Archive -Workspace C:\Users\ctate\Documents\doksn
    #>
    [CmdletBinding()]
    [Alias('tstat')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Path,

        [string] $Workspace
    )

    $stateFile = Resolve-StateFilePath -Path $Path -Workspace $Workspace

    if (-not (Test-Path $stateFile)) {
        return [PSCustomObject]@{
            Path       = (Resolve-Path $Path -ErrorAction SilentlyContinue)?.Path ?? $Path
            StateFile  = $stateFile
            Exists     = $false
            State      = [KtreesnState]::Unknown
            Entries    = @{}
            LastUpdate = $null
        }
    }

    $raw = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
    $raw | Add-Member -NotePropertyName 'Exists' -NotePropertyValue $true -Force
    $raw | Add-Member -NotePropertyName 'StateFile' -NotePropertyValue $stateFile -Force
    return $raw
}

function Set-DirectoryState {
    <#
    .SYNOPSIS
        Write or update processing state for a directory or specific paths within it.

    .DESCRIPTION
        Creates/updates _ktreesn_state.json to track which files/subdirectories
        have been processed, are pending, errored, etc.

    .PARAMETER Path
        Target directory.

    .PARAMETER State
        The state to assign: Unknown, Pending, Scanning, Processing, Complete, Error, Skipped.

    .PARAMETER Items
        Specific file/subdirectory paths within -Path to set state on.
        If omitted, sets the state for the directory as a whole.

    .PARAMETER Note
        Optional note (e.g., error message, run ID, timestamp).

    .PARAMETER Workspace
        If provided, state file lives in workspace/maps/ instead of the source directory.

    .EXAMPLE
        Set-DirectoryState C:\GIS\Archive -State Pending

    .EXAMPLE
        Set-DirectoryState C:\GIS\Archive -State Complete -Items @('roads.shp','wells.tif') -Note 'run_20260308'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Path,

        [Parameter(Mandatory)]
        [KtreesnState] $State,

        [string[]] $Items,

        [string] $Note,

        [string] $Workspace
    )

    $stateFile = Resolve-StateFilePath -Path $Path -Workspace $Workspace

    # Ensure parent directory exists
    $parentDir = Split-Path $stateFile -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Load existing or create new
    if (Test-Path $stateFile) {
        $stateObj = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
    }
    else {
        $stateObj = [PSCustomObject]@{
            Path       = (Resolve-Path $Path -ErrorAction SilentlyContinue)?.Path ?? $Path
            StateFile  = $stateFile
            State      = [KtreesnState]::Unknown.ToString()
            Entries    = @{}
            LastUpdate = $null
        }
    }

    $timestamp = [datetime]::UtcNow.ToString('o')
    $stateObj.LastUpdate = $timestamp

    if ($Items -and $Items.Count -gt 0) {
        # Set state on specific items
        $entriesHash = @{}
        if ($stateObj.Entries -is [PSCustomObject]) {
            $stateObj.Entries.PSObject.Properties | ForEach-Object {
                $entriesHash[$_.Name] = $_.Value
            }
        }
        foreach ($item in $Items) {
            $entriesHash[$item] = [PSCustomObject]@{
                State     = $State.ToString()
                Note      = $Note
                Timestamp = $timestamp
            }
        }
        $stateObj.Entries = [PSCustomObject]$entriesHash
    }
    else {
        # Set state for entire directory
        $stateObj.State = $State.ToString()
        if ($Note) {
            $stateObj | Add-Member -NotePropertyName 'Note' -NotePropertyValue $Note -Force
        }
    }

    $stateObj | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $stateFile -Encoding utf8 -Force
    Write-Verbose "State written to: $stateFile"
    return $stateObj
}

function Resolve-StateFilePath {
    param([string]$Path, [string]$Workspace)

    $resolved = (Resolve-Path $Path -ErrorAction SilentlyContinue)?.Path ?? $Path

    if ($Workspace) {
        # Sanitize path for use as subdirectory name
        $sanitized = $resolved -replace ':', '' -replace '\\\\', '_' -replace '\\', '_'
        $mapsDir = Join-Path $Workspace $script:SnapshotDir $sanitized
        return Join-Path $mapsDir $script:StateFileName
    }
    else {
        return Join-Path $resolved $script:StateFileName
    }
}


# ═══════════════════════════════════════════════════════════════
# GET-DOKSNPROCESSINGSTATUS — Cross-reference input vs workspace
# ═══════════════════════════════════════════════════════════════

function Get-DoksnProcessingStatus {
    <#
    .SYNOPSIS
        Check which files in an input directory have already been processed by Doksn.

    .DESCRIPTION
        Cross-references files in the input directory against the Doksn workspace
        (sourcemirror, sourceprocd, jsonprocd) to determine what's been processed,
        what's pending, and what errored.  This is the key function for job setup
        intelligence — call it before running Doksn to understand the work ahead.

    .PARAMETER InputPath
        The source directory to check.

    .PARAMETER Workspace
        Doksn workspace root (contains sourcemirror/, sourceprocd/, jsonprocd/).

    .PARAMETER Detailed
        Include per-file status instead of just summary counts.

    .EXAMPLE
        Get-DoksnProcessingStatus -InputPath Q:\Archive\Geology -Workspace C:\Users\ctate\Documents\doksn

    .EXAMPLE
        Get-DoksnProcessingStatus Q:\Archive -Workspace C:\doksn_ws -Detailed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $InputPath,

        [Parameter(Mandatory, Position = 1)]
        [string] $Workspace,

        [switch] $Detailed
    )

    $inputResolved = (Resolve-Path $InputPath -ErrorAction Stop).Path
    $mirrorDir  = Join-Path $Workspace 'sourcemirror'
    $procdDir   = Join-Path $Workspace 'sourceprocd'
    $jsonDir    = Join-Path $Workspace 'jsonprocd'

    # Get input files
    $inputFiles = @(Get-ChildItem -LiteralPath $inputResolved -Recurse -File -ErrorAction SilentlyContinue)

    if ($inputFiles.Count -eq 0) {
        Write-Warning "No files found in $InputPath"
        return [PSCustomObject]@{
            InputPath   = $inputResolved
            Workspace   = $Workspace
            TotalFiles  = 0
            Mirrored    = 0
            OCRProcessed = 0
            JsonExtracted = 0
            Unprocessed = 0
            Files       = @()
        }
    }

    # Build lookup of what exists in workspace
    $mirrorFiles = @{}
    if (Test-Path $mirrorDir) {
        Get-ChildItem -LiteralPath $mirrorDir -Recurse -File -ErrorAction SilentlyContinue |
            ForEach-Object { $mirrorFiles[$_.Name] = $_.FullName }
    }

    $procdFiles = @{}
    if (Test-Path $procdDir) {
        Get-ChildItem -LiteralPath $procdDir -Recurse -File -ErrorAction SilentlyContinue |
            ForEach-Object { $procdFiles[$_.Name] = $_.FullName }
    }

    $jsonFiles = @{}
    if (Test-Path $jsonDir) {
        Get-ChildItem -LiteralPath $jsonDir -Recurse -File -ErrorAction SilentlyContinue |
            ForEach-Object {
                # JSON files use <originalname>_<hash>_ocr.json pattern
                # Extract base name for matching
                $baseName = $_.BaseName -replace '_[a-f0-9]{6,}_ocr$', ''
                $jsonFiles[$baseName] = $_.FullName
            }
    }

    $mirrored     = 0
    $ocrProcessed = 0
    $jsonExtracted = 0
    $unprocessed  = 0
    $fileDetails  = [System.Collections.Generic.List[object]]::new()

    foreach ($f in $inputFiles) {
        $baseName = [IO.Path]::GetFileNameWithoutExtension($f.Name)
        $hasMirror = $mirrorFiles.ContainsKey($f.Name)
        $hasOCR    = $procdFiles.ContainsKey($f.Name) -or
                     $procdFiles.ContainsKey("${baseName}_ocr.pdf")
        $hasJson   = $jsonFiles.ContainsKey($baseName)

        if ($hasMirror) { $mirrored++ }
        if ($hasOCR)    { $ocrProcessed++ }
        if ($hasJson)   { $jsonExtracted++ }

        $status = if ($hasJson -and $hasOCR)    { 'Complete' }
                  elseif ($hasMirror)            { 'Partial' }
                  else                           { 'Unprocessed' }

        if ($status -eq 'Unprocessed') { $unprocessed++ }

        if ($Detailed) {
            $fileDetails.Add([PSCustomObject]@{
                Name        = $f.Name
                RelativePath = $f.FullName.Substring($inputResolved.Length).TrimStart('\')
                Size        = $f.Length
                SizeHuman   = Get-HumanSize $f.Length
                Status      = $status
                Mirrored    = $hasMirror
                OCRProcessed = $hasOCR
                JsonExtracted = $hasJson
            })
        }
    }

    [PSCustomObject]@{
        InputPath     = $inputResolved
        Workspace     = $Workspace
        TotalFiles    = $inputFiles.Count
        TotalSize     = Get-HumanSize ($inputFiles | Measure-Object Length -Sum).Sum
        Mirrored      = $mirrored
        OCRProcessed  = $ocrProcessed
        JsonExtracted = $jsonExtracted
        Unprocessed   = $unprocessed
        PercentDone   = if ($inputFiles.Count -gt 0) {
                            [math]::Round(($jsonExtracted / $inputFiles.Count) * 100, 1)
                        } else { 0 }
        Files         = if ($Detailed) { $fileDetails } else { $null }
        StateFile     = Resolve-StateFilePath -Path $InputPath -Workspace $Workspace
        HasStateFile  = Test-Path (Resolve-StateFilePath -Path $InputPath -Workspace $Workspace)
    }
}


# ═══════════════════════════════════════════════════════════════
# EXPORT-DIRECTORYMAP — Serialize to JSON/markdown/text
# ═══════════════════════════════════════════════════════════════

function Export-DirectoryMap {
    <#
    .SYNOPSIS
        Save a directory map snapshot to disk.

    .DESCRIPTION
        Serializes a KtreesnNode tree to JSON (for programmatic use, diffing,
        and Doksn integration) or markdown/text (for reports).

    .PARAMETER Map
        The KtreesnNode object from Get-DirectoryMap.

    .PARAMETER OutFile
        Destination path. Format is inferred from extension:
          .json — full structured snapshot (Doksn-compatible)
          .md   — markdown tree with fenced code block
          .txt  — plain text tree

    .PARAMETER Workspace
        If provided, saves to workspace/maps/ with an auto-generated name.

    .EXAMPLE
        Get-DirectoryMap C:\Data -Geo | Export-DirectoryMap -OutFile snapshot.json

    .EXAMPLE
        $map = Get-DirectoryMap Q:\Archive -Geo
        Export-DirectoryMap $map -Workspace C:\Users\ctate\Documents\doksn
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [PSCustomObject] $Map,

        [string] $OutFile,
        [string] $Workspace
    )

    process {
        if (-not $OutFile -and -not $Workspace) {
            Write-Error 'Specify -OutFile or -Workspace.'
            return
        }

        if (-not $OutFile -and $Workspace) {
            $sanitized = ($Map.FullPath -replace ':', '' -replace '\\\\', '_' -replace '\\', '_')
            $ts = $Map.ScanTime.ToString('yyyyMMdd_HHmmss')
            $mapsDir = Join-Path $Workspace $script:SnapshotDir
            if (-not (Test-Path $mapsDir)) { New-Item -ItemType Directory -Path $mapsDir -Force | Out-Null }
            $OutFile = Join-Path $mapsDir "${sanitized}_${ts}.json"
        }

        $ext = [IO.Path]::GetExtension($OutFile).ToLower()

        switch ($ext) {
            '.json' {
                $Map | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OutFile -Encoding utf8 -Force
            }
            '.md' {
                $lines = @("### Directory Map: $($Map.FullPath)")
                $lines += "Scanned: $($Map.ScanTime) | Geo: $($Map.GeoMode) | Files: $($Map.FileCount) | Size: $(Get-HumanSize $Map.Size)"
                $lines += ''
                $lines += '```text'
                $lines += (Render-TreeLines $Map '' $true)
                $lines += '```'
                $lines -join "`n" | Set-Content -LiteralPath $OutFile -Encoding utf8 -Force
            }
            default {
                # Plain text
                $lines = @("Directory Map: $($Map.FullPath)")
                $lines += "Scanned: $($Map.ScanTime) | Geo: $($Map.GeoMode) | Files: $($Map.FileCount) | Size: $(Get-HumanSize $Map.Size)"
                $lines += ''
                $lines += (Render-TreeLines $Map '' $true)
                $lines -join "`n" | Set-Content -LiteralPath $OutFile -Encoding utf8 -Force
            }
        }

        Write-Host "Snapshot saved: $OutFile"
        return $OutFile
    }
}

function Render-TreeLines {
    <# Recursively render a node tree into plain-text lines (no ANSI) #>
    param(
        [PSCustomObject] $Node,
        [string] $Indent,
        [bool] $IsRoot
    )

    $brT = [string]([char]0x251C) + [string]([char]0x2500) + [string]([char]0x2500) + ' '
    $brL = [string]([char]0x2514) + [string]([char]0x2500) + [string]([char]0x2500) + ' '
    $bar = [string]([char]0x2502) + '   '
    $spc = '    '

    $lines = [System.Collections.Generic.List[string]]::new()

    if ($IsRoot) {
        $lines.Add("$($Node.Name)/ ($(Get-HumanSize $Node.Size), $($Node.FileCount) files)")
    }

    if (-not $Node.Children) { return $lines }

    $children = @($Node.Children)
    for ($i = 0; $i -lt $children.Count; $i++) {
        $child  = $children[$i]
        $isLast = ($i -eq $children.Count - 1)
        $pref   = if ($isLast) { $brL } else { $brT }
        $pad    = if ($isLast) { $spc } else { $bar }

        switch ($child.Type) {
            'Directory' {
                $lines.Add("$Indent$pref$($child.Name)/ ($(Get-HumanSize $child.Size))")
                $lines.AddRange([string[]](Render-TreeLines $child ($Indent + $pad) $false))
            }
            'Geodatabase' {
                $lines.Add("$Indent$pref$($child.Name)/ [geodatabase] ($(Get-HumanSize $child.Size))")
            }
            'GeoGroup' {
                $sc = if ($child.SidecarCount -gt 0) { " + $($child.SidecarCount) sidecars" } else { '' }
                $lines.Add("$Indent$pref$($child.Name)$sc ($(Get-HumanSize $child.Size))")
            }
            'Symlink' {
                $lines.Add("$Indent$pref$($child.Name) -> $($child.LinkTarget)")
            }
            default {
                $lines.Add("$Indent$pref$($child.Name) ($(Get-HumanSize $child.Size))")
            }
        }
    }

    return $lines
}


# ═══════════════════════════════════════════════════════════════
# SHOW-DIRECTORYTREE — Colorized console display
# ═══════════════════════════════════════════════════════════════

function Show-DirectoryTree {
    <#
    .SYNOPSIS
        Display a colorized directory tree in the console.

    .DESCRIPTION
        Wrapper that scans via Get-DirectoryMap and renders a colorized tree
        to the console.  This is the display-oriented function — use
        Get-DirectoryMap when you need structured data.

        Supports all the same parameters as Get-DirectoryMap plus display
        options like -ShowSize, -ShowDate, -MaxFilesConsole, and -OutFile.

    .PARAMETER Path
        Root directory. Alias: -p

    .PARAMETER Depth
        Max recursion depth. Alias: -d. Default: 5.

    .PARAMETER Geo
        GIS-aware grouping. Alias: -g.

    .PARAMETER ShowSize
        Show file sizes. Alias: -s.

    .PARAMETER ShowDate
        Show last-modified dates. Alias: -sdt.

    .PARAMETER Info
        Shortcut for -ShowSize -ShowDate. Alias: -i.

    .PARAMETER Filter
        Wildcard filename filter. Alias: -fl.

    .PARAMETER OutFile
        Write tree to file (.md wraps in fenced code block). Alias: -o.

    .PARAMETER Append
        Append to -OutFile. Alias: -a.

    .PARAMETER NoColor
        Suppress ANSI color codes.

    .EXAMPLE
        Show-DirectoryTree C:\GIS\Projects -Geo -Info -d 3

    .EXAMPLE
        t -g -f -i     # Using the 't' alias with common flags
    #>
    [CmdletBinding()]
    [Alias('t')]
    param(
        [Parameter(Position = 0, ValueFromPipeline)]
        [Alias('p')]  [string] $Path = '.',
        [Alias('d')]  [int]    $Depth = 5,
        [Alias('g')]  [switch] $Geo,
        [Alias('fl')] [string] $Filter = '*',
        [Alias('s')]  [switch] $ShowSize,
        [Alias('sdt')][switch] $ShowDate,
        [Alias('i')]  [switch] $Info,
        [Alias('limit')][int]  $MaxFilesConsole = 0,
        [Alias('o')]  [string] $OutFile,
        [Alias('a')]  [switch] $Append,
        [switch] $NoColor
    )

    process {
        if ($Info) { $ShowSize = $true; $ShowDate = $true }

        # Get structured map
        $map = Get-DirectoryMap -Path $Path -Depth $Depth -Geo:$Geo -Filter $Filter

        # Setup colors
        $useColor = -not ($NoColor -or $env:NO_COLOR -or $OutFile)
        if ($useColor -and (Get-Variable PSStyle -ErrorAction SilentlyContinue)) {
            $c = @{
                Dir   = $PSStyle.Foreground.BrightBlue  + $PSStyle.Bold
                File  = $PSStyle.Foreground.BrightGreen  + $PSStyle.Bold
                Gdb   = $PSStyle.Foreground.Green         + $PSStyle.Bold
                Group = $PSStyle.Foreground.BrightCyan    + $PSStyle.Bold
                Link  = $PSStyle.Foreground.Magenta       + $PSStyle.Bold
                Meta  = $PSStyle.Foreground.BrightBlack
                Reset = $PSStyle.Reset
            }
        } else {
            $c = @{ Dir=''; File=''; Gdb=''; Group=''; Link=''; Meta=''; Reset='' }
        }

        $brT = [string]([char]0x251C) + [string]([char]0x2500) + [string]([char]0x2500) + ' '
        $brL = [string]([char]0x2514) + [string]([char]0x2500) + [string]([char]0x2500) + ' '
        $bar = [string]([char]0x2502) + '   '
        $spc = '    '

        $results = [System.Collections.Generic.List[string]]::new()

        # Active params for header
        $params = @("Depth=$Depth")
        if ($Geo) { $params += 'Geo' }
        if ($ShowSize) { $params += 'Size' }
        if ($ShowDate) { $params += 'Date' }
        if ($Filter -ne '*') { $params += "Filter=$Filter" }

        $header = "$($c.Dir)$($map.FullPath)$($c.Reset)/ ($($params -join ', '))"
        $results.Add($header)
        Write-Host $header

        # Recursive renderer
        function Render-ConsoleNode {
            param(
                [PSCustomObject] $Node,
                [string] $Indent,
                [ref] $FileCount
            )

            if (-not $Node.Children) { return }
            $children = @($Node.Children)

            for ($i = 0; $i -lt $children.Count; $i++) {
                $child  = $children[$i]
                $isLast = ($i -eq $children.Count - 1)
                $pref   = if ($isLast) { $brL } else { $brT }
                $pad    = if ($isLast) { $spc } else { $bar }

                $size = if ($ShowSize) { " $(Get-HumanSize $child.Size)" } else { '' }
                $date = if ($ShowDate) { " $($c.Meta)[$($child.LastModified.ToString('yyyy-MM-dd'))]$($c.Reset)" } else { '' }

                $isFileLike = $child.Type -in @('File', 'GeoGroup', 'Symlink') -and $child.Type -ne 'Directory'

                switch ($child.Type) {
                    'Directory' {
                        $line = "$Indent$($c.Dir)$pref$($child.Name)$($c.Reset)/$size$date"
                        $results.Add($line); Write-Host $line
                        Render-ConsoleNode -Node $child -Indent ($Indent + $pad) -FileCount $FileCount
                    }
                    'Geodatabase' {
                        $line = "$Indent$($c.Gdb)$pref$($child.Name)$($c.Reset)/ [geodatabase]$size$date"
                        $results.Add($line); Write-Host $line
                    }
                    'GeoGroup' {
                        $sc = if ($child.SidecarCount -gt 0) { " + $($child.SidecarCount) sidecars" } else { '' }
                        $line = "$Indent$($c.Group)$pref$($child.Name)$sc$($c.Reset)$size$date"
                        $results.Add($line)
                        $FileCount.Value++
                        if ($MaxFilesConsole -le 0 -or $FileCount.Value -le $MaxFilesConsole) {
                            Write-Host $line
                        }
                    }
                    'Symlink' {
                        $tgt = if ($child.LinkTarget) { " -> $($child.LinkTarget)" } else { '' }
                        $line = "$Indent$($c.Link)$pref$($child.Name)$($c.Reset)$tgt$size$date"
                        $results.Add($line)
                        $FileCount.Value++
                        if ($MaxFilesConsole -le 0 -or $FileCount.Value -le $MaxFilesConsole) {
                            Write-Host $line
                        }
                    }
                    default {
                        $line = "$Indent$($c.File)$pref$($child.Name)$($c.Reset)$size$date"
                        $results.Add($line)
                        $FileCount.Value++
                        if ($MaxFilesConsole -le 0 -or $FileCount.Value -le $MaxFilesConsole) {
                            Write-Host $line
                        }
                    }
                }
            }

            # Truncation notice (per-directory)
            if ($MaxFilesConsole -gt 0 -and $FileCount.Value -gt $MaxFilesConsole) {
                $hidden = $FileCount.Value - $MaxFilesConsole
                Write-Host "$Indent$($c.Meta)    ... and $hidden more$($c.Reset)"
            }
        }

        [int]$fc = 0
        Render-ConsoleNode -Node $map -Indent '' -FileCount ([ref]$fc)

        # File export
        if ($OutFile) {
            $ansiRegex = '\x1b\[[0-9;]*m'
            $clean = $results | ForEach-Object { $_ -replace $ansiRegex, '' }

            if ($OutFile -like '*.md') {
                $export = @("### Directory Tree: $($map.FullPath) ($($params -join ', '))") +
                          @('```text') + $clean + @('```')
            } else {
                $export = $clean
            }
            $splat = @{ FilePath = $OutFile; Encoding = 'utf8'; Force = $true }
            if ($Append) { $splat['Append'] = $true }
            $export | Out-File @splat
            Write-Host "$($c.Meta)Written to: $OutFile$($c.Reset)"
        }

        return $results
    }
}


# ═══════════════════════════════════════════════════════════════
# ALIASES
# ═══════════════════════════════════════════════════════════════

Set-Alias -Name t     -Value Show-DirectoryTree     -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name tmap  -Value Get-DirectoryMap        -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name tdiff -Value Compare-DirectoryMap    -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name tstat -Value Get-DirectoryState      -Option AllScope -ErrorAction SilentlyContinue

# ═══════════════════════════════════════════════════════════════
# MODULE EXPORT
# ═══════════════════════════════════════════════════════════════

Export-ModuleMember -Function @(
    'Get-DirectoryMap'
    'Compare-DirectoryMap'
    'Get-DirectoryState'
    'Set-DirectoryState'
    'Show-DirectoryTree'
    'Export-DirectoryMap'
    'Get-DirectoryMapSummary'
    'Get-DoksnProcessingStatus'
) -Alias @('t', 'tmap', 'tdiff', 'tstat')
