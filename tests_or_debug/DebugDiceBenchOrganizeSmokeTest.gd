extends SceneTree


var battle_screen: Node = null
var stage: Node = null
var controller = null


func _init() -> void:
	print("--- DebugDiceBenchOrganizeSmokeTest: start ---")

	var all_passed := true
	var scene: PackedScene = load("res://scenes/battle/BattleScreen.tscn")
	battle_screen = scene.instantiate()
	root.add_child(battle_screen)
	await process_frame
	await process_frame
	stage = _find_node_by_name(battle_screen, "FormalBattleDiceStage3D")
	controller = battle_screen.get("controller")
	await _wait_for_initial_3d_roll()

	all_passed = _check("正式战斗使用 3D 骰子整理区", stage != null) and all_passed
	if stage != null:
		stage.call("_on_organize_pressed")
		await process_frame
		var organized_order := _display_order()
		all_passed = _check("整理后显示顺序非空", not organized_order.is_empty()) and all_passed
		all_passed = _check("整理后按点数降序", _display_order_is_descending()) and all_passed
		all_passed = _check("整理后 3D 骰子位置按显示顺序重排", _same_int_order(_visual_order(), organized_order)) and all_passed
		all_passed = _check("organize_ready_slots_match_display_order", _ready_slots_match_order(organized_order)) and all_passed
		if controller != null and not organized_order.is_empty():
			var selected_slot_index := mini(2, organized_order.size() - 1)
			var selected_die_index := int(organized_order[selected_slot_index])
			controller.toggle_select(selected_die_index)
			await battle_screen.call("_play_reroll_magic")
			all_passed = _check("reroll_ready_return_target_matches_display_slot", _last_ready_return_target_matches(selected_die_index)) and all_passed
			all_passed = _check("unselected_hold_keeps_display_order", _last_unselected_hold_targets_follow_order([selected_die_index], organized_order)) and all_passed
			all_passed = _check("3D 重投后保留整理顺序", _same_int_order(_display_order(), organized_order)) and all_passed
			all_passed = _check("3D 重投后位置仍按整理顺序", _same_int_order(_visual_order(), organized_order)) and all_passed

	if battle_screen != null:
		battle_screen.queue_free()
	print("PASS: DebugDiceBenchOrganizeSmokeTest" if all_passed else "FAIL: DebugDiceBenchOrganizeSmokeTest")
	print("--- end ---")
	quit(0 if all_passed else 1)


func _wait_for_initial_3d_roll() -> void:
	for _index in range(720):
		if controller == null:
			return
		if controller.has_method("is_waiting_for_initial_roll_results") and not controller.is_waiting_for_initial_roll_results():
			return
		await physics_frame


func _display_order_is_descending() -> bool:
	var pips := _display_pips()
	if pips.size() <= 1:
		return true
	for index in range(1, pips.size()):
		if pips[index - 1] < pips[index]:
			return false
	return true


func _display_pips() -> Array[int]:
	var pips_by_die: Dictionary = {}
	var state = stage.get("current_state") if stage != null else null
	if state != null:
		for die_data in state.dice_results:
			if die_data != null and die_data.current_face != null:
				pips_by_die[die_data.die_index] = int(die_data.current_face.pip)

	var result: Array[int] = []
	for die_index in _display_order():
		result.append(int(pips_by_die.get(die_index, -1)))
	return result


func _display_order() -> Array[int]:
	if stage == null or not stage.has_method("get_display_die_order"):
		return []
	return stage.call("get_display_die_order")


func _visual_order() -> Array[int]:
	if stage == null or not stage.has_method("get_visual_die_order_left_to_right"):
		return []
	return stage.call("get_visual_die_order_left_to_right")


func _ready_slots_match_order(order: Array[int]) -> bool:
	if stage == null:
		return false
	var battle_mgr = stage.get("battle_mgr")
	if battle_mgr == null or not battle_mgr.has_method("get_ready_slot_for_die"):
		return false
	for visual_slot_index in range(order.size()):
		var die_index := int(order[visual_slot_index])
		var actual_slot := int(battle_mgr.call("get_ready_slot_for_die", die_index))
		if actual_slot != visual_slot_index:
			return false
	return true


func _last_ready_return_target_matches(die_index: int) -> bool:
	if stage == null:
		return false
	var battle_mgr = stage.get("battle_mgr")
	if battle_mgr == null or not battle_mgr.has_method("get_ready_position_for_die"):
		return false
	var snapshot: Dictionary = battle_mgr.get_snapshot()
	var dice_rows: Array = snapshot.get("dice", [])
	if die_index < 0 or die_index >= dice_rows.size() or not (dice_rows[die_index] is Dictionary):
		return false
	var row: Dictionary = dice_rows[die_index]
	var target: Vector3 = row.get("ready_return_target_position", Vector3.ZERO)
	var expected: Vector3 = battle_mgr.call("get_ready_position_for_die", die_index)
	return target.distance_to(expected) <= 0.02


func _last_unselected_hold_targets_follow_order(selected_indices: Array[int], display_order: Array[int]) -> bool:
	if stage == null:
		return false
	var battle_mgr = stage.get("battle_mgr")
	if battle_mgr == null:
		return false
	var snapshot: Dictionary = battle_mgr.get_snapshot()
	var dice_rows: Array = snapshot.get("dice", [])
	var rows: Array[Dictionary] = []
	for raw_die_index in display_order:
		var die_index := int(raw_die_index)
		if selected_indices.has(die_index):
			continue
		if die_index < 0 or die_index >= dice_rows.size() or not (dice_rows[die_index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[die_index]
		var hold_target: Vector3 = row.get("unselected_hold_target_position", Vector3.ZERO)
		rows.append({
			"die_index": die_index,
			"x": hold_target.x,
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ax := float(a.get("x", 0.0))
		var bx := float(b.get("x", 0.0))
		if is_equal_approx(ax, bx):
			return int(a.get("die_index", 0)) < int(b.get("die_index", 0))
		return ax < bx
	)
	var actual_order: Array[int] = []
	for row in rows:
		actual_order.append(int(row.get("die_index", -1)))
	var expected_order: Array[int] = []
	for die_index in display_order:
		if not selected_indices.has(int(die_index)):
			expected_order.append(int(die_index))
	return _same_int_order(actual_order, expected_order)


func _same_int_order(a: Array[int], b: Array[int]) -> bool:
	if a.size() != b.size():
		return false
	for index in range(a.size()):
		if a[index] != b[index]:
			return false
	return true


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
