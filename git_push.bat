@echo off
setlocal EnableExtensions EnableDelayedExpansion

pushd "%~dp0" >nul

set "REMOTE_NAME=origin"
set "BRANCH_NAME=main"
set "TARGET_REMOTE_URL=https://github.com/bootestRook/Dice_rougelike.git"
set "RETRY_SECONDS=5"
set "OUTPUT_FILE=%TEMP%\dice_rougelike_git_push_%RANDOM%%RANDOM%.txt"
set "STATUS_FILE=%TEMP%\dice_rougelike_git_push_status_%RANDOM%%RANDOM%.txt"

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
echo Push branch: %BRANCH_NAME% -^> %REMOTE_NAME%/%BRANCH_NAME%

git status --short > "%STATUS_FILE%"
if errorlevel 1 (
    echo ERROR: Failed to read Git status.
    call :PauseAndExit 1
    exit /b 1
)

for %%A in ("%STATUS_FILE%") do set "STATUS_SIZE=%%~zA"
if not "%STATUS_SIZE%"=="0" (
    echo.
    echo There are uncommitted files. This script only pushes committed changes:
    type "%STATUS_FILE%"
)

echo.
echo Failed attempts retry every %RETRY_SECONDS% seconds. Press Ctrl+C to stop.
echo.

set /a ATTEMPT=1

:PushLoop
echo Push attempt !ATTEMPT!...
git push -u "%REMOTE_NAME%" "%BRANCH_NAME%" > "%OUTPUT_FILE%" 2>&1
set "PUSH_EXIT=%ERRORLEVEL%"
type "%OUTPUT_FILE%"

if "%PUSH_EXIT%"=="0" (
    echo.
    echo Push finished.
    call :PauseAndExit 0
    exit /b 0
)

findstr /I /C:"non-fast-forward" /C:"fetch first" /C:"Updates were rejected" /C:"remote contains work that you do not have locally" "%OUTPUT_FILE%" >nul 2>nul
if not errorlevel 1 call :PullBeforePush

echo.
echo Push failed. Retrying in %RETRY_SECONDS% seconds.
timeout /t %RETRY_SECONDS% /nobreak >nul
set /a ATTEMPT+=1
goto :PushLoop

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

:PullBeforePush
echo.
echo Remote has commits that are not local. Trying pull before the next push...
git pull --rebase --autostash "%REMOTE_NAME%" "%BRANCH_NAME%"
if errorlevel 1 (
    echo.
    echo Pull before push did not finish. Resolve any conflicts if needed; this script will keep retrying.
)
exit /b 0

:PauseAndExit
set "EXIT_CODE=%~1"
del "%OUTPUT_FILE%" >nul 2>nul
del "%STATUS_FILE%" >nul 2>nul
echo.
if /I not "%NO_PAUSE%"=="1" pause
popd >nul
exit /b %EXIT_CODE%
