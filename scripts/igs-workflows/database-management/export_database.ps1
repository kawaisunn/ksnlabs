# export_database.ps1
# Purpose: Export SQL Server database as .bacpac for sharing between instances
# Author: KSN/IGS - AI-assisted development
# Date: 2026-02-14
# Session: ownership-reclaim-001
# Dependencies: SQL Server, SqlPackage.exe
# Engram-Tag: database, sql-server, backup, data-export

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ServerInstance = "localhost\SQLEXPRESS",
    
    [Parameter(Mandatory=$false)]
    [string]$Database = "itdaggdb_dev",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\exports",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeData = $true
)

Write-Host "=== SQL Database Export ===" -ForegroundColor Cyan
Write-Host "Server: $ServerInstance" -ForegroundColor Gray
Write-Host "Database: $Database" -ForegroundColor Gray
Write-Host ""

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "✓ Created export directory: $OutputPath" -ForegroundColor Green
}

# Generate filename with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$exportFile = Join-Path $OutputPath "$Database`_$timestamp.bacpac"

# Find SqlPackage.exe
$sqlPackagePaths = @(
    "${env:ProgramFiles}\Microsoft SQL Server\160\DAC\bin\SqlPackage.exe",  # SQL Server 2022
    "${env:ProgramFiles}\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe",  # SQL Server 2019
    "${env:ProgramFiles}\Microsoft SQL Server\140\DAC\bin\SqlPackage.exe",  # SQL Server 2017
    "${env:ProgramFiles(x86)}\Microsoft SQL Server\160\DAC\bin\SqlPackage.exe",
    "${env:ProgramFiles(x86)}\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe",
    "${env:ProgramFiles(x86)}\Microsoft SQL Server\140\DAC\bin\SqlPackage.exe"
)

$sqlPackage = $null
foreach ($path in $sqlPackagePaths) {
    if (Test-Path $path) {
        $sqlPackage = $path
        break
    }
}

if (-not $sqlPackage) {
    Write-Host "ERROR: SqlPackage.exe not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "SqlPackage.exe is required for .bacpac export." -ForegroundColor Yellow
    Write-Host "Install options:" -ForegroundColor Yellow
    Write-Host "  1. Install SQL Server Data Tools (SSDT)" -ForegroundColor White
    Write-Host "  2. Install DacFramework: https://aka.ms/dacfx-msi" -ForegroundColor White
    Write-Host "  3. Use SSMS (SQL Server Management Studio) export wizard" -ForegroundColor White
    exit 1
}

Write-Host "✓ Found SqlPackage.exe: $sqlPackage" -ForegroundColor Green
Write-Host ""
Write-Host "Exporting database..." -ForegroundColor Yellow
Write-Host "This may take several minutes depending on database size..." -ForegroundColor Gray
Write-Host ""

# Build connection string
$connectionString = "Data Source=$ServerInstance;Initial Catalog=$Database;Integrated Security=True"

# Export database
try {
    $arguments = @(
        "/Action:Export",
        "/SourceConnectionString:`"$connectionString`"",
        "/TargetFile:`"$exportFile`"",
        "/p:VerifyExtraction=True"
    )
    
    $process = Start-Process -FilePath $sqlPackage -ArgumentList $arguments -Wait -NoNewWindow -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host ""
        Write-Host "=== Export Successful ===" -ForegroundColor Green
        Write-Host ""
        
        $fileInfo = Get-Item $exportFile
        $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        
        Write-Host "Export file: $exportFile" -ForegroundColor Cyan
        Write-Host "Size: $sizeMB MB" -ForegroundColor Gray
        Write-Host ""
        
        if ($sizeMB -gt 100) {
            Write-Host "⚠️  WARNING: File is larger than GitHub's 100MB limit!" -ForegroundColor Yellow
            Write-Host "Consider:" -ForegroundColor Yellow
            Write-Host "  - Using schema-only export (schema scripts)" -ForegroundColor White
            Write-Host "  - Git LFS for large files" -ForegroundColor White
            Write-Host "  - Shared network drive" -ForegroundColor White
            Write-Host "  - Tailscale + direct SQL connection" -ForegroundColor White
        } elseif ($sizeMB -gt 50) {
            Write-Host "⚠️  File is getting large for Git ($sizeMB MB)" -ForegroundColor Yellow
            Write-Host "Consider schema-only approach for frequent commits" -ForegroundColor Yellow
        } else {
            Write-Host "✓ File size OK for GitHub ($sizeMB MB)" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "To import on another instance:" -ForegroundColor Cyan
        Write-Host "  .\import_database.ps1 -BackupFile `"$exportFile`"" -ForegroundColor White
        Write-Host ""
        Write-Host "Or manually:" -ForegroundColor Cyan
        Write-Host "  1. Copy .bacpac file to other machine" -ForegroundColor White
        Write-Host "  2. Use SSMS: Right-click Databases → Import Data-tier Application" -ForegroundColor White
        Write-Host "  3. Select the .bacpac file" -ForegroundColor White
        
    } else {
        Write-Host "ERROR: Export failed with exit code $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "ERROR: Export failed: $_" -ForegroundColor Red
    exit 1
}
