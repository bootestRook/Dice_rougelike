extends SceneTree
class_name DebugDiceToolFirstBatchSmokeTest


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const DiceToolService = preload("res://scripts/rules/dice_tools/DiceToolService.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


func _init() -> void:
	print("--- DebugDiceToolFirstBatchSmokeTest: start ---")

	var all_passed := true
	all_passed = _check_catalog_data() and all_passed
	all_passed = _check_pip_helpers() and all_passed
	all_passed = _check_short_straight_rule() and all_passed
	all_passed = _check_stone_seed() and all_passed
	all_passed = _check_six_forge_generator_slot_full() and all_passed
	all_passed = _check_space_combo_upgrade() and all_passed
	all_passed = _check_stay_ornament_xmult() and all_passed
	all_passed = _check_unscored_blackboard_empty() and all_passed
	all_passed = _check_pareidolia_keeps_real_pips() and all_passed
	all_passed = _check_trigger_logs() and all_passed

	print("PASS: DebugDiceToolFirstBatchSmokeTest" if all_passed else "FAIL: DebugDiceToolFirstBatchSmokeTest")
	print("--- DebugDiceToolFirstBatchSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_catalog_data() -> bool:
	var defs: Array = []
	for id in DiceToolCatalog.FIRST_BATCH_IDS:
		defs.append(DiceToolCatalog.get_def(id))
	var ids: Array[StringName] = []
	var passed := defs.size() == 50
	for def in defs:
		if def == null:
			passed = false
			continue
		ids.append(def.tool_id)
		passed = passed and def.is_formal()
		passed = passed and def.drop_pool_reserved == &"TBD"
		passed = passed and str(def.drop_weight_reserved) == "TBD"
		passed = passed and def.display_name != ""
		passed = passed and not _contains_forbidden_text(def.display_name)
		passed = passed and not _contains_forbidden_text(def.effect_text)
		passed = passed and not _contains_forbidden_text(def.notes)
		passed = passed and not def.display_name.contains(def.balatro_source_name)
	passed = passed and ids.size() == _unique_ids(ids).size()
	for id in DiceToolCatalog.FIRST_BATCH_IDS:
		passed = passed and ids.has(id)
	return _check("first batch has 50 formal Chinese dice tool defs without forbidden old terms", passed)


func _check_pip_helpers() -> bool:
	var service := DiceToolService.new()
	var passed := (
		service.is_low_pip(1)
		and service.is_low_pip(4)
		and not service.is_low_pip(5)
		and service.is_high_pip(5)
		and service.is_high_pip(8)
		and not service.is_high_pip(4)
		and service.is_even_pip(8)
		and service.is_odd_pip(7)
	)
	return _check("high and low pip helpers use 5/6/7/8 and 1/2/3/4", passed)


func _check_short_straight_rule() -> bool:
	var straight_result := _score([1, 2, 3, 4], [DiceToolCatalog.TOOL_SHORT_STRAIGHT_RULE])
	var aligned_result := _score([1, 3, 5, 7], [DiceToolCatalog.TOOL_SHORT_STRAIGHT_RULE, DiceToolCatalog.TOOL_ALIGNED_FACT_MULT])
	var passed := (
		straight_result.primary_combo == &"straight"
		and aligned_result.primary_combo != &"straight"
		and aligned_result.mult == aligned_result.combo_mult + 10
	)
	return _check("four-finger rule only shortens straight detection and does not rewrite aligned facts", passed)


func _check_stone_seed() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.dice_tools.append(_tool(DiceToolCatalog.TOOL_STONE_SEED))
	run_state.installed_tools = run_state.dice_tools
	var before_faces := _total_face_count(run_state)
	var before_dice := run_state.dice.size()
	var service := DiceToolService.new()
	service.apply_battle_start_effects(run_state, BattleConfig.new())
	var after_faces := _total_face_count(run_state)
	var stone_count := _count_ornaments(run_state, FaceState.ORN_STONE)
	var passed := before_dice == run_state.dice.size() and before_faces == after_faces and stone_count == 1
	return _check("stone seed only replaces one existing face ornament", passed)


func _check_six_forge_generator_slot_full() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.item_slot_capacity = 0
	run_state.dice_tools.append(_tool(DiceToolCatalog.TOOL_SIX_FORGE_GENERATOR))
	run_state.installed_tools = run_state.dice_tools
	var result := _score_with_run([6], run_state, FixedRng.new([0.0], []))
	var passed := run_state.item_slots.is_empty() and _logs_text_contain(result, "道具槽位不足")
	return _check("six forge generator does not generate when item slots are full", passed)


func _check_space_combo_upgrade() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.dice_tools.append(_tool(DiceToolCatalog.TOOL_SPACE_COMBO_UPGRADE))
	run_state.installed_tools = run_state.dice_tools
	var result := _score_with_run([2, 2], run_state, FixedRng.new([0.0], []))
	var legal_keys := true
	for key in run_state.combo_levels.keys():
		legal_keys = legal_keys and ComboUpgradeCatalog.get_def_by_upgrade_id(StringName(str(key))) != null
	var passed := (
		result.primary_combo == &"pair"
		and run_state.get_combo_level(&"pair") == 2
		and legal_keys
		and not run_state.combo_levels.has(&"contains_pair")
	)
	return _check("space combo upgrade only upgrades the primary combo level", passed)


func _check_stay_ornament_xmult() -> bool:
	var result_0 := _score_stay_xmult_count(0)
	var result_5 := _score_stay_xmult_count(5)
	var result_10 := _score_stay_xmult_count(10)
	var passed := (
		is_equal_approx(result_0.xmult, 1.0)
		and is_equal_approx(result_5.xmult, 2.0)
		and is_equal_approx(result_10.xmult, 3.0)
	)
	return _check("stay ornament xmult uses integer factors at 0/5/10 faces", passed)


func _check_unscored_blackboard_empty() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.dice_tools.append(_tool(DiceToolCatalog.TOOL_UNSCORED_LOW_HIGH_XMULT))
	run_state.installed_tools = run_state.dice_tools
	var selected := _make_roll(0, 0, 1)
	var stone_unscored := _make_roll(1, 0, 6, FaceState.ORN_STONE, false)
	var result := _score_rolls_with_run([selected], [selected, stone_unscored], run_state)
	var passed := is_equal_approx(result.xmult, 1.0)
	return _check("blackboard does not trigger with no valid unscored stay pips", passed)


func _check_pareidolia_keeps_real_pips() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.dice_tools.append(_tool(DiceToolCatalog.TOOL_ALL_FACES_HIGH_FOR_TOOLS))
	run_state.dice_tools.append(_tool(DiceToolCatalog.TOOL_HIGH_PIP_CHIPS))
	run_state.installed_tools = run_state.dice_tools
	var result := _score_with_run([1, 1, 2], run_state)
	var passed := (
		result.primary_combo == &"pair"
		and result.scored_point_sum == 4
		and result.chips == result.combo_chips_bonus + result.scored_point_sum + 90
	)
	return _check("pareidolia affects dice tool high checks but not real pips, point sum, or primary combo", passed)


func _check_trigger_logs() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.dice_tools.append(_tool(DiceToolCatalog.TOOL_BASIC_MULT))
	run_state.dice_tools.append(_tool(DiceToolCatalog.TOOL_RANDOM_MULT))
	run_state.installed_tools = run_state.dice_tools
	var result := _score_with_run([6], run_state, FixedRng.new([], [7]))
	var passed := (
		_logs_text_contain(result, "基础倍率器")
		and _logs_text_contain(result, "乱码倍率器")
		and _logs_text_contain(result, "随机结果 +7 倍率")
	)
	return _check("triggered dice tools write settlement logs", passed)


func _score(pips: Array, tool_ids: Array) -> ScoreResult:
	var run_state := RunState.new()
	run_state.setup_new_run()
	for id in tool_ids:
		run_state.dice_tools.append(_tool(StringName(str(id))))
	run_state.installed_tools = run_state.dice_tools
	return _score_with_run(pips, run_state)


func _score_with_run(pips: Array, run_state: RunState, fixed_rng = null) -> ScoreResult:
	var rolls: Array[RolledFace] = []
	for index in range(pips.size()):
		rolls.append(_make_roll(index, 0, int(pips[index])))
	return _score_rolls_with_run(rolls, rolls, run_state, fixed_rng)


func _score_rolls_with_run(selected: Array, all_rolls: Array, run_state: RunState, fixed_rng = null) -> ScoreResult:
	var context := ScoreContext.new()
	context.selected_faces = _to_roll_array(selected)
	context.all_rolled_faces = _to_roll_array(all_rolls)
	context.run_state = run_state
	context.source_dice = run_state.dice
	context.rng = fixed_rng if fixed_rng != null else FixedRng.new([0.99, 0.99, 0.99], [0])
	return ScoreEngine.new().score(context)


func _score_stay_xmult_count(count: int) -> ScoreResult:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.dice_tools.append(_tool(DiceToolCatalog.TOOL_STAY_ORNAMENT_XMULT))
	run_state.installed_tools = run_state.dice_tools
	var applied := 0
	for die in run_state.dice:
		for face in die.faces:
			face.ornament_id = FaceState.ORN_NONE
			if applied < count:
				face.ornament_id = FaceState.ORN_STAY
				applied += 1
	return _score_with_run([1], run_state)


func _make_roll(
	die_index: int,
	face_index: int,
	pip: int,
	ornament_id: StringName = FaceState.ORN_NONE,
	selected: bool = true
) -> RolledFace:
	var face := FaceState.new(pip, ornament_id, FaceState.MARK_NONE)
	var roll := RolledFace.new()
	roll.set_roll(die_index, face_index, face)
	roll.selected = selected
	return roll


func _to_roll_array(values: Array) -> Array[RolledFace]:
	var result: Array[RolledFace] = []
	for value in values:
		if value is RolledFace:
			result.append(value)
	return result


func _tool(tool_id: StringName) -> DiceToolState:
	return DiceToolState.create(tool_id, DiceToolCatalog.display_name_for_id(tool_id), DiceToolCatalog.sell_value_for_rarity(DiceToolCatalog.get_def(tool_id).rarity))


func _contains_forbidden_text(text: String) -> bool:
	for word in [
		"同" + "域",
		"花色" + "→点域重构",
		"小" + "顺",
		"大" + "顺",
		"高点面" + "（4/5/6）",
		"低点面" + "（1/2/3）",
		"消耗" + "槽",
		"每" + "手",
		"本" + "手",
		"最后一" + "手",
		"X" + "1.5",
		"X" + "0.2",
		"+" + "X" + "0.25",
		"百分比" + "终倍率",
	]:
		if text.contains(word):
			return true
	return false


func _logs_text_contain(result, needle: String) -> bool:
	for entry in result.logs:
		if entry != null and entry.get_text().contains(needle):
			return true
	return false


func _total_face_count(run_state: RunState) -> int:
	var count := 0
	for die in run_state.dice:
		count += die.faces.size()
	return count


func _count_ornaments(run_state: RunState, ornament_id: StringName) -> int:
	var count := 0
	for die in run_state.dice:
		for face in die.faces:
			if face.get_effective_ornament_id() == ornament_id:
				count += 1
	return count


func _unique_ids(ids: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for id in ids:
		if not result.has(id):
			result.append(id)
	return result


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed


class FixedRng:
	extends RefCounted

	var floats: Array = []
	var ints: Array = []

	func _init(new_floats: Array = [], new_ints: Array = []) -> void:
		floats = new_floats.duplicate()
		ints = new_ints.duplicate()

	func randf() -> float:
		if floats.is_empty():
			return 0.99
		return float(floats.pop_front())

	func randi_range(from_value: int, to_value: int) -> int:
		if ints.is_empty():
			return from_value
		return clampi(int(ints.pop_front()), from_value, to_value)
