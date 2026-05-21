extends SceneTree


var battle_screen: Node = null
var bench_area: Node = null
var scoring_area: Node = null
var controller = null
var unselected_index: int = -1
var step: int = 0
var wait_frames: int = 0


func _init() -> void:
	print("--- DebugUnselectedDiceVisibleDuringResolutionSmokeTest: start ---")


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
		bench_area = _find_node_by_name(battle_screen, "FormalBattleDiceStage3D")
		scoring_area = bench_area
		controller = battle_screen.get("controller")
		if (bench_area == null or scoring_area == null or controller == null) and wait_frames < 30:
			return false
		if bench_area == null or scoring_area == null or controller == null:
			print("FAIL: battle UI missing")
			quit(1)
			return true
		if controller.has_method("is_waiting_for_initial_roll_results") and controller.is_waiting_for_initial_roll_results():
			if wait_frames < 5000:
				return false
			print("FAIL: initial 3D roll timeout")
			quit(1)
			return true
		bench_area.call("_on_organize_pressed")
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
		unselected_index = 5
		var trace = controller.request_settle_selected({})
		if trace == null:
			print("FAIL: trace null")
			quit(1)
			return true
		battle_screen.skip_resolution_animation()
		battle_screen.set("active_resolution_trace", trace)
		battle_screen.set("is_resolution_playing", true)
		battle_screen.set("battle_ui_state", 3)
		battle_screen._refresh_hud()
		battle_screen.move_selected_dice_to_resolution_by_trace(trace)
		step = 3
		wait_frames = 0
		return false

	if step == 3:
		wait_frames += 1
		if wait_frames < 20:
			return false
		var visible := _unselected_die_is_visible()
		var no_2d_clone := _find_die_view(battle_screen) == null
		print("unselected_index=%d" % [unselected_index])
		print("unselected_visible=%s" % [str(visible)])
		print("no_2d_clone=%s" % [str(no_2d_clone)])
		print("PASS: DebugUnselectedDiceVisibleDuringResolutionSmokeTest" if visible and no_2d_clone else "FAIL: DebugUnselectedDiceVisibleDuringResolutionSmokeTest")
		print("--- end ---")
		quit(0 if visible and no_2d_clone else 1)
		return true

	return false


func _unselected_die_is_visible() -> bool:
	var battle_mgr = bench_area.get("battle_mgr")
	if battle_mgr == null:
		return false
	if unselected_index < 0 or unselected_index >= battle_mgr.using_dices.size():
		return false
	var instance = battle_mgr.using_dices[unselected_index]
	if instance == null or instance.avatar == null:
		return false
	return bool(instance.avatar.visible)


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


func _find_die_view(root_node: Node) -> Control:
	if root_node is DiceView:
		return root_node as DiceView
	for child in root_node.get_children():
		var result := _find_die_view(child)
		if result != null:
			return result
	return null
