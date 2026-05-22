extends SceneTree
class_name DebugGmDiceVisualTextureSmokeTest


const REPRO_SHADER_PATH := "res://assets/shaders/dice/repro_glow_dice.gdshader"
const ROUNDED_MESH_PATH := "res://assets/models/dice/rounded_d6_mesh.tres"
const EXPECTED_DEFAULT_MATERIAL_IDS := [
	"repro_blue",
	"repro_purple",
	"repro_cyan",
	"repro_purple",
	"repro_gold",
	"repro_silverwhite",
]
const REPRO_MATERIAL_PATHS := {
	"repro_blue": "res://assets/materials/dice/repro_blue_dice.tres",
	"repro_purple": "res://assets/materials/dice/repro_purple_dice.tres",
	"repro_cyan": "res://assets/materials/dice/repro_cyan_dice.tres",
	"repro_gold": "res://assets/materials/dice/repro_gold_dice.tres",
	"repro_silverwhite": "res://assets/materials/dice/repro_silverwhite_dice.tres",
}


func _init() -> void:
	print("--- DebugGmDiceVisualTextureSmokeTest: start ---")
	var all_passed := true
	all_passed = _check_repro_shader() and all_passed
	all_passed = _check_repro_materials() and all_passed
	var screen_passed := await _check_default_screen_dice()
	all_passed = screen_passed and all_passed
	print("PASS: DebugGmDiceVisualTextureSmokeTest" if all_passed else "FAIL: DebugGmDiceVisualTextureSmokeTest")
	print("--- DebugGmDiceVisualTextureSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_repro_shader() -> bool:
	var ok := true
	var shader := load(REPRO_SHADER_PATH) as Shader
	ok = _check("visual repro dice shader loads", shader != null) and ok
	if shader != null:
		var code := shader.code
		ok = _check("visual repro shader has atlas face detail", code.contains("face_uv") and code.contains("inset_line")) and ok
		ok = _check("visual repro shader has edge detail controls", code.contains("face_detail_strength") and code.contains("edge_line_strength")) and ok
	return ok


func _check_repro_materials() -> bool:
	var ok := true
	for material_id in REPRO_MATERIAL_PATHS.keys():
		var path := str(REPRO_MATERIAL_PATHS[material_id])
		var material := load(path) as ShaderMaterial
		ok = _check("%s material loads" % material_id, material != null) and ok
		if material == null:
			continue
		ok = _check("%s material uses visual shader" % material_id, material.shader != null and material.shader.resource_path == REPRO_SHADER_PATH) and ok
		ok = _check("%s material has face detail" % material_id, float(material.get_shader_parameter("face_detail_strength")) > 0.0) and ok
		ok = _check("%s material has edge line detail" % material_id, float(material.get_shader_parameter("edge_line_strength")) > 0.0) and ok
	return ok


func _check_default_screen_dice() -> bool:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	var scene := load("res://scenes/debug/GmPhysicsDiceTestScreen.tscn") as PackedScene
	var ok := _check("gm physics dice test scene loads", scene != null)
	if scene == null:
		return ok
	var screen := scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	await process_frame
	screen.call("automation_clear")
	screen.call("automation_set_dice_count", 6)
	await process_frame
	await process_frame
	var snapshot: Dictionary = screen.call("automation_get_snapshot")
	var dice_rows: Array = snapshot.get("dice", [])
	ok = _check("default visual repro screen has six dice", dice_rows.size() == EXPECTED_DEFAULT_MATERIAL_IDS.size()) and ok
	for index in range(mini(dice_rows.size(), EXPECTED_DEFAULT_MATERIAL_IDS.size())):
		var row: Dictionary = dice_rows[index] if dice_rows[index] is Dictionary else {}
		var expected_id := str(EXPECTED_DEFAULT_MATERIAL_IDS[index])
		var expected_material_path := str(REPRO_MATERIAL_PATHS[expected_id])
		ok = _check("die %d uses %s material id" % [index + 1, expected_id], row != null and str(row.get("material_id", "")) == expected_id) and ok
		ok = _check("die %d uses repro material resource" % [index + 1], row != null and str(row.get("body_material_resource_path", "")) == expected_material_path) and ok
		ok = _check("die %d uses repro shader" % [index + 1], row != null and str(row.get("body_material_shader_path", "")) == REPRO_SHADER_PATH) and ok
		ok = _check("die %d exposes shader face detail" % [index + 1], row != null and float(row.get("body_material_face_detail_strength", 0.0)) > 0.0) and ok
		ok = _check("die %d uses rounded d6 mesh" % [index + 1], row != null and str(row.get("body_mesh_resource_path", "")) == ROUNDED_MESH_PATH) and ok
		ok = _check("die %d has six centered face labels" % [index + 1], row != null and int(row.get("face_label_count", 0)) == 6 and bool(row.get("face_label_centered", false))) and ok
		ok = _check("die %d face labels are double-sided" % [index + 1], row != null and bool(row.get("face_label_double_sided", false))) and ok
		ok = _check("die %d face labels clear rounded mesh" % [index + 1], row != null and float(row.get("face_label_min_surface_offset", 0.0)) >= 0.030) and ok
	screen.queue_free()
	return ok


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
