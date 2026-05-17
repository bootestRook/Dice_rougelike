extends SceneTree
class_name DebugDieBodyWholeDieServicesSmokeTest


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const DieBodyCatalog = preload("res://scripts/rules/forge/DieBodyCatalog.gd")
const WholeDieService = preload("res://scripts/rules/forge/WholeDieService.gd")
const WholeDieServiceCatalog = preload("res://scripts/rules/forge/WholeDieServiceCatalog.gd")
const WholeDieServiceMigration = preload("res://scripts/rules/forge/WholeDieServiceMigration.gd")


func _init() -> void:
	print("--- DebugDieBodyWholeDieServicesSmokeTest: start ---")

	var all_passed := true
	all_passed = _check_body_catalog() and all_passed
	all_passed = _check_standard_body_no_extra_effect() and all_passed
	all_passed = _check_iron_body_once_and_stay_bonus() and all_passed
	all_passed = _check_glass_body_burst_bonus() and all_passed
	all_passed = _check_biased_weights() and all_passed
	all_passed = _check_hollow_body_once_after_reroll() and all_passed
	all_passed = _check_mirror_body_retriggers_ornament_only() and all_passed
	all_passed = _check_cracked_body_absorbs_first_break() and all_passed
	all_passed = _check_merchant_body_adds_only_existing_coin_events() and all_passed
	all_passed = _check_whole_die_catalog_and_migration() and all_passed
	all_passed = _check_convert_d4() and all_passed
	all_passed = _check_convert_d6() and all_passed
	all_passed = _check_convert_d8() and all_passed
	all_passed = _check_change_body_keeps_faces() and all_passed
	all_passed = _check_full_reforge_keeps_one_face() and all_passed
	all_passed = _check_text_and_config_constraints() and all_passed

	print("PASS: DebugDieBodyWholeDieServicesSmokeTest" if all_passed else "FAIL: DebugDieBodyWholeDieServicesSmokeTest")
	print("--- DebugDieBodyWholeDieServicesSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_body_catalog() -> bool:
	var defs := DieBodyCatalog.get_all_defs()
	var ids: Array[StringName] = []
	var passed := defs.size() == 8
	for def in defs:
		passed = passed and def != null
		passed = passed and def.is_formal()
		passed = passed and def.reserved_drop_pool == &"TBD"
		passed = passed and def.reserved_drop_weight == &"TBD"
		ids.append(def.body_id)
	passed = passed and ids.has(DieState.BODY_CRACKED)
	passed = passed and ids.has(DieState.BODY_MERCHANT)
	passed = passed and DisplayNames.body_name(DieState.BODY_CRACKED) == "裂纹骰胚"
	passed = passed and DisplayNames.body_name(DieState.BODY_MERCHANT) == "商人骰胚"
	return _check("body catalog has eight formal body defs with TBD drop fields", passed)


func _check_standard_body_no_extra_effect() -> bool:
	var standard := _score([_make_roll(0, 0, 1, FaceState.ORN_NONE, FaceState.MARK_NONE, DieState.BODY_STANDARD)])
	var iron := _score(
		[_make_roll(0, 0, 1)],
		[_make_roll(0, 0, 1), _make_roll(1, 0, 2, FaceState.ORN_NONE, FaceState.MARK_NONE, DieState.BODY_IRON, false)]
	)
	return _check("body_standard has no extra effect", standard.final_score == 6 and iron.chips == standard.chips + 10)


func _check_iron_body_once_and_stay_bonus() -> bool:
	var selected := _make_roll(0, 0, 1)
	var iron_stay := _make_roll(1, 0, 5, FaceState.ORN_STAY, FaceState.MARK_NONE, DieState.BODY_IRON, false)
	var result := _score([selected], [selected, iron_stay])
	var once_context := ScoreContext.new()
	once_context.selected_faces = [selected]
	once_context.all_rolled_faces = [selected, iron_stay, _make_roll(1, 1, 4, FaceState.ORN_NONE, FaceState.MARK_NONE, DieState.BODY_IRON, false)]
	var once_result := ScoreEngine.new().score(once_context)
	var passed := (
		result.chips == 16
		and result.mult == 3
		and is_equal_approx(result.xmult, 2.0)
		and _logs_contain(result, [&"LOG.BODY_IRON"])
		and once_result.chips == 16
	)
	return _check("body_iron triggers once and stay face adds +2 mult", passed)


func _check_glass_body_burst_bonus() -> bool:
	var result := _score([_make_roll(0, 0, 1, FaceState.ORN_BURST, FaceState.MARK_NONE, DieState.BODY_GLASS)])
	var source := FileAccess.get_file_as_string("res://scripts/rules/scoring/EffectResolver.gd")
	var passed := (
		result.xmult == 3.0
		and result.final_score == 18
		and source.contains("GLASS_BURST_XMULT_BONUS_PERCENT := 25")
		and not source.contains("2.25")
		and not source.contains("破碎成长")
	)
	return _check("body_glass uses +25 percent burst bonus without growth counter", passed)


func _check_biased_weights() -> bool:
	var die := _make_die(&"biased", 6, DieState.BODY_BIASED)
	var service := WholeDieService.new()
	service.init_biased_weights(die, 2)
	var passed := die.face_weights == [1, 1, 2, 1, 1, 1]
	var run_state := _make_run_with_dice([die])
	service.convert_die_to_d4(run_state, 0, [0, 1, 2, 3], 1)
	passed = passed and run_state.dice[0].face_weights == [1, 2, 1, 1]
	service.change_body(run_state, 0, DieState.BODY_STANDARD)
	passed = passed and run_state.dice[0].face_weights == [1, 1, 1, 1]
	return _check("body_biased initializes exactly one weight 2 and refreshes on body/face count changes", passed)


func _check_hollow_body_once_after_reroll() -> bool:
	var roll := _make_roll(0, 0, 1, FaceState.ORN_NONE, FaceState.MARK_NONE, DieState.BODY_HOLLOW)
	var context := ScoreContext.new()
	context.selected_faces = [roll]
	context.all_rolled_faces = [roll]
	context.rerolled_die_ids_this_round[roll.die_id] = true
	var result := ScoreEngine.new().score(context)
	var duplicate := _make_roll(0, 1, 2, FaceState.ORN_NONE, FaceState.MARK_NONE, DieState.BODY_HOLLOW)
	var once_context := ScoreContext.new()
	once_context.selected_faces = [roll, duplicate]
	once_context.all_rolled_faces = [roll, duplicate]
	once_context.rerolled_die_ids_this_round[roll.die_id] = true
	var once_result := ScoreEngine.new().score(once_context)
	var passed := result.chips == 11 and result.mult == 2 and result.final_score == 22
	passed = passed and once_result.mult < 4 and _logs_contain(result, [&"LOG.BODY_HOLLOW"])
	return _check("body_hollow triggers after reroll and does not stack by reroll count", passed)


func _check_mirror_body_retriggers_ornament_only() -> bool:
	var mirror := _make_roll(0, 0, 4, FaceState.ORN_CHIP, FaceState.MARK_NONE, DieState.BODY_MIRROR)
	var match_roll := _make_roll(1, 0, 4)
	var result := _score([mirror, match_roll])
	var stone_match := _make_roll(1, 0, 4, FaceState.ORN_STONE)
	var stone_result := _score([_make_roll(0, 0, 4, FaceState.ORN_CHIP, FaceState.MARK_NONE, DieState.BODY_MIRROR), stone_match])
	var passed := _log_count(result, &"LOG.ORNAMENT_CHIP") == _log_count(stone_result, &"LOG.ORNAMENT_CHIP") + 1
	passed = passed and _logs_contain(result, [&"LOG.BODY_MIRROR"])
	passed = passed and not _logs_contain(stone_result, [&"LOG.BODY_MIRROR"])
	return _check("body_mirror retriggers ornament once and stone faces do not match point logic", passed)


func _check_cracked_body_absorbs_first_break() -> bool:
	var die := _make_die(&"cracked", 6, DieState.BODY_CRACKED)
	die.faces[0].ornament_id = FaceState.ORN_BURST
	var battle_state := BattleState.new()
	battle_state.dice.append(die)
	var first_context := ScoreContext.new()
	first_context.selected_faces = [_roll_from_die(die, 0, 0)]
	first_context.all_rolled_faces = first_context.selected_faces
	first_context.battle_state = battle_state
	first_context.rng = FixedRng.new([0.0])
	var first := ScoreEngine.new().score(first_context)
	var second_context := ScoreContext.new()
	second_context.selected_faces = [_roll_from_die(die, 0, 0)]
	second_context.all_rolled_faces = second_context.selected_faces
	second_context.battle_state = battle_state
	second_context.rng = FixedRng.new([0.0])
	var second := ScoreEngine.new().score(second_context)
	var passed := (
		die.faces[0].ornament_id == FaceState.ORN_NONE
		and _logs_contain(first, [&"LOG.BODY_CRACKED_ABSORB"])
		and _logs_contain(second, [&"LOG.ORNAMENT_BURST_BREAK"])
	)
	return _check("body_cracked absorbs first burst break and second break is normal", passed)


func _check_merchant_body_adds_only_existing_coin_events() -> bool:
	var gold_mark := _score_with_run([_make_roll(0, 0, 1, FaceState.ORN_NONE, FaceState.MARK_GOLD, DieState.BODY_MERCHANT)])
	var no_gold := _score_with_run([_make_roll(0, 0, 1, FaceState.ORN_NONE, FaceState.MARK_NONE, DieState.BODY_MERCHANT)])
	var selected := _make_roll(0, 0, 1)
	var gold_orn := _make_roll(1, 0, 5, FaceState.ORN_GOLD, FaceState.MARK_NONE, DieState.BODY_MERCHANT, false)
	var ornament_result := _score_with_run([selected], [selected, gold_orn])
	var passed := gold_mark.coins_delta == 2 and no_gold.coins_delta == 0 and ornament_result.coins_delta == 4
	passed = passed and _logs_contain(gold_mark, [&"LOG.BODY_MERCHANT"])
	return _check("body_merchant only adds +1 to existing gold mark or gold ornament coin events", passed)


func _check_whole_die_catalog_and_migration() -> bool:
	var defs := WholeDieServiceCatalog.get_all_defs()
	var ids: Array[StringName] = []
	var passed := defs.size() == 5
	for def in defs:
		passed = passed and def != null
		passed = passed and def.is_formal()
		passed = passed and def.requires_confirmation
		passed = passed and def.reserved_drop_pool == &"TBD"
		passed = passed and def.reserved_drop_weight == &"TBD"
		ids.append(def.service_id)
	passed = passed and ids.has(WholeDieServiceCatalog.DIE_CONVERT_D6)
	passed = passed and WholeDieServiceMigration.migrate_legacy_service_id(&"reward_new_d4") == WholeDieServiceCatalog.DIE_CONVERT_D4
	passed = passed and WholeDieServiceMigration.migrate_legacy_service_id(&"reward_distribution") == &""
	return _check("whole-die catalog has formal services and legacy migration", passed)


func _check_convert_d4() -> bool:
	var die := _make_die(&"d8", 8, DieState.BODY_STANDARD)
	die.faces[4].pip = 7
	die.faces[4].ornament_id = FaceState.ORN_HOLO
	die.faces[4].mark_id = FaceState.MARK_RED
	var run_state := _make_run_with_dice([die])
	var result := WholeDieService.new().convert_die_to_d4(run_state, 0, [0, 1, 4, 7])
	var converted := run_state.dice[0]
	var passed := bool(result.get("success", false))
	passed = passed and converted.face_count == 4 and converted.faces.size() == 4
	passed = passed and converted.faces[2].pip == 4
	passed = passed and converted.faces[2].ornament_id == FaceState.ORN_HOLO
	passed = passed and converted.faces[2].mark_id == FaceState.MARK_RED
	return _check("die_convert_d4 keeps four faces and clamps pips above 4 to 4", passed)


func _check_convert_d6() -> bool:
	var d4 := _make_die(&"d4", 4, DieState.BODY_STANDARD)
	var d8 := _make_die(&"d8", 8, DieState.BODY_STANDARD)
	d8.faces[6].pip = 7
	d8.faces[7].pip = 8
	var run_state := _make_run_with_dice([d4, d8])
	var service := WholeDieService.new()
	service.rng.seed = 606
	var d4_result := service.convert_die_to_d6(run_state, 0)
	var d8_result := service.convert_die_to_d6(run_state, 1, [0, 1, 2, 3, 6, 7])
	var passed := bool(d4_result.get("success", false)) and bool(d8_result.get("success", false))
	passed = passed and run_state.dice[0].face_count == 6 and run_state.dice[0].faces.size() == 6
	passed = passed and run_state.dice[0].faces[4].ornament_id == FaceState.ORN_NONE and run_state.dice[0].faces[4].mark_id == FaceState.MARK_NONE
	passed = passed and run_state.dice[1].face_count == 6 and run_state.dice[1].faces[4].pip == 6 and run_state.dice[1].faces[5].pip == 6
	passed = passed and not service.can_use_service(run_state, WholeDieServiceCatalog.DIE_CONVERT_D6, {"die_index": 0})
	return _check("die_convert_d6 works from D4/D8 and clamps D8 pips 7/8 to 6", passed)


func _check_convert_d8() -> bool:
	var d4 := _make_die(&"d4", 4, DieState.BODY_STANDARD)
	var d6 := _make_die(&"d6", 6, DieState.BODY_STANDARD)
	var run_state := _make_run_with_dice([d4, d6])
	var service := WholeDieService.new()
	service.rng.seed = 808
	var d4_result := service.convert_die_to_d8(run_state, 0)
	var d6_result := service.convert_die_to_d8(run_state, 1)
	var passed := bool(d4_result.get("success", false)) and bool(d6_result.get("success", false))
	passed = passed and run_state.dice[0].face_count == 8 and run_state.dice[0].faces.size() == 8
	passed = passed and run_state.dice[1].face_count == 8 and run_state.dice[1].faces.size() == 8
	return _check("die_convert_d8 fills dice to eight faces", passed)


func _check_change_body_keeps_faces() -> bool:
	var die := _make_die(&"body_change", 6, DieState.BODY_STANDARD)
	die.faces[0].pip = 6
	die.faces[0].ornament_id = FaceState.ORN_POLY
	die.faces[0].mark_id = FaceState.MARK_BLUE
	var before := _face_signature(die)
	var run_state := _make_run_with_dice([die])
	var service := WholeDieService.new()
	var result := service.change_body(run_state, 0, DieState.BODY_BIASED, 3)
	var passed := bool(result.get("success", false))
	passed = passed and run_state.dice[0].body_id == DieState.BODY_BIASED
	passed = passed and _face_signature(run_state.dice[0]) == before
	passed = passed and run_state.dice[0].face_weights == [1, 1, 1, 2, 1, 1]
	return _check("die_change_body keeps face_count and every FaceState slot", passed)


func _check_full_reforge_keeps_one_face() -> bool:
	var die := _make_die(&"reforge", 6, DieState.BODY_BIASED)
	die.faces[2].pip = 6
	die.faces[2].ornament_id = FaceState.ORN_BURST
	die.faces[2].mark_id = FaceState.MARK_RED
	var kept_signature := "%d/%s/%s" % [die.faces[2].pip, str(die.faces[2].ornament_id), str(die.faces[2].mark_id)]
	var run_state := _make_run_with_dice([die])
	var service := WholeDieService.new()
	service.rng.seed = 909
	var result := service.full_reforge(run_state, 0, 2, 0)
	var converted := run_state.dice[0]
	var passed := bool(result.get("success", false))
	passed = passed and converted.face_count == 6 and converted.faces.size() == 6
	passed = passed and "%d/%s/%s" % [converted.faces[2].pip, str(converted.faces[2].ornament_id), str(converted.faces[2].mark_id)] == kept_signature
	for face_index in range(converted.faces.size()):
		if face_index == 2:
			continue
		passed = passed and converted.faces[face_index].ornament_id == FaceState.ORN_NONE
		passed = passed and converted.faces[face_index].mark_id == FaceState.MARK_NONE
	passed = passed and converted.face_weights == [2, 1, 1, 1, 1, 1]
	return _check("die_full_reforge keeps one chosen face and resets all others", passed)


func _check_text_and_config_constraints() -> bool:
	var body_catalog := FileAccess.get_file_as_string("res://scripts/rules/forge/DieBodyCatalog.gd")
	var service_catalog := FileAccess.get_file_as_string("res://scripts/rules/forge/WholeDieServiceCatalog.gd")
	var service_source := FileAccess.get_file_as_string("res://scripts/rules/forge/WholeDieService.gd")
	var effect_source := FileAccess.get_file_as_string("res://scripts/rules/scoring/EffectResolver.gd")
	var die := _make_die(&"display", 8, DieState.BODY_MERCHANT)
	var summary := DisplayNames.die_summary(die)
	var passed := true
	for text in [body_catalog, service_catalog, service_source, summary]:
		passed = passed and not text.contains("distribution_id")
		passed = passed and not text.contains("distribution")
		passed = passed and not text.contains("骰子等级")
		passed = passed and not text.contains("骰面等级")
	passed = passed and body_catalog.contains("每回合") and body_catalog.contains("本回合")
	passed = passed and not body_catalog.contains("每手") and not body_catalog.contains("本手")
	passed = passed and not effect_source.contains("2.25")
	passed = passed and summary.contains("面数：D8") and summary.contains("骰胚：商人骰胚")
	return _check("new body/service data and UI text avoid distribution, die/face level, old turn terms, and decimal glass config", passed)


func _score(selected: Array, all_rolls: Array = []) -> ScoreResult:
	var context := ScoreContext.new()
	context.selected_faces = _to_roll_array(selected)
	context.all_rolled_faces = context.selected_faces if all_rolls.is_empty() else _to_roll_array(all_rolls)
	context.rng = FixedRng.new([0.99, 0.99, 0.99, 0.99])
	return ScoreEngine.new().score(context)


func _score_with_run(selected: Array, all_rolls: Array = []) -> ScoreResult:
	var context := ScoreContext.new()
	context.selected_faces = _to_roll_array(selected)
	context.all_rolled_faces = context.selected_faces if all_rolls.is_empty() else _to_roll_array(all_rolls)
	context.run_state = RunState.new()
	context.run_state.setup_new_run()
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
	ornament_id: StringName = FaceState.ORN_NONE,
	mark_id: StringName = FaceState.MARK_NONE,
	body_id: StringName = DieState.BODY_STANDARD,
	selected: bool = true
) -> RolledFace:
	var die := _make_die(StringName("die_%d" % [die_index]), 6, body_id)
	die.faces[face_index].pip = pip
	die.faces[face_index].ornament_id = ornament_id
	die.faces[face_index].mark_id = mark_id
	return _roll_from_die(die, die_index, face_index, selected)


func _roll_from_die(die: DieState, die_index: int, face_index: int, selected: bool = true) -> RolledFace:
	var roll := RolledFace.new()
	roll.set_roll(die_index, face_index, die.faces[face_index], die)
	roll.selected = selected
	return roll


func _make_die(id: StringName, face_count: int, body_id: StringName) -> DieState:
	var die := DieState.new()
	die.id = id
	die.die_id = id
	die.face_count = face_count
	die.body_id = DieState.normalize_body_id(body_id)
	for pip in range(1, face_count + 1):
		die.faces.append(FaceState.new(pip))
		die.face_weights.append(1)
	return die


func _make_run_with_dice(dice: Array) -> RunState:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.dice.clear()
	for die in dice:
		if die is DieState:
			run_state.dice.append(die)
	return run_state


func _face_signature(die: DieState) -> String:
	var parts := PackedStringArray()
	for face in die.faces:
		parts.append("%d/%s/%s" % [face.pip, str(face.ornament_id), str(face.mark_id)])
	return "|".join(parts)


func _logs_contain(result: ScoreResult, keys: Array) -> bool:
	for key in keys:
		var found := false
		for entry in result.logs:
			if entry.key == key:
				found = true
				break
		if not found:
			return false
	return true


func _log_count(result: ScoreResult, key: StringName) -> int:
	var count := 0
	for entry in result.logs:
		if entry.key == key:
			count += 1
	return count


class FixedRng:
	extends RefCounted

	var values: Array = []

	func _init(new_values: Array) -> void:
		values = new_values.duplicate()

	func randf() -> float:
		if values.is_empty():
			return 0.99
		return float(values.pop_front())


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
