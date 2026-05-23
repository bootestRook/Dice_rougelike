extends SceneTree
class_name DebugRunFlowSmokeTest


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const BattleLogEntry = preload("res://scripts/log/BattleLogEntry.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


func _init() -> void:
	print("--- DebugRunFlowSmokeTest: start ---")

	var all_passed := true
	var flow := GameFlowController.new()
	flow.start_new_run()

	all_passed = _check("run_state exists after start_new_run", flow.get_run_state() != null) and all_passed
	all_passed = _check("start_new_run enters map phase", flow.current_state_id == &"map") and all_passed
	all_passed = _check("new run starts with 9999 coins", flow.get_run_state().coins == GameFlowController.STARTING_COINS and flow.get_run_state().coins == 9999) and all_passed
	all_passed = _check("demo map has 32 nodes", flow.get_map_state().get("nodes", []).size() == 32) and all_passed
	all_passed = _check("first circle keeps shops out before grid 15", _first_circle_shop_placement_is_protected(flow.get_map_state().get("nodes", []))) and all_passed
	all_passed = _check("map state exposes circle base score", int(flow.get_map_state().get("circle_base_score", 0)) == flow.get_run_state().get_current_circle_base_score()) and all_passed
	all_passed = _check("starting run has 6 dice", flow.get_run_state().dice.size() == 6) and all_passed
	all_passed = _check("battle_index starts at 0", flow.get_run_state().battle_index == 0) and all_passed
	all_passed = _check("new run starts on start node", int(flow.get_map_state().get("current_index", -1)) == 0) and all_passed
	all_passed = _check_one_die_map_roll() and all_passed
	all_passed = _check_map_movement_uses_first_two_formal_dice() and all_passed
	all_passed = _check_danger_target_formula() and all_passed
	all_passed = _check_circle_boss_final_rule() and all_passed
	all_passed = _check_map_reward_and_event_nodes() and all_passed
	all_passed = _check_map_boss_stop_and_return_refresh(flow) and all_passed

	var reached_battle_node := false
	for _attempt in range(8):
		var map_roll := flow.roll_map_movement()
		var roll_values: Array = map_roll.get("state", {}).get("last_rolls", [])
		all_passed = _check("map movement rolls two normal D6", _is_two_d6_roll(roll_values)) and all_passed
		all_passed = _check("map movement steps equal both dice", int(map_roll.get("steps", 0)) == int(roll_values[0]) + int(roll_values[1])) and all_passed
		if bool(map_roll.get("pending_battle", false)):
			reached_battle_node = true
			break
	all_passed = _check("map movement can reach a battle node", reached_battle_node) and all_passed
	all_passed = _check("enter battle from map switches to battle phase", reached_battle_node and flow.request_enter_battle_from_map() and flow.current_state_id == &"battle") and all_passed

	var coins_before_win := flow.get_run_state().coins
	flow.on_battle_won()
	var coin_summary := flow.get_pending_battle_coin_reward_summary()
	all_passed = _check("non-final win enters coin reward phase first", flow.current_state_id == &"battle_coin_reward") and all_passed
	all_passed = _check("coin reward grants clear coins before normal rewards", flow.get_run_state().coins >= coins_before_win + GameFlowController.BATTLE_CLEAR_COIN_REWARD) and all_passed
	all_passed = _check("coin reward summary includes battle clear reward", int(coin_summary.get("total", 0)) >= GameFlowController.BATTLE_CLEAR_COIN_REWARD) and all_passed
	all_passed = _check("normal rewards are not generated before continue", flow.get_run_state().last_reward_choices.is_empty()) and all_passed
	all_passed = _check("continue after coin reward opens normal reward phase", flow.continue_after_battle_coin_reward() and flow.current_state_id == &"reward") and all_passed
	all_passed = _check("non-final win generates 3 rewards after continue", flow.get_run_state().last_reward_choices.size() == 3) and all_passed

	var reward = flow.get_run_state().last_reward_choices[0]
	flow.choose_reward(reward)
	flow.install_pending_piece(0, 0)
	all_passed = _check("installed_piece_count increased", flow.get_run_state().installed_piece_count == 1) and all_passed
	all_passed = _check("installed_piece_history has record", flow.get_run_state().installed_piece_history.size() == 1) and all_passed
	all_passed = _check("battle_index advanced after install", flow.get_run_state().battle_index == 1) and all_passed
	all_passed = _check("after reward install returns to map phase", flow.current_state_id == &"map") and all_passed
	_record_sample_settlements(flow.get_run_state())
	all_passed = _check("recent settlement logs are capped at 5", flow.get_run_state().recent_settlement_logs.size() == 5) and all_passed
	all_passed = _check("oldest settlement log was trimmed", int(flow.get_run_state().recent_settlement_logs[0].get("hand", 0)) == 2) and all_passed
	all_passed = _check("best hand score records highest actual result", flow.get_run_state().best_hand_score == 105) and all_passed
	all_passed = _check("effect trigger counts accumulate", int(flow.get_run_state().effect_trigger_counts.get(&"ornament_burst", 0)) == 6) and all_passed

	flow.get_run_state().current_circle_index = flow.get_run_state().max_circles - 1
	flow.get_run_state().set_current_encounter_node_type(&"boss")
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


func _is_two_d6_roll(values: Array) -> bool:
	if values.size() != 2:
		return false
	for value in values:
		var pip := int(value)
		if pip < 1 or pip > 6:
			return false
	return true


func _check_one_die_map_roll() -> bool:
	var flow := GameFlowController.new()
	flow.start_new_run()
	var result := flow.roll_map_movement([0])
	var state: Dictionary = result.get("state", {})
	var roll_values: Array = state.get("last_rolls", [])
	var rolled_indices: Array = state.get("last_rolled_dice_indices", [])
	var all_passed := true
	all_passed = _check("map movement can roll one selected die", bool(result.get("success", false))) and all_passed
	all_passed = _check("one-die map roll records selected die index", rolled_indices.size() == 1 and int(rolled_indices[0]) == 0) and all_passed
	all_passed = _check("one-die map roll keeps two result slots", roll_values.size() == 2) and all_passed
	all_passed = _check("one-die map roll leaves unselected die empty", roll_values.size() == 2 and int(roll_values[1]) == 0) and all_passed
	all_passed = _check("one-die map roll result is normal D6", roll_values.size() == 2 and int(roll_values[0]) >= 1 and int(roll_values[0]) <= 6) and all_passed
	all_passed = _check("one-die map movement uses selected die only", int(result.get("steps", 0)) == int(roll_values[0])) and all_passed
	all_passed = _check("one-die map roll increases circle action count", int(state.get("circle_action_count", 0)) == 1) and all_passed
	flow.free()
	return all_passed


func _check_map_movement_uses_first_two_formal_dice() -> bool:
	var flow := GameFlowController.new()
	flow.start_new_run()
	var run_state := flow.get_run_state()
	_set_all_face_pips(run_state.dice[0], 6)
	_set_all_face_pips(run_state.dice[1], 4)
	_set_all_face_pips(run_state.dice[2], 1)

	var result := flow.roll_map_movement([0, 1])
	var state: Dictionary = result.get("state", {})
	var roll_values: Array = state.get("last_rolls", [])
	var face_indices: Array = state.get("last_roll_face_indices", [])
	var movement_face_counts: Array = state.get("movement_die_face_counts", [])
	var movement_dice := flow.get_map_movement_dice()

	var all_passed := true
	all_passed = _check("map movement exposes exactly two formal dice", movement_dice.size() == 2 and int(state.get("movement_dice_count", 0)) == 2) and all_passed
	all_passed = _check("map movement uses first formal die pips", roll_values.size() == 2 and int(roll_values[0]) == 6) and all_passed
	all_passed = _check("map movement uses second formal die pips", roll_values.size() == 2 and int(roll_values[1]) == 4) and all_passed
	all_passed = _check("map movement ignores third combat die", int(result.get("steps", 0)) == 10) and all_passed
	all_passed = _check("map movement records formal face indices", face_indices.size() == 2 and int(face_indices[0]) >= 0 and int(face_indices[1]) >= 0) and all_passed
	all_passed = _check("map movement exposes formal face counts", movement_face_counts.size() == 2 and int(movement_face_counts[0]) == 6 and int(movement_face_counts[1]) == 6) and all_passed
	flow.free()
	return all_passed


func _check_map_reward_and_event_nodes() -> bool:
	var reward_flow := GameFlowController.new()
	reward_flow.start_new_run()
	var reward_index := _first_node_index_of_type(reward_flow.get_map_state().get("nodes", []), &"reward")
	reward_flow.map_position_index = reward_index
	var reward_before_battle_index := reward_flow.get_run_state().battle_index
	var reward_entered := reward_flow.request_enter_reward_from_map()
	var reward_choices: Array = reward_flow.get_run_state().last_reward_choices
	var reward_choice = reward_choices[0] if not reward_choices.is_empty() else null
	reward_flow.choose_reward(reward_choice)
	var reward_state := reward_flow.get_map_state()
	var reward_nodes: Array = reward_state.get("nodes", [])

	var event_flow := GameFlowController.new()
	event_flow.start_new_run()
	var event_index := _first_node_index_of_type(event_flow.get_map_state().get("nodes", []), &"event")
	event_flow.map_position_index = event_index
	var event_entered := event_flow.request_enter_event_from_map()
	var event_choices: Array = event_flow.get_run_state().last_reward_choices
	var event_choice = event_choices[0] if not event_choices.is_empty() else null
	event_flow.choose_reward(event_choice)
	var event_item := event_flow.get_run_state().item_slots[0] if event_flow.get_run_state().item_slots.size() > 0 else null

	var all_passed := true
	all_passed = _check("map reward node enters direct reward phase", reward_index >= 0 and reward_entered and reward_flow.current_state_id == &"map") and all_passed
	all_passed = _check("map reward node grants item without advancing battle index", reward_flow.get_run_state().item_slots.size() == 1 and reward_flow.get_run_state().battle_index == reward_before_battle_index) and all_passed
	all_passed = _check("map reward node is cleared after choice", reward_nodes.size() > reward_index and bool(reward_nodes[reward_index].get("is_cleared", false))) and all_passed
	all_passed = _check("map event node grants dice-tool item reward", event_index >= 0 and event_entered and event_flow.current_state_id == &"map" and event_item != null and event_item.item_type == ItemInstance.TYPE_DICE_TOOL) and all_passed
	reward_flow.free()
	event_flow.free()
	return all_passed


func _set_all_face_pips(die, pip: int) -> void:
	if die == null:
		return
	for face in die.faces:
		if face != null:
			face.pip = pip


func _check_map_boss_stop_and_return_refresh(flow: GameFlowController) -> bool:
	flow.map_position_index = 30
	if flow.map_nodes.size() > 3:
		flow.map_nodes[3]["is_cleared"] = true
	var result := flow.roll_map_movement()
	var after_state := flow.get_map_state()
	var after_nodes: Array = after_state.get("nodes", [])
	var all_passed := true
	all_passed = _check("map stops on final boss node before start", bool(result.get("stopped_by_boss", false)) and int(after_state.get("current_index", -1)) == 31) and all_passed
	all_passed = _check("map boss stop truncates remaining movement", int(result.get("actual_steps", 0)) == 1) and all_passed
	all_passed = _check("map boss node requires battle", bool(after_state.get("pending_battle", false)) and bool(after_state.get("pending_boss_battle", false))) and all_passed
	all_passed = _check("map boss stop does not refresh before battle", int(after_state.get("refresh_count", 0)) == 0) and all_passed
	all_passed = _check("boss-triggering movement counts for danger", int(after_state.get("circle_action_count", 0)) == 1) and all_passed
	flow.get_run_state().set_current_encounter_node_type(&"boss")
	flow.get_run_state().advance_battle()
	flow.return_to_map_after_battle()
	var returned_state := flow.get_map_state()
	var returned_nodes: Array = returned_state.get("nodes", [])
	all_passed = _check("boss battle return moves player to start node", int(returned_state.get("current_index", -1)) == 0) and all_passed
	all_passed = _check("boss battle return refreshes map", int(returned_state.get("refresh_count", 0)) == 1) and all_passed
	all_passed = _check("boss battle return clears old cleared flags", returned_nodes.size() > 3 and not bool(returned_nodes[3].get("is_cleared", true))) and all_passed
	all_passed = _check("refreshed boss map keeps 32 nodes", returned_nodes.size() == 32) and all_passed
	all_passed = _check("refreshed boss map follows node bag counts", _map_node_bag_is_valid(returned_nodes)) and all_passed
	all_passed = _check("boss battle return advances circle", flow.get_run_state().get_circle_number() == 2) and all_passed
	all_passed = _check("boss battle return clears danger", int(returned_state.get("circle_action_count", -1)) == 0 and int(returned_state.get("danger_bonus_percent", -1)) == 0) and all_passed
	flow.start_new_run()
	return all_passed


func _map_node_bag_is_valid(nodes: Array) -> bool:
	if nodes.size() != 32:
		return false
	var counts := {}
	for node in nodes:
		var type_id := StringName(str(node.get("node_type", "")))
		counts[type_id] = int(counts.get(type_id, 0)) + 1
	if int(counts.get(&"start", 0)) != 1:
		return false
	if int(counts.get(&"boss", 0)) != 1:
		return false
	if int(counts.get(&"battle", 0)) != 10:
		return false
	if int(counts.get(&"elite", 0)) != 2:
		return false
	if int(counts.get(&"shop", 0)) != 3:
		return false
	if int(counts.get(&"forge", 0)) != 2:
		return false
	if int(counts.get(&"reward", 0)) != 5:
		return false
	if int(counts.get(&"event", 0)) != 4:
		return false
	if int(counts.get(&"penalty", 0)) != 2:
		return false
	if int(counts.get(&"rest", 0)) != 2:
		return false
	if StringName(str(nodes[0].get("node_type", ""))) != &"start":
		return false
	if StringName(str(nodes[nodes.size() - 1].get("node_type", ""))) != &"boss":
		return false
	return _map_spacing_is_valid(nodes)


func _first_circle_shop_placement_is_protected(nodes: Array) -> bool:
	if nodes.size() != 32:
		return false
	if StringName(str(nodes[0].get("node_type", ""))) != &"start":
		return false
	if StringName(str(nodes[nodes.size() - 1].get("node_type", ""))) != &"boss":
		return false
	var shop_count := 0
	for index in range(1, nodes.size() - 1):
		var node_type := StringName(str(nodes[index].get("node_type", "")))
		if index < GameFlowController.FIRST_CIRCLE_FIRST_SHOP_INDEX and node_type == &"shop":
			return false
		if node_type == &"shop":
			shop_count += 1
			if shop_count == 1 and index != GameFlowController.FIRST_CIRCLE_FIRST_SHOP_INDEX:
				return false
	return shop_count == 3


func _first_node_index_of_type(nodes: Array, node_type: StringName) -> int:
	for index in range(nodes.size()):
		var node: Dictionary = nodes[index]
		if StringName(str(node.get("node_type", ""))) == node_type:
			return index
	return -1


func _map_spacing_is_valid(nodes: Array) -> bool:
	for index in range(nodes.size()):
		var type_id := StringName(str(nodes[index].get("node_type", "")))
		if type_id == &"penalty":
			if index <= 2:
				return false
			if index > 0 and StringName(str(nodes[index - 1].get("node_type", ""))) == &"penalty":
				return false
			if index + 1 < nodes.size() and StringName(str(nodes[index + 1].get("node_type", ""))) == &"penalty":
				return false
			if index > 0 and StringName(str(nodes[index - 1].get("node_type", ""))) == &"elite":
				return false
			if index + 1 < nodes.size() and StringName(str(nodes[index + 1].get("node_type", ""))) == &"elite":
				return false
	return true


func _check_danger_target_formula() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()

	var all_passed := true
	var expected_danger := {
		1: 0,
		2: 2,
		3: 4,
		4: 7,
		5: 10,
		6: 15,
		7: 21,
		8: 28,
		9: 36,
		10: 45,
		11: 55,
		12: 65,
		13: 65,
	}
	all_passed = _check("run has 8 circles", run_state.max_circles == 8) and all_passed
	all_passed = _check("circle 4 base score is 1000", run_state.circle_base_scores[3] == 1000) and all_passed
	for action_count in expected_danger.keys():
		all_passed = _check(
			"action %d danger bonus == %d%%" % [action_count, int(expected_danger[action_count])],
			run_state.get_danger_bonus_percent(action_count) == int(expected_danger[action_count])
		) and all_passed

	run_state.current_circle_index = 3
	run_state.current_circle_action_count = 8
	all_passed = _check("circle 4 adjusted base score uses danger", run_state.get_current_circle_adjusted_base_score() == 1280) and all_passed
	all_passed = _check("circle 4 normal target uses danger", run_state.get_target_score(&"battle") == 1280) and all_passed
	all_passed = _check("circle 4 elite target uses 1.5x and danger", run_state.get_target_score(&"elite") == 1920) and all_passed
	all_passed = _check("circle 4 boss target uses 2x and danger", run_state.get_target_score(&"boss") == 2560) and all_passed
	var breakdown := run_state.get_target_breakdown(&"elite")
	all_passed = _check("target breakdown exposes danger fields", int(breakdown.get("action_count", 0)) == 8 and int(breakdown.get("danger_bonus_percent", 0)) == 28) and all_passed
	return all_passed


func _check_circle_boss_final_rule() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()

	var all_passed := true
	run_state.set_current_encounter_node_type(&"battle")
	all_passed = _check("battle node is not boss", not run_state.is_boss_battle()) and all_passed
	run_state.set_current_encounter_node_type(&"elite")
	all_passed = _check("elite node is not boss", not run_state.is_boss_battle()) and all_passed
	run_state.set_current_encounter_node_type(&"boss")
	all_passed = _check("boss node sets boss flag", run_state.is_boss_battle()) and all_passed
	all_passed = _check("boss before final circle is not final battle", not run_state.is_final_battle()) and all_passed
	run_state.current_circle_index = run_state.max_circles - 1
	all_passed = _check("boss on circle 8 is final battle", run_state.is_final_battle()) and all_passed
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
