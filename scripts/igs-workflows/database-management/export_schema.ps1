# export_schema.ps1
# Purpose: Export SQL Server database schema to version-controlled SQL files
# Author: KSN/IGS - AI-assisted development
# Date: 2026-02-14
# Session: ownership-reclaim-001
# Dependencies: SQL Server, SqlServer PowerShell module
# Engram-Tag: database, sql-server, schema-management, version-control

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ServerInstance = "localhost\SQLEXPRESS",
    
    [Parameter(Mandatory=$false)]
    [string]$Database = "itdaggdb_dev",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\schema"
)

# Import SQL Server module
try {
    Import-Module SqlServer -ErrorAction Stop
} catch {
    Write-Host "ERROR: SqlServer module not found. Installing..." -ForegroundColor Red
    Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber
    Import-Module SqlServer
}

Write-Host "=== SQL Schema Export ===" -ForegroundColor Cyan
Write-Host "Server: $ServerInstance" -ForegroundColor Gray
Write-Host "Database: $Database" -ForegroundColor Gray
Write-Host "Output: $OutputPath" -ForegroundColor Gray
Write-Host ""

# Create output directories
$directories = @(
    "$OutputPath\tables",
    "$OutputPath\views",
    "$OutputPath\procedures",
    "$OutputPath\functions",
    "$OutputPath\indexes",
    "$OutputPath\triggers"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Connect to database
try {
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($ServerInstance)
    $db = $server.Databases[$Database]
    
    if (-not $db) {
        Write-Host "ERROR: Database '$Database' not found on $ServerInstance" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Connected to database" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: Could not connect to SQL Server: $_" -ForegroundColor Red
    exit 1
}

# Script options
$options = New-Object Microsoft.SqlServer.Management.Smo.ScriptingOptions
$options.ScriptDrops = $false
$options.IncludeIfNotExists = $true
$options.ScriptSchema = $true
$options.ScriptData = $false
$options.Indexes = $true
$options.DriAll = $true  # Declarative Referential Integrity (FK, PK, etc.)

Write-Host ""
Write-Host "Exporting schema objects..." -ForegroundColor Yellow

# Export Tables
Write-Host "  - Tables..." -ForegroundColor Gray
foreach ($table in $db.Tables | Where-Object {-not $_.IsSystemObject}) {
    $fileName = "$OutputPath\tables\$($table.Schema).$($table.Name).sql"
    $table.Script($options) | Out-File -FilePath $fileName -Encoding UTF8
    Write-Host "    ✓ $($table.Schema).$($table.Name)" -ForegroundColor Green
}

# Export Views
Write-Host "  - Views..." -ForegroundColor Gray
foreach ($view in $db.Views | Where-Object {-not $_.IsSystemObject}) {
    $fileName = "$OutputPath\views\$($view.Schema).$($view.Name).sql"
    $view.Script($options) | Out-File -FilePath $fileName -Encoding UTF8
    Write-Host "    ✓ $($view.Schema).$($view.Name)" -ForegroundColor Green
}

# Export Stored Procedures
Write-Host "  - Stored Procedures..." -ForegroundColor Gray
foreach ($proc in $db.StoredProcedures | Where-Object {-not $_.IsSystemObject}) {
    $fileName = "$OutputPath\procedures\$($proc.Schema).$($proc.Name).sql"
    $proc.Script($options) | Out-File -FilePath $fileName -Encoding UTF8
    Write-Host "    ✓ $($proc.Schema).$($proc.Name)" -ForegroundColor Green
}

# Export Functions
Write-Host "  - Functions..." -ForegroundColor Gray
foreach ($func in $db.UserDefinedFunctions | Where-Object {-not $_.IsSystemObject}) {
    $fileName = "$OutputPath\functions\$($func.Schema).$($func.Name).sql"
    $func.Script($options) | Out-File -FilePath $fileName -Encoding UTF8
    Write-Host "    ✓ $($func.Schema).$($func.Name)" -ForegroundColor Green
}

# Export Triggers
Write-Host "  - Triggers..." -ForegroundColor Gray
foreach ($trigger in $db.Triggers) {
    $fileName = "$OutputPath\triggers\$($trigger.Name).sql"
    $trigger.Script($options) | Out-File -FilePath $fileName -Encoding UTF8
    Write-Host "    ✓ $($trigger.Name)" -ForegroundColor Green
}

# Create master script to apply all in correct order
$masterScript = @"
-- Master Schema Application Script
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Database: $Database
-- Server: $ServerInstance

USE [$Database]
GO

PRINT 'Applying schema from version control...'
GO

-- Tables (will be created in dependency order)
$(Get-ChildItem "$OutputPath\tables\*.sql" | ForEach-Object {":r `"$(Resolve-Path $_.FullName)`"`n"})

-- Views
$(Get-ChildItem "$OutputPath\views\*.sql" -ErrorAction SilentlyContinue | ForEach-Object {":r `"$(Resolve-Path $_.FullName)`"`n"})

-- Functions
$(Get-ChildItem "$OutputPath\functions\*.sql" -ErrorAction SilentlyContinue | ForEach-Object {":r `"$(Resolve-Path $_.FullName)`"`n"})

-- Stored Procedures
$(Get-ChildItem "$OutputPath\procedures\*.sql" -ErrorAction SilentlyContinue | ForEach-Object {":r `"$(Resolve-Path $_.FullName)`"`n"})

-- Triggers
$(Get-ChildItem "$OutputPath\triggers\*.sql" -ErrorAction SilentlyContinue | ForEach-Object {":r `"$(Resolve-Path $_.FullName)`"`n"})

PRINT 'Schema application complete!'
GO
"@

$masterScript | Out-File -FilePath "$OutputPath\apply_schema.sql" -Encoding UTF8

Write-Host ""
Write-Host "=== Export Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Schema exported to: $OutputPath" -ForegroundColor Green
Write-Host "Master script: $OutputPath\apply_schema.sql" -ForegroundColor Green
Write-Host ""
Write-Host "To apply schema on another instance:" -ForegroundColor Yellow
Write-Host "  sqlcmd -S <server> -d <database> -i `"$OutputPath\apply_schema.sql`"" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  git add schema/" -ForegroundColor White
Write-Host "  git commit -m 'Updated database schema'" -ForegroundColor White
Write-Host "  git push" -ForegroundColor White
