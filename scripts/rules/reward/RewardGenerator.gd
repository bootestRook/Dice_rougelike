extends RefCounted
class_name RewardGenerator


const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ForgeItemDef = preload("res://scripts/data_defs/ForgeItemDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const DiceToolRewardChoice = preload("res://scripts/data_defs/DiceToolRewardChoice.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const ComboUpgradeItem = preload("res://scripts/rules/combo/ComboUpgradeItem.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const FoundryServiceDef = preload("res://scripts/data_defs/FoundryServiceDef.gd")
const FoundryServiceCatalog = preload("res://scripts/rules/forge/FoundryServiceCatalog.gd")


const NORMAL_REWARD_POOL_IDS := [
	&"pip_1",
	&"pip_2",
	&"pip_3",
	&"pip_4",
	&"pip_5",
	&"pip_6",
	&"ornament_chip",
	&"ornament_mult",
	&"ornament_wild",
	&"ornament_burst",
	&"ornament_stay",
	&"ornament_stone",
	&"ornament_gold",
	&"ornament_lucky",
	&"ornament_foil",
	&"ornament_holo",
	&"ornament_poly",
	&"mark_red",
	&"mark_blue",
	&"mark_purple",
	&"mark_gold",
	&"mark_white",
	&"red_1",
	&"red_2",
	&"red_3",
	&"red_4",
	&"red_5",
	&"red_6",
	&"blue_1",
	&"blue_2",
	&"blue_3",
	&"blue_4",
	&"blue_5",
	&"blue_6",
	&"purple_1",
	&"purple_2",
	&"purple_3",
	&"purple_4",
	&"purple_5",
	&"purple_6",
	&"gold_1",
	&"gold_2",
	&"gold_3",
	&"gold_4",
	&"gold_5",
	&"gold_6",
	&"burst_1",
	&"burst_2",
	&"burst_3",
	&"burst_4",
	&"burst_5",
	&"burst_6",
	&"stay_1",
	&"stay_2",
	&"stay_3",
	&"stay_4",
	&"stay_5",
	&"stay_6",
]

const STARTER_POOL_IDS := NORMAL_REWARD_POOL_IDS
const FULL_REWARD_POOL_IDS := NORMAL_REWARD_POOL_IDS

const DIRECT_POWER_IDS := [
	&"pip_6",
	&"ornament_chip",
	&"ornament_mult",
	&"ornament_wild",
	&"ornament_burst",
	&"ornament_stay",
	&"ornament_stone",
	&"ornament_gold",
	&"ornament_lucky",
	&"ornament_foil",
	&"ornament_holo",
	&"ornament_poly",
	&"mark_red",
	&"mark_gold",
	&"red_6",
	&"burst_1",
	&"stay_6",
]

const COMBO_UPGRADE_IDS := [
	&"upgrade_combo_scatter",
	&"upgrade_combo_pair",
	&"upgrade_combo_two_pair",
	&"upgrade_combo_three_kind",
	&"upgrade_combo_full_house",
	&"upgrade_combo_four_kind",
	&"upgrade_combo_straight",
	&"upgrade_combo_five_kind",
]

const REWARD_RARITY_ORDER := [
	&"common",
	&"uncommon",
	&"rare",
	&"epic",
	&"legendary",
]

const NORMAL_BATTLE_RARITY_WEIGHTS := {
	&"common": 72.0,
	&"uncommon": 24.0,
	&"rare": 4.0,
	&"epic": 0.0,
	&"legendary": 0.0,
}

const ELITE_REWARD_RARITY_WEIGHTS := {
	&"common": 20.0,
	&"uncommon": 45.0,
	&"rare": 28.0,
	&"epic": 7.0,
	&"legendary": 0.0,
}

const BOSS_REWARD_RARITY_WEIGHTS := {
	&"common": 0.0,
	&"uncommon": 20.0,
	&"rare": 45.0,
	&"epic": 25.0,
	&"legendary": 10.0,
}


var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func generate_forge_choices(count: int = 3, battle_index: int = 0) -> Array[ForgePieceDef]:
	return generate_forge_choices_for_encounter(count, RunState.ENCOUNTER_BATTLE, battle_index)


func generate_forge_choices_for_encounter(count: int = 3, encounter_type: StringName = &"battle", battle_index: int = 0) -> Array[ForgePieceDef]:
	var pool := _build_reward_pool_for_encounter(encounter_type, battle_index)
	var requested_count: int = max(0, count)
	var rarity_weights := _rarity_weights_for_encounter(encounter_type)
	var choices := _draw_weighted_unique_choices(pool, requested_count, rarity_weights)
	_ensure_direct_power_choice(choices, pool, rarity_weights)
	return choices


func generate_forge_choices_for_battle(count: int, battle_index: int) -> Array[ForgePieceDef]:
	return generate_forge_choices(count, battle_index)


func generate_forge_piece_choices(run_state: RunState, count: int = 3) -> Array[ForgePieceDef]:
	var battle_index := 0
	var encounter_type := RunState.ENCOUNTER_BATTLE
	if run_state != null:
		battle_index = run_state.battle_index
		encounter_type = run_state.current_encounter_node_type
	return generate_forge_choices_for_encounter(count, encounter_type, battle_index)


func generate_battle_reward_choices(run_state: RunState, count: int = 3) -> Array:
	var choices: Array = []
	choices.append_array(generate_forge_piece_choices(run_state, count))
	var encounter_type := RunState.ENCOUNTER_BATTLE
	if run_state != null:
		encounter_type = run_state.current_encounter_node_type
	if encounter_type == RunState.ENCOUNTER_ELITE:
		_replace_one_choice_with_dice_tool(choices, count, _elite_dice_tool_reward_pool(), "精英骰具奖励")
	elif encounter_type == RunState.ENCOUNTER_BOSS:
		_replace_one_choice_with_dice_tool(choices, count, _boss_dice_tool_reward_pool(), "首领骰具奖励")
	return choices


func generate_map_reward_node_choices(count: int = 3) -> Array:
	var choices: Array = []
	if rng.randf() < 0.25:
		var dice_choice := _draw_dice_tool_reward_choice(_map_reward_dice_tool_pool(), "奖励节点骰具")
		if dice_choice != null:
			choices.append(dice_choice)
	_fill_direct_forge_item_choices(choices, count)
	return choices


func generate_special_event_choices(count: int = 3) -> Array:
	var choices: Array = []
	var dice_choice := _draw_dice_tool_reward_choice(_special_event_dice_tool_pool(), "特殊奇遇骰具")
	if dice_choice != null:
		choices.append(dice_choice)
	_fill_direct_forge_item_choices(choices, count)
	return choices


func generate_forge_item_choices(count: int = 3) -> Array[ForgeItemDef]:
	var choices: Array[ForgeItemDef] = []
	for id in _draw_unique_formal_forge_item_ids(ForgeItemCatalog.get_all_ids(), max(0, count)):
		var def := ForgeItemCatalog.get_def(id)
		if def != null:
			choices.append(def)
	return choices


func generate_foundry_service_choices(count: int = 3) -> Array[FoundryServiceDef]:
	var choices: Array[FoundryServiceDef] = []
	for id in _draw_unique_formal_foundry_service_ids(FoundryServiceCatalog.get_all_ids(), max(0, count)):
		var def := FoundryServiceCatalog.get_def(id)
		if def != null:
			choices.append(def)
	return choices


func _replace_one_choice_with_dice_tool(choices: Array, count: int, pool: Array, source_note: String) -> void:
	var dice_choice := _draw_dice_tool_reward_choice(pool, source_note)
	if dice_choice == null:
		return
	if choices.is_empty():
		choices.append(dice_choice)
		return
	var replace_index: int = mini(maxi(0, count - 1), choices.size() - 1)
	choices[replace_index] = dice_choice


func _fill_direct_forge_item_choices(choices: Array, count: int) -> void:
	var needed: int = maxi(0, count - choices.size())
	if needed <= 0:
		return
	for item in generate_forge_item_choices(needed):
		choices.append(item)


func _elite_dice_tool_reward_pool() -> Array:
	return _weighted_pool_from_item_data(DiceToolCatalog.get_special_dice_tool_item_pool(&"rare"), 100)


func _boss_dice_tool_reward_pool() -> Array:
	var pool := []
	pool.append_array(_weighted_pool_from_item_data(DiceToolCatalog.get_special_dice_tool_item_pool(&"rare"), 55))
	pool.append_array(_weighted_pool_from_item_data(DiceToolCatalog.get_special_dice_tool_item_pool(&"epic"), 30))
	pool.append_array(_weighted_pool_from_item_data(DiceToolCatalog.get_legendary_dice_tool_item_pool(), 15))
	return pool


func _map_reward_dice_tool_pool() -> Array:
	var pool := []
	pool.append_array(_weighted_pool_from_item_data(DiceToolCatalog.get_generated_dice_tool_item_pool(&"common"), 55))
	pool.append_array(_weighted_pool_from_item_data(DiceToolCatalog.get_generated_dice_tool_item_pool(&"uncommon"), 30))
	pool.append_array(_weighted_pool_from_item_data(DiceToolCatalog.get_generated_dice_tool_item_pool(&"rare"), 12))
	pool.append_array(_weighted_pool_from_item_data(DiceToolCatalog.get_special_dice_tool_item_pool(&"epic"), 3))
	return pool


func _special_event_dice_tool_pool() -> Array:
	var pool := []
	pool.append_array(_weighted_pool_from_item_data(DiceToolCatalog.get_special_dice_tool_item_pool(&"rare"), 55))
	pool.append_array(_weighted_pool_from_item_data(DiceToolCatalog.get_special_dice_tool_item_pool(&"epic"), 35))
	pool.append_array(_weighted_pool_from_item_data(DiceToolCatalog.get_legendary_dice_tool_item_pool(), 10))
	return pool


func _weighted_pool_from_item_data(source: Array, weight: int) -> Array:
	var result := []
	for data in source:
		var entry := Dictionary(data).duplicate(true)
		entry["weight"] = weight
		result.append(entry)
	return result


func _draw_dice_tool_reward_choice(source: Array, source_note: String) -> DiceToolRewardChoice:
	if source.is_empty():
		return null
	var total_weight := 0
	for data in source:
		total_weight += max(0, int(Dictionary(data).get("weight", 0)))
	if total_weight <= 0:
		return null
	var roll := rng.randi_range(1, total_weight)
	var cursor := 0
	for data in source:
		cursor += max(0, int(Dictionary(data).get("weight", 0)))
		if roll <= cursor:
			return DiceToolRewardChoice.from_tool_data(Dictionary(data), source_note)
	return null


func roll_random_forge_item(battle_index: int = 0) -> StringName:
	var pool := _build_reward_pool_for_battle(battle_index)
	if pool.is_empty():
		return &""
	var choices := _draw_weighted_unique_choices(pool, 1, _rarity_weights_for_encounter(RunState.ENCOUNTER_BATTLE))
	if choices.is_empty() or choices[0] == null:
		return &""
	return choices[0].id


func roll_random_formal_forge_item(excluded_ids: Array = []) -> StringName:
	var pool: Array[StringName] = []
	for id in ForgeItemCatalog.get_all_ids():
		if not excluded_ids.has(id):
			pool.append(id)
	if pool.is_empty():
		return &""
	return pool[rng.randi_range(0, pool.size() - 1)]


func combo_upgrade_item_id(combo_id: StringName) -> StringName:
	return ComboUpgradeCatalog.item_id_for_combo(_normalize_combo_id(combo_id))


func _draw_unique_formal_forge_item_ids(pool: Array, requested_count: int) -> Array[StringName]:
	var source: Array[StringName] = []
	for id in pool:
		source.append(StringName(str(id)))
	var choices: Array[StringName] = []
	while choices.size() < requested_count and not source.is_empty():
		var index := rng.randi_range(0, source.size() - 1)
		choices.append(source[index])
		source.remove_at(index)
	return choices


func _draw_unique_formal_foundry_service_ids(pool: Array, requested_count: int) -> Array[StringName]:
	var source: Array[StringName] = []
	for id in pool:
		source.append(StringName(str(id)))
	var choices: Array[StringName] = []
	while choices.size() < requested_count and not source.is_empty():
		var index := rng.randi_range(0, source.size() - 1)
		choices.append(source[index])
		source.remove_at(index)
	return choices


func _draw_unique_choices(pool: Array[ForgePieceDef], requested_count: int) -> Array[ForgePieceDef]:
	var choices: Array[ForgePieceDef] = []
	var ids: Array[StringName] = []
	while choices.size() < requested_count and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		var piece := pool[index]
		pool.remove_at(index)
		if piece == null or ids.has(piece.id):
			continue
		choices.append(piece)
		ids.append(piece.id)

	return choices


func _draw_weighted_unique_choices(pool: Array[ForgePieceDef], requested_count: int, rarity_weights: Dictionary) -> Array[ForgePieceDef]:
	var choices: Array[ForgePieceDef] = []
	var ids: Array[StringName] = []
	while choices.size() < requested_count and not pool.is_empty():
		var rarity := _roll_available_rarity(pool, rarity_weights)
		if rarity == &"":
			break

		var candidate_indices: Array[int] = []
		for index in range(pool.size()):
			var piece := pool[index]
			if piece != null and piece.get_rarity() == rarity:
				candidate_indices.append(index)

		if candidate_indices.is_empty():
			break

		var pool_index := candidate_indices[rng.randi_range(0, candidate_indices.size() - 1)]
		var piece := pool[pool_index]
		pool.remove_at(pool_index)
		if piece == null or ids.has(piece.id):
			continue
		choices.append(piece)
		ids.append(piece.id)

	return choices


func _roll_available_rarity(pool: Array[ForgePieceDef], rarity_weights: Dictionary) -> StringName:
	var available_weights := {}
	var total_weight := 0.0
	for piece in pool:
		if piece == null:
			continue
		var rarity := piece.get_rarity()
		var weight := float(rarity_weights.get(rarity, 0.0))
		if weight <= 0.0 or available_weights.has(rarity):
			continue
		available_weights[rarity] = weight
		total_weight += weight

	if total_weight <= 0.0:
		return &""

	var roll := rng.randf() * total_weight
	var cursor := 0.0
	for rarity in REWARD_RARITY_ORDER:
		var weight := float(available_weights.get(rarity, 0.0))
		if weight <= 0.0:
			continue
		cursor += weight
		if roll < cursor:
			return rarity

	var last_available := &""
	for rarity in REWARD_RARITY_ORDER:
		if float(available_weights.get(rarity, 0.0)) > 0.0:
			last_available = rarity
	return last_available


func _ensure_direct_power_choice(choices: Array[ForgePieceDef], pool: Array[ForgePieceDef], rarity_weights: Dictionary = {}) -> void:
	if choices.is_empty() or _has_direct_power_choice(choices):
		return

	var used_ids := {}
	for choice in choices:
		if choice != null:
			used_ids[choice.id] = true

	var candidates: Array[ForgePieceDef] = []
	for piece in pool:
		if piece != null and _is_direct_power_piece(piece) and not used_ids.has(piece.id) and _piece_has_positive_rarity_weight(piece, rarity_weights):
			candidates.append(piece)

	if candidates.is_empty():
		return

	var replacement := candidates[rng.randi_range(0, candidates.size() - 1)]
	var replace_index := rng.randi_range(0, choices.size() - 1)
	choices[replace_index] = replacement


func _has_direct_power_choice(choices: Array[ForgePieceDef]) -> bool:
	for choice in choices:
		if _is_direct_power_piece(choice):
			return true
	return false


func _is_direct_power_piece(piece: ForgePieceDef) -> bool:
	return piece != null and (DIRECT_POWER_IDS.has(piece.id) or _is_direct_power_composite_id(piece.id))


func _build_reward_pool_for_battle(_battle_index: int) -> Array[ForgePieceDef]:
	return _build_reward_pool_for_encounter(RunState.ENCOUNTER_BATTLE, _battle_index)


func _build_reward_pool_for_encounter(_encounter_type: StringName, _battle_index: int = 0) -> Array[ForgePieceDef]:
	return _build_pool_from_ids(FULL_REWARD_POOL_IDS)


func _build_forge_piece_pool() -> Array[ForgePieceDef]:
	return _build_pool_from_ids(FULL_REWARD_POOL_IDS)


func _rarity_weights_for_encounter(encounter_type: StringName) -> Dictionary:
	match encounter_type:
		RunState.ENCOUNTER_ELITE:
			return ELITE_REWARD_RARITY_WEIGHTS
		RunState.ENCOUNTER_BOSS:
			return BOSS_REWARD_RARITY_WEIGHTS
		_:
			return NORMAL_BATTLE_RARITY_WEIGHTS


func _piece_has_positive_rarity_weight(piece: ForgePieceDef, rarity_weights: Dictionary) -> bool:
	if piece == null:
		return false
	if rarity_weights.is_empty():
		return true
	return float(rarity_weights.get(piece.get_rarity(), 0.0)) > 0.0


func _build_pool_from_ids(ids: Array) -> Array[ForgePieceDef]:
	var catalog := _build_piece_catalog()
	var pool: Array[ForgePieceDef] = []
	for id in ids:
		if catalog.has(id):
			pool.append(catalog[id])
	return pool


func _build_piece_catalog() -> Dictionary:
	var catalog := {
		&"pip_1": _make_piece(&"pip_1", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 1)], &"common", [&"low"]),
		&"pip_2": _make_piece(&"pip_2", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 2)], &"common", [&"low", &"straight", &"even"]),
		&"pip_3": _make_piece(&"pip_3", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 3)], &"common", [&"straight", &"odd"]),
		&"pip_4": _make_piece(&"pip_4", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 4)], &"common", [&"low", &"straight", &"even"]),
		&"pip_5": _make_piece(&"pip_5", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 5)], &"common", [&"straight", &"odd"]),
		&"pip_6": _make_piece(&"pip_6", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 6)], &"common", [&"six", &"power"]),
		&"ornament_chip": _make_piece(&"ornament_chip", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_chip")], &"common", [&"ornament", &"stable", &"chips"]),
		&"ornament_mult": _make_piece(&"ornament_mult", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_mult")], &"common", [&"ornament", &"mult"]),
		&"ornament_wild": _make_piece(&"ornament_wild", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_wild")], &"rare", [&"ornament", &"straight", &"stable"]),
		&"ornament_burst": _make_piece(&"ornament_burst", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_burst")], &"uncommon", [&"ornament", &"burst", &"xmult"]),
		&"ornament_stay": _make_piece(&"ornament_stay", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_stay")], &"uncommon", [&"ornament", &"stay", &"stable"]),
		&"ornament_stone": _make_piece(&"ornament_stone", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_stone")], &"uncommon", [&"ornament", &"chips", &"stable"]),
		&"ornament_gold": _make_piece(&"ornament_gold", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_gold")], &"uncommon", [&"ornament", &"stay", &"stable"]),
		&"ornament_lucky": _make_piece(&"ornament_lucky", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_lucky")], &"uncommon", [&"ornament", &"mult"]),
		&"ornament_foil": _make_piece(&"ornament_foil", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_foil")], &"rare", [&"ornament", &"chips"]),
		&"ornament_holo": _make_piece(&"ornament_holo", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_holo")], &"rare", [&"ornament", &"mult"]),
		&"ornament_poly": _make_piece(&"ornament_poly", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_poly")], &"epic", [&"ornament", &"xmult"]),
		&"mark_red": _make_piece(&"mark_red", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_red")], &"rare", [&"mark", &"extra_trigger", &"burst"]),
		&"mark_blue": _make_piece(&"mark_blue", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_blue")], &"rare", [&"mark", &"stay", &"stable"]),
		&"mark_purple": _make_piece(&"mark_purple", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_purple")], &"rare", [&"mark", &"reroll"]),
		&"mark_gold": _make_piece(&"mark_gold", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_gold")], &"uncommon", [&"mark", &"gold", &"stable"]),
		&"mark_white": _make_piece(&"mark_white", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_white")], &"rare", [&"mark", &"stable"]),
		&"upgrade_combo_scatter": _make_piece(&"upgrade_combo_scatter", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"scatter")], &"common", [&"upgrade", &"stable"]),
		&"upgrade_combo_pair": _make_piece(&"upgrade_combo_pair", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"pair")], &"common", [&"upgrade", &"stable"]),
		&"upgrade_combo_two_pair": _make_piece(&"upgrade_combo_two_pair", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"two_pair")], &"uncommon", [&"upgrade", &"stable"]),
		&"upgrade_combo_three_kind": _make_piece(&"upgrade_combo_three_kind", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"three_kind")], &"uncommon", [&"upgrade", &"stable"]),
		&"upgrade_combo_full_house": _make_piece(&"upgrade_combo_full_house", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"full_house")], &"uncommon", [&"upgrade", &"stable"]),
		&"upgrade_combo_four_kind": _make_piece(&"upgrade_combo_four_kind", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"four_kind")], &"rare", [&"upgrade", &"stable"]),
		&"upgrade_combo_straight": _make_piece(&"upgrade_combo_straight", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"straight")], &"rare", [&"upgrade", &"stable"]),
		&"upgrade_combo_five_kind": _make_piece(&"upgrade_combo_five_kind", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"five_kind")], &"epic", [&"upgrade", &"stable"]),
		&"cleanse": _make_piece(&"cleanse", [_make_op(ForgeOperationDef.OP_CLEANSE)], &"uncommon", [&"stable"]),

		&"material_glass": _make_piece(&"material_glass", [_make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"glass")], &"uncommon", [&"ornament", &"burst", &"xmult"]),
		&"material_steel": _make_piece(&"material_steel", [_make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"steel")], &"uncommon", [&"ornament", &"stay", &"stable"]),
		&"glass_1": _make_piece(&"glass_1", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 1), _make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"glass")], &"uncommon", [&"low", &"ornament", &"burst", &"xmult"]),
		&"rune_six": _make_piece(&"rune_six", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"six")], &"uncommon", [&"six"]),
		&"rune_straight": _make_piece(&"rune_straight", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"straight")], &"rare", [&"straight"]),
		&"rune_pair": _make_piece(&"rune_pair", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"pair")], &"uncommon", [&"extra_trigger"]),
		&"rune_odd": _make_piece(&"rune_odd", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"odd")], &"common", [&"odd"]),
		&"rune_even": _make_piece(&"rune_even", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"even")], &"common", [&"even"]),
		&"upgrade_1": _make_piece(&"upgrade_1", [_make_int_op(ForgeOperationDef.OP_UPGRADE, 1)], &"rare", [&"stable"]),
	}
	_add_mark_pip_pieces(catalog, &"red", &"mark_red", &"common", [&"mark", &"extra_trigger", &"burst"])
	_add_mark_pip_pieces(catalog, &"blue", &"mark_blue", &"rare", [&"mark", &"stay", &"stable"])
	_add_mark_pip_pieces(catalog, &"purple", &"mark_purple", &"rare", [&"mark", &"reroll"])
	_add_mark_pip_pieces(catalog, &"gold", &"mark_gold", &"uncommon", [&"mark", &"gold", &"stable"])
	_add_ornament_pip_pieces(catalog, &"burst", &"orn_burst", &"uncommon", [&"ornament", &"burst", &"xmult"])
	_add_ornament_pip_pieces(catalog, &"stay", &"orn_stay", &"uncommon", [&"ornament", &"stay", &"stable"])
	return catalog


func _add_mark_pip_pieces(catalog: Dictionary, id_prefix: StringName, mark_id: StringName, rarity: StringName, tags: Array) -> void:
	for pip in range(1, 7):
		var id := StringName("%s_%d" % [str(id_prefix), pip])
		catalog[id] = _make_piece(id, [
			_make_int_op(ForgeOperationDef.OP_SET_PIP, pip),
			_make_id_op(ForgeOperationDef.OP_SET_MARK, mark_id),
		], _composite_rarity(id_prefix, pip, rarity), _merge_tags(_pip_tags(pip), tags))


func _add_ornament_pip_pieces(catalog: Dictionary, id_prefix: StringName, ornament_id: StringName, rarity: StringName, tags: Array) -> void:
	for pip in range(1, 7):
		var id := StringName("%s_%d" % [str(id_prefix), pip])
		catalog[id] = _make_piece(id, [
			_make_int_op(ForgeOperationDef.OP_SET_PIP, pip),
			_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, ornament_id),
		], _composite_rarity(id_prefix, pip, rarity), _merge_tags(_pip_tags(pip), tags))


func _composite_rarity(id_prefix: StringName, pip: int, fallback: StringName) -> StringName:
	match id_prefix:
		&"red":
			return &"epic" if pip >= 4 else &"rare"
		&"blue":
			return &"epic" if pip >= 6 else &"rare"
		&"purple":
			return &"epic" if pip >= 6 else &"rare"
		&"gold":
			return &"rare" if pip >= 6 else &"uncommon"
		&"burst":
			return &"rare" if pip >= 4 else &"uncommon"
		&"stay":
			return &"rare" if pip >= 5 else &"uncommon"
		_:
			return fallback


func _pip_tags(pip: int) -> Array[StringName]:
	match pip:
		1:
			return [&"low"]
		2:
			return [&"low", &"straight", &"even"]
		3:
			return [&"straight", &"odd"]
		4:
			return [&"low", &"straight", &"even"]
		5:
			return [&"straight", &"odd"]
		6:
			return [&"six", &"power"]
		_:
			return []


func _merge_tags(first: Array, second: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for tag in first:
		var normalized := StringName(str(tag))
		if normalized != &"" and not result.has(normalized):
			result.append(normalized)
	for tag in second:
		var next_normalized := StringName(str(tag))
		if next_normalized != &"" and not result.has(next_normalized):
			result.append(next_normalized)
	return result


func _make_piece(id: StringName, ops: Array, rarity: StringName = &"common", tags: Array = []) -> ForgePieceDef:
	var piece := ForgePieceDef.new()
	piece.id = id
	piece.name_key = LocKeys.forge_part_name_key(id)
	piece.desc_key = LocKeys.forge_part_desc_key(id)
	piece.display_name = _display_name_for_id(id)
	piece.description = _description_for_id(id)
	piece.rarity = rarity
	piece.rarity_key = LocKeys.rarity_key(rarity)
	for op_def in ops:
		if op_def is ForgeOperationDef:
			piece.operations.append(op_def)
	for tag in tags:
		if tag is StringName:
			piece.tags.append(tag)
		else:
			piece.tags.append(StringName(str(tag)))
	return piece


func _composite_display_name_for_id(id: StringName) -> String:
	var parsed := _parse_pip_composite_id(id)
	if parsed.is_empty():
		return ""
	var prefix_text := _composite_name_prefix(StringName(str(parsed.get("prefix", &""))))
	if prefix_text == "":
		return ""
	return "%s %d" % [prefix_text, int(parsed.get("pip", 0))]


func _composite_description_for_id(id: StringName) -> String:
	var parsed := _parse_pip_composite_id(id)
	if parsed.is_empty():
		return ""
	var pip := int(parsed.get("pip", 0))
	match StringName(str(parsed.get("prefix", &""))):
		&"red":
			return str(TranslationServer.translate(&"FORGE_PART.COMPOSITE_RED.DESC")) % [pip]
		&"blue":
			return str(TranslationServer.translate(&"FORGE_PART.COMPOSITE_BLUE.DESC")) % [pip]
		&"purple":
			return str(TranslationServer.translate(&"FORGE_PART.COMPOSITE_PURPLE.DESC")) % [pip]
		&"gold":
			return str(TranslationServer.translate(&"FORGE_PART.COMPOSITE_GOLD.DESC")) % [pip]
		&"burst":
			return str(TranslationServer.translate(&"FORGE_PART.COMPOSITE_BURST.DESC")) % [pip]
		&"stay":
			return str(TranslationServer.translate(&"FORGE_PART.COMPOSITE_STAY.DESC")) % [pip]
		_:
			return ""


func _composite_name_prefix(prefix: StringName) -> String:
	match prefix:
		&"red":
			return str(TranslationServer.translate(&"AUTO.TEXT.79C2CA946E6B"))
		&"blue":
			return str(TranslationServer.translate(&"AUTO.TEXT.DF9F6D1541D3"))
		&"purple":
			return str(TranslationServer.translate(&"AUTO.TEXT.8EBB318D3D60"))
		&"gold":
			return str(TranslationServer.translate(&"AUTO.TEXT.C95B7D8DF883"))
		&"burst":
			return str(TranslationServer.translate(&"FORGE_PART.COMPOSITE_BURST.NAME_PREFIX"))
		&"stay":
			return str(TranslationServer.translate(&"FORGE_PART.COMPOSITE_STAY.NAME_PREFIX"))
		_:
			return ""


func _is_direct_power_composite_id(id: StringName) -> bool:
	var parsed := _parse_pip_composite_id(id)
	if parsed.is_empty():
		return false
	var prefix := StringName(str(parsed.get("prefix", &"")))
	var pip := int(parsed.get("pip", 0))
	return pip == 6 or [&"red", &"gold", &"burst", &"stay"].has(prefix)


func _parse_pip_composite_id(id: StringName) -> Dictionary:
	var text := str(id)
	var separator := text.rfind("_")
	if separator <= 0 or separator >= text.length() - 1:
		return {}
	var prefix := text.substr(0, separator)
	var suffix := text.substr(separator + 1)
	if not suffix.is_valid_int():
		return {}
	var pip := int(suffix)
	if pip < 1 or pip > 6:
		return {}
	match prefix:
		"red", "blue", "purple", "gold", "burst", "stay":
			return {
				"prefix": StringName(prefix),
				"pip": pip,
			}
		_:
			return {}


func _display_name_for_id(id: StringName) -> String:
	var combo_item := ComboUpgradeItem.from_item_id(id)
	if combo_item != null:
		return combo_item.display_name

	var composite_name := _composite_display_name_for_id(id)
	if composite_name != "":
		return composite_name

	match id:
		&"pip_1":
			return str(TranslationServer.translate(&"AUTO.TEXT.D6015166CA43"))
		&"pip_2":
			return str(TranslationServer.translate(&"FORGE_PART.PIP_2.NAME"))
		&"pip_3":
			return str(TranslationServer.translate(&"AUTO.TEXT.5831FA30C96E"))
		&"pip_4":
			return str(TranslationServer.translate(&"FORGE_PART.PIP_4.NAME"))
		&"pip_5":
			return str(TranslationServer.translate(&"FORGE_PART.PIP_5.NAME"))
		&"pip_6":
			return str(TranslationServer.translate(&"AUTO.TEXT.C02DD5A6CE94"))
		&"ornament_chip":
			return str(TranslationServer.translate(&"AUTO.TEXT.117883B0EBE1"))
		&"ornament_mult":
			return str(TranslationServer.translate(&"AUTO.TEXT.C500FA399240"))
		&"ornament_wild":
			return str(TranslationServer.translate(&"AUTO.TEXT.AC2FB8965804"))
		&"ornament_burst", &"material_glass":
			return str(TranslationServer.translate(&"AUTO.TEXT.97FB92DB432F"))
		&"ornament_stay", &"material_steel":
			return str(TranslationServer.translate(&"AUTO.TEXT.5C1FC3B3DE4C"))
		&"ornament_stone":
			return str(TranslationServer.translate(&"AUTO.TEXT.7D507BD3C533"))
		&"ornament_gold":
			return str(TranslationServer.translate(&"AUTO.TEXT.0C170134B33B"))
		&"ornament_lucky":
			return str(TranslationServer.translate(&"AUTO.TEXT.9B44878F713C"))
		&"ornament_foil":
			return str(TranslationServer.translate(&"AUTO.TEXT.EF8326246CC6"))
		&"ornament_holo":
			return str(TranslationServer.translate(&"AUTO.TEXT.71057C7B06AE"))
		&"ornament_poly":
			return str(TranslationServer.translate(&"AUTO.TEXT.C7D719D6CF7B"))
		&"mark_red":
			return str(TranslationServer.translate(&"AUTO.TEXT.79C2CA946E6B"))
		&"mark_blue":
			return str(TranslationServer.translate(&"AUTO.TEXT.DF9F6D1541D3"))
		&"mark_purple":
			return str(TranslationServer.translate(&"AUTO.TEXT.8EBB318D3D60"))
		&"mark_gold":
			return str(TranslationServer.translate(&"AUTO.TEXT.C95B7D8DF883"))
		&"mark_white":
			return str(TranslationServer.translate(&"AUTO.TEXT.2E1D574ED743"))
		&"glass_1":
			return str(TranslationServer.translate(&"AUTO.TEXT.BC7DA19E882B"))
		&"cleanse":
			return str(TranslationServer.translate(&"AUTO.TEXT.16544158C110"))
		&"rune_six", &"rune_straight", &"rune_pair", &"rune_odd", &"rune_even", &"upgrade_1":
			return str(TranslationServer.translate(&"AUTO.TEXT.CBF70592C60C"))
		_:
			return str(id)


func _description_for_id(id: StringName) -> String:
	if id == &"mark_red":
		return str(TranslationServer.translate(&"AUTO.TEXT.DB4775169C24"))
	if id == &"mark_blue":
		return str(TranslationServer.translate(&"AUTO.TEXT.EDE4E88DE3D0"))
	if id == &"mark_purple":
		return str(TranslationServer.translate(&"AUTO.TEXT.296FAC38B168"))
	if id == &"mark_gold":
		return str(TranslationServer.translate(&"AUTO.TEXT.547F36B364AF"))
	if id == &"mark_white":
		return str(TranslationServer.translate(&"AUTO.TEXT.48C725A7FD3F"))
	if ComboUpgradeItem.from_item_id(id) != null:
		return str(TranslationServer.translate(&"AUTO.TEXT.B147441759D4"))
	var composite_description := _composite_description_for_id(id)
	if composite_description != "":
		return composite_description
	match id:
		&"pip_1":
			return str(TranslationServer.translate(&"AUTO.TEXT.2A2DE5E19D26"))
		&"pip_2":
			return str(TranslationServer.translate(&"FORGE_PART.PIP_2.DESC"))
		&"pip_3":
			return str(TranslationServer.translate(&"AUTO.TEXT.BC90445D994E"))
		&"pip_4":
			return str(TranslationServer.translate(&"FORGE_PART.PIP_4.DESC"))
		&"pip_5":
			return str(TranslationServer.translate(&"FORGE_PART.PIP_5.DESC"))
		&"pip_6":
			return str(TranslationServer.translate(&"AUTO.TEXT.24E797AEACB8"))
		&"ornament_chip":
			return str(TranslationServer.translate(&"AUTO.TEXT.98262A372A55"))
		&"ornament_mult":
			return str(TranslationServer.translate(&"AUTO.TEXT.57E72BA166C1"))
		&"ornament_wild":
			return str(TranslationServer.translate(&"AUTO.TEXT.11582CECE2E0"))
		&"ornament_burst", &"material_glass":
			return str(TranslationServer.translate(&"AUTO.TEXT.DC80A8298359"))
		&"ornament_stay", &"material_steel":
			return str(TranslationServer.translate(&"AUTO.TEXT.A74D96EFFD75"))
		&"ornament_stone":
			return str(TranslationServer.translate(&"AUTO.TEXT.18257B5FA85D"))
		&"ornament_gold":
			return str(TranslationServer.translate(&"AUTO.TEXT.1CA08BEA94D3"))
		&"ornament_lucky":
			return str(TranslationServer.translate(&"AUTO.TEXT.E699B4E7996F"))
		&"ornament_foil":
			return str(TranslationServer.translate(&"AUTO.TEXT.CB14C28C4282"))
		&"ornament_holo":
			return str(TranslationServer.translate(&"AUTO.TEXT.E70A3C6E22B1"))
		&"ornament_poly":
			return str(TranslationServer.translate(&"AUTO.TEXT.2BF754A09305"))
		&"mark_red":
			return str(TranslationServer.translate(&"AUTO.TEXT.955AC7EBFC11"))
		&"mark_blue":
			return str(TranslationServer.translate(&"AUTO.TEXT.3FDF9FEFC7A8"))
		&"mark_purple":
			return str(TranslationServer.translate(&"AUTO.TEXT.05A8FE4EDC14"))
		&"mark_gold":
			return str(TranslationServer.translate(&"AUTO.TEXT.D5E268A322C9"))
		&"mark_white":
			return str(TranslationServer.translate(&"AUTO.TEXT.DA4587CAAA98"))
		&"upgrade_combo_scatter", &"upgrade_combo_pair", &"upgrade_combo_two_pair", &"upgrade_combo_three_kind", &"upgrade_combo_full_house", &"upgrade_combo_four_kind", &"upgrade_combo_straight", &"upgrade_combo_five_kind":
			return str(TranslationServer.translate(&"AUTO.TEXT.B147441759D4"))
		&"glass_1":
			return str(TranslationServer.translate(&"AUTO.TEXT.3A3EE1B5AB90"))
		&"cleanse":
			return str(TranslationServer.translate(&"AUTO.TEXT.8D4E7410F9F2"))
		&"rune_six", &"rune_straight", &"rune_pair", &"rune_odd", &"rune_even", &"upgrade_1":
			return str(TranslationServer.translate(&"AUTO.TEXT.594EF392D12F"))
		_:
			return ""


func _normalize_combo_id(combo_id: StringName) -> StringName:
	match combo_id:
		&"HIGH_CARD", &"high_card", &"SCATTER", &"scatter":
			return &"scatter"
		&"PAIR", &"pair":
			return &"pair"
		&"TWO_PAIR", &"two_pair":
			return &"two_pair"
		&"THREE_KIND", &"three_kind":
			return &"three_kind"
		&"FULL_HOUSE", &"full_house":
			return &"full_house"
		&"FOUR_KIND", &"four_kind":
			return &"four_kind"
		&"SMALL_STRAIGHT", &"LARGE_STRAIGHT", &"small_straight", &"large_straight", &"STRAIGHT", &"straight":
			return &"straight"
		&"FIVE_KIND", &"five_kind":
			return &"five_kind"
		_:
			return combo_id


func _make_op(op: StringName) -> ForgeOperationDef:
	var operation := ForgeOperationDef.new()
	operation.op = op
	return operation


func _make_int_op(op: StringName, value_int: int) -> ForgeOperationDef:
	var operation := _make_op(op)
	operation.value_int = value_int
	return operation


func _make_id_op(op: StringName, value_id: StringName) -> ForgeOperationDef:
	var operation := _make_op(op)
	operation.value_id = value_id
	return operation
