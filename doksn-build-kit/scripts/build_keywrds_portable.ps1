#Requires -Version 7.0
<#
.SYNOPSIS
    Package the keywrds engine as a standalone portable zip.

.DESCRIPTION
    Creates a self-contained portable distribution of keywrds that needs no
    .NET runtime, no admin rights, and no installation.  Unzip and run.

    The package contains:
      - Embedded Python 3.13 (from python.org embeddable package)
      - engine/keywards/ (10 modules from ocritd tree)
      - Pre-installed wheels (pydantic, rich, colorama, tqdm, etc.)
      - run_keywrds.cmd  (double-click launcher)
      - run_keywrds.ps1  (PowerShell launcher with argument passthrough)

    Output: $OcritdRoot\dist\keywrds_standalone_v$Version.zip

.PARAMETER OcritdRoot
    Root of the ocritd/doksn source tree.  Default: C:\dev\ocritd

.PARAMETER StagingDir
    Where stage_all_deps.ps1 downloaded wheels.  Default: C:\dev\ocritd\sandbox\staging

.PARAMETER Version
    Version tag for the output zip.  Default: reads from engine/version.py.

.PARAMETER PythonEmbedUrl
    URL for the Python 3.13 embeddable zip.  Override if you need a different version.

.EXAMPLE
    .\build_keywrds_portable.ps1

.EXAMPLE
    .\build_keywrds_portable.ps1 -Version '0.9.0'

.NOTES
    Author : kawaisunn / IGS-AI Collaboration (Claude Opus 4.6)
    Date   : 2026-03-07, full script 2026-03-09
#>
[CmdletBinding()]
param(
    [string] $OcritdRoot     = 'C:\dev\ocritd',
    [string] $StagingDir     = 'C:\dev\ocritd\sandbox\staging',
    [string] $Version        = '',
    [string] $PythonEmbedUrl = 'https://www.python.org/ftp/python/3.13.0/python-3.13.0-embed-amd64.zip'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ═══════════════════════════════════════════════════════════════
# RESOLVE VERSION
# ═══════════════════════════════════════════════════════════════

if (-not $Version) {
    $versionPy = Join-Path $OcritdRoot 'engine\version.py'
    if (Test-Path $versionPy) {
        $content = Get-Content $versionPy -Raw
        if ($content -match '__version__\s*=\s*"([^"]+)"') {
            $Version = $Matches[1]
        }
    }
    if (-not $Version) { $Version = '0.8.0' }
}

$buildDir  = Join-Path $OcritdRoot "dist\keywrds_build_$Version"
$outputZip = Join-Path $OcritdRoot "dist\keywrds_standalone_v$Version.zip"
$wheelsDir = Join-Path $StagingDir 'wheels'
$kwSource  = Join-Path $OcritdRoot 'engine\keywards'

Write-Host ""
Write-Host "$([char]0x2554)$([string]([char]0x2550) * 50)$([char]0x2557)" -ForegroundColor Cyan
Write-Host "$([char]0x2551) keywrds Standalone Portable Builder$(' ' * 13)$([char]0x2551)" -ForegroundColor Cyan
Write-Host "$([char]0x2551) Version: $Version$(' ' * (40 - $Version.Length))$([char]0x2551)" -ForegroundColor Cyan
Write-Host "$([char]0x255A)$([string]([char]0x2550) * 50)$([char]0x255D)" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# PREFLIGHT
# ═══════════════════════════════════════════════════════════════

if (-not (Test-Path $kwSource)) {
    Write-Error "keywrds source not found at $kwSource. Check OcritdRoot."
    return
}

# Ensure dist/ exists
$distDir = Join-Path $OcritdRoot 'dist'
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

# Clean previous build
if (Test-Path $buildDir) {
    Write-Host "  Cleaning previous build..." -ForegroundColor DarkGray
    Remove-Item $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# ═══════════════════════════════════════════════════════════════
# [1/5] EMBEDDED PYTHON
# ═══════════════════════════════════════════════════════════════

Write-Host "  [1/5] Embedded Python 3.13" -ForegroundColor Yellow

$pyZipStaged = Join-Path $StagingDir 'python-3.13.0-embed-amd64.zip'
$pyZipFile   = $pyZipStaged

if (-not (Test-Path $pyZipStaged)) {
    Write-Host "    Downloading embedded Python..." -ForegroundColor DarkGray
    Invoke-WebRequest -Uri $PythonEmbedUrl -OutFile $pyZipStaged -UseBasicParsing
}

$pythonDir = Join-Path $buildDir 'python'
New-Item -ItemType Directory -Path $pythonDir -Force | Out-Null
Expand-Archive -LiteralPath $pyZipFile -DestinationPath $pythonDir -Force

# Enable pip/site-packages: uncomment 'import site' in python313._pth
$pthFile = Get-ChildItem $pythonDir -Filter 'python*._pth' | Select-Object -First 1
if ($pthFile) {
    $pthContent = Get-Content $pthFile.FullName
    $pthContent = $pthContent -replace '^#\s*import site', 'import site'
    # Add Lib\site-packages path
    $pthContent += 'Lib\site-packages'
    $pthContent | Set-Content $pthFile.FullName -Encoding utf8
    Write-Host "    $([char]0x2714) Embedded Python extracted, site-packages enabled" -ForegroundColor Green
} else {
    Write-Host "    $([char]0x26A0) Could not find ._pth file to enable site-packages" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════
# [2/5] INSTALL WHEELS
# ═══════════════════════════════════════════════════════════════

Write-Host "  [2/5] Installing wheels" -ForegroundColor Yellow

$sitePackages = Join-Path $pythonDir 'Lib\site-packages'
New-Item -ItemType Directory -Path $sitePackages -Force | Out-Null

if (Test-Path $wheelsDir) {
    $wheels = Get-ChildItem $wheelsDir -Filter '*.whl'
    if ($wheels.Count -gt 0) {
        # Use pip from host to install into the embedded python's site-packages
        $pipExe = Get-Command pip -ErrorAction SilentlyContinue
        if ($pipExe) {
            & pip install --no-deps --target $sitePackages ($wheels | ForEach-Object { $_.FullName }) 2>&1 | Out-Null
            Write-Host "    $([char]0x2714) $($wheels.Count) wheels installed to site-packages" -ForegroundColor Green
        } else {
            # Fallback: extract wheels directly (they're zip files)
            foreach ($whl in $wheels) {
                Expand-Archive -LiteralPath $whl.FullName -DestinationPath $sitePackages -Force
            }
            Write-Host "    $([char]0x2714) $($wheels.Count) wheels extracted (fallback mode)" -ForegroundColor Green
        }
    } else {
        Write-Host "    $([char]0x26A0) No .whl files in $wheelsDir" -ForegroundColor Yellow
    }
} else {
    Write-Host "    $([char]0x26A0) Wheels directory not found. Run stage_all_deps.ps1 first." -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════
# [3/5] COPY KEYWRDS ENGINE
# ═══════════════════════════════════════════════════════════════

Write-Host "  [3/5] Copying keywrds engine" -ForegroundColor Yellow

$kwDest = Join-Path $buildDir 'engine\keywards'
New-Item -ItemType Directory -Path (Join-Path $buildDir 'engine') -Force | Out-Null
Copy-Item -LiteralPath $kwSource -Destination $kwDest -Recurse -Force

# Also copy the engine __init__.py and version.py so imports work
$engineInit = Join-Path $OcritdRoot 'engine\__init__.py'
$engineVer  = Join-Path $OcritdRoot 'engine\version.py'
if (Test-Path $engineInit) { Copy-Item $engineInit -Destination (Join-Path $buildDir 'engine\__init__.py') }
if (Test-Path $engineVer)  { Copy-Item $engineVer  -Destination (Join-Path $buildDir 'engine\version.py') }

$kwModules = (Get-ChildItem $kwDest -Filter '*.py').Count
Write-Host "    $([char]0x2714) $kwModules modules copied" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# [4/5] CREATE LAUNCHERS
# ═══════════════════════════════════════════════════════════════

Write-Host "  [4/5] Creating launchers" -ForegroundColor Yellow

# CMD launcher (double-click friendly)
$cmdLauncher = @"
@echo off
REM keywrds Standalone Launcher v$Version
REM Double-click to run, or: run_keywrds.cmd [args]
setlocal
set SCRIPT_DIR=%~dp0
set PYTHON=%SCRIPT_DIR%python\python.exe
set PYTHONPATH=%SCRIPT_DIR%

if "%~1"=="" (
    echo keywrds v$Version - Keyword extraction engine
    echo Usage: run_keywrds.cmd ^<input_file_or_dir^> [options]
    echo.
    "%PYTHON%" -m engine.keywards --help 2>nul || echo Run with an input path to extract keywords.
) else (
    "%PYTHON%" -m engine.keywards %*
)

pause
"@
$cmdLauncher | Set-Content (Join-Path $buildDir 'run_keywrds.cmd') -Encoding ascii

# PowerShell launcher
$ps1Launcher = @"
# keywrds Standalone Launcher v$Version
# Usage: .\run_keywrds.ps1 <input_file_or_dir> [options]
param([Parameter(ValueFromRemainingArguments)]`$Args)

`$scriptDir = `$PSScriptRoot
`$python    = Join-Path `$scriptDir 'python\python.exe'
`$env:PYTHONPATH = `$scriptDir

if (-not `$Args -or `$Args.Count -eq 0) {
    Write-Host 'keywrds v$Version - Keyword extraction engine' -ForegroundColor Cyan
    Write-Host 'Usage: .\run_keywrds.ps1 <input_file_or_dir> [options]'
    & `$python -m engine.keywards --help 2>`$null
} else {
    & `$python -m engine.keywards @Args
}
"@
$ps1Launcher | Set-Content (Join-Path $buildDir 'run_keywrds.ps1') -Encoding utf8

Write-Host "    $([char]0x2714) run_keywrds.cmd + run_keywrds.ps1 created" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# [5/5] CREATE ZIP
# ═══════════════════════════════════════════════════════════════

Write-Host "  [5/5] Packaging zip" -ForegroundColor Yellow

if (Test-Path $outputZip) { Remove-Item $outputZip -Force }
Compress-Archive -Path "$buildDir\*" -DestinationPath $outputZip -Force

$zipSize = [math]::Round((Get-Item $outputZip).Length / 1MB, 1)
Write-Host ""
Write-Host "  $([char]0x2714) keywrds standalone packaged!" -ForegroundColor Green
Write-Host "    Output: $outputZip ($zipSize MB)" -ForegroundColor Cyan
Write-Host "    Unzip anywhere and run: run_keywrds.cmd or run_keywrds.ps1" -ForegroundColor DarkGray
Write-Host ""

# Clean build dir (keep zip)
Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue

return $outputZip
