# import_database.ps1
# Purpose: Import SQL Server database from .bacpac file
# Author: KSN/IGS - AI-assisted development
# Date: 2026-02-14
# Session: ownership-reclaim-001
# Dependencies: SQL Server, SqlPackage.exe
# Engram-Tag: database, sql-server, restore, data-import

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    
    [Parameter(Mandatory=$false)]
    [string]$ServerInstance = "localhost\SQLEXPRESS",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetDatabase = $null  # Auto-detect from filename if not provided
)

Write-Host "=== SQL Database Import ===" -ForegroundColor Cyan

# Validate backup file exists
if (-not (Test-Path $BackupFile)) {
    Write-Host "ERROR: Backup file not found: $BackupFile" -ForegroundColor Red
    exit 1
}

$fileInfo = Get-Item $BackupFile
$sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

# Auto-detect database name from filename if not provided
if (-not $TargetDatabase) {
    $TargetDatabase = [System.IO.Path]::GetFileNameWithoutExtension($BackupFile) -replace '_\d{4}-\d{2}-\d{2}.*$', ''
    Write-Host "Auto-detected database name: $TargetDatabase" -ForegroundColor Yellow
}

Write-Host "Server: $ServerInstance" -ForegroundColor Gray
Write-Host "Target Database: $TargetDatabase" -ForegroundColor Gray
Write-Host "Backup File: $BackupFile ($sizeMB MB)" -ForegroundColor Gray
Write-Host ""

# Confirm before proceeding
$confirmation = Read-Host "This will create/overwrite database '$TargetDatabase'. Continue? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Import cancelled." -ForegroundColor Yellow
    exit 0
}

# Find SqlPackage.exe
$sqlPackagePaths = @(
    "${env:ProgramFiles}\Microsoft SQL Server\160\DAC\bin\SqlPackage.exe",
    "${env:ProgramFiles}\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe",
    "${env:ProgramFiles}\Microsoft SQL Server\140\DAC\bin\SqlPackage.exe",
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
    Write-Host "Install SQL Server Data Tools or DacFramework" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Found SqlPackage.exe" -ForegroundColor Green
Write-Host ""
Write-Host "Importing database..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Gray
Write-Host ""

# Build connection string
$connectionString = "Data Source=$ServerInstance;Initial Catalog=$TargetDatabase;Integrated Security=True"

# Import database
try {
    $arguments = @(
        "/Action:Import",
        "/SourceFile:`"$BackupFile`"",
        "/TargetConnectionString:`"$connectionString`"",
        "/p:DatabaseEdition=Default",
        "/p:DatabaseServiceObjective=Default"
    )
    
    $process = Start-Process -FilePath $sqlPackage -ArgumentList $arguments -Wait -NoNewWindow -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host ""
        Write-Host "=== Import Successful ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "Database '$TargetDatabase' ready on $ServerInstance" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Connect with:" -ForegroundColor Yellow
        Write-Host "  Server: $ServerInstance" -ForegroundColor White
        Write-Host "  Database: $TargetDatabase" -ForegroundColor White
        
    } else {
        Write-Host "ERROR: Import failed with exit code $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "ERROR: Import failed: $_" -ForegroundColor Red
    exit 1
}
