@echo off
setlocal EnableExtensions EnableDelayedExpansion

pushd "%~dp0" >nul

set "REMOTE_NAME=origin"
set "BRANCH_NAME=main"
set "TARGET_REMOTE_URL=https://github.com/bootestRook/Dice_rougelike.git"
set "RETRY_SECONDS=5"

where git >nul 2>nul
if errorlevel 1 (
    echo ERROR: Git was not found. Install Git and make sure the git command is available.
    call :PauseAndExit 1
    exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo ERROR: This folder is not a Git repository: %CD%
    call :PauseAndExit 1
    exit /b 1
)

call :EnsureOrigin
if errorlevel 1 (
    call :PauseAndExit 1
    exit /b 1
)

echo Repo folder: %CD%
echo Remote repo: %TARGET_REMOTE_URL%
echo Pull branch: %REMOTE_NAME%/%BRANCH_NAME%
echo Failed attempts retry every %RETRY_SECONDS% seconds. Press Ctrl+C to stop.
echo.

set /a ATTEMPT=1

:PullLoop
echo Pull attempt !ATTEMPT!...
git pull --rebase --autostash "%REMOTE_NAME%" "%BRANCH_NAME%"
if not errorlevel 1 (
    echo.
    echo Pull finished.
    git status --short
    call :PauseAndExit 0
    exit /b 0
)

call :PrintManualFixIfNeeded

echo.
echo Pull failed. Retrying in %RETRY_SECONDS% seconds.
timeout /t %RETRY_SECONDS% /nobreak >nul
set /a ATTEMPT+=1
goto :PullLoop

:EnsureOrigin
set "ORIGIN_URL="
for /f "delims=" %%A in ('git remote get-url "%REMOTE_NAME%" 2^>nul') do (
    if not defined ORIGIN_URL set "ORIGIN_URL=%%A"
)

if not defined ORIGIN_URL (
    git remote add "%REMOTE_NAME%" "%TARGET_REMOTE_URL%"
    if errorlevel 1 (
        echo ERROR: Failed to add remote: %TARGET_REMOTE_URL%
        exit /b 1
    )
    echo Remote added: %TARGET_REMOTE_URL%
    exit /b 0
)

if /I not "%ORIGIN_URL%"=="%TARGET_REMOTE_URL%" (
    echo ERROR: origin does not match the target repo.
    echo Current: %ORIGIN_URL%
    echo Target:  %TARGET_REMOTE_URL%
    exit /b 1
)

exit /b 0

:PrintManualFixIfNeeded
set "HAS_CONFLICT="
for /f "delims=" %%F in ('git diff --name-only --diff-filter=U') do (
    if not defined HAS_CONFLICT (
        echo.
        echo Pull created conflicts. Fix these files, then run the script again:
        set "HAS_CONFLICT=1"
    )
    echo   %%F
)

set "REBASE_MERGE="
set "REBASE_APPLY="
for /f "delims=" %%P in ('git rev-parse --git-path rebase-merge') do set "REBASE_MERGE=%%P"
for /f "delims=" %%P in ('git rev-parse --git-path rebase-apply') do set "REBASE_APPLY=%%P"

if defined REBASE_MERGE if exist "!REBASE_MERGE!" (
    echo.
    echo An unfinished rebase was detected. Resolve it, then run the script again.
)

if defined REBASE_APPLY if exist "!REBASE_APPLY!" (
    echo.
    echo An unfinished rebase was detected. Resolve it, then run the script again.
)

exit /b 0

:PauseAndExit
set "EXIT_CODE=%~1"
echo.
if /I not "%NO_PAUSE%"=="1" pause
popd >nul
exit /b %EXIT_CODE%
