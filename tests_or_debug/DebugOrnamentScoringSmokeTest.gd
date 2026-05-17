extends SceneTree
class_name DebugOrnamentScoringSmokeTest


const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


func _init() -> void:
	print("--- DebugOrnamentScoringSmokeTest: start ---")

	var all_passed := true

	all_passed = _check("chip ornament adds 30 chips", _score([_roll(0, 0, 1, &"orn_chip")]).chips == 36) and all_passed
	all_passed = _check("foil ornament adds 50 chips", _score([_roll(0, 0, 1, &"orn_foil")]).chips == 56) and all_passed
	all_passed = _check("mult ornament adds 4 mult", _score([_roll(0, 0, 1, &"orn_mult")]).mult == 5) and all_passed
	all_passed = _check("burst ornament x2", is_equal_approx(_score([_roll(0, 0, 1, &"orn_burst")]).xmult, 2.0)) and all_passed

	var selected := _roll(0, 0, 1)
	var stay_unselected := _roll(1, 0, 5, &"orn_stay", &"mark_none", &"none", 1, false)
	all_passed = _check("stay unselected adds x1.5", is_equal_approx(_score([selected], [selected, stay_unselected]).xmult, 1.5)) and all_passed

	var red_chip := _score([_roll(0, 0, 1, &"orn_chip", &"red")])
	all_passed = _check("red repeats pip and chip", red_chip.chips == 67) and all_passed
	var red_mult := _score([_roll(0, 0, 1, &"orn_mult", &"red")])
	all_passed = _check("red repeats mult", red_mult.chips == 7 and red_mult.mult == 9) and all_passed
	var red_burst := _score([_roll(0, 0, 1, &"orn_burst", &"red")])
	all_passed = _check("red repeats burst", red_burst.chips == 7 and is_equal_approx(red_burst.xmult, 4.0)) and all_passed

	var selected_blue := _roll(0, 0, 1)
	var blue_unselected := _roll(1, 0, 5, &"orn_none", &"blue", &"none", 1, false)
	all_passed = _check("blue unselected provides mult", _score([selected_blue], [selected_blue, blue_unselected]).mult == 3) and all_passed

	var legacy_glass := _score([_roll(0, 0, 1, &"orn_none", &"mark_none", &"glass")])
	all_passed = _check("legacy glass scores as burst", is_equal_approx(legacy_glass.xmult, 2.0)) and all_passed
	var selected_steel := _roll(0, 0, 1)
	var legacy_steel := _roll(1, 0, 5, &"orn_none", &"mark_none", &"steel", 1, false)
	all_passed = _check("legacy steel scores as stay", is_equal_approx(_score([selected_steel], [selected_steel, legacy_steel]).xmult, 1.5)) and all_passed
	all_passed = _check("poly occupies ornament slot and adds x1.5", is_equal_approx(_score([_roll(0, 0, 1, &"orn_poly")]).xmult, 1.5)) and all_passed
	all_passed = _check("logs are Chinese and hide legacy ids", not _logs_have_forbidden_text(red_burst) and not _logs_have_forbidden_text(legacy_glass)) and all_passed

	print("PASS: DebugOrnamentScoringSmokeTest" if all_passed else "FAIL: DebugOrnamentScoringSmokeTest")
	print("--- DebugOrnamentScoringSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _score(selected: Array, all_rolls: Array = []) -> ScoreResult:
	var context := ScoreContext.new()
	context.selected_faces = _to_roll_array(selected)
	context.all_rolled_faces = _to_roll_array(selected if all_rolls.is_empty() else all_rolls)
	context.rng = FixedRng.new([0.99, 0.99, 0.99, 0.99])
	return ScoreEngine.new().score(context)


func _to_roll_array(values: Array) -> Array[RolledFace]:
	var result: Array[RolledFace] = []
	for value in values:
		if value is RolledFace:
			result.append(value)
	return result


func _roll(
	die_index: int,
	face_index: int,
	pip: int,
	ornament_id: StringName = &"orn_none",
	mark_id: StringName = &"mark_none",
	material_id: StringName = &"none",
	level: int = 1,
	selected: bool = true
) -> RolledFace:
	var face := FaceState.new()
	face.pip = pip
	face.ornament_id = ornament_id
	face.mark_id = mark_id
	face.material_id = material_id
	face.level = level
	var roll := RolledFace.new()
	roll.set_roll(die_index, face_index, face)
	roll.selected = selected
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


func _logs_have_forbidden_text(result: ScoreResult) -> bool:
	for entry in result.logs:
		var text := entry.get_text()
		for forbidden in ["material", "rune", "level", "glass", "steel"]:
			if text.contains(forbidden):
				return true
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
