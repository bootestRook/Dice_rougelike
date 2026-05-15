$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

$RemoteName = "origin"
$BranchName = "main"
$TargetRemoteUrl = "https://github.com/bootestRook/Dice_rougelike.git"
$RetrySeconds = 5

function Pause-And-Exit {
    param([int]$Code = 0)

    Write-Host ""
    Read-Host "Press Enter to exit"
    exit $Code
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

function Ensure-Origin {
    $originOutput = @(& git remote get-url $RemoteName 2>$null)
    if ($LASTEXITCODE -ne 0) {
        & git remote add $RemoteName $TargetRemoteUrl
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add remote: $TargetRemoteUrl"
        }
        Write-Host "Remote added: $TargetRemoteUrl"
        return
    }

    $originUrl = ($originOutput | Select-Object -First 1).Trim()
    if ($originUrl -ne $TargetRemoteUrl) {
        throw "origin does not match the target repo. Current: $originUrl Target: $TargetRemoteUrl"
    }
}

function Test-NeedsManualFix {
    $conflicts = @(& git diff --name-only --diff-filter=U)
    if ($conflicts.Count -gt 0) {
        Write-Host ""
        Write-Host "Pull created conflicts. Fix these files, then run the script again:"
        $conflicts | ForEach-Object { Write-Host "  $_" }
        return $true
    }

    $rebaseMergePath = (& git rev-parse --git-path rebase-merge).Trim()
    $rebaseApplyPath = (& git rev-parse --git-path rebase-apply).Trim()
    if ((Test-Path -LiteralPath $rebaseMergePath) -or (Test-Path -LiteralPath $rebaseApplyPath)) {
        Write-Host ""
        Write-Host "An unfinished rebase was detected. Resolve it, then run the script again."
        return $true
    }

    return $false
}

try {
    Test-GitCommand
    Test-GitRepository
    Ensure-Origin

    Write-Host "Repo folder: $PSScriptRoot"
    Write-Host "Remote repo: $TargetRemoteUrl"
    Write-Host "Pull branch: $RemoteName/$BranchName"
    Write-Host "Failed attempts retry every $RetrySeconds seconds. Press Ctrl+C to stop."
    Write-Host ""

    $attempt = 1
    while ($true) {
        Write-Host "Pull attempt $attempt..."
        & git pull --rebase --autostash $RemoteName $BranchName

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "Pull finished."
            & git status --short
            Pause-And-Exit 0
        }

        if (Test-NeedsManualFix) {
            Pause-And-Exit 1
        }

        Write-Host ""
        Write-Host "Pull failed. Retrying in $RetrySeconds seconds."
        Start-Sleep -Seconds $RetrySeconds
        $attempt += 1
    }
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)"
    Pause-And-Exit 1
}
