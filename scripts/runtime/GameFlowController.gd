extends Node
class_name GameFlowController


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const DiceToolService = preload("res://scripts/rules/dice_tools/DiceToolService.gd")
const ForgeService = preload("res://scripts/rules/forge/ForgeService.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ShopService = preload("res://scripts/rules/shop/ShopService.gd")

signal flow_state_changed(state_id: StringName)
signal run_started(run_state: RunState)
signal map_requested(map_state: Dictionary)
signal map_state_changed(map_state: Dictionary)
signal map_movement_settled(map_state: Dictionary)
signal battle_requested(run_state: RunState)
signal reward_requested(choices: Array)
signal forge_install_requested(piece: ForgePieceDef)
signal shop_requested(shop_state: Dictionary)
signal booster_pack_opened(open_result: Dictionary)
signal run_result_requested(run_state: RunState)
signal run_state_changed(run_state: RunState)


var current_state_id: StringName = &"boot"
var run_state: RunState = null
var dice_tool_service := DiceToolService.new()
var reward_generator := RewardGenerator.new()
var forge_service := ForgeService.new()
var shop_service := ShopService.new()
var map_nodes: Array[Dictionary] = []
var map_position_index: int = 0
var map_last_roll: int = 0
var map_last_rolls: Array[int] = []
var map_last_rolled_dice_indices: Array[int] = []
var map_last_path: Array[int] = []
var map_last_refresh_path_index: int = -1
var map_last_stopped_by_boss: bool = false
var map_pending_battle: bool = false
var map_roll_count: int = 0
var map_refresh_count: int = 0
var map_rng := RandomNumberGenerator.new()


func set_flow_state(state_id: StringName) -> void:
	current_state_id = state_id
	flow_state_changed.emit(current_state_id)


func start_new_run() -> void:
	run_state = RunState.new()
	run_state.setup_new_run()
	_reset_demo_map()
	set_flow_state(&"map")
	run_started.emit(run_state)
	run_state_changed.emit(run_state)
	map_requested.emit(get_map_state())


func start_next_battle() -> void:
	if run_state == null:
		start_new_run()
		return

	run_state.ensure_starting_dice()
	if _is_battle_map_node_type(_current_map_node_type()):
		run_state.set_current_encounter_node_type(_current_map_node_type())
	map_pending_battle = false
	set_flow_state(&"battle")
	map_state_changed.emit(get_map_state())
	battle_requested.emit(run_state)


func on_battle_won() -> void:
	if run_state == null:
		push_warning("GameFlowController.on_battle_won without run_state.")
		return

	if run_state.is_final_battle():
		run_state.mark_run_won()
		set_flow_state(&"run_victory")
		run_state_changed.emit(run_state)
		run_result_requested.emit(run_state)
		return

	var choices := reward_generator.generate_forge_choices(3, run_state.battle_index)
	run_state.last_reward_choices = choices
	set_flow_state(&"reward")
	run_state_changed.emit(run_state)
	reward_requested.emit(choices)


func on_battle_lost() -> void:
	if run_state == null:
		return

	run_state.mark_run_lost()
	set_flow_state(&"run_defeat")
	run_state_changed.emit(run_state)
	run_result_requested.emit(run_state)


func choose_reward(reward) -> void:
	if run_state == null:
		push_warning("GameFlowController.choose_reward without run_state.")
		return
	var piece := reward as ForgePieceDef
	if piece == null:
		if _choose_direct_item_reward(reward):
			return
		push_warning("GameFlowController.choose_reward called with unsupported reward.")
		return

	if run_state.apply_combo_upgrade_piece(piece):
		run_state.last_reward_choices.clear()
		run_state.pending_forge_piece = null
		run_state.advance_battle()
		run_state_changed.emit(run_state)
		return_to_map_after_battle()
		return

	run_state.pending_forge_piece = piece
	set_flow_state(&"forge")
	run_state_changed.emit(run_state)
	forge_install_requested.emit(piece)


func _choose_direct_item_reward(reward) -> bool:
	var item_id := _reward_item_id(reward)
	if item_id == &"":
		return false
	if not run_state.add_item_to_inventory_or_pending(item_id):
		push_warning("GameFlowController.choose_reward could not add item reward: %s" % [str(item_id)])
		return false
	run_state.last_reward_choices.clear()
	run_state.pending_forge_piece = null
	run_state.advance_battle()
	run_state_changed.emit(run_state)
	return_to_map_after_battle()
	return true


func _reward_item_id(reward) -> StringName:
	if reward is StringName:
		return reward
	if reward is String:
		return StringName(reward)
	var object := reward as Object
	if object == null:
		return &""
	for property in object.get_property_list():
		if str(property.get("name", "")) != "id":
			continue
		var raw_id = object.get("id")
		if raw_id == null:
			return &""
		return StringName(str(raw_id))
	return &""


func install_pending_piece(die_index: int, face_index: int) -> bool:
	if run_state == null:
		push_warning("GameFlowController.install_pending_piece without run_state.")
		return false
	if run_state.pending_forge_piece == null:
		push_warning("GameFlowController.install_pending_piece without pending piece.")
		return false
	if die_index < 0 or die_index >= run_state.dice.size():
		push_warning("GameFlowController.install_pending_piece die_index out of range: %d" % [die_index])
		return false

	var piece := run_state.pending_forge_piece
	if not forge_service.can_apply_piece(piece, run_state.dice[die_index], face_index):
		push_warning("GameFlowController.install_pending_piece cannot apply piece.")
		return false

	var before_face = null
	if face_index >= 0 and face_index < run_state.dice[die_index].faces.size():
		before_face = run_state.dice[die_index].faces[face_index].clone()
	forge_service.apply_piece(piece, run_state.dice[die_index], face_index)
	if before_face != null and face_index >= 0 and face_index < run_state.dice[die_index].faces.size():
		dice_tool_service.on_face_changed(run_state, before_face, run_state.dice[die_index].faces[face_index], &"forge_piece")
	run_state.record_installed_piece(piece, die_index, face_index)
	run_state.pending_forge_piece = null
	run_state.last_reward_choices.clear()
	run_state.advance_battle()
	run_state_changed.emit(run_state)
	return_to_map_after_battle()
	return true


func apply_pending_dice_tool_face_copy(die_index: int, face_index: int) -> Dictionary:
	if run_state == null:
		return {"success": false, "reason": "当前没有局内状态。"}
	var result := dice_tool_service.apply_pending_face_copy(run_state, {
		"die_index": die_index,
		"face_index": face_index,
	})
	if bool(result.get("success", false)):
		run_state_changed.emit(run_state)
	return result


func record_hand_score(score_or_result, hand_number: int = 0) -> void:
	if run_state == null:
		return

	run_state.record_hand_score(score_or_result, hand_number)
	run_state_changed.emit(run_state)


func back_to_main() -> void:
	set_flow_state(&"main")


func get_run_state() -> RunState:
	return run_state


func enter_battle() -> void:
	start_next_battle()


func enter_reward() -> void:
	on_battle_won()


func enter_forge() -> void:
	set_flow_state(&"forge")


func enter_shop() -> Dictionary:
	if run_state == null:
		start_new_run()
		return {}
	var shop_state := shop_service.generate_shop(run_state)
	set_flow_state(&"shop")
	run_state_changed.emit(run_state)
	shop_requested.emit(shop_state)
	return shop_state


func reroll_shop_random_items() -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var result := shop_service.reroll_random_shop_items(run_state)
	run_state_changed.emit(run_state)
	if bool(result.get("success", false)):
		shop_requested.emit(run_state.current_shop_state)
	return result


func purchase_shop_offer_by_slot(slot_group: StringName, index: int = 0) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var result := shop_service.purchase_offer_by_slot(run_state, slot_group, index)
	run_state_changed.emit(run_state)
	if bool(result.get("success", false)) and result.has("candidate_offers"):
		booster_pack_opened.emit(result)
	return result


func get_map_state() -> Dictionary:
	return {
		"phase": current_state_id,
		"nodes": _map_nodes_for_view(),
		"current_index": map_position_index,
		"last_roll": map_last_roll,
		"last_rolls": map_last_rolls.duplicate(),
		"last_rolled_dice_indices": map_last_rolled_dice_indices.duplicate(),
		"last_path": map_last_path.duplicate(),
		"last_refresh_path_index": map_last_refresh_path_index,
		"stopped_by_boss": map_last_stopped_by_boss,
		"pending_battle": map_pending_battle,
		"pending_boss_battle": _is_boss_map_node_type(_current_map_node_type()),
		"roll_count": map_roll_count,
		"refresh_count": map_refresh_count,
		"circle": run_state.get_circle_number() if run_state != null else 1,
		"max_circles": run_state.max_circles if run_state != null else 8,
		"circle_base_score": run_state.get_current_circle_base_score() if run_state != null else 0,
		"circle_action_count": run_state.current_circle_action_count if run_state != null else 0,
		"danger_bonus_percent": run_state.get_danger_bonus_percent() if run_state != null else 0,
		"danger_multiplier": run_state.get_danger_multiplier() if run_state != null else 1.0,
		"current_node_target_score": _current_map_node_target_score(),
		"movement_dice_count": 2,
		"movement_die_face_count": 6,
	}


func roll_map_movement(selected_dice_indices: Array = [0, 1]) -> Dictionary:
	if current_state_id != &"map":
		return {
			"success": false,
			"message": "当前不在地图阶段。",
			"state": get_map_state(),
		}
	if map_nodes.is_empty():
		_reset_demo_map()

	var rolled_indices := _normalize_map_movement_dice_indices(selected_dice_indices)
	var rolls := _roll_map_movement_dice(rolled_indices)
	return _apply_map_movement_rolls(rolled_indices, rolls)


func prepare_map_movement_roll(selected_dice_indices: Array = [0, 1]) -> Dictionary:
	if current_state_id != &"map":
		return {
			"success": false,
			"message": "当前不在地图阶段。",
			"state": get_map_state(),
		}
	if map_nodes.is_empty():
		_reset_demo_map()

	var rolled_indices := _normalize_map_movement_dice_indices(selected_dice_indices)
	var rolls := _roll_map_movement_dice(rolled_indices)
	return {
		"success": true,
		"rolls": rolls.duplicate(),
		"rolled_dice_indices": rolled_indices.duplicate(),
		"steps": _sum_int_array(rolls),
		"state": get_map_state(),
	}


func apply_prepared_map_movement_roll(selected_dice_indices: Array, prepared_rolls: Array) -> Dictionary:
	if current_state_id != &"map":
		return {
			"success": false,
			"message": "当前不在地图阶段。",
			"state": get_map_state(),
		}
	if map_nodes.is_empty():
		_reset_demo_map()

	var rolled_indices := _normalize_map_movement_dice_indices(selected_dice_indices)
	var rolls := _sanitize_prepared_map_movement_rolls(rolled_indices, prepared_rolls)
	if rolls.is_empty():
		return {
			"success": false,
			"message": "前进骰结果无效。",
			"state": get_map_state(),
		}
	return _apply_map_movement_rolls(rolled_indices, rolls)


func _apply_map_movement_rolls(rolled_indices: Array[int], rolls: Array[int]) -> Dictionary:
	var previous_index := map_position_index
	map_last_rolled_dice_indices = rolled_indices.duplicate()
	map_last_rolls = rolls.duplicate()
	var steps := _sum_int_array(map_last_rolls)
	var path := _movement_path_until_forced_stop(previous_index, steps)

	map_position_index = path[path.size() - 1] if not path.is_empty() else previous_index
	map_last_stopped_by_boss = _path_hits_boss(path)
	map_last_refresh_path_index = -1 if map_last_stopped_by_boss else _start_index_in_path(path)
	var map_refreshed := map_last_refresh_path_index >= 0
	if map_refreshed:
		_refresh_map_ring()
	map_last_roll = steps
	map_last_path = path.duplicate()
	map_roll_count += 1
	if run_state != null:
		run_state.record_map_movement_action()
		run_state_changed.emit(run_state)
	map_pending_battle = _is_battle_map_node_type(_current_map_node_type())
	map_state_changed.emit(get_map_state())
	return {
		"success": true,
		"steps": steps,
		"actual_steps": path.size(),
		"stopped_by_boss": map_last_stopped_by_boss,
		"rolled_dice_indices": map_last_rolled_dice_indices.duplicate(),
		"previous_index": previous_index,
		"current_index": map_position_index,
		"path": path,
		"map_refreshed": map_refreshed,
		"refresh_path_index": map_last_refresh_path_index,
		"current_node": _current_map_node_for_view(),
		"pending_battle": map_pending_battle,
		"pending_boss_battle": _is_boss_map_node_type(_current_map_node_type()),
		"state": get_map_state(),
	}


func notify_map_movement_settled() -> void:
	if current_state_id != &"map":
		return
	map_movement_settled.emit(get_map_state())


func request_enter_battle_from_map() -> bool:
	if current_state_id != &"map":
		return false
	if not _is_battle_map_node_type(_current_map_node_type()):
		return false
	if run_state != null:
		run_state.set_current_encounter_node_type(_current_map_node_type())
	start_next_battle()
	return true


func return_to_map_after_battle() -> void:
	if run_state == null:
		return
	var completed_node_type := _current_map_node_type()
	if _is_boss_map_node_type(completed_node_type):
		_return_to_start_after_boss_battle()
		set_flow_state(&"map")
		map_state_changed.emit(get_map_state())
		map_requested.emit(get_map_state())
		return

	_mark_current_map_node_cleared()
	map_pending_battle = false
	map_last_path.clear()
	map_last_stopped_by_boss = false
	set_flow_state(&"map")
	map_state_changed.emit(get_map_state())
	map_requested.emit(get_map_state())


func _reset_demo_map() -> void:
	map_rng.seed = 20260519
	var types := _generate_map_types_for_refresh(0)
	map_nodes.clear()
	for index in range(types.size()):
		map_nodes.append({
			"node_id": StringName("demo_map_node_%02d" % [index]),
			"node_type": types[index],
			"index": index,
			"is_start": index == 0,
			"is_current": index == _start_map_index_for_count(types.size()),
			"is_cleared": false,
			"visual_state": &"current" if index == _start_map_index_for_count(types.size()) else &"normal",
		})
	map_position_index = _start_map_index()
	map_last_roll = 0
	map_last_rolls.clear()
	map_last_rolled_dice_indices.clear()
	map_last_path.clear()
	map_last_refresh_path_index = -1
	map_last_stopped_by_boss = false
	map_pending_battle = false
	map_roll_count = 0
	map_refresh_count = 0


func _map_nodes_for_view() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in map_nodes:
		var view_node := node.duplicate(true)
		var index := int(view_node.get("index", 0))
		var is_current := index == map_position_index
		view_node["is_current"] = is_current
		if is_current:
			view_node["visual_state"] = &"current"
		elif bool(view_node.get("is_cleared", false)):
			view_node["visual_state"] = &"cleared"
		else:
			view_node["visual_state"] = &"normal"
		result.append(view_node)
	return result


func _current_map_node_for_view() -> Dictionary:
	var nodes := _map_nodes_for_view()
	if nodes.is_empty():
		return {}
	return nodes[wrapi(map_position_index, 0, nodes.size())]


func _current_map_node_type() -> StringName:
	if map_nodes.is_empty():
		return &"start"
	var node := map_nodes[wrapi(map_position_index, 0, map_nodes.size())]
	return StringName(str(node.get("node_type", "start")))


func _mark_current_map_node_cleared() -> void:
	if map_nodes.is_empty():
		return
	var index := wrapi(map_position_index, 0, map_nodes.size())
	map_nodes[index]["is_cleared"] = true


func _normalize_map_movement_dice_indices(raw_indices: Array) -> Array[int]:
	var result: Array[int] = []
	for raw_index in raw_indices:
		var index := int(raw_index)
		if index < 0 or index >= 2:
			continue
		if result.has(index):
			continue
		result.append(index)
	if result.is_empty():
		result.append(0)
	result.sort()
	return result


func _roll_map_movement_dice(selected_dice_indices: Array[int]) -> Array[int]:
	var rolls: Array[int] = [0, 0]
	for die_index in selected_dice_indices:
		if die_index < 0 or die_index >= rolls.size():
			continue
		rolls[die_index] = map_rng.randi_range(1, 6)
	return rolls


func _sanitize_prepared_map_movement_rolls(selected_dice_indices: Array[int], raw_rolls: Array) -> Array[int]:
	var rolls: Array[int] = [0, 0]
	for die_index in selected_dice_indices:
		if die_index < 0 or die_index >= rolls.size() or die_index >= raw_rolls.size():
			return []
		var pip := int(raw_rolls[die_index])
		if pip < 1 or pip > 6:
			return []
		rolls[die_index] = pip
	return rolls


func _is_battle_map_node_type(node_type: StringName) -> bool:
	return node_type == &"battle" or node_type == &"elite" or node_type == &"boss"


func _is_boss_map_node_type(node_type: StringName) -> bool:
	return node_type == &"boss"


func _boss_map_index() -> int:
	return maxi(0, map_nodes.size() - 1)


func _start_map_index() -> int:
	return _start_map_index_for_count(map_nodes.size())


func _start_map_index_for_count(_count: int) -> int:
	return 0


func _movement_path_until_forced_stop(previous_index: int, steps: int) -> Array[int]:
	var path: Array[int] = []
	if map_nodes.is_empty():
		return path
	var boss_index := _boss_map_index()
	for offset in range(maxi(0, steps)):
		var next_index := wrapi(previous_index + offset + 1, 0, map_nodes.size())
		path.append(next_index)
		if next_index == boss_index:
			break
	return path


func _path_hits_boss(path: Array[int]) -> bool:
	var boss_index := _boss_map_index()
	for raw_index in path:
		if int(raw_index) == boss_index:
			return true
	return false


func _return_to_start_after_boss_battle() -> void:
	map_position_index = _start_map_index()
	map_pending_battle = false
	map_last_roll = 0
	map_last_rolls.clear()
	map_last_rolled_dice_indices.clear()
	map_last_path.clear()
	map_last_refresh_path_index = -1
	map_last_stopped_by_boss = false
	_refresh_map_ring()


func _start_index_in_path(path: Array[int]) -> int:
	for index in range(path.size()):
		if int(path[index]) == 0:
			return index
	return -1


func _refresh_map_ring() -> void:
	if map_nodes.is_empty():
		return
	map_refresh_count += 1
	var types := _generate_map_types_for_refresh(map_refresh_count)
	for index in range(map_nodes.size()):
		var node := map_nodes[index]
		node["node_type"] = types[index]
		node["is_start"] = index == 0
		node["is_cleared"] = false
		node["visual_state"] = &"current" if index == map_position_index else &"normal"


func _generate_map_types_for_refresh(refresh_index: int) -> Array[StringName]:
	var bag := _build_map_node_bag(refresh_index)
	var arranged := _arrange_map_node_bag(bag)
	var result: Array[StringName] = [&"start"]
	result.append_array(arranged)
	result.append(&"boss")
	return result


func _build_map_node_bag(refresh_index: int) -> Array[StringName]:
	var counts := _map_node_counts_for_refresh(refresh_index)
	var bag: Array[StringName] = []
	for type_id in counts.keys():
		for _index in range(int(counts[type_id])):
			bag.append(type_id)
	return bag


func _map_node_counts_for_refresh(_refresh_index: int) -> Dictionary:
	return {
		&"battle": 10,
		&"elite": 2,
		&"shop": 3,
		&"forge": 2,
		&"reward": 5,
		&"event": 4,
		&"penalty": 2,
		&"rest": 2,
	}


func _arrange_map_node_bag(source_bag: Array[StringName]) -> Array[StringName]:
	var best_candidate: Array[StringName] = []
	var best_score := -999
	for _attempt in range(120):
		var candidate := source_bag.duplicate()
		_shuffle_string_name_array(candidate)
		var score := _map_candidate_score(candidate)
		if score > best_score:
			best_score = score
			best_candidate = candidate
		if score >= 0:
			return candidate
	return best_candidate


func _shuffle_string_name_array(values: Array[StringName]) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := map_rng.randi_range(0, index)
		var old_value := values[index]
		values[index] = values[swap_index]
		values[swap_index] = old_value


func _map_candidate_score(candidate: Array[StringName]) -> int:
	var penalty := 0
	for index in range(candidate.size()):
		var type_id := candidate[index]
		if type_id == &"penalty":
			if index <= 1:
				penalty += 8
			if index > 0 and candidate[index - 1] == &"penalty":
				penalty += 10
			if index + 1 < candidate.size() and candidate[index + 1] == &"penalty":
				penalty += 10
			if index > 0 and candidate[index - 1] == &"elite":
				penalty += 6
			if index + 1 < candidate.size() and candidate[index + 1] == &"elite":
				penalty += 6
	return -penalty


func _sum_int_array(values: Array[int]) -> int:
	var total := 0
	for value in values:
		total += value
	return total


func _current_map_node_target_score() -> int:
	if run_state == null:
		return 0
	var node_type := _current_map_node_type()
	if not _is_battle_map_node_type(node_type):
		return 0
	return run_state.get_target_score(node_type)
