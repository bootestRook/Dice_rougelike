extends RefCounted
class_name RewardGenerator


const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


const STARTER_POOL_IDS := [
	&"pip_6",
	&"pip_3",
	&"red_6",
	&"glass_1",
	&"material_glass",
	&"material_steel",
	&"mark_blue",
	&"rune_six",
	&"rune_even",
	&"rune_odd",
	&"upgrade_1",
]

const FULL_REWARD_POOL_IDS := [
	&"pip_6",
	&"pip_1",
	&"pip_3",
	&"mark_red",
	&"mark_blue",
	&"material_glass",
	&"material_steel",
	&"rune_six",
	&"rune_straight",
	&"rune_pair",
	&"rune_odd",
	&"rune_even",
	&"upgrade_1",
	&"red_6",
	&"glass_1",
]

const DIRECT_POWER_IDS := [
	&"red_6",
	&"glass_1",
	&"material_glass",
	&"material_steel",
	&"mark_blue",
	&"rune_six",
	&"rune_even",
	&"rune_odd",
	&"upgrade_1",
	&"pip_6",
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


func _build_reward_pool_for_battle(battle_index: int) -> Array[ForgePieceDef]:
	if battle_index <= 1:
		return _build_pool_from_ids(STARTER_POOL_IDS)

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
		&"pip_6": _make_piece(&"pip_6", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 6)], &"common", [&"six_build", &"high_pip"]),
		&"pip_1": _make_piece(&"pip_1", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 1)], &"common", [&"low_pip"]),
		&"pip_3": _make_piece(&"pip_3", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 3)], &"common", [&"odd_build", &"low_pip"]),
		&"mark_red": _make_piece(&"mark_red", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"red")], &"common", [&"single_face", &"retrigger"]),
		&"mark_blue": _make_piece(&"mark_blue", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"blue")], &"common", [&"unselected", &"mult_build"]),
		&"material_glass": _make_piece(&"material_glass", [_make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"glass")], &"common", [&"single_face", &"xmult_build"]),
		&"material_steel": _make_piece(&"material_steel", [_make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"steel")], &"common", [&"unselected", &"mult_build"]),
		&"rune_six": _make_piece(&"rune_six", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"six")], &"common", [&"six_build", &"mult_build"]),
		&"rune_straight": _make_piece(&"rune_straight", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"straight")], &"common", [&"straight_build", &"chips_build"]),
		&"rune_pair": _make_piece(&"rune_pair", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"pair")], &"common", [&"pair_build", &"retrigger"]),
		&"rune_odd": _make_piece(&"rune_odd", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"odd")], &"common", [&"odd_build", &"mult_build"]),
		&"rune_even": _make_piece(&"rune_even", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"even")], &"common", [&"even_build", &"chips_build"]),
		&"upgrade_1": _make_piece(&"upgrade_1", [_make_int_op(ForgeOperationDef.OP_UPGRADE, 1)], &"common", [&"level_build", &"single_face"]),
		&"cleanse": _make_piece(&"cleanse", [_make_op(ForgeOperationDef.OP_CLEANSE)], &"common", [&"cleanse"]),
		&"red_6": _make_piece(&"red_6", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 6), _make_id_op(ForgeOperationDef.OP_SET_MARK, &"red")], &"common", [&"six_build", &"retrigger"]),
		&"glass_1": _make_piece(&"glass_1", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 1), _make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"glass")], &"common", [&"low_pip", &"xmult_build"]),
	}


func _make_piece(id: StringName, ops: Array, rarity: StringName = &"common", tags: Array = []) -> ForgePieceDef:
	var piece := ForgePieceDef.new()
	piece.id = id
	piece.name_key = LocKeys.forge_part_name_key(id)
	piece.desc_key = LocKeys.forge_part_desc_key(id)
	piece.rarity = rarity
	piece.rarity_key = LocKeys.rarity_key(rarity)
	for op_def in ops:
		if op_def is ForgeOperationDef:
			piece.operations.append(op_def)
	for tag in tags:
		if tag is StringName:
			piece.archetype_tags.append(tag)
		else:
			piece.archetype_tags.append(StringName(str(tag)))
	return piece


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
