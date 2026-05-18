extends SceneTree
class_name DebugDiceToolSecondBatchSmokeTest


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const DiceToolService = preload("res://scripts/rules/dice_tools/DiceToolService.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")


func _init() -> void:
	print("--- DebugDiceToolSecondBatchSmokeTest: start ---")
	var all_passed := true
	all_passed = _check_catalog_data() and all_passed
	all_passed = _check_static_forbidden_terms() and all_passed
	all_passed = _check_single_face_blueprint_copy() and all_passed
	all_passed = _check_single_face_blueprint_pending_target_flow() and all_passed
	all_passed = _check_splash_scoring() and all_passed
	all_passed = _check_single_six_reforge_no_slot() and all_passed
	all_passed = _check_star_counter() and all_passed
	all_passed = _check_trail_marker_once() and all_passed
	all_passed = _check_shortcut_straight() and all_passed
	all_passed = _check_copy_hologram() and all_passed
	all_passed = _check_ornament_vampire() and all_passed
	all_passed = _check_max_score_decay() and all_passed
	all_passed = _check_face_count_gap_mult() and all_passed
	all_passed = _check_single_reroll_trade() and all_passed
	all_passed = _check_ancient_point_class() and all_passed
	all_passed = _check_ramen_integer_decay() and all_passed
	all_passed = _check_all_die_shapes_stable() and all_passed
	print("PASS: DebugDiceToolSecondBatchSmokeTest" if all_passed else "FAIL: DebugDiceToolSecondBatchSmokeTest")
	print("--- DebugDiceToolSecondBatchSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_catalog_data() -> bool:
	var passed: bool = DiceToolCatalog.SECOND_BATCH_IDS.size() == 50
	for id in DiceToolCatalog.SECOND_BATCH_IDS:
		var def = DiceToolCatalog.get_def(id)
		passed = passed and def != null
		if def == null:
			continue
		passed = passed and def.is_formal()
		passed = passed and def.display_name != ""
		passed = passed and def.drop_pool_reserved == &"TBD"
		passed = passed and str(def.drop_weight_reserved) == "TBD"
		passed = passed and not _contains_forbidden_text(def.display_name)
		passed = passed and not _contains_forbidden_text(def.effect_text)
	return _check("second batch has 50 formal Chinese dice tool defs", passed)


func _check_static_forbidden_terms() -> bool:
	var text := ""
	for path in [
		"res://scripts/rules/dice_tools/DiceToolCatalog.gd",
		"res://scripts/rules/dice_tools/DiceToolService.gd",
		"res://tests_or_debug/DebugDiceToolSecondBatchSmokeTest.gd",
	]:
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			text += file.get_as_text()
	var passed: bool = not _contains_forbidden_text(text)
	return _check("second batch static text has no forbidden terms", passed)


func _check_single_face_blueprint_copy() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_SINGLE_FACE_BLUEPRINT])
	var service := DiceToolService.new()
	run_state.dice[0].faces[0].pip = 6
	run_state.dice[0].faces[0].ornament_id = FaceState.ORN_CHIP
	run_state.dice[0].faces[0].mark_id = FaceState.MARK_RED
	var before_count := _total_face_count(run_state)
	var result := service.copy_existing_face(run_state, {"die_index": 0, "face_index": 0}, {"die_index": 0, "face_index": 1})
	var target = run_state.dice[0].faces[1]
	var passed: bool = (
		bool(result.get("success", false))
		and _total_face_count(run_state) == before_count
		and target.pip == 6
		and target.ornament_id == FaceState.ORN_CHIP
		and target.mark_id == FaceState.MARK_RED
	)
	return _check("single face blueprint copies onto an existing target face only", passed)


func _check_single_face_blueprint_pending_target_flow() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_SINGLE_FACE_BLUEPRINT])
	run_state.dice[0].faces[0].pip = 5
	run_state.dice[0].faces[0].ornament_id = FaceState.ORN_MULT
	run_state.dice[0].faces[0].mark_id = FaceState.MARK_BLUE
	run_state.pending_dice_tool_face_copy = {
		"source_die_index": 0,
		"source_face_index": 0,
	}
	var before_count := _total_face_count(run_state)
	var flow := GameFlowController.new()
	flow.run_state = run_state
	var result := flow.apply_pending_dice_tool_face_copy(0, 2)
	flow.free()
	var target = run_state.dice[0].faces[2]
	var passed: bool = (
		bool(result.get("success", false))
		and run_state.pending_dice_tool_face_copy.is_empty()
		and _total_face_count(run_state) == before_count
		and target.pip == 5
		and target.ornament_id == FaceState.ORN_MULT
		and target.mark_id == FaceState.MARK_BLUE
	)
	return _check("single face blueprint pending target flow applies through controller service", passed)


func _check_splash_scoring() -> bool:
	var base_run := _run_with_tools([])
	var splash_run := _run_with_tools([DiceToolCatalog.TOOL_SPLASH_SCORING])
	var rolls := [
		_make_roll_from_run(base_run, 0, 1, 2, FaceState.ORN_NONE),
		_make_roll_from_run(base_run, 1, 1, 2, FaceState.ORN_NONE),
		_make_roll_from_run(base_run, 2, 2, 3, FaceState.ORN_CHIP),
	]
	var base_result := _score_rolls_with_run(rolls, base_run)
	var splash_rolls := [
		_make_roll_from_run(splash_run, 0, 1, 2, FaceState.ORN_NONE),
		_make_roll_from_run(splash_run, 1, 1, 2, FaceState.ORN_NONE),
		_make_roll_from_run(splash_run, 2, 2, 3, FaceState.ORN_CHIP),
	]
	var splash_result := _score_rolls_with_run(splash_rolls, splash_run)
	var passed: bool = (
		base_result.scored_point_sum == splash_result.scored_point_sum
		and splash_result.chips == base_result.chips + 30
	)
	return _check("splash scoring retriggers only non-structure ornament without repeating pip sum", passed)


func _check_single_six_reforge_no_slot() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_SINGLE_SIX_REFORGE])
	run_state.item_slot_capacity = 0
	run_state.dice[0].faces[5].pip = 6
	run_state.dice[0].faces[5].ornament_id = FaceState.ORN_CHIP
	run_state.dice[0].faces[5].mark_id = FaceState.MARK_RED
	var roll := _make_roll_from_run(run_state, 0, 5, 6, FaceState.ORN_CHIP, FaceState.MARK_RED)
	var result := _score_rolls_with_run([roll], run_state, FixedRng.new([0.0], [0]), true)
	var face = run_state.dice[0].faces[5]
	var passed: bool = (
		face.pip == 6
		and face.ornament_id == FaceState.ORN_CHIP
		and face.mark_id == FaceState.MARK_RED
		and run_state.item_slots.is_empty()
		and _logs_text_contain(result, "道具槽位不足")
	)
	return _check("single six reforge does not reset when item slots are full", passed)


func _check_star_counter() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_STAR_COUNTER])
	run_state.dice_tools[0].permanent_counters["combo_upgrade_used_count"] = 3
	var result := _score_pips(run_state, [1, 2, 3, 4, 5])
	return _check("star counter grants integer xmult after 3 combo upgrades", int(result.xmult) == 2)


func _check_trail_marker_once() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_TRAIL_MARKER])
	var roll := _make_roll_from_run(run_state, 0, 0, 1)
	var first := _score_rolls_with_run([roll], run_state)
	var second := _score_rolls_with_run([_make_roll_from_run(run_state, 0, 0, 1)], run_state)
	var credited: Dictionary = run_state.dice_tools[0].permanent_counters.get("credited_face_keys", {})
	var passed: bool = credited.size() == 1 and first.chips == second.chips
	return _check("trail marker credits the same physical face only once", passed)


func _check_shortcut_straight() -> bool:
	var shortcut := _score_pips(_run_with_tools([DiceToolCatalog.TOOL_SHORTCUT_STRAIGHT]), [1, 3, 4, 5, 6])
	var stacked := _score_pips(_run_with_tools([DiceToolCatalog.TOOL_SHORTCUT_STRAIGHT, DiceToolCatalog.TOOL_SHORT_STRAIGHT_RULE]), [1, 3, 4, 5])
	var failed_gap := _score_pips(_run_with_tools([DiceToolCatalog.TOOL_SHORTCUT_STRAIGHT]), [1, 3, 5, 6, 7])
	var passed: bool = (
		shortcut.primary_combo == ComboEvaluator.STRAIGHT
		and stacked.primary_combo == ComboEvaluator.STRAIGHT
		and failed_gap.primary_combo != ComboEvaluator.STRAIGHT
	)
	return _check("shortcut straight allows one gap and stacks with four-finger rule", passed)


func _check_copy_hologram() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_COPY_HOLOGRAM])
	var service := DiceToolService.new()
	service.on_face_copied(run_state)
	service.on_face_copied(run_state)
	var result := _score_pips(run_state, [1, 2, 3, 4, 5])
	return _check("copy hologram grants integer xmult every 2 copied faces", int(result.xmult) == 2)


func _check_ornament_vampire() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_ORNAMENT_VAMPIRE])
	run_state.dice[0].faces[0].pip = 6
	run_state.dice[0].faces[0].ornament_id = FaceState.ORN_CHIP
	run_state.dice[0].faces[0].mark_id = FaceState.MARK_RED
	_score_rolls_with_run([_make_roll_from_run(run_state, 0, 0, 6, FaceState.ORN_CHIP, FaceState.MARK_RED)], run_state)
	var face = run_state.dice[0].faces[0]
	var passed: bool = face.pip == 6 and face.ornament_id == FaceState.ORN_NONE and face.mark_id == FaceState.MARK_RED
	return _check("ornament vampire clears only ornament", passed)


func _check_max_score_decay() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_MAX_SCORE_DECAY])
	var service := DiceToolService.new()
	var config := BattleConfig.new()
	service.apply_battle_start_effects(run_state, config)
	var start_limit := config.max_scored_faces_per_round
	var context := _context_for_run(run_state)
	context.battle_state = _fake_battle_state(config)
	var result := ScoreResult.new()
	service.apply_round_end_effects(context, result)
	run_state.dice_tools[0].permanent_counters["bean_bonus"] = 1
	service.apply_round_end_effects(context, result)
	var passed: bool = start_limit == 10 and config.max_scored_faces_per_round == 8 and run_state.dice_tools.is_empty()
	return _check("max score decay modifies max scored faces and self-destructs at zero", passed)


func _check_face_count_gap_mult() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_FACE_COUNT_GAP_MULT])
	run_state.starting_total_face_count = run_state.get_total_face_count()
	run_state.dice[0].face_count = 4
	run_state.dice[0].faces = run_state.dice[0].faces.slice(0, 4)
	run_state.dice[0].face_weights = [1, 1, 1, 1]
	var result := _score_pips(run_state, [1, 2, 3, 4])
	return _check("face count gap mult reads legal total face count gap only", result.mult >= 9)


func _check_single_reroll_trade() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_SINGLE_REROLL_TRADE])
	var service := DiceToolService.new()
	run_state.dice[0].faces[0].ornament_id = FaceState.ORN_CHIP
	run_state.dice[0].faces[0].mark_id = FaceState.MARK_RED
	var before_count := _total_face_count(run_state)
	var logs := service.apply_reroll_before_effects(run_state, [_make_roll_from_run(run_state, 0, 0, 1, FaceState.ORN_CHIP, FaceState.MARK_RED)])
	var face = run_state.dice[0].faces[0]
	var passed: bool = run_state.coins == 3 and _total_face_count(run_state) == before_count and face.ornament_id == FaceState.ORN_NONE and face.mark_id == FaceState.MARK_NONE and not logs.is_empty()
	return _check("single reroll trade resets face and grants coins without changing face count", passed)


func _check_ancient_point_class() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_ANCIENT_POINT_CLASS])
	run_state.dice_tools[0].permanent_counters["ancient_class"] = &"high"
	var result := _score_pips(run_state, [5, 1])
	var has_forbidden_fact := result.facts.has("same_domain") or result.tags.has(&"same_domain")
	return _check("ancient point class uses only local class state", int(result.xmult) == 2 and not has_forbidden_fact)


func _check_ramen_integer_decay() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_REROLL_DECAY_X2])
	var first := _score_pips(run_state, [1, 2, 3, 4, 5])
	run_state.dice_tools[0].permanent_counters["rerolled_face_count_for_ramen"] = 10
	var second := _score_pips(run_state, [1, 2, 3, 4, 5])
	return _check("ramen uses integer xmult decay from 2 to 1 after 10 rerolled faces", int(first.xmult) == 2 and int(second.xmult) == 1)


func _check_all_die_shapes_stable() -> bool:
	var run_state := _run_with_tools(DiceToolCatalog.SECOND_BATCH_IDS)
	for die in run_state.dice:
		if die.faces.size() != die.face_count:
			return _check("all dice keep faces.size equal to face_count", false)
	return _check("all dice keep faces.size equal to face_count", true)


func _run_with_tools(tool_ids: Array) -> RunState:
	var run_state := RunState.new()
	run_state.setup_new_run()
	for id in tool_ids:
		run_state.dice_tools.append(_tool(StringName(str(id))))
	run_state.installed_tools = run_state.dice_tools
	return run_state


func _tool(tool_id: StringName) -> DiceToolState:
	var def = DiceToolCatalog.get_def(tool_id)
	return DiceToolState.create(tool_id, DiceToolCatalog.display_name_for_id(tool_id), DiceToolCatalog.sell_value_for_rarity(def.rarity), def.rarity)


func _score_pips(run_state: RunState, pips: Array, fixed_rng = null) -> ScoreResult:
	var rolls: Array[RolledFace] = []
	for index in range(pips.size()):
		rolls.append(_make_roll_from_run(run_state, index, 0, int(pips[index])))
	return _score_rolls_with_run(rolls, run_state, fixed_rng)


func _score_rolls_with_run(rolls: Array, run_state: RunState, fixed_rng = null, first_round: bool = false) -> ScoreResult:
	var context := _context_for_run(run_state)
	var typed_rolls: Array[RolledFace] = []
	for roll in rolls:
		typed_rolls.append(roll)
	context.selected_faces = typed_rolls
	context.all_rolled_faces = typed_rolls
	context.rng = fixed_rng if fixed_rng != null else FixedRng.new([0.99, 0.99, 0.99], [0])
	if first_round:
		var hand := HandState.new()
		hand.hand_index = 0
		context.hand_state = hand
	return ScoreEngine.new().score(context)


func _context_for_run(run_state: RunState) -> ScoreContext:
	var context := ScoreContext.new()
	context.run_state = run_state
	context.source_dice = run_state.dice
	return context


func _fake_battle_state(config: BattleConfig):
	var BattleState = preload("res://scripts/core/battle/BattleState.gd")
	var state = BattleState.new()
	state.config = config
	return state


func _make_roll_from_run(run_state: RunState, die_index: int, face_index: int, pip: int, ornament_id: StringName = FaceState.ORN_NONE, mark_id: StringName = FaceState.MARK_NONE) -> RolledFace:
	var face := FaceState.new(pip, ornament_id, mark_id)
	var roll := RolledFace.new()
	roll.set_roll(die_index, face_index, face, run_state.dice[die_index])
	return roll


func _total_face_count(run_state: RunState) -> int:
	var count := 0
	for die in run_state.dice:
		count += die.faces.size()
	return count


func _logs_text_contain(result: ScoreResult, needle: String) -> bool:
	for entry in result.logs:
		if entry != null and entry.get_text().contains(needle):
			return true
	return false


func _contains_forbidden_text(text: String) -> bool:
	for word in [
		"同" + "域",
		"小" + "顺",
		"大" + "顺",
		"每" + "手",
		"本" + "手",
		"消耗" + "槽",
		"消耗品" + "槽",
		"X" + "1.5",
		"X" + "0.",
		"+" + "X" + "0.",
		"-" + "X" + "0.",
		"150" + "%",
		"25" + "%",
		"10" + "%",
		"骰面" + "等级",
		"骰子" + "等级",
		"新增" + "骰面",
		"删除" + "骰面",
	]:
		if text.contains(word):
			return true
	return false


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
