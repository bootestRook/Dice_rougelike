extends SceneTree
class_name DebugMapStageFlowSmokeTest


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const MapStageViewScript = preload("res://scripts/ui/map/MapStageView.gd")


func _init() -> void:
	print("--- DebugMapStageFlowSmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var main_start_passed := await _check_main_start_enters_map()
	all_passed = main_start_passed and all_passed

	var flow := GameFlowController.new()
	root.add_child(flow)
	flow.start_new_run()

	var map_view = MapStageViewScript.new()
	map_view.setup(flow, flow.get_map_state())
	root.add_child(map_view)

	await process_frame
	await process_frame

	all_passed = _check("new run starts at map phase", flow.current_state_id == &"map") and all_passed
	all_passed = _check("map view has board texture resource", _texture_exists(map_view, "MapBoardTexture")) and all_passed
	all_passed = _check("map view has backdrop texture resource", _texture_exists(map_view, "MapBackdropTexture")) and all_passed
	all_passed = _check("map view has player marker resource", _texture_exists(map_view, "PlayerMarker")) and all_passed
	all_passed = _check("map view builds 32 route nodes", _count_nodes_by_prefix(map_view, "MapNode_") == 32) and all_passed
	all_passed = _check("map art config has all node textures", _has_all_node_textures(map_view)) and all_passed
	all_passed = _check("map rest node uses generated texture", _rest_node_uses_generated_texture(map_view)) and all_passed
	all_passed = _check("map node text labels are readable", _node_label_is_readable(map_view)) and all_passed
	all_passed = _check("map final node is boss", _node_type_at(flow, 31) == &"boss") and all_passed
	all_passed = _check("map player marker is centered on current node", _player_marker_is_centered(map_view)) and all_passed
	all_passed = _check("map movement step label exists", _find_node_by_name(map_view, "MovementStepLabel") != null) and all_passed
	all_passed = _check("map board raise duration is not too fast", float(map_view.call("automation_get_snapshot").get("board_raise_duration", 0.0)) >= 0.75) and all_passed
	all_passed = await _check_board_raise_locks_map_interaction(map_view) and all_passed
	all_passed = _check("map movement step duration is slower", float(map_view.call("automation_get_snapshot").get("marker_step_duration", 0.0)) >= 0.28) and all_passed
	all_passed = _check("map stage uses two movement dice views", _count_nodes_by_prefix(map_view, "MovementDice_") == 2) and all_passed
	all_passed = _check("map stage has movement magic fx layer", _find_node_by_name(map_view, "MovementRollFxLayer") != null) and all_passed
	all_passed = _check("map stage wires black magic fx scene", bool(map_view.call("automation_get_snapshot").get("has_movement_magic_fx", false))) and all_passed
	all_passed = _check("roll button uses texture button", _find_texture_button(map_view, "RollMovementButton") != null) and all_passed
	all_passed = _check("map danger label exists", _find_node_by_name(map_view, "DangerLabel") != null) and all_passed
	var circle_action_label := _find_node_by_name(map_view, "CircleActionLabel") as Label
	all_passed = _check("map shows circle action count in map area", circle_action_label != null and circle_action_label.visible and circle_action_label.text.contains("本圈行动：0 次")) and all_passed
	all_passed = _check("map snapshot exposes circle base score", int(map_view.call("automation_get_snapshot").get("circle_base_score", 0)) == flow.get_run_state().get_current_circle_base_score()) and all_passed
	all_passed = await _check_map_view_can_roll_one_selected_die(map_view, flow) and all_passed
	all_passed = await _check_map_view_stops_at_boss_and_refreshes_after_return(map_view, flow) and all_passed

	var roll_button := _find_texture_button(map_view, "RollMovementButton")
	if roll_button != null:
		roll_button.pressed.emit()
		await _wait_for_map_animation(map_view)

	var state: Dictionary = flow.get_map_state()
	var last_rolls: Array = state.get("last_rolls", [])
	all_passed = _check("map roll uses two D6 values", _is_two_d6_roll(last_rolls)) and all_passed
	var node_count := int(state.get("nodes", []).size())
	var expected_index := (int(last_rolls[0]) + int(last_rolls[1])) % node_count if last_rolls.size() == 2 and node_count > 0 else -1
	all_passed = _check("map roll moves player by dice sum", int(state.get("current_index", 0)) == expected_index) and all_passed
	all_passed = _check("map roll updates danger action count", int(state.get("circle_action_count", 0)) == 1) and all_passed
	all_passed = _check("map action badge updates after roll", circle_action_label != null and circle_action_label.text.contains("本圈行动：1 次")) and all_passed
	if not bool(state.get("pending_battle", false)):
		state = await _roll_until_battle(map_view, flow)
	all_passed = _check("movement can stop on battle node", bool(state.get("pending_battle", false))) and all_passed
	var enter_button_wrapper := _find_node_by_name(map_view, "EnterBattleButton") as Control
	all_passed = _check("enter battle button appears on battle node", enter_button_wrapper != null and enter_button_wrapper.visible) and all_passed

	all_passed = _check("enter battle from map succeeds", flow.request_enter_battle_from_map()) and all_passed
	all_passed = _check("flow switches to battle phase", flow.current_state_id == &"battle") and all_passed

	flow.return_to_map_after_battle()
	all_passed = _check("return_to_map_after_battle switches back to map", flow.current_state_id == &"map") and all_passed

	map_view.queue_free()
	flow.queue_free()
	print("PASS: DebugMapStageFlowSmokeTest" if all_passed else "FAIL: DebugMapStageFlowSmokeTest")
	print("--- DebugMapStageFlowSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_main_start_enters_map() -> bool:
	var scene := load("res://scenes/main/Main.tscn")
	var main_view = scene.instantiate()
	root.add_child(main_view)
	await process_frame
	await process_frame

	main_view.call("_on_start_battle_pressed")
	await create_timer(0.25).timeout

	var flow = main_view.game_flow_controller
	var main_stage := _find_node_by_name(main_view, "MainStageContainer") as Control
	var map_stage := _find_node_by_name(main_view, "MapStageView") as Control
	var input_shield := _find_node_by_name(main_view, "RunStageInputShield") as Control
	var battle_screen = main_view.call("_current_battle_screen")
	var passed := true
	var rise_snapshot: Dictionary = map_stage.call("automation_get_snapshot") if map_stage != null else {}
	passed = _check("map board is raising from bottom at run start", map_stage != null and bool(rise_snapshot.get("is_board_animating", false))) and passed
	passed = _check("run stage input shield blocks other buttons during map raise", input_shield != null and input_shield.visible) and passed
	await create_timer(0.85).timeout
	await process_frame
	passed = _check("main start enters map phase", flow != null and flow.current_state_id == &"map") and passed
	passed = _check("main stage container exists", main_stage != null) and passed
	passed = _check("map stage view is visible after start", map_stage != null and map_stage.visible) and passed
	passed = _check("run stage input shield is released after map raise", input_shield != null and not input_shield.visible) and passed
	passed = _check("map stage is mounted over scoring and prep area", map_stage != null and map_stage.get_parent() != null and map_stage.get_parent().name == "MapStageOverlayHost") and passed
	passed = _check("battle stage stays underneath map", battle_screen != null and battle_screen.visible) and passed
	if battle_screen != null:
		passed = _check("battle controller is deferred during map phase", battle_screen.controller != null and battle_screen.controller.battle_state == null) and passed
		var overlay_host := _find_node_by_name(battle_screen, "MapStageOverlayHost") as Control
		var top_inventory := _find_node_by_name(battle_screen, "TopInventoryBar") as Control
		passed = _check("map overlay is below top inventory", overlay_host != null and top_inventory != null and overlay_host.get_global_rect().position.y > top_inventory.get_global_rect().position.y) and passed
		var battle_title := _find_node_by_name(battle_screen, "BattleTitle") as Label
		var battle_value := _find_node_by_name(battle_screen, "BattleValue") as Label
		var status_label := _find_node_by_name(battle_screen, "StatusLabel") as Label
		var circle_action_label := _find_node_by_name(map_stage, "CircleActionLabel") as Label
		flow.roll_map_movement([0])
		await process_frame
		passed = _check("underlying battle stage refreshes map action count", status_label != null and status_label.text == "行动 1次") and passed
		passed = _check("underlying battle sidebar uses base score slot", battle_title != null and battle_title.text == "基础分" and battle_value != null and battle_value.text == "300") and passed
		passed = _check("underlying battle sidebar omits map action count and danger", battle_value != null and not battle_value.text.contains("次") and not battle_value.text.contains("%")) and passed
		passed = _check("map overlay shows action count outside sidebar", circle_action_label != null and circle_action_label.text.contains("本圈行动：1 次")) and passed
		passed = await _check_sidebar_base_score_waits_for_map_stop(flow, map_stage, battle_value, input_shield) and passed

	main_view.queue_free()
	await process_frame
	return passed


func _check_board_raise_locks_map_interaction(map_view: Node) -> bool:
	var roll_button := _find_texture_button(map_view, "RollMovementButton")
	var first_die := _find_node_by_name(map_view, "MovementDice_1")
	var raise_task = map_view.call("play_raise")
	await create_timer(0.12).timeout

	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var all_passed := true
	all_passed = _check("map board reports animation while raising", bool(snapshot.get("is_board_animating", false))) and all_passed
	all_passed = _check("map interaction lock is active while board moves", bool(snapshot.get("interaction_locked", false))) and all_passed
	all_passed = _check("map roll button is disabled while board moves", roll_button != null and roll_button.disabled) and all_passed
	all_passed = _check("map movement die is disabled while board moves", first_die is BaseButton and (first_die as BaseButton).disabled) and all_passed

	await raise_task
	snapshot = map_view.call("automation_get_snapshot")
	all_passed = _check("map board interaction lock releases after raise", not bool(snapshot.get("is_board_animating", true)) and not bool(snapshot.get("interaction_locked", true))) and all_passed
	all_passed = _check("map roll button is enabled after board raise", roll_button != null and not roll_button.disabled) and all_passed
	return all_passed


func _check_sidebar_base_score_waits_for_map_stop(flow: GameFlowController, map_stage: Node, battle_value: Label, input_shield: Control) -> bool:
	if flow == null or map_stage == null or battle_value == null or flow.get_run_state() == null:
		return _check("base score wait setup exists", false)

	flow._reset_demo_map()
	flow.get_run_state().reset_circle_pressure()
	flow.get_run_state().current_circle_action_count = 4
	flow.run_state_changed.emit(flow.get_run_state())
	flow.map_state_changed.emit(flow.get_map_state())
	await create_timer(0.85).timeout

	var all_passed := true
	var before_text := battle_value.text
	all_passed = _check("base score precondition uses current danger", before_text == "321") and all_passed

	var roll_button := _find_texture_button(map_stage, "RollMovementButton")
	if roll_button == null:
		return _check("base score wait roll button exists", false) and all_passed

	var before_roll_count := int(flow.get_map_state().get("roll_count", 0))
	roll_button.pressed.emit()
	var waited := 0.0
	while int(flow.get_map_state().get("roll_count", 0)) == before_roll_count and waited < 2.0:
		await create_timer(0.05).timeout
		waited += 0.05

	all_passed = _check("map roll state updates before marker settles", int(flow.get_map_state().get("roll_count", 0)) > before_roll_count and bool(map_stage.get("is_marker_animating"))) and all_passed
	all_passed = _check("run stage input shield blocks other buttons during map movement", input_shield != null and input_shield.visible) and all_passed
	all_passed = _check("base score holds until marker stops", battle_value.text == before_text) and all_passed

	await _wait_for_map_animation(map_stage)
	all_passed = _check("run stage input shield releases after map movement", input_shield != null and not input_shield.visible) and all_passed
	await create_timer(0.85).timeout
	var expected_text := str(flow.get_run_state().get_current_circle_adjusted_base_score())
	all_passed = _check("base score settles after marker stops", battle_value.text == expected_text) and all_passed
	return all_passed


func _roll_until_battle(map_view: Node, flow: GameFlowController) -> Dictionary:
	var state: Dictionary = flow.get_map_state()
	var roll_button := _find_texture_button(map_view, "RollMovementButton")
	for _attempt in range(8):
		if bool(state.get("pending_battle", false)):
			return state
		if roll_button == null:
			return state
		roll_button.pressed.emit()
		await _wait_for_map_animation(map_view)
		state = flow.get_map_state()
	return state


func _check_map_view_stops_at_boss_and_refreshes_after_return(map_view: Node, flow: GameFlowController) -> bool:
	var roll_button := _find_texture_button(map_view, "RollMovementButton")
	if roll_button == null:
		return _check("map boss stop roll button exists", false)
	flow.map_position_index = 30
	if flow.map_nodes.size() > 4:
		flow.map_nodes[4]["is_cleared"] = true
	flow.map_state_changed.emit(flow.get_map_state())
	await process_frame
	var before_state := flow.get_map_state()
	roll_button.pressed.emit()
	await _wait_for_map_animation(map_view)
	var after_state := flow.get_map_state()
	var after_nodes: Array = after_state.get("nodes", [])
	var all_passed := true
	all_passed = _check("map view stops movement on boss node", bool(after_state.get("stopped_by_boss", false)) and int(after_state.get("current_index", -1)) == 31) and all_passed
	all_passed = _check("map view boss stop shows boss battle pending", bool(after_state.get("pending_boss_battle", false)) and bool(after_state.get("pending_battle", false))) and all_passed
	all_passed = _check("map view boss stop keeps final node as boss", after_nodes.size() == 32 and StringName(str(after_nodes[31].get("node_type", ""))) == &"boss") and all_passed
	if flow.get_run_state() != null:
		flow.get_run_state().set_current_encounter_node_type(&"boss")
		flow.get_run_state().advance_battle()
	flow.return_to_map_after_battle()
	var returned_state := flow.get_map_state()
	var returned_nodes: Array = returned_state.get("nodes", [])
	all_passed = _check("map view boss return moves to start node", int(returned_state.get("current_index", -1)) == 0) and all_passed
	all_passed = _check("map view boss return refreshes nodes", int(returned_state.get("refresh_count", 0)) == int(before_state.get("refresh_count", 0)) + 1) and all_passed
	all_passed = _check("map view boss return clears stale cleared flag", returned_nodes.size() > 4 and not bool(returned_nodes[4].get("is_cleared", true))) and all_passed
	flow.map_state_changed.emit(flow.get_map_state())
	await process_frame
	return all_passed


func _check_map_view_can_roll_one_selected_die(map_view: Node, flow: GameFlowController) -> bool:
	var roll_button := _find_texture_button(map_view, "RollMovementButton")
	if roll_button == null:
		return _check("one-die map roll button exists", false)
	map_view.call("_on_movement_die_pressed", 1)
	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var selected_indices: Array = snapshot.get("selected_movement_dice_indices", [])
	var all_passed := true
	all_passed = _check("map view can deselect one movement die", selected_indices.size() == 1 and int(selected_indices[0]) == 0) and all_passed
	var before_roll_count := int(flow.get_map_state().get("roll_count", 0))
	roll_button.pressed.emit()
	await create_timer(0.12).timeout
	var pending_snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var first_die := _find_node_by_name(map_view, "MovementDice_1")
	all_passed = _check("map view waits for dice reveal before movement roll resolves", int(flow.get_map_state().get("roll_count", 0)) == before_roll_count) and all_passed
	all_passed = _check("map view reports movement roll pending before result", bool(pending_snapshot.get("is_movement_roll_pending", false))) and all_passed
	all_passed = _check("map view keeps movement dice visually enabled while rolling", first_die is BaseButton and not (first_die as BaseButton).disabled) and all_passed
	await _wait_for_map_animation(map_view)
	var state := flow.get_map_state()
	var last_rolls: Array = state.get("last_rolls", [])
	var rolled_indices: Array = state.get("last_rolled_dice_indices", [])
	var node_count := int(state.get("nodes", []).size())
	all_passed = _check("map view one-die roll records one die", rolled_indices.size() == 1 and int(rolled_indices[0]) == 0) and all_passed
	all_passed = _check("map view one-die roll leaves second die empty", last_rolls.size() == 2 and int(last_rolls[1]) == 0) and all_passed
	all_passed = _check("map view one-die roll uses selected die as steps", last_rolls.size() == 2 and int(state.get("last_roll", 0)) == int(last_rolls[0])) and all_passed
	all_passed = _check("map view one-die roll moves by selected die", last_rolls.size() == 2 and node_count > 0 and int(state.get("current_index", 0)) == int(last_rolls[0]) % node_count) and all_passed
	all_passed = _check("map view one-die roll exposes danger action count", int(state.get("circle_action_count", 0)) == 1) and all_passed
	flow._reset_demo_map()
	if flow.get_run_state() != null:
		flow.get_run_state().reset_circle_pressure()
	flow.map_state_changed.emit(flow.get_map_state())
	await process_frame
	map_view.call("_on_movement_die_pressed", 1)
	return all_passed


func _wait_for_map_animation(map_view: Node) -> void:
	await process_frame
	var waited := 0.0
	while bool(map_view.get("is_marker_animating")) and waited < 7.0:
		await create_timer(0.1).timeout
		waited += 0.1


func _texture_exists(root_node: Node, node_name: String) -> bool:
	var node := _find_node_by_name(root_node, node_name)
	if node is TextureRect:
		return (node as TextureRect).texture != null
	return false


func _has_all_node_textures(map_view) -> bool:
	var art = map_view.art_config
	if art == null:
		return false
	return art.backdrop_texture != null \
		and art.start_node_texture != null \
		and art.battle_node_texture != null \
		and art.elite_node_texture != null \
		and art.boss_node_texture != null \
		and art.shop_node_texture != null \
		and art.forge_node_texture != null \
		and art.reward_node_texture != null \
		and art.penalty_node_texture != null \
		and art.event_node_texture != null \
		and art.rest_node_texture != null


func _rest_node_uses_generated_texture(map_view) -> bool:
	var art = map_view.art_config
	if art == null or art.rest_node_texture == null:
		return false
	var path := str(art.rest_node_texture.resource_path)
	return path.ends_with("node_rest_generated.png") and not path.contains("placeholder")


func _node_label_is_readable(map_view) -> bool:
	var art = map_view.art_config
	if art == null:
		return false
	var label := _find_node_by_name(map_view, "NodeLabel") as Label
	var background := _find_node_by_name(map_view, "NodeLabelBackground") as Panel
	return art.show_node_text_labels \
		and art.node_font_size >= 20 \
		and art.node_label_size.y >= 38.0 \
		and label != null \
		and label.visible \
		and not label.clip_text \
		and background != null \
		and background.visible


func _node_type_at(flow: GameFlowController, index: int) -> StringName:
	var nodes: Array = flow.get_map_state().get("nodes", [])
	if index < 0 or index >= nodes.size():
		return &""
	return StringName(str(nodes[index].get("node_type", "")))


func _player_marker_is_centered(map_view) -> bool:
	var marker := _find_node_by_name(map_view, "PlayerMarker") as Control
	if marker == null:
		return false
	var positions: Array = map_view.call("_route_positions", 32)
	if positions.is_empty():
		return false
	var art = map_view.art_config
	var expected: Vector2 = positions[0] - art.player_marker_size * 0.5 + art.player_marker_offset
	return marker.position.distance_to(expected) < 0.5


func _find_texture_button(root_node: Node, wrapper_name: String) -> TextureButton:
	var wrapper := _find_node_by_name(root_node, wrapper_name)
	if wrapper == null:
		return null
	return wrapper.get_node_or_null("ButtonTexture") as TextureButton


func _count_nodes_by_prefix(root_node: Node, prefix: String) -> int:
	var count := 0
	if root_node.name.begins_with(prefix):
		count += 1
	for child in root_node.get_children():
		count += _count_nodes_by_prefix(child, prefix)
	return count


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
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


func _is_two_d6_roll(values: Array) -> bool:
	if values.size() != 2:
		return false
	for value in values:
		var pip := int(value)
		if pip < 1 or pip > 6:
			return false
	return true
