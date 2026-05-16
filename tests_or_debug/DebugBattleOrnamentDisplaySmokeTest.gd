extends SceneTree
class_name DebugBattleOrnamentDisplaySmokeTest


const RunState = preload("res://scripts/core/battle/RunState.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")


func _init() -> void:
	print("--- DebugBattleOrnamentDisplaySmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.dice[0].faces[0].ornament_id = &"orn_burst"
	run_state.dice[0].faces[0].mark_id = &"red"

	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	battle_screen.setup(null, run_state)
	root.add_child(battle_screen)

	await process_frame
	await process_frame
	await process_frame

	var bench = battle_screen.get("dice_bench_area")
	if bench != null:
		bench.show_info_for_die(0)
	await process_frame
	await process_frame
	await process_frame

	var popup_text := _collect_visible_text(battle_screen)
	all_passed = _check("ornament link reaches info popup", popup_text.contains("ornament:orn_burst")) and all_passed
	all_passed = _check("mark link reaches info popup", popup_text.contains("mark:red")) and all_passed

	battle_screen.queue_free()

	var flow := GameFlowController.new()
	root.add_child(flow)
	flow.start_new_run()
	var installed_state: RunState = flow.get_run_state()
	installed_state.pending_forge_piece = _make_ornament_piece(&"orn_burst")
	flow.install_pending_piece(0, 0)
	await process_frame

	var installed_battle_screen = scene.instantiate()
	installed_battle_screen.setup(null, installed_state)
	root.add_child(installed_battle_screen)
	await process_frame
	await process_frame
	await process_frame

	var installed_bench = installed_battle_screen.get("dice_bench_area")
	if installed_bench != null:
		installed_bench.show_info_for_die(0)
	await process_frame
	await process_frame
	await process_frame

	var installed_popup_text := _collect_visible_text(installed_battle_screen)
	all_passed = _check("installed ornament stays on run die", installed_state.dice[0].faces[0].ornament_id == &"orn_burst") and all_passed
	all_passed = _check("installed ornament link reaches battle info popup", installed_popup_text.contains("ornament:orn_burst")) and all_passed

	installed_battle_screen.queue_free()
	flow.queue_free()
	print("PASS: DebugBattleOrnamentDisplaySmokeTest" if all_passed else "FAIL: DebugBattleOrnamentDisplaySmokeTest")
	print("--- DebugBattleOrnamentDisplaySmokeTest: end ---")
	quit(0 if all_passed else 1)


func _make_ornament_piece(ornament_id: StringName) -> ForgePieceDef:
	var operation := ForgeOperationDef.new()
	operation.op = ForgeOperationDef.OP_SET_ORNAMENT
	operation.value_id = ornament_id

	var piece := ForgePieceDef.new()
	piece.id = &"debug_ornament"
	piece.display_name = "Debug Ornament"
	piece.operations = [operation]
	return piece


func _collect_visible_text(root_node: Node) -> String:
	var lines: Array[String] = []
	_collect_visible_text_recursive(root_node, lines)
	return "\n".join(lines)


func _collect_visible_text_recursive(root_node: Node, lines: Array[String]) -> void:
	if root_node is CanvasItem and not (root_node as CanvasItem).visible:
		return
	if root_node is Label:
		lines.append((root_node as Label).text)
	elif root_node is RichTextLabel:
		lines.append((root_node as RichTextLabel).text)
	for child in root_node.get_children():
		_collect_visible_text_recursive(child, lines)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
