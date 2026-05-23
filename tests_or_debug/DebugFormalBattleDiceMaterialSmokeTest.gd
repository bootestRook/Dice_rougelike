extends SceneTree
class_name DebugFormalBattleDiceMaterialSmokeTest


const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")

const EXPECTED_MATERIAL_ID := GmDiceDefinition.MATERIAL_REPRO_LAPIS
const EXPECTED_MATERIAL_PATH := "res://assets/materials/dice/repro_lapis_dice.tres"
const EXPECTED_SHADER_PATH := "res://assets/shaders/dice/repro_glow_dice.gdshader"


func _init() -> void:
	print("--- DebugFormalBattleDiceMaterialSmokeTest: start ---")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	var scene := load("res://scenes/battle/components/BattleDiceStage3D.tscn") as PackedScene
	var all_passed := _check("formal 3D dice stage scene loads", scene != null)
	if scene == null:
		_finish(all_passed)
		return

	var stage := scene.instantiate() as Control
	root.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame

	var state := _make_state()
	stage.call("render", state)
	await process_frame
	await process_frame
	await process_frame

	var battle_mgr = stage.get("battle_mgr")
	all_passed = _check("formal 3D dice manager exists", battle_mgr != null) and all_passed
	var snapshot: Dictionary = battle_mgr.get_snapshot() if battle_mgr != null else {}
	var dice_rows: Array = snapshot.get("dice", [])
	all_passed = _check("formal stage creates six dice", dice_rows.size() == 6) and all_passed
	for index in range(dice_rows.size()):
		var row: Dictionary = dice_rows[index] if dice_rows[index] is Dictionary else {}
		all_passed = _check("die %d uses qingjin material id" % [index + 1], StringName(str(row.get("material_id", ""))) == EXPECTED_MATERIAL_ID) and all_passed
		all_passed = _check("die %d writes Chinese qingjin name" % [index + 1], str(row.get("material_name", "")) == "青金骰胚") and all_passed
		all_passed = _check("die %d uses qingjin material resource" % [index + 1], str(row.get("body_material_source_path", "")) == EXPECTED_MATERIAL_PATH) and all_passed
		all_passed = _check("die %d uses repro shader" % [index + 1], str(row.get("body_material_shader_path", "")) == EXPECTED_SHADER_PATH) and all_passed

	_finish(all_passed)


func _make_state() -> BattleHudState:
	var state := BattleHudState.new()
	state.dice_results = []
	for die_index in range(6):
		var die := DieState.create_normal_d6(StringName("formal_material_d6_%d" % [die_index + 1]))
		var die_data := DieViewData.new()
		die_data.setup_from_die(die, die_index)
		die_data.current_face_index = die_index
		die_data.current_face = die_data.faces[die_index]
		state.dice_results.append(die_data)
	return state


func _finish(all_passed: bool) -> void:
	print("PASS: DebugFormalBattleDiceMaterialSmokeTest" if all_passed else "FAIL: DebugFormalBattleDiceMaterialSmokeTest")
	print("--- DebugFormalBattleDiceMaterialSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
