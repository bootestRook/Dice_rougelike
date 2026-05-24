extends SceneTree
class_name DebugEliteVictoryFlowSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


func _init() -> void:
	print("--- DebugEliteVictoryFlowSmokeTest: start ---")

	var all_passed := true
	all_passed = _check("elite controller victory stops before next hand", _check_elite_controller_victory_stops()) and all_passed
	var ui_passed := await _check_3d_entry_restores_stale_victory_target()
	all_passed = _check("3D hand entry restores stale victory target", ui_passed) and all_passed

	await _cleanup_nodes_before_quit([])
	print("PASS: DebugEliteVictoryFlowSmokeTest" if all_passed else "FAIL: DebugEliteVictoryFlowSmokeTest")
	print("--- DebugEliteVictoryFlowSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_elite_controller_victory_stops() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.circle_base_scores[0] = 1
	run_state.set_current_encounter_node_type(RunState.ENCOUNTER_ELITE)

	var controller := BattleController.new()
	controller.roll_service.rng.seed = 20260524
	controller.start_battle(null, run_state)
	var target_is_elite := controller.get_target_score() == run_state.get_target_score(RunState.ENCOUNTER_ELITE)
	_select_first_count(controller, 5)
	controller.score_selected()

	var victory := controller.get_phase() == BattleController.BattlePhase.VICTORY
	var finished := controller.battle_state != null and controller.battle_state.battle_finished and controller.battle_state.victory
	var no_next_hand := controller.get_current_hand_number() == 1
	var score_reached := controller.get_total_score() >= controller.get_target_score()
	controller.free()
	return target_is_elite and victory and finished and no_next_hand and score_reached


func _check_3d_entry_restores_stale_victory_target() -> bool:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	root.add_child(battle_screen)

	await process_frame
	await process_frame
	await process_frame
	await _wait_for_initial_3d_roll(battle_screen)

	var sidebar = battle_screen.get("left_sidebar")
	if sidebar == null or not sidebar.has_method("play_battle_victory_target_feedback"):
		await _cleanup_nodes_before_quit([battle_screen])
		return false

	await sidebar.play_battle_victory_target_feedback()
	var active_before := bool(sidebar.is_battle_victory_target_active()) if sidebar.has_method("is_battle_victory_target_active") else false

	var elite_run := RunState.new()
	elite_run.setup_new_run()
	elite_run.set_current_encounter_node_type(RunState.ENCOUNTER_ELITE)
	battle_screen.call("start_battle_with_run_state", null, elite_run)
	await _wait_for_initial_3d_roll(battle_screen)
	await process_frame
	await process_frame

	var active_after := bool(sidebar.is_battle_victory_target_active()) if sidebar.has_method("is_battle_victory_target_active") else true
	var snapshot: Dictionary = battle_screen.call("automation_get_snapshot")
	var restored := active_before and not active_after
	var waiting_action := str(snapshot.get("phase", "")) == "WAITING_ACTION"
	var first_hand := int(snapshot.get("hand", 0)) == 1
	var elite_target := int(snapshot.get("target_score", 0)) == elite_run.get_target_score(RunState.ENCOUNTER_ELITE)

	await _cleanup_nodes_before_quit([battle_screen])
	return restored and waiting_action and first_hand and elite_target


func _select_first_count(controller: BattleController, count: int) -> void:
	var rolls := controller.get_current_rolls()
	for index in range(min(count, rolls.size())):
		if not rolls[index].selected:
			controller.toggle_select(index)


func _wait_for_initial_3d_roll(battle_screen: Node) -> void:
	var controller = battle_screen.get("controller")
	for _index in range(720):
		if controller == null:
			return
		if controller.has_method("is_waiting_for_initial_roll_results") and not controller.is_waiting_for_initial_roll_results():
			return
		await physics_frame


func _cleanup_nodes_before_quit(nodes: Array) -> void:
	await _flush_runtime_feedback(nodes)
	for node in nodes:
		if node != null and is_instance_valid(node):
			node.free()
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
