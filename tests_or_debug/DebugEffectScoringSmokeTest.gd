extends SceneTree
class_name DebugEffectScoringSmokeTest


const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


func _init() -> void:
	print("--- DebugEffectScoringSmokeTest: start ---")

	var all_passed := true

	var ordinary_6 := _score([_make_roll(0, 0, 6)])
	all_passed = _check("ordinary 6 scores 6", ordinary_6.chips == 6 and ordinary_6.mult == 1 and is_equal_approx(ordinary_6.xmult, 1.0) and ordinary_6.final_score == 6) and all_passed

	var chip := _score([_make_roll(0, 0, 1, &"orn_chip")])
	all_passed = _check("chip ornament adds 30 chips", chip.chips == 31 and chip.final_score == 31) and all_passed

	var foil := _score([_make_roll(0, 0, 1, &"orn_foil")])
	all_passed = _check("foil ornament adds 50 chips", foil.chips == 51 and foil.final_score == 51 and _logs_contain(foil, ["ornament_foil"])) and all_passed

	var mult := _score([_make_roll(0, 0, 1, &"orn_mult")])
	all_passed = _check("mult ornament adds 4 mult", mult.mult == 5 and mult.final_score == 5) and all_passed

	var burst := _score([_make_roll(0, 0, 1, &"orn_burst")])
	all_passed = _check("burst ornament gives x2", is_equal_approx(burst.xmult, 2.0) and burst.final_score == 2) and all_passed
	var burst_break_roll := _make_roll(0, 0, 4, &"orn_burst", &"red")
	var burst_break_context := ScoreContext.new()
	burst_break_context.selected_faces = [burst_break_roll]
	burst_break_context.all_rolled_faces = burst_break_context.selected_faces
	burst_break_context.rng = FixedRng.new([0.0])
	var burst_break := ScoreEngine.new().score(burst_break_context)
	all_passed = _check(
		"burst break clears only ornament",
		burst_break_roll.face.ornament_id == &"orn_none"
		and burst_break_roll.face.pip == 4
		and burst_break_roll.face.mark_id == &"red"
		and _logs_contain(burst_break, ["ornament_burst"])
		and _floating_texts_contain(burst_break, "爆裂破碎")
	) and all_passed

	var selected_stay_test := _make_roll(0, 0, 1)
	var unselected_stay := _make_roll(1, 0, 5, &"orn_stay", &"mark_none", &"none", 1, false)
	var stay := _score([selected_stay_test], [selected_stay_test, unselected_stay])
	all_passed = _check("stay ornament unselected adds x1.5", is_equal_approx(stay.xmult, 1.5) and stay.final_score == 2) and all_passed

	var red_chip := _score([_make_roll(0, 0, 1, &"orn_chip", &"red")])
	all_passed = _check("red repeats pip and chip", red_chip.chips == 62 and red_chip.final_score == 62) and all_passed
	all_passed = _check("red logs extra trigger", _logs_contain(red_chip, ["mark_red", "extra_pip", "ornament_chip"])) and all_passed

	var red_mult := _score([_make_roll(0, 0, 1, &"orn_mult", &"red")])
	all_passed = _check("red repeats mult ornament", red_mult.chips == 2 and red_mult.mult == 9 and red_mult.final_score == 18) and all_passed

	var red_burst := _score([_make_roll(0, 0, 1, &"orn_burst", &"red")])
	all_passed = _check("red repeats burst ornament", red_burst.chips == 2 and is_equal_approx(red_burst.xmult, 4.0) and red_burst.final_score == 8) and all_passed

	var selected_blue_test := _make_roll(0, 0, 1)
	var unselected_blue := _make_roll(1, 0, 5, &"orn_none", &"blue", &"none", 1, false)
	var blue := _score([selected_blue_test], [selected_blue_test, unselected_blue])
	all_passed = _check("blue mark unselected adds 2 mult without stay", blue.mult == 3 and blue.final_score == 3) and all_passed

	var selected_blue_stay_test := _make_roll(0, 0, 1)
	var unselected_blue_stay := _make_roll(1, 0, 5, &"orn_stay", &"blue", &"none", 1, false)
	var blue_stay := _score([selected_blue_stay_test], [selected_blue_stay_test, unselected_blue_stay])
	all_passed = _check("blue mark follows stay flow", blue_stay.mult == 4 and is_equal_approx(blue_stay.xmult, 1.5) and blue_stay.final_score == 6) and all_passed

	var purple := _score([_make_roll(0, 0, 1, &"orn_none", &"purple", &"none", 1, true, &"none", true)])
	all_passed = _check("purple mark rewards rerolled selected face", purple.mult == 5 and purple.final_score == 5) and all_passed

	var legacy_glass := _score([_make_roll(0, 0, 1, &"orn_none", &"mark_none", &"glass")])
	all_passed = _check("legacy glass material maps to burst", is_equal_approx(legacy_glass.xmult, 2.0) and legacy_glass.final_score == 2) and all_passed

	var selected_legacy_steel_test := _make_roll(0, 0, 1)
	var legacy_steel_unselected := _make_roll(1, 0, 5, &"orn_none", &"mark_none", &"steel", 1, false)
	var legacy_steel := _score([selected_legacy_steel_test], [selected_legacy_steel_test, legacy_steel_unselected])
	all_passed = _check("legacy steel material maps to stay", is_equal_approx(legacy_steel.xmult, 1.5) and legacy_steel.final_score == 2) and all_passed

	var legacy_disabled := _score([_make_roll(0, 0, 6, &"orn_none", &"mark_none", &"none", 5, true, &"six")])
	all_passed = _check("rune and level do not affect scoring", legacy_disabled.chips == 6 and legacy_disabled.mult == 1 and legacy_disabled.final_score == 6) and all_passed
	var source_die := DieState.create_normal_d6(&"source_d6")
	source_die.faces[0].ornament_id = &"orn_foil"
	var stale_roll := _make_roll(0, 0, 1, &"orn_none")
	var stale_context := ScoreContext.new()
	stale_context.selected_faces = [stale_roll]
	stale_context.all_rolled_faces = stale_context.selected_faces
	var source_dice: Array[DieState] = [source_die]
	stale_context.source_dice = source_dice
	stale_context.rng = FixedRng.new([0.99, 0.99])
	var stale_result := ScoreEngine.new().score(stale_context)
	all_passed = _check("source face ornament fallback scores foil", stale_result.chips == 51 and stale_result.final_score == 51 and _logs_contain(stale_result, ["ornament_foil"])) and all_passed
	var stone := _score([_make_roll(0, 0, 6, &"orn_stone"), _make_roll(1, 0, 6), _make_roll(2, 0, 6), _make_roll(3, 0, 6), _make_roll(4, 0, 6)])
	all_passed = _check("stone exits point logic and adds chips", stone.primary_combo == ComboEvaluator.FOUR_KIND and stone.chips == 134) and all_passed
	var gold_run := RunState.new()
	gold_run.setup_new_run()
	var context := ScoreContext.new()
	var selected_gold_test := _make_roll(0, 0, 1)
	var unselected_gold := _make_roll(1, 0, 5, &"orn_gold", &"mark_none", &"none", 1, false)
	context.selected_faces = [selected_gold_test]
	context.all_rolled_faces = [selected_gold_test, unselected_gold]
	context.run_state = gold_run
	context.rng = FixedRng.new([0.99, 0.99])
	var gold_result := ScoreEngine.new().score(context)
	all_passed = _check("gold ornament adds coins", gold_result.coins_delta == 3 and gold_run.coins == 3) and all_passed
	var lucky_context := ScoreContext.new()
	lucky_context.selected_faces = [_make_roll(0, 0, 1, &"orn_lucky")]
	lucky_context.all_rolled_faces = lucky_context.selected_faces
	lucky_context.run_state = gold_run
	lucky_context.rng = FixedRng.new([0.0, 0.0])
	var lucky := ScoreEngine.new().score(lucky_context)
	all_passed = _check("lucky double trigger", lucky.mult == 21 and lucky.coins_delta == 20 and gold_run.coins == 23) and all_passed
	all_passed = _check("log text has no legacy slots", not _logs_text_contains_legacy(red_burst) and not _logs_text_contains_legacy(legacy_glass) and not _logs_text_contains_legacy(legacy_steel)) and all_passed

	print("PASS: DebugEffectScoringSmokeTest" if all_passed else "FAIL: DebugEffectScoringSmokeTest")
	print("--- DebugEffectScoringSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _score(selected: Array, all_rolls: Array = []) -> ScoreResult:
	var context := ScoreContext.new()
	context.selected_faces = _to_roll_array(selected)
	if all_rolls.is_empty():
		context.all_rolled_faces = _to_roll_array(selected)
	else:
		context.all_rolled_faces = _to_roll_array(all_rolls)
	context.rng = FixedRng.new([0.99, 0.99, 0.99, 0.99])
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
	ornament_id: StringName = &"orn_none",
	mark_id: StringName = &"mark_none",
	material_id: StringName = &"none",
	level: int = 1,
	selected: bool = true,
	rune_id: StringName = &"none",
	was_rerolled: bool = false
) -> RolledFace:
	var face := FaceState.new()
	face.pip = pip
	face.ornament_id = ornament_id
	face.mark_id = mark_id
	face.material_id = material_id
	face.rune_id = rune_id
	face.level = level

	var roll := RolledFace.new()
	roll.set_roll(die_index, face_index, face)
	roll.selected = selected
	roll.was_rerolled = was_rerolled
	return roll


class FixedRng:
	extends RefCounted

	var values: Array = []

	func _init(new_values: Array) -> void:
		values = new_values.duplicate()

	func randf() -> float:
		if values.is_empty():
			return 0.99
		return values.pop_front()


func _logs_contain(result: ScoreResult, needles: Array) -> bool:
	for needle in needles:
		var found := false
		for entry in result.logs:
			if str(entry.key).find(str(needle)) >= 0 or str(entry.category).find(str(needle)) >= 0:
				found = true
				break
		if not found:
			return false
	return true


func _floating_texts_contain(result: ScoreResult, needle: String) -> bool:
	for event in result.floating_texts:
		if str(event.get("text", "")).contains(needle):
			return true
	return false


func _logs_text_contains_legacy(result: ScoreResult) -> bool:
	for entry in result.logs:
		var text := entry.get_text()
		for legacy in ["material", "rune", "level", "glass", "steel", "符文", "等级"]:
			if text.contains(legacy):
				return true
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
