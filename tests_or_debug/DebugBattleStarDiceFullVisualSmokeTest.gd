extends SceneTree
class_name DebugBattleStarDiceFullVisualSmokeTest


const DiceMaterialFactory := preload("res://scripts/ui/debug/star_dice_full/DiceMaterialFactory.gd")

const SCENE_PATH := "res://scenes/debug/battle_star_dice_full.tscn"
const EXTERNAL_ROUNDED_DICE_GLB_PATH := "res://assets/models/dice/rounded_dice_base.glb"
const MESH_PATH := "res://assets/models/dice/battle_star/rounded_dice_mesh.tres"
const MATERIAL_DIR := "res://assets/materials/dice/battle_star"
const SHADER_PATH := "res://assets/shaders/dice/battle_star_dice_full.gdshader"
const CAPTURE_RUNNER_PATH := "res://tests_or_debug/visual_acceptance/shader_light/tools/battle_star_dice_full_capture_runner.gd"
const ROUNDED_MESH_FACTORY_PATH := "res://scripts/ui/debug/RoundedDiceMeshFactory.gd"
const COLOR_EPS := 0.006
const STAR_GOLD_COLOR := Color(0.909804, 0.847059, 0.686275, 1.0)
const DIGIT_COLOR := Color(0.960784, 0.949020, 0.909804, 1.0)
const KEY_LIGHT_COLOR := Color(1.0, 0.949, 0.839, 1.0)
const FILL_LIGHT_COLOR := Color(0.722, 0.843, 1.0, 1.0)
const RIM_LIGHT_COLOR := Color(1.0, 0.973, 0.918, 1.0)


func _init() -> void:
	print("--- DebugBattleStarDiceFullVisualSmokeTest: start ---")
	var all_passed := true
	all_passed = _check("battle star dice full scene loads", load(SCENE_PATH) is PackedScene) and all_passed
	all_passed = _check("battle star dice shader loads", load(SHADER_PATH) is Shader) and all_passed
	all_passed = _check("capture runner script exists", FileAccess.file_exists(CAPTURE_RUNNER_PATH)) and all_passed
	all_passed = _check("capture runner script loads", load(CAPTURE_RUNNER_PATH) is Script) and all_passed
	all_passed = _check_rounded_model_source() and all_passed
	all_passed = _check_materials() and all_passed
	all_passed = _check_scene() and all_passed
	all_passed = _check_capture_runner_contract() and all_passed
	print("PASS: DebugBattleStarDiceFullVisualSmokeTest" if all_passed else "FAIL: DebugBattleStarDiceFullVisualSmokeTest")
	print("--- DebugBattleStarDiceFullVisualSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_rounded_model_source() -> bool:
	var ok := true
	if ResourceLoader.exists(EXTERNAL_ROUNDED_DICE_GLB_PATH):
		ok = _check("external rounded dice glb exists", true) and ok
		ok = _check("external rounded dice glb loads", load(EXTERNAL_ROUNDED_DICE_GLB_PATH) is PackedScene) and ok
		return ok
	ok = _check("external rounded dice glb missing, using RoundedDiceMeshFactory ArrayMesh fallback", FileAccess.file_exists(ROUNDED_MESH_FACTORY_PATH)) and ok
	return _check_mesh() and ok


func _check_mesh() -> bool:
	var ok := true
	var mesh := load(MESH_PATH) as ArrayMesh
	ok = _check("rounded dice mesh loads", mesh != null) and ok
	if mesh == null:
		return ok
	ok = _check("rounded dice mesh has one surface", mesh.get_surface_count() == 1) and ok
	var aabb := mesh.get_aabb()
	ok = _check("rounded dice mesh is centered", aabb.position.distance_to(Vector3(-0.5, -0.5, -0.5)) <= 0.002) and ok
	ok = _check("rounded dice mesh has unit bounds", aabb.size.distance_to(Vector3.ONE) <= 0.002) and ok
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	ok = _check("rounded dice mesh has dense geometry", vertices.size() >= 900 and indices.size() >= 3000) and ok
	ok = _check("rounded dice mesh has normals", normals.size() == vertices.size()) and ok
	ok = _check("rounded dice mesh has real bevel normals", _bevel_normal_count(normals) >= 240) and ok
	ok = _check("rounded dice mesh has continuous top-edge bevel normals", _top_edge_normal_bucket_count(normals) >= 4) and ok
	ok = _check("rounded dice mesh has rounded corner normals", _corner_normal_count(normals) >= 64) and ok
	ok = _check("rounded dice mesh has triangle indices", indices.size() > 0 and indices.size() % 3 == 0) and ok
	ok = _check("rounded dice vertex normals point away from center", _outward_vertex_normal_error_count(vertices, normals) == 0) and ok
	ok = _check("rounded dice triangle winding is Godot front-facing outside", _godot_front_face_winding_error_count(vertices, normals, indices) == 0) and ok
	ok = _check("rounded dice triangle winding matches exterior position", _position_front_face_winding_error_count(vertices, indices) == 0) and ok
	return ok


func _check_materials() -> bool:
	var ok := true
	for material_id in DiceMaterialFactory.MATERIAL_ORDER:
		var path := DiceMaterialFactory.material_path(MATERIAL_DIR, material_id)
		var material := load(path) as ShaderMaterial
		ok = _check("material %s loads as ShaderMaterial" % material_id, material != null) and ok
		if material == null:
			continue
		ok = _check("material %s has base albedo" % material_id, material.get_shader_parameter("base_albedo") is Color) and ok
		ok = _check("material %s has roughness" % material_id, float(material.get_shader_parameter("roughness_value")) > 0.0) and ok
		ok = _check("material %s has metallic" % material_id, float(material.get_shader_parameter("metallic_value")) >= 0.0) and ok
		ok = _check("material %s has emission color" % material_id, material.get_shader_parameter("emission_color") is Color) and ok
		ok = _check("material %s has emission energy" % material_id, float(material.get_shader_parameter("emission_energy")) > 0.0) and ok
		ok = _check("material %s has emission mask power" % material_id, float(material.get_shader_parameter("emission_mask_power")) > 0.0) and ok
		ok = _check("material %s has fake normal detail" % material_id, float(material.get_shader_parameter("fake_normal_strength")) > 0.0) and ok
		if material_id == "gold":
			ok = _check_color("star gold battle material is champagne gold", material.get_shader_parameter("base_albedo") as Color, STAR_GOLD_COLOR) and ok
			ok = _check_color("star gold battle digit emission is warm ivory", material.get_shader_parameter("emission_color") as Color, DIGIT_COLOR) and ok
			ok = _check("star gold battle material metallic is 0.96", is_equal_approx(float(material.get_shader_parameter("metallic_value")), 0.96)) and ok
			ok = _check("star gold battle material body roughness is 0.18", is_equal_approx(float(material.get_shader_parameter("roughness_value")), 0.18)) and ok
			ok = _check("star gold battle material digit energy is 0.5", is_equal_approx(float(material.get_shader_parameter("emission_energy")), 0.50)) and ok
	return ok


func _check_scene() -> bool:
	var ok := true
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		return false
	var root_node := packed.instantiate()
	ok = _check("scene has fixed Camera3D", _find_node(root_node, "Camera3D") is Camera3D) and ok
	ok = _check("scene has WorldEnvironment", _find_node(root_node, "WorldEnvironment") is WorldEnvironment) and ok
	ok = _check("scene has LightingRig", _find_node(root_node, "LightingRig") is Node3D) and ok
	ok = _check("scene has warm key light", _find_node(root_node, "WarmKeyLight") is DirectionalLight3D) and ok
	ok = _check("scene has blue fill light", _find_node(root_node, "BlueFillLight") is OmniLight3D) and ok
	ok = _check("scene has warm rim light", _find_node(root_node, "WarmRimLight") is OmniLight3D) and ok
	ok = _check("scene has dice emission helper root", _find_node(root_node, "DiceEmissionHelperLights") is Node3D) and ok
	ok = _check("scene has six dice helper lights", _count_nodes_with_prefix(root_node, "DiceEmissionHelper_") == 6) and ok
	ok = _check("scene has six fake contact shadows", _count_nodes_with_prefix(root_node, "FakeContactShadow_") == 6) and ok
	ok = _check("scene has six rounded dice", _count_nodes_with_prefix(root_node, "RoundedDice_") == 6) and ok
	ok = _check("scene has six rounded body mesh nodes", _count_nodes_with_name(root_node, "RoundedDiceMesh") == 6) and ok
	ok = _check("scene has six top glow digits", _count_nodes_with_name(root_node, "TopDigitGlow") == 6) and ok
	ok = _check("top digit decals stay centered above rounded top face", _top_digits_are_centered(root_node)) and ok
	ok = _check("scene has glowing panel borders", _count_nodes_with_prefix(root_node, "TopPanelGlowBorder") >= 24 and _count_nodes_with_prefix(root_node, "FrontPanelGlowBorder") >= 24) and ok
	ok = _check("scene has no Control UI nodes", _count_nodes_by_class(root_node, "Control") == 0) and ok
	ok = _check("scene has no physics body nodes", _count_nodes_by_class(root_node, "RigidBody3D") == 0 and _count_nodes_by_class(root_node, "StaticBody3D") == 0 and _count_nodes_by_class(root_node, "CollisionShape3D") == 0) and ok
	ok = _check("scene has no BoxMesh resources", _count_meshes_by_class(root_node, "BoxMesh") == 0) and ok
	ok = _check_material_quality_lighting(root_node) and ok
	ok = _check_body_meshes(root_node) and ok
	root_node.free()
	return ok


func _check_material_quality_lighting(root_node: Node) -> bool:
	var ok := true
	var key := _find_node(root_node, "WarmKeyLight") as Light3D
	var fill := _find_node(root_node, "BlueFillLight") as Light3D
	var rim := _find_node(root_node, "WarmRimLight") as Light3D
	var probe := _find_node(root_node, "DiceGlossReflectionProbe")
	var world_environment := _find_node(root_node, "WorldEnvironment") as WorldEnvironment
	ok = _check("scene reflection probe exists for metal evaluation", probe != null) and ok
	if probe != null:
		ok = _check("scene reflection probe intensity is boosted", float(probe.get("intensity")) >= 0.90) and ok
	ok = _check("scene key light color is warm", key != null and _color_close(key.light_color, KEY_LIGHT_COLOR)) and ok
	ok = _check("scene fill light color is cool blue", fill != null and _color_close(fill.light_color, FILL_LIGHT_COLOR)) and ok
	ok = _check("scene rim light color is warm ivory", rim != null and _color_close(rim.light_color, RIM_LIGHT_COLOR)) and ok
	if key != null and fill != null and rim != null:
		ok = _check("scene fill/key ratio is about 0.28", absf(fill.light_energy / key.light_energy - 0.28) <= 0.025) and ok
		ok = _check("scene rim/key ratio is about 0.20", absf(rim.light_energy / key.light_energy - 0.20) <= 0.025) and ok
	if world_environment != null and world_environment.environment != null:
		var background := world_environment.environment.background_color
		ok = _check("scene background is deep blue-gray, not pure black", background.r > 0.04 and background.r < 0.16 and background.b > background.r and background.b < 0.20) and ok
	return ok


func _check_body_meshes(root_node: Node) -> bool:
	var ok := true
	var bodies := []
	_collect_nodes_with_name(root_node, "RoundedDiceMesh", bodies)
	for body_value in bodies:
		var body := body_value as MeshInstance3D
		ok = _check("dice body uses rounded mesh resource", body != null and body.mesh != null and body.mesh.resource_path == MESH_PATH) and ok
		ok = _check("dice body is not BoxMesh", body != null and not (body.mesh is BoxMesh)) and ok
	return ok


func _check_capture_runner_contract() -> bool:
	var text := FileAccess.get_file_as_string(CAPTURE_RUNNER_PATH)
	var ok := true
	ok = _check("capture runner writes timestamped output", text.contains("run_id") and text.contains("git_hash")) and ok
	ok = _check("capture runner emits no_postprocess", text.contains("no_postprocess")) and ok
	ok = _check("capture runner emits postprocess_on", text.contains("postprocess_on")) and ok
	ok = _check("capture runner emits reference_compare", text.contains("reference_compare")) and ok
	ok = _check("capture runner saves under visual acceptance tmp_report", text.contains("tests_or_debug/tmp_report/visual_acceptance/shader_light")) and ok
	return ok


func _bevel_normal_count(normals: PackedVector3Array) -> int:
	var count := 0
	for normal in normals:
		var axes := 0
		if absf(normal.x) > 0.08:
			axes += 1
		if absf(normal.y) > 0.08:
			axes += 1
		if absf(normal.z) > 0.08:
			axes += 1
		if axes >= 2:
			count += 1
	return count


func _top_edge_normal_bucket_count(normals: PackedVector3Array) -> int:
	var buckets := {}
	for normal in normals:
		var horizontal := maxf(absf(normal.x), absf(normal.z))
		if normal.y > 0.08 and normal.y < 0.98 and horizontal > 0.08:
			buckets[roundi(normal.y * 100.0)] = true
	return buckets.size()


func _corner_normal_count(normals: PackedVector3Array) -> int:
	var count := 0
	for normal in normals:
		if absf(normal.x) > 0.08 and absf(normal.y) > 0.08 and absf(normal.z) > 0.08:
			count += 1
	return count


func _godot_front_face_winding_error_count(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> int:
	var count := 0
	for i in range(0, indices.size(), 3):
		var ia := int(indices[i])
		var ib := int(indices[i + 1])
		var ic := int(indices[i + 2])
		var face_normal := (vertices[ib] - vertices[ia]).cross(vertices[ic] - vertices[ia])
		if face_normal.length_squared() <= 0.00000001:
			continue
		var target := (normals[ia] + normals[ib] + normals[ic]).normalized()
		if face_normal.normalized().dot(target) > -0.72:
			count += 1
	return count


func _outward_vertex_normal_error_count(vertices: PackedVector3Array, normals: PackedVector3Array) -> int:
	var count := 0
	for i in range(vertices.size()):
		var expected := _dominant_position_normal(vertices[i])
		if expected == Vector3.ZERO:
			continue
		if normals[i].normalized().dot(expected) < 0.45:
			count += 1
	return count


func _position_front_face_winding_error_count(vertices: PackedVector3Array, indices: PackedInt32Array) -> int:
	var count := 0
	for i in range(0, indices.size(), 3):
		var a := vertices[int(indices[i])]
		var b := vertices[int(indices[i + 1])]
		var c := vertices[int(indices[i + 2])]
		var cross_normal := (b - a).cross(c - a)
		if cross_normal.length_squared() <= 0.00000001:
			continue
		var expected := _dominant_position_normal((a + b + c) / 3.0)
		if expected == Vector3.ZERO:
			continue
		var godot_front_normal := -cross_normal.normalized()
		if godot_front_normal.dot(expected) < 0.45:
			count += 1
	return count


func _dominant_position_normal(position: Vector3) -> Vector3:
	var ax := absf(position.x)
	var ay := absf(position.y)
	var az := absf(position.z)
	if ax >= ay and ax >= az:
		return Vector3.RIGHT if position.x >= 0.0 else Vector3.LEFT
	if ay >= az:
		return Vector3.UP if position.y >= 0.0 else Vector3.DOWN
	return Vector3.BACK if position.z >= 0.0 else Vector3.FORWARD


func _top_digits_are_centered(root_node: Node) -> bool:
	var labels := []
	_collect_nodes_with_name(root_node, "TopDigitGlow", labels)
	if labels.size() != 6:
		return false
	for value in labels:
		var label := value as Label3D
		if label == null:
			return false
		if absf(label.position.x) > 0.001 or absf(label.position.z) > 0.001:
			return false
		if label.position.y < 0.54:
			return false
		if not is_equal_approx(label.rotation.x, -PI * 0.5):
			return false
	return true


func _find_node(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_node(child, node_name)
		if found != null:
			return found
	return null


func _count_nodes_with_prefix(node: Node, prefix: String) -> int:
	var count := 1 if node.name.begins_with(prefix) else 0
	for child in node.get_children():
		count += _count_nodes_with_prefix(child, prefix)
	return count


func _count_nodes_with_name(node: Node, node_name: String) -> int:
	var count := 1 if node.name == node_name else 0
	for child in node.get_children():
		count += _count_nodes_with_name(child, node_name)
	return count


func _count_nodes_by_class(node: Node, class_text: String) -> int:
	var count := 1 if node.get_class() == class_text else 0
	for child in node.get_children():
		count += _count_nodes_by_class(child, class_text)
	return count


func _count_meshes_by_class(node: Node, class_text: String) -> int:
	var count := 0
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null and mesh_instance.mesh.get_class() == class_text:
			count += 1
	for child in node.get_children():
		count += _count_meshes_by_class(child, class_text)
	return count


func _collect_nodes_with_name(node: Node, node_name: String, results: Array) -> void:
	if node.name == node_name:
		results.append(node)
	for child in node.get_children():
		_collect_nodes_with_name(child, node_name, results)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed


func _check_color(label: String, actual: Color, expected: Color) -> bool:
	return _check(label, _color_close(actual, expected))


func _color_close(actual: Color, expected: Color) -> bool:
	return absf(actual.r - expected.r) <= COLOR_EPS \
		and absf(actual.g - expected.g) <= COLOR_EPS \
		and absf(actual.b - expected.b) <= COLOR_EPS \
		and absf(actual.a - expected.a) <= COLOR_EPS
