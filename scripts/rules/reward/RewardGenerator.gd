extends RefCounted
class_name RewardGenerator


const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ForgeItemDef = preload("res://scripts/data_defs/ForgeItemDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const ComboUpgradeItem = preload("res://scripts/rules/combo/ComboUpgradeItem.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")


const NORMAL_REWARD_POOL_IDS := [
	&"pip_6",
	&"pip_1",
	&"pip_3",
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
	&"red_6",
	&"burst_1",
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


var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func generate_forge_choices(count: int = 3, battle_index: int = 0) -> Array[ForgePieceDef]:
	var pool := _build_reward_pool_for_battle(battle_index)
	var requested_count: int = max(0, count)
	var choices := _draw_unique_choices(pool, requested_count)
	_ensure_direct_power_choice(choices, pool)
	return choices


func generate_forge_choices_for_battle(count: int, battle_index: int) -> Array[ForgePieceDef]:
	return generate_forge_choices(count, battle_index)


func generate_forge_piece_choices(run_state: RunState, count: int = 3) -> Array[ForgePieceDef]:
	var battle_index := 0
	if run_state != null:
		battle_index = run_state.battle_index
	return generate_forge_choices(count, battle_index)


func generate_forge_item_choices(count: int = 3) -> Array[ForgeItemDef]:
	var choices: Array[ForgeItemDef] = []
	for id in _draw_unique_formal_forge_item_ids(ForgeItemCatalog.get_all_ids(), max(0, count)):
		var def := ForgeItemCatalog.get_def(id)
		if def != null:
			choices.append(def)
	return choices


func roll_random_forge_item(battle_index: int = 0) -> StringName:
	var pool := _build_reward_pool_for_battle(battle_index)
	if pool.is_empty():
		return &""
	return pool[rng.randi_range(0, pool.size() - 1)].id


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


func _ensure_direct_power_choice(choices: Array[ForgePieceDef], pool: Array[ForgePieceDef]) -> void:
	if choices.is_empty() or _has_direct_power_choice(choices):
		return

	var used_ids := {}
	for choice in choices:
		if choice != null:
			used_ids[choice.id] = true

	var candidates: Array[ForgePieceDef] = []
	for piece in pool:
		if piece != null and _is_direct_power_piece(piece) and not used_ids.has(piece.id):
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
	return piece != null and DIRECT_POWER_IDS.has(piece.id)


func _build_reward_pool_for_battle(_battle_index: int) -> Array[ForgePieceDef]:
	return _build_pool_from_ids(FULL_REWARD_POOL_IDS)


func _build_forge_piece_pool() -> Array[ForgePieceDef]:
	return _build_pool_from_ids(FULL_REWARD_POOL_IDS)


func _build_pool_from_ids(ids: Array) -> Array[ForgePieceDef]:
	var catalog := _build_piece_catalog()
	var pool: Array[ForgePieceDef] = []
	for id in ids:
		if catalog.has(id):
			pool.append(catalog[id])
	return pool


func _build_piece_catalog() -> Dictionary:
	return {
		&"pip_6": _make_piece(&"pip_6", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 6)], &"common", [&"six", &"power"]),
		&"pip_1": _make_piece(&"pip_1", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 1)], &"common", [&"low"]),
		&"pip_3": _make_piece(&"pip_3", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 3)], &"common", [&"straight", &"odd"]),
		&"ornament_chip": _make_piece(&"ornament_chip", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_chip")], &"common", [&"ornament", &"stable", &"chips"]),
		&"ornament_mult": _make_piece(&"ornament_mult", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_mult")], &"common", [&"ornament", &"mult"]),
		&"ornament_wild": _make_piece(&"ornament_wild", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_wild")], &"uncommon", [&"ornament", &"straight", &"stable"]),
		&"ornament_burst": _make_piece(&"ornament_burst", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_burst")], &"common", [&"ornament", &"burst", &"xmult"]),
		&"ornament_stay": _make_piece(&"ornament_stay", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_stay")], &"common", [&"ornament", &"stay", &"stable"]),
		&"ornament_stone": _make_piece(&"ornament_stone", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_stone")], &"common", [&"ornament", &"chips", &"stable"]),
		&"ornament_gold": _make_piece(&"ornament_gold", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_gold")], &"uncommon", [&"ornament", &"stay", &"stable"]),
		&"ornament_lucky": _make_piece(&"ornament_lucky", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_lucky")], &"uncommon", [&"ornament", &"mult"]),
		&"ornament_foil": _make_piece(&"ornament_foil", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_foil")], &"rare", [&"ornament", &"chips"]),
		&"ornament_holo": _make_piece(&"ornament_holo", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_holo")], &"rare", [&"ornament", &"mult"]),
		&"ornament_poly": _make_piece(&"ornament_poly", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_poly")], &"rare", [&"ornament", &"xmult"]),
		&"mark_red": _make_piece(&"mark_red", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_red")], &"common", [&"mark", &"extra_trigger", &"burst"]),
		&"mark_blue": _make_piece(&"mark_blue", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_blue")], &"common", [&"mark", &"stay", &"stable"]),
		&"mark_purple": _make_piece(&"mark_purple", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_purple")], &"common", [&"mark", &"reroll"]),
		&"mark_gold": _make_piece(&"mark_gold", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_gold")], &"uncommon", [&"mark", &"gold", &"stable"]),
		&"mark_white": _make_piece(&"mark_white", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_white")], &"rare", [&"mark", &"stable"]),
		&"upgrade_combo_scatter": _make_piece(&"upgrade_combo_scatter", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"scatter")], &"common", [&"upgrade", &"stable"]),
		&"upgrade_combo_pair": _make_piece(&"upgrade_combo_pair", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"pair")], &"common", [&"upgrade", &"stable"]),
		&"upgrade_combo_two_pair": _make_piece(&"upgrade_combo_two_pair", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"two_pair")], &"common", [&"upgrade", &"stable"]),
		&"upgrade_combo_three_kind": _make_piece(&"upgrade_combo_three_kind", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"three_kind")], &"common", [&"upgrade", &"stable"]),
		&"upgrade_combo_full_house": _make_piece(&"upgrade_combo_full_house", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"full_house")], &"common", [&"upgrade", &"stable"]),
		&"upgrade_combo_four_kind": _make_piece(&"upgrade_combo_four_kind", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"four_kind")], &"common", [&"upgrade", &"stable"]),
		&"upgrade_combo_straight": _make_piece(&"upgrade_combo_straight", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"straight")], &"common", [&"upgrade", &"stable"]),
		&"upgrade_combo_five_kind": _make_piece(&"upgrade_combo_five_kind", [_make_id_op(ForgeOperationDef.OP_COMBO_UPGRADE, &"five_kind")], &"common", [&"upgrade", &"stable"]),
		&"red_6": _make_piece(&"red_6", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 6), _make_id_op(ForgeOperationDef.OP_SET_MARK, &"mark_red")], &"common", [&"six", &"mark", &"extra_trigger", &"burst"]),
		&"burst_1": _make_piece(&"burst_1", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 1), _make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_burst")], &"common", [&"low", &"ornament", &"burst", &"xmult"]),
		&"stay_6": _make_piece(&"stay_6", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 6), _make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_stay")], &"common", [&"six", &"stay", &"ornament"]),
		&"cleanse": _make_piece(&"cleanse", [_make_op(ForgeOperationDef.OP_CLEANSE)], &"common", [&"stable"]),

		&"material_glass": _make_piece(&"material_glass", [_make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"glass")], &"common", [&"ornament", &"burst", &"xmult"]),
		&"material_steel": _make_piece(&"material_steel", [_make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"steel")], &"common", [&"ornament", &"stay", &"stable"]),
		&"glass_1": _make_piece(&"glass_1", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 1), _make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"glass")], &"common", [&"low", &"ornament", &"burst", &"xmult"]),
		&"rune_six": _make_piece(&"rune_six", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"six")], &"common", [&"six"]),
		&"rune_straight": _make_piece(&"rune_straight", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"straight")], &"common", [&"straight"]),
		&"rune_pair": _make_piece(&"rune_pair", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"pair")], &"common", [&"extra_trigger"]),
		&"rune_odd": _make_piece(&"rune_odd", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"odd")], &"common", [&"odd"]),
		&"rune_even": _make_piece(&"rune_even", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"even")], &"common", [&"even"]),
		&"upgrade_1": _make_piece(&"upgrade_1", [_make_int_op(ForgeOperationDef.OP_UPGRADE, 1)], &"common", [&"stable"]),
	}


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


func _display_name_for_id(id: StringName) -> String:
	var combo_item := ComboUpgradeItem.from_item_id(id)
	if combo_item != null:
		return combo_item.display_name

	match id:
		&"pip_6":
			return "点数片：6"
		&"pip_1":
			return "点数片：1"
		&"pip_3":
			return "点数片：3"
		&"ornament_chip":
			return "筹码面饰"
		&"ornament_mult":
			return "倍率面饰"
		&"ornament_wild":
			return "万能面饰"
		&"ornament_burst", &"material_glass":
			return "爆裂面饰"
		&"ornament_stay", &"material_steel":
			return "留场面饰"
		&"ornament_stone":
			return "石质面饰"
		&"ornament_gold":
			return "金辉面饰"
		&"ornament_lucky":
			return "幸运面饰"
		&"ornament_foil":
			return "箔光强化"
		&"ornament_holo":
			return "幻彩强化"
		&"ornament_poly":
			return "多彩强化"
		&"mark_red":
			return "红印"
		&"mark_blue":
			return "蓝印"
		&"mark_purple":
			return "紫印"
		&"mark_gold":
			return "金印"
		&"mark_white":
			return "白印"
		&"red_6":
			return "红印 6"
		&"burst_1", &"glass_1":
			return "爆裂 1"
		&"stay_6":
			return "留场 6"
		&"cleanse":
			return "净化件"
		&"rune_six", &"rune_straight", &"rune_pair", &"rune_odd", &"rune_even", &"upgrade_1":
			return "已停用铸骰件"
		_:
			return str(id)


func _description_for_id(id: StringName) -> String:
	if id == &"mark_red":
		return "该骰面被结算或未结算留场触发后，额外触发 1 次。"
	if id == &"mark_blue":
		return "若该骰面本手最终投出但未被选择结算，本手结束时生成主骰型升级件。"
	if id == &"mark_purple":
		return "该骰面被重投时生成 1 个随机铸骰件；每场战斗每个物理面最多成功触发 1 次。"
	if id == &"mark_gold":
		return "该骰面被结算并计分时获得 1 金币。"
	if id == &"mark_white":
		return "该骰面免疫 Boss 或负面规则；一场 Boss 战结束后移除。"
	if ComboUpgradeItem.from_item_id(id) != null:
		return "骰型升级件。由蓝印生成，占用 1 个道具槽位。"
	match id:
		&"pip_6":
			return "将一个骰面替换为 6。"
		&"pip_1":
			return "将一个骰面替换为 1。"
		&"pip_3":
			return "将一个骰面替换为 3。"
		&"ornament_chip":
			return "给一个骰面安装筹码面饰。被结算时 +30 基础战力。"
		&"ornament_mult":
			return "给一个骰面安装倍率面饰。被结算时 +4 Mult。"
		&"ornament_wild":
			return "给一个骰面安装万能面饰。结算前可选择临时点数参与点数判断。"
		&"ornament_burst", &"material_glass":
			return "给一个骰面安装爆裂面饰。被结算时终倍率 ×2，结算后可能破碎。"
		&"ornament_stay", &"material_steel":
			return "给一个骰面安装留场面饰。投出但未结算时，终倍率 ×1.5。"
		&"ornament_stone":
			return "给一个骰面安装石质面饰。被结算时 +50 基础战力，但不参与点数判断。"
		&"ornament_gold":
			return "给一个骰面安装金辉面饰。投出但未结算且本手成功结算后 +3 金币。"
		&"ornament_lucky":
			return "给一个骰面安装幸运面饰。被结算时独立概率获得 +20 Mult 或 +20 金币。"
		&"ornament_foil":
			return "给一个骰面安装箔光强化。被结算时 +50 基础战力。"
		&"ornament_holo":
			return "给一个骰面安装幻彩强化。被结算时 +10 Mult。"
		&"ornament_poly":
			return "给一个骰面安装多彩强化。被结算时终倍率 ×1.5。"
		&"mark_red":
			return "给一个骰面添加红印。该面被结算时额外触发一次。"
		&"mark_blue":
			return "给一个骰面添加蓝印。该面投出但未结算时触发留场收益。"
		&"mark_purple":
			return "给一个骰面添加紫印。该骰子本手被重投后出现时，触发额外收益。"
		&"mark_gold":
			return "给一个骰面添加金印。该面被结算并计分时获得 1 金币。"
		&"mark_white":
			return "给一个骰面添加白印。该面免疫 Boss 或负面规则，一场 Boss 战后移除。"
		&"upgrade_combo_scatter", &"upgrade_combo_pair", &"upgrade_combo_two_pair", &"upgrade_combo_three_kind", &"upgrade_combo_full_house", &"upgrade_combo_four_kind", &"upgrade_combo_straight", &"upgrade_combo_five_kind":
			return "骰型升级件。由蓝印生成，占用 1 个道具槽位。"
		&"red_6":
			return "将一个骰面替换为 6，并添加红印。"
		&"burst_1", &"glass_1":
			return "将一个骰面替换为 1，并安装爆裂面饰。"
		&"stay_6":
			return "将一个骰面替换为 6，并安装留场面饰。投出但未结算时提供收益。"
		&"cleanse":
			return "清除该骰面的负面面饰或负面印记。"
		&"rune_six", &"rune_straight", &"rune_pair", &"rune_odd", &"rune_even", &"upgrade_1":
			return "当前版本不启用该普通铸骰效果。"
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
