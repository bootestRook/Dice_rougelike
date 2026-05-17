extends SceneTree


var battle_screen: Node = null
var bench_area: Node = null
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
		if bench_area == null and wait_frames < 30:
			return false
		if bench_area == null:
			print("FAIL: DiceBenchArea missing")
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
		var passed := _display_order_is_descending()
		print("display_order=%s" % [str(_display_order())])
		print("display_pips=%s" % [str(_display_pips())])
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
