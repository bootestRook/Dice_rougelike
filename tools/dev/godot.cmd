@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0godot.ps1" %*
exit /b %ERRORLEVEL%
