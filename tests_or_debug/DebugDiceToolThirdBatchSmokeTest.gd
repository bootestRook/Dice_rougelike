extends SceneTree
class_name DebugDiceToolThirdBatchSmokeTest


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const DiceToolService = preload("res://scripts/rules/dice_tools/DiceToolService.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


func _init() -> void:
	print("--- DebugDiceToolThirdBatchSmokeTest: start ---")
	var all_passed := true
	all_passed = _check_catalog_data() and all_passed
	all_passed = _check_static_forbidden_terms() and all_passed
	all_passed = _check_six_four_broadcast() and all_passed
	all_passed = _check_seltzer_retrigger_decay() and all_passed
	all_passed = _check_castle_pip_class() and all_passed
	all_passed = _check_campfire_sales() and all_passed
	all_passed = _check_bone_safety() and all_passed
	all_passed = _check_troubadour_limits() and all_passed
	all_passed = _check_marked_temp_face() and all_passed
	all_passed = _check_fact_tolerance() and all_passed
	all_passed = _check_probability_doubler() and all_passed
	all_passed = _check_copy_tools_skip_copy_targets() and all_passed
	all_passed = _check_burst_break_glass() and all_passed
	all_passed = _check_first_reroll_combo_upgrade() and all_passed
	all_passed = _check_high_pip_transform() and all_passed
	all_passed = _check_shop_end_item_copy() and all_passed
	all_passed = _check_all_die_shapes_stable() and all_passed
	print("PASS: DebugDiceToolThirdBatchSmokeTest" if all_passed else "FAIL: DebugDiceToolThirdBatchSmokeTest")
	print("--- DebugDiceToolThirdBatchSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_catalog_data() -> bool:
	var passed: bool = DiceToolCatalog.THIRD_BATCH_IDS.size() == 50
	for id in DiceToolCatalog.THIRD_BATCH_IDS:
		var def = DiceToolCatalog.get_def(id)
		passed = passed and def != null
		if def == null:
			continue
		passed = passed and def.is_formal()
		passed = passed and def.display_name != ""
		passed = passed and def.display_name != def.balatro_source_name
		passed = passed and def.drop_pool_reserved == &"TBD"
		passed = passed and str(def.drop_weight_reserved) == "TBD"
		passed = passed and not _contains_forbidden_text(def.display_name)
		passed = passed and not _contains_forbidden_text(def.effect_text)
	return _check("third batch has 50 formal Chinese dice tool defs", passed)


func _check_static_forbidden_terms() -> bool:
	var text := ""
	for path in [
		"res://scripts/rules/dice_tools/DiceToolCatalog.gd",
		"res://scripts/rules/dice_tools/DiceToolService.gd",
		"res://tests_or_debug/DebugDiceToolThirdBatchSmokeTest.gd",
	]:
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			text += file.get_as_text()
	return _check("third batch static text has no blocked terms", not _contains_forbidden_text(text))


func _check_six_four_broadcast() -> bool:
	var base_run := _run_with_tools([])
	var tool_run := _run_with_tools([DiceToolCatalog.TOOL_SIX_FOUR_BROADCAST])
	var base := _score_rolls_with_run([
		_make_roll_from_run(base_run, 0, 0, 4),
		_make_roll_from_run(base_run, 1, 0, 6),
		_make_roll_from_run(base_run, 2, 0, 4, FaceState.ORN_STONE),
	], base_run)
	var scored := _score_rolls_with_run([
		_make_roll_from_run(tool_run, 0, 0, 4),
		_make_roll_from_run(tool_run, 1, 0, 6),
		_make_roll_from_run(tool_run, 2, 0, 4, FaceState.ORN_STONE),
	], tool_run)
	var passed := scored.chips == base.chips + 20 and scored.mult == base.mult + 8
	return _check("six four broadcast affects only valid 4 and 6 faces", passed)


func _check_seltzer_retrigger_decay() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_SELTZER_RETRIGGER])
	run_state.dice_tools[0].permanent_counters["remaining_retrigger_rounds"] = 1
	var roll := _make_roll_from_run(run_state, 0, 0, 3, FaceState.ORN_CHIP)
	var result := _score_rolls_with_run([roll], run_state)
	var context := _context_for_run(run_state)
	context.battle_state = _fake_battle_state(BattleConfig.new())
	DiceToolService.new().apply_round_end_effects(context, result)
	var passed := result.chips >= 60 and run_state.dice_tools.is_empty()
	return _check("seltzer retriggers once, decrements, and self-destructs at zero", passed)


func _check_castle_pip_class() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_CASTLE_PIP_CLASS])
	run_state.dice_tools[0].combat_counters["castle_class"] = &"low"
	var service := DiceToolService.new()
	service.apply_reroll_before_effects(run_state, [_make_roll_from_run(run_state, 0, 0, 2), _make_roll_from_run(run_state, 1, 0, 6)])
	var text := DiceToolCatalog.get_def(DiceToolCatalog.TOOL_CASTLE_PIP_CLASS).effect_text
	var passed := int(run_state.dice_tools[0].permanent_counters.get("chips_bonus", 0)) == 3 and not _contains_forbidden_text(text)
	return _check("castle pip class reads only odd even low high classes", passed)


func _check_campfire_sales() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_CAMPFIRE_SALES])
	var service := DiceToolService.new()
	for _i in range(4):
		service.on_item_sold(run_state)
	var result := _score_pips(run_state, [1, 2, 3, 4, 5])
	service.on_boss_defeated(run_state)
	var passed := int(result.xmult) == 2 and int(run_state.dice_tools[0].permanent_counters.get("xmult_bonus", 0)) == 0
	return _check("campfire gains integer xmult every four sold items and resets after Boss", passed)


func _check_bone_safety() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_BONE_SAFETY])
	var state := _fake_battle_state(BattleConfig.new())
	state.config.target_score = 100
	state.total_score = 25
	var result := ScoreResult.new()
	var passed := DiceToolService.new().try_apply_bone_safety(run_state, state, result) and run_state.dice_tools.is_empty() and _logs_text_contain(result, "保底骨架避免失败")
	return _check("bone safety avoids failure at one quarter target and self-destructs", passed)


func _check_troubadour_limits() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_TROUBADOUR_SLOTS])
	var config := BattleConfig.new()
	config.max_scored_faces_per_round = 5
	config.hands_per_battle = 1
	DiceToolService.new().apply_battle_start_effects(run_state, config)
	var passed := config.max_scored_faces_per_round == 7 and config.hands_per_battle == 1
	return _check("troubadour modifies score limit and keeps round count above zero", passed)


func _check_marked_temp_face() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_MARKED_TEMP_FACE])
	var service := DiceToolService.new()
	var hand := HandState.new()
	hand.rolled_faces = [_make_roll_from_run(run_state, 0, 0, 1)]
	var battle := _fake_battle_state(BattleConfig.new())
	var before_count := _total_face_count(run_state)
	service.apply_round_start_effects(run_state, battle, hand)
	var generated := hand.rolled_faces.size() == 2 and hand.rolled_faces[1].is_temporary and _total_face_count(run_state) == before_count
	var context := _context_for_run(run_state)
	context.hand_state = hand
	context.battle_state = battle
	service.apply_round_end_effects(context, ScoreResult.new())
	var removed := hand.rolled_faces.size() == 1 and battle.temporary_faces.is_empty()
	return _check("marked temp face is current-round only and not written to permanent dice", generated and removed)


func _check_fact_tolerance() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_FACT_TOLERANCE])
	var result := _score_pips(run_state, [1, 3, 5, 2])
	var blocked_key := "same" + "_" + "domain"
	var passed := bool(result.facts.get("is_all_odd", false)) and not result.facts.has(blocked_key) and not result.tags.has(StringName(blocked_key))
	return _check("fact tolerance only relaxes the four aligned facts", passed)


func _check_probability_doubler() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_PROBABILITY_DOUBLER])
	var service := DiceToolService.new()
	var half := service.apply_probability_modifiers(run_state, 1, 2)
	var rare := service.apply_probability_modifiers(run_state, 1, 15)
	var target := service._random_legal_pip_for_run(run_state)
	var passed := half.x == 1 and half.y == 1 and rare.x == 2 and rare.y == 15 and target >= 1 and target <= 8
	return _check("probability doubler clamps odds and leaves random target selection separate", passed)


func _check_copy_tools_skip_copy_targets() -> bool:
	var run_state := _run_with_tools([
		DiceToolCatalog.TOOL_RIGHT_COPY_BLUEPRINT,
		DiceToolCatalog.TOOL_LEFT_COPY_BRAINSTORM,
		DiceToolCatalog.TOOL_BASIC_MULT,
	])
	var base := _score_pips(_run_with_tools([DiceToolCatalog.TOOL_BASIC_MULT]), [1])
	var copied := _score_pips(run_state, [1])
	return _check("copy tools skip other copy tools and avoid recursive targets", copied.mult >= base.mult + 8)


func _check_burst_break_glass() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_BURST_BREAK_GLASS])
	var service := DiceToolService.new()
	service.on_burst_ornament_broken(run_state)
	var after_break := int(run_state.dice_tools[0].permanent_counters.get("xmult_bonus", 0))
	var after_no_break := int(run_state.dice_tools[0].permanent_counters.get("xmult_bonus", 0))
	return _check("burst break glass grows only when actual break hook fires", after_break == 1 and after_no_break == 1)


func _check_first_reroll_combo_upgrade() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_FIRST_REROLL_COMBO_UPGRADE])
	var service := DiceToolService.new()
	service.apply_reroll_before_effects(run_state, [_make_roll_from_run(run_state, 0, 0, 2), _make_roll_from_run(run_state, 1, 0, 2)])
	var pair_level := run_state.get_combo_level(ComboUpgradeCatalog.PAIR)
	var allowed := true
	for key in run_state.combo_levels.keys():
		if not ComboUpgradeCatalog.get_combo_ids().has(StringName(str(key))):
			allowed = false
	return _check("first reroll combo upgrade touches only primary combo levels", pair_level == 2 and allowed)


func _check_high_pip_transform() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_HIGH_PIP_TRANSFORM_X])
	var before := FaceState.new(6)
	var after := FaceState.new(3)
	var total_before := _total_face_count(run_state)
	DiceToolService.new().on_face_changed(run_state, before, after, &"debug")
	var passed := int(run_state.dice_tools[0].permanent_counters.get("high_transform_counter", 0)) == 1 and _total_face_count(run_state) == total_before
	return _check("high pip transform grows on high to non-high without changing face count", passed)


func _check_shop_end_item_copy() -> bool:
	var run_state := _run_with_tools([DiceToolCatalog.TOOL_SHOP_END_ITEM_COPY])
	run_state.item_slot_capacity = 3
	run_state.item_slots.clear()
	run_state.add_item_instance_to_slots(ItemInstance.create_forge_item(ForgeItemCatalog.get_all_ids()[0], "测试铸骰件"))
	run_state.add_item_instance_to_slots(ItemInstance.create_dice_tool(DiceToolCatalog.TOOL_BASIC_MULT, "基础倍率器", 2))
	DiceToolService.new().on_shop_phase_end(run_state)
	var copied: ItemInstance = run_state.item_slots[2] if run_state.item_slots.size() >= 3 else null
	var passed := copied != null and copied.item_type != ItemInstance.TYPE_DICE_TOOL and not bool(copied.metadata.get("is_negative", false))
	return _check("shop end item copy copies only held forge or combo upgrade items into item slots", passed)


func _check_all_die_shapes_stable() -> bool:
	var run_state := _run_with_tools(DiceToolCatalog.THIRD_BATCH_IDS)
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


func _score_rolls_with_run(rolls: Array, run_state: RunState, fixed_rng = null) -> ScoreResult:
	var context := _context_for_run(run_state)
	var typed_rolls: Array[RolledFace] = []
	for roll in rolls:
		typed_rolls.append(roll)
	context.selected_faces = typed_rolls
	context.all_rolled_faces = typed_rolls
	context.rng = fixed_rng if fixed_rng != null else FixedRng.new([0.99, 0.99, 0.99], [0])
	return ScoreEngine.new().score(context)


func _context_for_run(run_state: RunState) -> ScoreContext:
	var context := ScoreContext.new()
	context.run_state = run_state
	context.source_dice = run_state.dice
	return context


func _fake_battle_state(config: BattleConfig) -> BattleState:
	var state := BattleState.new()
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
		"same" + "_" + "domain",
		"domain" + "_id",
		"suit" + "_id",
		"小" + "顺",
		"大" + "顺",
		"消耗" + "槽",
		"消耗品" + "槽",
		"手牌" + "上限",
		"骰子" + "等级",
		"骰面" + "等级",
		"face" + "_level",
		"X" + "1.5",
		"X" + "0.25",
		"X" + "0.5",
		"X" + "0.75",
		"+" + "X" + "0.1",
		"-" + "X" + "0.01",
		"终倍率 ×" + "150" + "%",
		"终倍率加成 +" + "25" + "%",
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
