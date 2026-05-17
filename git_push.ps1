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

function Invoke-Git {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $output = @(& git @Arguments 2>&1 | ForEach-Object { $_.ToString() })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $output
    }
}

function Test-GitRepository {
    $result = Invoke-Git rev-parse --is-inside-work-tree
    if ($result.ExitCode -ne 0) {
        throw "This folder is not a Git repository: $PSScriptRoot"
    }
}

function Ensure-Origin {
    $originResult = Invoke-Git remote get-url $RemoteName
    if ($originResult.ExitCode -ne 0) {
        $addResult = Invoke-Git remote add $RemoteName $TargetRemoteUrl
        if ($addResult.ExitCode -ne 0) {
            throw "Failed to add remote: $TargetRemoteUrl"
        }
        Write-Host "Remote added: $TargetRemoteUrl"
        return
    }

    $originUrl = ($originResult.Output | Select-Object -First 1).Trim()
    if ($originUrl -ne $TargetRemoteUrl) {
        throw "origin does not match the target repo. Current: $originUrl Target: $TargetRemoteUrl"
    }
}

function Test-NeedsPullFirst {
    param([string]$GitOutput)

    return $GitOutput -match "non-fast-forward|fetch first|Updates were rejected|remote contains work that you do not have locally"
}

function Invoke-PullBeforePush {
    Write-Host ""
    Write-Host "Remote has commits that are not local. Trying pull before the next push..."
    $pullResult = Invoke-Git pull --rebase --autostash $RemoteName $BranchName
    $pullResult.Output | ForEach-Object { Write-Host $_ }

    if ($pullResult.ExitCode -ne 0) {
        Write-Host ""
        Write-Host "Pull before push did not finish. Resolve any conflicts if needed; this script will keep retrying."
    }
}

try {
    Test-GitCommand
    Test-GitRepository
    Ensure-Origin

    Write-Host "Repo folder: $PSScriptRoot"
    Write-Host "Remote repo: $TargetRemoteUrl"
    Write-Host "Push branch: $BranchName -> $RemoteName/$BranchName"

    $statusResult = Invoke-Git status --short
    $status = $statusResult.Output
    if ($status.Count -gt 0) {
        Write-Host ""
        Write-Host "There are uncommitted files. This script only pushes committed changes:"
        $status | ForEach-Object { Write-Host $_ }
    }

    Write-Host ""
    Write-Host "Failed attempts retry every $RetrySeconds seconds. Press Ctrl+C to stop."
    Write-Host ""

    $attempt = 1
    while ($true) {
        Write-Host "Push attempt $attempt..."
        $pushResult = Invoke-Git push -u $RemoteName $BranchName
        $output = $pushResult.Output
        $exitCode = $pushResult.ExitCode
        $output | ForEach-Object { Write-Host $_ }

        if ($exitCode -eq 0) {
            Write-Host ""
            Write-Host "Push finished."
            Pause-And-Exit 0
        }

        $outputText = $output | Out-String
        if (Test-NeedsPullFirst $outputText) {
            Invoke-PullBeforePush
        }

        Write-Host ""
        Write-Host "Push failed. Retrying in $RetrySeconds seconds."
        Start-Sleep -Seconds $RetrySeconds
        $attempt += 1
    }
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)"
    Pause-And-Exit 1
}
