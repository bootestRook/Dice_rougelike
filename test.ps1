param(
    [int]$Runs = 30,
    [int]$Port = 24886,
    [string]$GodotBin = "",
    [string]$PythonBin = "",
    [string]$ReportDir = "",
    [string]$StateFile = "",
    [int]$MaxSteps = 900,
    [string]$Seed = "",
    [double]$MutationScale = 0.16,
    [switch]$Headless,
    [switch]$KeepOpen
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

$ToolPath = Join-Path $ProjectRoot "tools\automation\evolving_bridge_playtester.py"
if (-not (Test-Path -LiteralPath $ToolPath)) {
    throw "Missing playtester: $ToolPath"
}

function Resolve-PythonBin {
    param([string]$Requested)

    if ($Requested -ne "") {
        if (-not (Test-Path -LiteralPath $Requested)) {
            throw "PythonBin not found: $Requested"
        }
        return $Requested
    }

    $bundledPython = "C:\Users\Arche\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    if (Test-Path -LiteralPath $bundledPython) {
        return $bundledPython
    }

    $command = Get-Command python -ErrorAction SilentlyContinue
    if ($null -ne $command -and $command.Source -notlike "*WindowsApps*") {
        return $command.Source
    }

    throw "Python not found. Pass -PythonBin <path>."
}

function Resolve-GodotBin {
    param([string]$Requested, [bool]$PreferHeadless)

    if ($Requested -ne "") {
        if (-not (Test-Path -LiteralPath $Requested)) {
            throw "GodotBin not found: $Requested"
        }
        return $Requested
    }

    if ($env:GODOT_BIN -and (Test-Path -LiteralPath $env:GODOT_BIN)) {
        return $env:GODOT_BIN
    }

    $tempRoot = Join-Path $env:TEMP "codex_godot_4_6_2"
    $guiGodot = Join-Path $tempRoot "Godot_v4.6.2-stable_win64.exe"
    $consoleGodot = Join-Path $tempRoot "Godot_v4.6.2-stable_win64_console.exe"

    if ($PreferHeadless -and (Test-Path -LiteralPath $consoleGodot)) {
        return $consoleGodot
    }
    if (Test-Path -LiteralPath $guiGodot) {
        return $guiGodot
    }
    if (Test-Path -LiteralPath $consoleGodot) {
        return $consoleGodot
    }

    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    throw "Godot not found. Pass -GodotBin <path> or set GODOT_BIN."
}

$ResolvedPython = Resolve-PythonBin -Requested $PythonBin
$ResolvedGodot = Resolve-GodotBin -Requested $GodotBin -PreferHeadless ([bool]$Headless)

$Arguments = @(
    $ToolPath,
    "--runs", "$Runs",
    "--port", "$Port",
    "--godot-bin", $ResolvedGodot,
    "--project", $ProjectRoot,
    "--max-steps", "$MaxSteps",
    "--mutation-scale", "$MutationScale"
)

if ($Seed -ne "") {
    $Arguments += @("--seed", $Seed)
}
if ($ReportDir -ne "") {
    $Arguments += @("--report-dir", $ReportDir)
}
if ($StateFile -ne "") {
    $Arguments += @("--state-file", $StateFile)
}
if ($Headless) {
    $Arguments += "--headless"
}
if ($KeepOpen) {
    $Arguments += "--keep-open"
}

Write-Host "Project: $ProjectRoot"
Write-Host "Python : $ResolvedPython"
Write-Host "Godot  : $ResolvedGodot"
Write-Host "Runs   : $Runs"
Write-Host ""

& $ResolvedPython @Arguments
exit $LASTEXITCODE
