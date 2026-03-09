#Requires -Version 7.0
<#
.SYNOPSIS
    Pull the latest Ktreesn module from GitHub into the Doksn runtime.

.DESCRIPTION
    Clones or pulls the kawaisunn/ktreesn repository and copies the module
    files (Ktreesn.psm1, Ktreesn.psd1) into the Doksn runtime modules
    directory so the Doksn launcher can call Ktreesn functions.

    This script is designed for both build-time (staging for MSI) and
    dev-time (keeping your local copy current) use.

    Flow:
      1. Clone or pull kawaisunn/ktreesn to $CloneDir
      2. Copy Ktreesn.psm1 + Ktreesn.psd1 to $TargetDir
      3. Verify the module imports cleanly
      4. Report version and function count

.PARAMETER CloneDir
    Where to clone/pull the ktreesn repo.  Default: C:\dev\Ktreesn

.PARAMETER TargetDir
    Doksn runtime module directory.  Default: C:\dev\ocritd\runtime\modules\Ktreesn

.PARAMETER Branch
    Git branch to track.  Default: main

.PARAMETER RepoUrl
    Git remote URL.  Default: https://github.com/kawaisunn/ktreesn.git

.PARAMETER SkipPull
    Don't pull from remote; just copy existing local files.

.PARAMETER Verify
    Import the module after staging and verify functions are exported.

.EXAMPLE
    .\stage_ktreesn.ps1

.EXAMPLE
    .\stage_ktreesn.ps1 -SkipPull -Verify

.EXAMPLE
    # Stage to a different target (e.g., Antiquarian)
    .\stage_ktreesn.ps1 -TargetDir 'D:\doksn\runtime\modules\Ktreesn'

.NOTES
    Author : kawaisunn / IGS-AI Collaboration (Claude Opus 4.6)
    Date   : 2026-03-09
#>
[CmdletBinding()]
param(
    [string] $CloneDir  = 'C:\dev\Ktreesn',
    [string] $TargetDir = 'C:\dev\ocritd\runtime\modules\Ktreesn',
    [string] $Branch    = 'main',
    [string] $RepoUrl   = 'https://github.com/kawaisunn/ktreesn.git',
    [switch] $SkipPull,
    [switch] $Verify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ═══════════════════════════════════════════════════════════════
# GIT RESOLUTION
# ═══════════════════════════════════════════════════════════════

# Find git — try common paths
$gitExe = $null
$gitCandidates = @(
    (Get-Command git -ErrorAction SilentlyContinue)?.Source,
    'C:\Program Files\Git\cmd\git.exe',
    'C:\Program Files (x86)\Git\cmd\git.exe'
)
foreach ($g in $gitCandidates) {
    if ($g -and (Test-Path $g)) { $gitExe = $g; break }
}

Write-Host ""
Write-Host "$([char]0x2554)$([string]([char]0x2550) * 50)$([char]0x2557)" -ForegroundColor Cyan
Write-Host "$([char]0x2551) Ktreesn Module Stager$(' ' * 29)$([char]0x2551)" -ForegroundColor Cyan
Write-Host "$([char]0x255A)$([string]([char]0x2550) * 50)$([char]0x255D)" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# [1/3] CLONE OR PULL
# ═══════════════════════════════════════════════════════════════

Write-Host "  [1/3] Source: $CloneDir" -ForegroundColor Yellow

if ($SkipPull) {
    Write-Host "    $([char]0x25CB) Skipping git pull (-SkipPull)" -ForegroundColor DarkGray
} elseif (-not $gitExe) {
    Write-Host "    $([char]0x26A0) git not found. Using existing local files." -ForegroundColor Yellow
} else {
    if (Test-Path (Join-Path $CloneDir '.git')) {
        # Pull latest
        Write-Host "    Pulling latest from $Branch..." -ForegroundColor DarkGray
        Push-Location $CloneDir
        try {
            $pullOutput = & $gitExe pull origin $Branch 2>&1
            $pullStatus = $LASTEXITCODE
            if ($pullStatus -eq 0) {
                $headHash = (& $gitExe rev-parse --short HEAD 2>$null) ?? 'unknown'
                Write-Host "    $([char]0x2714) Updated to $headHash" -ForegroundColor Green
            } else {
                Write-Host "    $([char]0x26A0) git pull returned exit code $pullStatus" -ForegroundColor Yellow
                $pullOutput | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
            }
        }
        finally { Pop-Location }
    } else {
        # Fresh clone
        Write-Host "    Cloning $RepoUrl..." -ForegroundColor DarkGray
        $cloneParent = Split-Path $CloneDir -Parent
        if (-not (Test-Path $cloneParent)) {
            New-Item -ItemType Directory -Path $cloneParent -Force | Out-Null
        }
        & $gitExe clone $RepoUrl $CloneDir -b $Branch 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    $([char]0x2714) Cloned to $CloneDir" -ForegroundColor Green
        } else {
            Write-Error "git clone failed. Check credentials and network."
            return
        }
    }
}

# Verify source files exist
$srcPsm1 = Join-Path $CloneDir 'Ktreesn.psm1'
$srcPsd1 = Join-Path $CloneDir 'Ktreesn.psd1'

if (-not (Test-Path $srcPsm1)) {
    Write-Error "Ktreesn.psm1 not found at $CloneDir. Clone may have failed."
    return
}
if (-not (Test-Path $srcPsd1)) {
    Write-Host "    $([char]0x26A0) Ktreesn.psd1 not found. Copying psm1 only." -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════
# [2/3] COPY TO DOKSN RUNTIME
# ═══════════════════════════════════════════════════════════════

Write-Host "  [2/3] Target: $TargetDir" -ForegroundColor Yellow

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Write-Host "    Created target directory" -ForegroundColor DarkGray
}

$copied = 0
foreach ($file in @($srcPsm1, $srcPsd1)) {
    if (Test-Path $file) {
        Copy-Item -LiteralPath $file -Destination $TargetDir -Force
        $copied++
    }
}

# Also copy README if present (for reference)
$srcReadme = Join-Path $CloneDir 'README.md'
if (Test-Path $srcReadme) {
    Copy-Item -LiteralPath $srcReadme -Destination $TargetDir -Force
    $copied++
}

Write-Host "    $([char]0x2714) $copied files copied to runtime" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# [3/3] VERIFY (optional)
# ═══════════════════════════════════════════════════════════════

Write-Host "  [3/3] Verification" -ForegroundColor Yellow

$targetPsd1 = Join-Path $TargetDir 'Ktreesn.psd1'
$targetPsm1 = Join-Path $TargetDir 'Ktreesn.psm1'

# Basic checks
if (Test-Path $targetPsm1) {
    $lineCount = (Get-Content $targetPsm1).Count
    Write-Host "    Ktreesn.psm1: $lineCount lines" -ForegroundColor DarkGray
}
if (Test-Path $targetPsd1) {
    $psdContent = Get-Content $targetPsd1 -Raw
    if ($psdContent -match "ModuleVersion\s*=\s*'([^']+)'") {
        Write-Host "    Module version: $($Matches[1])" -ForegroundColor DarkGray
    }
}

if ($Verify -and (Test-Path $targetPsd1)) {
    Write-Host "    Importing module for verification..." -ForegroundColor DarkGray
    try {
        # Import in a child scope to avoid polluting current session
        $testResult = pwsh -NoProfile -Command @"
            Import-Module '$targetPsd1' -Force -ErrorAction Stop
            `$funcs = Get-Command -Module Ktreesn
            `$aliases = Get-Alias | Where-Object { `$_.ModuleName -eq 'Ktreesn' }
            [PSCustomObject]@{
                Functions = `$funcs.Count
                Aliases   = `$aliases.Count
                Names     = (`$funcs.Name -join ', ')
            } | ConvertTo-Json
"@ | ConvertFrom-Json

        Write-Host "    $([char]0x2714) Module imports cleanly" -ForegroundColor Green
        Write-Host "    Functions: $($testResult.Functions) ($($testResult.Names))" -ForegroundColor DarkGray
        Write-Host "    Aliases: $($testResult.Aliases)" -ForegroundColor DarkGray
    }
    catch {
        Write-Host "    $([char]0x2718) Module import failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} elseif (-not $Verify) {
    Write-Host "    $([char]0x25CB) Skipped import test. Use -Verify to test." -ForegroundColor DarkGray
}

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  $([char]0x2500)$([string]([char]0x2500) * 49)" -ForegroundColor Cyan
Write-Host "  $([char]0x2714) Ktreesn staged for Doksn" -ForegroundColor Green
Write-Host "  Source: $CloneDir" -ForegroundColor DarkGray
Write-Host "  Target: $TargetDir" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  C# integration call pattern:" -ForegroundColor DarkGray
Write-Host "    pwsh -NoProfile -Command `"Import-Module '$targetPsd1'; ...`"" -ForegroundColor DarkGray
Write-Host ""
