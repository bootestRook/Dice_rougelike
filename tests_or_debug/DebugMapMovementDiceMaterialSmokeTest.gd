extends SceneTree
class_name DebugMapMovementDiceMaterialSmokeTest


const DieState = preload("res://scripts/core/dice/DieState.gd")
const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const MapMovementDicePhysicsView = preload("res://scripts/ui/map/components/MapMovementDicePhysicsView.gd")

const EXPECTED_MATERIAL_ID := GmDiceDefinition.MATERIAL_REPRO_LAPIS
const EXPECTED_MATERIAL_PATH := "res://assets/materials/dice/repro_lapis_dice.tres"


func _init() -> void:
	print("--- DebugMapMovementDiceMaterialSmokeTest: start ---")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	var view := MapMovementDicePhysicsView.new()
	view.name = "MapMovementDiceMaterialTestView"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(view)
	await process_frame
	await process_frame

	var dice := [
		DieState.create_normal_d6(&"map_material_d6_1"),
		DieState.create_normal_d6(&"map_material_d6_2"),
	]
	view.set_formal_dice(dice)
	await process_frame
	await process_frame

	var snapshot: Dictionary = view.automation_get_snapshot()
	var gm_snapshot: Dictionary = snapshot.get("gm_snapshot", {})
	var dice_rows: Array = gm_snapshot.get("dice", [])
	var all_passed := true
	all_passed = _check("map movement view uses gm dice", bool(snapshot.get("uses_gm_dice_view", false))) and all_passed
	all_passed = _check("map movement view creates two dice", dice_rows.size() == 2) and all_passed
	for index in range(dice_rows.size()):
		var row: Dictionary = dice_rows[index] if dice_rows[index] is Dictionary else {}
		all_passed = _check("map die %d uses qingjin material id" % [index + 1], StringName(str(row.get("material_id", ""))) == EXPECTED_MATERIAL_ID) and all_passed
		all_passed = _check("map die %d uses qingjin material resource" % [index + 1], str(row.get("body_material_source_path", "")) == EXPECTED_MATERIAL_PATH) and all_passed
	view.queue_free()

	print("PASS: DebugMapMovementDiceMaterialSmokeTest" if all_passed else "FAIL: DebugMapMovementDiceMaterialSmokeTest")
	print("--- DebugMapMovementDiceMaterialSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
