extends RefCounted
class_name GmDiceMaterialResolver


const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const RoundedDiceMeshFactory := preload("res://scripts/ui/debug/RoundedDiceMeshFactory.gd")


const STANDARD_D6_MESH_PATH := "res://assets/models/dice/standard_d6_mesh.tres"
const ROUNDED_DICE_BASE_GLB_PATH := "res://assets/models/dice/rounded_dice_base.glb"
const ROUNDED_D6_MESH_PATH := "res://assets/models/dice/rounded_d6_mesh.tres"
const PREVIEW_ROUNDED_D6_MESH_PATH := "res://assets/models/dice/preview_rounded_d6_body_mesh.tres"
const REPRO_DICE_SHADER_PATH := "res://assets/shaders/dice/repro_glow_dice.gdshader"
const LAYERED_BODY_SHADER_PATH := "res://assets/shaders/dice/dice_layered_body.gdshader"
const FACE_DIGIT_COLOR := Color(0.960784, 0.949020, 0.909804, 1.0)
const MATERIAL_RESOURCE_PATHS := {
	GmDiceDefinition.MATERIAL_REPRO_LAPIS: "res://assets/materials/dice/repro_lapis_dice.tres",
	GmDiceDefinition.MATERIAL_REPRO_BLUE: "res://assets/materials/dice/repro_blue_dice.tres",
	GmDiceDefinition.MATERIAL_REPRO_PURPLE: "res://assets/materials/dice/repro_purple_dice.tres",
	GmDiceDefinition.MATERIAL_REPRO_CYAN: "res://assets/materials/dice/repro_cyan_dice.tres",
	GmDiceDefinition.MATERIAL_REPRO_GOLD: "res://assets/materials/dice/repro_gold_dice.tres",
	GmDiceDefinition.MATERIAL_REPRO_SILVERWHITE: "res://assets/materials/dice/repro_silverwhite_dice.tres",
	GmDiceDefinition.MATERIAL_BRONZE: "res://assets/materials/dice/bronze_dice.tres",
	GmDiceDefinition.MATERIAL_GOLD: "res://assets/materials/dice/gold_dice.tres",
	GmDiceDefinition.MATERIAL_CRYSTAL: "res://assets/materials/dice/crystal_dice.tres",
}

static var _body_material_cache := {}
static var _body_mesh_cache: Mesh = null
static var _preview_mesh_cache: Mesh = null
static var _repro_shader_cache: Shader = null
static var _layered_body_shader_cache: Shader = null


static func get_material_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for option in GmDiceDefinition.get_material_options():
		var material_id := GmDiceDefinition.normalize_material_id(StringName(str(option.get("id", GmDiceDefinition.MATERIAL_STANDARD))))
		var path := material_resource_path(material_id)
		rows.append({
			"id": material_id,
			"id_text": str(material_id),
			"name": GmDiceDefinition.material_name(material_id),
			"resource_path": path,
			"has_resource": not path.is_empty() and ResourceLoader.exists(path),
			"programmatic": path.is_empty() or not ResourceLoader.exists(path),
			"mesh_path": preview_mesh_path(),
		})
	return rows


static func material_resource_path(material_id: StringName) -> String:
	var normalized_id := GmDiceDefinition.normalize_material_id(material_id)
	return str(MATERIAL_RESOURCE_PATHS.get(normalized_id, ""))


static func load_body_material(material_id: StringName) -> Material:
	var path := material_resource_path(material_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if _body_material_cache.has(path):
		return _body_material_cache[path] as Material
	var material := load(path) as Material
	if material != null:
		_body_material_cache[path] = material
	return material


static func load_body_mesh(_material_id: StringName = GmDiceDefinition.MATERIAL_STANDARD) -> Mesh:
	if _body_mesh_cache != null:
		return _body_mesh_cache
	if ResourceLoader.exists(ROUNDED_DICE_BASE_GLB_PATH):
		var glb_mesh := _load_first_mesh_from_scene(ROUNDED_DICE_BASE_GLB_PATH)
		if glb_mesh != null:
			_body_mesh_cache = glb_mesh
			return _body_mesh_cache
	if ResourceLoader.exists(ROUNDED_D6_MESH_PATH):
		_body_mesh_cache = load(ROUNDED_D6_MESH_PATH) as Mesh
		return _body_mesh_cache
	_body_mesh_cache = RoundedDiceMeshFactory.create_rounded_cube({
		"resource_name": "rounded_d6_mesh_runtime_fallback",
	})
	return _body_mesh_cache


static func preview_mesh_path() -> String:
	if ResourceLoader.exists(PREVIEW_ROUNDED_D6_MESH_PATH):
		return PREVIEW_ROUNDED_D6_MESH_PATH
	if ResourceLoader.exists(ROUNDED_D6_MESH_PATH):
		return ROUNDED_D6_MESH_PATH
	return ""


static func load_preview_mesh(_material_id: StringName = GmDiceDefinition.MATERIAL_STANDARD) -> Mesh:
	if _preview_mesh_cache != null:
		return _preview_mesh_cache
	var path := preview_mesh_path()
	if path.is_empty():
		_preview_mesh_cache = RoundedDiceMeshFactory.create_rounded_cube({
			"resource_name": "rounded_d6_preview_runtime_fallback",
		})
		return _preview_mesh_cache
	if path.ends_with(".glb"):
		var glb_mesh := _load_first_mesh_from_scene(path)
		if glb_mesh != null:
			_preview_mesh_cache = glb_mesh
			return _preview_mesh_cache
	_preview_mesh_cache = load(path) as Mesh
	return _preview_mesh_cache


static func _load_first_mesh_from_scene(path: String) -> Mesh:
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var root := packed.instantiate()
	var mesh := _find_first_mesh(root)
	root.free()
	return mesh


static func _find_first_mesh(node: Node) -> Mesh:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		return mesh_instance.mesh
	for child in node.get_children():
		var mesh := _find_first_mesh(child)
		if mesh != null:
			return mesh
	return null


static func make_body_material(body_color: Color, material_id: StringName) -> Material:
	var normalized_id := GmDiceDefinition.normalize_material_id(material_id)
	var resource_material := load_body_material(normalized_id)
	if resource_material != null:
		return resource_material
	var programmatic_material := make_programmatic_body_material(body_color, normalized_id)
	if programmatic_material != null:
		return programmatic_material
	return make_standard_fallback_material(body_color, normalized_id)


static func make_body_material_instance(
	body_color: Color,
	material_id: StringName,
	face_albedo_texture: Texture2D = null,
	face_layer_enabled := false
) -> Material:
	var material := make_body_material(body_color, material_id)
	if material == null:
		return null
	var instance := material.duplicate(true) as Material
	if face_layer_enabled and instance is BaseMaterial3D:
		instance = _make_layered_body_material_from_base(instance as BaseMaterial3D, body_color, material_id)
	_apply_face_layer_texture(instance, face_albedo_texture, face_layer_enabled)
	return instance


static func apply_face_layer_texture(material: Material, face_albedo_texture: Texture2D, enabled := true) -> void:
	_apply_face_layer_texture(material, face_albedo_texture, enabled)


static func make_edge_rim_material(material_id: StringName, fallback_color: Color = Color(0.80, 0.94, 1.00, 1.0)) -> StandardMaterial3D:
	var color := edge_rim_color(material_id, fallback_color)
	var material := StandardMaterial3D.new()
	material.resource_name = "gm_%s_edge_frame_layer" % str(GmDiceDefinition.normalize_material_id(material_id))
	material.albedo_color = Color(color.r * 0.58, color.g * 0.58, color.b * 0.60, 0.26)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = edge_rim_energy(material_id) * 0.24
	material.roughness = 0.42
	material.metallic = 0.0
	return material


static func edge_rim_color(material_id: StringName, fallback_color: Color = Color(0.80, 0.94, 1.00, 1.0)) -> Color:
	match GmDiceDefinition.normalize_material_id(material_id):
		GmDiceDefinition.MATERIAL_REPRO_LAPIS:
			return Color(1.00, 0.76, 0.30, 1.0)
		GmDiceDefinition.MATERIAL_REPRO_BLUE:
			return Color(0.58, 0.86, 1.00, 1.0)
		GmDiceDefinition.MATERIAL_REPRO_PURPLE:
			return Color(0.92, 0.56, 1.00, 1.0)
		GmDiceDefinition.MATERIAL_REPRO_CYAN:
			return Color(0.62, 1.00, 0.96, 1.0)
		GmDiceDefinition.MATERIAL_REPRO_GOLD:
			return Color(1.0, 0.973, 0.918, 1.0)
		GmDiceDefinition.MATERIAL_GOLD:
			return Color(0.96, 0.82, 0.36, 1.0)
		GmDiceDefinition.MATERIAL_REPRO_SILVERWHITE, GmDiceDefinition.MATERIAL_CRYSTAL:
			return Color(0.96, 1.00, 1.00, 1.0)
		GmDiceDefinition.MATERIAL_IRON:
			return Color(0.95, 0.84, 0.66, 1.0)
		GmDiceDefinition.MATERIAL_BRONZE:
			return Color(0.78, 0.54, 0.30, 1.0)
		GmDiceDefinition.MATERIAL_GLASS:
			return Color(0.82, 1.00, 1.00, 1.0)
		_:
			return fallback_color


static func edge_rim_energy(material_id: StringName) -> float:
	match GmDiceDefinition.normalize_material_id(material_id):
		GmDiceDefinition.MATERIAL_REPRO_LAPIS:
			return 0.09
		GmDiceDefinition.MATERIAL_REPRO_GOLD, GmDiceDefinition.MATERIAL_GOLD:
			return 0.08
		GmDiceDefinition.MATERIAL_REPRO_SILVERWHITE, GmDiceDefinition.MATERIAL_CRYSTAL:
			return 0.07
		GmDiceDefinition.MATERIAL_REPRO_BLUE, GmDiceDefinition.MATERIAL_REPRO_PURPLE, GmDiceDefinition.MATERIAL_REPRO_CYAN:
			return 0.085
		GmDiceDefinition.MATERIAL_GLASS:
			return 0.09
		_:
			return 0.07


static func make_programmatic_body_material(body_color: Color, material_id: StringName) -> Material:
	if not ResourceLoader.exists(REPRO_DICE_SHADER_PATH):
		return null
	var shader := _load_repro_shader()
	if shader == null:
		return null

	var normalized_id := GmDiceDefinition.normalize_material_id(material_id)
	var material := ShaderMaterial.new()
	material.resource_name = "gm_programmatic_%s_dice" % str(normalized_id)
	material.shader = shader

	var base := body_color
	var edge := Color(0.80, 0.94, 1.00, 1.0)
	var emission := Color(base.r * 0.55 + 0.10, base.g * 0.55 + 0.20, base.b * 0.70 + 0.22, 1.0)
	var metallic := 0.22
	var roughness := 0.34
	match normalized_id:
		GmDiceDefinition.MATERIAL_REPRO_LAPIS:
			base = Color(0.018, 0.095, 0.380, 1.0)
			edge = Color(1.00, 0.76, 0.30, 1.0)
			emission = Color(0.36, 0.58, 1.00, 1.0)
			metallic = 0.38
			roughness = 0.25
		GmDiceDefinition.MATERIAL_IRON:
			base = Color(0.70, 0.76, 0.84, 1.0)
			edge = Color(0.95, 1.00, 1.00, 1.0)
			emission = Color(0.36, 0.50, 0.70, 1.0)
			metallic = 0.55
			roughness = 0.34
		GmDiceDefinition.MATERIAL_GLASS:
			base = Color(0.42, 0.82, 1.00, 0.72)
			edge = Color(0.82, 1.00, 1.00, 1.0)
			emission = Color(0.18, 0.62, 1.00, 1.0)
			metallic = 0.04
			roughness = 0.22

	material.set_shader_parameter("base_color", base)
	material.set_shader_parameter("edge_color", edge)
	material.set_shader_parameter("emission_color", emission)
	material.set_shader_parameter("metallic", metallic)
	material.set_shader_parameter("roughness", roughness)
	material.set_shader_parameter("emission_strength", 0.10)
	material.set_shader_parameter("fresnel_strength", 0.62)
	material.set_shader_parameter("fresnel_power", 3.20)
	material.set_shader_parameter("surface_variation", 0.028)
	material.set_shader_parameter("face_detail_strength", 1.0)
	material.set_shader_parameter("edge_line_strength", 0.58)
	material.set_shader_parameter("corner_glint_strength", 0.24)
	material.set_shader_parameter("side_shadow_strength", 0.36)
	return material


static func make_standard_fallback_material(body_color: Color, material_id: StringName) -> StandardMaterial3D:
	var normalized_id := GmDiceDefinition.normalize_material_id(material_id)
	var material := StandardMaterial3D.new()
	match normalized_id:
		GmDiceDefinition.MATERIAL_IRON:
			material.albedo_color = Color(0.58, 0.63, 0.67)
			material.roughness = 0.32
			material.metallic = 0.52
			material.emission_enabled = true
			material.emission = Color(0.12, 0.16, 0.18)
			material.emission_energy_multiplier = 0.06
		GmDiceDefinition.MATERIAL_GLASS:
			material.albedo_color = Color(0.70, 0.92, 1.00, 0.66)
			material.roughness = 0.08
			material.metallic = 0.0
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.emission_enabled = true
			material.emission = Color(0.24, 0.64, 0.95)
			material.emission_energy_multiplier = 0.22
		GmDiceDefinition.MATERIAL_CRYSTAL:
			material.albedo_color = Color(0.52, 0.96, 1.00, 0.54)
			material.roughness = 0.025
			material.metallic = 0.0
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.emission_enabled = true
			material.emission = Color(0.34, 1.00, 0.92)
			material.emission_energy_multiplier = 0.48
		_:
			material.albedo_color = body_color
			material.roughness = 0.52
			material.metallic = 0.02
			material.emission_enabled = true
			material.emission = body_color.darkened(0.35)
			material.emission_energy_multiplier = 0.06
	return material


static func _make_layered_body_material_from_base(base_material: BaseMaterial3D, body_color: Color, material_id: StringName) -> Material:
	if not ResourceLoader.exists(LAYERED_BODY_SHADER_PATH):
		return base_material
	var shader := _load_layered_body_shader()
	if shader == null:
		return base_material
	var material := ShaderMaterial.new()
	var normalized_id := GmDiceDefinition.normalize_material_id(material_id)
	material.resource_name = "gm_%s_layered_body" % str(normalized_id)
	material.shader = shader
	material.render_priority = base_material.render_priority

	var base_albedo = base_material.get("albedo_color")
	material.set_shader_parameter("base_albedo", base_albedo if base_albedo is Color else body_color)
	_set_shader_texture_parameter(material, "albedo_texture", base_material.get("albedo_texture"), "albedo_texture_enabled")
	_set_shader_texture_parameter(material, "normal_texture", base_material.get("normal_texture"), "normal_texture_enabled")
	_set_shader_texture_parameter(material, "orm_texture", base_material.get("orm_texture"), "orm_texture_enabled")
	_set_shader_texture_parameter(material, "emission_texture", base_material.get("emission_texture"), "emission_texture_enabled")
	_set_shader_texture_parameter(material, "height_texture", base_material.get("heightmap_texture"), "height_texture_enabled")

	var emission = base_material.get("emission")
	material.set_shader_parameter("emission_color", emission if emission is Color else Color.BLACK)
	material.set_shader_parameter("emission_energy", float(base_material.get("emission_energy_multiplier")) if base_material.get("emission_energy_multiplier") != null else 0.0)
	material.set_shader_parameter("heightmap_scale", float(base_material.get("heightmap_scale")) if base_material.get("heightmap_scale") != null else 0.0)
	material.set_shader_parameter("metallic_value", float(base_material.get("metallic")) if base_material.get("metallic") != null else 0.0)
	material.set_shader_parameter("roughness_value", float(base_material.get("roughness")) if base_material.get("roughness") != null else 0.55)
	return material


static func _load_repro_shader() -> Shader:
	if _repro_shader_cache != null:
		return _repro_shader_cache
	_repro_shader_cache = load(REPRO_DICE_SHADER_PATH) as Shader
	return _repro_shader_cache


static func _load_layered_body_shader() -> Shader:
	if _layered_body_shader_cache != null:
		return _layered_body_shader_cache
	_layered_body_shader_cache = load(LAYERED_BODY_SHADER_PATH) as Shader
	return _layered_body_shader_cache


static func _set_shader_texture_parameter(material: ShaderMaterial, texture_parameter: String, value, enabled_parameter: String) -> void:
	if value is Texture2D:
		material.set_shader_parameter(texture_parameter, value)
		material.set_shader_parameter(enabled_parameter, 1.0)
	else:
		material.set_shader_parameter(enabled_parameter, 0.0)


static func _apply_face_layer_texture(material: Material, face_albedo_texture: Texture2D, enabled := true) -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null or shader_material.shader == null:
		return
	if not shader_material.shader.code.contains("face_albedo_texture"):
		return
	if face_albedo_texture != null:
		shader_material.set_shader_parameter("face_albedo_texture", face_albedo_texture)
	shader_material.set_shader_parameter("face_layer_enabled", 1.0 if enabled and face_albedo_texture != null else 0.0)
	shader_material.set_shader_parameter("face_layer_strength", 1.0)


static func face_label_color(material_id: StringName, fallback_color: Color = Color(0.12, 0.14, 0.18)) -> Color:
	return FACE_DIGIT_COLOR


static func face_label_outline_color(material_id: StringName) -> Color:
	match GmDiceDefinition.normalize_material_id(material_id):
		GmDiceDefinition.MATERIAL_REPRO_LAPIS:
			return Color(0.04, 0.025, 0.00, 0.88)
		GmDiceDefinition.MATERIAL_REPRO_BLUE:
			return Color(0.00, 0.05, 0.18, 0.84)
		GmDiceDefinition.MATERIAL_REPRO_PURPLE:
			return Color(0.08, 0.00, 0.16, 0.86)
		GmDiceDefinition.MATERIAL_REPRO_CYAN:
			return Color(0.00, 0.08, 0.10, 0.84)
		GmDiceDefinition.MATERIAL_REPRO_GOLD, GmDiceDefinition.MATERIAL_GOLD:
			return Color(0.16, 0.08, 0.00, 0.86)
		GmDiceDefinition.MATERIAL_REPRO_SILVERWHITE, GmDiceDefinition.MATERIAL_CRYSTAL:
			return Color(0.02, 0.05, 0.10, 0.82)
		_:
			return Color(0.03, 0.04, 0.08, 0.70)
