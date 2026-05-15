extends RefCounted
class_name ScoreEngine


const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const EffectResolver = preload("res://scripts/rules/scoring/EffectResolver.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const BattleLogEntry = preload("res://scripts/log/BattleLogEntry.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


var effect_resolver := EffectResolver.new()


func score(context: ScoreContext) -> ScoreResult:
	var result := ScoreResult.new()
	var total_pips := _sum_selected_pips(context)
	var combo_id := context.combo_id

	if combo_id == &"":
		combo_id = ComboEvaluator.new().evaluate(_selected_pips(context))
	context.combo_id = combo_id
	context.combo_type = combo_id
	result.combo_id = combo_id
	result.combo_name_key = LocKeys.combo_key(combo_id)
	_copy_display_combos(context, result)
	result.tags.clear()
	for tag in context.tags:
		result.tags.append(tag)

	var base_values := _base_values_for_combo(combo_id, total_pips)
	result.chips = int(base_values["chips"])
	result.mult = int(base_values["mult"])
	result.xmult = 1.0

	_add_log(result, &"LOG.COMBO", {"combo": LocKeys.combo_key(combo_id)}, &"combo")
	_add_log(result, &"LOG.PIP_SUM", {"sum": total_pips}, &"base")
	_add_log(result, &"LOG.BASE_CHIPS", {"chips": result.chips}, &"base")
	_add_log(result, &"LOG.BASE_MULT", {"mult": result.mult}, &"base")
	_add_log(result, &"LOG.BASE_XMULT", {"xmult": _format_xmult(result.xmult)}, &"base")

	effect_resolver.apply_effects(context, result)
	result.final_score = roundi(float(result.chips * result.mult) * result.xmult)
	_add_log(result, &"LOG.FINAL_SCORE", {
		"chips": result.chips,
		"mult": result.mult,
		"xmult": _format_xmult(result.xmult),
		"score": result.final_score,
	}, &"final")
	return result


func _selected_pips(context: ScoreContext) -> Array[int]:
	var pips: Array[int] = []

	for rolled_face in context.selected_faces:
		if rolled_face.face != null:
			pips.append(rolled_face.face.pip)

	return pips


func _sum_selected_pips(context: ScoreContext) -> int:
	var total := 0

	for pip in _selected_pips(context):
		total += pip

	return total


func _copy_display_combos(context: ScoreContext, result: ScoreResult) -> void:
	result.display_combo_ids.clear()
	if context.display_combo_ids.is_empty():
		result.display_combo_ids.append(context.combo_id)
		return

	for display_combo_id in context.display_combo_ids:
		result.display_combo_ids.append(display_combo_id)


func _base_values_for_combo(combo_id: StringName, pip_total: int) -> Dictionary:
	match combo_id:
		ComboEvaluator.PAIR:
			return {"chips": 10 + pip_total, "mult": 2}
		ComboEvaluator.TWO_PAIR:
			return {"chips": 20 + pip_total, "mult": 3}
		ComboEvaluator.THREE_KIND:
			return {"chips": 30 + pip_total, "mult": 4}
		ComboEvaluator.FULL_HOUSE:
			return {"chips": 40 + pip_total, "mult": 5}
		ComboEvaluator.SMALL_STRAIGHT:
			return {"chips": 40 + pip_total, "mult": 4}
		ComboEvaluator.LARGE_STRAIGHT:
			return {"chips": 80 + pip_total, "mult": 8}
		ComboEvaluator.FOUR_KIND:
			return {"chips": 60 + pip_total, "mult": 8}
		ComboEvaluator.FIVE_KIND:
			return {"chips": 100 + pip_total, "mult": 15}
		_:
			return {"chips": pip_total, "mult": 1}


func _add_log(result: ScoreResult, key: StringName, args: Dictionary = {}, category: StringName = &"general") -> void:
	var entry := BattleLogEntry.new(key, args, category)
	result.add_log(entry)


func _format_xmult(value: float) -> String:
	return "%.2f" % [value]
