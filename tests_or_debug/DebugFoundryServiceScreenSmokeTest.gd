extends SceneTree
class_name DebugFoundryServiceScreenSmokeTest


const RunState = preload("res://scripts/core/battle/RunState.gd")
const FoundryServiceScreen = preload("res://scripts/ui/forge/FoundryServiceScreen.gd")


func _init() -> void:
	print("--- DebugFoundryServiceScreenSmokeTest: start ---")

	var run_state := RunState.new()
	run_state.setup_new_run()
	var screen := FoundryServiceScreen.new()
	screen.setup(run_state)
	screen._build_view()
	var passed := screen.get_child_count() > 0 and screen.root != null and screen.confirm_dialog != null
	screen.free()

	print("%s: Foundry service screen builds cards and confirmation UI" % ["PASS" if passed else "FAIL"])
	print("PASS: DebugFoundryServiceScreenSmokeTest" if passed else "FAIL: DebugFoundryServiceScreenSmokeTest")
	print("--- DebugFoundryServiceScreenSmokeTest: end ---")
	quit(0 if passed else 1)
