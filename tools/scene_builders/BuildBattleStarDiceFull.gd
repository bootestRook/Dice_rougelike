extends SceneTree


const RoundedDiceMeshFactory := preload("res://scripts/ui/debug/RoundedDiceMeshFactory.gd")
const DiceMaterialFactory := preload("res://scripts/ui/debug/star_dice_full/DiceMaterialFactory.gd")
const LightingRig := preload("res://scripts/ui/debug/star_dice_full/LightingRig.gd")

const SCENE_PATH := "res://scenes/debug/battle_star_dice_full.tscn"
const EXTERNAL_ROUNDED_DICE_GLB_PATH := "res://assets/models/dice/rounded_dice_base.glb"
const MESH_PATH := "res://assets/models/dice/battle_star/rounded_dice_mesh.tres"
const MATERIAL_DIR := "res://assets/materials/dice/battle_star"
const SHADER_PATH := "res://assets/shaders/dice/battle_star_dice_full.gdshader"
const ENVIRONMENT_PATH := "res://assets/environments/battle_star_dice_full_environment.tres"
const STAGE_SCENE_PATH := "res://assets/models/stage/star_astrology_disc.tscn"

const DICE_SCALE := 0.78
const FACE_PANEL_HALF := 0.355
const FACE_PANEL_FILL_HALF := 0.324
const FACE_PANEL_FILL_THICKNESS := 0.014
const FACE_PANEL_BORDER_THICKNESS := 0.018
const FACE_PANEL_SURFACE_OFFSET := 0.512
const FACE_PANEL_BORDER_OFFSET := 0.532
const DIGIT_OFFSET := 0.550
const DICE_VALUES := [4, 3, 3, 4, 1, 6]
const DICE_MATERIAL_IDS := ["blue", "purple", "teal", "purple", "gold", "white"]
const DICE_POSITIONS := [
	Vector3(-1.95, 0.43, 0.12),
	Vector3(-1.17, 0.43, 0.155),
	Vector3(-0.39, 0.43, 0.12),
	Vector3(0.39, 0.43, 0.155),
	Vector3(1.17, 0.43, 0.12),
	Vector3(1.95, 0.43, 0.155),
]


func _init() -> void:
	print("--- BuildBattleStarDiceFull: start ---")
	var ok := _run()
	print("PASS: BuildBattleStarDiceFull" if ok else "FAIL: BuildBattleStarDiceFull")
	print("--- BuildBattleStarDiceFull: end ---")
	quit(0 if ok else 1)


func _run() -> bool:
	var ok := _ensure_directories()
	if not ok:
		return false
	ok = _save_rounded_mesh() and ok
	ok = DiceMaterialFactory.save_materials(SHADER_PATH, MATERIAL_DIR) and ok
	ok = _save_environment() and ok
	ok = _save_scene() and ok
	ok = _validate_outputs() and ok
	return ok


func _ensure_directories() -> bool:
	var ok := true
	for path in [
		"res://assets/models/dice/battle_star",
		MATERIAL_DIR,
		"res://assets/environments",
		"res://scenes/debug",
	]:
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
		if error != OK and error != ERR_ALREADY_EXISTS:
			push_error("Cannot create directory: %s" % path)
			ok = false
	return ok


func _save_rounded_mesh() -> bool:
	if ResourceLoader.exists(EXTERNAL_ROUNDED_DICE_GLB_PATH):
		print("INFO: external rounded dice model exists; scene builder will prefer %s" % EXTERNAL_ROUNDED_DICE_GLB_PATH)
		return true
	var mesh: ArrayMesh = RoundedDiceMeshFactory.create_rounded_cube({
		"bevel_radius": 0.125,
		"bevel_segments": 6,
		"edge_length_segments": 7,
		"resource_name": "RoundedDiceMesh",
	})
	return _save_resource(mesh, MESH_PATH)


func _save_environment() -> bool:
	var env: Environment = LightingRig.create_environment(true)
	return _save_resource(env, ENVIRONMENT_PATH)


func _save_scene() -> bool:
	var root := Node3D.new()
	root.name = "BattleStarDiceFull"
	root.set_meta("visual_scope", "dice_only_no_gameplay_ui_physics")

	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = load(ENVIRONMENT_PATH) as Environment
	root.add_child(env_node)

	_add_board(root)
	_add_reflection_probe(root)
	_add_camera(root)
	_add_dice(root)
	LightingRig.populate(root, DICE_POSITIONS, DICE_MATERIAL_IDS)
	_add_visual_acceptance_camera(root)

	return _save_packed_scene(root, SCENE_PATH)


func _add_board(root: Node3D) -> void:
	var board_root := Node3D.new()
	board_root.name = "Board3D"
	root.add_child(board_root)
	var stage_scene := load(STAGE_SCENE_PATH) as PackedScene
	if stage_scene == null:
		return
	var stage := stage_scene.instantiate()
	stage.name = "ExistingStarAstrologyDisc"
	board_root.add_child(stage)


func _add_reflection_probe(root: Node3D) -> void:
	if not ClassDB.class_exists("ReflectionProbe"):
		return
	var probe := ClassDB.instantiate("ReflectionProbe") as Node3D
	if probe == null:
		return
	probe.name = "DiceGlossReflectionProbe"
	probe.position = Vector3(0.0, 1.75, 0.12)
	_set_existing(probe, ["size"], Vector3(7.4, 3.2, 5.4))
	_set_existing(probe, ["origin_offset"], Vector3(0.0, 0.18, 0.0))
	_set_existing(probe, ["intensity"], 0.58)
	_set_existing(probe, ["max_distance"], 10.0)
	_set_existing(probe, ["box_projection"], true)
	_set_existing(probe, ["enable_shadows"], false)
	root.add_child(probe)


func _add_camera(root: Node3D) -> void:
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 5.65, 6.95)
	camera.fov = 34.0
	camera.near = 0.05
	camera.far = 80.0
	camera.current = true
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.42, 0.12), Vector3.UP)
	root.add_child(camera)


func _add_visual_acceptance_camera(root: Node3D) -> void:
	var camera := Camera3D.new()
	camera.name = "VA_Camera3D"
	camera.position = Vector3(0.0, 5.65, 6.95)
	camera.fov = 34.0
	camera.near = 0.05
	camera.far = 80.0
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.42, 0.12), Vector3.UP)
	root.add_child(camera)

	var markers := Node3D.new()
	markers.name = "VA_CameraMarkers"
	root.add_child(markers)
	var marker := Marker3D.new()
	marker.name = "battle_star_dice_full"
	marker.position = Vector3(0.0, 5.65, 6.95)
	marker.look_at_from_position(marker.position, Vector3(0.0, 0.42, 0.12), Vector3.UP)
	marker.set_meta("va_target", Vector3(0.0, 0.42, 0.12))
	markers.add_child(marker)


func _add_dice(root: Node3D) -> void:
	var dice_row := Node3D.new()
	dice_row.name = "DiceRow"
	root.add_child(dice_row)

	var mesh := load(MESH_PATH) as Mesh
	for i in range(DICE_VALUES.size()):
		var material_id := str(DICE_MATERIAL_IDS[i])
		var dice_root := Node3D.new()
		dice_root.name = "RoundedDice_%02d" % [i + 1]
		dice_root.position = DICE_POSITIONS[i]
		dice_root.scale = Vector3.ONE * DICE_SCALE
		dice_root.rotation_degrees = Vector3(-11.0, -16.0 + 5.5 * float(i), 4.0 - 1.5 * float(i % 3))
		dice_row.add_child(dice_root)

		_add_dice_body(dice_root, mesh, material_id)
		_add_face_panels(dice_root, material_id)
		_add_face_markers(dice_root, int(DICE_VALUES[i]), material_id)


func _add_dice_body(dice_root: Node3D, mesh: Mesh, material_id: String) -> void:
	var layer := Node3D.new()
	layer.name = "BodyMaterialLayer"
	dice_root.add_child(layer)

	var material := load(DiceMaterialFactory.material_path(MATERIAL_DIR, material_id)) as Material
	if ResourceLoader.exists(EXTERNAL_ROUNDED_DICE_GLB_PATH):
		var packed := load(EXTERNAL_ROUNDED_DICE_GLB_PATH) as PackedScene
		if packed != null:
			var model := packed.instantiate()
			model.name = "RoundedDiceMesh"
			_apply_material_to_mesh_instances(model, material)
			layer.add_child(model)
			return
	var body := MeshInstance3D.new()
	body.name = "RoundedDiceMesh"
	body.mesh = mesh
	body.material_override = material
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	layer.add_child(body)


func _add_face_panels(dice_root: Node3D, material_id: String) -> void:
	var inset_layer := Node3D.new()
	inset_layer.name = "FacePanelInsetLayer"
	dice_root.add_child(inset_layer)

	var glow_layer := Node3D.new()
	glow_layer.name = "FacePanelGlowLayer"
	dice_root.add_child(glow_layer)

	var fill_material := DiceMaterialFactory.make_panel_fill_material(material_id, 0.0)
	var side_material := DiceMaterialFactory.make_panel_fill_material(material_id, 0.20)
	var line_material := DiceMaterialFactory.make_glow_line_material(material_id, 1.0)
	_add_top_panel_fill(inset_layer, fill_material)
	_add_front_panel_fill(inset_layer, fill_material)
	_add_side_panel_fill(inset_layer, side_material, -1.0)
	_add_side_panel_fill(inset_layer, side_material, 1.0)
	_add_top_panel_border(glow_layer, line_material)
	_add_front_panel_border(glow_layer, line_material)


func _add_top_panel_fill(parent: Node3D, material: Material) -> void:
	var panel := MeshInstance3D.new()
	panel.name = "TopInsetPanel"
	panel.mesh = _make_box_array_mesh(Vector3(FACE_PANEL_FILL_HALF * 2.0, FACE_PANEL_FILL_THICKNESS, FACE_PANEL_FILL_HALF * 2.0))
	panel.position = Vector3(0.0, FACE_PANEL_SURFACE_OFFSET, 0.0)
	panel.material_override = material
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(panel)


func _add_front_panel_fill(parent: Node3D, material: Material) -> void:
	var panel := MeshInstance3D.new()
	panel.name = "FrontInsetPanel"
	panel.mesh = _make_box_array_mesh(Vector3(FACE_PANEL_FILL_HALF * 2.0, FACE_PANEL_FILL_HALF * 2.0, FACE_PANEL_FILL_THICKNESS))
	panel.position = Vector3(0.0, 0.0, FACE_PANEL_SURFACE_OFFSET)
	panel.material_override = material
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(panel)


func _add_side_panel_fill(parent: Node3D, material: Material, sign_x: float) -> void:
	var panel := MeshInstance3D.new()
	panel.name = "LeftInsetPanel" if sign_x < 0.0 else "RightInsetPanel"
	panel.mesh = _make_box_array_mesh(Vector3(FACE_PANEL_FILL_THICKNESS, FACE_PANEL_FILL_HALF * 2.0, FACE_PANEL_FILL_HALF * 2.0))
	panel.position = Vector3(sign_x * FACE_PANEL_SURFACE_OFFSET, 0.0, 0.0)
	panel.material_override = material
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(panel)


func _add_top_panel_border(parent: Node3D, material: Material) -> void:
	var h := FACE_PANEL_HALF
	var t := FACE_PANEL_BORDER_THICKNESS
	var y := FACE_PANEL_BORDER_OFFSET
	_add_bar(parent, "TopPanelGlowBorder", Vector3(0.0, y, -h), Vector3(h * 2.0, t, t), material)
	_add_bar(parent, "TopPanelGlowBorder", Vector3(0.0, y, h), Vector3(h * 2.0, t, t), material)
	_add_bar(parent, "TopPanelGlowBorder", Vector3(-h, y, 0.0), Vector3(t, t, h * 2.0), material)
	_add_bar(parent, "TopPanelGlowBorder", Vector3(h, y, 0.0), Vector3(t, t, h * 2.0), material)


func _add_front_panel_border(parent: Node3D, material: Material) -> void:
	var h := FACE_PANEL_HALF
	var t := FACE_PANEL_BORDER_THICKNESS
	var z := FACE_PANEL_BORDER_OFFSET
	_add_bar(parent, "FrontPanelGlowBorder", Vector3(0.0, -h, z), Vector3(h * 2.0, t, t), material)
	_add_bar(parent, "FrontPanelGlowBorder", Vector3(0.0, h, z), Vector3(h * 2.0, t, t), material)
	_add_bar(parent, "FrontPanelGlowBorder", Vector3(-h, 0.0, z), Vector3(t, h * 2.0, t), material)
	_add_bar(parent, "FrontPanelGlowBorder", Vector3(h, 0.0, z), Vector3(t, h * 2.0, t), material)


func _add_face_markers(dice_root: Node3D, top_value: int, material_id: String) -> void:
	var marker_layer := Node3D.new()
	marker_layer.name = "DigitAndDecalLayer"
	dice_root.add_child(marker_layer)

	var digit_material := DiceMaterialFactory.make_digit_material(material_id)
	var glow_material := DiceMaterialFactory.make_glow_line_material(material_id, 1.22)
	_add_top_digit(marker_layer, top_value, digit_material)
	_add_front_star_decal(marker_layer, glow_material)


func _add_top_digit(parent: Node3D, value: int, material: Material) -> void:
	var label := Label3D.new()
	label.name = "TopDigitGlow"
	label.text = str(value)
	label.position = Vector3(0.0, DIGIT_OFFSET, 0.0)
	label.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.double_sided = true
	label.font_size = 96
	label.pixel_size = 0.0047
	var digit_color := Color(1.0, 1.0, 1.0, 1.0)
	if material is StandardMaterial3D:
		var digit_material := material as StandardMaterial3D
		digit_color = digit_material.emission
	label.modulate = Color(digit_color.r * 1.65, digit_color.g * 1.65, digit_color.b * 1.65, 1.0)
	label.outline_size = 10
	label.outline_modulate = Color(0.03, 0.04, 0.08, 0.78)
	parent.add_child(label)


func _add_front_star_decal(parent: Node3D, material: Material) -> void:
	for angle in [0.0, PI * 0.25, PI * 0.5, PI * 0.75]:
		var length := 0.30 if is_equal_approx(angle, 0.0) or is_equal_approx(angle, PI * 0.5) else 0.22
		var bar := MeshInstance3D.new()
		bar.name = "FrontStarGlowDecal_%02d" % [parent.get_child_count() + 1]
		bar.mesh = _make_box_array_mesh(Vector3(length, 0.018, 0.012))
		bar.position = Vector3(0.0, 0.0, DIGIT_OFFSET - 0.004)
		bar.rotation = Vector3(0.0, 0.0, angle)
		bar.material_override = material
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(bar)


func _add_bar(parent: Node3D, node_prefix: String, local_position: Vector3, size: Vector3, material: Material) -> void:
	var bar := MeshInstance3D.new()
	bar.name = "%s_%02d" % [node_prefix, parent.get_child_count() + 1]
	bar.mesh = _make_box_array_mesh(size)
	bar.position = local_position
	bar.material_override = material
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(bar)


func _make_box_array_mesh(size: Vector3) -> ArrayMesh:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	_add_box_face(vertices, normals, uvs, indices, [
		Vector3(-hx, hy, -hz), Vector3(-hx, hy, hz), Vector3(hx, hy, hz), Vector3(hx, hy, -hz),
	], Vector3.UP)
	_add_box_face(vertices, normals, uvs, indices, [
		Vector3(-hx, -hy, hz), Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, -hy, hz),
	], Vector3.DOWN)
	_add_box_face(vertices, normals, uvs, indices, [
		Vector3(-hx, -hy, hz), Vector3(hx, -hy, hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz),
	], Vector3.FORWARD)
	_add_box_face(vertices, normals, uvs, indices, [
		Vector3(hx, -hy, -hz), Vector3(-hx, -hy, -hz), Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz),
	], Vector3.BACK)
	_add_box_face(vertices, normals, uvs, indices, [
		Vector3(hx, -hy, hz), Vector3(hx, -hy, -hz), Vector3(hx, hy, -hz), Vector3(hx, hy, hz),
	], Vector3.RIGHT)
	_add_box_face(vertices, normals, uvs, indices, [
		Vector3(-hx, -hy, -hz), Vector3(-hx, -hy, hz), Vector3(-hx, hy, hz), Vector3(-hx, hy, -hz),
	], Vector3.LEFT)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.resource_name = "DiceDecalArrayMesh"
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_box_face(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, corners: Array, normal: Vector3) -> void:
	var start := vertices.size()
	var face_uvs := [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)]
	for i in range(4):
		vertices.append(corners[i])
		normals.append(normal)
		uvs.append(face_uvs[i])
	indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))


func _apply_material_to_mesh_instances(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.material_override = material
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_apply_material_to_mesh_instances(child, material)


func _save_packed_scene(root: Node, path: String) -> bool:
	_set_scene_owner(root, root)
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Cannot pack scene: %s" % path)
		root.free()
		return false
	var save_error := ResourceSaver.save(packed, path)
	root.free()
	if save_error != OK:
		push_error("Cannot save scene: %s" % path)
		return false
	return true


func _set_scene_owner(node: Node, owner: Node) -> void:
	if node != owner:
		node.owner = owner
	for child in node.get_children():
		_set_scene_owner(child, owner)


func _save_resource(resource: Resource, path: String) -> bool:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Cannot save resource: %s" % path)
		return false
	return true


func _validate_outputs() -> bool:
	var ok := true
	ok = _check("scene saved", load(SCENE_PATH) is PackedScene) and ok
	ok = _check("rounded dice mesh saved", load(MESH_PATH) is ArrayMesh) and ok
	ok = _check("environment saved", load(ENVIRONMENT_PATH) is Environment) and ok
	for material_id in DiceMaterialFactory.MATERIAL_ORDER:
		ok = _check("material %s saved" % material_id, load(DiceMaterialFactory.material_path(MATERIAL_DIR, material_id)) is Material) and ok
	var scene := load(SCENE_PATH) as PackedScene
	if scene != null:
		var state := scene.get_state()
		ok = _check("scene has six rounded dice", _scene_state_count_nodes_with_prefix(state, "RoundedDice_") == 6) and ok
		ok = _check("scene has six body layers", _scene_state_count_nodes_with_name(state, "BodyMaterialLayer") == 6) and ok
		ok = _check("scene has six inset panel layers", _scene_state_count_nodes_with_name(state, "FacePanelInsetLayer") == 6) and ok
		ok = _check("scene has six panel glow layers", _scene_state_count_nodes_with_name(state, "FacePanelGlowLayer") == 6) and ok
		ok = _check("scene has six top glow digits", _scene_state_count_nodes_with_name(state, "TopDigitGlow") == 6) and ok
		ok = _check("scene has no BoxMesh subresources", not _scene_state_has_subresource_type(state, "BoxMesh")) and ok
		ok = _check("scene has lighting rig", _scene_state_has_node_name(state, "LightingRig")) and ok
		ok = _check("scene has six fake contact shadows", _scene_state_count_nodes_with_prefix(state, "FakeContactShadow_") == 6) and ok
	return ok


func _scene_state_has_node_name(state: SceneState, node_name: String) -> bool:
	for node_index in range(state.get_node_count()):
		if str(state.get_node_name(node_index)) == node_name:
			return true
	return false


func _scene_state_count_nodes_with_prefix(state: SceneState, prefix: String) -> int:
	var count := 0
	for node_index in range(state.get_node_count()):
		if str(state.get_node_name(node_index)).begins_with(prefix):
			count += 1
	return count


func _scene_state_count_nodes_with_name(state: SceneState, node_name: String) -> int:
	var count := 0
	for node_index in range(state.get_node_count()):
		if str(state.get_node_name(node_index)) == node_name:
			count += 1
	return count


func _scene_state_has_subresource_type(state: SceneState, type_name: String) -> bool:
	for node_index in range(state.get_node_count()):
		for property_index in range(state.get_node_property_count(node_index)):
			var value = state.get_node_property_value(node_index, property_index)
			if value is Resource and value.get_class() == type_name:
				return true
	return false


func _check(label: String, passed: bool) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", label])
	if not passed:
		push_error(label)
	return passed


func _set_existing(object: Object, names: Array, value) -> bool:
	if object == null:
		return false
	var properties := {}
	for item in object.get_property_list():
		properties[item["name"]] = true
	for name in names:
		if properties.has(name):
			object.set(name, value)
			return true
	return false
