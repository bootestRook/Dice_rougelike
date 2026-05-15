extends RefCounted
class_name RunState


const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocService = preload("res://scripts/i18n/LocService.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


const MAX_RECENT_SETTLEMENT_LOGS := 5


var dice: Array[DieState] = []
var relic_ids: Array[StringName] = []
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
var installed_piece_count: int = 0
var installed_piece_history: Array[Dictionary] = []
var recent_settlement_logs: Array[Dictionary] = []
var effect_trigger_counts: Dictionary = {}
var effect_trigger_order: Array[StringName] = []


func setup_new_run() -> void:
	battle_index = 0
	current_battle = null
	last_reward_choices.clear()
	pending_forge_piece = null
	run_won = false
	run_lost = false
	total_hands_scored = 0
	total_score_scored = 0
	best_hand_score = 0
	installed_piece_count = 0
	installed_piece_history.clear()
	recent_settlement_logs.clear()
	effect_trigger_counts.clear()
	effect_trigger_order.clear()
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

	# battle_index is 0-based: battle_index 0 is the first battle.
	var index: int = clampi(battle_index, 0, target_scores.size() - 1)
	return target_scores[index]


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


func record_installed_piece(piece: ForgePieceDef, die_index: int, face_index: int) -> void:
	if piece == null:
		return

	installed_piece_count += 1
	installed_piece_history.append({
		"battle": battle_index + 1,
		"piece_key": piece.get_name_key(),
		"piece_id": piece.id,
		"die": die_index + 1,
		"face": face_index + 1,
	})


func get_run_summary_text() -> String:
	var lines := PackedStringArray()
	lines.append(LocService.t(&"UI.RUN.SUMMARY_BATTLES_CLEARED", {
		"cleared": min(battle_index + (1 if run_won else 0), max_battles),
		"max": max_battles,
	}))
	lines.append(LocService.t(&"UI.RUN.SUMMARY_CURRENT_BATTLE", {"battle": battle_index + 1}))
	lines.append(LocService.t(&"UI.RUN.SUMMARY_TOTAL_HANDS", {"hands": total_hands_scored}))
	lines.append(LocService.t(&"UI.RUN.SUMMARY_TOTAL_SCORE", {"score": total_score_scored}))
	lines.append(LocService.t(&"UI.RUN.SUMMARY_BEST_HAND", {"score": best_hand_score}))
	lines.append(_most_triggered_effect_summary_text())
	lines.append(LocService.t(&"UI.RUN.SUMMARY_INSTALLED_COUNT", {"count": installed_piece_count}))
	if installed_piece_history.is_empty():
		lines.append(LocService.t(&"UI.RUN.SUMMARY_HISTORY_NONE"))
	else:
		lines.append(LocService.t(&"UI.RUN.SUMMARY_HISTORY_TITLE"))
		for item in installed_piece_history:
			lines.append(LocService.t(&"UI.RUN.SUMMARY_HISTORY_ITEM", {
				"battle": int(item.get("battle", 0)),
				"piece": LocService.t(StringName(item.get("piece_key", &""))),
				"die": int(item.get("die", 0)),
				"face": int(item.get("face", 0)),
			}))
	lines.append("")
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

	while recent_settlement_logs.size() > MAX_RECENT_SETTLEMENT_LOGS:
		recent_settlement_logs.remove_at(0)

	_record_effect_triggers(result)


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
		&"material_steel", &"mark_blue", &"mark_red", &"rune_pair", &"level", &"material_glass", &"rune_six", &"rune_straight", &"rune_odd", &"rune_even":
			return true
		_:
			return false


func _most_triggered_effect_summary_text() -> String:
	var category := _most_triggered_effect_category()
	if category == &"":
		return LocService.t(&"UI.RUN.SUMMARY_TOP_EFFECT_NONE")

	return LocService.t(&"UI.RUN.SUMMARY_TOP_EFFECT", {
		"effect": _effect_category_text(category),
		"count": int(effect_trigger_counts.get(category, 0)),
	})


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
		&"material_steel":
			return LocService.t(LocKeys.material_name_key(&"steel"))
		&"material_glass":
			return LocService.t(LocKeys.material_name_key(&"glass"))
		&"mark_blue":
			return LocService.t(LocKeys.imprint_name_key(&"blue"))
		&"mark_red":
			return LocService.t(LocKeys.imprint_name_key(&"red"))
		&"rune_pair":
			return LocService.t(LocKeys.rune_name_key(&"pair"))
		&"rune_six":
			return LocService.t(LocKeys.rune_name_key(&"six"))
		&"rune_straight":
			return LocService.t(LocKeys.rune_name_key(&"straight"))
		&"rune_odd":
			return LocService.t(LocKeys.rune_name_key(&"odd"))
		&"rune_even":
			return LocService.t(LocKeys.rune_name_key(&"even"))
		&"level":
			return LocService.t(&"EFFECT.LEVEL.NAME")
		_:
			return str(category)


func _append_recent_settlement_text(lines: PackedStringArray) -> void:
	if recent_settlement_logs.is_empty():
		lines.append(LocService.t(&"UI.RUN.SUMMARY_SETTLEMENT_NONE"))
		return

	lines.append(LocService.t(&"UI.RUN.SUMMARY_SETTLEMENT_TITLE", {
		"count": recent_settlement_logs.size(),
		"max": MAX_RECENT_SETTLEMENT_LOGS,
	}))
	for item in recent_settlement_logs:
		var result: ScoreResult = item.get("result") as ScoreResult
		if result == null:
			continue

		lines.append(LocService.t(&"UI.RUN.SUMMARY_SETTLEMENT_ITEM", {
			"battle": int(item.get("battle", 0)),
			"hand": int(item.get("hand", 0)),
			"score": int(item.get("score", 0)),
		}))
		for entry in result.logs:
			if entry != null:
				lines.append(LocService.t(&"UI.RUN.SUMMARY_SETTLEMENT_LOG_ITEM", {
					"text": entry.get_text(),
				}))
