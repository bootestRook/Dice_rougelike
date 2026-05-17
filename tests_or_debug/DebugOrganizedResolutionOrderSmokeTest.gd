extends SceneTree


var battle_screen: Node = null
var bench_area: Node = null
var scoring_area: Node = null
var controller = null
var expected_order: Array[int] = []
var step: int = 0
var wait_frames: int = 0


func _init() -> void:
	print("--- DebugOrganizedResolutionOrderSmokeTest: start ---")


func _process(_delta: float) -> bool:
	if step == 0:
		var scene: PackedScene = load("res://scenes/battle/BattleScreen.tscn")
		battle_screen = scene.instantiate()
		root.add_child(battle_screen)
		step = 1
		wait_frames = 0
		return false

	if step == 1:
		wait_frames += 1
		bench_area = _find_node_by_name(battle_screen, "DiceBenchArea")
		scoring_area = _find_node_by_name(battle_screen, "SegmentScoringArea")
		controller = battle_screen.get("controller")
		if (bench_area == null or scoring_area == null or controller == null) and wait_frames < 30:
			return false
		if bench_area == null or scoring_area == null or controller == null:
			print("FAIL: battle UI missing")
			quit(1)
			return true
		bench_area._on_organize_pressed()
		step = 2
		wait_frames = 0
		return false

	if step == 2:
		wait_frames += 1
		if bool(bench_area.get("is_sorting_dice")) and wait_frames < 90:
			return false
		if wait_frames < 40:
			return false

		for index in range(5):
			controller.toggle_select(index)
		var trace = controller.request_settle_selected({})
		if trace == null:
			print("FAIL: trace null")
			quit(1)
			return true
		expected_order = _expected_visual_selected_order(trace.selected_slot_indices)
		battle_screen.skip_resolution_animation()
		battle_screen.move_selected_dice_to_resolution_by_trace(trace)
		step = 3
		wait_frames = 0
		return false

	if step == 3:
		wait_frames += 1
		var current_order := _settlement_order()
		if (current_order.size() < expected_order.size() or not _all_settlement_slots_visible()) and wait_frames < 180:
			return false
		var passed := _same_int_order(current_order, expected_order)
		print("expected_order=%s" % [str(expected_order)])
		print("settlement_order=%s" % [str(current_order)])
		print("PASS: DebugOrganizedResolutionOrderSmokeTest" if passed else "FAIL: DebugOrganizedResolutionOrderSmokeTest")
		print("--- end ---")
		quit(0 if passed else 1)
		return true

	return false


func _expected_visual_selected_order(selected_slots: Array[int]) -> Array[int]:
	var selected_lookup: Dictionary = {}
	for slot_index in selected_slots:
		selected_lookup[int(slot_index)] = true

	var result: Array[int] = []
	for die_index in bench_area.get_display_die_order():
		if selected_lookup.has(die_index):
			result.append(die_index)
			selected_lookup.erase(die_index)
	for slot_index in selected_slots:
		var die_index := int(slot_index)
		if selected_lookup.has(die_index):
			result.append(die_index)
			selected_lookup.erase(die_index)
	return result


func _settlement_order() -> Array[int]:
	var order: Array[int] = []
	var slots := _find_node_by_name(scoring_area, "SettlementSlots")
	if slots == null:
		return order
	for child in slots.get_children():
		order.append(int(child.get_meta("die_index", -1)))
	return order


func _all_settlement_slots_visible() -> bool:
	var slots := _find_node_by_name(scoring_area, "SettlementSlots")
	if slots == null:
		return false
	for child in slots.get_children():
		if child is Control and (child as Control).modulate.a < 0.99:
			return false
	return slots.get_child_count() > 0


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
