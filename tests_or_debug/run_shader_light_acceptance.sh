#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [ "${GODOT_BIN:-}" != "" ]; then
	GODOT_EXE="$GODOT_BIN"
else
	GODOT_EXE="$(command -v godot || true)"
fi

if [ "$GODOT_EXE" = "" ]; then
	echo "FAIL: GODOT_BIN is not set and godot was not found on PATH."
	exit 1
fi

if [ "$#" -eq 0 ]; then
	set -- --all
fi

"$GODOT_EXE" --path . --script "res://tests_or_debug/visual_acceptance/shader_light/tools/shader_light_acceptance_runner.gd" -- --shader-light-va "$@"
