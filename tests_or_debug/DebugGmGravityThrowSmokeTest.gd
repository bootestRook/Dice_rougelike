extends SceneTree
class_name DebugGmGravityThrowSmokeTest


func _init() -> void:
	print("--- DebugGmGravityThrowSmokeTest: start ---")
	var all_passed := true

	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var error := change_scene_to_file("res://scenes/main/Main.tscn")
	all_passed = _check("main scene loads", error == OK) and all_passed
	await process_frame
	await process_frame

	var main := current_scene
	var gm_button := _find_button_by_text(main, "GM测试")
	all_passed = _check("main menu has GM test button", gm_button != null) and all_passed
	if gm_button != null:
		_send_mouse_button(gm_button, MOUSE_BUTTON_LEFT)
		await process_frame
		await process_frame

	all_passed = _check("GM test list opens", _has_node_named(main, "GMTestRoot")) and all_passed
	var gravity_button := _find_button_by_text(main, "骰子重力投掷")
	all_passed = _check("GM list has dice gravity throw button", gravity_button != null) and all_passed
	if gravity_button != null:
		_send_mouse_button(gravity_button, MOUSE_BUTTON_LEFT)
		await process_frame
		await process_frame

	var sandbox := _find_node_by_name(main, "GMGravityThrowSandbox")
	all_passed = _check("dice gravity throw sandbox opens", sandbox != null) and all_passed
	if sandbox != null:
		all_passed = _check("sandbox has world nodes", sandbox.call("has_world_nodes")) and all_passed
		all_passed = _check("sandbox has static bounds", sandbox.call("has_static_bounds")) and all_passed
		all_passed = _check("sandbox collision bounds do not render occluding wall meshes", int(sandbox.call("get_visible_boundary_mesh_count")) == 0) and all_passed
		var dice_count_control := _find_node_by_name(sandbox, "DiceCountSpinBox")
		var throw_button := _find_button_by_text(sandbox, "投掷骰子")
		var camera_view_button := _find_button_by_text(sandbox, "视角：斜上方")
		var back_button := _find_button_by_text(sandbox, "返回列表")
		all_passed = _check("sandbox has dice count selector", dice_count_control is SpinBox) and all_passed
		all_passed = _check("sandbox has six target pip inputs", int(sandbox.call("get_target_pip_input_count")) == 6) and all_passed
		all_passed = _check("target pip inputs default to one", _all_string_values(sandbox.call("get_target_pip_input_texts"), "1")) and all_passed
		all_passed = _check("sandbox has throw dice button", throw_button != null) and all_passed
		all_passed = _check("sandbox has camera view button", camera_view_button != null) and all_passed
		all_passed = _check("sandbox has return button", back_button != null) and all_passed
		if camera_view_button != null:
			var top_position: Vector3 = sandbox.call("get_camera_position")
			all_passed = _check("camera defaults to oblique top view", bool(sandbox.call("is_camera_top_view")) and top_position.y > top_position.z and absf(top_position.x) > 1.0 and absf(top_position.z) > 1.0) and all_passed
			_send_mouse_button(camera_view_button, MOUSE_BUTTON_LEFT)
			await process_frame
			var side_position: Vector3 = sandbox.call("get_camera_position")
			all_passed = _check("camera button shows side view", camera_view_button.text == "视角：侧面") and all_passed
			all_passed = _check("camera switches to side view", not bool(sandbox.call("is_camera_top_view")) and side_position.z > side_position.y) and all_passed
			_send_mouse_button(camera_view_button, MOUSE_BUTTON_LEFT)
			await process_frame
			var restored_top_position: Vector3 = sandbox.call("get_camera_position")
			all_passed = _check("camera switches back to oblique top view", bool(sandbox.call("is_camera_top_view")) and restored_top_position.y > restored_top_position.z and absf(restored_top_position.x) > 1.0 and absf(restored_top_position.z) > 1.0) and all_passed
		if throw_button != null:
			sandbox.call("set_debug_dice_count", 4)
			sandbox.call("set_debug_target_pip", 0, "6")
			sandbox.call("set_debug_target_pip", 1, "2")
			sandbox.call("set_debug_target_pip", 2, "9")
			sandbox.call("set_debug_target_pip", 3, "x")
			_send_mouse_button(throw_button, MOUSE_BUTTON_LEFT)
			await process_frame
			await physics_frame
			all_passed = _check("throw button records valid throw", bool(sandbox.call("was_throw_started"))) and all_passed
			all_passed = _check("dice start above throw area", bool(sandbox.call("was_last_throw_started_above"))) and all_passed
			var initial_velocity: Vector3 = sandbox.call("get_last_initial_linear_velocity")
			all_passed = _check("dice starts with downward physical velocity", initial_velocity.y < 0.0) and all_passed
			all_passed = _check("throw creates rigid dice", str(sandbox.call("get_current_cube_class_name")) == "RigidBody3D") and all_passed
			all_passed = _check("four rigid dice exist after throw", int(sandbox.call("get_rigid_body_count")) == 4) and all_passed
			all_passed = _check("last dice count is recorded", int(sandbox.call("get_last_dice_count")) == 4) and all_passed
			all_passed = _check("target pip inputs are constrained", _same_int_array(sandbox.call("get_last_target_pips"), [6, 2, 6, 1])) and all_passed
			var pip_counts: Array = sandbox.call("get_visible_pip_counts")
			all_passed = _check("each dice renders all pip marks", _all_int_values(pip_counts, 21) and pip_counts.size() == 4) and all_passed
			all_passed = _check("real physics throw is released before calibration", bool(sandbox.call("did_last_use_airborne_physics")) and bool(sandbox.call("did_last_use_true_physics")) and bool(sandbox.call("did_last_release_real_physics"))) and all_passed
			all_passed = _check("multi dice collision is enabled", bool(sandbox.call("did_last_enable_dice_collision"))) and all_passed
			all_passed = _check("front half uses real physics window", _is_between(float(sandbox.call("get_last_physics_seconds")), 0.0, 0.05)) and all_passed
			all_passed = _check("bounce phase restores old half-second feel", _is_between(float(sandbox.call("get_bounce_roll_phase_seconds")), 0.48, 0.68)) and all_passed
			await create_timer(1.60).timeout
			all_passed = _check("front half completes fast heavy physics before calibration", _is_between(float(sandbox.call("get_last_physics_seconds")), 0.22, 0.65)) and all_passed
			all_passed = _check("calibration freezes dice after real physics", bool(sandbox.call("did_last_freeze_after_physics"))) and all_passed
			all_passed = _check("all dice record physical ground contact", int(sandbox.call("get_last_physics_ground_contact_count")) == 4 and _positive_int_array(sandbox.call("get_last_physics_contact_counts"), 4)) and all_passed
			var ground_positions: Array = sandbox.call("get_last_ground_positions")
			all_passed = _check("dice land inside throw bounds", ground_positions.size() == 4 and _positions_inside_throw_bounds(ground_positions, float(sandbox.call("get_ground_limit_x")), float(sandbox.call("get_ground_limit_z")))) and all_passed
			all_passed = _check("dice landing scatter does not collapse into a line", _positions_use_two_axes(ground_positions)) and all_passed
			var landing_seconds_by_die: Array = sandbox.call("get_last_landing_seconds_by_die")
			var landing_speeds: Array = sandbox.call("get_last_landing_speeds")
			all_passed = _check("dice physical contact timings and speeds are recorded", _float_values_between(landing_seconds_by_die, 4, 0.20, 0.65) and _float_values_above(landing_speeds, 4, 700.0)) and all_passed
			all_passed = _check("landing uses physical gravity curve", bool(sandbox.call("did_last_landing_use_gravity_curve"))) and all_passed
			all_passed = _check("ground contact is recorded before calibration", bool(sandbox.call("did_last_record_ground_contact"))) and all_passed
			all_passed = _check("calibration starts after ground contact", bool(sandbox.call("did_last_start_calibration_after_ground"))) and all_passed
			all_passed = _check("bounce roll returns to the ground", bool(sandbox.call("did_last_bounce_touch_ground"))) and all_passed
			all_passed = _check("target face turn is gradual during bounce", _is_between(float(sandbox.call("get_last_final_push_seconds")), 0.24, 0.78)) and all_passed
			all_passed = _check("dice visits fake face before target", int(sandbox.call("get_last_fake_face_number")) != int(sandbox.call("get_last_target_face_number"))) and all_passed
			all_passed = _check("dice adjusts toward target during bounce", bool(sandbox.call("was_last_adjusted_during_bounce"))) and all_passed
			var bounce_directions: Array = sandbox.call("get_last_bounce_directions")
			var bounce_roll_axes: Array = sandbox.call("get_last_bounce_roll_axes")
			var turn_speeds: Array = sandbox.call("get_last_turn_speeds")
			var turn_distances: Array = sandbox.call("get_last_turn_distances")
			var turn_time_factors: Array = sandbox.call("get_last_turn_time_factors")
			var directional_roll_strengths: Array = sandbox.call("get_last_directional_roll_strengths")
			var settle_wobble_angles: Array = sandbox.call("get_last_settle_wobble_angles")
			var settle_wobble_frequencies: Array = sandbox.call("get_last_settle_wobble_frequencies")
			var bounce_seconds_by_die: Array = sandbox.call("get_last_bounce_seconds_by_die")
			var bounce_heights: Array = sandbox.call("get_last_bounce_heights")
			var bounce_up_speeds: Array = sandbox.call("get_last_bounce_up_speeds")
			var collision_push_distances: Array = sandbox.call("get_last_collision_push_distances")
			var turn_start_ratios: Array = sandbox.call("get_last_turn_start_ratios")
			var turn_end_ratios: Array = sandbox.call("get_last_turn_end_ratios")
			var turn_curve_powers: Array = sandbox.call("get_last_turn_curve_powers")
			var calibration_force_factors: Array = sandbox.call("get_last_calibration_force_factors")
			var calibration_roll_boosts: Array = sandbox.call("get_last_calibration_roll_boosts")
			all_passed = _check("bounce uses randomized horizontal directions", _directions_are_randomized(bounce_directions, 4)) and all_passed
			all_passed = _check("bounce directions follow final movement", _directions_follow_movement(ground_positions, sandbox.call("get_last_final_positions"), bounce_directions)) and all_passed
			all_passed = _check("bounce roll axes follow movement direction", _roll_axes_follow_directions(bounce_directions, bounce_roll_axes)) and all_passed
			all_passed = _check("directional roll spin follows remaining force", _float_values_between(directional_roll_strengths, 4, 0.20, 0.55)) and all_passed
			all_passed = _check("turn speed and distance are recorded", _positive_float_array(turn_speeds, 4) and _positive_float_array(turn_distances, 4)) and all_passed
			all_passed = _check("target turn timing uses physics-influenced stagger", _float_values_between(turn_time_factors, 4, 0.65, 1.55) and _float_array_varies(turn_time_factors, 4, 0.18)) and all_passed
			all_passed = _check("dice collision push is applied after landing", _positive_float_array(collision_push_distances, 4)) and all_passed
			all_passed = _check("settle wobble is recorded in physical-looking ranges", _float_values_between(settle_wobble_angles, 4, 0.045, 0.090) and _float_values_between(settle_wobble_frequencies, 4, 1.65, 2.45) and _float_array_varies(settle_wobble_angles, 4, 0.01) and _float_array_varies(settle_wobble_frequencies, 4, 0.08)) and all_passed
			all_passed = _check("bounce duration speed and height respond to remaining force", _float_values_between(bounce_seconds_by_die, 4, 0.28, 0.80) and _float_values_between(bounce_heights, 4, 20.0, 64.0) and _float_values_between(bounce_up_speeds, 4, 120.0, 760.0) and _float_array_varies(bounce_seconds_by_die, 4, 0.06) and _float_array_varies(bounce_heights, 4, 0.5) and _float_array_varies(bounce_up_speeds, 4, 1.0) and _float_array_varies(turn_speeds, 4, 0.01)) and all_passed
			all_passed = _check("target rotation completion is staggered per die", _float_values_between(turn_start_ratios, 4, 0.02, 0.19) and _float_values_between(turn_end_ratios, 4, 0.50, 0.93) and _float_array_varies(turn_end_ratios, 4, 0.02) and _turn_windows_are_gradual(turn_start_ratios, turn_end_ratios)) and all_passed
			all_passed = _check("calibration records per-die remaining force and roll assist", _float_values_between(calibration_force_factors, 4, 0.0, 1.0) and _positive_float_array(calibration_roll_boosts, 4) and _float_array_varies(calibration_force_factors, 4, 0.02)) and all_passed
			all_passed = _check("target rotation curve is based on current face distance", _float_values_between(turn_curve_powers, 4, 0.70, 1.0) and _float_array_varies(turn_curve_powers, 4, 0.01)) and all_passed
			all_passed = _check("turn effort applies slight roll", bool(sandbox.call("did_last_apply_roll_offset")) and float(sandbox.call("get_last_roll_offset_distance")) > 14.0) and all_passed
			all_passed = _check("dice settle target pips up", bool(sandbox.call("was_last_face_up_completed")) and _same_int_array(sandbox.call("get_last_target_face_numbers"), [6, 2, 6, 1])) and all_passed
			all_passed = _check("dice final positions do not overlap", _positions_have_min_clearance(sandbox.call("get_last_final_positions"), float(sandbox.call("get_minimum_die_clearance")))) and all_passed
			all_passed = _check("dice throw presentation remains compact", _is_between(float(sandbox.call("get_last_throw_total_seconds")), 0.75, 1.55)) and all_passed
		if throw_button != null:
			sandbox.call("set_debug_dice_count", 2)
			sandbox.call("set_debug_target_pip", 0, "3")
			sandbox.call("set_debug_target_pip", 1, "4")
			_send_mouse_button(throw_button, MOUSE_BUTTON_LEFT)
			await process_frame
			await physics_frame
			all_passed = _check("repeated throw increments count", int(sandbox.call("get_throw_count")) == 2) and all_passed
			all_passed = _check("repeated throw resets rigid dice count", int(sandbox.call("get_rigid_body_count")) == 2) and all_passed
			all_passed = _check("second throw targets requested pips", _same_int_array(sandbox.call("get_last_target_pips"), [3, 4])) and all_passed
		if back_button != null:
			_send_mouse_button(back_button, MOUSE_BUTTON_LEFT)
			await process_frame
			await process_frame
			all_passed = _check("sandbox return opens GM list", _has_node_named(main, "GMTestRoot")) and all_passed
			all_passed = _check("sandbox is removed after return", _find_node_by_name(main, "GMGravityThrowSandbox") == null) and all_passed

	if main != null:
		main.queue_free()
	await process_frame

	print("PASS: DebugGmGravityThrowSmokeTest" if all_passed else "FAIL: DebugGmGravityThrowSmokeTest")
	print("--- DebugGmGravityThrowSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _find_button_by_text(node: Node, text: String) -> Button:
	if node is Button:
		var button := node as Button
		if button.text == text:
			return button
	for child in node.get_children():
		var result := _find_button_by_text(child, text)
		if result != null:
			return result
	return null


func _find_node_by_name(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var result := _find_node_by_name(child, node_name)
		if result != null:
			return result
	return null


func _has_node_named(node: Node, node_name: String) -> bool:
	return _find_node_by_name(node, node_name) != null


func _send_mouse_button(target: Control, button_index: int) -> void:
	var center := target.get_global_rect().get_center()
	print("sending button=%d target=%s center=%s disabled=%s filter=%s" % [
		button_index,
		target.name,
		center,
		str(target.get("disabled")),
		str(target.mouse_filter),
	])

	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	root.get_viewport().push_input(motion)

	var press := InputEventMouseButton.new()
	press.button_index = button_index
	press.pressed = true
	press.position = center
	press.global_position = center
	root.get_viewport().push_input(press)

	var release := InputEventMouseButton.new()
	release.button_index = button_index
	release.pressed = false
	release.position = center
	release.global_position = center
	root.get_viewport().push_input(release)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed


func _is_between(value: float, min_value: float, max_value: float) -> bool:
	return value >= min_value and value <= max_value


func _same_int_array(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for index in range(expected.size()):
		if int(actual[index]) != int(expected[index]):
			return false
	return true


func _all_int_values(values: Array, expected: int) -> bool:
	for value in values:
		if int(value) != expected:
			return false
	return true


func _all_string_values(values: Array, expected: String) -> bool:
	for value in values:
		if str(value) != expected:
			return false
	return true


func _positions_inside_throw_bounds(values: Array, limit_x: float, limit_z: float) -> bool:
	for value in values:
		var position: Vector3 = value
		if absf(position.x) > limit_x + 0.1:
			return false
		if absf(position.z) > limit_z + 0.1:
			return false
	return true


func _positions_use_two_axes(values: Array) -> bool:
	if values.size() < 2:
		return false
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for value in values:
		var position: Vector3 = value
		min_x = minf(min_x, position.x)
		max_x = maxf(max_x, position.x)
		min_z = minf(min_z, position.z)
		max_z = maxf(max_z, position.z)
	return (max_x - min_x) > 18.0 and (max_z - min_z) > 18.0


func _positions_have_min_clearance(values: Array, min_clearance: float) -> bool:
	if values.size() < 2:
		return false
	for left_index in range(values.size()):
		var left_position: Vector3 = values[left_index]
		for right_index in range(left_index + 1, values.size()):
			var right_position: Vector3 = values[right_index]
			var distance := Vector2(left_position.x, left_position.z).distance_to(Vector2(right_position.x, right_position.z))
			if distance < min_clearance - 0.1:
				return false
	return true


func _directions_are_randomized(values: Array, expected_count: int) -> bool:
	if values.size() != expected_count:
		return false
	var first_angle := 0.0
	var has_first := false
	var has_different_angle := false
	for value in values:
		var direction: Vector3 = value
		if absf(direction.y) > 0.001 or direction.length() < 0.90:
			return false
		var angle := atan2(direction.z, direction.x)
		if not has_first:
			first_angle = angle
			has_first = true
			continue
		if absf(wrapf(angle - first_angle, -PI, PI)) > 0.12:
			has_different_angle = true
	return has_different_angle


func _directions_follow_movement(starts: Array, ends: Array, directions: Array) -> bool:
	if starts.size() != ends.size() or starts.size() != directions.size() or starts.is_empty():
		return false
	for index in range(starts.size()):
		var start_position: Vector3 = starts[index]
		var end_position: Vector3 = ends[index]
		var direction: Vector3 = directions[index]
		var delta := Vector3(end_position.x - start_position.x, 0.0, end_position.z - start_position.z)
		if delta.length() <= 0.001:
			return false
		var expected_direction := delta.normalized()
		if direction.normalized().dot(expected_direction) < 0.99:
			return false
	return true


func _roll_axes_follow_directions(directions: Array, roll_axes: Array) -> bool:
	if directions.size() != roll_axes.size() or directions.is_empty():
		return false
	for index in range(directions.size()):
		var direction: Vector3 = directions[index]
		var roll_axis: Vector3 = roll_axes[index]
		if direction.length() <= 0.001 or roll_axis.length() <= 0.001:
			return false
		var expected_axis := Vector3.UP.cross(Vector3(direction.x, 0.0, direction.z).normalized()).normalized()
		if roll_axis.normalized().dot(expected_axis) < 0.99:
			return false
	return true


func _positive_float_array(values: Array, expected_count: int) -> bool:
	if values.size() != expected_count:
		return false
	for value in values:
		if float(value) <= 0.0:
			return false
	return true


func _float_values_above(values: Array, expected_count: int, min_value: float) -> bool:
	if values.size() != expected_count:
		return false
	for value in values:
		if float(value) < min_value:
			return false
	return true


func _positive_int_array(values: Array, expected_count: int) -> bool:
	if values.size() != expected_count:
		return false
	for value in values:
		if int(value) <= 0:
			return false
	return true


func _float_values_between(values: Array, expected_count: int, min_value: float, max_value: float) -> bool:
	if values.size() != expected_count:
		return false
	for value in values:
		if not _is_between(float(value), min_value, max_value):
			return false
	return true


func _float_array_varies(values: Array, expected_count: int, min_delta: float) -> bool:
	if values.size() != expected_count:
		return false
	var min_value := INF
	var max_value := -INF
	for value in values:
		min_value = minf(min_value, float(value))
		max_value = maxf(max_value, float(value))
	return max_value - min_value >= min_delta


func _turn_windows_are_gradual(start_values: Array, end_values: Array) -> bool:
	if start_values.size() != end_values.size() or start_values.is_empty():
		return false
	for index in range(start_values.size()):
		if float(end_values[index]) - float(start_values[index]) < 0.36:
			return false
	return true
