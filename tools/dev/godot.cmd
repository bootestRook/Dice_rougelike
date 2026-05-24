@echo off
setlocal
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0godot.ps1" %*
exit /b %ERRORLEVEL%
