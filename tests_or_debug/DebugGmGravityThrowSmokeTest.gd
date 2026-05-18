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
		var camera_view_button := _find_button_by_text(sandbox, "视角：侧面")
		var back_button := _find_button_by_text(sandbox, "返回列表")
		all_passed = _check("sandbox has dice count selector", dice_count_control is SpinBox) and all_passed
		all_passed = _check("sandbox has six target pip inputs", int(sandbox.call("get_target_pip_input_count")) == 6) and all_passed
		all_passed = _check("target pip inputs default to one", _all_string_values(sandbox.call("get_target_pip_input_texts"), "1")) and all_passed
		all_passed = _check("sandbox has throw dice button", throw_button != null) and all_passed
		all_passed = _check("sandbox has camera view button", camera_view_button != null) and all_passed
		all_passed = _check("sandbox has return button", back_button != null) and all_passed
		if camera_view_button != null:
			var side_position: Vector3 = sandbox.call("get_camera_position")
			all_passed = _check("camera defaults to side view", not bool(sandbox.call("is_camera_top_view")) and side_position.z > side_position.y) and all_passed
			_send_mouse_button(camera_view_button, MOUSE_BUTTON_LEFT)
			await process_frame
			var top_position: Vector3 = sandbox.call("get_camera_position")
			all_passed = _check("camera switches to top view", bool(sandbox.call("is_camera_top_view")) and top_position.y > top_position.z) and all_passed
			_send_mouse_button(camera_view_button, MOUSE_BUTTON_LEFT)
			await process_frame
			var restored_side_position: Vector3 = sandbox.call("get_camera_position")
			all_passed = _check("camera switches back to side view", not bool(sandbox.call("is_camera_top_view")) and restored_side_position.z > restored_side_position.y) and all_passed
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
			all_passed = _check("scripted physical throw is recorded before calibration", bool(sandbox.call("did_last_use_airborne_physics"))) and all_passed
			all_passed = _check("multi dice collision is enabled", bool(sandbox.call("did_last_enable_dice_collision"))) and all_passed
			all_passed = _check("landing phase restores old 0.3 second feel", _is_between(float(sandbox.call("get_landing_phase_seconds")), 0.25, 0.40)) and all_passed
			all_passed = _check("bounce phase restores old half-second feel", _is_between(float(sandbox.call("get_bounce_roll_phase_seconds")), 0.48, 0.68)) and all_passed
			all_passed = _check("target face pre-rotation stays around 0.2 seconds", _is_between(float(sandbox.call("get_face_pre_rotate_seconds")), 0.15, 0.25)) and all_passed
			await create_timer(1.20).timeout
			all_passed = _check("landing uses physical gravity curve", bool(sandbox.call("did_last_landing_use_gravity_curve"))) and all_passed
			all_passed = _check("ground contact is recorded before calibration", bool(sandbox.call("did_last_record_ground_contact"))) and all_passed
			all_passed = _check("calibration starts after ground contact", bool(sandbox.call("did_last_start_calibration_after_ground"))) and all_passed
			all_passed = _check("bounce roll returns to the ground", bool(sandbox.call("did_last_bounce_touch_ground"))) and all_passed
			all_passed = _check("target face pre-rotation is used during bounce", _is_between(float(sandbox.call("get_last_final_push_seconds")), 0.15, 0.25)) and all_passed
			all_passed = _check("dice visits fake face before target", int(sandbox.call("get_last_fake_face_number")) != int(sandbox.call("get_last_target_face_number"))) and all_passed
			all_passed = _check("dice adjusts toward target during bounce", bool(sandbox.call("was_last_adjusted_during_bounce"))) and all_passed
			all_passed = _check("far target rotation applies slight roll", bool(sandbox.call("did_last_apply_roll_offset")) and float(sandbox.call("get_last_roll_offset_distance")) > 0.0) and all_passed
			all_passed = _check("dice settle target pips up", bool(sandbox.call("was_last_face_up_completed")) and _same_int_array(sandbox.call("get_last_target_face_numbers"), [6, 2, 6, 1])) and all_passed
			all_passed = _check("dice throw presentation keeps old compact duration", _is_between(float(sandbox.call("get_last_throw_total_seconds")), 0.75, 1.05)) and all_passed
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
