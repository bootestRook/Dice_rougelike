$ErrorActionPreference = "Stop"

$printPath = $false
$persistUserEnv = $false
$godotArgs = New-Object System.Collections.Generic.List[string]

foreach ($arg in $args) {
    if ($arg -eq "-PrintPath" -or $arg -eq "--print-path") {
        $printPath = $true
        continue
    }
    if ($arg -eq "-PersistUserEnv" -or $arg -eq "--persist-user-env") {
        $persistUserEnv = $true
        continue
    }
    $godotArgs.Add($arg)
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$candidates = New-Object System.Collections.Generic.List[object]
$seen = @{}

function Add-Candidate {
    param(
        [string] $Path,
        [string] $Source
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    $expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim())
    if (-not [System.IO.Path]::IsPathRooted($expanded)) {
        $expanded = Join-Path $repoRoot $expanded
    }

    if (-not (Test-Path -LiteralPath $expanded -PathType Leaf)) {
        return
    }

    $resolved = (Resolve-Path -LiteralPath $expanded).Path
    if ($seen.ContainsKey($resolved)) {
        return
    }

    $seen[$resolved] = $true
    $candidates.Add([pscustomobject]@{
        Path = $resolved
        Source = $Source
    })
}

function Add-ExeCandidatesFromRoot {
    param(
        [string] $Root,
        [string] $Source
    )

    if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root -PathType Container)) {
        return
    }

    $files = Get-ChildItem -LiteralPath $Root -Recurse -Filter "Godot*.exe" -ErrorAction SilentlyContinue |
        Sort-Object `
            @{ Expression = { if ($_.Name -like "*console.exe") { 0 } else { 1 } }; Ascending = $true },
            @{ Expression = { $_.LastWriteTimeUtc }; Descending = $true }

    foreach ($file in $files) {
        Add-Candidate $file.FullName $Source
    }
}

function Save-TempGodotToStableCache {
    param([string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        return $Path
    }

    $tempRoot = [System.IO.Path]::GetTempPath().TrimEnd('\')
    if (-not $Path.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Path
    }

    $sourceDir = Split-Path -Parent $Path
    $leaf = Split-Path -Leaf $sourceDir
    if ($leaf -notlike "codex-godot-*") {
        return $Path
    }

    $targetDir = Join-Path $env:LOCALAPPDATA (Join-Path "CodexGodot" $leaf)
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

    foreach ($file in Get-ChildItem -LiteralPath $sourceDir -File -Filter "Godot*.exe" -ErrorAction SilentlyContinue) {
        $target = Join-Path $targetDir $file.Name
        if (-not (Test-Path -LiteralPath $target -PathType Leaf) -or ((Get-Item -LiteralPath $target).Length -ne $file.Length)) {
            Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        }
    }

    $cachedConsole = Get-ChildItem -LiteralPath $targetDir -File -Filter "*console.exe" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1

    if ($null -ne $cachedConsole) {
        return $cachedConsole.FullName
    }

    $cachedSameName = Join-Path $targetDir (Split-Path -Leaf $Path)
    if (Test-Path -LiteralPath $cachedSameName -PathType Leaf) {
        return (Resolve-Path -LiteralPath $cachedSameName).Path
    }

    return $Path
}

$overrideFile = Join-Path $repoRoot ".godot-bin"
if (Test-Path -LiteralPath $overrideFile -PathType Leaf) {
    foreach ($line in Get-Content -LiteralPath $overrideFile) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -gt 0 -and -not $trimmed.StartsWith("#")) {
            Add-Candidate $trimmed ".godot-bin"
        }
    }
}

Add-Candidate $env:GODOT_BIN "process GODOT_BIN"
Add-Candidate ([Environment]::GetEnvironmentVariable("GODOT_BIN", "User")) "user GODOT_BIN"
Add-Candidate ([Environment]::GetEnvironmentVariable("GODOT_BIN", "Machine")) "machine GODOT_BIN"

foreach ($commandName in @("godot", "godot4")) {
    $command = Get-Command $commandName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $command) {
        Add-Candidate $command.Source "PATH:$commandName"
    }
}

if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    Add-ExeCandidatesFromRoot (Join-Path $env:LOCALAPPDATA "CodexGodot") "LOCALAPPDATA CodexGodot cache"
}

if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
    Add-ExeCandidatesFromRoot (Join-Path $env:ProgramFiles "Godot") "Program Files Godot"
}

$programFilesX86 = ${env:ProgramFiles(x86)}
if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
    Add-ExeCandidatesFromRoot (Join-Path $programFilesX86 "Godot") "Program Files (x86) Godot"
}

$tempRoot = [System.IO.Path]::GetTempPath()
if (Test-Path -LiteralPath $tempRoot -PathType Container) {
    $tempDirs = Get-ChildItem -LiteralPath $tempRoot -Directory -Filter "codex-godot-*" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending
    foreach ($tempDir in $tempDirs) {
        Add-ExeCandidatesFromRoot $tempDir.FullName "Codex temp Godot cache"
    }
}

if ($candidates.Count -eq 0) {
    Write-Error "Godot executable not found. Install Godot, set GODOT_BIN, or create a .godot-bin file containing the executable path."
    exit 1
}

$godotBin = Save-TempGodotToStableCache $candidates[0].Path
$env:GODOT_BIN = $godotBin

if ($persistUserEnv) {
    [Environment]::SetEnvironmentVariable("GODOT_BIN", $godotBin, "User")
    Write-Output "Set user GODOT_BIN=$godotBin"
}

if ($printPath) {
    Write-Output $godotBin
}

if ($godotArgs.Count -eq 0) {
    exit 0
}

& $godotBin @godotArgs
exit $LASTEXITCODE
