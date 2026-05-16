extends SceneTree
class_name DebugNoLegacyFaceSlotsSmokeTest


const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


const REMOVED_REWARD_IDS := [
	&"rune_six",
	&"rune_straight",
	&"rune_pair",
	&"rune_odd",
	&"rune_even",
	&"upgrade_1",
	&"material_glass",
	&"material_steel",
]


func _init() -> void:
	print("--- DebugNoLegacyFaceSlotsSmokeTest: start ---")

	var all_passed := true
	var generator := RewardGenerator.new()
	generator.rng.seed = 999
	for index in range(30):
		var choices := generator.generate_forge_choices(3, index)
		all_passed = _check("reward batch %d has no removed ids" % [index], not _choices_have_removed_ids(choices)) and all_passed

	var rune_result := _score([_roll_with_legacy(6, &"six", 1)])
	all_passed = _check("rune_id six does not add mult", rune_result.mult == 1 and rune_result.final_score == 6) and all_passed

	var level_result := _score([_roll_with_legacy(1, &"none", 5)])
	all_passed = _check("level 5 does not add chips", level_result.chips == 1 and level_result.final_score == 1) and all_passed
	all_passed = _check("logs do not mention removed visible slots", not _logs_contain_removed_visible_terms(rune_result) and not _logs_contain_removed_visible_terms(level_result)) and all_passed

	print("PASS: DebugNoLegacyFaceSlotsSmokeTest" if all_passed else "FAIL: DebugNoLegacyFaceSlotsSmokeTest")
	print("--- DebugNoLegacyFaceSlotsSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _choices_have_removed_ids(choices: Array) -> bool:
	for choice in choices:
		if choice != null and REMOVED_REWARD_IDS.has(choice.id):
			return true
	return false


func _score(selected: Array) -> ScoreResult:
	var context := ScoreContext.new()
	context.selected_faces = _to_roll_array(selected)
	context.all_rolled_faces = context.selected_faces
	return ScoreEngine.new().score(context)


func _to_roll_array(values: Array) -> Array[RolledFace]:
	var result: Array[RolledFace] = []
	for value in values:
		if value is RolledFace:
			result.append(value)
	return result


func _roll_with_legacy(pip: int, rune_id: StringName, level: int) -> RolledFace:
	var face := FaceState.new()
	face.pip = pip
	face.rune_id = rune_id
	face.level = level
	var roll := RolledFace.new()
	roll.set_roll(0, 0, face)
	roll.selected = true
	return roll


func _logs_contain_removed_visible_terms(result: ScoreResult) -> bool:
	for entry in result.logs:
		var text := entry.get_text()
		for term in ["符文", "等级"]:
			if text.contains(term):
				return true
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
