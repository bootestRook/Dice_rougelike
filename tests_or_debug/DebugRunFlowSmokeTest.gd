extends SceneTree
class_name DebugRunFlowSmokeTest


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const BattleLogEntry = preload("res://scripts/log/BattleLogEntry.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


func _init() -> void:
	print("--- DebugRunFlowSmokeTest: start ---")

	var all_passed := true
	var flow := GameFlowController.new()
	flow.start_new_run()

	all_passed = _check("run_state exists after start_new_run", flow.get_run_state() != null) and all_passed
	all_passed = _check("starting run has 6 dice", flow.get_run_state().dice.size() == 6) and all_passed
	all_passed = _check("battle_index starts at 0", flow.get_run_state().battle_index == 0) and all_passed
	all_passed = _check_target_curve() and all_passed
	all_passed = _check_boss_schedule() and all_passed

	flow.on_battle_won()
	all_passed = _check("non-final win generates 3 rewards", flow.get_run_state().last_reward_choices.size() == 3) and all_passed

	var reward = flow.get_run_state().last_reward_choices[0]
	flow.choose_reward(reward)
	flow.install_pending_piece(0, 0)
	all_passed = _check("installed_piece_count increased", flow.get_run_state().installed_piece_count == 1) and all_passed
	all_passed = _check("installed_piece_history has record", flow.get_run_state().installed_piece_history.size() == 1) and all_passed
	all_passed = _check("battle_index advanced after install", flow.get_run_state().battle_index == 1) and all_passed
	_record_sample_settlements(flow.get_run_state())
	all_passed = _check("recent settlement logs are capped at 5", flow.get_run_state().recent_settlement_logs.size() == 5) and all_passed
	all_passed = _check("oldest settlement log was trimmed", int(flow.get_run_state().recent_settlement_logs[0].get("hand", 0)) == 2) and all_passed
	all_passed = _check("best hand score records highest actual result", flow.get_run_state().best_hand_score == 105) and all_passed
	all_passed = _check("effect trigger counts accumulate", int(flow.get_run_state().effect_trigger_counts.get(&"ornament_burst", 0)) == 6) and all_passed

	flow.get_run_state().battle_index = flow.get_run_state().max_battles - 1
	flow.on_battle_won()
	all_passed = _check("final battle win marks run_won", flow.get_run_state().run_won) and all_passed
	all_passed = _check("final battle win does not keep normal rewards", flow.get_run_state().last_reward_choices.is_empty()) and all_passed

	flow.start_new_run()
	flow.on_battle_lost()
	all_passed = _check("battle loss marks run_lost", flow.get_run_state().run_lost) and all_passed

	if all_passed:
		print("PASS: DebugRunFlowSmokeTest")
	else:
		print("FAIL: DebugRunFlowSmokeTest")

	flow.free()
	print("--- DebugRunFlowSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed


func _check_target_curve() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()

	var expected_scores: Array[int] = [
		300,
		450,
		600,
		800,
		1200,
		1600,
		2000,
		3000,
		4000,
		5000,
		7500,
		10000,
		11000,
		16500,
		22000,
		20000,
		30000,
		40000,
		35000,
		52500,
		70000,
		50000,
		75000,
		100000,
	]
	var all_passed := true
	all_passed = _check("run has 24 battles", run_state.max_battles == expected_scores.size()) and all_passed
	for index in range(expected_scores.size()):
		if index > 0:
			run_state.advance_battle()
		all_passed = _check(
			"battle %d target_score == %d" % [index + 1, expected_scores[index]],
			run_state.get_target_score() == expected_scores[index]
		) and all_passed
	return all_passed


func _check_boss_schedule() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()

	var boss_battles := [3, 6, 9, 12, 15, 18, 21, 24]
	var all_passed := true
	for index in range(run_state.max_battles):
		run_state.battle_index = index
		var battle_number := index + 1
		var expected_boss := boss_battles.has(battle_number)
		all_passed = _check(
			"battle %d boss flag == %s" % [battle_number, str(expected_boss)],
			run_state.is_boss_battle() == expected_boss
		) and all_passed
	return all_passed


func _record_sample_settlements(run_state: RunState) -> void:
	for index in range(6):
		var result := ScoreResult.new()
		result.final_score = 100 + index
		result.add_log(BattleLogEntry.new(&"LOG.ORNAMENT_BURST", {
			"die": 1,
			"face": 1,
			"ornament": "爆裂面饰",
			"xmult": "2",
		}, &"ornament_burst"))
		run_state.record_hand_score(result, index + 1)
