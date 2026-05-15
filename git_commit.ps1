$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

function Pause-And-Exit {
    param([int]$Code = 0)

    Write-Host ""
    Read-Host "Press Enter to exit"
    exit $Code
}

function Invoke-Git {
    param([string[]]$GitArgs)

    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Test-GitCommand {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git was not found. Install Git and make sure the git command is available."
    }
}

function Test-GitRepository {
    & git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "This folder is not a Git repository: $PSScriptRoot"
    }
}

function Get-BlockedStagedFiles {
    $blockedPatterns = @(
        '^\.godot/',
        '^\.import/',
        '^node_modules/',
        '^build/',
        '^dist/',
        '^exports/',
        '^ai_outputs/',
        '^ai_temp/',
        '^references_temp/',
        '^screenshots/',
        '^recordings/',
        '\.(exe|apk|aab|app|dmg|zip|7z|rar)$'
    )

    $stagedFiles = @(& git diff --cached --name-only)
    $blockedFiles = @()

    foreach ($file in $stagedFiles) {
        foreach ($pattern in $blockedPatterns) {
            if ($file -match $pattern) {
                $blockedFiles += $file
                break
            }
        }
    }

    return $blockedFiles | Sort-Object -Unique
}

try {
    Test-GitCommand
    Test-GitRepository

    Write-Host "Repo folder: $PSScriptRoot"
    Write-Host ""

    $status = @(& git status --short --untracked-files=all)
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to read Git status."
    }

    if ($status.Count -eq 0) {
        Write-Host "No non-ignored changes to commit."
        Pause-And-Exit 0
    }

    Write-Host "Current non-ignored changes:"
    $status | ForEach-Object { Write-Host $_ }
    Write-Host ""

    $confirm = Read-Host "Commit all non-ignored changes listed above? Type y then Enter"
    if ($confirm -notin @("y", "Y", "yes", "YES")) {
        Write-Host "Commit cancelled."
        Pause-And-Exit 0
    }

    $message = Read-Host "Commit message; leave blank for default"
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = "chore: update project files"
    }

    Invoke-Git @("add", "-A", "--", ".")

    $blockedFiles = @(Get-BlockedStagedFiles)
    if ($blockedFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Blocked files were staged and will be unstaged:"
        foreach ($file in $blockedFiles) {
            & git restore --staged -- $file
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to unstage blocked file: $file"
            }
            Write-Host "  $file"
        }
    }

    $stagedFiles = @(& git diff --cached --name-only)
    if ($stagedFiles.Count -eq 0) {
        Write-Host ""
        Write-Host "No files are staged for commit."
        Pause-And-Exit 0
    }

    Write-Host ""
    Write-Host "Files to commit:"
    $stagedFiles | ForEach-Object { Write-Host "  $_" }
    Write-Host ""

    Invoke-Git @("commit", "-m", $message)

    Write-Host ""
    Write-Host "Commit finished."
    Invoke-Git @("log", "-1", "--oneline")
    Pause-And-Exit 0
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)"
    Pause-And-Exit 1
}
