extends RefCounted


const CELL_SIZE := 128
const ATLAS_COLS := 3
const ATLAS_ROWS := 2
const TEX_WIDTH := CELL_SIZE * ATLAS_COLS
const TEX_HEIGHT := CELL_SIZE * ATLAS_ROWS
const MODEL_MESH_PATH := "res://assets/models/dice/standard_d6_mesh.tres"
const MODEL_SCENE_PATH := "res://assets/models/dice/standard_d6_preview.tscn"
const SHADER_PATH := "res://assets/shaders/dice/crystal_dice.gdshader"
const COMMON_PREVIEW_PATH := "res://assets/scenes/preview/dice_material_preview.tscn"
const SCREENSHOT_DIR := "res://assets/scenes/preview/preview_shots"
const MATERIAL_TEXTURE_NAMES := ["albedo", "normal", "orm", "emission", "height"]
const DATA_TEXTURE_NAMES := ["orm", "height", "flow_mask"]

const MATERIALS := {
	"bronze": {
		"display_name": "青铜骰子",
		"material_path": "res://assets/materials/dice/bronze_dice.tres",
		"texture_dir": "res://assets/textures/dice/bronze",
		"scene_path": "res://assets/scenes/preview/bronze_dice_preview.tscn",
		"base": Color(0.545098, 0.352941, 0.168627, 1.0),
		"dark": Color(0.30, 0.17, 0.08, 1.0),
		"edge": Color(0.72, 0.47, 0.24, 1.0),
		"accent": Color(0.12, 0.30, 0.23, 1.0),
		"pip": Color(0.055, 0.030, 0.018, 1.0),
		"metallic": 0.92,
		"roughness": 0.42,
		"roughness_body": 0.42,
		"roughness_panel": 0.46,
		"roughness_edge": 0.30,
		"normal_strength": 3.5,
	},
	"gold": {
		"display_name": "黄金骰子",
		"material_path": "res://assets/materials/dice/gold_dice.tres",
		"texture_dir": "res://assets/textures/dice/gold",
		"scene_path": "res://assets/scenes/preview/gold_dice_preview.tscn",
		"base": Color(0.850980, 0.713725, 0.227451, 1.0),
		"dark": Color(0.48, 0.35, 0.09, 1.0),
		"edge": Color(1.0, 0.86, 0.38, 1.0),
		"accent": Color(0.93, 0.66, 0.16, 1.0),
		"pip": Color(0.095, 0.055, 0.014, 1.0),
		"metallic": 0.97,
		"roughness": 0.24,
		"roughness_body": 0.24,
		"roughness_panel": 0.30,
		"roughness_edge": 0.14,
		"normal_strength": 2.9,
	},
	"crystal": {
		"display_name": "水晶骰子",
		"material_path": "res://assets/materials/dice/crystal_dice.tres",
		"texture_dir": "res://assets/textures/dice/crystal",
		"scene_path": "res://assets/scenes/preview/crystal_dice_preview.tscn",
		"base": Color(0.38, 0.86, 1.0, 0.52),
		"dark": Color(0.05, 0.18, 0.30, 0.42),
		"edge": Color(0.90, 1.0, 1.0, 0.68),
		"accent": Color(0.30, 0.96, 1.0, 0.80),
		"pip": Color(0.90, 1.0, 1.0, 0.85),
		"metallic": 0.0,
		"roughness": 0.16,
		"normal_strength": 3.0,
	},
}

var _ok := true
var _screenshot_jobs: Array[Dictionary] = []
var _active_viewport: SubViewport = null
var _active_path := ""
var _frames_left := 0
var _finished := false
var _tree: SceneTree = null


func run(tree: SceneTree) -> void:
	_tree = tree
	print("--- BuildDiceMaterialPipeline: start ---")
	_ok = _ensure_directories() and _ok
	if _ok:
		_normalize_texture_imports()
		_generate_all_textures()
		_save_standard_d6_mesh()
		_save_materials()
		_save_preview_scenes()
	_finish()


func process_step(_delta: float) -> bool:
	if _finished:
		return true
	if _active_viewport == null:
		if _screenshot_jobs.is_empty():
			_finish()
			return true
		_start_next_screenshot()
		return false
	_frames_left -= 1
	if _frames_left <= 0:
		_finish_active_screenshot()
	return false


func _ensure_directories() -> bool:
	var ok := true
	for path in [
		"res://assets/textures/dice/bronze",
		"res://assets/textures/dice/gold",
		"res://assets/textures/dice/crystal",
		"res://assets/materials/dice",
		"res://assets/shaders/dice",
		"res://assets/models/dice",
		"res://assets/scenes/preview",
		SCREENSHOT_DIR,
	]:
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
		if error != OK and error != ERR_ALREADY_EXISTS:
			push_error("无法创建目录：%s" % path)
			ok = false
	return ok


func _generate_all_textures() -> void:
	for material_id in MATERIALS.keys():
		var spec: Dictionary = MATERIALS[material_id]
		for texture_name in _texture_names_for_material(str(material_id)):
			var path := "%s/%s_dice_%s.png" % [spec["texture_dir"], material_id, texture_name]
			if not FileAccess.file_exists(path):
				_ok = false
				push_error("Missing generated texture: %s" % path)


func _texture_names_for_material(material_id: String) -> Array:
	var names := MATERIAL_TEXTURE_NAMES.duplicate()
	if material_id == "crystal":
		names.append("flow_mask")
	return names


func _normalize_texture_imports() -> void:
	for material_id in MATERIALS.keys():
		var spec: Dictionary = MATERIALS[material_id]
		for texture_name in _texture_names_for_material(str(material_id)):
			var texture_path := "%s/%s_dice_%s.png" % [spec["texture_dir"], material_id, texture_name]
			var import_path := "%s.import" % texture_path
			if not FileAccess.file_exists(import_path):
				continue
			var text := FileAccess.get_file_as_string(import_path)
			var is_normal: bool = texture_name == "normal"
			var is_data: bool = DATA_TEXTURE_NAMES.has(texture_name)
			text = _set_import_value(text, "compress/normal_map", "1" if is_normal else "0")
			text = _set_import_value(text, "mipmaps/generate", "true")
			text = _set_import_value(text, "roughness/mode", "1" if is_normal else "0")
			text = _set_import_value(text, "roughness/src_normal", "\"%s/%s_dice_normal.png\"" % [spec["texture_dir"], material_id] if is_normal else "\"\"")
			text = _set_import_value(text, "process/normal_map_invert_y", "false")
			text = _set_import_value(text, "process/hdr_as_srgb", "false")
			if is_data:
				text = _set_import_value(text, "compress/channel_pack", "0")
			var file := FileAccess.open(import_path, FileAccess.WRITE)
			if file == null:
				_ok = false
				push_error("Cannot write texture import settings: %s" % import_path)
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


func _generate_texture_set(material_id: String, spec: Dictionary) -> void:
	print("生成贴图：%s" % spec["display_name"])
	var albedo := Image.create(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8)
	var normal := Image.create(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8)
	var orm := Image.create(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8)
	var emission := Image.create(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8)
	var height := Image.create(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8)
	var flow := Image.create(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8)

	for y in TEX_HEIGHT:
		for x in TEX_WIDTH:
			var sample := _sample_surface(material_id, spec, x, y)
			albedo.set_pixel(x, y, sample["albedo"])
			normal.set_pixel(x, y, _normal_color(material_id, spec, x, y))
			orm.set_pixel(x, y, sample["orm"])
			emission.set_pixel(x, y, sample["emission"])
			var h: float = float(sample["height"])
			height.set_pixel(x, y, Color(h, h, h, 1.0))
			var f: float = float(sample["flow"])
			flow.set_pixel(x, y, Color(f, f, f, 1.0))

	_save_png(albedo, "%s/%s_dice_albedo.png" % [spec["texture_dir"], material_id])
	_save_png(normal, "%s/%s_dice_normal.png" % [spec["texture_dir"], material_id])
	_save_png(orm, "%s/%s_dice_orm.png" % [spec["texture_dir"], material_id])
	_save_png(emission, "%s/%s_dice_emission.png" % [spec["texture_dir"], material_id])
	_save_png(height, "%s/%s_dice_height.png" % [spec["texture_dir"], material_id])
	if material_id == "crystal":
		_save_png(flow, "%s/%s_dice_flow_mask.png" % [spec["texture_dir"], material_id])


func _save_png(image: Image, path: String) -> void:
	image.generate_mipmaps()
	var error := image.save_png(path)
	if error != OK:
		push_error("保存 PNG 失败：%s" % path)


func _sample_surface(material_id: String, spec: Dictionary, x: int, y: int) -> Dictionary:
	var uv := _cell_uv(x, y)
	var face_value := _face_value_at(x, y)
	var noise_low := _fbm(Vector2(float(x), float(y)) * 0.012 + _seed_offset(material_id))
	var noise_high := _fbm(Vector2(float(x), float(y)) * 0.055 + _seed_offset(material_id) * 1.7)
	var pip := _pip_mask(face_value, uv)
	var pip_rim := _pip_rim(face_value, uv)
	var edge := _edge_mask(uv)
	var center_distance := maxf(absf(uv.x - 0.5), absf(uv.y - 0.5))
	var panel := 1.0 - smoothstep(0.30, 0.48, center_distance)
	var scratch := _scratch_mask(material_id, uv, x, y)
	var crack := _crack_mask(material_id, uv, x, y)
	var patina := 0.0
	if material_id == "bronze":
		patina = clampf((noise_low - 0.48) * 3.8 + pip * 0.42 + edge * 0.18, 0.0, 1.0)
	var antique_dirt := clampf((1.0 - noise_low) * 0.36 + pip * 0.62 + scratch * 0.18, 0.0, 1.0)

	var base: Color = spec["base"]
	var dark: Color = spec["dark"]
	var edge_color: Color = spec["edge"]
	var accent: Color = spec["accent"]
	var pip_color: Color = spec["pip"]
	var color := base.lerp(dark, antique_dirt * 0.46)
	color = color.lerp(edge_color, clampf(edge * (0.34 + noise_high * 0.18) + pip_rim * 0.22, 0.0, 0.72))
	color = color.lerp(pip_color, pip * (0.74 if material_id != "crystal" else 0.40))
	if material_id == "bronze":
		color = color.lerp(accent, patina * 0.72)
	elif material_id == "gold":
		color = color.lerp(accent, clampf(scratch * 0.22 + (1.0 - edge) * 0.07, 0.0, 0.28))
	else:
		var flow_sample := _flow_value(uv, x, y)
		color = color.lerp(accent, clampf(flow_sample * 0.42 + crack * 0.30, 0.0, 0.70))
		color.a = 0.46 + edge * 0.14 + pip * 0.12

	var height_value := _height_value(material_id, spec, x, y)
	var roughness_body := float(spec.get("roughness_body", spec["roughness"]))
	var roughness_panel := float(spec.get("roughness_panel", roughness_body))
	var roughness_edge := float(spec.get("roughness_edge", roughness_body))
	var roughness := lerpf(lerpf(roughness_body, roughness_panel, panel), roughness_edge, edge)
	var metallic := float(spec["metallic"])
	var ao := clampf(0.92 - pip * 0.34 - scratch * 0.08 - crack * 0.14, 0.0, 1.0)
	if material_id == "bronze":
		roughness = clampf(roughness + patina * 0.055 + scratch * 0.035, 0.24, 0.58)
		metallic = clampf(metallic - patina * 0.13 - antique_dirt * 0.025, 0.72, 0.94)
	elif material_id == "gold":
		roughness = clampf(roughness + antique_dirt * 0.045 + scratch * 0.025, 0.12, 0.38)
		metallic = clampf(metallic - antique_dirt * 0.025 - scratch * 0.018, 0.90, 0.99)
	else:
		roughness = clampf(roughness + crack * 0.18 + pip * 0.10, 0.04, 0.46)
		metallic = 0.0

	var emission_color := Color(0, 0, 0, 1)
	var flow := 0.0
	if material_id == "bronze":
		emission_color = Color(0.02, 0.16, 0.10, 1.0) * clampf(patina * 0.32 + pip_rim * 0.06, 0.0, 0.40)
	elif material_id == "gold":
		emission_color = Color(1.0, 0.50, 0.12, 1.0) * clampf(edge * 0.10 + pip_rim * 0.08, 0.0, 0.22)
	else:
		flow = _flow_value(uv, x, y)
		emission_color = Color(0.34, 0.96, 1.0, 1.0) * clampf(flow * 0.86 + pip_rim * 0.58 + edge * 0.22, 0.0, 1.0)

	return {
		"albedo": color,
		"orm": Color(ao, roughness, metallic, 1.0),
		"emission": emission_color,
		"height": height_value,
		"flow": flow,
	}


func _height_value(material_id: String, spec: Dictionary, x: int, y: int) -> float:
	var uv := _cell_uv(x, y)
	var face_value := _face_value_at(x, y)
	var noise_low := _fbm(Vector2(float(x), float(y)) * 0.018 + _seed_offset(material_id))
	var noise_high := _fbm(Vector2(float(x), float(y)) * 0.070 + _seed_offset(material_id) * 0.67)
	var edge := _edge_mask(uv)
	var pip := _pip_mask(face_value, uv)
	var pip_rim := _pip_rim(face_value, uv)
	var scratch := _scratch_mask(material_id, uv, x, y)
	var crack := _crack_mask(material_id, uv, x, y)
	var h := 0.52 + (noise_low - 0.5) * 0.10 + (noise_high - 0.5) * 0.035
	h += edge * (0.12 if material_id != "crystal" else 0.075)
	h += pip_rim * 0.11
	h -= pip * (0.30 if material_id != "crystal" else 0.19)
	h -= scratch * (0.035 if material_id != "crystal" else 0.010)
	h += crack * (0.13 if material_id == "crystal" else 0.0)
	return clampf(h, 0.0, 1.0)


func _normal_color(material_id: String, spec: Dictionary, x: int, y: int) -> Color:
	var strength := float(spec["normal_strength"])
	var l := _height_value(material_id, spec, max(0, x - 1), y)
	var r := _height_value(material_id, spec, min(TEX_WIDTH - 1, x + 1), y)
	var u := _height_value(material_id, spec, x, max(0, y - 1))
	var d := _height_value(material_id, spec, x, min(TEX_HEIGHT - 1, y + 1))
	var n := Vector3((l - r) * strength, (u - d) * strength, 1.0).normalized()
	return Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0)


func _cell_uv(x: int, y: int) -> Vector2:
	return Vector2(float(x % CELL_SIZE) / float(CELL_SIZE - 1), float(y % CELL_SIZE) / float(CELL_SIZE - 1))


func _face_value_at(x: int, y: int) -> int:
	var col := clampi(x / CELL_SIZE, 0, ATLAS_COLS - 1)
	var row := clampi(y / CELL_SIZE, 0, ATLAS_ROWS - 1)
	return row * ATLAS_COLS + col + 1


func _pip_positions(value: int) -> Array[Vector2]:
	match value:
		1:
			return [Vector2(0.5, 0.5)]
		2:
			return [Vector2(0.30, 0.30), Vector2(0.70, 0.70)]
		3:
			return [Vector2(0.30, 0.30), Vector2(0.5, 0.5), Vector2(0.70, 0.70)]
		4:
			return [Vector2(0.30, 0.30), Vector2(0.70, 0.30), Vector2(0.30, 0.70), Vector2(0.70, 0.70)]
		5:
			return [Vector2(0.30, 0.30), Vector2(0.70, 0.30), Vector2(0.5, 0.5), Vector2(0.30, 0.70), Vector2(0.70, 0.70)]
		6:
			return [Vector2(0.30, 0.24), Vector2(0.70, 0.24), Vector2(0.30, 0.5), Vector2(0.70, 0.5), Vector2(0.30, 0.76), Vector2(0.70, 0.76)]
	return []


func _pip_mask(value: int, uv: Vector2) -> float:
	var result := 0.0
	for pos in _pip_positions(value):
		var dist := uv.distance_to(pos)
		result = maxf(result, 1.0 - smoothstep(0.055, 0.082, dist))
	return clampf(result, 0.0, 1.0)


func _pip_rim(value: int, uv: Vector2) -> float:
	var result := 0.0
	for pos in _pip_positions(value):
		var dist := uv.distance_to(pos)
		var outer := 1.0 - smoothstep(0.074, 0.104, dist)
		var inner := 1.0 - smoothstep(0.046, 0.068, dist)
		result = maxf(result, clampf(outer - inner, 0.0, 1.0))
	return clampf(result, 0.0, 1.0)


func _edge_mask(uv: Vector2) -> float:
	var edge_distance := minf(minf(uv.x, 1.0 - uv.x), minf(uv.y, 1.0 - uv.y))
	return pow(1.0 - smoothstep(0.018, 0.135, edge_distance), 1.65)


func _scratch_mask(material_id: String, uv: Vector2, x: int, y: int) -> float:
	var seed := _seed_offset(material_id)
	var grain := _fbm(Vector2(float(x), float(y)) * Vector2(0.060, 0.018) + seed * 2.1)
	var line_a := absf(sin((uv.x * 18.0 + uv.y * 7.0 + grain * 2.8 + seed.x) * PI))
	var line_b := absf(sin((uv.x * -9.0 + uv.y * 21.0 + seed.y) * PI))
	var scratch := 1.0 - smoothstep(0.030, 0.090, minf(line_a, line_b))
	return clampf(scratch * smoothstep(0.50, 0.86, grain), 0.0, 1.0)


func _crack_mask(material_id: String, uv: Vector2, x: int, y: int) -> float:
	if material_id != "crystal":
		return 0.0
	var seed := _seed_offset(material_id)
	var diagonal := absf(_fract((uv.x * 2.35 + uv.y * 1.65 + _fbm(Vector2(float(x), float(y)) * 0.015 + seed)) * 4.0) - 0.5)
	var fine := 1.0 - smoothstep(0.025, 0.085, diagonal)
	var gate := smoothstep(0.47, 0.80, _fbm(Vector2(float(x), float(y)) * 0.033 + seed * 1.9))
	return clampf(fine * gate, 0.0, 1.0)


func _flow_value(uv: Vector2, x: int, y: int) -> float:
	var noise := _fbm(Vector2(float(x), float(y)) * 0.019 + Vector2(9.1, 4.7))
	var band := sin((uv.x * 3.4 + uv.y * 4.8 + noise * 1.7) * TAU)
	var ribbon := smoothstep(0.58, 0.98, band * 0.5 + 0.5)
	var vein := smoothstep(0.62, 0.91, _crack_mask("crystal", uv, x, y))
	return clampf(maxf(ribbon * 0.82, vein), 0.0, 1.0)


func _seed_offset(material_id: String) -> Vector2:
	match material_id:
		"bronze":
			return Vector2(12.37, 4.91)
		"gold":
			return Vector2(31.20, 16.84)
		"crystal":
			return Vector2(7.73, 27.51)
	return Vector2.ZERO


func _fbm(p: Vector2) -> float:
	var value := 0.0
	var amplitude := 0.5
	var frequency := 1.0
	for _i in 3:
		value += _smooth_noise(p * frequency) * amplitude
		frequency *= 2.03
		amplitude *= 0.5
	return clampf(value, 0.0, 1.0)


func _smooth_noise(p: Vector2) -> float:
	var i := Vector2(floor(p.x), floor(p.y))
	var f := Vector2(_fract(p.x), _fract(p.y))
	var u := f * f * (Vector2(3.0, 3.0) - 2.0 * f)
	var a := _hash21(i)
	var b := _hash21(i + Vector2(1.0, 0.0))
	var c := _hash21(i + Vector2(0.0, 1.0))
	var d := _hash21(i + Vector2(1.0, 1.0))
	return lerpf(lerpf(a, b, u.x), lerpf(c, d, u.x), u.y)


func _hash21(p: Vector2) -> float:
	return _fract(sin(p.dot(Vector2(127.1, 311.7))) * 43758.5453123)


func _fract(value: float) -> float:
	return value - floor(value)


func _save_standard_d6_mesh() -> void:
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	_add_cube_face(vertices, normals, uvs, indices, 1, Vector3.UP, [
		Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5),
	])
	_add_cube_face(vertices, normals, uvs, indices, 6, Vector3.DOWN, [
		Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.5, -0.5, -0.5), Vector3(-0.5, -0.5, -0.5),
	])
	_add_cube_face(vertices, normals, uvs, indices, 2, Vector3.FORWARD, [
		Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, 0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(0.5, -0.5, 0.5),
	])
	_add_cube_face(vertices, normals, uvs, indices, 5, Vector3.BACK, [
		Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5), Vector3(-0.5, 0.5, -0.5), Vector3(-0.5, -0.5, -0.5),
	])
	_add_cube_face(vertices, normals, uvs, indices, 3, Vector3.RIGHT, [
		Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(0.5, 0.5, -0.5), Vector3(0.5, -0.5, -0.5),
	])
	_add_cube_face(vertices, normals, uvs, indices, 4, Vector3.LEFT, [
		Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, 0.5, -0.5), Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, -0.5, 0.5),
	])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.resource_name = "standard_d6_mesh"
	var error := ResourceSaver.save(mesh, MODEL_MESH_PATH)
	if error != OK:
		push_error("保存骰子模型失败：%s" % MODEL_MESH_PATH)

	var root := Node3D.new()
	root.name = "StandardD6PreviewModel"
	var dice := MeshInstance3D.new()
	dice.name = "DiceMesh"
	dice.mesh = mesh
	root.add_child(dice)
	_save_scene(root, MODEL_SCENE_PATH)
	root.free()


func _add_cube_face(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, value: int, normal: Vector3, corners: Array) -> void:
	var start := vertices.size()
	var uv_rect := _uv_rect_for_value(value)
	var face_uvs := [
		Vector2(uv_rect.position.x, uv_rect.end.y),
		Vector2(uv_rect.position.x, uv_rect.position.y),
		Vector2(uv_rect.end.x, uv_rect.position.y),
		Vector2(uv_rect.end.x, uv_rect.end.y),
	]
	for i in 4:
		vertices.append(corners[i])
		normals.append(normal)
		uvs.append(face_uvs[i])
	indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))


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


func _save_materials() -> void:
	_save_orm_material("bronze", MATERIALS["bronze"])
	_save_orm_material("gold", MATERIALS["gold"])
	_save_crystal_material()


func _save_orm_material(material_id: String, spec: Dictionary) -> void:
	var material = ClassDB.instantiate("ORMMaterial3D") if ClassDB.class_exists("ORMMaterial3D") else StandardMaterial3D.new()
	material.resource_name = "%s_dice" % material_id
	material.albedo_color = spec["base"]
	material.metallic = float(spec["metallic"])
	material.roughness = float(spec["roughness"])
	_set_existing(material, ["albedo_texture"], _load_texture("%s/%s_dice_albedo.png" % [spec["texture_dir"], material_id]))
	_set_existing(material, ["orm_texture"], _load_texture("%s/%s_dice_orm.png" % [spec["texture_dir"], material_id]))
	_set_existing(material, ["normal_enabled"], true)
	_set_existing(material, ["normal_texture"], _load_texture("%s/%s_dice_normal.png" % [spec["texture_dir"], material_id]))
	_set_existing(material, ["heightmap_enabled"], true)
	_set_existing(material, ["heightmap_texture"], _load_texture("%s/%s_dice_height.png" % [spec["texture_dir"], material_id]))
	_set_existing(material, ["heightmap_scale"], 0.020 if material_id == "gold" else 0.026)
	_set_existing(material, ["emission_enabled"], true)
	_set_existing(material, ["emission"], Color(0.16, 0.10, 0.04, 1.0) if material_id == "gold" else Color(0.025, 0.10, 0.07, 1.0))
	_set_existing(material, ["emission_energy_multiplier"], 0.09 if material_id == "gold" else 0.08)
	_set_existing(material, ["emission_texture"], _load_texture("%s/%s_dice_emission.png" % [spec["texture_dir"], material_id]))
	var error := ResourceSaver.save(material, spec["material_path"])
	if error != OK:
		push_error("保存材质失败：%s" % spec["material_path"])


func _save_crystal_material() -> void:
	var spec: Dictionary = MATERIALS["crystal"]
	var shader := load(SHADER_PATH) as Shader
	var material := ShaderMaterial.new()
	material.resource_name = "crystal_dice"
	material.shader = shader
	for texture_name in ["albedo", "normal", "orm", "emission", "height"]:
		material.set_shader_parameter("%s_texture" % texture_name, _load_texture("%s/crystal_dice_%s.png" % [spec["texture_dir"], texture_name]))
	material.set_shader_parameter("flow_mask_texture", _load_texture("%s/crystal_dice_flow_mask.png" % spec["texture_dir"]))
	material.set_shader_parameter("alpha_base", 0.42)
	material.set_shader_parameter("emission_power", 1.15)
	material.set_shader_parameter("fresnel_power", 3.2)
	material.set_shader_parameter("flow_speed", 0.18)
	material.set_shader_parameter("glow_color", Color(0.30, 0.95, 1.00, 1.0))
	material.set_shader_parameter("tint_color", Color(0.45, 0.88, 1.00, 1.0))
	var error := ResourceSaver.save(material, spec["material_path"])
	if error != OK:
		push_error("保存材质失败：%s" % spec["material_path"])


func _load_texture(path: String) -> Texture2D:
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("贴图无法加载：%s" % path)
	return texture


func _set_existing(object: Object, names: Array, value) -> bool:
	var properties := {}
	for item in object.get_property_list():
		properties[item["name"]] = true
	for name in names:
		if properties.has(name):
			object.set(name, value)
			return true
	return false


func _save_preview_scenes() -> void:
	for material_id in ["bronze", "gold", "crystal"]:
		var spec: Dictionary = MATERIALS[material_id]
		var root := _make_preview_root("%sDicePreview" % material_id.capitalize(), spec["material_path"], 0.0, "neutral")
		_save_scene(root, spec["scene_path"])
		root.free()
	var showcase := _make_showcase_root()
	_save_scene(showcase, COMMON_PREVIEW_PATH)
	showcase.free()


func _make_showcase_root() -> Node3D:
	var root := Node3D.new()
	root.name = "DiceMaterialPreview"
	_add_environment(root, "neutral")
	_add_camera(root, Vector3(0.0, 2.2, 5.1), Vector3(0.0, 0.26, 0.0), 42.0)
	_add_preview_floor(root, Vector3(0.0, -0.55, 0.0), Vector3(5.9, 0.08, 2.5))
	var x_positions := [-1.75, 0.0, 1.75]
	var ids := ["bronze", "gold", "crystal"]
	for i in ids.size():
		var spec: Dictionary = MATERIALS[ids[i]]
		var dice := _make_dice_mesh(spec["material_path"])
		dice.name = "%sDiceMesh" % str(ids[i]).capitalize()
		dice.position = Vector3(x_positions[i], 0.10, 0.0)
		dice.rotation_degrees = Vector3(-18.0, 34.0, 10.0)
		root.add_child(dice)
	return root


func _make_preview_root(root_name: String, material_path: String, x_position: float, light_mode: String) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	_add_environment(root, light_mode)
	_add_camera(root, Vector3(2.35, 1.85, 3.45), Vector3(0.0, 0.08, 0.0), 37.0)
	_add_preview_floor(root, Vector3(0.0, -0.55, 0.0), Vector3(3.1, 0.08, 2.25))
	var dice := _make_dice_mesh(material_path)
	dice.position = Vector3(x_position, 0.05, 0.0)
	dice.rotation_degrees = Vector3(-18.0, 36.0, 12.0)
	root.add_child(dice)
	return root


func _add_environment(root: Node3D, light_mode: String) -> void:
	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	match light_mode:
		"bright":
			env.background_color = Color(0.78, 0.80, 0.84)
			env.ambient_light_color = Color(0.92, 0.90, 0.86)
			env.ambient_light_energy = 1.25
		"dark":
			env.background_color = Color(0.030, 0.032, 0.044)
			env.ambient_light_color = Color(0.24, 0.22, 0.20)
			env.ambient_light_energy = 0.42
		_:
			env.background_color = Color(0.18, 0.18, 0.22)
			env.ambient_light_color = Color(0.62, 0.58, 0.52)
			env.ambient_light_energy = 0.78
	_set_existing(env, ["ambient_light_sky_contribution"], 0.20 if light_mode != "dark" else 0.30)
	_set_existing(env, ["reflected_light_source"], 0)
	_set_existing(env, ["glow_enabled"], true)
	_set_existing(env, ["glow_intensity"], 0.48 if light_mode != "dark" else 0.72)
	_set_existing(env, ["glow_strength"], 0.82)
	_set_existing(env, ["glow_bloom"], 0.18 if light_mode == "dark" else 0.10)
	env_node.environment = env
	root.add_child(env_node)

	var key := DirectionalLight3D.new()
	key.name = "DirectionalLight3D"
	key.rotation_degrees = Vector3(-46.0, 36.0, 0.0)
	key.light_energy = 4.0 if light_mode == "bright" else (1.25 if light_mode == "dark" else 2.35)
	key.shadow_enabled = true
	root.add_child(key)

	var aux := OmniLight3D.new()
	aux.name = "AuxPointLight"
	aux.position = Vector3(-2.0, 1.6, 2.2)
	aux.light_color = Color(0.62, 0.86, 1.0)
	aux.light_energy = 1.75 if light_mode != "dark" else 0.70
	aux.omni_range = 5.8
	root.add_child(aux)

	var rim := OmniLight3D.new()
	rim.name = "RimGlowLight"
	rim.position = Vector3(2.4, 1.5, -1.9)
	rim.light_color = Color(0.30, 0.95, 1.0)
	rim.light_energy = 1.25 if light_mode != "bright" else 0.80
	rim.omni_range = 5.2
	root.add_child(rim)

	var metal_fill := OmniLight3D.new()
	metal_fill.name = "MetalReflectionFillLight"
	metal_fill.position = Vector3(0.8, 1.15, 2.6)
	metal_fill.light_color = Color(1.0, 0.78, 0.46)
	metal_fill.light_energy = 0.55 if light_mode != "dark" else 0.42
	metal_fill.light_specular = 0.45
	metal_fill.omni_range = 4.8
	metal_fill.shadow_enabled = false
	root.add_child(metal_fill)


func _add_camera(root: Node3D, position: Vector3, target: Vector3, fov: float) -> void:
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.position = position
	camera.fov = fov
	camera.near = 0.05
	camera.far = 50.0
	camera.current = true
	camera.look_at_from_position(position, target, Vector3.UP)
	root.add_child(camera)


func _add_preview_floor(root: Node3D, position: Vector3, size: Vector3) -> void:
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "PreviewFloor"
	var mesh := BoxMesh.new()
	mesh.size = size
	floor_mesh.mesh = mesh
	floor_mesh.position = position
	floor_mesh.material_override = _make_floor_material()
	root.add_child(floor_mesh)


func _make_floor_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.20, 0.23, 1.0)
	material.roughness = 0.74
	material.metallic = 0.0
	return material


func _make_dice_mesh(material_path: String) -> MeshInstance3D:
	var dice := MeshInstance3D.new()
	dice.name = "DiceMesh"
	dice.mesh = load(MODEL_MESH_PATH)
	dice.material_override = load(material_path)
	return dice


func _save_scene(root: Node, path: String) -> void:
	_set_scene_owner(root, root)
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("打包场景失败：%s" % path)
		return
	var save_error := ResourceSaver.save(packed, path)
	if save_error != OK:
		push_error("保存场景失败：%s" % path)


func _set_scene_owner(node: Node, owner: Node) -> void:
	if node != owner:
		node.owner = owner
	for child in node.get_children():
		_set_scene_owner(child, owner)


func _prepare_screenshot_jobs() -> void:
	for material_id in ["bronze", "gold", "crystal"]:
		var spec: Dictionary = MATERIALS[material_id]
		for light_mode in ["bright", "neutral", "dark"]:
			_screenshot_jobs.append({
				"material_id": material_id,
				"material_path": spec["material_path"],
				"light_mode": light_mode,
			})


func _start_next_screenshot() -> void:
	var job: Dictionary = _screenshot_jobs.pop_front()
	var material_id: String = str(job["material_id"])
	var material_path: String = str(job["material_path"])
	var light_mode: String = str(job["light_mode"])
	_active_path = "%s/%s_dice_%s.png" % [SCREENSHOT_DIR, material_id, light_mode]
	var viewport := SubViewport.new()
	viewport.name = "%s_%s_CaptureViewport" % [material_id, light_mode]
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	_tree.root.add_child(viewport)
	var world := _make_preview_root("%s_%s_CaptureRoot" % [material_id, light_mode], material_path, 0.0, light_mode)
	viewport.add_child(world)
	_active_viewport = viewport
	_frames_left = 4


func _finish_active_screenshot() -> void:
	var viewport_texture := _active_viewport.get_texture()
	if viewport_texture == null:
		push_error("Screenshot viewport texture unavailable: %s" % _active_path)
		_ok = false
		_active_viewport.queue_free()
		_active_viewport = null
		_active_path = ""
		return
	var image := viewport_texture.get_image()
	if image == null:
		push_error("Screenshot image unavailable: %s" % _active_path)
		_ok = false
		_active_viewport.queue_free()
		_active_viewport = null
		_active_path = ""
		return
	var error := image.save_png(_active_path)
	if error != OK:
		push_error("Save screenshot failed: %s" % _active_path)
		_ok = false
	else:
		print("Saved screenshot: %s" % _active_path)
	_active_viewport.queue_free()
	_active_viewport = null
	_active_path = ""


func _finish() -> void:
	_finished = true
	print("PASS: BuildDiceMaterialPipeline" if _ok else "FAIL: BuildDiceMaterialPipeline")
	print("--- BuildDiceMaterialPipeline: end ---")
	_tree.quit(0 if _ok else 1)
