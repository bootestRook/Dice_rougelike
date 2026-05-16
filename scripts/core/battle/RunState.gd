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


const MAX_RECENT_SETTLEMENT_LOGS := 5
const DEFAULT_ITEM_SLOT_CAPACITY := 3
const DEFAULT_DICE_TOOL_CAPACITY := 3


var dice: Array[DieState] = []
var relic_ids: Array[StringName] = []
var item_ids: Array[StringName] = []
var item_slots: Array[ItemInstance] = []
var pending_item_ids: Array[StringName] = []
var item_slot_capacity: int = DEFAULT_ITEM_SLOT_CAPACITY
var last_copyable_used_item_id: StringName = &""
var dice_tools: Array[DiceToolState] = []
var dice_tool_capacity: int = DEFAULT_DICE_TOOL_CAPACITY
var battle_index: int = 0
var current_battle: BattleState = null
var last_reward_choices: Array[ForgePieceDef] = []
var pending_forge_piece: ForgePieceDef = null
var max_battles: int = 5
var target_scores: Array[int] = [1000, 1150, 1400, 1750, 2300]
var run_won: bool = false
var run_lost: bool = false
var total_hands_scored: int = 0
var total_score_scored: int = 0
var best_hand_score: int = 0
var coins: int = 0
var installed_piece_count: int = 0
var installed_piece_history: Array[Dictionary] = []
var recent_settlement_logs: Array[Dictionary] = []
var recent_hand_summaries: Array[String] = []
var effect_trigger_counts: Dictionary = {}
var effect_trigger_order: Array[StringName] = []
var combo_appearance_counts: Dictionary = {}
var combo_last_formula_by_id: Dictionary = {}
var combo_levels: Dictionary = {}


func setup_new_run() -> void:
	battle_index = 0
	current_battle = null
	last_reward_choices.clear()
	pending_forge_piece = null
	item_ids.clear()
	item_slots.clear()
	pending_item_ids.clear()
	item_slot_capacity = DEFAULT_ITEM_SLOT_CAPACITY
	last_copyable_used_item_id = &""
	dice_tools.clear()
	dice_tool_capacity = DEFAULT_DICE_TOOL_CAPACITY
	run_won = false
	run_lost = false
	total_hands_scored = 0
	total_score_scored = 0
	best_hand_score = 0
	coins = 0
	installed_piece_count = 0
	installed_piece_history.clear()
	recent_settlement_logs.clear()
	recent_hand_summaries.clear()
	effect_trigger_counts.clear()
	effect_trigger_order.clear()
	combo_appearance_counts.clear()
	combo_last_formula_by_id.clear()
	combo_levels = ComboUpgradeCatalog.default_combo_levels()
	create_default_loadout()


func create_default_loadout() -> void:
	dice.clear()

	for die_index in range(6):
		dice.append(DieState.create_normal_d6(StringName("normal_d6_%d" % [die_index + 1])))


func ensure_starting_dice() -> void:
	if dice.is_empty():
		create_default_loadout()


func advance_battle() -> void:
	battle_index += 1
	current_battle = null


func get_target_score() -> int:
	if target_scores.is_empty():
		return 1000

	var index: int = clampi(battle_index, 0, target_scores.size() - 1)
	return target_scores[index]


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
	coins += amount


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
	return dice_tools.size() < max(0, dice_tool_capacity)


func install_dice_tool_item_from_slot(slot_index: int) -> bool:
	ensure_item_slots_from_legacy()
	if not has_free_dice_tool_slot():
		return false
	if slot_index < 0 or slot_index >= item_slots.size():
		return false
	var item := item_slots[slot_index]
	if item == null or item.item_type != ItemInstance.TYPE_DICE_TOOL:
		return false
	var tool = DiceToolState.from_item_instance(item)
	if tool == null:
		return false
	dice_tools.append(tool)
	consume_item_slot(slot_index)
	return true


func install_dice_tool_item(item_id: StringName) -> bool:
	var slot_index := find_item_slot_index(item_id)
	if slot_index < 0:
		return false
	return install_dice_tool_item_from_slot(slot_index)


func is_final_battle() -> bool:
	return battle_index >= max_battles - 1


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
	return max(1, int(combo_levels.get(_normalized_combo_id(combo_id), 1)))


func get_combo_last_formula(combo_id: StringName) -> Dictionary:
	var key := _normalized_combo_id(combo_id)
	if not combo_last_formula_by_id.has(key):
		return {}
	return combo_last_formula_by_id[key].duplicate(true)


func ensure_combo_levels() -> void:
	var migrated := {}
	for existing_id in combo_levels.keys():
		var normalized_id := _normalized_combo_id(StringName(str(existing_id)))
		if normalized_id == &"" or not ComboUpgradeCatalog.has_combo(normalized_id):
			continue
		migrated[normalized_id] = max(
			int(migrated.get(normalized_id, 1)),
			max(1, int(combo_levels[existing_id]))
		)

	for combo_id in ComboUpgradeCatalog.get_combo_ids():
		if not migrated.has(combo_id):
			migrated[combo_id] = 1

	combo_levels = migrated


func increase_combo_level(combo_id: StringName, amount: int = 1) -> bool:
	ensure_combo_levels()
	var normalized_id := _normalized_combo_id(combo_id)
	if normalized_id == &"" or not ComboUpgradeCatalog.has_combo(normalized_id):
		return false

	combo_levels[normalized_id] = max(1, int(combo_levels.get(normalized_id, 1))) + max(1, amount)
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
	lines.append("已通过战斗：%d / %d" % [min(battle_index + (1 if run_won else 0), max_battles), max_battles])
	lines.append("当前战斗序号：%d" % [battle_index + 1])
	lines.append("总结算手数：%d" % [total_hands_scored])
	lines.append("总获得战力：%d" % [total_score_scored])
	lines.append("最高单手战力：%d" % [best_hand_score])
	lines.append("金币：%d" % [coins])
	lines.append(_most_triggered_effect_summary_text())
	lines.append("已安装铸骰件：%d" % [installed_piece_count])
	lines.append(get_installed_piece_history_text())
	lines.append("")
	_append_recent_settlement_text(lines)
	return "\n".join(lines)


func get_installed_piece_history_text() -> String:
	if installed_piece_history.is_empty():
		return "安装历史：无"

	var lines := PackedStringArray()
	lines.append("安装历史：")
	for item in installed_piece_history:
		lines.append("第 %d 场后：%s 安装到 骰子 %d / 面 %d" % [
			int(item.get("battle", 0)),
			str(item.get("piece_name", "")),
			int(item.get("die", 0)),
			int(item.get("face", 0)),
		])
		lines.append("标签：%s" % [str(item.get("piece_tags_text", "无"))])
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
	recent_hand_summaries.append("第 %d 场 / 第 %d 手：最终战力 %d\n%s" % [
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
	match combo_id:
		&"FIVE_KIND", &"five_kind":
			return &"five_kind"
		&"LARGE_STRAIGHT", &"SMALL_STRAIGHT", &"large_straight", &"small_straight", &"straight":
			return &"straight"
		&"FOUR_KIND", &"four_kind":
			return &"four_kind"
		&"FULL_HOUSE", &"full_house":
			return &"full_house"
		&"THREE_KIND", &"three_kind":
			return &"three_kind"
		&"TWO_PAIR", &"two_pair":
			return &"two_pair"
		&"PAIR", &"pair":
			return &"pair"
		&"HIGH_CARD", &"high_card", &"scatter":
			return &"scatter"
		_:
			return combo_id


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
		&"ornament_chip", &"ornament_mult", &"ornament_wild", &"ornament_burst", &"ornament_stay", &"ornament_stone", &"ornament_gold", &"ornament_lucky", &"ornament_foil", &"ornament_holo", &"ornament_poly", &"mark_blue", &"mark_red", &"mark_purple", &"mark_gold", &"mark_white", &"extra_pip":
			return true
		_:
			return false


func _most_triggered_effect_summary_text() -> String:
	var category := _most_triggered_effect_category()
	if category == &"":
		return "最常触发效果：无"

	return "最常触发效果：%s（%d 次）" % [
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
			return "额外触发点数"
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
			return ItemInstance.create_dice_tool(
				item_id,
				str(tool_data.get("name", item_id)),
				int(tool_data.get("sell_value", 0))
			)

	return ItemInstance.create(item_id, ItemInstance.TYPE_GENERIC, str(item_id))


func _is_copyable_item_id(item_id: StringName) -> bool:
	if item_id == &"" or item_id == ForgeItemCatalog.FORGE_ECHO_COPY:
		return false
	if ComboUpgradeItem.from_item_id(item_id) != null:
		return true
	return ForgeItemCatalog.has_forge_item(item_id)


func _append_recent_settlement_text(lines: PackedStringArray) -> void:
	if recent_settlement_logs.is_empty():
		lines.append("最近结算摘要：无")
		return

	lines.append("最近结算摘要（%d / %d）：" % [recent_settlement_logs.size(), MAX_RECENT_SETTLEMENT_LOGS])
	for item in recent_settlement_logs:
		var result: ScoreResult = item.get("result") as ScoreResult
		if result == null:
			continue

		lines.append("第 %d 场 / 第 %d 手：最终战力 %d" % [
			int(item.get("battle", 0)),
			int(item.get("hand", 0)),
			int(item.get("score", 0)),
		])
		lines.append(result.get_summary_text_zh())
