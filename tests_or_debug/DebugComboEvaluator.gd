extends SceneTree
class_name DebugComboEvaluator


const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const DicePatternResolver = preload("res://scripts/rules/combo/DicePatternResolver.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const TagEvaluator = preload("res://scripts/rules/combo/TagEvaluator.gd")


func _init() -> void:
	print("--- DebugComboEvaluator: start ---")

	var resolver := DicePatternResolver.new()
	var all_passed := true
	var cases := [
		{
			"name": "straight 1-5",
			"pips": [1, 2, 3, 4, 5],
			"combo": ComboEvaluator.STRAIGHT,
		},
		{
			"name": "straight 2-6",
			"pips": [2, 3, 4, 5, 6],
			"combo": ComboEvaluator.STRAIGHT,
		},
		{
			"name": "straight 3-7",
			"pips": [3, 4, 5, 6, 7],
			"combo": ComboEvaluator.STRAIGHT,
		},
		{
			"name": "straight 4-8",
			"pips": [4, 5, 6, 7, 8],
			"combo": ComboEvaluator.STRAIGHT,
		},
		{
			"name": "four low pips stay scatter",
			"pips": [1, 2, 3, 4],
			"combo": ComboEvaluator.SCATTER,
			"facts": {"is_all_low": true, "is_low_total": true},
		},
		{
			"name": "four high pips stay scatter",
			"pips": [5, 6, 7, 8],
			"combo": ComboEvaluator.SCATTER,
			"facts": {"is_all_high": true, "is_high_total": true},
		},
		{
			"name": "five kind facts do not grant tags",
			"pips": [1, 1, 1, 1, 1],
			"combo": ComboEvaluator.FIVE_KIND,
			"facts": {
				"has_pair_shape": true,
				"has_three_kind_shape": true,
				"has_four_kind_shape": true,
			},
		},
		{
			"name": "two pair with even and six facts",
			"pips": [2, 2, 4, 4, 6],
			"combo": ComboEvaluator.TWO_PAIR,
			"facts": {"is_all_even": true, "contains_six": true},
		},
		{
			"name": "first roll scored fact",
			"pips": [2, 4, 6],
			"combo": ComboEvaluator.SCATTER,
			"rerolled": false,
			"facts": {"is_first_roll_scored": true, "has_rerolled": false},
		},
		{
			"name": "rerolled fact",
			"pips": [2, 4, 6],
			"combo": ComboEvaluator.SCATTER,
			"rerolled": true,
			"facts": {"has_rerolled": true, "is_first_roll_scored": false},
		},
		{
			"name": "unscored stay fact",
			"pips": [2, 4, 6],
			"combo": ComboEvaluator.SCATTER,
			"rolled_extra": [8],
			"facts": {"has_unscored_stay": true},
		},
	]

	for case_index in range(cases.size()):
		var test_case: Dictionary = cases[case_index]
		var scored_faces := _make_selected_faces(test_case["pips"])
		var rolled_faces := _make_rolled_faces_with_extra(scored_faces, test_case.get("rolled_extra", []))
		var pips := _to_int_array(test_case["pips"])
		var expected_combo := StringName(str(test_case["combo"]))
		var resolution := resolver.resolve(
			scored_faces,
			rolled_faces,
			bool(test_case.get("rerolled", false)),
			bool(test_case.get("last_hand", false))
		)
		var actual_combo := StringName(str(resolution["primary_combo_id"]))
		var combo_passed := actual_combo == expected_combo
		var display_passed := _same_ids(resolver.evaluate_display_combos(pips), [expected_combo])
		var contained_passed := resolver.evaluate_contained_patterns(pips).is_empty()
		var active_tags_passed := _array_value_empty(resolution["active_tags"])
		var legacy_tags_passed := (
			_array_value_empty(resolution["condition_tags"])
			and _array_value_empty(resolution["operation_tags"])
			and _array_value_empty(resolution["state_tags"])
		)
		var facts_passed := _facts_match(resolution["facts"], test_case.get("facts", {}))
		all_passed = (
			all_passed
			and combo_passed
			and display_passed
			and contained_passed
			and active_tags_passed
			and legacy_tags_passed
			and facts_passed
		)

		print("Case %02d: %s" % [case_index + 1, test_case["name"]])
		print("  input: %s" % [_describe_pips(test_case["pips"])])
		print("  expected combo: %s" % [str(expected_combo)])
		print("  actual combo:   %s" % [str(actual_combo)])
		print("  facts: %s" % [str(resolution["facts"])])
		print("  active tags: %s" % [str(resolution["active_tags"])])
		print("  passed: %s" % [str(combo_passed and display_passed and contained_passed and active_tags_passed and legacy_tags_passed and facts_passed)])

	all_passed = _check_tag_evaluator_does_not_auto_grant() and all_passed
	all_passed = _check_score_engine_primary_combo_only() and all_passed
	all_passed = _check_facts_do_not_add_score() and all_passed
	all_passed = _check_official_ornament_point_logic() and all_passed
	all_passed = _check_legacy_id_migration() and all_passed

	print("--- DebugComboEvaluator: end ---")
	quit(0 if all_passed else 1)


func _check_tag_evaluator_does_not_auto_grant() -> bool:
	var context := ScoreContext.new()
	context.selected_faces = _make_selected_faces([2, 2, 4, 4, 6])
	context.all_rolled_faces = context.selected_faces
	context.used_reroll = true
	context.is_last_hand = true

	var tag_evaluator := TagEvaluator.new()
	var tags := tag_evaluator.evaluate_tags(context)
	var facts := tag_evaluator.evaluate_facts(context)
	var passed := (
		tags.is_empty()
		and bool(facts["is_all_even"])
		and bool(facts["contains_six"])
		and bool(facts["has_rerolled"])
		and bool(facts["is_last_hand"])
	)
	print("TagEvaluator keeps facts separate from active tags: %s" % [str(passed)])
	if not passed:
		push_error("TagEvaluator should not auto-grant condition tags. tags=%s facts=%s" % [str(tags), str(facts)])
	return passed


func _check_score_engine_primary_combo_only() -> bool:
	var five_kind := _score_pips([6, 6, 6, 6, 6])
	var five_passed := (
		five_kind.primary_combo == ComboEvaluator.FIVE_KIND
		and five_kind.combo_id == ComboEvaluator.FIVE_KIND
		and _same_ids(five_kind.display_combo_ids, [ComboEvaluator.FIVE_KIND])
		and five_kind.contained_patterns.is_empty()
		and five_kind.tags.is_empty()
		and bool(five_kind.facts["has_pair_shape"])
		and bool(five_kind.facts["has_three_kind_shape"])
		and bool(five_kind.facts["has_four_kind_shape"])
		and five_kind.chips == 130
		and five_kind.mult == 15
		and five_kind.final_score == 1950
	)
	print("ScoreEngine uses one primary combo and empty active tags: %s" % [str(five_passed)])
	if not five_passed:
		push_error("Five kind should use only primary combo base values.")
	return five_passed


func _check_facts_do_not_add_score() -> bool:
	var result := _score_pips([2, 2, 4, 4, 6])
	var passed := (
		result.primary_combo == ComboEvaluator.TWO_PAIR
		and bool(result.facts["is_all_even"])
		and bool(result.facts["contains_six"])
		and result.tags.is_empty()
		and result.chips == 38
		and result.mult == 3
		and result.final_score == 114
	)
	print("Facts do not add Chips/Mult/XMult by themselves: %s" % [str(passed)])
	if not passed:
		push_error("Facts should be readable only, not score modifiers. result=%s" % [result.get_summary_text()])
	return passed


func _check_official_ornament_point_logic() -> bool:
	var wild_context := ScoreContext.new()
	wild_context.selected_faces = [
		_make_roll(0, 0, 1),
		_make_roll(1, 0, 2),
		_make_roll(2, 0, 3),
		_make_roll(3, 0, 4),
		_make_roll(4, 0, 6, &"orn_wild", 6),
	]
	wild_context.all_rolled_faces = wild_context.selected_faces
	wild_context.wild_effective_pips["4:0"] = 5
	var wild_result := ScoreEngine.new().score(wild_context)
	var wild_passed := (
		wild_result.primary_combo == ComboEvaluator.STRAIGHT
		and wild_result.chips == 96
		and wild_context.wild_effective_pips.is_empty()
	)

	var d4_context := ScoreContext.new()
	var d4_roll := _make_roll(0, 0, 4, &"orn_wild", 4)
	d4_context.selected_faces = [d4_roll]
	d4_context.all_rolled_faces = [d4_roll]
	var options := ScoreEngine.new().get_wild_pip_options(d4_roll, d4_context)
	var d4_passed := options == [1, 2, 3, 4]

	var stone_result := _score_rolls([
		_make_roll(0, 0, 6, &"orn_stone"),
		_make_roll(1, 0, 6),
		_make_roll(2, 0, 6),
		_make_roll(3, 0, 6),
		_make_roll(4, 0, 6),
	])
	var stone_passed := (
		stone_result.primary_combo == ComboEvaluator.FOUR_KIND
		and bool(stone_result.facts.get("has_four_kind_shape", false))
		and stone_result.chips == 134
	)

	var passed := wild_passed and d4_passed and stone_passed
	print("Official ornament point logic: %s" % [str(passed)])
	if not passed:
		push_error("Wild or stone point logic failed. wild=%s d4=%s stone=%s" % [wild_result.get_summary_text(), str(options), stone_result.get_summary_text()])
	return passed


func _check_legacy_id_migration() -> bool:
	var resolver := ComboEvaluator.new()
	var passed := (
		resolver.normalize_combo_id(&"HIGH_CARD") == ComboEvaluator.SCATTER
		and resolver.normalize_combo_id(&"SMALL_STRAIGHT") == ComboEvaluator.STRAIGHT
		and resolver.normalize_combo_id(&"LARGE_STRAIGHT") == ComboEvaluator.STRAIGHT
	)
	print("Legacy combo ids migrate to new ids: %s" % [str(passed)])
	if not passed:
		push_error("Legacy combo ids should normalize to scatter/straight.")
	return passed


func _score_pips(pips: Array) -> ScoreResult:
	var context := ScoreContext.new()
	context.selected_faces = _make_selected_faces(pips)
	context.all_rolled_faces = context.selected_faces
	return ScoreEngine.new().score(context)


func _score_rolls(rolls: Array[RolledFace]) -> ScoreResult:
	var context := ScoreContext.new()
	context.selected_faces = rolls
	context.all_rolled_faces = rolls
	return ScoreEngine.new().score(context)


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


func _make_roll(die_index: int, face_index: int, pip: int, ornament_id: StringName = &"orn_none", face_count: int = 6) -> RolledFace:
	var die := DieState.create_normal_d6(StringName("test_d%d" % [die_index]))
	die.face_count = face_count
	while die.faces.size() > face_count:
		die.faces.remove_at(die.faces.size() - 1)
		die.face_weights.remove_at(die.face_weights.size() - 1)
	var face := FaceState.new()
	face.pip = pip
	face.ornament_id = ornament_id

	var rolled_face := RolledFace.new()
	rolled_face.set_roll(die_index, face_index, face, die)
	rolled_face.selected = true
	return rolled_face


func _make_rolled_faces_with_extra(scored_faces: Array[RolledFace], extra_pips: Array) -> Array[RolledFace]:
	var rolled_faces: Array[RolledFace] = []
	for scored_face in scored_faces:
		rolled_faces.append(scored_face)

	for extra_index in range(extra_pips.size()):
		var face := FaceState.new()
		face.pip = int(extra_pips[extra_index])

		var rolled_face := RolledFace.new()
		rolled_face.die_index = scored_faces.size() + extra_index
		rolled_face.face_index = scored_faces.size() + extra_index
		rolled_face.face = face
		rolled_face.selected = false
		rolled_faces.append(rolled_face)

	return rolled_faces


func _to_int_array(values: Array) -> Array[int]:
	var result: Array[int] = []

	for value in values:
		result.append(int(value))

	return result


func _same_ids(actual: Array[StringName], expected: Array[StringName]) -> bool:
	if actual.size() != expected.size():
		return false

	for index in range(expected.size()):
		if actual[index] != expected[index]:
			return false

	return true


func _facts_match(actual: Dictionary, expected: Dictionary) -> bool:
	for key in expected.keys():
		if bool(actual.get(key, false)) != bool(expected[key]):
			push_error("Fact mismatch: %s expected=%s actual=%s" % [str(key), str(expected[key]), str(actual.get(key, null))])
			return false
	return true


func _array_value_empty(value) -> bool:
	return value is Array and value.is_empty()


func _describe_pips(pips: Array) -> String:
	var texts := PackedStringArray()

	for pip in pips:
		texts.append(str(pip))

	return "[" + ", ".join(texts) + "]"
