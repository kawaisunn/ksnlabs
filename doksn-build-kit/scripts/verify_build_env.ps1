#Requires -Version 7.0
<#
.SYNOPSIS
    Pre-build sanity check: are all tools present to build Doksn?

.DESCRIPTION
    Checks for every tool, SDK, runtime, and staged installer needed by the
    Doksn build pipeline (BUILD_ALL.ps1).  Reports PASS / WARN / FAIL for
    each check with a box-drawing summary at the end.

    Checks:
      .NET 8 SDK, WiX v3 CLI (candle/light), Python 3.x, Tesseract OCR,
      Ghostscript, Poppler (pdftotext), ocritd source tree, staged
      installers in sandbox/staging, MSIX tooling (optional).

.PARAMETER OcritdRoot
    Root of the ocritd/doksn source tree.  Default: C:\dev\ocritd

.PARAMETER StagingDir
    Where stage_all_deps.ps1 downloaded installers.  Default: C:\dev\ocritd\sandbox\staging

.PARAMETER CheckMSIX
    Include MSIX tooling checks (makeappx.exe, signtool.exe).

.EXAMPLE
    .\verify_build_env.ps1

.EXAMPLE
    .\verify_build_env.ps1 -CheckMSIX

.NOTES
    Author : kawaisunn / IGS-AI Collaboration (Claude Opus 4.6)
    Date   : 2026-03-07, full script 2026-03-09
#>
[CmdletBinding()]
param(
    [string] $OcritdRoot = 'C:\dev\ocritd',
    [string] $StagingDir = 'C:\dev\ocritd\sandbox\staging',
    [switch] $CheckMSIX
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$script:passes = 0
$script:warns  = 0
$script:fails  = 0

# ═══════════════════════════════════════════════════════════════
# UI HELPERS
# ═══════════════════════════════════════════════════════════════

function Write-Header {
    $bar = [string]([char]0x2550) * 60
    Write-Host ""
    Write-Host "$([char]0x2554)$bar$([char]0x2557)" -ForegroundColor Cyan
    Write-Host "$([char]0x2551) Doksn Build Environment Verifier$(' ' * 27)$([char]0x2551)" -ForegroundColor Cyan
    Write-Host "$([char]0x255A)$bar$([char]0x255D)" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Check([string]$Label, [string]$Status, [string]$Detail) {
    switch ($Status) {
        'PASS' {
            Write-Host "  $([char]0x2714) " -ForegroundColor Green -NoNewline
            Write-Host "$Label" -NoNewline
            Write-Host " $([char]0x2500) $Detail" -ForegroundColor DarkGray
            $script:passes++
        }
        'WARN' {
            Write-Host "  $([char]0x26A0) " -ForegroundColor Yellow -NoNewline
            Write-Host "$Label" -NoNewline
            Write-Host " $([char]0x2500) $Detail" -ForegroundColor DarkYellow
            $script:warns++
        }
        'FAIL' {
            Write-Host "  $([char]0x2718) " -ForegroundColor Red -NoNewline
            Write-Host "$Label" -NoNewline
            Write-Host " $([char]0x2500) $Detail" -ForegroundColor Red
            $script:fails++
        }
    }
}

function Test-CommandExists([string]$Cmd) {
    return [bool](Get-Command $Cmd -ErrorAction SilentlyContinue)
}

# ═══════════════════════════════════════════════════════════════
# CHECKS
# ═══════════════════════════════════════════════════════════════

Write-Header

Write-Host "  $([char]0x250C) Build Tools" -ForegroundColor White
Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray

# .NET SDK
if (Test-CommandExists 'dotnet') {
    $dotnetVer = & dotnet --version 2>$null
    if ($dotnetVer -match '^8\.') {
        Write-Check '.NET SDK' 'PASS' "v$dotnetVer"
    } else {
        Write-Check '.NET SDK' 'WARN' "v$dotnetVer found (need 8.x). Staged installer may work."
    }
} else {
    Write-Check '.NET SDK' 'FAIL' 'dotnet not in PATH. Run staged dotnet-sdk installer.'
}

# WiX Toolset (candle.exe / light.exe)
$wixPaths = @(
    'C:\Program Files (x86)\WiX Toolset v3.14\bin\candle.exe',
    'C:\Program Files (x86)\WiX Toolset v3.11\bin\candle.exe'
)
$wixFound = $wixPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($wixFound) {
    Write-Check 'WiX Toolset' 'PASS' "candle.exe found at $(Split-Path $wixFound -Parent)"
} elseif (Test-CommandExists 'candle') {
    Write-Check 'WiX Toolset' 'PASS' 'candle.exe in PATH'
} else {
    $staged = Join-Path $StagingDir 'wix314.exe'
    if (Test-Path $staged) {
        Write-Check 'WiX Toolset' 'WARN' "Not installed, but wix314.exe staged. Run installer."
    } else {
        Write-Check 'WiX Toolset' 'FAIL' 'Not installed and not staged. Run stage_all_deps.ps1 first.'
    }
}

# Python
if (Test-CommandExists 'python') {
    $pyVer = & python --version 2>$null
    Write-Check 'Python' 'PASS' $pyVer
} elseif (Test-CommandExists 'py') {
    $pyVer = & py --version 2>$null
    Write-Check 'Python' 'PASS' "$pyVer (via py launcher)"
} else {
    Write-Check 'Python' 'FAIL' 'python not found. Needed for engine/ and keywrds.'
}

Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray
Write-Host "  $([char]0x251C) External Tools" -ForegroundColor White
Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray

# Tesseract
$tessPaths = @(
    'C:\Program Files\Tesseract-OCR\tesseract.exe',
    'C:\Program Files (x86)\Tesseract-OCR\tesseract.exe'
)
$tessFound = $tessPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($tessFound -or (Test-CommandExists 'tesseract')) {
    $tessExe = if ($tessFound) { $tessFound } else { (Get-Command tesseract).Source }
    $tessVer = & $tessExe --version 2>&1 | Select-Object -First 1
    Write-Check 'Tesseract OCR' 'PASS' $tessVer
} else {
    Write-Check 'Tesseract OCR' 'FAIL' 'Not installed. Required for OCR processing.'
}

# Ghostscript
$gsPaths = @(
    'C:\Program Files\gs\gs10.04.0\bin\gswin64c.exe',
    'C:\Program Files\gs\gs10.03.1\bin\gswin64c.exe',
    'C:\Program Files (x86)\gs\gs10.04.0\bin\gswin32c.exe'
)
$gsFound = $gsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($gsFound -or (Test-CommandExists 'gswin64c')) {
    Write-Check 'Ghostscript' 'PASS' ($gsFound ?? 'gswin64c in PATH')
} else {
    Write-Check 'Ghostscript' 'WARN' 'Not found in standard paths. Needed for PDF OCR preprocessing.'
}

# Poppler (pdftotext)
if (Test-CommandExists 'pdftotext') {
    Write-Check 'Poppler (pdftotext)' 'PASS' 'pdftotext in PATH'
} else {
    $popplerDir = Get-ChildItem 'C:\' -Directory -Filter 'poppler*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($popplerDir) {
        Write-Check 'Poppler (pdftotext)' 'WARN' "Found $($popplerDir.FullName) but not in PATH."
    } else {
        Write-Check 'Poppler (pdftotext)' 'WARN' 'Not found. Optional but recommended for text-based PDFs.'
    }
}

Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray
Write-Host "  $([char]0x251C) Source Files" -ForegroundColor White
Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray

# ocritd source tree
if (Test-Path (Join-Path $OcritdRoot 'engine\doksn.py')) {
    Write-Check 'Doksn source' 'PASS' "engine/doksn.py found in $OcritdRoot"
} else {
    Write-Check 'Doksn source' 'FAIL' "engine/doksn.py not found at $OcritdRoot"
}

# BUILD_ALL.ps1
if (Test-Path (Join-Path $OcritdRoot 'BUILD_ALL.ps1')) {
    Write-Check 'BUILD_ALL.ps1' 'PASS' 'Build orchestrator present'
} else {
    Write-Check 'BUILD_ALL.ps1' 'FAIL' 'BUILD_ALL.ps1 missing from ocritd root'
}

# keywrds engine
$kwDir = Join-Path $OcritdRoot 'engine\keywards'
if (Test-Path $kwDir) {
    $kwModules = (Get-ChildItem $kwDir -Filter '*.py' -ErrorAction SilentlyContinue).Count
    Write-Check 'keywrds engine' 'PASS' "$kwModules Python modules in engine/keywards/"
} else {
    Write-Check 'keywrds engine' 'FAIL' 'engine/keywards/ not found'
}

# WiX source (.wxs)
$wxsFiles = Get-ChildItem $OcritdRoot -Filter '*.wxs' -Recurse -ErrorAction SilentlyContinue
if ($wxsFiles.Count -gt 0) {
    Write-Check 'WiX sources' 'PASS' "$($wxsFiles.Count) .wxs file(s) found"
} else {
    Write-Check 'WiX sources' 'WARN' 'No .wxs files found. BUILD.ps1 may generate them.'
}

# Ktreesn module
$ktreesnPaths = @(
    (Join-Path $OcritdRoot 'runtime\modules\Ktreesn\Ktreesn.psm1'),
    'C:\dev\Ktreesn\Ktreesn.psm1'
)
$ktreesnFound = $ktreesnPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($ktreesnFound) {
    Write-Check 'Ktreesn module' 'PASS' "Found at $(Split-Path $ktreesnFound -Parent)"
} else {
    Write-Check 'Ktreesn module' 'WARN' 'Not staged into runtime/modules/. Run stage_ktreesn.ps1'
}

Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray
Write-Host "  $([char]0x251C) Staged Installers" -ForegroundColor White
Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray

# Check staging directory
if (Test-Path $StagingDir) {
    $stagedFiles = Get-ChildItem $StagingDir -File -ErrorAction SilentlyContinue
    $totalMB = [math]::Round(($stagedFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    Write-Check 'Staging directory' 'PASS' "$($stagedFiles.Count) files, $totalMB MB total"

    # Spot-check key files
    $expectedFiles = @('dotnet-sdk-8.0.404-win-x64.exe', 'wix314.exe', 'tesseract-ocr-w64-setup-5.3.4.exe', 'gs10040w64.exe')
    foreach ($ef in $expectedFiles) {
        if (Test-Path (Join-Path $StagingDir $ef)) {
            Write-Check "  $ef" 'PASS' 'staged'
        } else {
            Write-Check "  $ef" 'WARN' 'not staged'
        }
    }

    # Wheels
    $wheelsDir = Join-Path $StagingDir 'wheels'
    if (Test-Path $wheelsDir) {
        $whlCount = (Get-ChildItem $wheelsDir -Filter '*.whl' -ErrorAction SilentlyContinue).Count
        if ($whlCount -gt 0) {
            Write-Check '  Python wheels' 'PASS' "$whlCount .whl files"
        } else {
            Write-Check '  Python wheels' 'WARN' 'wheels/ exists but empty'
        }
    } else {
        Write-Check '  Python wheels' 'WARN' 'wheels/ not found. Keywrds standalone may fail.'
    }
} else {
    Write-Check 'Staging directory' 'FAIL' "$StagingDir does not exist. Run stage_all_deps.ps1"
}

# MSIX tooling (optional)
if ($CheckMSIX) {
    Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray
    Write-Host "  $([char]0x251C) MSIX Tooling" -ForegroundColor White
    Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray

    if (Test-CommandExists 'makeappx') {
        Write-Check 'makeappx.exe' 'PASS' 'in PATH'
    } else {
        $sdkPaths = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin' -Recurse -Filter 'makeappx.exe' -ErrorAction SilentlyContinue
        if ($sdkPaths) {
            Write-Check 'makeappx.exe' 'PASS' $sdkPaths[0].FullName
        } else {
            Write-Check 'makeappx.exe' 'FAIL' 'Not found. Install Windows SDK.'
        }
    }

    if (Test-CommandExists 'signtool') {
        Write-Check 'signtool.exe' 'PASS' 'in PATH'
    } else {
        $sdkPaths = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin' -Recurse -Filter 'signtool.exe' -ErrorAction SilentlyContinue
        if ($sdkPaths) {
            Write-Check 'signtool.exe' 'PASS' $sdkPaths[0].FullName
        } else {
            Write-Check 'signtool.exe' 'FAIL' 'Not found. Install Windows SDK.'
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray
Write-Host "  $([char]0x2514)" -ForegroundColor DarkGray
Write-Host ""
$bar = [string]([char]0x2550) * 50
Write-Host "  $bar" -ForegroundColor Cyan
Write-Host "  PASS: $script:passes  |  WARN: $script:warns  |  FAIL: $script:fails" -ForegroundColor Cyan

if ($script:fails -eq 0 -and $script:warns -eq 0) {
    Write-Host "  $([char]0x2714) Build environment is fully ready!" -ForegroundColor Green
} elseif ($script:fails -eq 0) {
    Write-Host "  $([char]0x26A0) Build should work, but resolve warnings for best results." -ForegroundColor Yellow
} else {
    Write-Host "  $([char]0x2718) Build will likely fail. Fix FAIL items above." -ForegroundColor Red
}
Write-Host "  $bar" -ForegroundColor Cyan
Write-Host ""

# Return structured result for automation
[PSCustomObject]@{
    Passes = $script:passes
    Warns  = $script:warns
    Fails  = $script:fails
    Ready  = ($script:fails -eq 0)
}
