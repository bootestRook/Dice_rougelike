extends SceneTree


var battle_screen: Node = null
var bench_area: Node = null
var controller = null
var organized_order: Array[int] = []
var organized_order_was_descending: bool = false
var step: int = 0
var wait_frames: int = 0


func _init() -> void:
	print("--- DebugDiceBenchOrganizeSmokeTest: start ---")


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
		controller = battle_screen.get("controller")
		if (bench_area == null or controller == null) and wait_frames < 30:
			return false
		if bench_area == null or controller == null:
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
		organized_order_was_descending = _display_order_is_descending()
		organized_order = _display_order()
		if organized_order.is_empty():
			print("FAIL: organized order empty")
			quit(1)
			return true
		controller.toggle_select(organized_order[0])
		controller.reroll()
		step = 3
		wait_frames = 0
		return false

	if step == 3:
		wait_frames += 1
		if wait_frames < 6:
			return false
		var reroll_kept_order := _same_int_order(_display_order(), organized_order)
		var passed := organized_order_was_descending and reroll_kept_order
		print("display_order=%s" % [str(_display_order())])
		print("display_pips=%s" % [str(_display_pips())])
		print("organized_order=%s" % [str(organized_order)])
		print("organized_order_was_descending=%s" % [str(organized_order_was_descending)])
		print("reroll_kept_order=%s" % [str(reroll_kept_order)])
		print("PASS: DebugDiceBenchOrganizeSmokeTest" if passed else "FAIL: DebugDiceBenchOrganizeSmokeTest")
		print("--- end ---")
		quit(0 if passed else 1)
		return true

	return false


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
	var state = bench_area.get("current_state")
	if state != null:
		for die_data in state.dice_results:
			if die_data != null and die_data.current_face != null:
				pips_by_die[die_data.die_index] = int(die_data.current_face.pip)

	var result: Array[int] = []
	for die_index in _display_order():
		result.append(int(pips_by_die.get(die_index, -1)))
	return result


func _display_order() -> Array[int]:
	var order: Array[int] = []
	var dice_row := _find_node_by_name(bench_area, "DiceRow")
	if dice_row == null:
		return order
	for child in dice_row.get_children():
		order.append(int(child.get_meta("die_index", -1)))
	return order


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
