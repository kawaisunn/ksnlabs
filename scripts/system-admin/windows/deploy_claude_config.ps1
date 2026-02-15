# deploy_claude_config.ps1
# Purpose: Deploy Claude Desktop orientation system (failsafe + auto-load)
# Author: KSN/IGS - AI-assisted development
# Date: 2026-02-14
# Usage: Run on BOTH home and work machines
# Engram-Tag: claude-desktop, configuration, collaboration-protocol

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('HOME','WORK')]
    [string]$Machine,
    
    [Parameter(Mandatory=$false)]
    [string]$DevRoot = "C:\dev"
)

Write-Host "=== Deploying Claude Desktop Configuration ===" -ForegroundColor Cyan
Write-Host "Machine: $Machine" -ForegroundColor Yellow
Write-Host "Target: $DevRoot" -ForegroundColor Gray
Write-Host ""

# Create directory structure
Write-Host "Creating directory structure..." -ForegroundColor Yellow

$directories = @(
    "$DevRoot\.claude",
    "$DevRoot\ksnlabs\engram\session-handovers",
    "$DevRoot\ksnlabs\engram\workflows",
    "$DevRoot\ksnlabs\engram\learnings",
    "$DevRoot\ksnlabs\engram\benchmarks"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ✓ Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  ✓ Exists: $dir" -ForegroundColor Gray
    }
}

# Deploy claude_start.json (failsafe config)
Write-Host ""
Write-Host "Deploying failsafe config..." -ForegroundColor Yellow

$jsonConfig = Get-Content "claude_start.json" -Raw | ConvertFrom-Json
$jsonConfig.runtime.machine = $Machine
$jsonConfig | ConvertTo-Json -Depth 10 | Out-File "$DevRoot\claude_start.json" -Encoding UTF8

Write-Host "  ✓ Deployed: $DevRoot\claude_start.json" -ForegroundColor Green
Write-Host "    Machine set to: $Machine" -ForegroundColor Cyan

# Deploy CLAUDE.md (auto-load)
Write-Host ""
Write-Host "Deploying auto-load file..." -ForegroundColor Yellow

Copy-Item "CLAUDE.md" "$DevRoot\.claude\CLAUDE.md" -Force
Write-Host "  ✓ Deployed: $DevRoot\.claude\CLAUDE.md" -ForegroundColor Green

# Deploy README (recovery guide)
Write-Host ""
Write-Host "Deploying recovery guide..." -ForegroundColor Yellow

Copy-Item "README_CLAUDE_START.md" "$DevRoot\README_CLAUDE_START.md" -Force
Write-Host "  ✓ Deployed: $DevRoot\README_CLAUDE_START.md" -ForegroundColor Green

# Create initial session handover
Write-Host ""
Write-Host "Creating initial session handover..." -ForegroundColor Yellow

$initialHandoff = @{
    "_meta" = @{
        "session_id" = "initial-setup-001"
        "created" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        "machine" = $Machine
        "purpose" = "Initial Claude Desktop configuration"
    }
    "status" = "Configuration deployed successfully"
    "next_steps" = @(
        "Open Claude Desktop",
        "Verify auto-load: Look for confirmation message",
        "If auto-load fails: Tell Claude 'Read C:\dev\claude_start.json'",
        "Begin work: No environment setup needed"
    )
}

$handoffPath = "$DevRoot\ksnlabs\engram\session-handovers\2026-02-14_initial-setup-$Machine.json"
$initialHandoff | ConvertTo-Json -Depth 10 | Out-File $handoffPath -Encoding UTF8

Write-Host "  ✓ Created: $handoffPath" -ForegroundColor Green

# Verify MCP configuration
Write-Host ""
Write-Host "Checking MCP configuration..." -ForegroundColor Yellow

$mcpConfigPath = "$env:APPDATA\Claude\claude_desktop_config.json"

if (Test-Path $mcpConfigPath) {
    $mcpConfig = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
    
    if ($mcpConfig.mcpServers.filesystem) {
        Write-Host "  ✓ MCP filesystem server configured" -ForegroundColor Green
        
        $allowedPaths = $mcpConfig.mcpServers.filesystem.args | Where-Object { $_ -like "*dev*" }
        if ($allowedPaths) {
            Write-Host "  ✓ C:\dev access enabled" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  C:\dev not in allowed paths" -ForegroundColor Yellow
            Write-Host "    Add 'C:\\dev' to MCP filesystem args in:" -ForegroundColor White
            Write-Host "    $mcpConfigPath" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ⚠️  MCP filesystem server not configured" -ForegroundColor Yellow
        Write-Host "    Configure MCP in Claude Desktop settings" -ForegroundColor White
    }
} else {
    Write-Host "  ⚠️  MCP config not found" -ForegroundColor Yellow
    Write-Host "    Expected at: $mcpConfigPath" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files deployed:" -ForegroundColor Green
Write-Host "  ✓ $DevRoot\claude_start.json (failsafe)" -ForegroundColor White
Write-Host "  ✓ $DevRoot\.claude\CLAUDE.md (auto-load)" -ForegroundColor White
Write-Host "  ✓ $DevRoot\README_CLAUDE_START.md (recovery guide)" -ForegroundColor White
Write-Host "  ✓ Initial session handover" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open Claude Desktop" -ForegroundColor White
Write-Host "  2. Start new chat" -ForegroundColor White
Write-Host "  3. Look for: 'Desktop session, C:\dev access enabled'" -ForegroundColor White
Write-Host "  4. If missing, say: 'Read C:\dev\claude_start.json'" -ForegroundColor White
Write-Host ""
Write-Host "Configuration ready for $Machine workstation!" -ForegroundColor Green
