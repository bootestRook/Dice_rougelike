extends SceneTree
class_name DebugMapRealInputSmokeTest


func _init() -> void:
	print("--- DebugMapRealInputSmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var scene := load("res://scenes/main/Main.tscn")
	var main_view = scene.instantiate()
	root.add_child(main_view)
	await process_frame
	await process_frame

	main_view.call("_on_start_battle_pressed")
	await create_timer(1.05).timeout
	await process_frame

	var map_view := _find_node_by_name(main_view, "MapStageView") as Control
	var input_shield := _find_node_by_name(main_view, "RunStageInputShield") as Control
	all_passed = _check("地图界面可见", map_view != null and map_view.visible) and all_passed
	all_passed = _check("地图输入遮罩已释放", input_shield != null and not input_shield.visible) and all_passed

	var second_die := _find_node_by_name(main_view, "MovementDice_2") as Control
	all_passed = _check("第二颗前进骰热点存在", second_die != null and second_die.visible) and all_passed
	if second_die != null:
		await _send_real_click(second_die.get_global_rect().get_center())
		await process_frame
		var selected_after_die_click: Array = (map_view.call("automation_get_snapshot") as Dictionary).get("selected_movement_dice_indices", []) if map_view != null else []
		all_passed = _check("真实点击可选择第二颗前进骰", selected_after_die_click == [0, 1]) and all_passed

	var roll_button := _find_node_by_name(main_view, "RollMovementButton") as Control
	all_passed = _check("投掷前进骰子按钮存在", roll_button != null and roll_button.visible) and all_passed
	if roll_button != null:
		await _send_real_click(roll_button.get_global_rect().get_center())
		var flow = main_view.game_flow_controller
		var waited := 0.0
		while waited < 9.0 and flow != null and int(flow.get_map_state().get("circle_action_count", 0)) == 0:
			await create_timer(0.1).timeout
			waited += 0.1
		var state: Dictionary = flow.get_map_state() if flow != null else {}
		all_passed = _check("真实点击可触发投掷前进骰子", int(state.get("circle_action_count", 0)) == 1) and all_passed

	main_view.queue_free()
	await process_frame
	print("PASS: DebugMapRealInputSmokeTest" if all_passed else "FAIL: DebugMapRealInputSmokeTest")
	print("--- DebugMapRealInputSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _send_real_click(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.get_viewport().push_input(motion)
	await process_frame

	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = position
	down.global_position = position
	root.get_viewport().push_input(down)
	await process_frame

	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = position
	up.global_position = position
	root.get_viewport().push_input(up)
	await process_frame


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var result := _find_node_by_name(child, node_name)
		if result != null:
			return result
	return null


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
