@echo off
setlocal EnableExtensions EnableDelayedExpansion

pushd "%~dp0" >nul

set "STATUS_FILE=%TEMP%\dice_rougelike_git_status_%RANDOM%%RANDOM%.txt"
set "STAGED_FILE=%TEMP%\dice_rougelike_git_staged_%RANDOM%%RANDOM%.txt"

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

echo Repo folder: %CD%
echo.

git status --short --untracked-files=all > "%STATUS_FILE%"
if errorlevel 1 (
    echo ERROR: Failed to read Git status.
    call :PauseAndExit 1
    exit /b 1
)

for %%A in ("%STATUS_FILE%") do set "STATUS_SIZE=%%~zA"
if "%STATUS_SIZE%"=="0" (
    echo No non-ignored changes to commit.
    call :PauseAndExit 0
    exit /b 0
)

echo Current non-ignored changes:
type "%STATUS_FILE%"
echo.

set "CONFIRM="
set /p "CONFIRM=Commit all non-ignored changes listed above? Type y then Enter: "
if /I not "%CONFIRM%"=="y" if /I not "%CONFIRM%"=="yes" (
    echo Commit cancelled.
    call :PauseAndExit 0
    exit /b 0
)

set "MESSAGE="
set /p "MESSAGE=Commit message; leave blank for default: "
if "%MESSAGE%"=="" set "MESSAGE=chore: update project files"

git add -A -- .
if errorlevel 1 (
    echo ERROR: git add failed.
    call :PauseAndExit 1
    exit /b 1
)

git diff --cached --name-only > "%STAGED_FILE%"
if errorlevel 1 (
    echo ERROR: Failed to read staged files.
    call :PauseAndExit 1
    exit /b 1
)

set "BLOCKED_COUNT=0"
for /f "usebackq delims=" %%F in ("%STAGED_FILE%") do (
    call :IsBlockedFile "%%F"
    if not errorlevel 1 (
        if "!BLOCKED_COUNT!"=="0" (
            echo.
            echo Blocked files were staged and will be unstaged:
        )
        git restore --staged -- "%%F"
        if errorlevel 1 (
            echo ERROR: Failed to unstage blocked file: %%F
            call :PauseAndExit 1
            exit /b 1
        )
        echo   %%F
        set /a BLOCKED_COUNT+=1
    )
)

git diff --cached --name-only > "%STAGED_FILE%"
if errorlevel 1 (
    echo ERROR: Failed to read staged files.
    call :PauseAndExit 1
    exit /b 1
)

for %%A in ("%STAGED_FILE%") do set "STAGED_SIZE=%%~zA"
if "%STAGED_SIZE%"=="0" (
    echo.
    echo No files are staged for commit.
    call :PauseAndExit 0
    exit /b 0
)

echo.
echo Files to commit:
for /f "usebackq delims=" %%F in ("%STAGED_FILE%") do echo   %%F
echo.

git commit -m "%MESSAGE%"
if errorlevel 1 (
    echo ERROR: git commit failed.
    call :PauseAndExit 1
    exit /b 1
)

echo.
echo Commit finished.
git log -1 --oneline
call :PauseAndExit 0
exit /b 0

:IsBlockedFile
set "CHECK_FILE=%~1"
set "CHECK_EXT=%~x1"
set "BLOCKED="

if /I "!CHECK_FILE:~0,7!"==".godot/" set "BLOCKED=1"
if /I "!CHECK_FILE:~0,8!"==".import/" set "BLOCKED=1"
if /I "!CHECK_FILE:~0,13!"=="node_modules/" set "BLOCKED=1"
if /I "!CHECK_FILE:~0,6!"=="build/" set "BLOCKED=1"
if /I "!CHECK_FILE:~0,5!"=="dist/" set "BLOCKED=1"
if /I "!CHECK_FILE:~0,8!"=="exports/" set "BLOCKED=1"
if /I "!CHECK_FILE:~0,11!"=="ai_outputs/" set "BLOCKED=1"
if /I "!CHECK_FILE:~0,8!"=="ai_temp/" set "BLOCKED=1"
if /I "!CHECK_FILE:~0,16!"=="references_temp/" set "BLOCKED=1"
if /I "!CHECK_FILE:~0,12!"=="screenshots/" set "BLOCKED=1"
if /I "!CHECK_FILE:~0,11!"=="recordings/" set "BLOCKED=1"

if /I "!CHECK_EXT!"==".exe" set "BLOCKED=1"
if /I "!CHECK_EXT!"==".apk" set "BLOCKED=1"
if /I "!CHECK_EXT!"==".aab" set "BLOCKED=1"
if /I "!CHECK_EXT!"==".app" set "BLOCKED=1"
if /I "!CHECK_EXT!"==".dmg" set "BLOCKED=1"
if /I "!CHECK_EXT!"==".zip" set "BLOCKED=1"
if /I "!CHECK_EXT!"==".7z" set "BLOCKED=1"
if /I "!CHECK_EXT!"==".rar" set "BLOCKED=1"

if defined BLOCKED exit /b 0
exit /b 1

:PauseAndExit
set "EXIT_CODE=%~1"
del "%STATUS_FILE%" >nul 2>nul
del "%STAGED_FILE%" >nul 2>nul
echo.
if /I not "%NO_PAUSE%"=="1" pause
popd >nul
exit /b %EXIT_CODE%
