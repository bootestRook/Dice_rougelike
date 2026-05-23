extends RefCounted
class_name RunState


const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocService = preload("res://scripts/i18n/LocService.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const ComboUpgradeItem = preload("res://scripts/rules/combo/ComboUpgradeItem.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")


const MAX_RECENT_SETTLEMENT_LOGS := 5
const DEFAULT_ITEM_SLOT_CAPACITY := 3
const DEFAULT_DICE_TOOL_CAPACITY := 3
const ENCOUNTER_BATTLE := &"battle"
const ENCOUNTER_ELITE := &"elite"
const ENCOUNTER_BOSS := &"boss"
const ENCOUNTER_TYPE_MULTIPLIERS := {
	ENCOUNTER_BATTLE: 1.0,
	ENCOUNTER_ELITE: 1.5,
	ENCOUNTER_BOSS: 2.0,
}
const DANGER_BONUS_PERCENTS := [
	0,
	0,
	2,
	4,
	7,
	10,
	15,
	21,
	28,
	36,
	45,
	55,
	65,
]


var dice: Array[DieState] = []
var relic_ids: Array[StringName] = []
var item_ids: Array[StringName] = []
var item_slots: Array[ItemInstance] = []
var pending_item_ids: Array[StringName] = []
var item_slot_capacity: int = DEFAULT_ITEM_SLOT_CAPACITY
var last_copyable_used_item_id: StringName = &""
var dice_tools: Array[DiceToolState] = []
var installed_tools: Array[DiceToolState] = []
var dice_tool_capacity: int = DEFAULT_DICE_TOOL_CAPACITY
var battle_index: int = 0
var current_battle: BattleState = null
var last_reward_choices: Array = []
var pending_forge_piece: ForgePieceDef = null
var max_circles: int = 8
var current_circle_index: int = 0
var current_circle_action_count: int = 0
var current_encounter_node_type: StringName = ENCOUNTER_BATTLE
var max_battles: int = 8
var circle_base_scores: Array[int] = [
	300,
	500,
	750,
	1000,
	1500,
	2200,
	3200,
	4500,
]
var target_scores: Array[int] = []
var boss_battle_numbers: Array[int] = []
var run_won: bool = false
var run_lost: bool = false
var total_hands_scored: int = 0
var total_score_scored: int = 0
var best_hand_score: int = 0
var coins: int = 0
var shop_reroll_base_cost: int = 5
var shop_reroll_count_this_shop: int = 0
var shop_non_unlock_purchase_count_this_shop: int = 0
var shop_random_item_slot_bonus: int = 0
var shop_booster_slot_bonus: int = 0
var shop_random_item_discount: float = 0.0
var first_non_unlock_purchase_discount: float = 0.0
var first_reroll_free: bool = false
var shop_face_items_enabled: bool = false
var shop_advanced_face_display_slots: int = 0
var shop_forge_item_weight_multiplier: float = 1.0
var shop_combo_upgrade_weight_multiplier: float = 1.0
var shop_face_pack_weight_multiplier: float = 1.0
var shop_combo_pack_weight_multiplier: float = 1.0
var advanced_face_pack_rewards_enabled: bool = false
var forge_item_discount: float = 0.0
var combo_upgrade_discount: float = 0.0
var current_shop_state: Dictionary = {}
var pending_booster_resolution: Dictionary = {}
var shop_logs: Array[Dictionary] = []
var long_term_unlocks: Dictionary = {}
var long_term_unlock_effect_totals: Dictionary = {}
var battle_rerolls_per_hand_delta: int = 0
var face_pack_extra_candidates: int = 0
var advanced_ornament_weight_multiplier: float = 1.0
var forge_service_pack_enabled: bool = false
var forge_pack_extra_candidates: int = 0
var combo_pack_extra_candidates: int = 0
var combo_pack_include_most_played: bool = false
var observatory_enabled: bool = false
var observatory_used_this_battle: bool = false
var first_score_echo_enabled: bool = false
var first_score_echo_used_this_battle: bool = false
var unused_reroll_gold_enabled: bool = false
var interest_enabled: bool = false
var interest_cap: int = 0
var money_tree_enabled: bool = false
var contract_tool_slots: int = 0
var loop_first_battles_danger_reduction_count: int = 0
var danger_action_count_reduction: int = 0
var boss_danger_action_count_reduction: int = 0
var free_boss_rule_reroll_per_loop: int = 0
var boss_rule_choice_count: int = 1
var long_term_boss_rule_grace_per_battle: int = 0
var installed_piece_count: int = 0
var installed_piece_history: Array[Dictionary] = []
var recent_settlement_logs: Array[Dictionary] = []
var recent_hand_summaries: Array[String] = []
var effect_trigger_counts: Dictionary = {}
var effect_trigger_order: Array[StringName] = []
var combo_appearance_counts: Dictionary = {}
var combo_scored_counts: Dictionary = {}
var combo_last_formula_by_id: Dictionary = {}
var combo_levels: Dictionary = {}
var used_forge_item_count: int = 0
var used_combo_upgrade_item_ids: Dictionary = {}
var pending_double_reward_tags: int = 0
var starting_total_face_count: int = 0
var skipped_battle_node_count: int = 0
var battle_rounds_available_delta: int = 0
var max_scored_faces_per_round_delta: int = 0
var battle_reward_choice_bonus: int = 0
var pending_dice_tool_face_copy: Dictionary = {}
var foundry_logs: Array[Dictionary] = []


func _init() -> void:
	installed_tools = dice_tools


func setup_new_run() -> void:
	battle_index = 0
	current_circle_index = 0
	current_circle_action_count = 0
	current_encounter_node_type = ENCOUNTER_BATTLE
	max_battles = max_circles
	target_scores = circle_base_scores
	current_battle = null
	last_reward_choices.clear()
	pending_forge_piece = null
	item_ids.clear()
	item_slots.clear()
	pending_item_ids.clear()
	item_slot_capacity = DEFAULT_ITEM_SLOT_CAPACITY
	last_copyable_used_item_id = &""
	dice_tools.clear()
	installed_tools = dice_tools
	dice_tool_capacity = DEFAULT_DICE_TOOL_CAPACITY
	run_won = false
	run_lost = false
	total_hands_scored = 0
	total_score_scored = 0
	best_hand_score = 0
	coins = 0
	shop_reroll_base_cost = 5
	shop_reroll_count_this_shop = 0
	shop_non_unlock_purchase_count_this_shop = 0
	shop_random_item_slot_bonus = 0
	shop_booster_slot_bonus = 0
	shop_random_item_discount = 0.0
	first_non_unlock_purchase_discount = 0.0
	first_reroll_free = false
	shop_face_items_enabled = false
	shop_advanced_face_display_slots = 0
	shop_forge_item_weight_multiplier = 1.0
	shop_combo_upgrade_weight_multiplier = 1.0
	shop_face_pack_weight_multiplier = 1.0
	shop_combo_pack_weight_multiplier = 1.0
	advanced_face_pack_rewards_enabled = false
	forge_item_discount = 0.0
	combo_upgrade_discount = 0.0
	current_shop_state.clear()
	pending_booster_resolution.clear()
	shop_logs.clear()
	long_term_unlocks.clear()
	long_term_unlock_effect_totals.clear()
	battle_rerolls_per_hand_delta = 0
	face_pack_extra_candidates = 0
	advanced_ornament_weight_multiplier = 1.0
	forge_service_pack_enabled = false
	forge_pack_extra_candidates = 0
	combo_pack_extra_candidates = 0
	combo_pack_include_most_played = false
	observatory_enabled = false
	observatory_used_this_battle = false
	first_score_echo_enabled = false
	first_score_echo_used_this_battle = false
	unused_reroll_gold_enabled = false
	interest_enabled = false
	interest_cap = 0
	money_tree_enabled = false
	contract_tool_slots = 0
	loop_first_battles_danger_reduction_count = 0
	danger_action_count_reduction = 0
	boss_danger_action_count_reduction = 0
	free_boss_rule_reroll_per_loop = 0
	boss_rule_choice_count = 1
	long_term_boss_rule_grace_per_battle = 0
	installed_piece_count = 0
	installed_piece_history.clear()
	recent_settlement_logs.clear()
	recent_hand_summaries.clear()
	effect_trigger_counts.clear()
	effect_trigger_order.clear()
	combo_appearance_counts.clear()
	combo_scored_counts.clear()
	combo_last_formula_by_id.clear()
	combo_levels = ComboUpgradeCatalog.default_combo_levels()
	used_forge_item_count = 0
	used_combo_upgrade_item_ids.clear()
	pending_double_reward_tags = 0
	starting_total_face_count = 0
	skipped_battle_node_count = 0
	battle_rounds_available_delta = 0
	max_scored_faces_per_round_delta = 0
	battle_reward_choice_bonus = 0
	pending_dice_tool_face_copy.clear()
	foundry_logs.clear()
	create_default_loadout()
	starting_total_face_count = get_total_face_count()


func create_default_loadout() -> void:
	dice.clear()

	for die_index in range(6):
		dice.append(DieState.create_normal_d6(StringName("normal_d6_%d" % [die_index + 1])))


func ensure_starting_dice() -> void:
	if dice.is_empty():
		create_default_loadout()
	if starting_total_face_count <= 0:
		starting_total_face_count = get_total_face_count()


func get_total_face_count() -> int:
	var total := 0
	for die in dice:
		if die != null:
			total += die.face_count
	return total


func advance_battle() -> void:
	var completed_node_type := current_encounter_node_type
	battle_index += 1
	current_battle = null
	if completed_node_type == ENCOUNTER_BOSS:
		advance_circle_after_boss()
	current_encounter_node_type = ENCOUNTER_BATTLE


func advance_circle_after_boss() -> void:
	if current_circle_index < maxi(0, max_circles - 1):
		current_circle_index += 1
	reset_circle_pressure()


func reset_circle_pressure() -> void:
	current_circle_action_count = 0


func record_map_movement_action() -> void:
	current_circle_action_count += 1


func set_current_encounter_node_type(node_type: StringName) -> void:
	current_encounter_node_type = normalized_encounter_node_type(node_type)


func normalized_encounter_node_type(node_type: StringName) -> StringName:
	match node_type:
		ENCOUNTER_ELITE:
			return ENCOUNTER_ELITE
		ENCOUNTER_BOSS:
			return ENCOUNTER_BOSS
		_:
			return ENCOUNTER_BATTLE


func get_circle_number() -> int:
	return current_circle_index + 1


func get_current_circle_base_score() -> int:
	if circle_base_scores.is_empty():
		return 850

	var index: int = clampi(current_circle_index, 0, circle_base_scores.size() - 1)
	return circle_base_scores[index]


func get_current_circle_adjusted_base_score(action_count: int = -1) -> int:
	return int(round(float(get_current_circle_base_score()) * get_danger_multiplier(action_count)))


func get_danger_bonus_percent(action_count: int = -1) -> int:
	var resolved_count := current_circle_action_count if action_count < 0 else action_count
	if resolved_count <= 0:
		return 0
	var index := mini(resolved_count, DANGER_BONUS_PERCENTS.size() - 1)
	return int(DANGER_BONUS_PERCENTS[index])


func get_effective_danger_action_count(node_type: StringName = &"", action_count: int = -1) -> int:
	var resolved_count := current_circle_action_count if action_count < 0 else action_count
	var resolved_type := current_encounter_node_type if node_type == &"" else normalized_encounter_node_type(node_type)
	var reduction := 0
	if resolved_type == ENCOUNTER_BOSS:
		reduction += max(0, boss_danger_action_count_reduction)
	elif loop_first_battles_danger_reduction_count > 0 and resolved_count <= loop_first_battles_danger_reduction_count:
		reduction += max(0, danger_action_count_reduction)
	return max(0, resolved_count - reduction)


func get_danger_bonus_percent_for_node(node_type: StringName = &"", action_count: int = -1) -> int:
	return get_danger_bonus_percent(get_effective_danger_action_count(node_type, action_count))


func get_danger_multiplier_for_node(node_type: StringName = &"", action_count: int = -1) -> float:
	return 1.0 + float(get_danger_bonus_percent_for_node(node_type, action_count)) / 100.0


func get_danger_multiplier(action_count: int = -1) -> float:
	return 1.0 + float(get_danger_bonus_percent(action_count)) / 100.0


func get_encounter_type_multiplier(node_type: StringName = &"") -> float:
	var resolved_type := current_encounter_node_type if node_type == &"" else normalized_encounter_node_type(node_type)
	return float(ENCOUNTER_TYPE_MULTIPLIERS.get(resolved_type, 1.0))


func get_target_score(node_type: StringName = &"") -> int:
	var base_score := get_current_circle_base_score()
	var resolved_type := current_encounter_node_type if node_type == &"" else normalized_encounter_node_type(node_type)
	var multiplier := get_encounter_type_multiplier(resolved_type)
	var danger_multiplier := get_danger_multiplier_for_node(resolved_type)
	return int(round(float(base_score) * multiplier * danger_multiplier))


func get_target_breakdown(node_type: StringName = &"") -> Dictionary:
	var resolved_type := current_encounter_node_type if node_type == &"" else normalized_encounter_node_type(node_type)
	return {
		"circle": get_circle_number(),
		"base_score": get_current_circle_base_score(),
		"encounter_type": resolved_type,
		"encounter_multiplier": get_encounter_type_multiplier(resolved_type),
		"action_count": current_circle_action_count,
		"effective_danger_action_count": get_effective_danger_action_count(resolved_type),
		"danger_bonus_percent": get_danger_bonus_percent_for_node(resolved_type),
		"danger_multiplier": get_danger_multiplier_for_node(resolved_type),
		"target_score": get_target_score(resolved_type),
	}


func has_free_item_slot() -> bool:
	ensure_item_slots_from_legacy()
	return item_slots.size() < max(0, item_slot_capacity)


func get_free_item_slot_count() -> int:
	ensure_item_slots_from_legacy()
	return max(0, item_slot_capacity - item_slots.size())


func add_item_to_inventory_or_pending(item_id: StringName, item_type: StringName = &"") -> bool:
	if item_id == &"":
		return false
	var item := _make_item_instance_from_id(item_id)
	if item_type != &"":
		item.item_type = item_type
	return add_item_instance_to_slots(item)


func add_item_instance_to_slots(item: ItemInstance) -> bool:
	ensure_item_slots_from_legacy()
	if item == null or item.item_id == &"":
		return false
	if not has_free_item_slot():
		return false
	item_slots.append(item.clone_as_new())
	_sync_item_ids_from_slots()
	return true


func add_coins(amount: int, _source: StringName = &"") -> void:
	coins = max(get_min_allowed_coins(), coins + amount)


func get_shop_reroll_cost() -> int:
	return max(1, shop_reroll_base_cost + shop_reroll_count_this_shop)


func get_shop_random_item_slot_count() -> int:
	return max(0, 2 + shop_random_item_slot_bonus)


func get_shop_relic_shelf_slot_count() -> int:
	return get_shop_random_item_slot_count()


func get_shop_booster_slot_count() -> int:
	return max(0, 2 + shop_booster_slot_bonus)


func get_most_scored_combo_id() -> StringName:
	var best_combo: StringName = &""
	var best_count := 0
	for raw_id in combo_scored_counts.keys():
		var combo_id := _normalized_combo_id(StringName(str(raw_id)))
		var count := int(combo_scored_counts.get(raw_id, 0))
		if combo_id != &"" and count > best_count:
			best_combo = combo_id
			best_count = count
	if best_combo != &"":
		return best_combo

	for raw_id in combo_appearance_counts.keys():
		var combo_id := _normalized_combo_id(StringName(str(raw_id)))
		var count := int(combo_appearance_counts.get(raw_id, 0))
		if combo_id != &"" and count > best_count:
			best_combo = combo_id
			best_count = count
	return best_combo


func has_long_term_unlock(unlock_id: StringName) -> bool:
	return bool(long_term_unlocks.get(unlock_id, false))


func add_long_term_unlock_effect(effect_type: StringName, amount: int) -> void:
	if effect_type == &"" or amount == 0:
		return
	long_term_unlock_effect_totals[effect_type] = int(long_term_unlock_effect_totals.get(effect_type, 0)) + amount


func get_long_term_unlock_effect_total(effect_type: StringName) -> int:
	return int(long_term_unlock_effect_totals.get(effect_type, 0))


func consume_item_slot(slot_index: int) -> ItemInstance:
	ensure_item_slots_from_legacy()
	if slot_index < 0 or slot_index >= item_slots.size():
		return null
	var item := item_slots[slot_index]
	item_slots.remove_at(slot_index)
	_sync_item_ids_from_slots()
	return item


func find_item_slot_index(item_id: StringName) -> int:
	ensure_item_slots_from_legacy()
	for index in range(item_slots.size()):
		var item := item_slots[index]
		if item != null and item.item_id == item_id:
			return index
	return -1


func remove_first_item_by_id(item_id: StringName) -> ItemInstance:
	var index := find_item_slot_index(item_id)
	if index < 0:
		return null
	return consume_item_slot(index)


func ensure_item_slots_from_legacy() -> void:
	if not item_slots.is_empty() or item_ids.is_empty():
		return
	for item_id in item_ids:
		item_slots.append(_make_item_instance_from_id(item_id))
	_sync_item_ids_from_slots()


func record_copyable_used_item_id(item_id: StringName) -> void:
	if _is_copyable_item_id(item_id):
		last_copyable_used_item_id = item_id


func has_free_dice_tool_slot() -> bool:
	return get_non_negative_dice_tool_count() < max(0, dice_tool_capacity + contract_tool_slots)


func get_free_dice_tool_slot_count() -> int:
	return max(0, dice_tool_capacity + contract_tool_slots - get_non_negative_dice_tool_count())


func get_non_negative_dice_tool_count() -> int:
	_sync_installed_tools_alias()
	var count := 0
	for tool in dice_tools:
		if tool != null and not tool.is_negative:
			count += 1
	return count


func get_empty_regular_dice_tool_slot_count() -> int:
	return max(0, dice_tool_capacity - _regular_dice_tool_count())


func get_min_allowed_coins() -> int:
	_sync_installed_tools_alias()
	var minimum := 0
	for tool in dice_tools:
		if tool != null and tool.tool_id == DiceToolCatalog.TOOL_CREDIT_DEBT:
			minimum = min(minimum, -20)
	return minimum


func install_dice_tool_item_from_slot(slot_index: int) -> bool:
	ensure_item_slots_from_legacy()
	if slot_index < 0 or slot_index >= item_slots.size():
		return false
	var item := item_slots[slot_index]
	if item == null or item.item_type != ItemInstance.TYPE_DICE_TOOL:
		return false
	var tool = DiceToolState.from_item_instance(item)
	if tool == null:
		return false
	if not install_dice_tool_state(tool):
		return false
	consume_item_slot(slot_index)
	return true


func install_dice_tool_item_instance(item: ItemInstance) -> bool:
	if item == null or item.item_type != ItemInstance.TYPE_DICE_TOOL:
		return false
	var tool = DiceToolState.from_item_instance(item)
	if tool == null:
		return false
	return install_dice_tool_state(tool)


func install_dice_tool_state(tool: DiceToolState) -> bool:
	if tool == null or tool.tool_id == &"":
		return false
	var slot_type := _dice_tool_slot_type_for_install(tool.rarity)
	if slot_type == &"":
		return false
	var installed_tool = tool.clone_without_combat_counters(true)
	installed_tool.metadata["slot_type"] = slot_type
	dice_tools.append(installed_tool)
	installed_tools = dice_tools
	return true


func remove_dice_tool_at_index(slot_index: int):
	_sync_installed_tools_alias()
	if slot_index < 0 or slot_index >= dice_tools.size():
		return null
	var removed := dice_tools[slot_index]
	dice_tools.remove_at(slot_index)
	installed_tools = dice_tools
	return removed


func install_dice_tool_item(item_id: StringName) -> bool:
	var slot_index := find_item_slot_index(item_id)
	if slot_index < 0:
		return false
	return install_dice_tool_item_from_slot(slot_index)


func is_final_battle() -> bool:
	return is_boss_battle() and current_circle_index >= max_circles - 1


func is_boss_battle() -> bool:
	return current_encounter_node_type == ENCOUNTER_BOSS


func mark_run_won() -> void:
	run_won = true
	run_lost = false
	pending_forge_piece = null
	last_reward_choices.clear()


func mark_run_lost() -> void:
	run_lost = true
	run_won = false
	pending_forge_piece = null


func record_hand_score(score_or_result, hand_number: int = 0) -> void:
	var score := 0
	var result: ScoreResult = null
	if score_or_result is ScoreResult:
		result = score_or_result
		score = result.final_score
	else:
		score = int(score_or_result)

	total_hands_scored += 1
	total_score_scored += score
	best_hand_score = max(best_hand_score, score)

	if result != null:
		_record_settlement_result(result, hand_number)


func get_combo_appearance_count(combo_id: StringName) -> int:
	return int(combo_appearance_counts.get(_normalized_combo_id(combo_id), 0))


func get_combo_level(combo_id: StringName) -> int:
	ensure_combo_levels()
	var normalized_id := _normalized_combo_id(combo_id)
	if normalized_id == &"" or not ComboUpgradeCatalog.has_combo(normalized_id):
		return 1
	var def := ComboUpgradeCatalog.get_def(normalized_id)
	return max(1, int(combo_levels.get(def.upgrade_id, combo_levels.get(normalized_id, 1))))


func get_combo_last_formula(combo_id: StringName) -> Dictionary:
	var key := _normalized_combo_id(combo_id)
	if not combo_last_formula_by_id.has(key):
		return {}
	return combo_last_formula_by_id[key].duplicate(true)


func ensure_combo_levels() -> void:
	var migrated := {}
	for existing_id in combo_levels.keys():
		var normalized_id := ComboUpgradeCatalog.normalize_combo_id(StringName(str(existing_id)))
		if normalized_id == &"" or not ComboUpgradeCatalog.has_combo(normalized_id):
			continue
		var def := ComboUpgradeCatalog.get_def(normalized_id)
		var level_key := def.upgrade_id
		migrated[level_key] = max(
			int(migrated.get(level_key, 1)),
			max(1, int(combo_levels[existing_id]))
		)

	for combo_def in ComboUpgradeCatalog.get_all_defs():
		if not migrated.has(combo_def.upgrade_id):
			migrated[combo_def.upgrade_id] = 1

	combo_levels = migrated


func increase_combo_level(combo_id: StringName, amount: int = 1) -> bool:
	ensure_combo_levels()
	var normalized_id := _normalized_combo_id(combo_id)
	if normalized_id == &"" or not ComboUpgradeCatalog.has_combo(normalized_id):
		return false

	var def := ComboUpgradeCatalog.get_def(normalized_id)
	combo_levels[def.upgrade_id] = max(1, int(combo_levels.get(def.upgrade_id, 1))) + max(1, amount)
	return true


func apply_combo_upgrade_item(item: ComboUpgradeItem) -> bool:
	if item == null:
		return false
	ensure_combo_levels()
	return item.apply_to_combo_levels(combo_levels)


func use_item(item_id: StringName) -> bool:
	var item_index := find_item_slot_index(item_id)
	if item_index < 0:
		return false

	var item := ComboUpgradeItem.from_item_id(item_id)
	if item == null:
		return false

	if not apply_combo_upgrade_item(item):
		return false

	consume_item_slot(item_index)
	record_copyable_used_item_id(item_id)
	used_combo_upgrade_item_ids[item_id] = true
	for tool in dice_tools:
		if tool != null and tool.tool_id == DiceToolCatalog.TOOL_STAR_COUNTER:
			tool.permanent_counters["combo_upgrade_used_count"] = int(tool.permanent_counters.get("combo_upgrade_used_count", 0)) + 1
	return true


func apply_combo_upgrade_piece(piece: ForgePieceDef) -> bool:
	if piece == null:
		return false
	for operation in piece.get_operations():
		if operation == null or operation.get_effective_op() != ForgeOperationDef.OP_COMBO_UPGRADE:
			continue
		return increase_combo_level(operation.get_effective_value_id())
	return false


func record_installed_piece(piece: ForgePieceDef, die_index: int, face_index: int) -> void:
	if piece == null:
		return

	installed_piece_count += 1
	installed_piece_history.append({
		"battle": battle_index + 1,
		"battle_index": battle_index,
		"piece_key": piece.get_name_key(),
		"piece_id": piece.id,
		"piece_name": piece.get_display_name(),
		"piece_tags": piece.get_tags(),
		"piece_tags_text": piece.get_tags_display_text(),
		"die": die_index + 1,
		"face": face_index + 1,
		"die_index": die_index,
		"face_index": face_index,
	})


func has_installed_piece_on_face(die_index: int, face_index: int) -> bool:
	for item in installed_piece_history:
		if int(item.get("die_index", -1)) == die_index and int(item.get("face_index", -1)) == face_index:
			return true

	return false


func get_run_summary_text() -> String:
	var lines := PackedStringArray()
	lines.append("当前圈数：%d / %d" % [min(get_circle_number() + (1 if run_won else 0), max_circles), max_circles])
	lines.append("已完成战斗：%d" % [battle_index])
	lines.append("本圈行动：%d 次，危急值：+%d%%" % [current_circle_action_count, get_danger_bonus_percent()])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.AAD002B83E9D")) % [total_hands_scored])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.2444EE1FC9E1")) % [total_score_scored])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.F31F59CBCB2C")) % [best_hand_score])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.220EE7ACC516")) % [coins])
	lines.append(_most_triggered_effect_summary_text())
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.E69FDA851F52")) % [installed_piece_count])
	lines.append(get_installed_piece_history_text())
	lines.append("")
	_append_recent_settlement_text(lines)
	return "\n".join(lines)


func get_installed_piece_history_text() -> String:
	if installed_piece_history.is_empty():
		return str(TranslationServer.translate(&"AUTO.TEXT.5811C61314A1"))

	var lines := PackedStringArray()
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.B5D005020079")))
	for item in installed_piece_history:
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.1DE727CACA95")) % [
			int(item.get("battle", 0)),
			str(item.get("piece_name", "")),
			int(item.get("die", 0)),
			int(item.get("face", 0)),
		])
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.ABAAFC3C7A71")) % [str(item.get("piece_tags_text", str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))))])
	return "\n".join(lines)


func get_recent_hand_summaries_text() -> String:
	var lines := PackedStringArray()
	_append_recent_settlement_text(lines)
	return "\n".join(lines)


func clone_dice() -> Array[DieState]:
	var cloned_dice: Array[DieState] = []

	for die in dice:
		cloned_dice.append(die.clone())

	return cloned_dice


func _record_settlement_result(result: ScoreResult, hand_number: int) -> void:
	recent_settlement_logs.append({
		"battle": battle_index + 1,
		"hand": hand_number,
		"score": result.final_score,
		"result": result,
	})
	recent_hand_summaries.append(str(TranslationServer.translate(&"AUTO.TEXT.91E79785325C")) % [
		battle_index + 1,
		hand_number,
		result.final_score,
		result.get_summary_text_zh(),
	])

	while recent_settlement_logs.size() > MAX_RECENT_SETTLEMENT_LOGS:
		recent_settlement_logs.remove_at(0)
	while recent_hand_summaries.size() > MAX_RECENT_SETTLEMENT_LOGS:
		recent_hand_summaries.remove_at(0)

	_record_combo_stats(result, hand_number)
	_record_effect_triggers(result)


func _record_combo_stats(result: ScoreResult, hand_number: int) -> void:
	if result == null:
		return
	var combo_id := result.primary_combo
	if combo_id == &"":
		combo_id = result.combo_id
	combo_id = _normalized_combo_id(combo_id)
	if combo_id == &"":
		return

	combo_appearance_counts[combo_id] = int(combo_appearance_counts.get(combo_id, 0)) + 1
	ensure_combo_levels()
	combo_last_formula_by_id[combo_id] = {
		"chips": result.combo_chips_bonus,
		"mult": result.combo_mult,
		"battle": battle_index + 1,
		"hand": hand_number,
	}


func _normalized_combo_id(combo_id: StringName) -> StringName:
	return ComboUpgradeCatalog.normalize_combo_id(combo_id)


func record_foundry_log(service_id: StringName, service_name: String, message: String, details: Dictionary = {}) -> void:
	foundry_logs.append({
		"battle": battle_index + 1,
		"service_id": service_id,
		"service_name": service_name,
		"message": message,
		"details": details.duplicate(true),
		"coins": coins,
	})


func record_shop_log(message: String, details: Dictionary = {}) -> void:
	if message == "":
		return
	shop_logs.append({
		"battle": battle_index + 1,
		"message": message,
		"details": details.duplicate(true),
		"coins": coins,
	})


func _regular_dice_tool_count() -> int:
	_sync_installed_tools_alias()
	var count := 0
	for tool in dice_tools:
		if tool == null or tool.is_negative:
			continue
		if StringName(str(tool.metadata.get("slot_type", &"regular"))) != &"contract":
			count += 1
	return count


func _contract_dice_tool_count() -> int:
	_sync_installed_tools_alias()
	var count := 0
	for tool in dice_tools:
		if tool != null and not tool.is_negative and StringName(str(tool.metadata.get("slot_type", &"regular"))) == &"contract":
			count += 1
	return count


func _dice_tool_slot_type_for_install(rarity: StringName) -> StringName:
	if _regular_dice_tool_count() < max(0, dice_tool_capacity):
		return &"regular"
	if _contract_dice_tool_count() >= max(0, contract_tool_slots):
		return &""
	if rarity == &"common" or rarity == &"uncommon":
		return &"contract"
	return &""


func _sync_installed_tools_alias() -> void:
	if dice_tools.is_empty() and not installed_tools.is_empty():
		dice_tools = installed_tools
	elif installed_tools.is_empty() and not dice_tools.is_empty():
		installed_tools = dice_tools


func _record_effect_triggers(result: ScoreResult) -> void:
	for entry in result.logs:
		if entry == null or not _is_counted_effect_category(entry.category):
			continue

		if not effect_trigger_counts.has(entry.category):
			effect_trigger_order.append(entry.category)
			effect_trigger_counts[entry.category] = 0
		effect_trigger_counts[entry.category] = int(effect_trigger_counts[entry.category]) + 1


func _is_counted_effect_category(category: StringName) -> bool:
	match category:
		&"ornament_chip", &"ornament_mult", &"ornament_wild", &"ornament_burst", &"ornament_stay", &"ornament_stone", &"ornament_gold", &"ornament_lucky", &"ornament_foil", &"ornament_holo", &"ornament_poly", &"mark_blue", &"mark_red", &"mark_purple", &"mark_gold", &"mark_white", &"extra_pip", &"body_iron", &"body_hollow", &"body_mirror", &"body_cracked", &"body_merchant", &"dice_tool":
			return true
		_:
			return false


func _most_triggered_effect_summary_text() -> String:
	var category := _most_triggered_effect_category()
	if category == &"":
		return str(TranslationServer.translate(&"AUTO.TEXT.1B8190006657"))

	return str(TranslationServer.translate(&"AUTO.TEXT.35BAEA2DB315")) % [
		_effect_category_text(category),
		int(effect_trigger_counts.get(category, 0)),
	]


func _most_triggered_effect_category() -> StringName:
	var best_category: StringName = &""
	var best_count := 0
	for category in effect_trigger_order:
		var count := int(effect_trigger_counts.get(category, 0))
		if count > best_count:
			best_category = category
			best_count = count
	return best_category


func _effect_category_text(category: StringName) -> String:
	match category:
		&"ornament_chip":
			return DisplayNames.ornament_name(&"orn_chip")
		&"ornament_mult":
			return DisplayNames.ornament_name(&"orn_mult")
		&"ornament_wild":
			return DisplayNames.ornament_name(&"orn_wild")
		&"ornament_burst":
			return DisplayNames.ornament_name(&"orn_burst")
		&"ornament_stay":
			return DisplayNames.ornament_name(&"orn_stay")
		&"ornament_stone":
			return DisplayNames.ornament_name(&"orn_stone")
		&"ornament_gold":
			return DisplayNames.ornament_name(&"orn_gold")
		&"ornament_lucky":
			return DisplayNames.ornament_name(&"orn_lucky")
		&"ornament_foil":
			return DisplayNames.ornament_name(&"orn_foil")
		&"ornament_holo":
			return DisplayNames.ornament_name(&"orn_holo")
		&"ornament_poly":
			return DisplayNames.ornament_name(&"orn_poly")
		&"mark_blue":
			return DisplayNames.mark_name(&"blue")
		&"mark_red":
			return DisplayNames.mark_name(&"red")
		&"mark_purple":
			return DisplayNames.mark_name(&"purple")
		&"mark_gold":
			return DisplayNames.mark_name(&"mark_gold")
		&"mark_white":
			return DisplayNames.mark_name(&"mark_white")
		&"extra_pip":
			return str(TranslationServer.translate(&"AUTO.TEXT.121760C4E89D"))
		&"body_iron":
			return DisplayNames.body_name(DieState.BODY_IRON)
		&"body_hollow":
			return DisplayNames.body_name(DieState.BODY_HOLLOW)
		&"body_mirror":
			return DisplayNames.body_name(DieState.BODY_MIRROR)
		&"body_cracked":
			return DisplayNames.body_name(DieState.BODY_CRACKED)
		&"body_merchant":
			return DisplayNames.body_name(DieState.BODY_MERCHANT)
		&"dice_tool":
			return "骰具"
		_:
			return str(category)


func _sync_item_ids_from_slots() -> void:
	item_ids.clear()
	for item in item_slots:
		if item != null and item.item_id != &"":
			item_ids.append(item.item_id)


func _make_item_instance_from_id(item_id: StringName) -> ItemInstance:
	var combo_item := ComboUpgradeItem.from_item_id(item_id)
	if combo_item != null:
		return ItemInstance.create_combo_upgrade(item_id)

	var forge_def := ForgeItemCatalog.get_def(item_id)
	if forge_def != null:
		return ItemInstance.create_forge_item(item_id, forge_def.get_display_name())

	for tool_data in ForgeItemCatalog.get_dice_tool_item_pool():
		if StringName(str(tool_data.get("id", &""))) == item_id:
			var item: ItemInstance = ItemInstance.create_dice_tool(
				item_id,
				str(tool_data.get("name", item_id)),
				int(tool_data.get("sell_value", 0))
			)
			item.metadata["rarity"] = StringName(str(tool_data.get("rarity", &"common")))
			return item

	return ItemInstance.create(item_id, ItemInstance.TYPE_GENERIC, str(item_id))


func _is_copyable_item_id(item_id: StringName) -> bool:
	if item_id == &"" or item_id == ForgeItemCatalog.FORGE_ECHO_COPY:
		return false
	if ComboUpgradeItem.from_item_id(item_id) != null:
		return true
	return ForgeItemCatalog.has_forge_item(item_id)


func _append_recent_settlement_text(lines: PackedStringArray) -> void:
	if recent_settlement_logs.is_empty():
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.883EA5139D05")))
		return

	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.1F6C99CA29E0")) % [recent_settlement_logs.size(), MAX_RECENT_SETTLEMENT_LOGS])
	for item in recent_settlement_logs:
		var result: ScoreResult = item.get("result") as ScoreResult
		if result == null:
			continue

		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.2B299868C5C9")) % [
			int(item.get("battle", 0)),
			int(item.get("hand", 0)),
			int(item.get("score", 0)),
		])
		lines.append(result.get_summary_text_zh())
