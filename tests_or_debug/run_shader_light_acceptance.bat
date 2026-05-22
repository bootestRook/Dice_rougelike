@echo off
setlocal

pushd "%~dp0.." >nul

if defined GODOT_BIN (
	set "GODOT_EXE=%GODOT_BIN%"
) else (
	for /f "delims=" %%G in ('where godot 2^>nul') do (
		set "GODOT_EXE=%%G"
		goto :godot_found
	)
)

:godot_found
if not defined GODOT_EXE (
	echo FAIL: GODOT_BIN is not set and godot was not found on PATH.
	popd >nul
	exit /b 1
)

if "%~1"=="" (
	"%GODOT_EXE%" --path . --script "res://tests_or_debug/visual_acceptance/shader_light/tools/shader_light_acceptance_runner.gd" -- --shader-light-va --all
) else (
	"%GODOT_EXE%" --path . --script "res://tests_or_debug/visual_acceptance/shader_light/tools/shader_light_acceptance_runner.gd" -- --shader-light-va %*
)
set "EXIT_CODE=%ERRORLEVEL%"

popd >nul
exit /b %EXIT_CODE%
