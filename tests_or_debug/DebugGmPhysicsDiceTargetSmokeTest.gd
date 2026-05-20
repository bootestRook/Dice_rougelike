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
	screen.call("automation_select_dice", [0, 1, 2, 3, 4, 5])
	var start_ms := Time.get_ticks_msec()
	screen.call("_drop_with_current_settings", true)
	var launch_snapshot: Dictionary = screen.call("automation_get_snapshot")
	all_passed = _check("target throw launches all selected dice together", _rolling_indices(launch_snapshot) == [0, 1, 2, 3, 4, 5] and int(launch_snapshot.get("pending_launches", -1)) == 0) and all_passed

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
	var return_seen := false
	var curved_return_seen := false
	var individual_return_seen := false
	for _i in range(540):
		await physics_frame
		var snapshot: Dictionary = screen.call("automation_get_snapshot")
		if _any_ready_returning(snapshot):
			return_seen = true
		if _any_curved_ready_return(snapshot):
			curved_return_seen = true
		if _any_ready_returning(snapshot) and not _rolling_indices(snapshot).is_empty():
			individual_return_seen = true
		if not bool(snapshot.get("rolling", true)) and int(snapshot.get("active_dice", 0)) == 6:
			final_values = snapshot.get("last_values", [])
			settled = true
			break
	all_passed = _check("target throw settles", settled) and all_passed
	print("target final values: %s" % [str(final_values)])
	all_passed = _check("target throw stores settled ground pips", _values_are_valid_pips(final_values, 6)) and all_passed
	var settled_snapshot: Dictionary = screen.call("automation_get_snapshot")
	all_passed = _check("target dice begin ready return after ground stillness", return_seen) and all_passed
	all_passed = _check("target dice return together after all selected dice stop", not individual_return_seen) and all_passed
	all_passed = _check("target dice ready return uses curved path", curved_return_seen) and all_passed
	all_passed = _check("target dice sample face after stable ground stop", _dice_settled_on_ground(settled_snapshot)) and all_passed
	all_passed = _check("target dice return starts from settled ground position", _return_starts_from_settled_position(settled_snapshot)) and all_passed
	all_passed = _check("target dice keep settled pips after returning to ready row", _ready_faces_match_settled_faces(settled_snapshot)) and all_passed
	all_passed = _check("target dice expose post-return resolution request", _resolution_request_matches_snapshot(settled_snapshot, [0, 1, 2, 3, 4, 5])) and all_passed
	all_passed = _check("target dice expose post-score dice exit request", _dice_exit_request_matches_snapshot(settled_snapshot)) and all_passed
	all_passed = _check("target dice keep requested ready return speed", is_equal_approx(float(settled_snapshot.get("ready_return_duration_seconds", 0.0)), 0.58)) and all_passed
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


func _values_are_valid_pips(values: Array, expected_count: int) -> bool:
	if values.size() != expected_count:
		return false
	for value in values:
		var pip := int(value)
		if pip < 1 or pip > 6:
			return false
	return true


func _any_ready_returning(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary and bool(row.get("returning_to_ready", false)):
			return true
	return false


func _any_curved_ready_return(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary and bool(row.get("returning_to_ready", false)) and float(row.get("ready_return_curve_offset", 0.0)) > 0.10:
			return true
	return false


func _rolling_indices(snapshot: Dictionary) -> Array[int]:
	var indices: Array[int] = []
	var dice_rows: Array = snapshot.get("dice", [])
	for index in range(dice_rows.size()):
		var row = dice_rows[index]
		if row is Dictionary and bool(row.get("rolling", false)):
			indices.append(index)
	return indices


func _dice_settled_on_ground(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var settled_position: Vector3 = row.get("last_settled_position", Vector3.ZERO)
		if settled_position.y < -0.20 or settled_position.y > 1.20:
			return false
		if float(row.get("last_settled_linear_speed", 999.0)) > 0.19:
			return false
		if float(row.get("last_settled_angular_speed", 999.0)) > 0.31:
			return false
		if int(row.get("last_settled_stable_frames", 0)) < 12:
			return false
	return true


func _return_starts_from_settled_position(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var settled_position: Vector3 = row.get("last_settled_position", Vector3.ZERO)
		var return_start_position: Vector3 = row.get("ready_return_start_position", Vector3.ZERO)
		if settled_position.distance_to(return_start_position) > 0.02:
			return false
	return true


func _ready_faces_match_settled_faces(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var settled_face_index := int(row.get("last_settled_face_index", -1))
		var settled_face_value := int(row.get("last_settled_face_value", 0))
		if settled_face_index < 0 or settled_face_value < 1 or settled_face_value > 6:
			return false
		if int(row.get("face_index", -2)) != settled_face_index:
			return false
		if int(row.get("face_value", 0)) != settled_face_value:
			return false
		if int(row.get("visual_top_face_index", -2)) != settled_face_index:
			return false
		if int(row.get("visual_top_face_value", 0)) != settled_face_value:
			return false
		if float(row.get("visual_top_text_alignment", -1.0)) < 0.95:
			return false
	return true


func _resolution_request_matches_snapshot(snapshot: Dictionary, expected_rolled_indices: Array) -> bool:
	if int(snapshot.get("resolution_request_count", 0)) < 1:
		return false
	var request: Dictionary = snapshot.get("last_resolution_request", {})
	if str(request.get("source", "")) != "gm_physics_dice":
		return false
	if str(request.get("phase", "")) != "after_ready_return":
		return false
	if request.get("rolled_dice_indices", []) != expected_rolled_indices:
		return false
	var dice_rows: Array = request.get("dice", [])
	var final_values: Array = snapshot.get("last_values", [])
	if dice_rows.size() != final_values.size():
		return false
	var total := 0
	for index in range(dice_rows.size()):
		if not (dice_rows[index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[index]
		var face_value := int(row.get("face_value", 0))
		if face_value != int(final_values[index]):
			return false
		if bool(row.get("rolled", false)) != expected_rolled_indices.has(index):
			return false
		total += face_value
	var score_request: Dictionary = request.get("score_request", {})
	if int(score_request.get("point_total", -1)) != total:
		return false
	if score_request.get("pip_values", []) != final_values:
		return false
	var effect_request: Dictionary = request.get("effect_request", {})
	return str(effect_request.get("status", "")) == "reserved_for_formal_game" and effect_request.get("steps", []) == []


func _dice_exit_request_matches_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("dice_exit_request_count", 0)) < 1:
		return false
	var request: Dictionary = snapshot.get("last_dice_exit_request", {})
	if str(request.get("source", "")) != "gm_physics_dice":
		return false
	if str(request.get("phase", "")) != "after_score_resolved":
		return false
	var animation: Dictionary = request.get("animation", {})
	if str(animation.get("order", "")) != "left_to_right":
		return false
	if str(animation.get("curve", "")) != "straight":
		return false
	if (animation.get("world_exit_direction", Vector3.ZERO) as Vector3).distance_to(Vector3(0.0, 0.0, -1.0)) > 0.01:
		return false
	if float(animation.get("step_delay_seconds", 0.0)) <= 0.0 or float(animation.get("duration_seconds", 0.0)) <= 0.0:
		return false
	var world_exit_offset := animation.get("world_exit_offset", Vector3.ZERO) as Vector3
	if world_exit_offset.z >= 0.0 or absf(world_exit_offset.y) > 0.01:
		return false
	if absf(float(animation.get("arc_height", -1.0))) > 0.01:
		return false
	var next_round: Dictionary = request.get("next_round", {})
	if not bool(next_round.get("wait", false)) or str(next_round.get("status", "")) != "reserved_for_formal_game":
		return false
	var score: Dictionary = snapshot.get("score", {})
	var request_score: Dictionary = request.get("score", {})
	if int(request_score.get("final_score", -1)) != int(score.get("final_score", -2)):
		return false
	if int(request_score.get("current_score", -1)) != int(score.get("current_score", -2)):
		return false
	var sequence: Array = request.get("sequence", [])
	var final_values: Array = snapshot.get("last_values", [])
	if sequence.size() != final_values.size() or sequence.is_empty():
		return false
	var previous_x := -INF
	var step_delay := float(animation.get("step_delay_seconds", 0.0))
	for order_index in range(sequence.size()):
		if not (sequence[order_index] is Dictionary):
			return false
		var item: Dictionary = sequence[order_index]
		if int(item.get("order_index", -1)) != order_index:
			return false
		if not is_equal_approx(float(item.get("delay_seconds", -1.0)), float(order_index) * step_delay):
			return false
		if (item.get("exit_direction", Vector3.ZERO) as Vector3).distance_to(Vector3(0.0, 0.0, -1.0)) > 0.01:
			return false
		var start_position := item.get("start_position", Vector3.ZERO) as Vector3
		if start_position.x < previous_x - 0.001:
			return false
		previous_x = start_position.x
		var die_index := int(item.get("die_index", -1))
		if die_index < 0 or die_index >= final_values.size():
			return false
		if int(item.get("face_value", 0)) != int(final_values[die_index]):
			return false
	return true
