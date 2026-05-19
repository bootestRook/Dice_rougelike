extends SceneTree
class_name DebugMapNonCombatVisualStateSmokeTest


const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")


func _init() -> void:
	print("--- DebugMapNonCombatVisualStateSmokeTest: start ---")

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
	all_passed = _check("battle screen exists under map", battle_screen != null) and all_passed
	all_passed = _check("map view is visible at run start", _map_view_visible(main_view)) and all_passed
	all_passed = _check("install focus overlay is not visible at run start", not _install_focus_overlay_visible(battle_screen)) and all_passed

	if battle_screen != null:
		battle_screen.call("begin_reward_install", _make_debug_piece())
	await process_frame
	await process_frame

	all_passed = _check("install focus overlay is visible during install", _install_focus_overlay_visible(battle_screen)) and all_passed
	var snapshot: Dictionary = battle_screen.call("automation_get_snapshot") if battle_screen != null else {}
	all_passed = _check("battle screen enters reward install state", bool(snapshot.get("reward_install_active", false))) and all_passed

	var flow = main_view.game_flow_controller
	if flow != null:
		flow.return_to_map_after_battle()
	await create_timer(1.05).timeout
	await process_frame
	await process_frame

	snapshot = battle_screen.call("automation_get_snapshot") if battle_screen != null else {}
	all_passed = _check("map view stays visible after returning to map", _map_view_visible(main_view)) and all_passed
	all_passed = _check("install focus overlay is hidden after returning to map", not _install_focus_overlay_visible(battle_screen)) and all_passed
	all_passed = _check("reward phase is cleared after returning to map", not bool(snapshot.get("reward_phase_active", true))) and all_passed
	all_passed = _check("reward install state is cleared after returning to map", not bool(snapshot.get("reward_install_active", true))) and all_passed

	main_view.queue_free()
	print("PASS: DebugMapNonCombatVisualStateSmokeTest" if all_passed else "FAIL: DebugMapNonCombatVisualStateSmokeTest")
	print("--- DebugMapNonCombatVisualStateSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _make_debug_piece() -> ForgePieceDef:
	var operation := ForgeOperationDef.new()
	operation.op = ForgeOperationDef.OP_SET_MARK
	operation.value_id = &"mark_red"

	var piece := ForgePieceDef.new()
	piece.id = &"debug_map_visual_state"
	piece.display_name = "调试红印"
	piece.description = "调试用。"
	piece.operations = [operation]
	return piece


func _map_view_visible(root_node: Node) -> bool:
	var map_view := _find_node_by_name(root_node, "MapStageView") as Control
	return map_view != null and map_view.visible


func _install_focus_overlay_visible(battle_screen) -> bool:
	if battle_screen == null:
		return false
	var overlay := _find_node_by_name(battle_screen, "InstallFocusOverlay") as Control
	return overlay != null and overlay.visible


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
