extends SceneTree
class_name DebugComboEvaluator


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const TagEvaluator = preload("res://scripts/rules/combo/TagEvaluator.gd")


func _init() -> void:
	print("--- DebugComboEvaluator: start ---")

	var combo_evaluator := ComboEvaluator.new()
	var tag_evaluator := TagEvaluator.new()
	var all_passed := true
	var cases := [
		{
			"name": "five kind beats everything",
			"pips": [6, 6, 6, 6, 6],
			"combo": ComboEvaluator.FIVE_KIND,
			"tags": [TagEvaluator.ALL_EVEN, TagEvaluator.HIGH_TOTAL, TagEvaluator.CONTAINS_SIX, TagEvaluator.MANY_SIXES],
		},
		{
			"name": "large straight 1-5",
			"pips": [1, 2, 3, 4, 5],
			"combo": ComboEvaluator.LARGE_STRAIGHT,
			"tags": [],
		},
		{
			"name": "large straight 2-6",
			"pips": [2, 3, 4, 5, 6],
			"combo": ComboEvaluator.LARGE_STRAIGHT,
			"tags": [TagEvaluator.CONTAINS_SIX],
		},
		{
			"name": "four kind",
			"pips": [4, 4, 4, 4, 2],
			"combo": ComboEvaluator.FOUR_KIND,
			"tags": [TagEvaluator.ALL_EVEN],
		},
		{
			"name": "full house",
			"pips": [3, 3, 3, 2, 2],
			"combo": ComboEvaluator.FULL_HOUSE,
			"tags": [],
		},
		{
			"name": "small straight with duplicate",
			"pips": [1, 2, 3, 4, 4],
			"combo": ComboEvaluator.SMALL_STRAIGHT,
			"display_combos": [ComboEvaluator.SMALL_STRAIGHT, ComboEvaluator.PAIR],
			"tags": [],
		},
		{
			"name": "small straight plus pair",
			"pips": [3, 4, 4, 5, 6],
			"combo": ComboEvaluator.SMALL_STRAIGHT,
			"display_combos": [ComboEvaluator.SMALL_STRAIGHT, ComboEvaluator.PAIR],
			"tags": [TagEvaluator.CONTAINS_SIX],
		},
		{
			"name": "three kind",
			"pips": [5, 5, 5, 2, 6],
			"combo": ComboEvaluator.THREE_KIND,
			"tags": [TagEvaluator.CONTAINS_SIX],
		},
		{
			"name": "two pair",
			"pips": [2, 2, 5, 5, 6],
			"combo": ComboEvaluator.TWO_PAIR,
			"tags": [TagEvaluator.CONTAINS_SIX],
		},
		{
			"name": "pair",
			"pips": [1, 1, 3, 4, 6],
			"combo": ComboEvaluator.PAIR,
			"tags": [TagEvaluator.CONTAINS_SIX],
		},
		{
			"name": "high card all odd low total",
			"pips": [1, 3, 5],
			"combo": ComboEvaluator.HIGH_CARD,
			"tags": [TagEvaluator.ALL_ODD, TagEvaluator.LOW_TOTAL, TagEvaluator.FEW_SCORED],
		},
		{
			"name": "few scored rerolled last hand",
			"pips": [2, 4, 6],
			"combo": ComboEvaluator.HIGH_CARD,
			"rerolls": 1,
			"hand_index": 3,
			"hands_per_battle": 4,
			"tags": [TagEvaluator.ALL_EVEN, TagEvaluator.CONTAINS_SIX, TagEvaluator.FEW_SCORED, TagEvaluator.REROLLED, TagEvaluator.LAST_HAND],
		},
	]

	for case_index in range(cases.size()):
		var test_case: Dictionary = cases[case_index]
		var selected_faces := _make_selected_faces(test_case["pips"])
		var context := _make_context(selected_faces, test_case)
		var pips := _to_int_array(test_case["pips"])
		var actual_combo := combo_evaluator.evaluate(pips)
		var actual_display_combos := combo_evaluator.evaluate_display_combos(pips)
		var actual_tags := tag_evaluator.evaluate_tags(context)
		var expected_combo := StringName(str(test_case["combo"]))
		var expected_display_combos: Array[StringName] = [expected_combo]
		if test_case.has("display_combos"):
			expected_display_combos = _to_string_name_array(test_case["display_combos"])
		var expected_tags := _to_string_name_array(test_case["tags"])
		var combo_passed := actual_combo == expected_combo
		var display_passed := _same_ids(actual_display_combos, expected_display_combos)
		var tags_passed := _same_tags(actual_tags, expected_tags)
		all_passed = all_passed and combo_passed and display_passed and tags_passed

		print("Case %02d: %s" % [case_index + 1, test_case["name"]])
		print("  input: %s" % [_describe_pips(test_case["pips"])])
		print("  expected combo: %s" % [str(expected_combo)])
		print("  actual combo:   %s" % [str(actual_combo)])
		print("  expected display combos: %s" % [_describe_tags(expected_display_combos)])
		print("  actual display combos:   %s" % [_describe_tags(actual_display_combos)])
		print("  expected tags:  %s" % [_describe_tags(expected_tags)])
		print("  actual tags:    %s" % [_describe_tags(actual_tags)])
		print("  passed: %s" % [str(combo_passed and display_passed and tags_passed)])

	print("--- DebugComboEvaluator: end ---")
	var exit_code := 0
	if not all_passed:
		exit_code = 1
	quit(exit_code)


func _make_selected_faces(pips: Array) -> Array[RolledFace]:
	var selected_faces: Array[RolledFace] = []

	for index in range(pips.size()):
		var face := FaceState.new()
		face.pip = int(pips[index])

		var rolled_face := RolledFace.new()
		rolled_face.die_index = index
		rolled_face.face_index = index
		rolled_face.face = face
		rolled_face.selected = true
		selected_faces.append(rolled_face)

	return selected_faces


func _make_context(selected_faces: Array[RolledFace], test_case: Dictionary) -> ScoreContext:
	var context := ScoreContext.new()
	context.selected_faces = selected_faces
	context.hand_state = HandState.new()
	context.hand_state.rerolls_used = int(test_case.get("rerolls", 0))
	context.hand_state.hand_index = int(test_case.get("hand_index", 0))
	context.battle_state = BattleState.new()
	context.battle_state.config = BattleConfig.new()
	context.battle_state.config.hands_per_battle = int(test_case.get("hands_per_battle", 4))
	return context


func _to_string_name_array(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []

	for value in values:
		result.append(StringName(str(value)))

	return result


func _to_int_array(values: Array) -> Array[int]:
	var result: Array[int] = []

	for value in values:
		result.append(int(value))

	return result


func _same_tags(actual: Array[StringName], expected: Array[StringName]) -> bool:
	if actual.size() != expected.size():
		return false

	for expected_tag in expected:
		if not actual.has(expected_tag):
			return false

	return true


func _same_ids(actual: Array[StringName], expected: Array[StringName]) -> bool:
	if actual.size() != expected.size():
		return false

	for index in range(expected.size()):
		if actual[index] != expected[index]:
			return false

	return true


func _describe_pips(pips: Array) -> String:
	var texts := PackedStringArray()

	for pip in pips:
		texts.append(str(pip))

	return "[" + ", ".join(texts) + "]"


func _describe_tags(tags: Array[StringName]) -> String:
	var texts := PackedStringArray()

	for tag in tags:
		texts.append(str(tag))

	return "[" + ", ".join(texts) + "]"
