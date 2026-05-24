extends SceneTree
class_name DebugBattleRewardFlowUiSmokeTest


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")


func _init() -> void:
	print("--- DebugBattleRewardFlowUiSmokeTest: start ---")

	var all_passed := true
	var flow := GameFlowController.new()
	root.add_child(flow)
	flow.start_new_run()

	var battle_screen = load("res://scenes/battle/BattleScreen.tscn").instantiate()
	battle_screen.setup(flow, flow.get_run_state(), true)
	root.add_child(battle_screen)
	await process_frame
	await process_frame

	var debug_choices := [
		_make_debug_piece(&"debug_pip_6", 6),
		_make_debug_piece(&"debug_pip_5", 5),
		_make_debug_piece(&"debug_pip_4", 4),
	]
	flow.reward_requested.connect(func(_choices: Array) -> void:
		flow.get_run_state().last_reward_choices = debug_choices
		battle_screen.show_reward_choices(debug_choices)
	)
	flow.forge_install_requested.connect(func(piece: ForgePieceDef) -> void:
		battle_screen.begin_reward_install(piece)
	)

	flow.on_battle_won()
	battle_screen.show_battle_coin_reward(flow.get_pending_battle_coin_reward_summary())
	await process_frame
	await process_frame

	var snapshot: Dictionary = battle_screen.automation_get_snapshot()
	all_passed = _check("coin reward phase is active", flow.current_state_id == &"battle_coin_reward") and all_passed
	all_passed = _check("coin reward overlay is visible", bool(snapshot.get("coin_reward_overlay_visible", false))) and all_passed
	all_passed = _check("coin reward title exists", _find_label_with_text(battle_screen, "金币奖励") != null) and all_passed
	all_passed = _check("coin reward clear row exists", _find_label_with_text(battle_screen, "通关奖励") != null) and all_passed
	all_passed = _check("coin reward continue button exists", _find_button_with_text(battle_screen, "继续") != null) and all_passed

	var continue_button := _find_button_with_text(battle_screen, "继续")
	if continue_button != null:
		continue_button.pressed.emit()
	await process_frame
	await process_frame

	snapshot = battle_screen.automation_get_snapshot()
	all_passed = _check("continue opens normal reward phase", flow.current_state_id == &"reward") and all_passed
	all_passed = _check("coin reward overlay is hidden after continue", not bool(snapshot.get("coin_reward_overlay_visible", true))) and all_passed
	all_passed = _check("normal reward title exists", _find_label_with_text(battle_screen, "常规奖励") != null) and all_passed
	all_passed = _check("normal reward cards show pick action", _find_label_with_text(battle_screen, "挑选") != null) and all_passed

	flow.choose_reward(debug_choices[0])
	await process_frame
	await process_frame
	snapshot = battle_screen.automation_get_snapshot()
	all_passed = _check("choosing normal reward enters install phase", flow.current_state_id == &"forge" and bool(snapshot.get("reward_install_active", false))) and all_passed

	await _cleanup_nodes_before_quit([battle_screen, flow])
	print("PASS: DebugBattleRewardFlowUiSmokeTest" if all_passed else "FAIL: DebugBattleRewardFlowUiSmokeTest")
	print("--- DebugBattleRewardFlowUiSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _make_debug_piece(id: StringName, pip: int) -> ForgePieceDef:
	var operation := ForgeOperationDef.new()
	operation.op = ForgeOperationDef.OP_SET_PIP
	operation.value_int = pip

	var piece := ForgePieceDef.new()
	piece.id = id
	piece.display_name = "%d 点片" % [pip]
	piece.description = "替换目标骰面的点数。"
	piece.operations = [operation]
	return piece


func _find_button_with_text(root_node: Node, text: String) -> Button:
	if root_node is Button and (root_node as Button).text == text:
		return root_node as Button
	for child in root_node.get_children():
		var result := _find_button_with_text(child, text)
		if result != null:
			return result
	return null


func _find_label_with_text(root_node: Node, text: String) -> Label:
	if root_node is Label and (root_node as Label).text == text:
		return root_node as Label
	for child in root_node.get_children():
		var result := _find_label_with_text(child, text)
		if result != null:
			return result
	return null


func _cleanup_nodes_before_quit(nodes: Array) -> void:
	await _flush_runtime_feedback(nodes)
	for node in nodes:
		if node != null and is_instance_valid(node):
			node.queue_free()
	for _index in range(8):
		await process_frame
	await physics_frame
	await process_frame


func _flush_runtime_feedback(nodes: Array) -> void:
	for node in nodes:
		if node == null or not is_instance_valid(node):
			continue
		var sidebar = node.get("left_sidebar")
		if sidebar != null and sidebar.has_method("automation_flush_runtime_feedback"):
			await sidebar.automation_flush_runtime_feedback()


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
