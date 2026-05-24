extends SceneTree
class_name DebugMapEventRewardReturnSmokeTest


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")


func _init() -> void:
	print("--- DebugMapEventRewardReturnSmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	var main_view = scene.instantiate() if scene != null else null
	if main_view != null:
		root.add_child(main_view)
	await process_frame
	await process_frame

	if main_view != null and main_view.has_method("_on_start_battle_pressed"):
		main_view.call("_on_start_battle_pressed")
	await create_timer(1.05).timeout
	await process_frame

	var flow: GameFlowController = main_view.get("game_flow_controller") as GameFlowController if main_view != null else null
	var map_view := _find_node_by_name(main_view, "MapStageView") as Control
	all_passed = _check("main map setup exists", flow != null and map_view != null and map_view.visible) and all_passed

	if flow != null and map_view != null:
		if flow.map_nodes.size() > 1:
			flow.map_nodes[1]["node_type"] = &"event"
			flow.map_position_index = 0
			flow.map_state_changed.emit(flow.get_map_state())
			await process_frame

		var movement_result := flow.apply_prepared_map_movement_roll([0], [1], [0])
		await process_frame
		var event_snapshot: Dictionary = map_view.call("automation_get_snapshot")
		all_passed = _check("map movement can stop on event node", bool(movement_result.get("success", false)) and bool(event_snapshot.get("pending_event", false))) and all_passed
		all_passed = _check("event node shows enter action", bool(event_snapshot.get("enter_battle_button_visible", false)) and not bool(event_snapshot.get("enter_battle_button_disabled", true))) and all_passed

		map_view.call("_on_enter_battle_pressed")
		await process_frame
		await process_frame

		var reward_snapshot: Dictionary = main_view.call("automation_get_snapshot") if main_view != null and main_view.has_method("automation_get_snapshot") else {}
		var stale_map_view := _find_node_by_name(main_view, "MapStageView") as Control
		all_passed = _check("event reward uses standalone reward screen", str(reward_snapshot.get("view", "")) == "reward" and flow.current_state_id == &"reward") and all_passed
		all_passed = _check("event reward removes blocking map overlay", stale_map_view == null or not stale_map_view.visible) and all_passed
		all_passed = _check("event reward keeps reward choices available", (flow.get_run_state().last_reward_choices as Array).size() > 0) and all_passed

		var choose_result: Dictionary = main_view.call("automation_choose_reward", 0) if main_view != null and main_view.has_method("automation_choose_reward") else {}
		await create_timer(1.05).timeout
		await process_frame
		await process_frame
		var after_choice_snapshot: Dictionary = main_view.call("automation_get_snapshot") if main_view != null and main_view.has_method("automation_get_snapshot") else {}
		if str(after_choice_snapshot.get("view", "")) == "forge" and main_view.has_method("automation_install_piece"):
			main_view.call("automation_install_piece", 0, 0)
			await create_timer(1.05).timeout
			await process_frame
			await process_frame

		var returned_map_view := _find_node_by_name(main_view, "MapStageView") as Control
		var returned_snapshot: Dictionary = returned_map_view.call("automation_get_snapshot") if returned_map_view != null else {}
		var returned_state := flow.get_map_state()
		var returned_nodes: Array = returned_state.get("nodes", [])
		var event_node_cleared := returned_nodes.size() > 1 and bool(returned_nodes[1].get("is_cleared", false))
		all_passed = _check("choosing event reward succeeds", bool(choose_result.get("ok", false))) and all_passed
		all_passed = _check("event reward returns to map phase", flow.current_state_id == &"map" and str((main_view.call("automation_get_snapshot") as Dictionary).get("view", "")) == "map") and all_passed
		all_passed = _check("event node is cleared after reward", event_node_cleared and not bool(returned_snapshot.get("pending_event", true))) and all_passed
		all_passed = _check("map can roll after event reward", returned_map_view != null and returned_map_view.visible and bool(returned_snapshot.get("roll_button_visible", false)) and not bool(returned_snapshot.get("roll_button_disabled", true))) and all_passed

	if main_view != null:
		main_view.queue_free()
	await process_frame
	print("PASS: DebugMapEventRewardReturnSmokeTest" if all_passed else "FAIL: DebugMapEventRewardReturnSmokeTest")
	print("--- DebugMapEventRewardReturnSmokeTest: end ---")
	quit(0 if all_passed else 1)


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
