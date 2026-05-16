extends SceneTree
class_name DebugForgeRewardSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const ForgeService = preload("res://scripts/rules/forge/ForgeService.gd")
const ForgeInstallScreen = preload("res://scripts/ui/forge/ForgeInstallScreen.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


func _init() -> void:
	print("--- DebugForgeRewardSmokeTest: start ---")

	var all_passed := true
	var run_state := RunState.new()
	run_state.setup_new_run()
	all_passed = _check("setup_new_run creates 6 dice", run_state.dice.size() == 6) and all_passed
	all_passed = _check("each starting die has 6 faces", _all_dice_have_six_faces(run_state)) and all_passed
	all_passed = _check("each starting die is standard D6", _all_dice_are_standard_d6(run_state)) and all_passed

	var reward_generator := RewardGenerator.new()
	reward_generator.rng.seed = 24680
	var choices := reward_generator.generate_forge_choices(3)
	all_passed = _check("generate_forge_choices returns 3 rewards", choices.size() == 3) and all_passed
	all_passed = _check("generated rewards are unique", _choices_are_unique(choices)) and all_passed
	all_passed = _check("generated rewards contain no legacy ids", not _has_legacy_reward(choices)) and all_passed

	var full_pool := reward_generator.generate_forge_choices(99)
	var pip_6 := _find_piece_by_id(full_pool, &"pip_6")
	var red_6 := _find_piece_by_id(full_pool, &"red_6")
	var burst_1 := _find_piece_by_id(full_pool, &"burst_1")
	all_passed = _check("pip_6 forge piece exists", pip_6 != null) and all_passed
	all_passed = _check("red_6 forge piece exists", red_6 != null) and all_passed
	all_passed = _check("burst_1 forge piece exists", burst_1 != null) and all_passed

	var forge_service := ForgeService.new()
	if pip_6 != null:
		forge_service.apply_piece(pip_6, run_state.dice[0], 0)
	all_passed = _check("set_pip 6 changes dice[0].faces[0]", run_state.dice[0].faces[0].pip == 6) and all_passed
	all_passed = _check("visible forged face is detected", forge_service.face_has_forge_effect(run_state.dice[0].faces[0], 1)) and all_passed

	if red_6 != null:
		forge_service.apply_piece(red_6, run_state.dice[1], 1)
	var red_face_ok := run_state.dice[1].faces[1].pip == 6 and run_state.dice[1].faces[1].mark_id == &"red"
	all_passed = _check("red_6 sets pip and mark", red_face_ok) and all_passed

	if burst_1 != null:
		forge_service.apply_piece(burst_1, run_state.dice[2], 2)
	var burst_face_ok := run_state.dice[2].faces[2].pip == 1 and run_state.dice[2].faces[2].ornament_id == &"orn_burst"
	all_passed = _check("burst_1 sets pip and ornament", burst_face_ok) and all_passed

	var slot_die := run_state.dice[3]
	forge_service.apply_piece(_make_piece(&"slot_pip_6", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 6)]), slot_die, 0)
	forge_service.apply_piece(_make_piece(&"slot_pip_3", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 3)]), slot_die, 0)
	all_passed = _check("pip slot replaces previous pip", slot_die.faces[0].pip == 3) and all_passed
	forge_service.apply_piece(_make_piece(&"slot_burst", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"burst")]), slot_die, 0)
	forge_service.apply_piece(_make_piece(&"slot_stay", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"stay")]), slot_die, 0)
	all_passed = _check("ornament slot replaces previous ornament", slot_die.faces[0].ornament_id == &"orn_stay") and all_passed
	forge_service.apply_piece(_make_piece(&"slot_legacy_glass", [_make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"glass")]), slot_die, 0)
	all_passed = _check("legacy set_material maps to burst ornament", slot_die.faces[0].ornament_id == &"orn_burst") and all_passed
	forge_service.apply_piece(_make_piece(&"slot_red", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"red")]), slot_die, 0)
	forge_service.apply_piece(_make_piece(&"slot_blue", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"blue")]), slot_die, 0)
	all_passed = _check("mark slot replaces previous mark", slot_die.faces[0].mark_id == &"blue") and all_passed

	var disabled_face = slot_die.faces[0]
	disabled_face.rune_id = &"six"
	disabled_face.level = 2
	forge_service.apply_piece(_make_piece(&"slot_disabled_rune", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"even")]), slot_die, 0)
	forge_service.apply_piece(_make_piece(&"slot_disabled_upgrade", [_make_int_op(ForgeOperationDef.OP_UPGRADE, 1)]), slot_die, 0)
	all_passed = _check("deprecated rune and upgrade operations do not mutate slots", disabled_face.rune_id == &"six" and disabled_face.level == 2) and all_passed

	if pip_6 != null:
		forge_service.apply_piece(pip_6, run_state.dice[4], 5)
		run_state.record_installed_piece(pip_6, 4, 5)

	var forge_screen := ForgeInstallScreen.new()
	forge_screen.setup(null, run_state, red_6)
	all_passed = _check("normal face does not ask replace confirmation", not forge_screen._needs_replace_confirmation(5, 0)) and all_passed
	all_passed = _check("visible forged face asks replace confirmation", forge_screen._needs_replace_confirmation(0, 0)) and all_passed
	all_passed = _check("history-only forged face asks replace confirmation", forge_screen._needs_replace_confirmation(4, 5)) and all_passed
	forge_screen.free()

	var controller := BattleController.new()
	controller.roll_service.rng.seed = 13579
	controller.start_battle(null, run_state)
	var uses_run_dice := controller.dice.size() == run_state.dice.size() and controller.dice[0] == run_state.dice[0]
	var keeps_forge_changes := controller.dice[0].faces[0].pip == 6 and controller.dice[1].faces[1].mark_id == &"red"
	all_passed = _check("BattleController uses RunState.dice objects", uses_run_dice) and all_passed
	all_passed = _check("BattleController sees forged faces", keeps_forge_changes) and all_passed

	controller.free()
	print("PASS: DebugForgeRewardSmokeTest" if all_passed else "FAIL: DebugForgeRewardSmokeTest")
	print("--- DebugForgeRewardSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _all_dice_have_six_faces(run_state: RunState) -> bool:
	for die in run_state.dice:
		if die.faces.size() != 6:
			return false
	return true


func _all_dice_are_standard_d6(run_state: RunState) -> bool:
	for die in run_state.dice:
		if die.face_count != 6 or die.body_id != &"standard":
			return false
	return true


func _choices_are_unique(choices: Array[ForgePieceDef]) -> bool:
	var ids: Array[StringName] = []
	for choice in choices:
		if choice == null or ids.has(choice.id):
			return false
		ids.append(choice.id)
	return true


func _has_legacy_reward(choices: Array[ForgePieceDef]) -> bool:
	for choice in choices:
		if choice != null and [&"rune_six", &"rune_straight", &"rune_pair", &"rune_odd", &"rune_even", &"upgrade_1", &"material_glass", &"material_steel", &"glass_1"].has(choice.id):
			return true
	return false


func _find_piece_by_id(choices: Array[ForgePieceDef], id: StringName) -> ForgePieceDef:
	for choice in choices:
		if choice != null and choice.id == id:
			return choice
	return null


func _make_piece(id: StringName, operations: Array) -> ForgePieceDef:
	var piece := ForgePieceDef.new()
	piece.id = id
	for operation in operations:
		if operation is ForgeOperationDef:
			piece.operations.append(operation)
	return piece


func _make_int_op(op: StringName, value_int: int) -> ForgeOperationDef:
	var operation := ForgeOperationDef.new()
	operation.op = op
	operation.value_int = value_int
	return operation


func _make_id_op(op: StringName, value_id: StringName) -> ForgeOperationDef:
	var operation := ForgeOperationDef.new()
	operation.op = op
	operation.value_id = value_id
	return operation


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
