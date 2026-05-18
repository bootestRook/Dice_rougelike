extends SceneTree
class_name DebugMainStartButtonSmokeTest


func _init() -> void:
	print("--- DebugMainStartButtonSmokeTest: start ---")
	var all_passed := true

	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var error := change_scene_to_file("res://scenes/main/Main.tscn")
	all_passed = _check("main scene loads", error == OK) and all_passed

	await process_frame
	await process_frame
	var main := current_scene

	var start_button := _find_button_by_text(main, "开始游戏")
	var gm_button := _find_button_by_text(main, "GM测试")
	var exit_button := _find_button_by_text(main, "退出")
	all_passed = _check("start button exists", start_button != null) and all_passed
	all_passed = _check("GM test button exists", gm_button != null) and all_passed
	all_passed = _check("exit button exists", exit_button != null) and all_passed

	if gm_button != null:
		_send_mouse_button(gm_button, MOUSE_BUTTON_LEFT)
		await process_frame
		await process_frame
		all_passed = _check("clicking GM opens GM test list", _has_node_named(main, "GMTestRoot")) and all_passed
		var back_button := _find_button_by_text(main, "返回主页")
		all_passed = _check("GM test list has return button", back_button != null) and all_passed
		if back_button != null:
			_send_mouse_button(back_button, MOUSE_BUTTON_LEFT)
			await process_frame
			await process_frame
			all_passed = _check("returning from GM shows main menu", _has_node_named(main, "MainMenuRoot")) and all_passed

	start_button = _find_button_by_text(main, "开始游戏")
	if start_button != null:
		_send_mouse_button(start_button, MOUSE_BUTTON_LEFT)
		await process_frame
		await _wait_for_battle_screen(main, 120)
		all_passed = _check("clicking start opens battle screen", _has_battle_screen(main)) and all_passed

	if main != null:
		main.queue_free()
	await process_frame

	print("PASS: DebugMainStartButtonSmokeTest" if all_passed else "FAIL: DebugMainStartButtonSmokeTest")
	print("--- DebugMainStartButtonSmokeTest: end ---")
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


func _wait_for_battle_screen(main: Node, max_steps: int) -> void:
	for _step in range(max_steps):
		if _has_battle_screen(main):
			return
		await create_timer(0.05).timeout


func _has_battle_screen(main: Node) -> bool:
	return _find_battle_screen(main) != null


func _find_battle_screen(node: Node) -> Node:
	if node.has_method("start_battle_with_run_state") and node.has_method("show_reward_choices"):
		return node
	for child in node.get_children():
		var result := _find_battle_screen(child)
		if result != null:
			return result
	return null


func _has_node_named(node: Node, node_name: String) -> bool:
	if node.name == node_name:
		return true
	for child in node.get_children():
		if _has_node_named(child, node_name):
			return true
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
