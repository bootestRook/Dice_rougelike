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
const EXPECTED_VISUAL_LAYER_ROLES := [
	"body",
	"face_marker",
	"face_albedo_texture",
	"state_overlay",
	"contact_shadow",
]


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
		ok = _check("visual repro shader tones down wireframe emission", code.contains("face_light_rolloff") and code.contains("fresnel_strength * 0.28")) and ok
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
	ok = _check("gm throw camera keeps default tuning", _camera_keeps_default_tuning(snapshot)) and ok
	var dice_rows: Array = snapshot.get("dice", [])
	ok = _check("default visual repro screen has six dice", dice_rows.size() == EXPECTED_DEFAULT_MATERIAL_IDS.size()) and ok
	for index in range(mini(dice_rows.size(), EXPECTED_DEFAULT_MATERIAL_IDS.size())):
		var row: Dictionary = dice_rows[index] if dice_rows[index] is Dictionary else {}
		var expected_id := str(EXPECTED_DEFAULT_MATERIAL_IDS[index])
		var expected_material_path := str(REPRO_MATERIAL_PATHS[expected_id])
		ok = _check("die %d uses %s material id" % [index + 1, expected_id], row != null and str(row.get("material_id", "")) == expected_id) and ok
		ok = _check("die %d keeps repro material source" % [index + 1], row != null and str(row.get("body_material_source_path", "")) == expected_material_path) and ok
		ok = _check("die %d uses repro shader" % [index + 1], row != null and str(row.get("body_material_shader_path", "")) == REPRO_SHADER_PATH) and ok
		ok = _check("die %d exposes shader face detail" % [index + 1], row != null and float(row.get("body_material_face_detail_strength", 0.0)) > 0.0) and ok
		ok = _check("die %d feeds face albedo texture to shader" % [index + 1], row != null and float(row.get("body_material_face_layer_enabled", 0.0)) > 0.5) and ok
		ok = _check("die %d outputs six-face albedo atlas" % [index + 1], row != null and bool(row.get("face_albedo_texture_exists", false)) and row.get("face_albedo_texture_size") == Vector2i(384, 256)) and ok
		ok = _check("die %d uses rounded d6 mesh" % [index + 1], row != null and str(row.get("body_mesh_resource_path", "")) == ROUNDED_MESH_PATH) and ok
		var layer_roles: Dictionary = row.get("visual_layer_roles", {}) if row != null else {}
		for role in EXPECTED_VISUAL_LAYER_ROLES:
			ok = _check("die %d exposes %s visual layer" % [index + 1, role], bool(layer_roles.get(role, false))) and ok
		ok = _check("die %d matches material inspector without edge/rim frame layer" % [index + 1], row != null and not bool(row.get("edge_rim_layer_exists", true)) and int(row.get("edge_rim_bar_count", -1)) == 0) and ok
		ok = _check("die %d keeps state outside body material" % [index + 1], row != null and bool(row.get("state_overlay_layer_exists", false)) and bool(row.get("selection_frame_visible", false)) == bool(row.get("selected", false))) and ok
		ok = _check("die %d matches material inspector without square face texture panels" % [index + 1], row != null and not bool(row.get("face_texture_layer_exists", true)) and int(row.get("face_texture_panel_count", -1)) == 0) and ok
		ok = _check("die %d no longer owns floating face labels" % [index + 1], row != null and int(row.get("face_marker_label_count", -1)) == 0 and int(row.get("face_label_count", -1)) == 0) and ok
		ok = _check("die %d has no visible face Label3D numbers" % [index + 1], row != null and not bool(row.get("face_label_nodes_visible", true))) and ok
		ok = _check("die %d records independent face layer data" % [index + 1], _has_six_face_layer_rows(row)) and ok
	screen.queue_free()
	return ok


func _camera_keeps_default_tuning(snapshot: Dictionary) -> bool:
	var fov := float(snapshot.get("camera_fov", 0.0))
	var position: Vector3 = snapshot.get("camera_position", Vector3.ZERO)
	var look_at: Vector3 = snapshot.get("camera_look_at", Vector3.ZERO)
	return is_equal_approx(fov, 38.0) \
		and position.distance_to(Vector3(0.0, 18.5, 1.0)) <= 0.001 \
		and look_at.distance_to(Vector3(0.0, 0.72, -0.04)) <= 0.001


func _has_six_face_layer_rows(row: Dictionary) -> bool:
	var system := row.get("face_layer_system", {}) as Dictionary
	var faces := system.get("faces", []) as Array
	if faces.size() != 6:
		return false
	for face_value in faces:
		var face := face_value as Dictionary
		if face.is_empty():
			return false
		var layers := face.get("layers", {}) as Dictionary
		var number_layer := layers.get("number_layer", {}) as Dictionary
		if not bool(number_layer.get("has_texture", false)):
			return false
	return true


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
