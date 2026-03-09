#Requires -Version 7.0
<#
.SYNOPSIS
    Git hygiene check for all KSN repositories.
.DESCRIPTION
    Verifies sync status, working tree cleanliness, merge state, stash,
    and object integrity across ocritd, ktreesn, and ksnlabs repos.
    Run at SESSION START and SESSION END. No exceptions.
.PARAMETER Fix
    Attempt auto-fix: pull behind repos, delete stale merge artifacts.
.PARAMETER Quick
    Skip git fsck (faster, still checks sync and cleanliness).
.EXAMPLE
    .\Verify-GitState.ps1
.EXAMPLE
    .\Verify-GitState.ps1 -Fix
.NOTES
    Author  : KSN / IGS-AI Collaboration
    Created : 2026-03-09
    Policy  : All outstanding git actions resolved when created,
              verified every session until zero hangups.
#>
[CmdletBinding()]
param(
    [switch] $Fix,
    [switch] $Quick
)

$repos = @(
    @{ Name = 'ocritd';  Path = 'C:\dev\ocritd';  Remote = 'origin'; Branch = 'main' }
    @{ Name = 'ktreesn'; Path = 'C:\dev\Ktreesn';  Remote = 'origin'; Branch = 'main' }
    @{ Name = 'ksnlabs'; Path = 'C:\dev\ksnlabs';  Remote = 'origin'; Branch = 'main' }
)

$totalIssues = 0
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  GIT HYGIENE CHECK - $timestamp" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

foreach ($repo in $repos) {
    $name = $repo.Name
    $path = $repo.Path
    $issues = [System.Collections.Generic.List[string]]::new()
    $fixes  = [System.Collections.Generic.List[string]]::new()

    Write-Host "--- $name ($path) ---" -ForegroundColor Yellow

    if (-not (Test-Path $path)) {
        Write-Host "  MISSING: repo directory not found!" -ForegroundColor Red
        $totalIssues++
        continue
    }

    Push-Location $path
    try {
        # 1. Fetch latest
        git fetch $repo.Remote --quiet 2>$null

        # 2. Working tree
        $dirty = @(git status --porcelain 2>$null)
        if ($dirty.Count -gt 0) {
            $issues.Add("DIRTY: $($dirty.Count) uncommitted changes")
            Write-Host "  [FAIL] Working tree dirty ($($dirty.Count) changes)" -ForegroundColor Red
        } else {
            Write-Host "  [OK]   Working tree clean" -ForegroundColor Green
        }

        # 3. Sync status
        $behind = @(git log --oneline "HEAD..$($repo.Remote)/$($repo.Branch)" 2>$null)
        $ahead  = @(git log --oneline "$($repo.Remote)/$($repo.Branch)..HEAD" 2>$null)
        if ($behind.Count -gt 0) {
            $issues.Add("BEHIND: $($behind.Count) commits behind remote")
            Write-Host "  [FAIL] $($behind.Count) commits behind remote" -ForegroundColor Red
            if ($Fix -and $dirty.Count -eq 0) {
                Write-Host "  [FIX]  Pulling..." -ForegroundColor Magenta
                git pull $repo.Remote $repo.Branch --ff-only 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $fixes.Add("Pulled $($behind.Count) commits")
                    Write-Host "  [DONE] Pull succeeded" -ForegroundColor Green
                } else {
                    Write-Host "  [FAIL] Pull failed - manual intervention needed" -ForegroundColor Red
                }
            }
        } elseif ($ahead.Count -gt 0) {
            $issues.Add("AHEAD: $($ahead.Count) unpushed commits")
            Write-Host "  [WARN] $($ahead.Count) unpushed commits" -ForegroundColor DarkYellow
            if ($Fix) {
                Write-Host "  [FIX]  Pushing..." -ForegroundColor Magenta
                git push $repo.Remote $repo.Branch 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $fixes.Add("Pushed $($ahead.Count) commits")
                    Write-Host "  [DONE] Push succeeded" -ForegroundColor Green
                } else {
                    Write-Host "  [FAIL] Push failed - manual intervention needed" -ForegroundColor Red
                }
            }
        } else {
            $sha = (git rev-parse --short HEAD 2>$null)
            Write-Host "  [OK]   Synced at $sha" -ForegroundColor Green
        }

        # 4. Stale merge/rebase state
        $staleFiles = @('MERGE_HEAD','AUTO_MERGE','REBASE_HEAD') |
            Where-Object { Test-Path ".git\$_" }
        $rebaseDir = Test-Path '.git\rebase-merge'
        if ($staleFiles.Count -gt 0 -or $rebaseDir) {
            $artifacts = ($staleFiles + $(if ($rebaseDir) {'rebase-merge/'})) -join ', '
            $issues.Add("STALE: $artifacts")
            Write-Host "  [FAIL] Stale merge artifacts: $artifacts" -ForegroundColor Red
            if ($Fix) {
                foreach ($f in $staleFiles) {
                    Remove-Item ".git\$f" -Force -ErrorAction SilentlyContinue
                    $fixes.Add("Deleted .git\$f")
                }
                Write-Host "  [DONE] Removed stale artifacts" -ForegroundColor Green
            }
        } else {
            Write-Host "  [OK]   No stale merge state" -ForegroundColor Green
        }

        # 5. Stash
        $stashes = @(git stash list 2>$null)
        if ($stashes.Count -gt 0) {
            $issues.Add("STASH: $($stashes.Count) stashed entries")
            Write-Host "  [WARN] $($stashes.Count) stash entries" -ForegroundColor DarkYellow
        } else {
            Write-Host "  [OK]   No stashes" -ForegroundColor Green
        }

        # 6. Object integrity (skip with -Quick)
        if (-not $Quick) {
            $fsck = git fsck --full 2>&1
            $errors = @($fsck | Where-Object { $_ -notmatch '^dangling' })
            if ($errors.Count -gt 0) {
                $issues.Add("CORRUPT: git fsck reported errors")
                Write-Host "  [FAIL] Object store errors detected!" -ForegroundColor Red
                $errors | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
            } else {
                Write-Host "  [OK]   Object store intact" -ForegroundColor Green
            }
        }

        $totalIssues += $issues.Count
        if ($fixes.Count -gt 0) {
            Write-Host "  Applied $($fixes.Count) fix(es): $($fixes -join '; ')" -ForegroundColor Magenta
        }
        Write-Host ""
    }
    finally {
        Pop-Location
    }
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
if ($totalIssues -eq 0) {
    Write-Host "  ALL REPOS CLEAN - $timestamp" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
} else {
    Write-Host "  $totalIssues ISSUE(S) FOUND - $timestamp" -ForegroundColor Red
    if (-not $Fix) {
        Write-Host "  Run with -Fix to auto-resolve" -ForegroundColor DarkYellow
    }
    Write-Host "========================================`n" -ForegroundColor Cyan
}

exit $totalIssues
