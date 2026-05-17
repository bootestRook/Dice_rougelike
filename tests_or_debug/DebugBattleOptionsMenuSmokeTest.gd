extends SceneTree
class_name DebugBattleOptionsMenuSmokeTest


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


func _init() -> void:
	print("--- DebugBattleOptionsMenuSmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var flow := GameFlowController.new()
	root.add_child(flow)

	var run_state := RunState.new()
	run_state.setup_new_run()

	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	battle_screen.setup(flow, run_state)
	battle_screen.resolution_fast_mode = true
	root.add_child(battle_screen)

	await process_frame
	await process_frame
	await process_frame

	battle_screen._on_options_pressed()
	await process_frame
	all_passed = _check("options stays locked during round intro", _find_node_by_name(battle_screen, "OptionsMenuOverlay") == null and not paused) and all_passed

	await create_timer(2.0).timeout

	battle_screen._on_options_pressed()
	await process_frame

	var overlay := _find_node_by_name(battle_screen, "OptionsMenuOverlay") as Control
	var scrim := _find_node_by_name(battle_screen, "OptionsMenuScrim") as ColorRect
	var panel := _find_node_by_name(battle_screen, "OptionsMenuPanel") as PanelContainer
	var restart_button := _find_button_by_text(battle_screen, "再来一局")
	var main_menu_button := _find_button_by_text(battle_screen, "主菜单")
	all_passed = _check("options overlay appears", overlay != null and scrim != null and panel != null) and all_passed
	all_passed = _check("options buttons exist", restart_button != null and main_menu_button != null) and all_passed
	all_passed = _check("scrim darkens the battle screen", scrim != null and scrim.color.a >= 0.60) and all_passed
	all_passed = _check("options pauses the battle", paused) and all_passed
	all_passed = _check("options overlay processes while paused", overlay != null and overlay.process_mode == Node.PROCESS_MODE_WHEN_PAUSED) and all_passed

	if restart_button != null:
		restart_button.pressed.emit()
		await process_frame
		all_passed = _check("restart starts a new battle flow", flow.current_state_id == &"battle" and flow.get_run_state() != null) and all_passed
		all_passed = _check("restart unpauses the tree", not paused) and all_passed

	await create_timer(0.2).timeout
	battle_screen._on_options_pressed()
	await process_frame
	main_menu_button = _find_button_by_text(battle_screen, "主菜单")
	if main_menu_button != null:
		all_passed = _check("main menu option pauses again", paused) and all_passed
		main_menu_button.pressed.emit()
		await process_frame
		all_passed = _check("main menu returns to main flow", flow.current_state_id == &"main") and all_passed
		all_passed = _check("main menu unpauses the tree", not paused) and all_passed

	battle_screen.queue_free()
	flow.queue_free()
	print("PASS: DebugBattleOptionsMenuSmokeTest" if all_passed else "FAIL: DebugBattleOptionsMenuSmokeTest")
	print("--- DebugBattleOptionsMenuSmokeTest: end ---")
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
