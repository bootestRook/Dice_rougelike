extends SceneTree
class_name DebugGmPhysicsDiceTargetSmokeTest


func _init() -> void:
	print("--- DebugGmPhysicsDiceTargetSmokeTest: start ---")
	var all_passed := true

	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	var scene := load("res://scenes/debug/GmPhysicsDiceTestScreen.tscn")
	var screen = scene.instantiate()
	root.add_child(screen)

	await process_frame
	await process_frame
	await process_frame

	var solver_snapshot: Dictionary = screen.call("automation_get_snapshot")
	all_passed = _check("native target solver is loaded", bool(solver_snapshot.get("target_solver_ready", false))) and all_passed

	screen.call("automation_clear")
	screen.call("automation_set_dice_count", 6)
	screen.call("automation_set_targets", [1, 2, 3, 4, 5, 6])
	var start_ms := Time.get_ticks_msec()
	screen.call("_drop_with_current_settings", true)

	var entered_playback := false
	var playback_latency_ms := 999999
	for _i in range(1800):
		await physics_frame
		var snapshot: Dictionary = screen.call("automation_get_snapshot")
		if not bool(snapshot.get("planning", true)) and int(snapshot.get("active_dice", 0)) == 6:
			playback_latency_ms = int(Time.get_ticks_msec() - start_ms)
			entered_playback = true
			break
	all_passed = _check("target solver enters visible playback", entered_playback) and all_passed
	print("target playback latency ms: %d" % playback_latency_ms)
	all_passed = _check("target playback starts within 800ms", playback_latency_ms <= 800) and all_passed
	var playback_snapshot: Dictionary = screen.call("automation_get_snapshot")
	all_passed = _check("target throw uses native solver", str(playback_snapshot.get("target_plan_source", "")) == "原生快速求解器") and all_passed
	all_passed = _check("target throw plays recorded physics trajectory", bool(playback_snapshot.get("recorded_playback", false))) and all_passed
	var min_path_separation := float(playback_snapshot.get("target_min_path_separation", 0.0))
	print("target min path separation: %.2f" % min_path_separation)
	all_passed = _check("target trajectories avoid visible clipping", min_path_separation >= 0.9) and all_passed
	var min_table_margin := float(playback_snapshot.get("target_min_table_margin", 0.0))
	print("target min table margin: %.2f" % min_table_margin)
	all_passed = _check("target trajectories stay inside table", min_table_margin >= 0.55) and all_passed

	var settled := false
	var final_values: Array = []
	for _i in range(720):
		await physics_frame
		var snapshot: Dictionary = screen.call("automation_get_snapshot")
		if not bool(snapshot.get("rolling", true)) and int(snapshot.get("active_dice", 0)) == 6:
			final_values = snapshot.get("last_values", [])
			settled = true
			break
	all_passed = _check("target throw settles", settled) and all_passed
	print("target final values: %s" % [str(final_values)])
	all_passed = _check("target throw lands requested pips", final_values == [1, 2, 3, 4, 5, 6]) and all_passed
	var settled_snapshot: Dictionary = screen.call("automation_get_snapshot")
	var dice_positions: Array = settled_snapshot.get("dice_positions", [])
	var min_final_separation := _min_xz_separation(dice_positions)
	print("target min final separation: %.2f" % min_final_separation)
	all_passed = _check("target dice do not settle embedded", min_final_separation >= 0.86) and all_passed

	screen.queue_free()
	print("PASS: DebugGmPhysicsDiceTargetSmokeTest" if all_passed else "FAIL: DebugGmPhysicsDiceTargetSmokeTest")
	print("--- DebugGmPhysicsDiceTargetSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed


func _min_xz_separation(positions: Array) -> float:
	if positions.size() < 2:
		return INF
	var min_distance := INF
	for i in range(positions.size()):
		for j in range(i + 1, positions.size()):
			var a_pos := positions[i] as Vector3
			var b_pos := positions[j] as Vector3
			min_distance = minf(min_distance, Vector2(a_pos.x, a_pos.z).distance_to(Vector2(b_pos.x, b_pos.z)))
	return min_distance
