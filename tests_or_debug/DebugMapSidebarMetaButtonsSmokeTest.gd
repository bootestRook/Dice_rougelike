extends SceneTree
class_name DebugMapSidebarMetaButtonsSmokeTest


func _init() -> void:
	print("--- DebugMapSidebarMetaButtonsSmokeTest: start ---")

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

	var battle_screen = main_view.call("_current_battle_screen")
	var map_view := _find_node_by_name(main_view, "MapStageView") as Control
	var input_shield := _find_node_by_name(main_view, "RunStageInputShield") as Control
	var info_button := _find_node_by_name(main_view, "InfoButton") as Button
	var options_button := _find_node_by_name(main_view, "OptionsButton") as Button

	all_passed = _check("map stage setup exists", battle_screen != null and map_view != null and map_view.visible) and all_passed
	all_passed = _check("map stage input shield released", input_shield != null and not input_shield.visible) and all_passed
	all_passed = _check("sidebar meta buttons exist", info_button != null and options_button != null) and all_passed
	all_passed = _check("sidebar info button is enabled during map stage", info_button != null and not info_button.disabled) and all_passed
	all_passed = _check("sidebar options button is enabled during map stage", options_button != null and not options_button.disabled) and all_passed

	if info_button != null:
		await _send_real_click(info_button.get_global_rect().get_center())
		await process_frame
		var popup: Control = null
		if battle_screen != null:
			popup = battle_screen.get("combo_info_popup") as Control
		all_passed = _check("map stage click opens battle info popup", popup != null and popup.visible) and all_passed
		if battle_screen != null and battle_screen.has_method("_hide_combo_info_popup"):
			battle_screen.call("_hide_combo_info_popup")
			await process_frame

	if options_button != null:
		await _send_real_click(options_button.get_global_rect().get_center())
		await process_frame
		var overlay := _find_node_by_name(main_view, "OptionsMenuOverlay") as Control
		all_passed = _check("map stage click opens options menu", overlay != null and overlay.visible and paused) and all_passed
		if battle_screen != null and battle_screen.has_method("_hide_options_menu"):
			battle_screen.call("_hide_options_menu", false)
		paused = false

	main_view.queue_free()
	await process_frame
	print("PASS: DebugMapSidebarMetaButtonsSmokeTest" if all_passed else "FAIL: DebugMapSidebarMetaButtonsSmokeTest")
	print("--- DebugMapSidebarMetaButtonsSmokeTest: end ---")
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
