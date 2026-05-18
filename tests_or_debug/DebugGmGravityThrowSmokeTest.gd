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
		var throw_button := _find_button_by_text(sandbox, "6面")
		var second_throw_button := _find_button_by_text(sandbox, "2面")
		var back_button := _find_button_by_text(sandbox, "返回列表")
		all_passed = _check("sandbox has six face buttons", int(sandbox.call("get_face_button_count")) == 6) and all_passed
		all_passed = _check("sandbox has target face throw button", throw_button != null) and all_passed
		all_passed = _check("sandbox has return button", back_button != null) and all_passed
		if throw_button != null:
			_send_mouse_button(throw_button, MOUSE_BUTTON_LEFT)
			await process_frame
			await physics_frame
			all_passed = _check("throw button records valid throw", bool(sandbox.call("was_throw_started"))) and all_passed
			all_passed = _check("cube starts above throw area", bool(sandbox.call("was_last_throw_started_above"))) and all_passed
			var initial_velocity: Vector3 = sandbox.call("get_last_initial_linear_velocity")
			all_passed = _check("dice starts fall without artificial downward kick", absf(initial_velocity.y) < 0.001) and all_passed
			all_passed = _check("throw creates rigid dice", str(sandbox.call("get_current_cube_class_name")) == "RigidBody3D") and all_passed
			all_passed = _check("one rigid body exists after throw", int(sandbox.call("get_rigid_body_count")) == 1) and all_passed
			var pip_count := int(sandbox.call("get_visible_pip_count"))
			all_passed = _check("dice renders all pip marks (%d)" % [pip_count], pip_count == 21) and all_passed
			all_passed = _check("landing phase is around 0.3 seconds", _is_between(float(sandbox.call("get_landing_phase_seconds")), 0.25, 0.40)) and all_passed
			all_passed = _check("bounce roll phase stays within requested range", _is_between(float(sandbox.call("get_bounce_roll_phase_seconds")), 0.5, 0.8)) and all_passed
			await create_timer(1.48).timeout
			all_passed = _check("landing uses gravity acceleration curve", bool(sandbox.call("did_last_landing_use_gravity_curve"))) and all_passed
			all_passed = _check("bounce starts after touching the ground", bool(sandbox.call("did_last_bounce_start_on_ground"))) and all_passed
			all_passed = _check("bounce roll returns to the ground", bool(sandbox.call("did_last_bounce_touch_ground"))) and all_passed
			all_passed = _check("dice visits fake face before target", int(sandbox.call("get_last_fake_face_number")) != int(sandbox.call("get_last_target_face_number"))) and all_passed
			all_passed = _check("dice adjusts toward target during bounce", bool(sandbox.call("was_last_adjusted_during_bounce"))) and all_passed
			all_passed = _check("dice quickly settles target face up", bool(sandbox.call("was_last_face_up_completed"))) and all_passed
			all_passed = _check("dice target face is six", int(sandbox.call("get_last_target_face_number")) == 6) and all_passed
			all_passed = _check("dice throw presentation stays under 1.5 seconds", float(sandbox.call("get_last_throw_total_seconds")) <= 1.5) and all_passed
		if second_throw_button != null:
			_send_mouse_button(second_throw_button, MOUSE_BUTTON_LEFT)
			await process_frame
			await physics_frame
			all_passed = _check("repeated throw increments count", int(sandbox.call("get_throw_count")) == 2) and all_passed
			all_passed = _check("repeated throw reuses cube slot", int(sandbox.call("get_rigid_body_count")) == 1) and all_passed
			all_passed = _check("second throw targets requested face", int(sandbox.call("get_last_target_face_number")) == 2) and all_passed
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
