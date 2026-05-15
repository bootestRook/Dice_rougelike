extends SceneTree
class_name DebugEffectScoringSmokeTest


const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


func _init() -> void:
	print("--- DebugEffectScoringSmokeTest: start ---")

	var all_passed := true

	var ordinary_6 := _score([_make_roll(0, 0, 6)])
	all_passed = _check("ordinary 6 scores 6", ordinary_6.chips == 6 and ordinary_6.mult == 1 and is_equal_approx(ordinary_6.xmult, 1.0) and ordinary_6.final_score == 6) and all_passed

	var rune_six := _score([_make_roll(0, 0, 6, &"", &"", &"six")])
	all_passed = _check("six rune adds 8 Mult", rune_six.mult == 9 and rune_six.final_score == 54) and all_passed
	all_passed = _check("six rune logs", _logs_contain(rune_six, ["rune_six"])) and all_passed

	var red_rune_six := _score([_make_roll(0, 0, 6, &"", &"red", &"six")])
	all_passed = _check("red + six rune retriggers", red_rune_six.mult >= 17 and red_rune_six.chips >= 12) and all_passed
	all_passed = _check("red mark extra trigger logs", _logs_contain(red_rune_six, ["mark_red"]) and _logs_contain(red_rune_six, ["extra_pip"])) and all_passed

	var glass := _score([_make_roll(0, 0, 1, &"glass")])
	all_passed = _check("glass gives X2", is_equal_approx(glass.xmult, 2.0) and glass.final_score == 2) and all_passed
	all_passed = _check("glass logs", _logs_contain(glass, ["material_glass"])) and all_passed

	var red_glass := _score([_make_roll(0, 0, 1, &"glass", &"red")])
	all_passed = _check("red + glass gives X4", is_equal_approx(red_glass.xmult, 4.0)) and all_passed
	all_passed = _check("red + glass logs twice", _count_logs_containing(red_glass, "material_glass") >= 2) and all_passed

	var selected_steel_test := _make_roll(0, 0, 1)
	var unselected_steel := _make_roll(1, 0, 5, &"steel", &"", &"", 1, false)
	var steel := _score([selected_steel_test], [selected_steel_test, unselected_steel])
	all_passed = _check("unselected steel adds 5 Mult", steel.mult == 6) and all_passed
	all_passed = _check("steel logs", _logs_contain(steel, ["material_steel"])) and all_passed

	var selected_blue_test := _make_roll(0, 0, 1)
	var unselected_blue := _make_roll(1, 0, 5, &"", &"blue", &"", 1, false)
	var blue := _score([selected_blue_test], [selected_blue_test, unselected_blue])
	all_passed = _check("unselected blue mark adds 3 Mult", blue.mult == 4) and all_passed
	all_passed = _check("blue mark logs", _logs_contain(blue, ["mark_blue"])) and all_passed

	var straight := _score([
		_make_roll(0, 0, 1),
		_make_roll(1, 0, 2),
		_make_roll(2, 0, 3, &"", &"", &"straight"),
		_make_roll(3, 0, 4),
	], [], ComboEvaluator.SMALL_STRAIGHT)
	all_passed = _check("straight rune adds 20 Chips", straight.chips == 70) and all_passed
	all_passed = _check("straight rune logs", _logs_contain(straight, ["rune_straight"])) and all_passed

	var pair := _score([
		_make_roll(0, 0, 4, &"", &"", &"pair"),
		_make_roll(1, 0, 4),
	], [], ComboEvaluator.PAIR)
	all_passed = _check("pair rune adds extra pip", pair.chips == 22) and all_passed
	all_passed = _check("pair rune logs", _logs_contain(pair, ["rune_pair"])) and all_passed

	var level_2 := _score([_make_roll(0, 0, 1, &"", &"", &"", 2)])
	all_passed = _check("Lv2 selected face adds 5 Chips", level_2.chips == 6) and all_passed
	all_passed = _check("Lv2 logs", _logs_contain(level_2, ["level"])) and all_passed

	if all_passed:
		print("PASS: DebugEffectScoringSmokeTest")
	else:
		print("FAIL: DebugEffectScoringSmokeTest")

	print("--- DebugEffectScoringSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _score(selected: Array, all_rolls: Array = [], combo_id: StringName = &"") -> ScoreResult:
	var context := ScoreContext.new()
	context.selected_faces = _to_roll_array(selected)
	if all_rolls.is_empty():
		context.all_rolled_faces = _to_roll_array(selected)
	else:
		context.all_rolled_faces = _to_roll_array(all_rolls)
	context.combo_id = combo_id
	context.combo_type = combo_id
	return ScoreEngine.new().score(context)


func _to_roll_array(values: Array) -> Array[RolledFace]:
	var result: Array[RolledFace] = []
	for value in values:
		if value is RolledFace:
			result.append(value)
	return result


func _make_roll(
	die_index: int,
	face_index: int,
	pip: int,
	material_id: StringName = &"",
	mark_id: StringName = &"",
	rune_id: StringName = &"",
	level: int = 1,
	selected: bool = true
) -> RolledFace:
	var face := FaceState.new()
	face.pip = pip
	face.material_id = material_id
	face.mark_id = mark_id
	face.rune_id = rune_id
	face.level = level

	var roll := RolledFace.new()
	roll.set_roll(die_index, face_index, face)
	roll.selected = selected
	return roll


func _logs_contain(result: ScoreResult, needles: Array) -> bool:
	for needle in needles:
		for entry in result.logs:
			if str(entry.key).find(str(needle)) >= 0 or str(entry.category).find(str(needle)) >= 0:
				return true
	return false


func _count_logs_containing(result: ScoreResult, needle: String) -> int:
	var count := 0
	for entry in result.logs:
		if str(entry.key).find(needle) >= 0 or str(entry.category).find(needle) >= 0:
			count += 1
	return count


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
