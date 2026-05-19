extends SceneTree
class_name DebugGmPhysicsDiceTestSmokeTest


func _init() -> void:
	print("--- DebugGmPhysicsDiceTestSmokeTest: start ---")
	var all_passed := true

	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	var main_scene := load("res://scenes/main/Main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame
	await process_frame

	var gm_button := _find_button_by_text(main, "GM物理投骰")
	all_passed = _check("main menu has gm physics dice entry", gm_button != null) and all_passed
	if gm_button != null:
		gm_button.pressed.emit()
		await process_frame
		await process_frame

	var screen := _find_node_by_name(main, "GmPhysicsDiceTestRoot")
	all_passed = _check("gm physics dice screen opens from main menu", screen != null) and all_passed
	all_passed = _check("gm screen does not start formal game flow", main.current_view_id == &"gm_physics_dice_test") and all_passed

	if screen != null:
		all_passed = _check("dice count slider exists", _find_node_by_name(screen, "DiceCountSlider") != null) and all_passed
		all_passed = _check("drop button exists", _find_node_by_name(screen, "DropButton") != null) and all_passed
		all_passed = _check("target grid exists", _find_node_by_name(screen, "TargetGrid") != null) and all_passed
		all_passed = _check("back button exists", _find_node_by_name(screen, "BackButton") != null) and all_passed

		screen.call("automation_clear")
		screen.call("automation_set_dice_count", 3)
		screen.call("automation_set_targets", [1, 2, null])
		var snapshot: Dictionary = screen.call("automation_get_snapshot")
		all_passed = _check("automation sets requested dice count", int(snapshot.get("dice_count", 0)) == 3) and all_passed
		all_passed = _check("automation stores target pips", snapshot.get("targets", []) == [1, 2, null]) and all_passed

		screen.call("automation_drop_random", 2)
		await physics_frame
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("random throw creates visible physics dice", int(snapshot.get("active_dice", 0)) == 2 and bool(snapshot.get("rolling", false))) and all_passed
		var before_yaw := float(snapshot.get("camera_yaw", 0.0))
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_RIGHT
		press.pressed = true
		screen.call("_input", press)
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(80, -30)
		screen.call("_input", motion)
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_RIGHT
		release.pressed = false
		screen.call("_input", release)
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("camera drag changes view angle", absf(float(snapshot.get("camera_yaw", 0.0)) - before_yaw) > 0.01) and all_passed
		screen.call("automation_clear")
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("clear removes visible dice", int(snapshot.get("active_dice", -1)) == 0) and all_passed

	main.queue_free()
	print("PASS: DebugGmPhysicsDiceTestSmokeTest" if all_passed else "FAIL: DebugGmPhysicsDiceTestSmokeTest")
	print("--- DebugGmPhysicsDiceTestSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var result := _find_node_by_name(child, node_name)
		if result != null:
			return result
	return null


func _find_button_by_text(root_node: Node, text: String) -> Button:
	if root_node is Button and (root_node as Button).text == text:
		return root_node as Button
	for child in root_node.get_children():
		var result := _find_button_by_text(child, text)
		if result != null:
			return result
	return null


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
