extends SceneTree


const RoundedDiceMeshFactory := preload("res://scripts/ui/debug/RoundedDiceMeshFactory.gd")

const CELL_SIZE := 128
const ATLAS_COLS := 3
const ATLAS_ROWS := 2
const DICE_HALF := 0.5
const BEVEL_RADIUS := 0.078
const BEVEL_SEGMENTS := 4
const EDGE_LENGTH_SEGMENTS := 5
const INNER_HALF := DICE_HALF - BEVEL_RADIUS
const SHOWCASE_DICE_SCALE := 0.76
const EDGE_FRAME_HALF := DICE_HALF - 0.014
const EDGE_FRAME_LENGTH := EDGE_FRAME_HALF * 2.0
const EDGE_BEVEL_RADIUS := 0.040
const EDGE_CORNER_CAP_RADIUS := EDGE_BEVEL_RADIUS
const FACE_PANEL_HALF := 0.36
const FACE_PANEL_THICKNESS := 0.020
const FACE_PANEL_FILL_HALF := 0.335
const FACE_PANEL_FILL_THICKNESS := 0.014
const FACE_PANEL_OFFSET := DICE_HALF + 0.026

const ROUNDED_MESH_PATH := "res://assets/models/dice/rounded_d6_mesh.tres"
const ROUNDED_PREVIEW_PATH := "res://assets/models/dice/rounded_d6_preview.tscn"
const DICE_SHADER_PATH := "res://assets/shaders/dice/repro_glow_dice.gdshader"
const DISC_SCENE_PATH := "res://assets/models/stage/star_astrology_disc.tscn"
const ENVIRONMENT_PATH := "res://assets/environments/gm_dice_visual_repro_environment.tres"
const SHOWCASE_SCENE_PATH := "res://scenes/debug/gm_dice_scene_visual_repro.tscn"
const STAGE_TEXTURE_DIR := "res://assets/textures/stage/star_disc"
const STAGE_TEXTURE_NAMES := ["albedo", "normal", "orm", "emission", "height"]
const STAGE_DATA_TEXTURE_NAMES := ["orm", "height"]

const DICE_MATERIALS := {
	"blue": {
		"path": "res://assets/materials/dice/repro_blue_dice.tres",
		"base": Color(0.026, 0.150, 0.520, 1.0),
		"edge": Color(0.58, 0.86, 1.00, 1.0),
		"emission": Color(0.10, 0.45, 1.00, 1.0),
		"metallic": 0.22,
		"roughness": 0.28,
		"emission_strength": 0.09,
		"fresnel_strength": 0.72,
		"face_detail_strength": 1.12,
		"edge_line_strength": 0.58,
		"corner_glint_strength": 0.24,
		"side_shadow_strength": 0.36,
	},
	"purple": {
		"path": "res://assets/materials/dice/repro_purple_dice.tres",
		"base": Color(0.235, 0.045, 0.500, 1.0),
		"edge": Color(0.92, 0.56, 1.00, 1.0),
		"emission": Color(0.67, 0.18, 1.00, 1.0),
		"metallic": 0.18,
		"roughness": 0.29,
		"emission_strength": 0.09,
		"fresnel_strength": 0.76,
		"face_detail_strength": 1.10,
		"edge_line_strength": 0.62,
		"corner_glint_strength": 0.28,
		"side_shadow_strength": 0.35,
	},
	"cyan": {
		"path": "res://assets/materials/dice/repro_cyan_dice.tres",
		"base": Color(0.000, 0.300, 0.330, 1.0),
		"edge": Color(0.62, 1.00, 0.96, 1.0),
		"emission": Color(0.05, 0.92, 0.92, 1.0),
		"metallic": 0.16,
		"roughness": 0.30,
		"emission_strength": 0.08,
		"fresnel_strength": 0.66,
		"face_detail_strength": 1.05,
		"edge_line_strength": 0.54,
		"corner_glint_strength": 0.22,
		"side_shadow_strength": 0.34,
	},
	"gold": {
		"path": "res://assets/materials/dice/repro_gold_dice.tres",
		"base": Color(0.909804, 0.847059, 0.686275, 1.0),
		"edge": Color(1.00, 0.973, 0.918, 1.0),
		"emission": Color(0.960784, 0.949020, 0.909804, 1.0),
		"metallic": 0.96,
		"roughness": 0.18,
		"roughness_body": 0.18,
		"roughness_panel": 0.24,
		"roughness_edge": 0.10,
		"emission_strength": 0.16,
		"fresnel_strength": 0.72,
		"face_detail_strength": 0.96,
		"edge_line_strength": 0.64,
		"corner_glint_strength": 0.22,
		"side_shadow_strength": 0.16,
	},
	"silverwhite": {
		"path": "res://assets/materials/dice/repro_silverwhite_dice.tres",
		"base": Color(0.580, 0.700, 0.870, 1.0),
		"edge": Color(0.96, 1.00, 1.00, 1.0),
		"emission": Color(0.48, 0.74, 1.00, 1.0),
		"metallic": 0.34,
		"roughness": 0.29,
		"emission_strength": 0.05,
		"fresnel_strength": 0.60,
		"face_detail_strength": 1.02,
		"edge_line_strength": 0.52,
		"corner_glint_strength": 0.20,
		"side_shadow_strength": 0.30,
	},
}

const STAGE_MATERIAL_PATHS := {
	"disc_base": "res://assets/materials/stage/star_disc_base.tres",
	"disc_side": "res://assets/materials/stage/star_disc_side.tres",
	"gold_line": "res://assets/materials/stage/star_disc_gold_line.tres",
	"blue_line": "res://assets/materials/stage/star_disc_blue_line.tres",
	"star_dot": "res://assets/materials/stage/star_disc_star_dot.tres",
	"vignette": "res://assets/materials/stage/star_disc_vignette.tres",
}


func _init() -> void:
	print("--- BuildGmDiceVisualRepro: start ---")
	var ok := _ensure_directories()
	if ok:
		_normalize_stage_texture_imports()
		ok = _save_rounded_d6_mesh() and ok
		ok = _save_dice_materials() and ok
		ok = _save_stage_materials() and ok
		ok = _save_environment() and ok
		ok = _save_star_disc_scene() and ok
		ok = _save_showcase_scene() and ok
		ok = _validate_outputs() and ok
	print("PASS: BuildGmDiceVisualRepro" if ok else "FAIL: BuildGmDiceVisualRepro")
	print("--- BuildGmDiceVisualRepro: end ---")
	quit(0 if ok else 1)


func _ensure_directories() -> bool:
	var ok := true
	for path in [
		"res://assets/models/dice",
		"res://assets/models/stage",
		"res://assets/materials/dice",
		"res://assets/materials/stage",
		STAGE_TEXTURE_DIR,
		"res://assets/shaders/dice",
		"res://assets/environments",
		"res://scenes/debug",
	]:
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
		if error != OK and error != ERR_ALREADY_EXISTS:
			push_error("Cannot create directory: %s" % path)
			ok = false
	return ok


func _normalize_stage_texture_imports() -> void:
	for texture_name_value in STAGE_TEXTURE_NAMES:
		var texture_name := str(texture_name_value)
		var texture_path := "%s/star_disc_%s.png" % [STAGE_TEXTURE_DIR, texture_name]
		var import_path := "%s.import" % texture_path
		if not FileAccess.file_exists(import_path):
			continue
		var text := FileAccess.get_file_as_string(import_path)
		var is_normal: bool = texture_name == "normal"
		var is_data: bool = STAGE_DATA_TEXTURE_NAMES.has(texture_name)
		text = _set_import_value(text, "compress/normal_map", "1" if is_normal else "0")
		text = _set_import_value(text, "mipmaps/generate", "true")
		text = _set_import_value(text, "roughness/mode", "1" if is_normal else "0")
		text = _set_import_value(text, "roughness/src_normal", "\"%s/star_disc_normal.png\"" % STAGE_TEXTURE_DIR if is_normal else "\"\"")
		text = _set_import_value(text, "process/normal_map_invert_y", "false")
		text = _set_import_value(text, "process/hdr_as_srgb", "false")
		if is_data:
			text = _set_import_value(text, "compress/channel_pack", "0")
		var file := FileAccess.open(import_path, FileAccess.WRITE)
		if file == null:
			push_error("Cannot write stage texture import settings: %s" % import_path)
		else:
			file.store_string(text)


func _set_import_value(text: String, key: String, value: String) -> String:
	var lines := text.split("\n")
	var prefix := "%s=" % key
	var replaced := false
	for index in lines.size():
		if lines[index].begins_with(prefix):
			lines[index] = "%s%s" % [prefix, value]
			replaced = true
	if not replaced:
		lines.append("%s%s" % [prefix, value])
	return "\n".join(lines)


func _save_rounded_d6_mesh() -> bool:
	var mesh := _make_rounded_d6_mesh()
	mesh.resource_name = "rounded_d6_mesh"
	var error := ResourceSaver.save(mesh, ROUNDED_MESH_PATH)
	if error != OK:
		push_error("Cannot save rounded d6 mesh: %s" % ROUNDED_MESH_PATH)
		return false

	var root := Node3D.new()
	root.name = "RoundedD6PreviewModel"
	var dice := MeshInstance3D.new()
	dice.name = "DiceMesh"
	dice.mesh = mesh
	root.add_child(dice)
	return _save_scene(root, ROUNDED_PREVIEW_PATH)


func _make_rounded_d6_mesh() -> ArrayMesh:
	return RoundedDiceMeshFactory.create_rounded_cube({
		"bevel_radius": 0.125,
		"bevel_segments": 6,
		"edge_length_segments": 7,
		"resource_name": "rounded_d6_mesh",
	})


func _add_flat_faces(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> void:
	var h := DICE_HALF
	var a := INNER_HALF
	_add_face_grid(vertices, normals, uvs, indices, 1, h, 0, 2, Vector3.UP, -a, a, -a, a)
	_add_face_grid(vertices, normals, uvs, indices, 1, -h, 0, 2, Vector3.DOWN, -a, a, -a, a)
	_add_face_grid(vertices, normals, uvs, indices, 2, h, 0, 1, Vector3.FORWARD, -a, a, -a, a)
	_add_face_grid(vertices, normals, uvs, indices, 2, -h, 0, 1, Vector3.BACK, -a, a, -a, a)
	_add_face_grid(vertices, normals, uvs, indices, 0, h, 2, 1, Vector3.RIGHT, -a, a, -a, a)
	_add_face_grid(vertices, normals, uvs, indices, 0, -h, 2, 1, Vector3.LEFT, -a, a, -a, a)


func _add_face_grid(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	fixed_axis: int,
	fixed_value: float,
	axis_u: int,
	axis_v: int,
	normal: Vector3,
	min_u: float,
	max_u: float,
	min_v: float,
	max_v: float
) -> void:
	var grid: Array = []
	for y in range(EDGE_LENGTH_SEGMENTS + 1):
		var row: Array[int] = []
		var v := lerpf(min_v, max_v, float(y) / float(EDGE_LENGTH_SEGMENTS))
		for x in range(EDGE_LENGTH_SEGMENTS + 1):
			var u := lerpf(min_u, max_u, float(x) / float(EDGE_LENGTH_SEGMENTS))
			var point := Vector3.ZERO
			point[fixed_axis] = fixed_value
			point[axis_u] = u
			point[axis_v] = v
			row.append(_append_vertex(vertices, normals, uvs, point, normal))
		grid.append(row)
	_add_grid_indices(vertices, normals, indices, grid)


func _add_edge_patches(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> void:
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			_add_edge_patch(vertices, normals, uvs, indices, 0, sx, 1, sy, 2)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_edge_patch(vertices, normals, uvs, indices, 0, sx, 2, sz, 1)
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_edge_patch(vertices, normals, uvs, indices, 1, sy, 2, sz, 0)


func _add_edge_patch(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, axis_a: int, sign_a: float, axis_b: int, sign_b: float, free_axis: int) -> void:
	var grid: Array = []
	for i in range(BEVEL_SEGMENTS + 1):
		var theta := (PI * 0.5) * float(i) / float(BEVEL_SEGMENTS)
		var row: Array[int] = []
		for j in range(EDGE_LENGTH_SEGMENTS + 1):
			var t := -INNER_HALF + 2.0 * INNER_HALF * float(j) / float(EDGE_LENGTH_SEGMENTS)
			var normal := Vector3.ZERO
			normal[axis_a] = sign_a * cos(theta)
			normal[axis_b] = sign_b * sin(theta)
			normal = normal.normalized()
			var position := Vector3.ZERO
			position[axis_a] = sign_a * INNER_HALF + normal[axis_a] * BEVEL_RADIUS
			position[axis_b] = sign_b * INNER_HALF + normal[axis_b] * BEVEL_RADIUS
			position[free_axis] = t
			row.append(_append_vertex(vertices, normals, uvs, position, normal))
		grid.append(row)
	_add_grid_indices(vertices, normals, indices, grid)


func _add_corner_patches(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> void:
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_add_corner_patch(vertices, normals, uvs, indices, sx, sy, sz)


func _add_corner_patch(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, sx: float, sy: float, sz: float) -> void:
	var grid: Array = []
	for i in range(BEVEL_SEGMENTS + 1):
		var u := (PI * 0.5) * float(i) / float(BEVEL_SEGMENTS)
		var row: Array[int] = []
		for j in range(BEVEL_SEGMENTS + 1):
			var v := (PI * 0.5) * float(j) / float(BEVEL_SEGMENTS)
			var n_abs := Vector3(cos(u) * cos(v), sin(u) * cos(v), sin(v))
			var normal := Vector3(sx * n_abs.x, sy * n_abs.y, sz * n_abs.z).normalized()
			var center := Vector3(sx * INNER_HALF, sy * INNER_HALF, sz * INNER_HALF)
			var position := center + normal * BEVEL_RADIUS
			row.append(_append_vertex(vertices, normals, uvs, position, normal))
		grid.append(row)
	_add_grid_indices(vertices, normals, indices, grid)


func _add_quad(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, corners: Array, normal: Vector3) -> void:
	var row: Array[int] = []
	for point in corners:
		row.append(_append_vertex(vertices, normals, uvs, point, normal))
	_add_triangle_indices(vertices, normals, indices, row[0], row[1], row[2])
	_add_triangle_indices(vertices, normals, indices, row[0], row[2], row[3])


func _add_grid_indices(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, grid: Array) -> void:
	for i in range(grid.size() - 1):
		var row_a: Array = grid[i]
		var row_b: Array = grid[i + 1]
		for j in range(row_a.size() - 1):
			var a := int(row_a[j])
			var b := int(row_b[j])
			var c := int(row_b[j + 1])
			var d := int(row_a[j + 1])
			_add_triangle_indices(vertices, normals, indices, a, b, c)
			_add_triangle_indices(vertices, normals, indices, a, c, d)


func _append_vertex(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, position: Vector3, normal: Vector3) -> int:
	vertices.append(position)
	normals.append(normal.normalized())
	uvs.append(_uv_for_point(position, normal))
	return vertices.size() - 1


func _add_triangle_indices(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, i0: int, i1: int, i2: int) -> void:
	var edge_a := vertices[i1] - vertices[i0]
	var edge_b := vertices[i2] - vertices[i0]
	var face_normal := edge_a.cross(edge_b)
	if face_normal.length_squared() <= 0.00000001:
		return
	var target_normal := (normals[i0] + normals[i1] + normals[i2]).normalized()
	if face_normal.dot(target_normal) > 0.0:
		indices.append_array(PackedInt32Array([i0, i2, i1]))
	else:
		indices.append_array(PackedInt32Array([i0, i1, i2]))


func _uv_for_point(position: Vector3, normal: Vector3) -> Vector2:
	var value := _face_value_from_normal(normal)
	var rect := _uv_rect_for_value(value)
	var local := Vector2.ZERO
	match value:
		1, 6:
			local = Vector2(position.x + DICE_HALF, position.z + DICE_HALF)
		2, 5:
			local = Vector2(position.x + DICE_HALF, position.y + DICE_HALF)
		3:
			local = Vector2(DICE_HALF - position.z, position.y + DICE_HALF)
		4:
			local = Vector2(position.z + DICE_HALF, position.y + DICE_HALF)
	local.x = clampf(local.x, 0.0, 1.0)
	local.y = clampf(local.y, 0.0, 1.0)
	return Vector2(rect.position.x + rect.size.x * local.x, rect.position.y + rect.size.y * (1.0 - local.y))


func _face_value_from_normal(normal: Vector3) -> int:
	var ax := absf(normal.x)
	var ay := absf(normal.y)
	var az := absf(normal.z)
	if ay >= ax and ay >= az:
		return 1 if normal.y >= 0.0 else 6
	if az >= ax:
		return 2 if normal.z >= 0.0 else 5
	return 3 if normal.x >= 0.0 else 4


func _uv_rect_for_value(value: int) -> Rect2:
	var index := value - 1
	var col := index % ATLAS_COLS
	var row := index / ATLAS_COLS
	var pad := 1.5 / float(CELL_SIZE)
	var u0 := float(col) / float(ATLAS_COLS) + pad
	var v0 := float(row) / float(ATLAS_ROWS) + pad
	var u1 := float(col + 1) / float(ATLAS_COLS) - pad
	var v1 := float(row + 1) / float(ATLAS_ROWS) - pad
	return Rect2(Vector2(u0, v0), Vector2(u1 - u0, v1 - v0))


func _save_dice_materials() -> bool:
	var shader := load(DICE_SHADER_PATH) as Shader
	if shader == null:
		push_error("Cannot load dice shader: %s" % DICE_SHADER_PATH)
		return false
	var ok := true
	for material_id in DICE_MATERIALS.keys():
		var spec: Dictionary = DICE_MATERIALS[material_id]
		var material := ShaderMaterial.new()
		material.resource_name = "repro_%s_dice" % material_id
		material.shader = shader
		material.set_shader_parameter("base_color", spec["base"])
		material.set_shader_parameter("edge_color", spec["edge"])
		material.set_shader_parameter("emission_color", spec["emission"])
		material.set_shader_parameter("metallic", float(spec["metallic"]))
		material.set_shader_parameter("roughness", float(spec["roughness"]))
		material.set_shader_parameter("emission_strength", float(spec["emission_strength"]))
		material.set_shader_parameter("fresnel_strength", float(spec["fresnel_strength"]))
		material.set_shader_parameter("fresnel_power", 2.75)
		material.set_shader_parameter("surface_variation", 0.028)
		material.set_shader_parameter("face_detail_strength", float(spec["face_detail_strength"]))
		material.set_shader_parameter("edge_line_strength", float(spec["edge_line_strength"]))
		material.set_shader_parameter("corner_glint_strength", float(spec["corner_glint_strength"]))
		material.set_shader_parameter("side_shadow_strength", float(spec["side_shadow_strength"]))
		var error := ResourceSaver.save(material, str(spec["path"]))
		if error != OK:
			push_error("Cannot save dice material: %s" % spec["path"])
			ok = false
	return ok


func _save_stage_materials() -> bool:
	var ok := true
	ok = _save_material(_make_stage_disc_material(), STAGE_MATERIAL_PATHS["disc_base"]) and ok
	ok = _save_material(_make_standard_material(Color(0.012, 0.012, 0.030, 1.0), 0.78, 0.0, Color(0.0, 0.0, 0.0, 1.0), 0.0), STAGE_MATERIAL_PATHS["disc_side"]) and ok
	ok = _save_material(_make_standard_material(Color(0.94, 0.62, 0.24, 1.0), 0.36, 0.18, Color(1.0, 0.68, 0.25, 1.0), 0.85), STAGE_MATERIAL_PATHS["gold_line"]) and ok
	ok = _save_material(_make_standard_material(Color(0.12, 0.44, 1.0, 1.0), 0.42, 0.0, Color(0.13, 0.58, 1.0, 1.0), 0.80), STAGE_MATERIAL_PATHS["blue_line"]) and ok
	ok = _save_material(_make_standard_material(Color(0.80, 0.94, 1.0, 1.0), 0.25, 0.0, Color(0.46, 0.78, 1.0, 1.0), 1.30), STAGE_MATERIAL_PATHS["star_dot"]) and ok
	var vignette := _make_standard_material(Color(0.0, 0.0, 0.0, 0.34), 0.9, 0.0, Color.BLACK, 0.0)
	vignette.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ok = _save_material(vignette, STAGE_MATERIAL_PATHS["vignette"]) and ok
	return ok


func _make_stage_disc_material() -> Material:
	var material = ClassDB.instantiate("ORMMaterial3D") if ClassDB.class_exists("ORMMaterial3D") else StandardMaterial3D.new()
	material.resource_name = "star_disc_base"
	material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	material.roughness = 0.50
	material.metallic = 0.10
	_set_existing(material, ["albedo_texture"], _load_stage_texture("albedo"))
	_set_existing(material, ["orm_texture"], _load_stage_texture("orm"))
	_set_existing(material, ["normal_enabled"], true)
	_set_existing(material, ["normal_texture"], _load_stage_texture("normal"))
	_set_existing(material, ["normal_scale"], 0.86)
	_set_existing(material, ["heightmap_enabled"], true)
	_set_existing(material, ["heightmap_texture"], _load_stage_texture("height"))
	_set_existing(material, ["heightmap_scale"], 0.045)
	_set_existing(material, ["emission_enabled"], true)
	_set_existing(material, ["emission"], Color(0.10, 0.17, 0.32, 1.0))
	_set_existing(material, ["emission_energy_multiplier"], 0.40)
	_set_existing(material, ["emission_texture"], _load_stage_texture("emission"))
	return material


func _make_standard_material(color: Color, roughness: float, metallic: float, emission: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material


func _save_material(material: Material, path: String) -> bool:
	var error := ResourceSaver.save(material, path)
	if error != OK:
		push_error("Cannot save material: %s" % path)
		return false
	return true


func _load_stage_texture(texture_name: String) -> Texture2D:
	var path := "%s/star_disc_%s.png" % [STAGE_TEXTURE_DIR, texture_name]
	if not ResourceLoader.exists(path):
		return null
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Cannot load stage disc texture: %s" % path)
	return texture


func _save_environment() -> bool:
	var env := Environment.new()
	env.resource_name = "gm_dice_visual_repro_environment"
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.095, 0.115, 0.140, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.36, 0.40, 1.0)
	env.ambient_light_energy = 0.56
	_set_existing(env, ["ambient_light_sky_contribution"], 0.16)
	_set_existing(env, ["reflected_light_source"], 0)
	_set_existing(env, ["glow_enabled"], true)
	_set_existing(env, ["glow_intensity"], 0.40)
	_set_existing(env, ["glow_strength"], 0.72)
	_set_existing(env, ["glow_bloom"], 0.10)
	_set_existing(env, ["glow_hdr_threshold"], 0.82)
	_set_existing(env, ["tonemap_mode"], 3)
	_set_existing(env, ["tonemap_exposure"], 1.00)
	_set_existing(env, ["tonemap_white"], 1.70)
	_set_existing(env, ["ssao_enabled"], true)
	_set_existing(env, ["ssao_radius"], 1.35)
	_set_existing(env, ["ssao_intensity"], 0.62)
	return _save_resource(env, ENVIRONMENT_PATH)


func _save_star_disc_scene() -> bool:
	var root := _make_star_disc_root()
	return _save_scene(root, DISC_SCENE_PATH)


func _make_star_disc_root() -> Node3D:
	var root := Node3D.new()
	root.name = "StarAstrologyDisc"
	var base_mat := load(STAGE_MATERIAL_PATHS["disc_base"]) as Material
	var side_mat := load(STAGE_MATERIAL_PATHS["disc_side"]) as Material

	var base := MeshInstance3D.new()
	base.name = "LitAstrologyDiscTop"
	base.mesh = _make_disc_top_mesh(5.30, 256)
	base.position.y = 0.012
	base.material_override = base_mat
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(base)

	var side := MeshInstance3D.new()
	side.name = "LitAstrologyDiscSide"
	var side_cylinder := CylinderMesh.new()
	side_cylinder.top_radius = 5.34
	side_cylinder.bottom_radius = 5.48
	side_cylinder.height = 0.28
	side_cylinder.radial_segments = 192
	side.mesh = side_cylinder
	side.position.y = -0.14
	side.material_override = side_mat
	side.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(side)

	return root


func _make_disc_top_mesh(radius: float, segments: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(segments):
		var angle_a := TAU * float(i) / float(segments)
		var angle_b := TAU * float(i + 1) / float(segments)
		var center := Vector3(0.0, 0.0, 0.0)
		var point_a := Vector3(cos(angle_a) * radius, 0.0, sin(angle_a) * radius)
		var point_b := Vector3(cos(angle_b) * radius, 0.0, sin(angle_b) * radius)
		_add_disc_vertex(surface, center, radius)
		_add_disc_vertex(surface, point_a, radius)
		_add_disc_vertex(surface, point_b, radius)
	surface.generate_tangents()
	return surface.commit()


func _add_disc_vertex(surface: SurfaceTool, vertex: Vector3, radius: float) -> void:
	surface.set_normal(Vector3.UP)
	surface.set_uv(Vector2(vertex.x / (radius * 2.0) + 0.5, vertex.z / (radius * 2.0) + 0.5))
	surface.add_vertex(vertex)


func _add_ring(parent: Node3D, node_name: String, radius: float, thickness: float, y: float, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = _make_annulus_mesh(radius - thickness * 0.5, radius + thickness * 0.5, y)
	node.material_override = material
	parent.add_child(node)


func _make_annulus_mesh(inner_radius: float, outer_radius: float, y: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var segments := 192
	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		for radius in [inner_radius, outer_radius]:
			vertices.append(dir * radius + Vector3(0.0, y, 0.0))
			normals.append(Vector3.UP)
			uvs.append(Vector2((dir.x + 1.0) * 0.5, (dir.z + 1.0) * 0.5))
	for i in range(segments):
		var a := i * 2
		indices.append_array(PackedInt32Array([a, a + 1, a + 3, a, a + 3, a + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_radial_line(parent: Node3D, node_name: String, angle: float, inner_radius: float, outer_radius: float, width: float, material: Material) -> void:
	var start := Vector2(cos(angle), sin(angle)) * inner_radius
	var end := Vector2(cos(angle), sin(angle)) * outer_radius
	_add_line_bar(parent, node_name, start, end, width, 0.030, material)


func _add_constellation_line(parent: Node3D, node_name: String, start: Vector2, end: Vector2, width: float, material: Material) -> void:
	_add_line_bar(parent, node_name, start, end, width, 0.050, material)


func _add_line_bar(parent: Node3D, node_name: String, start: Vector2, end: Vector2, width: float, y: float, material: Material) -> void:
	var delta := end - start
	var length := delta.length()
	if length <= 0.001:
		return
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(length, 0.010, width)
	node.mesh = mesh
	node.position = Vector3((start.x + end.x) * 0.5, y, (start.y + end.y) * 0.5)
	node.rotation.y = -atan2(delta.y, delta.x)
	node.material_override = material
	parent.add_child(node)


func _add_star_dot(parent: Node3D, node_name: String, point: Vector2, radius: float, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	node.position = Vector3(point.x, 0.070, point.y)
	node.material_override = material
	parent.add_child(node)


func _make_star_mesh(inner_radius: float, outer_radius: float, points: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	uvs.append(Vector2(0.5, 0.5))
	var total := points * 2
	for i in range(total):
		var radius := outer_radius if i % 2 == 0 else inner_radius
		var angle := TAU * float(i) / float(total)
		vertices.append(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
		normals.append(Vector3.UP)
		uvs.append(Vector2(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))
	for i in range(total):
		var next := 1 + ((i + 1) % total)
		indices.append_array(PackedInt32Array([0, 1 + i, next]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _save_showcase_scene() -> bool:
	var root := Node3D.new()
	root.name = "GmDiceSceneVisualRepro"

	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = load(ENVIRONMENT_PATH) as Environment
	root.add_child(env_node)

	var stage_scene := load(DISC_SCENE_PATH) as PackedScene
	if stage_scene != null:
		var stage := stage_scene.instantiate()
		stage.name = "StarAstrologyDisc"
		root.add_child(stage)

	_add_showcase_lights(root)
	_add_showcase_reflection_probe(root)
	_add_showcase_camera(root)
	_add_showcase_dice(root)
	_add_showcase_visual_acceptance_nodes(root)
	return _save_scene(root, SHOWCASE_SCENE_PATH)


func _add_showcase_lights(root: Node3D) -> void:
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-48.0, 38.0, 0.0)
	key.light_color = Color(1.00, 0.949, 0.839)
	key.light_energy = 1.90
	key.light_specular = 0.64
	key.shadow_enabled = true
	root.add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "CoolFillLight"
	fill.position = Vector3(-3.8, 2.2, 3.2)
	fill.light_color = Color(0.722, 0.843, 1.0)
	fill.light_energy = 0.53
	fill.light_specular = 0.28
	fill.omni_range = 8.6
	root.add_child(fill)

	var rim := OmniLight3D.new()
	rim.name = "CyanRimLight"
	rim.position = Vector3(3.6, 2.4, -2.8)
	rim.light_color = Color(1.0, 0.973, 0.918)
	rim.light_energy = 0.38
	rim.light_specular = 0.52
	rim.omni_range = 7.4
	root.add_child(rim)

	var gold := OmniLight3D.new()
	gold.name = "WarmGoldBounceLight"
	gold.position = Vector3(0.0, 1.15, 3.6)
	gold.light_color = Color(1.0, 0.63, 0.24)
	gold.light_energy = 0.72
	gold.light_specular = 0.40
	gold.omni_range = 5.6
	root.add_child(gold)

	var role_specs := [
		{
			"role": "soft_key_top",
			"name": "SoftTopKeyLight",
			"position": Vector3(0.0, 7.8, 1.5),
			"color": Color(1.00, 0.90, 0.72),
			"energy": 1.18,
			"range": 15.5,
			"specular": 0.18,
			"attenuation": 0.62,
		},
		{
			"role": "cool_table_bounce",
			"name": "CoolTableBounceLight",
			"position": Vector3(-2.5, 1.18, 1.75),
			"color": Color(0.26, 0.52, 1.00),
			"energy": 0.58,
			"range": 11.2,
			"specular": 0.08,
			"attenuation": 0.72,
		},
		{
			"role": "warm_gold_edge_kicker",
			"name": "WarmGoldEdgeKickerLight",
			"position": Vector3(4.3, 2.6, 3.2),
			"color": Color(1.00, 0.66, 0.28),
			"energy": 0.78,
			"range": 9.6,
			"specular": 0.42,
			"attenuation": 0.68,
		},
		{
			"role": "local_glint_highlight",
			"name": "LocalGlintHighlightLight",
			"position": Vector3(-1.1, 2.2, 2.0),
			"color": Color(0.84, 0.96, 1.00),
			"energy": 0.62,
			"range": 5.2,
			"specular": 0.56,
			"attenuation": 0.56,
		},
		{
			"role": "reflection_reference",
			"name": "ReflectionReferenceLight",
			"position": Vector3(2.0, 3.8, -2.8),
			"color": Color(0.92, 0.98, 1.00),
			"energy": 0.34,
			"range": 8.8,
			"specular": 0.62,
			"attenuation": 0.60,
		},
	]
	for spec in role_specs:
		var role_light := OmniLight3D.new()
		role_light.name = str(spec["name"])
		role_light.position = spec["position"]
		role_light.light_color = spec["color"]
		role_light.light_energy = float(spec["energy"])
		role_light.light_specular = float(spec["specular"])
		role_light.omni_range = float(spec["range"])
		role_light.omni_attenuation = float(spec["attenuation"])
		role_light.shadow_enabled = false
		role_light.set_meta("visual_light_role", str(spec["role"]))
		root.add_child(role_light)


func _add_showcase_reflection_probe(root: Node3D) -> void:
	if not ClassDB.class_exists("ReflectionProbe"):
		return
	var probe := ClassDB.instantiate("ReflectionProbe") as Node3D
	if probe == null:
		return
	probe.name = "GlossReflectionProbe"
	probe.position = Vector3(0.0, 1.85, 0.10)
	_set_existing(probe, ["size"], Vector3(9.4, 4.8, 7.2))
	_set_existing(probe, ["origin_offset"], Vector3(0.0, 0.14, 0.0))
	_set_existing(probe, ["intensity"], 0.95)
	_set_existing(probe, ["max_distance"], 12.0)
	_set_existing(probe, ["box_projection"], true)
	_set_existing(probe, ["enable_shadows"], false)
	root.add_child(probe)


func _add_showcase_camera(root: Node3D) -> void:
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.position = Vector3(0.0, 5.65, 6.95)
	camera.fov = 34.0
	camera.near = 0.05
	camera.far = 80.0
	camera.current = true
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.36, 0.10), Vector3.UP)
	root.add_child(camera)


func _add_showcase_visual_acceptance_nodes(root: Node3D) -> void:
	var camera := Camera3D.new()
	camera.name = "VA_Camera3D"
	camera.position = Vector3(0.0, 5.65, 6.95)
	camera.fov = 34.0
	camera.near = 0.05
	camera.far = 80.0
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.44, 0.12), Vector3.UP)
	root.add_child(camera)

	var markers := Node3D.new()
	markers.name = "VA_CameraMarkers"
	root.add_child(markers)
	_add_va_camera_marker(markers, "dice_shader_basic", Vector3(0.0, 5.65, 6.95), Vector3(0.0, 0.44, 0.12))
	_add_va_camera_marker(markers, "table_shader_basic", Vector3(0.0, 7.8, 4.8), Vector3(0.0, 0.05, 0.0))
	_add_va_camera_marker(markers, "light_effect_basic", Vector3(3.6, 3.2, 5.4), Vector3(0.15, 0.55, 0.1))
	_add_va_camera_marker(markers, "battle_star_dice_repro_full", Vector3(0.0, 5.65, 6.95), Vector3(0.0, 0.42, 0.12))

	var watermark_layer := CanvasLayer.new()
	watermark_layer.name = "VA_WatermarkLayer"
	watermark_layer.layer = 128
	root.add_child(watermark_layer)

	var watermark_label := Label.new()
	watermark_label.name = "VA_WatermarkLabel"
	watermark_label.text = "VA pending"
	watermark_label.offset_left = 18.0
	watermark_label.offset_top = 16.0
	watermark_label.offset_right = 720.0
	watermark_label.offset_bottom = 236.0
	watermark_label.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
	watermark_label.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.03, 0.92))
	watermark_label.add_theme_constant_override("outline_size", 4)
	watermark_label.add_theme_font_size_override("font_size", 20)
	watermark_layer.add_child(watermark_label)

	var runner_marker := Node.new()
	runner_marker.name = "VA_ShaderLightAcceptanceRunner"
	root.add_child(runner_marker)


func _add_va_camera_marker(parent: Node3D, marker_name: String, position: Vector3, target: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = position
	marker.set_meta("va_target", target)
	marker.look_at_from_position(position, target, Vector3.UP)
	parent.add_child(marker)


func _add_showcase_dice(root: Node3D) -> void:
	var mesh := load(ROUNDED_MESH_PATH) as Mesh
	var values := [4, 3, 3, 4, 1, 6]
	var material_ids := ["blue", "purple", "cyan", "purple", "gold", "silverwhite"]
	var x_positions := [-1.95, -1.17, -0.39, 0.39, 1.17, 1.95]
	for i in range(values.size()):
		var dice_root := Node3D.new()
		dice_root.name = "RoundedD6_%02d" % [i + 1]
		dice_root.position = Vector3(float(x_positions[i]), 0.43, 0.12 + 0.035 * float(i % 2))
		dice_root.scale = Vector3.ONE * SHOWCASE_DICE_SCALE
		dice_root.rotation_degrees = Vector3(-11.0, -16.0 + 5.5 * float(i), 4.0 - 1.5 * float(i % 3))
		root.add_child(dice_root)

		var body_layer := Node3D.new()
		body_layer.name = "BodyMaterialLayer"
		dice_root.add_child(body_layer)

		var body := MeshInstance3D.new()
		body.name = "DiceMesh"
		body.mesh = mesh
		body.material_override = load(str(DICE_MATERIALS[material_ids[i]]["path"])) as Material
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		body_layer.add_child(body)

		var edge_rim := Node3D.new()
		edge_rim.name = "EdgeRimGlowLayer"
		dice_root.add_child(edge_rim)
		_add_edge_frame_bars(edge_rim, _make_showcase_edge_rim_material(material_ids[i]))

		var face_layer := Node3D.new()
		face_layer.name = "FaceMarkerLayer"
		dice_root.add_child(face_layer)
		_add_face_markers(face_layer, int(values[i]), material_ids[i])

		var state_layer := Node3D.new()
		state_layer.name = "StateOverlayLayer"
		state_layer.visible = false
		dice_root.add_child(state_layer)

		var contact_layer := Node3D.new()
		contact_layer.name = "ContactShadowLayer"
		dice_root.add_child(contact_layer)
		var shadow := MeshInstance3D.new()
		shadow.name = "SoftContactShadow"
		shadow.mesh = _make_annulus_mesh(0.02, 0.42, 0.0)
		shadow.scale = Vector3(1.05, 1.0, 0.54)
		shadow.position = Vector3(0.0, -0.505, 0.02)
		var shadow_mat := _make_standard_material(Color(0.0, 0.0, 0.0, 0.42), 0.92, 0.0, Color.BLACK, 0.0)
		shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shadow.material_override = shadow_mat
		contact_layer.add_child(shadow)


func _add_edge_frame_bars(parent: Node3D, material: Material) -> void:
	var h := EDGE_FRAME_HALF
	var l := EDGE_FRAME_LENGTH
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_edge_bevel_rail(parent, Vector3(0.0, sy * h, sz * h), "x", l, material)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_edge_bevel_rail(parent, Vector3(sx * h, 0.0, sz * h), "y", l, material)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			_add_edge_bevel_rail(parent, Vector3(sx * h, sy * h, 0.0), "z", l, material)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_add_edge_corner_bevel_cap(parent, Vector3(sx * h, sy * h, sz * h), material)


func _add_edge_bevel_rail(parent: Node3D, local_position: Vector3, axis: String, length: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = EDGE_BEVEL_RADIUS
	mesh.bottom_radius = EDGE_BEVEL_RADIUS
	mesh.height = length
	mesh.radial_segments = 10
	mesh.rings = 1
	var bar := MeshInstance3D.new()
	bar.name = "EdgeBevelRail_%02d" % [parent.get_child_count() + 1]
	bar.mesh = mesh
	bar.position = local_position
	if axis == "x":
		bar.rotation.z = PI * 0.5
	elif axis == "z":
		bar.rotation.x = PI * 0.5
	bar.material_override = material
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(bar)


func _add_edge_corner_bevel_cap(parent: Node3D, local_position: Vector3, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = EDGE_CORNER_CAP_RADIUS
	mesh.height = EDGE_CORNER_CAP_RADIUS * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var cap := MeshInstance3D.new()
	cap.name = "EdgeCornerBevelCap_%02d" % [parent.get_child_count() + 1]
	cap.mesh = mesh
	cap.position = local_position
	cap.material_override = material
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(cap)


func _make_showcase_edge_rim_material(material_id: String) -> StandardMaterial3D:
	var spec: Dictionary = DICE_MATERIALS.get(material_id, DICE_MATERIALS["blue"])
	var edge: Color = spec.get("edge", Color(0.80, 0.94, 1.00, 1.0))
	var material := StandardMaterial3D.new()
	material.resource_name = "showcase_%s_edge_rim_layer" % material_id
	material.albedo_color = Color(edge.r * 0.58, edge.g * 0.58, edge.b * 0.60, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.emission_enabled = true
	material.emission = edge
	material.emission_energy_multiplier = clampf(float(spec.get("fresnel_strength", 0.7)) * 0.10, 0.045, 0.085)
	material.roughness = float(spec.get("roughness_edge", 0.42))
	material.metallic = 0.0
	return material


func _digit_color_for_material(material_id: String) -> Color:
	match material_id:
		"gold":
			return Color(0.960784, 0.949020, 0.909804, 1.0)
		"silverwhite":
			return Color(0.96, 0.98, 1.0, 1.0)
		"cyan":
			return Color(0.80, 1.0, 0.96, 1.0)
		"purple":
			return Color(0.98, 0.88, 1.0, 1.0)
		_:
			return Color(0.86, 0.95, 1.0, 1.0)


func _add_face_markers(parent: Node3D, top_value: int, material_id: String) -> void:
	var digit_color := _digit_color_for_material(material_id)
	var spec: Dictionary = DICE_MATERIALS.get(material_id, DICE_MATERIALS["blue"])
	var edge: Color = spec.get("edge", digit_color)
	var base: Color = spec.get("base", Color(0.12, 0.20, 0.36, 1.0))
	var panel_fill_material := _make_face_panel_fill_material(base, edge, float(spec.get("metallic", 0.14)), float(spec.get("roughness_panel", 0.38)))
	var side_fill_material := _make_face_panel_fill_material(base.darkened(0.22), edge.darkened(0.20), float(spec.get("metallic", 0.14)), float(spec.get("roughness_panel", 0.38)))
	var panel_border_material := _make_face_marker_material(Color(edge.r, edge.g, edge.b, 1.0), 0.11)
	var emblem_material := _make_face_marker_material(digit_color, 0.50)
	_add_top_face_fill(parent, panel_fill_material)
	_add_front_face_fill(parent, panel_fill_material)
	_add_side_face_fills(parent, side_fill_material)
	_add_top_face_panel(parent, panel_border_material)
	_add_front_face_panel(parent, panel_border_material)
	_add_front_star_emblem(parent, emblem_material)
	_add_face_labels(parent, top_value, digit_color)


func _make_face_marker_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy_multiplier = emission_energy
	return material


func _make_face_panel_fill_material(base: Color, edge: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var fill := base.lerp(edge, 0.18)
	material.albedo_color = Color(fill.r, fill.g, fill.b, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.roughness = roughness
	material.metallic = clampf(metallic * 0.45, 0.0, 0.30)
	material.emission_enabled = true
	material.emission = edge.darkened(0.38)
	material.emission_energy_multiplier = 0.035
	return material


func _add_top_face_fill(parent: Node3D, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(FACE_PANEL_FILL_HALF * 2.0, FACE_PANEL_FILL_THICKNESS, FACE_PANEL_FILL_HALF * 2.0)
	var panel := MeshInstance3D.new()
	panel.name = "TopFaceFill"
	panel.mesh = mesh
	panel.position = Vector3(0.0, FACE_PANEL_OFFSET - 0.004, 0.0)
	panel.material_override = material
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(panel)


func _add_front_face_fill(parent: Node3D, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(FACE_PANEL_FILL_HALF * 2.0, FACE_PANEL_FILL_HALF * 2.0, FACE_PANEL_FILL_THICKNESS)
	var panel := MeshInstance3D.new()
	panel.name = "FrontFaceFill"
	panel.mesh = mesh
	panel.position = Vector3(0.0, 0.0, FACE_PANEL_OFFSET - 0.004)
	panel.material_override = material
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(panel)


func _add_side_face_fills(parent: Node3D, material: Material) -> void:
	for sx in [-1.0, 1.0]:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(FACE_PANEL_FILL_THICKNESS, FACE_PANEL_FILL_HALF * 2.0, FACE_PANEL_FILL_HALF * 2.0)
		var panel := MeshInstance3D.new()
		panel.name = "SideFaceFill_L" if sx < 0.0 else "SideFaceFill_R"
		panel.mesh = mesh
		panel.position = Vector3(sx * (FACE_PANEL_OFFSET - 0.004), 0.0, 0.0)
		panel.material_override = material
		panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(panel)


func _add_top_face_panel(parent: Node3D, material: Material) -> void:
	var h := FACE_PANEL_HALF
	var t := FACE_PANEL_THICKNESS
	var y := FACE_PANEL_OFFSET
	_add_face_panel_bar(parent, "TopFacePanel", Vector3(0.0, y, -h), Vector3(h * 2.0, t, t), material)
	_add_face_panel_bar(parent, "TopFacePanel", Vector3(0.0, y, h), Vector3(h * 2.0, t, t), material)
	_add_face_panel_bar(parent, "TopFacePanel", Vector3(-h, y, 0.0), Vector3(t, t, h * 2.0), material)
	_add_face_panel_bar(parent, "TopFacePanel", Vector3(h, y, 0.0), Vector3(t, t, h * 2.0), material)


func _add_front_face_panel(parent: Node3D, material: Material) -> void:
	var h := FACE_PANEL_HALF
	var t := FACE_PANEL_THICKNESS
	var z := FACE_PANEL_OFFSET
	_add_face_panel_bar(parent, "FrontFacePanel", Vector3(0.0, -h, z), Vector3(h * 2.0, t, t), material)
	_add_face_panel_bar(parent, "FrontFacePanel", Vector3(0.0, h, z), Vector3(h * 2.0, t, t), material)
	_add_face_panel_bar(parent, "FrontFacePanel", Vector3(-h, 0.0, z), Vector3(t, h * 2.0, t), material)
	_add_face_panel_bar(parent, "FrontFacePanel", Vector3(h, 0.0, z), Vector3(t, h * 2.0, t), material)


func _add_face_panel_bar(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var bar := MeshInstance3D.new()
	bar.name = "%s_%02d" % [node_name, parent.get_child_count() + 1]
	bar.mesh = mesh
	bar.position = local_position
	bar.material_override = material
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(bar)


func _add_front_star_emblem(parent: Node3D, material: Material) -> void:
	for angle in [0.0, PI * 0.25, PI * 0.5, PI * 0.75]:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.30 if angle == 0.0 or angle == PI * 0.5 else 0.22, 0.020, 0.012)
		var bar := MeshInstance3D.new()
		bar.name = "FrontStarEmblem_%02d" % [parent.get_child_count() + 1]
		bar.mesh = mesh
		bar.position = Vector3(0.0, 0.0, DICE_HALF + 0.043)
		bar.rotation = Vector3(0.0, 0.0, angle)
		bar.material_override = material
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(bar)


func _add_face_labels(parent: Node3D, top_value: int, digit_color: Color) -> void:
	var face_rows := [
		{"name": "FaceTop", "text": str(top_value), "position": Vector3(0.0, DICE_HALF + 0.044, 0.0), "rotation": Vector3(-PI * 0.5, 0.0, 0.0), "scale": 1.0},
	]
	for row in face_rows:
		var label := Label3D.new()
		label.name = str(row["name"])
		label.text = str(row["text"])
		label.position = row["position"]
		label.rotation = row["rotation"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.double_sided = true
		label.font_size = 96
		label.pixel_size = 0.0047 * float(row["scale"])
		label.modulate = digit_color
		label.outline_size = 10
		label.outline_modulate = Color(0.03, 0.04, 0.08, 0.74)
		parent.add_child(label)


func _save_scene(root: Node, path: String) -> bool:
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


func _set_existing(object: Object, names: Array, value) -> bool:
	var properties := {}
	for item in object.get_property_list():
		properties[item["name"]] = true
	for name in names:
		if properties.has(name):
			object.set(name, value)
			return true
	return false


func _save_resource_if_missing(resource: Resource, path: String) -> bool:
	if ResourceLoader.exists(path):
		return true
	return _save_resource(resource, path)


func _fract(value: float) -> float:
	return value - floor(value)


func _validate_outputs() -> bool:
	var ok := true
	ok = _check_resource("rounded d6 mesh", ROUNDED_MESH_PATH, "Mesh") and ok
	ok = _check_resource("rounded d6 preview scene", ROUNDED_PREVIEW_PATH, "PackedScene") and ok
	ok = _check_resource("star astrology disc scene", DISC_SCENE_PATH, "PackedScene") and ok
	ok = _check_resource("visual repro environment", ENVIRONMENT_PATH, "Environment") and ok
	ok = _check_resource("visual repro showcase scene", SHOWCASE_SCENE_PATH, "PackedScene") and ok
	for texture_name in STAGE_TEXTURE_NAMES:
		ok = _check_resource("stage disc texture %s" % texture_name, "%s/star_disc_%s.png" % [STAGE_TEXTURE_DIR, texture_name], "Texture2D") and ok
	for material_id in DICE_MATERIALS.keys():
		var spec: Dictionary = DICE_MATERIALS[material_id]
		ok = _check_resource("dice material %s" % material_id, str(spec["path"]), "Material") and ok
	for material_path in STAGE_MATERIAL_PATHS.values():
		ok = _check_resource("stage material %s" % material_path.get_file(), str(material_path), "Material") and ok

	var mesh := load(ROUNDED_MESH_PATH) as Mesh
	if mesh != null:
		var aabb := mesh.get_aabb()
		ok = _check("rounded d6 has one mesh surface", mesh.get_surface_count() == 1) and ok
		ok = _check("rounded d6 pivot is centered", aabb.position.distance_to(Vector3(-0.5, -0.5, -0.5)) <= 0.002 and aabb.size.distance_to(Vector3.ONE) <= 0.002) and ok

	var showcase_scene := load(SHOWCASE_SCENE_PATH) as PackedScene
	if showcase_scene != null:
		var state := showcase_scene.get_state()
		ok = _check("showcase has no script binding", not _scene_state_has_script(state)) and ok
		ok = _check("showcase has WorldEnvironment", _scene_state_has_node_name(state, "WorldEnvironment")) and ok
		ok = _check("showcase has PreviewCamera", _scene_state_has_node_name(state, "PreviewCamera")) and ok
		ok = _check("showcase has key light", _scene_state_has_node_name(state, "KeyLight")) and ok
		ok = _check("showcase has cool fill light", _scene_state_has_node_name(state, "CoolFillLight")) and ok
		ok = _check("showcase has cyan rim light", _scene_state_has_node_name(state, "CyanRimLight")) and ok
		ok = _check("showcase has soft top key role light", _scene_state_has_node_name(state, "SoftTopKeyLight")) and ok
		ok = _check("showcase has cool table bounce role light", _scene_state_has_node_name(state, "CoolTableBounceLight")) and ok
		ok = _check("showcase has warm gold edge kicker role light", _scene_state_has_node_name(state, "WarmGoldEdgeKickerLight")) and ok
		ok = _check("showcase has local glint role light", _scene_state_has_node_name(state, "LocalGlintHighlightLight")) and ok
		ok = _check("showcase has reflection reference role light", _scene_state_has_node_name(state, "ReflectionReferenceLight")) and ok
		ok = _check("showcase has gloss reflection probe", _scene_state_has_node_name(state, "GlossReflectionProbe")) and ok
		ok = _check("showcase has six rounded dice", _scene_state_count_nodes_with_prefix(state, "RoundedD6_") == 6) and ok
		ok = _check("showcase has dice body material layers", _scene_state_count_nodes_with_name(state, "BodyMaterialLayer") == 6) and ok
		ok = _check("showcase has edge/rim glow layers", _scene_state_count_nodes_with_name(state, "EdgeRimGlowLayer") == 6) and ok
		ok = _check("showcase has rounded bevel rails", _scene_state_count_nodes_with_prefix(state, "EdgeBevelRail") >= 72) and ok
		ok = _check("showcase has rounded bevel corner caps", _scene_state_count_nodes_with_prefix(state, "EdgeCornerBevelCap") >= 48) and ok
		ok = _check("showcase has face marker layers", _scene_state_count_nodes_with_name(state, "FaceMarkerLayer") == 6) and ok
		ok = _check("showcase has top face fills", _scene_state_count_nodes_with_name(state, "TopFaceFill") == 6) and ok
		ok = _check("showcase has front face fills", _scene_state_count_nodes_with_name(state, "FrontFaceFill") == 6) and ok
		ok = _check("showcase has side face fills", _scene_state_count_nodes_with_prefix(state, "SideFaceFill") >= 12) and ok
		ok = _check("showcase has top face panels", _scene_state_count_nodes_with_prefix(state, "TopFacePanel") >= 24) and ok
		ok = _check("showcase has front face panels", _scene_state_count_nodes_with_prefix(state, "FrontFacePanel") >= 24) and ok
		ok = _check("showcase has front star emblems", _scene_state_count_nodes_with_prefix(state, "FrontStarEmblem") >= 24) and ok
		ok = _check("showcase has state overlay layers", _scene_state_count_nodes_with_name(state, "StateOverlayLayer") == 6) and ok
		ok = _check("showcase has contact shadow layers", _scene_state_count_nodes_with_name(state, "ContactShadowLayer") == 6) and ok
		ok = _check("showcase has VA camera", _scene_state_has_node_name(state, "VA_Camera3D")) and ok
		ok = _check("showcase has VA camera markers", _scene_state_has_node_name(state, "VA_CameraMarkers")) and ok
		ok = _check("showcase has VA watermark layer", _scene_state_has_node_name(state, "VA_WatermarkLayer")) and ok
		ok = _check("showcase has VA watermark label", _scene_state_has_node_name(state, "VA_WatermarkLabel")) and ok
		ok = _check("showcase has full-scene VA marker", _scene_state_has_node_name(state, "battle_star_dice_repro_full")) and ok
		ok = _check("showcase has VA runner marker", _scene_state_has_node_name(state, "VA_ShaderLightAcceptanceRunner")) and ok
	var disc_scene := load(DISC_SCENE_PATH) as PackedScene
	if disc_scene != null:
		var disc_state := disc_scene.get_state()
		ok = _check("disc scene has textured top mesh", _scene_state_has_node_name(disc_state, "LitAstrologyDiscTop")) and ok
		ok = _check("disc scene has normal side mesh", _scene_state_has_node_name(disc_state, "LitAstrologyDiscSide")) and ok
		ok = _check("disc scene no longer uses separate gold ring geometry", not _scene_state_has_node_name(disc_state, "GoldRing")) and ok
	return ok


func _check_resource(label: String, path: String, expected_type: String) -> bool:
	var resource := load(path)
	var passed := false
	match expected_type:
		"Mesh":
			passed = resource is Mesh
		"PackedScene":
			passed = resource is PackedScene
		"Environment":
			passed = resource is Environment
		"Material":
			passed = resource is Material
		"Texture2D":
			passed = resource is Texture2D
		_:
			passed = resource != null
	return _check("%s loads: %s" % [label, path], passed)


func _check(label: String, passed: bool) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", label])
	if not passed:
		push_error(label)
	return passed


func _scene_state_has_script(state) -> bool:
	for node_index in range(state.get_node_count()):
		for property_index in range(state.get_node_property_count(node_index)):
			if str(state.get_node_property_name(node_index, property_index)) == "script" and state.get_node_property_value(node_index, property_index) != null:
				return true
	return false


func _scene_state_has_node_name(state, node_name: String) -> bool:
	for node_index in range(state.get_node_count()):
		if str(state.get_node_name(node_index)) == node_name:
			return true
	return false


func _scene_state_count_nodes_with_prefix(state, prefix: String) -> int:
	var count := 0
	for node_index in range(state.get_node_count()):
		if str(state.get_node_name(node_index)).begins_with(prefix):
			count += 1
	return count


func _scene_state_count_nodes_with_name(state, node_name: String) -> int:
	var count := 0
	for node_index in range(state.get_node_count()):
		if str(state.get_node_name(node_index)) == node_name:
			count += 1
	return count
