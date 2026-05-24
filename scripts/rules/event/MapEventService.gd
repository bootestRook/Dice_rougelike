extends RefCounted
class_name MapEventService


const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const MapEventChoice = preload("res://scripts/data_defs/MapEventChoice.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")


var rng := RandomNumberGenerator.new()
var reward_generator := RewardGenerator.new()


func _init() -> void:
	rng.randomize()


func apply_choice(run_state, choice) -> Dictionary:
	var event_choice := choice as MapEventChoice
	if run_state == null or event_choice == null:
		return _result(false, "奇遇选项无效。")
	var args := event_choice.effect_args
	match event_choice.effect_id:
		&"gain_coins":
			_gain_coins(run_state, int(args.get("amount", 0)))
			return _complete("获得金币。")
		&"pay_coins":
			if not _pay_coins(run_state, int(args.get("cost", 0))):
				return _result(false, "金币不足。")
			return _complete("已支付金币。")
		&"grant_forge_piece":
			return _grant_forge_piece(args)
		&"pay_for_forge_piece":
			if not _pay_coins(run_state, int(args.get("cost", 0))):
				return _result(false, "金币不足。")
			return _grant_forge_piece(args)
		&"grant_forge_piece_with_next_battle_target":
			_apply_next_battle_target(run_state, float(args.get("target_multiplier", 1.0)))
			return _grant_forge_piece(args)
		&"grant_forge_piece_or_coins":
			if rng.randf() < 0.5:
				return _grant_forge_piece(args)
			_gain_coins(run_state, int(args.get("coins", 0)))
			return _complete("获得金币。")
		&"grant_forge_piece_with_random_clear":
			_clear_random_ornament(run_state)
			return _grant_forge_piece(args)
		&"grant_forge_piece_disable_ornament":
			run_state.next_battle_disabled_ornament_count += int(args.get("disabled_ornament_count", 0))
			return _grant_forge_piece(args)
		&"grant_forge_piece_random_pip_to_one":
			_randomize_one_pip(run_state, [1])
			return _grant_forge_piece(args)
		&"clear_random_ornament_gain_piece":
			_clear_random_ornament(run_state)
			return _grant_forge_piece(args)
		&"gamble_forge_piece":
			return _apply_gamble_forge_piece(run_state, args, false)
		&"gamble_forge_piece_with_failure_penalty":
			return _apply_gamble_forge_piece(run_state, args, true)
		&"gain_forge_item":
			return _gain_forge_item(run_state, StringName(str(args.get("item_id", &""))))
		&"pay_for_forge_item":
			if not _pay_coins(run_state, int(args.get("cost", 0))):
				return _result(false, "金币不足。")
			return _gain_forge_item(run_state, StringName(str(args.get("item_id", &""))))
		&"grant_dice_tool_with_next_battle_target":
			_apply_next_battle_target(run_state, float(args.get("target_multiplier", 1.0)))
			return _grant_dice_tool(run_state, StringName(str(args.get("rarity", &"common"))))
		&"grant_dice_tool_start_battle":
			var battle_tool_result := _grant_dice_tool(run_state, StringName(str(args.get("rarity", &"rare"))))
			if not bool(battle_tool_result.get("success", false)):
				return battle_tool_result
			battle_tool_result["mode"] = &"start_battle"
			battle_tool_result["message"] = "获得骰具遗物，并立即触发一场普通战斗。"
			return battle_tool_result
		&"grant_dice_tool_next_battle_hands":
			run_state.next_battle_hands_delta += int(args.get("hands_delta", 0))
			return _grant_dice_tool(run_state, StringName(str(args.get("rarity", &"rare"))))
		&"pay_all_for_forge_piece":
			var min_coins := int(args.get("min_coins", 0))
			if run_state.coins < min_coins:
				return _result(false, "金币不足。")
			run_state.add_coins(-run_state.coins, &"map_event")
			return _grant_forge_piece(args)
		&"pay_for_dice_tool":
			if not _pay_coins(run_state, int(args.get("cost", 0))):
				return _result(false, "金币不足。")
			return _grant_dice_tool(run_state, StringName(str(args.get("rarity", &"common"))))
		&"replace_dice_tool":
			if not _remove_first_dice_tool(run_state):
				return _result(false, "没有可替换的骰具。")
			return _grant_dice_tool(run_state, StringName(str(args.get("rarity", &"rare"))))
		&"sell_dice_tool":
			if not _remove_first_dice_tool(run_state):
				return _result(false, "没有可抵押的骰具。")
			_gain_coins(run_state, int(args.get("amount", 0)))
			return _complete("已抵押骰具。")
		&"gain_coins_next_battle_rerolls":
			_gain_coins(run_state, int(args.get("amount", 0)))
			run_state.next_battle_rerolls_per_hand_delta += int(args.get("rerolls_delta", 0))
			return _complete("已记录下一场战斗重投调整。")
		&"gain_coins_next_battle_target":
			_gain_coins(run_state, int(args.get("amount", 0)))
			_apply_next_battle_target(run_state, float(args.get("target_multiplier", 1.0)))
			return _complete("已记录下一场战斗目标调整。")
		&"gain_coins_next_battle_disabled_score_die":
			_gain_coins(run_state, int(args.get("amount", 0)))
			run_state.next_battle_disabled_score_die_count += int(args.get("disabled_score_die_count", 0))
			return _complete("已记录下一场战斗骰子限制。")
		&"pay_for_next_battle_rerolls":
			if not _pay_coins(run_state, int(args.get("cost", 0))):
				return _result(false, "金币不足。")
			_apply_next_battle_reroll_delta(run_state, int(args.get("rerolls_delta", 0)), int(args.get("charges", 1)))
			return _complete("已记录下一场战斗重投调整。")
		&"gain_coins_boss_target_multiplier":
			_gain_coins(run_state, int(args.get("amount", 0)))
			run_state.current_circle_boss_target_score_multiplier *= float(args.get("boss_multiplier", 1.0))
			return _complete("已记录本圈首领目标调整。")
		&"set_circle_target_modifiers":
			run_state.current_circle_boss_target_score_multiplier *= float(args.get("boss_multiplier", 1.0))
			run_state.current_circle_non_boss_target_score_multiplier *= float(args.get("non_boss_multiplier", 1.0))
			return _complete("已记录本圈目标分调整。")
		&"combo_upgrade_pool":
			_upgrade_random_combo_from_pool(run_state, args.get("combos", []), int(args.get("amount", 1)))
			return _complete("主骰型等级已提升。")
		&"combo_upgrade_most_scored":
			_upgrade_most_scored_combo(run_state, int(args.get("amount", 1)))
			return _complete("主骰型等级已提升。")
		&"combo_upgrade_random_next_battle_target":
			_upgrade_random_combo_from_pool(run_state, ComboUpgradeCatalog.get_combo_ids(), int(args.get("amount", 1)))
			_apply_next_battle_target(run_state, float(args.get("target_multiplier", 1.0)))
			return _complete("主骰型等级已提升，并记录下一场战斗目标调整。")
		&"combo_upgrade_and_piece":
			run_state.increase_combo_level(StringName(str(args.get("combo", &"scatter"))), int(args.get("amount", 1)))
			return _grant_forge_piece(args)
		&"combo_upgrade_gain_coins":
			run_state.increase_combo_level(StringName(str(args.get("combo", &"scatter"))), int(args.get("amount", 1)))
			_gain_coins(run_state, int(args.get("coins", 0)))
			return _complete("主骰型等级已提升。")
		&"random_pip_step":
			_step_random_pip(run_state, int(args.get("amount", 1)))
			return _complete("随机骰面点数已改变。")
		&"randomize_pips":
			_randomize_pips(run_state, args.get("pool", []), int(args.get("count", 1)))
			return _complete("随机骰面点数已改变。")
		&"randomize_pips_next_battle_target":
			_randomize_pips(run_state, args.get("pool", []), int(args.get("count", 1)))
			_apply_next_battle_target(run_state, float(args.get("target_multiplier", 1.0)))
			return _complete("随机骰面点数已改变，并记录下一场战斗目标调整。")
		&"randomize_pips_gain_coins":
			_randomize_pips(run_state, args.get("pool", []), int(args.get("count", 1)))
			_gain_coins(run_state, int(args.get("amount", 0)))
			return _complete("随机骰面点数已改变。")
		&"clear_random_ornament_gain_coins":
			_clear_random_ornament(run_state)
			_gain_coins(run_state, int(args.get("amount", 0)))
			return _complete("已回收面饰。")
		&"clear_random_mark_gain_coins":
			_clear_random_mark(run_state)
			_gain_coins(run_state, int(args.get("amount", 0)))
			return _complete("已回收印记。")
		&"set_next_event_bias":
			run_state.next_event_bias = StringName(str(args.get("bias", &"")))
			run_state.next_event_bias_multiplier = float(args.get("multiplier", 1.0))
			return _complete("已记录下一次奇遇倾向。")
		&"set_run_flag":
			_set_run_flag(run_state, StringName(str(args.get("flag", &""))), true)
			if args.has("next_battle_target_multiplier"):
				_apply_next_battle_target(run_state, float(args.get("next_battle_target_multiplier", 1.0)))
			return _complete("已记录地图情报。")
		&"pay_for_run_flag":
			if not _pay_coins(run_state, int(args.get("cost", 0))):
				return _result(false, "金币不足。")
			_set_run_flag(run_state, StringName(str(args.get("flag", &""))), true)
			return _complete("已记录地图机会。")
		&"set_shop_modifier":
			_set_shop_modifier(run_state, args)
			return _complete("已记录下一个商店调整。")
		&"gain_coins_set_shop_modifier":
			_gain_coins(run_state, int(args.get("amount", 0)))
			_set_shop_modifier(run_state, args)
			return _complete("已记录下一个商店调整。")
		&"no_effect":
			return _complete("无事发生。")
		_:
			return _complete("该奇遇效果已记录。")


func _grant_forge_piece(args: Dictionary) -> Dictionary:
	var piece = reward_generator.generate_map_event_forge_piece(StringName(str(args.get("pool", &"common_face"))))
	if piece == null:
		return _result(false, "没有可用铸骰件。")
	return {
		"success": true,
		"mode": &"forge_install",
		"piece": piece,
		"message": "获得铸骰件。",
	}


func _apply_gamble_forge_piece(run_state, args: Dictionary, apply_failure_penalty: bool) -> Dictionary:
	if not _pay_coins(run_state, int(args.get("cost", 0))):
		return _result(false, "金币不足。")
	if rng.randf() <= float(args.get("chance", 0.0)):
		return _grant_forge_piece(args)
	if apply_failure_penalty:
		run_state.next_battle_rerolls_per_hand_delta += int(args.get("rerolls_delta", 0))
	return _complete("赌局没有获得奖励。")


func _gain_forge_item(run_state, item_id: StringName) -> Dictionary:
	if item_id == &"" or not ForgeItemCatalog.has_forge_item(item_id):
		return _result(false, "铸骰道具无效。")
	if not run_state.add_item_to_inventory_or_pending(item_id):
		return _result(false, "道具槽位不足。")
	return _complete("获得铸骰道具。")


func _grant_dice_tool(run_state, rarity: StringName) -> Dictionary:
	var item_id := reward_generator.generate_map_event_dice_tool_item_id(rarity)
	if item_id == &"":
		return _result(false, "没有可用骰具。")
	if not run_state.add_item_to_inventory_or_pending(item_id):
		return _result(false, "道具槽位不足。")
	return _complete("获得骰具道具。")


func _pay_coins(run_state, cost: int) -> bool:
	var value: int = max(0, cost)
	if run_state.coins < value:
		return false
	run_state.add_coins(-value, &"map_event")
	return true


func _gain_coins(run_state, amount: int) -> void:
	run_state.add_coins(max(0, amount), &"map_event")


func _apply_next_battle_target(run_state, multiplier: float) -> void:
	run_state.next_battle_target_score_multiplier *= maxf(0.1, multiplier)


func _apply_next_battle_reroll_delta(run_state, delta: int, charges: int = 1) -> void:
	if charges <= 1:
		run_state.next_battle_rerolls_per_hand_delta += delta
		return
	if run_state.has_method("enqueue_battle_rerolls_per_hand_delta"):
		run_state.enqueue_battle_rerolls_per_hand_delta(delta, charges)
	else:
		run_state.next_battle_rerolls_per_hand_delta += delta


func _set_run_flag(run_state, key: StringName, value) -> void:
	if key == &"":
		return
	run_state.map_event_flags[key] = value


func _set_shop_modifier(run_state, args: Dictionary) -> void:
	var key := StringName(str(args.get("key", &"")))
	if key != &"":
		run_state.next_shop_modifiers[key] = args.get("value", true)
	if args.has("reroll_cost_delta"):
		run_state.next_shop_modifiers[&"reroll_cost_delta"] = int(run_state.next_shop_modifiers.get(&"reroll_cost_delta", 0)) + int(args.get("reroll_cost_delta", 0))


func _remove_first_dice_tool(run_state) -> bool:
	if run_state.dice_tools.is_empty():
		return false
	return run_state.remove_dice_tool_at_index(0) != null


func _upgrade_random_combo_from_pool(run_state, raw_combos: Array, amount: int) -> void:
	var combos: Array[StringName] = []
	for raw_combo in raw_combos:
		var combo := ComboUpgradeCatalog.normalize_combo_id(StringName(str(raw_combo)))
		if ComboUpgradeCatalog.has_combo(combo):
			combos.append(combo)
	if combos.is_empty():
		combos = [
			&"scatter",
			&"pair",
			&"two_pair",
			&"three_kind",
			&"full_house",
			&"four_kind",
			&"straight",
			&"five_kind",
		]
	run_state.increase_combo_level(combos[rng.randi_range(0, combos.size() - 1)], max(1, amount))


func _upgrade_most_scored_combo(run_state, amount: int) -> void:
	var combo_id: StringName = run_state.get_most_scored_combo_id() if run_state.has_method("get_most_scored_combo_id") else &""
	if combo_id == &"":
		_upgrade_random_combo_from_pool(run_state, ComboUpgradeCatalog.get_combo_ids(), amount)
		return
	run_state.increase_combo_level(combo_id, max(1, amount))


func _step_random_pip(run_state, amount: int) -> void:
	var face := _random_face(run_state, false)
	if face == null:
		return
	face.pip = wrapi(int(face.pip) + max(1, amount) - 1, 0, 6) + 1


func _randomize_pips(run_state, raw_pool: Array, count: int) -> void:
	var pool: Array[int] = []
	for raw_value in raw_pool:
		var pip := int(raw_value)
		if pip >= 1 and pip <= 6:
			pool.append(pip)
	if pool.is_empty():
		pool = [1, 2, 3, 4, 5, 6]
	var faces := _mutable_faces(run_state, false)
	_shuffle_faces(faces)
	for index in range(min(count, faces.size())):
		var face: FaceState = faces[index]
		face.pip = pool[rng.randi_range(0, pool.size() - 1)]


func _randomize_one_pip(run_state, pool: Array[int]) -> void:
	_randomize_pips(run_state, pool, 1)


func _clear_random_ornament(run_state) -> void:
	var candidates := _mutable_faces(run_state, true)
	var ornament_faces: Array[FaceState] = []
	for face in candidates:
		var normalized := FaceState.normalize_ornament_id(face.ornament_id)
		if normalized != FaceState.ORN_NONE and not _protected_ornaments().has(normalized):
			ornament_faces.append(face)
	if ornament_faces.is_empty():
		return
	ornament_faces[rng.randi_range(0, ornament_faces.size() - 1)].ornament_id = FaceState.ORN_NONE


func _clear_random_mark(run_state) -> void:
	var candidates := _mutable_faces(run_state, true)
	var mark_faces: Array[FaceState] = []
	for face in candidates:
		var normalized := FaceState.normalize_mark_id(face.mark_id)
		if normalized != FaceState.MARK_NONE and not _protected_marks().has(normalized):
			mark_faces.append(face)
	if mark_faces.is_empty():
		return
	mark_faces[rng.randi_range(0, mark_faces.size() - 1)].mark_id = FaceState.MARK_NONE


func _random_face(run_state, avoid_protected: bool) -> FaceState:
	var faces := _mutable_faces(run_state, avoid_protected)
	if faces.is_empty():
		return null
	return faces[rng.randi_range(0, faces.size() - 1)]


func _mutable_faces(run_state, avoid_protected: bool) -> Array[FaceState]:
	var result: Array[FaceState] = []
	if run_state == null:
		return result
	for die in run_state.dice:
		if die == null:
			continue
		for face in die.faces:
			if face == null:
				continue
			if avoid_protected and _face_is_protected(face):
				continue
			result.append(face)
	return result


func _face_is_protected(face: FaceState) -> bool:
	return _protected_marks().has(FaceState.normalize_mark_id(face.mark_id)) \
		or _protected_ornaments().has(FaceState.normalize_ornament_id(face.ornament_id))


func _protected_marks() -> Array[StringName]:
	return [
		FaceState.MARK_RED,
		FaceState.MARK_BLUE,
		FaceState.MARK_PURPLE,
		FaceState.MARK_WHITE,
	]


func _protected_ornaments() -> Array[StringName]:
	return [
		FaceState.ORN_FOIL,
		FaceState.ORN_HOLO,
		FaceState.ORN_POLY,
	]


func _shuffle_faces(values: Array[FaceState]) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var old_value := values[index]
		values[index] = values[swap_index]
		values[swap_index] = old_value


func _complete(message: String) -> Dictionary:
	return {
		"success": true,
		"mode": &"complete",
		"message": message,
	}


func _result(success: bool, message: String) -> Dictionary:
	return {
		"success": success,
		"mode": &"none",
		"message": message,
	}
