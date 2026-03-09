#Requires -Version 7.0
<#
.SYNOPSIS
    Download all Doksn build dependencies to a local staging directory.

.DESCRIPTION
    Fetches every external tool and installer needed to build the Doksn MSI
    (and optionally the MSIX) on a clean machine or Windows Sandbox.

    Downloads:
      [1/8] .NET 8.0 SDK
      [2/8] WiX Toolset v3.14
      [3/8] Tesseract OCR 5.3
      [4/8] Ghostscript 10.04
      [5/8] Poppler (pdftotext) 24.08
      [6/8] LibreOffice 25.8  (skip with -SkipLarge)
      [7/8] Windows SDK         (skip with -SkipMSIXPrep)
      [8/8] Python wheels for keywrds standalone

    All files land in $StagingDir (default: C:\dev\ocritd\sandbox\staging\).

.PARAMETER StagingDir
    Target directory for downloaded installers.  Created if absent.

.PARAMETER SkipLarge
    Skip LibreOffice download (~350 MB).  Useful for fast iteration.

.PARAMETER SkipMSIXPrep
    Skip Windows SDK download.  Only needed for MSIX packaging.

.PARAMETER OcritdRoot
    Root of the ocritd/doksn source tree.  Default: C:\dev\ocritd

.EXAMPLE
    pwsh -ExecutionPolicy Bypass -File stage_all_deps.ps1

.EXAMPLE
    .\stage_all_deps.ps1 -SkipLarge -SkipMSIXPrep

.NOTES
    Author : kawaisunn / IGS-AI Collaboration (Claude Opus 4.6)
    Date   : 2026-03-07, full script 2026-03-09
#>
[CmdletBinding()]
param(
    [string] $StagingDir  = 'C:\dev\ocritd\sandbox\staging',
    [string] $OcritdRoot  = 'C:\dev\ocritd',
    [switch] $SkipLarge,
    [switch] $SkipMSIXPrep
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ═══════════════════════════════════════════════════════════════
# BOX-DRAWING UI HELPERS
# ═══════════════════════════════════════════════════════════════

$script:stepTotal = 8
$script:stepCurrent = 0
$script:passes = 0
$script:skips  = 0
$script:fails  = 0

function Write-Header {
    $bar = [string]([char]0x2550) * 60
    Write-Host ""
    Write-Host "$([char]0x2554)$bar$([char]0x2557)" -ForegroundColor Cyan
    Write-Host "$([char]0x2551) Doksn Build Kit $([char]0x2500) Dependency Stager$(' ' * 24)$([char]0x2551)" -ForegroundColor Cyan
    Write-Host "$([char]0x2551) Target: $StagingDir$(' ' * (51 - $StagingDir.Length))$([char]0x2551)" -ForegroundColor Cyan
    Write-Host "$([char]0x255A)$bar$([char]0x255D)" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step([string]$Label) {
    $script:stepCurrent++
    $pct = [math]::Round(($script:stepCurrent / $script:stepTotal) * 100)
    $filled = [math]::Round($pct / 5)
    $empty  = 20 - $filled
    $progBar = "$([char]0x2588)" * $filled + "$([char]0x2591)" * $empty
    Write-Host ""
    Write-Host "  [$script:stepCurrent/$script:stepTotal] $Label" -ForegroundColor Yellow
    Write-Host "  $progBar $pct%" -ForegroundColor DarkGray
}

function Write-Result([string]$Status, [string]$Detail) {
    switch ($Status) {
        'PASS'  { Write-Host "    $([char]0x2714) $Detail" -ForegroundColor Green;  $script:passes++ }
        'SKIP'  { Write-Host "    $([char]0x25CB) $Detail" -ForegroundColor DarkYellow; $script:skips++ }
        'FAIL'  { Write-Host "    $([char]0x2718) $Detail" -ForegroundColor Red;    $script:fails++ }
        'INFO'  { Write-Host "    $([char]0x2500) $Detail" -ForegroundColor DarkGray }
    }
}

function Write-Summary {
    Write-Host ""
    $bar = [string]([char]0x2500) * 40
    Write-Host "  $bar" -ForegroundColor Cyan
    Write-Host "  Staging complete: $script:passes passed, $script:skips skipped, $script:fails failed" -ForegroundColor Cyan
    if ($script:fails -gt 0) {
        Write-Host "  $([char]0x26A0) Some downloads failed. Re-run or download manually." -ForegroundColor Red
    } else {
        Write-Host "  $([char]0x2714) All dependencies staged. Ready to build." -ForegroundColor Green
    }
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════
# DOWNLOAD HELPER
# ═══════════════════════════════════════════════════════════════

function Get-Dependency {
    param(
        [string] $Url,
        [string] $OutFile,
        [string] $Label
    )
    $dest = Join-Path $StagingDir $OutFile
    if (Test-Path $dest) {
        Write-Result 'PASS' "$Label already staged: $OutFile"
        return $true
    }
    Write-Result 'INFO' "Downloading $Label..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        if (Test-Path $dest) {
            $size = (Get-Item $dest).Length
            Write-Result 'PASS' "$Label staged ($([math]::Round($size/1MB, 1)) MB)"
            return $true
        }
    }
    catch {
        Write-Result 'FAIL' "$Label download failed: $($_.Exception.Message)"
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

Write-Header

# Ensure staging dir exists
if (-not (Test-Path $StagingDir)) {
    New-Item -ItemType Directory -Path $StagingDir -Force | Out-Null
    Write-Host "  Created staging directory: $StagingDir" -ForegroundColor DarkGray
}

# ── [1/8] .NET 8.0 SDK ───────────────────────────────────────
Write-Step '.NET 8.0 SDK (8.0.404)'
Get-Dependency `
    -Url 'https://download.visualstudio.microsoft.com/download/pr/dotnet-sdk-8.0.404-win-x64.exe' `
    -OutFile 'dotnet-sdk-8.0.404-win-x64.exe' `
    -Label '.NET 8.0.404 SDK'

# ── [2/8] WiX Toolset v3.14 ──────────────────────────────────
Write-Step 'WiX Toolset v3.14 (MSI builder)'
Get-Dependency `
    -Url 'https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314.exe' `
    -OutFile 'wix314.exe' `
    -Label 'WiX v3.14'

# ── [3/8] Tesseract OCR 5.3 ──────────────────────────────────
Write-Step 'Tesseract OCR 5.3 (UB Mannheim)'
Get-Dependency `
    -Url 'https://github.com/UB-Mannheim/tesseract/releases/download/v5.3.4.20240503/tesseract-ocr-w64-setup-5.3.4.20240503.exe' `
    -OutFile 'tesseract-ocr-w64-setup-5.3.4.exe' `
    -Label 'Tesseract 5.3'

# ── [4/8] Ghostscript 10.04 ──────────────────────────────────
Write-Step 'Ghostscript 10.04'
Get-Dependency `
    -Url 'https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10040/gs10040w64.exe' `
    -OutFile 'gs10040w64.exe' `
    -Label 'Ghostscript 10.04'

# ── [5/8] Poppler 24.08 ──────────────────────────────────────
Write-Step 'Poppler 24.08 (pdftotext)'
Get-Dependency `
    -Url 'https://github.com/oschwartz10612/poppler-windows/releases/download/v24.08.0-0/Release-24.08.0-0.zip' `
    -OutFile 'poppler-24.08.0-0.zip' `
    -Label 'Poppler 24.08'

# ── [6/8] LibreOffice ─────────────────────────────────────────
Write-Step 'LibreOffice (legacy .doc/.xls conversion)'
if ($SkipLarge) {
    Write-Result 'SKIP' 'LibreOffice skipped (-SkipLarge). Install manually if needed.'
} else {
    # LibreOffice direct download URL changes frequently — check https://www.libreoffice.org/download/download-libreoffice/
    # Using a stable mirror pattern. Update version number as needed.
    Get-Dependency `
        -Url 'https://download.documentfoundation.org/libreoffice/stable/25.2.1/win/x86_64/LibreOffice_25.2.1_Win_x86-64.msi' `
        -OutFile 'LibreOffice_25.2.1_Win_x86-64.msi' `
        -Label 'LibreOffice'
}

# ── [7/8] Windows SDK (MSIX tooling) ─────────────────────────
Write-Step 'Windows SDK (makeappx.exe, signtool.exe)'
if ($SkipMSIXPrep) {
    Write-Result 'SKIP' 'Windows SDK skipped (-SkipMSIXPrep). Only needed for MSIX packaging.'
} else {
    Get-Dependency `
        -Url 'https://go.microsoft.com/fwlink/?linkid=2272610' `
        -OutFile 'winsdksetup.exe' `
        -Label 'Windows SDK installer'
}

# ── [8/8] Python wheels for keywrds ──────────────────────────
Write-Step 'Python wheels for keywrds standalone'
$wheelsDir = Join-Path $StagingDir 'wheels'
if (-not (Test-Path $wheelsDir)) {
    New-Item -ItemType Directory -Path $wheelsDir -Force | Out-Null
}

# Keywrds needs a subset of the full doksn requirements
$keywrdsWheels = @(
    'pydantic', 'pydantic-core', 'annotated-types', 'typing-extensions',
    'rich', 'colorama', 'markdown-it-py', 'mdurl', 'pygments',
    'charset-normalizer', 'tqdm'
)

$pipExe = Get-Command pip -ErrorAction SilentlyContinue
if ($pipExe) {
    Write-Result 'INFO' "Downloading $($keywrdsWheels.Count) wheels to $wheelsDir"
    try {
        & pip download $keywrdsWheels --dest $wheelsDir --only-binary :all: --platform win_amd64 --python-version 3.13 2>&1 | Out-Null
        $whlCount = (Get-ChildItem $wheelsDir -Filter '*.whl' -ErrorAction SilentlyContinue).Count
        Write-Result 'PASS' "$whlCount wheel files staged"
    }
    catch {
        Write-Result 'FAIL' "pip download failed: $($_.Exception.Message)"
        Write-Result 'INFO' 'Manual fallback: pip download pydantic rich colorama tqdm charset-normalizer --dest wheels/'
    }
} else {
    Write-Result 'FAIL' 'pip not found in PATH. Install Python or download wheels manually.'
    Write-Result 'INFO' 'Needed wheels: pydantic, rich, colorama, tqdm, charset-normalizer (+ transitive deps)'
}

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

Write-Summary

# List staged files
Write-Host "  Staged files:" -ForegroundColor DarkGray
Get-ChildItem $StagingDir -File -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "    $($_.Name)  ($([math]::Round($_.Length/1MB, 1)) MB)" -ForegroundColor DarkGray
}
$whlCount = (Get-ChildItem $wheelsDir -Filter '*.whl' -ErrorAction SilentlyContinue).Count
if ($whlCount -gt 0) {
    Write-Host "    wheels/ ($whlCount .whl files)" -ForegroundColor DarkGray
}
Write-Host ""
