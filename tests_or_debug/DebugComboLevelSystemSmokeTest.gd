extends SceneTree
class_name DebugComboLevelSystemSmokeTest


const ComboLevelSystem = preload("res://scripts/rules/combo/ComboLevelSystem.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const ComboUpgradeItem = preload("res://scripts/rules/combo/ComboUpgradeItem.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")


func _init() -> void:
	print("--- DebugComboLevelSystemSmokeTest: start ---")

	var all_passed := true
	all_passed = _check_scatter_naming() and all_passed
	all_passed = _check_straight_merge() and all_passed
	all_passed = _check_combo_value_table() and all_passed
	all_passed = _check_level_formula() and all_passed
	all_passed = _check_no_condition_tag_upgrades_in_module() and all_passed
	all_passed = _check_blue_mark_combo_upgrade_item() and all_passed
	all_passed = _check_score_engine_uses_run_combo_levels_once() and all_passed

	print("PASS: DebugComboLevelSystemSmokeTest" if all_passed else "FAIL: DebugComboLevelSystemSmokeTest")
	print("--- DebugComboLevelSystemSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_scatter_naming() -> bool:
	var result := ComboLevelSystem.get_combo_level_result(&"scatter", {})
	var display_name := DisplayNames.combo_name(result.combo_id)
	var passed := (
		result.combo_id == &"scatter"
		and result.level == 1
		and result.chips_bonus == 5
		and result.mult == 1
		and display_name == "散点"
		and display_name != "高点"
	)
	return _check("scatter Lv1 is +5/x1 and displays 散点", passed)


func _check_straight_merge() -> bool:
	var result := ComboLevelSystem.get_combo_level_result(&"straight", {})
	var passed := (
		result.combo_id == &"straight"
		and result.level == 1
		and result.chips_bonus == 55
		and result.mult == 5
		and DisplayNames.combo_name(result.combo_id) == "顺子"
	)
	return _check("straight Lv1 is +55/x5 and displays 顺子", passed)


func _check_combo_value_table() -> bool:
	var expected := {
		&"scatter": [5, 1, 5, 1],
		&"pair": [10, 2, 6, 1],
		&"two_pair": [18, 2, 10, 1],
		&"three_kind": [25, 3, 12, 1],
		&"full_house": [40, 4, 16, 2],
		&"four_kind": [65, 6, 26, 2],
		&"straight": [55, 5, 22, 2],
		&"five_kind": [120, 10, 40, 3],
	}
	var passed := true
	for combo_id in expected.keys():
		var def := ComboUpgradeCatalog.get_def(combo_id)
		var values: Array = expected[combo_id]
		var combo_passed: bool = (
			def.lv1_chips_bonus == values[0]
			and def.lv1_mult == values[1]
			and def.chips_per_level == values[2]
			and def.mult_per_level == values[3]
		)
		passed = _check("%s combo value table matches rebalance" % [str(combo_id)], combo_passed) and passed
	return passed


func _check_level_formula() -> bool:
	var result := ComboLevelSystem.get_combo_level_result(&"four_kind", {&"four_kind": 3})
	var passed := (
		result.combo_id == &"four_kind"
		and result.level == 3
		and result.chips_bonus == 117
		and result.mult == 10
	)
	return _check("four_kind Lv3 formula is +117/x10", passed)


func _check_no_condition_tag_upgrades_in_module() -> bool:
	var forbidden := [
		"all_odd",
		"all_even",
		"low_total",
		"high_total",
		"contains_six",
		"few_scored",
		"rerolled",
		"stay",
		"high_card",
		"combo_high",
		"small_straight",
		"large_straight",
	]
	var text := PackedStringArray()
	for path in [
		"res://scripts/rules/combo/ComboLevelSystem.gd",
		"res://scripts/rules/combo/ComboUpgradeCatalog.gd",
	]:
		text.append(FileAccess.get_file_as_string(path))

	var joined := "\n".join(text)
	for id in forbidden:
		if joined.contains(id):
			return _check("ComboLevel module excludes legacy/tag upgrade id %s" % [id], false)
	return _check("ComboLevel module excludes condition tag and legacy combo upgrade ids", true)


func _check_blue_mark_combo_upgrade_item() -> bool:
	var item_id := RewardGenerator.new().combo_upgrade_item_id(&"full_house")
	var item := ComboUpgradeItem.from_item_id(item_id)
	var passed := (
		item != null
		and item.item_id == &"upgrade_combo_full_house"
		and item.target_combo_id == &"full_house"
		and item.display_name == "葫芦升级件"
	)

	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.add_item_to_inventory_or_pending(item_id)
	passed = passed and run_state.use_item(item_id)
	passed = passed and run_state.get_combo_level(&"full_house") == 2
	passed = passed and not run_state.item_ids.has(item_id)
	return _check("blue mark creates and uses the current primary combo upgrade item", passed)


func _check_score_engine_uses_run_combo_levels_once() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.combo_levels[&"four_kind"] = 3

	var context := ScoreContext.new()
	context.selected_faces = _make_selected_faces([6, 6, 6, 6, 1])
	context.all_rolled_faces = context.selected_faces
	context.run_state = run_state

	var result := ScoreEngine.new().score(context)
	var passed := (
		result.primary_combo == &"four_kind"
		and result.combo_level == 3
		and result.combo_chips_bonus == 117
		and result.combo_mult == 10
		and result.scored_point_sum == 25
		and result.chips == 142
		and result.mult == 10
		and result.final_score == 1420
	)
	return _check("ScoreEngine reads run combo level for base chips/mult", passed)


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


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
