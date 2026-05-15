extends SceneTree
class_name DebugForgeRewardSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const ForgeService = preload("res://scripts/rules/forge/ForgeService.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


func _init() -> void:
	print("--- DebugForgeRewardSmokeTest: start ---")

	var all_passed := true
	var run_state := RunState.new()
	run_state.setup_new_run()
	all_passed = _check("setup_new_run creates 6 dice", run_state.dice.size() == 6) and all_passed
	all_passed = _check("each starting die has 6 faces", _all_dice_have_six_faces(run_state)) and all_passed

	var reward_generator := RewardGenerator.new()
	reward_generator.rng.seed = 24680
	var choices := reward_generator.generate_forge_choices(3)
	all_passed = _check("generate_forge_choices returns 3 rewards", choices.size() == 3) and all_passed
	all_passed = _check("generated rewards are unique", _choices_are_unique(choices)) and all_passed

	var full_pool := reward_generator.generate_forge_choices(99)
	var pip_6 := _find_piece_by_id(full_pool, &"pip_6")
	all_passed = _check("pip_6 forge piece exists", pip_6 != null) and all_passed

	var forge_service := ForgeService.new()
	if pip_6 != null:
		forge_service.apply_piece(pip_6, run_state.dice[0], 0)
	all_passed = _check("set_pip 6 changes dice[0].faces[0]", run_state.dice[0].faces[0].pip == 6) and all_passed

	var red_6 := _find_piece_by_id(full_pool, &"red_6")
	if red_6 == null:
		red_6 = _make_red_6_piece()
	all_passed = _check("red_6 forge piece exists or was constructed", red_6 != null) and all_passed

	forge_service.apply_piece(red_6, run_state.dice[1], 1)
	var red_face_ok := run_state.dice[1].faces[1].pip == 6 and run_state.dice[1].faces[1].mark_id == &"red"
	all_passed = _check("red_6 sets pip and mark", red_face_ok) and all_passed

	var controller := BattleController.new()
	controller.roll_service.rng.seed = 13579
	controller.start_battle(null, run_state)
	var uses_run_dice := controller.dice.size() == run_state.dice.size() and controller.dice[0] == run_state.dice[0]
	var keeps_forge_changes := controller.dice[0].faces[0].pip == 6 and controller.dice[1].faces[1].mark_id == &"red"
	all_passed = _check("BattleController uses RunState.dice objects", uses_run_dice) and all_passed
	all_passed = _check("BattleController sees forged faces", keeps_forge_changes) and all_passed

	print("Current run dice after forge:")
	_print_run_dice(run_state)

	controller.free()
	print("--- DebugForgeRewardSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _all_dice_have_six_faces(run_state: RunState) -> bool:
	for die in run_state.dice:
		if die.faces.size() != 6:
			return false
	return true


func _choices_are_unique(choices: Array[ForgePieceDef]) -> bool:
	var ids: Array[StringName] = []
	for choice in choices:
		if choice == null or ids.has(choice.id):
			return false
		ids.append(choice.id)
	return true


func _find_piece_by_id(choices: Array[ForgePieceDef], id: StringName) -> ForgePieceDef:
	for choice in choices:
		if choice != null and choice.id == id:
			return choice
	return null


func _make_red_6_piece() -> ForgePieceDef:
	var piece := ForgePieceDef.new()
	piece.id = &"red_6_manual"
	piece.name_key = &"FORGE_PART.RED_6.NAME"
	piece.desc_key = &"FORGE_PART.RED_6.DESC"
	piece.rarity_key = &"RARITY.COMMON"
	piece.operations.append(_make_int_op(ForgeOperationDef.OP_SET_PIP, 6))
	piece.operations.append(_make_id_op(ForgeOperationDef.OP_SET_MARK, &"red"))
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


func _print_run_dice(run_state: RunState) -> void:
	for die_index in range(run_state.dice.size()):
		print("Die %d: %s" % [die_index + 1, _describe_die(run_state.dice[die_index])])


func _describe_die(die) -> String:
	var face_texts := PackedStringArray()
	for face_index in range(die.faces.size()):
		var face = die.faces[face_index]
		face_texts.append("#%d pip=%d material=%s mark=%s rune=%s level=%d" % [
			face_index,
			face.pip,
			str(face.material_id),
			str(face.mark_id),
			str(face.rune_id),
			face.level,
		])
	return "[" + ", ".join(face_texts) + "]"


func _check(label: String, passed: bool) -> bool:
	print("%s: %s" % [label, str(passed)])
	return passed
