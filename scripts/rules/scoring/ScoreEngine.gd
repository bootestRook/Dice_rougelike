extends RefCounted
class_name ScoreEngine


const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreLogEntry = preload("res://scripts/core/scoring/ScoreLogEntry.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")
const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")


func score(context: ScoreContext) -> ScoreResult:
	var result := ScoreResult.new()
	var total_pips := _sum_selected_pips(context)
	var combo_id := context.combo_id

	if combo_id == &"":
		combo_id = ComboEvaluator.new().evaluate(_selected_pips(context))

	var base_values := _base_values_for_combo(combo_id, total_pips)
	result.chips = int(base_values["chips"])
	result.mult = int(base_values["mult"])
	result.xmult = 1.0
	result.final_score = roundi(float(result.chips * result.mult) * result.xmult)

	_add_log(result, "combo", "Combo: %s" % [str(combo_id)])
	_add_log(result, "pips", "Pip total: %d" % [total_pips])
	_add_log(result, "chips", "Chips: %d" % [result.chips], result.chips, 0, 1.0)
	_add_log(result, "mult", "Mult: %d" % [result.mult], 0, result.mult, 1.0)
	_add_log(result, "xmult", "XMult: %.2f" % [result.xmult], 0, 0, result.xmult)
	_add_log(result, "final", "Final score: %d" % [result.final_score])
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


func _add_log(result: ScoreResult, source: String, text: String, chips_delta: int = 0, mult_delta: int = 0, xmult_factor: float = 1.0) -> void:
	var entry := ScoreLogEntry.new()
	entry.setup(source, text, chips_delta, mult_delta, xmult_factor)
	result.add_log(entry)
