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

	var initial_snapshot: Dictionary = screen.call("automation_get_snapshot")
	all_passed = _check("gm port target solver is intentionally detached", not bool(initial_snapshot.get("target_solver_ready", true))) and all_passed
	all_passed = _check("gm port exposes isolated source label", str(initial_snapshot.get("target_plan_source", "")) == "GM复刻接口") and all_passed
	all_passed = _check("gm scene exposes reusable bridge", bool(initial_snapshot.get("interface_ready", false)) and str(initial_snapshot.get("interface_source", "")) == "GM场景接口") and all_passed
	screen.call("automation_configure_session", {"target_score": 120, "dice_count": 4, "targets": [6, 5, null, 1]})
	var configured_snapshot: Dictionary = screen.call("automation_get_snapshot")
	all_passed = _check("gm scene accepts future session config", int(configured_snapshot.get("target_score", 0)) == 120 and configured_snapshot.get("targets", []) == [6, 5, null, 1]) and all_passed

	screen.call("automation_clear")
	screen.call("automation_set_dice_count", 6)
	screen.call("automation_set_targets", [1, 2, 3, 4, 5, 6])
	var start_ms := Time.get_ticks_msec()
	screen.call("_drop_with_current_settings", true)

	var entered_roll := false
	for _i in range(30):
		await physics_frame
		var snapshot: Dictionary = screen.call("automation_get_snapshot")
		if bool(snapshot.get("rolling", false)) and int(snapshot.get("active_dice", 0)) == 6:
			entered_roll = true
			break
	all_passed = _check("target throw enters rolling state", entered_roll) and all_passed
	var start_latency_ms := int(Time.get_ticks_msec() - start_ms)
	print("target roll start latency ms: %d" % start_latency_ms)
	all_passed = _check("target roll starts within 800ms", start_latency_ms <= 800) and all_passed

	var settled := false
	var final_values: Array = []
	for _i in range(420):
		await physics_frame
		var snapshot: Dictionary = screen.call("automation_get_snapshot")
		if not bool(snapshot.get("rolling", true)) and int(snapshot.get("active_dice", 0)) == 6:
			final_values = snapshot.get("last_values", [])
			settled = true
			break
	all_passed = _check("target throw settles", settled) and all_passed
	print("target final values: %s" % [str(final_values)])
	all_passed = _check("target throw keeps requested saved pips", final_values == [1, 2, 3, 4, 5, 6]) and all_passed
	var settled_snapshot: Dictionary = screen.call("automation_get_snapshot")
	var dice_positions: Array = settled_snapshot.get("dice_positions", [])
	var min_final_separation := _min_xz_separation(dice_positions)
	print("target min final separation: %.2f" % min_final_separation)
	all_passed = _check("target dice keep readable spacing", min_final_separation >= 0.35) and all_passed

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
