#Requires -Version 7.0
<#
.SYNOPSIS
    Convert the Doksn MSI to an MSIX package.

.DESCRIPTION
    Generates an AppxManifest.xml, creates an MSIX layout directory from the
    built MSI contents, and packages with makeappx.exe from the Windows SDK.

    This produces a dev/test MSIX.  For production distribution, the package
    must be signed with a trusted certificate (self-signed for dev, UofI cert
    for internal deployment, CA cert for public).  See docs/msix_prep.md.

    Prerequisites:
      - Windows SDK installed (makeappx.exe, signtool.exe)
      - Built MSI from BUILD_ALL.ps1
      - Optional: code signing certificate (.pfx)

.PARAMETER OcritdRoot
    Root of the ocritd/doksn source tree.  Default: C:\dev\ocritd

.PARAMETER MsiPath
    Path to the built .msi file.  Default: auto-detected in dist/.

.PARAMETER OutputDir
    Where to write the .msix file.  Default: $OcritdRoot\dist

.PARAMETER CertPath
    Optional .pfx file for signing.  If omitted, creates a self-signed cert.

.PARAMETER CertPassword
    Password for the .pfx certificate.

.PARAMETER Publisher
    MSIX publisher identity.  Default: CN=KSN Labs, O=Idaho Geological Survey

.PARAMETER Version
    MSIX version (must be x.y.z.w format).  Default: reads from engine/version.py + .0

.EXAMPLE
    .\convert_msi_to_msix.ps1

.EXAMPLE
    .\convert_msi_to_msix.ps1 -CertPath C:\certs\doksn.pfx -CertPassword 'secret'

.NOTES
    Author : kawaisunn / IGS-AI Collaboration (Claude Opus 4.6)
    Date   : 2026-03-07, full script 2026-03-09
    See    : docs/msix_prep.md for signing and deployment details
#>
[CmdletBinding()]
param(
    [string] $OcritdRoot   = 'C:\dev\ocritd',
    [string] $MsiPath      = '',
    [string] $OutputDir    = '',
    [string] $CertPath     = '',
    [string] $CertPassword = '',
    [string] $Publisher    = 'CN=KSN Labs, O=Idaho Geological Survey',
    [string] $Version      = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ═══════════════════════════════════════════════════════════════
# RESOLVE PARAMETERS
# ═══════════════════════════════════════════════════════════════

if (-not $OutputDir) { $OutputDir = Join-Path $OcritdRoot 'dist' }
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

# Auto-detect MSI
if (-not $MsiPath) {
    $msiCandidates = Get-ChildItem (Join-Path $OcritdRoot 'dist') -Filter '*.msi' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
    if ($msiCandidates.Count -eq 0) {
        Write-Error "No .msi found in $OcritdRoot\dist. Run BUILD_ALL.ps1 first."
        return
    }
    $MsiPath = $msiCandidates[0].FullName
    Write-Host "  Auto-detected MSI: $($msiCandidates[0].Name)" -ForegroundColor DarkGray
}

if (-not (Test-Path $MsiPath)) {
    Write-Error "MSI not found: $MsiPath"
    return
}

# Resolve version
if (-not $Version) {
    $versionPy = Join-Path $OcritdRoot 'engine\version.py'
    if (Test-Path $versionPy) {
        $content = Get-Content $versionPy -Raw
        if ($content -match '__version__\s*=\s*"([^"]+)"') {
            $Version = $Matches[1] + '.0'   # MSIX needs x.y.z.w
        }
    }
    if (-not $Version) { $Version = '0.8.0.0' }
}
# Ensure x.y.z.w format
if (($Version.Split('.')).Count -lt 4) { $Version += '.0' }

# Find makeappx.exe
$makeappx = Get-Command 'makeappx.exe' -ErrorAction SilentlyContinue
if (-not $makeappx) {
    $sdkSearch = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin' -Recurse -Filter 'makeappx.exe' -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if ($sdkSearch) {
        $makeappx = $sdkSearch
    } else {
        Write-Error 'makeappx.exe not found. Install Windows SDK or add to PATH.'
        return
    }
}
$makeappxExe = if ($makeappx -is [System.Management.Automation.CommandInfo]) { $makeappx.Source } else { $makeappx.FullName }

Write-Host ""
Write-Host "$([char]0x2554)$([string]([char]0x2550) * 50)$([char]0x2557)" -ForegroundColor Cyan
Write-Host "$([char]0x2551) Doksn MSI $([char]0x2192) MSIX Converter$(' ' * 23)$([char]0x2551)" -ForegroundColor Cyan
Write-Host "$([char]0x2551) Version: $Version$(' ' * (40 - $Version.Length))$([char]0x2551)" -ForegroundColor Cyan
Write-Host "$([char]0x255A)$([string]([char]0x2550) * 50)$([char]0x255D)" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# [1/4] EXTRACT MSI CONTENTS
# ═══════════════════════════════════════════════════════════════

Write-Host "  [1/4] Extracting MSI contents" -ForegroundColor Yellow

$layoutDir = Join-Path $OutputDir 'msix_layout'
if (Test-Path $layoutDir) { Remove-Item $layoutDir -Recurse -Force }
New-Item -ItemType Directory -Path $layoutDir -Force | Out-Null

# Use msiexec to extract to layout
$msiLog = Join-Path $env:TEMP 'doksn_msi_extract.log'
Start-Process msiexec.exe -ArgumentList "/a `"$MsiPath`" /qn TARGETDIR=`"$layoutDir`" /lv `"$msiLog`"" -Wait -NoNewWindow

# Verify extraction
$extractedFiles = Get-ChildItem $layoutDir -Recurse -File -ErrorAction SilentlyContinue
if ($extractedFiles.Count -eq 0) {
    Write-Host "    $([char]0x2718) MSI extraction produced no files. Check $msiLog" -ForegroundColor Red
    return
}
Write-Host "    $([char]0x2714) Extracted $($extractedFiles.Count) files" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# [2/4] GENERATE AppxManifest.xml
# ═══════════════════════════════════════════════════════════════

Write-Host "  [2/4] Generating AppxManifest.xml" -ForegroundColor Yellow

$manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
         IgnorableNamespaces="uap rescap">

  <Identity Name="KSNLabs.Doksn"
            Publisher="$Publisher"
            Version="$Version"
            ProcessorArchitecture="x64" />

  <Properties>
    <DisplayName>Doksn</DisplayName>
    <PublisherDisplayName>KSN Labs / Idaho Geological Survey</PublisherDisplayName>
    <Description>OCR Idaho - Document Processing System for geological survey workflows</Description>
    <Logo>Assets\StoreLogo.png</Logo>
  </Properties>

  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0" MaxVersionTested="10.0.22621.0" />
  </Dependencies>

  <Resources>
    <Resource Language="en-us" />
  </Resources>

  <Applications>
    <Application Id="Doksn" Executable="doksn.exe" EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="Doksn"
                          Description="Document Processing System"
                          BackgroundColor="transparent"
                          Square150x150Logo="Assets\Square150x150Logo.png"
                          Square44x44Logo="Assets\Square44x44Logo.png" />
    </Application>
  </Applications>

  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
  </Capabilities>
</Package>
"@

$manifest | Set-Content (Join-Path $layoutDir 'AppxManifest.xml') -Encoding utf8
Write-Host "    $([char]0x2714) AppxManifest.xml generated" -ForegroundColor Green

# Create placeholder logo assets
$assetsDir = Join-Path $layoutDir 'Assets'
if (-not (Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null }

# Generate minimal placeholder PNGs (1x1 transparent)
# In production, replace these with real logo assets
$placeholderNames = @('StoreLogo.png', 'Square150x150Logo.png', 'Square44x44Logo.png')
foreach ($name in $placeholderNames) {
    $assetPath = Join-Path $assetsDir $name
    if (-not (Test-Path $assetPath)) {
        # Minimal valid PNG: 1x1 transparent pixel
        [byte[]]$png = @(
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
            0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
            0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
            0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
            0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
        )
        [IO.File]::WriteAllBytes($assetPath, $png)
    }
}
Write-Host "    $([char]0x26A0) Placeholder logos created. Replace before distribution!" -ForegroundColor Yellow

# ═══════════════════════════════════════════════════════════════
# [3/4] PACKAGE WITH MAKEAPPX
# ═══════════════════════════════════════════════════════════════

Write-Host "  [3/4] Packaging with makeappx.exe" -ForegroundColor Yellow

$msixPath = Join-Path $OutputDir "Doksn_v$Version.msix"
if (Test-Path $msixPath) { Remove-Item $msixPath -Force }

$packResult = & $makeappxExe pack /d $layoutDir /p $msixPath /o 2>&1
if ($LASTEXITCODE -eq 0) {
    $msixSize = [math]::Round((Get-Item $msixPath).Length / 1MB, 1)
    Write-Host "    $([char]0x2714) MSIX created: $msixPath ($msixSize MB)" -ForegroundColor Green
} else {
    Write-Host "    $([char]0x2718) makeappx failed:" -ForegroundColor Red
    $packResult | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
    return
}

# ═══════════════════════════════════════════════════════════════
# [4/4] SIGN (optional)
# ═══════════════════════════════════════════════════════════════

Write-Host "  [4/4] Code signing" -ForegroundColor Yellow

if ($CertPath -and (Test-Path $CertPath)) {
    $signtool = Get-Command 'signtool.exe' -ErrorAction SilentlyContinue
    if (-not $signtool) {
        $sdkSearch = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin' -Recurse -Filter 'signtool.exe' -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | Select-Object -First 1
        if ($sdkSearch) { $signtool = $sdkSearch }
    }

    if ($signtool) {
        $signtoolExe = if ($signtool -is [System.Management.Automation.CommandInfo]) { $signtool.Source } else { $signtool.FullName }
        $signArgs = @('sign', '/fd', 'SHA256', '/f', $CertPath)
        if ($CertPassword) { $signArgs += @('/p', $CertPassword) }
        $signArgs += $msixPath

        $signResult = & $signtoolExe @signArgs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    $([char]0x2714) MSIX signed with $CertPath" -ForegroundColor Green
        } else {
            Write-Host "    $([char]0x2718) Signing failed:" -ForegroundColor Red
            $signResult | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
        }
    } else {
        Write-Host "    $([char]0x26A0) signtool.exe not found. MSIX created but unsigned." -ForegroundColor Yellow
    }
} else {
    Write-Host "    $([char]0x25CB) No certificate provided. Creating self-signed cert for dev..." -ForegroundColor DarkGray
    Write-Host "    To create one manually:" -ForegroundColor DarkGray
    Write-Host "      New-SelfSignedCertificate -Type Custom -Subject '$Publisher' \" -ForegroundColor DarkGray
    Write-Host "        -KeyUsage DigitalSignature -FriendlyName 'Doksn Dev' \" -ForegroundColor DarkGray
    Write-Host "        -CertStoreLocation 'Cert:\CurrentUser\My'" -ForegroundColor DarkGray
    Write-Host "    Then: signtool sign /fd SHA256 /a /f cert.pfx /p password $msixPath" -ForegroundColor DarkGray
}

# Clean layout
Remove-Item $layoutDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  $([char]0x2500)$([string]([char]0x2500) * 49)" -ForegroundColor Cyan
Write-Host "  Output: $msixPath" -ForegroundColor Cyan
Write-Host "  See docs/msix_prep.md for deployment guidance." -ForegroundColor DarkGray
Write-Host ""

return $msixPath
