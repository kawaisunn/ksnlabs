<#
.SYNOPSIS
    Install ksnPathCopy context menu utility.
.DESCRIPTION
    Deploys ksnPathCopy.ps1 and registers a cascading right-click context menu
    in Windows Explorer for files, folders, and folder backgrounds.

    Menu structure:
      ksnPathCopy  →  Path Copy (quoted, mapped)     ← default
                      Path (unquoted, mapped)
                      UNC Path (server name)
                      UNC Raw Path (IP, direct)

    v2.0: Uses nested HKCR subkeys instead of HKLM CommandStore.
    Self-contained — no cross-hive references, no GPO dependency.
    All HKCR paths with "*" use .NET Registry API (no wildcard expansion).
    Direct PowerShell invocation (no VBS) for Sophos compatibility.

.PARAMETER InstallDir
    Where to install the scripts. Default: C:\Program Files\ksnPathCopy
.PARAMETER Uninstall
    Remove all registry entries and optionally delete installed files.
.NOTES
    Author:  kawaisunn / ksnlabs
    Version: 2.0.0
    Date:    2026-03-11
    Requires: Run as Administrator
#>

param(
    [string]$InstallDir = "$env:ProgramFiles\ksnPathCopy",
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Elevation check ──────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Right-click PowerShell → Run as Administrator, then re-run." -ForegroundColor Yellow
    exit 1
}

# ── Constants ────────────────────────────────────────────────────────
$appName = "ksnPathCopy"
$version = "2.0.0"

# Resolve pwsh vs powershell — prefer pwsh (PowerShell Core)
$psExe = $null
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshCmd) { $psExe = $pwshCmd.Source }
if (-not $psExe) {
    $psCmd = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($psCmd) { $psExe = $psCmd.Source }
}
if (-not $psExe) {
    $psExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
}
Write-Host "  Using shell: $psExe" -ForegroundColor Gray

# Submenu items — order matters (Explorer sorts alphabetically by key name,
# so we prefix with 01_, 02_ etc. to control display order)
$menuItems = [ordered]@{
    "01_PathCopy" = @{ Label = "Path Copy (quoted, mapped)";  Icon = "imageres.dll,3";   Mode = "PathCopy" }
    "02_Path"     = @{ Label = "Path (unquoted, mapped)";     Icon = "imageres.dll,3";   Mode = "Path" }
    "03_UNCPath"  = @{ Label = "UNC Path (server name)";      Icon = "shell32.dll,275";  Mode = "UNCPath" }
    "04_UNCRaw"   = @{ Label = "UNC Raw Path (IP, direct)";   Icon = "shell32.dll,18";   Mode = "UNCRaw" }
}

# Three context targets. PathVar: %1 for files/folders, %V for background.
$contextRoots = @(
    @{ SubKey = "*\shell\$appName";                    Type = "Files";                PathVar = "%1" }
    @{ SubKey = "Directory\shell\$appName";             Type = "Folders";              PathVar = "%1" }
    @{ SubKey = "Directory\Background\shell\$appName";  Type = "Directory Background"; PathVar = "%V" }
)

# ── Helper: build command string ─────────────────────────────────────
function Get-CmdString {
    param([string]$PathVar, [string]$ModeName)
    $scriptPath = Join-Path $InstallDir "ksnPathCopy.ps1"
    return "$psExe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -TargetPath `"$PathVar`" -Mode $ModeName"
}

# ── UNINSTALL ────────────────────────────────────────────────────────
if ($Uninstall) {
    Write-Host "`n  ksnPathCopy Uninstall v$version" -ForegroundColor Cyan
    Write-Host "  $('─' * 40)" -ForegroundColor DarkGray

    # Remove v2.0 nested HKCR entries
    foreach ($ctx in $contextRoots) {
        try {
            [Microsoft.Win32.Registry]::ClassesRoot.DeleteSubKeyTree($ctx.SubKey, $false)
            Write-Host "  [OK] Removed: $($ctx.Type) ($($ctx.SubKey))" -ForegroundColor Green
        } catch {
            # Key doesn't exist
        }
    }

    # Also clean up any leftover v1.x CommandStore entries from HKLM
    $commandStore = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"
    $v1Keys = Get-ChildItem -LiteralPath $commandStore -ErrorAction SilentlyContinue |
              Where-Object { $_.PSChildName -like "ksnPathCopy*" }
    foreach ($key in $v1Keys) {
        Remove-Item -LiteralPath $key.PSPath -Recurse -Force
        Write-Host "  [OK] Removed v1.x CommandStore: $($key.PSChildName)" -ForegroundColor Green
    }

    # Ask about installed files
    if (Test-Path -LiteralPath $InstallDir) {
        $confirm = Read-Host "  Delete installed files at ${InstallDir}? (y/n)"
        if ($confirm -eq 'y') {
            Remove-Item -LiteralPath $InstallDir -Recurse -Force
            Write-Host "  [OK] Deleted $InstallDir" -ForegroundColor Green
        } else {
            Write-Host "  [--] Files kept at $InstallDir" -ForegroundColor Yellow
        }
    }

    Write-Host "`n  Uninstall complete. Restart Explorer to clear menu cache.`n" -ForegroundColor Cyan
    exit 0
}

# ── INSTALL ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ┌─────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │      ksnPathCopy v$version  Installer       │" -ForegroundColor Cyan
Write-Host "  │      kawaisunn / ksnlabs                 │" -ForegroundColor Cyan
Write-Host "  │      Nested subkeys — no CommandStore    │" -ForegroundColor Cyan
Write-Host "  └─────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Deploy files ─────────────────────────────────────────────
Write-Host "  [1/3] Deploying files → $InstallDir" -ForegroundColor Yellow

if (-not (Test-Path -LiteralPath $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
}

$sourceDir = $PSScriptRoot
if (-not $sourceDir) { $sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $sourceDir) { $sourceDir = Get-Location }

foreach ($file in @("ksnPathCopy.ps1", "install.ps1")) {
    $src = Join-Path $sourceDir $file
    $dst = Join-Path $InstallDir $file
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Write-Host "    Deployed: $file" -ForegroundColor Green
    } elseif ($file -eq "ksnPathCopy.ps1") {
        Write-Host "    ERROR: Cannot find $file in $sourceDir" -ForegroundColor Red
        exit 1
    }
}

$psExe | Set-Content (Join-Path $InstallDir ".shell_path") -Encoding UTF8
Write-Host "    Recorded shell: $psExe" -ForegroundColor Green

# ── Step 2: Clean up any v1.x CommandStore entries ────────────────────
Write-Host "`n  [2/3] Cleaning v1.x CommandStore entries (if any)" -ForegroundColor Yellow

$commandStore = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"
$v1Keys = Get-ChildItem -LiteralPath $commandStore -ErrorAction SilentlyContinue |
          Where-Object { $_.PSChildName -like "ksnPathCopy*" }
$v1Count = @($v1Keys).Count
if ($v1Count -gt 0) {
    foreach ($key in $v1Keys) {
        Remove-Item -LiteralPath $key.PSPath -Recurse -Force
    }
    Write-Host "    Removed $v1Count v1.x entries" -ForegroundColor Green
} else {
    Write-Host "    None found (clean install)" -ForegroundColor Green
}

# Also clean any old HKCR entries that used SubCommands pointing at CommandStore
foreach ($ctx in $contextRoots) {
    try {
        [Microsoft.Win32.Registry]::ClassesRoot.DeleteSubKeyTree($ctx.SubKey, $false)
    } catch {}
}
Write-Host "    Cleared old HKCR entries" -ForegroundColor Green

# ── Step 3: Register nested context menus ─────────────────────────────
#
# Structure (all under HKCR, no HKLM dependency):
#
#   HKCR\*\shell\ksnPathCopy
#     MUIVerb = "ksnPathCopy"
#     Icon = "imageres.dll,3"
#     SubCommands = ""              ← empty string = look in nested shell\
#     shell\
#       01_PathCopy\
#         (Default) = "Path Copy (quoted, mapped)"
#         Icon = "imageres.dll,3"
#         command\
#           (Default) = "pwsh.exe ... -Mode PathCopy"
#       02_Path\
#         ...
#
# Same structure repeated for Directory\shell and Directory\Background\shell.
#
Write-Host "`n  [3/3] Registering context menus (nested subkeys)" -ForegroundColor Yellow

foreach ($ctx in $contextRoots) {
    # Create parent key
    $parentKey = [Microsoft.Win32.Registry]::ClassesRoot.CreateSubKey($ctx.SubKey)
    $parentKey.SetValue("MUIVerb", $appName)
    $parentKey.SetValue("Icon", "imageres.dll,3")
    $parentKey.SetValue("SubCommands", "")   # Empty = enumerate nested shell\ subkeys
    $parentKey.Close()

    # Create each submenu item as a nested subkey
    foreach ($item in $menuItems.GetEnumerator()) {
        $keyName   = $item.Key       # e.g. "01_PathCopy"
        $label     = $item.Value.Label
        $icon      = $item.Value.Icon
        $mode      = $item.Value.Mode
        $cmdString = Get-CmdString $ctx.PathVar $mode

        # Create: <parent>\shell\01_PathCopy
        $itemSubKey = "$($ctx.SubKey)\shell\$keyName"
        $itemKey = [Microsoft.Win32.Registry]::ClassesRoot.CreateSubKey($itemSubKey)
        $itemKey.SetValue("", $label)      # (Default) = display label
        $itemKey.SetValue("Icon", $icon)
        $itemKey.Close()

        # Create: <parent>\shell\01_PathCopy\command
        $cmdSubKey = "$itemSubKey\command"
        $cmdKey = [Microsoft.Win32.Registry]::ClassesRoot.CreateSubKey($cmdSubKey)
        $cmdKey.SetValue("", $cmdString)   # (Default) = the command
        $cmdKey.Close()
    }

    Write-Host "    Registered: $($ctx.Type) (4 submenu items)" -ForegroundColor Green
}

# ── Done ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ┌─────────────────────────────────────────┐" -ForegroundColor Green
Write-Host "  │         Installation Complete            │" -ForegroundColor Green
Write-Host "  └─────────────────────────────────────────┘" -ForegroundColor Green
Write-Host ""
Write-Host "  Files:    $InstallDir" -ForegroundColor White
Write-Host "  Shell:    $psExe" -ForegroundColor White
Write-Host "  Method:   Nested HKCR subkeys (no CommandStore)" -ForegroundColor White
Write-Host "  Menu:     Right-click any file, folder, or folder background" -ForegroundColor White
Write-Host ""
Write-Host "  Submenu:" -ForegroundColor Gray
Write-Host "    Path Copy    `"J:\District1\Top 40 Sites\Br0002c`"" -ForegroundColor Gray
Write-Host "    Path          J:\District1\Top 40 Sites\Br0002c" -ForegroundColor Gray
Write-Host "    UNC Path      \\IGS-Rift\Share\District1\Top 40 Sites\Br0002c" -ForegroundColor Gray
Write-Host "    UNC Raw       \\10.1.2.3\Share\District1\Top 40 Sites\Br0002c" -ForegroundColor Gray
Write-Host ""
Write-Host "  To uninstall:  .\install.ps1 -Uninstall" -ForegroundColor DarkGray
Write-Host "  Explorer restart: taskkill /f /im explorer.exe; explorer" -ForegroundColor DarkGray
Write-Host ""
