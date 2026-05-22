extends RefCounted
class_name GmDiceMaterialResolver


const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")


const ROUNDED_D6_MESH_PATH := "res://assets/models/dice/rounded_d6_mesh.tres"
const REPRO_DICE_SHADER_PATH := "res://assets/shaders/dice/repro_glow_dice.gdshader"
const MATERIAL_RESOURCE_PATHS := {
	GmDiceDefinition.MATERIAL_REPRO_BLUE: "res://assets/materials/dice/repro_blue_dice.tres",
	GmDiceDefinition.MATERIAL_REPRO_PURPLE: "res://assets/materials/dice/repro_purple_dice.tres",
	GmDiceDefinition.MATERIAL_REPRO_CYAN: "res://assets/materials/dice/repro_cyan_dice.tres",
	GmDiceDefinition.MATERIAL_REPRO_GOLD: "res://assets/materials/dice/repro_gold_dice.tres",
	GmDiceDefinition.MATERIAL_REPRO_SILVERWHITE: "res://assets/materials/dice/repro_silverwhite_dice.tres",
	GmDiceDefinition.MATERIAL_BRONZE: "res://assets/materials/dice/bronze_dice.tres",
	GmDiceDefinition.MATERIAL_GOLD: "res://assets/materials/dice/gold_dice.tres",
	GmDiceDefinition.MATERIAL_CRYSTAL: "res://assets/materials/dice/crystal_dice.tres",
}


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
			"mesh_path": ROUNDED_D6_MESH_PATH if ResourceLoader.exists(ROUNDED_D6_MESH_PATH) else "",
		})
	return rows


static func material_resource_path(material_id: StringName) -> String:
	var normalized_id := GmDiceDefinition.normalize_material_id(material_id)
	return str(MATERIAL_RESOURCE_PATHS.get(normalized_id, ""))


static func load_body_material(material_id: StringName) -> Material:
	var path := material_resource_path(material_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Material


static func load_body_mesh(_material_id: StringName = GmDiceDefinition.MATERIAL_STANDARD) -> Mesh:
	if not ResourceLoader.exists(ROUNDED_D6_MESH_PATH):
		return null
	return load(ROUNDED_D6_MESH_PATH) as Mesh


static func make_body_material(body_color: Color, material_id: StringName) -> Material:
	var normalized_id := GmDiceDefinition.normalize_material_id(material_id)
	var resource_material := load_body_material(normalized_id)
	if resource_material != null:
		return resource_material
	var programmatic_material := make_programmatic_body_material(body_color, normalized_id)
	if programmatic_material != null:
		return programmatic_material
	return make_standard_fallback_material(body_color, normalized_id)


static func make_programmatic_body_material(body_color: Color, material_id: StringName) -> Material:
	if not ResourceLoader.exists(REPRO_DICE_SHADER_PATH):
		return null
	var shader := load(REPRO_DICE_SHADER_PATH) as Shader
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
	var roughness := 0.28
	match normalized_id:
		GmDiceDefinition.MATERIAL_IRON:
			base = Color(0.70, 0.76, 0.84, 1.0)
			edge = Color(0.95, 1.00, 1.00, 1.0)
			emission = Color(0.36, 0.50, 0.70, 1.0)
			metallic = 0.55
			roughness = 0.26
		GmDiceDefinition.MATERIAL_GLASS:
			base = Color(0.42, 0.82, 1.00, 0.72)
			edge = Color(0.82, 1.00, 1.00, 1.0)
			emission = Color(0.18, 0.62, 1.00, 1.0)
			metallic = 0.04
			roughness = 0.12

	material.set_shader_parameter("base_color", base)
	material.set_shader_parameter("edge_color", edge)
	material.set_shader_parameter("emission_color", emission)
	material.set_shader_parameter("metallic", metallic)
	material.set_shader_parameter("roughness", roughness)
	material.set_shader_parameter("emission_strength", 0.24)
	material.set_shader_parameter("fresnel_strength", 1.10)
	material.set_shader_parameter("fresnel_power", 2.75)
	material.set_shader_parameter("surface_variation", 0.028)
	material.set_shader_parameter("face_detail_strength", 1.0)
	material.set_shader_parameter("edge_line_strength", 1.0)
	material.set_shader_parameter("corner_glint_strength", 0.45)
	material.set_shader_parameter("side_shadow_strength", 0.24)
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


static func face_label_color(material_id: StringName, fallback_color: Color = Color(0.12, 0.14, 0.18)) -> Color:
	match GmDiceDefinition.normalize_material_id(material_id):
		GmDiceDefinition.MATERIAL_REPRO_GOLD, GmDiceDefinition.MATERIAL_GOLD:
			return Color(1.00, 0.96, 0.74, 1.0)
		GmDiceDefinition.MATERIAL_REPRO_PURPLE:
			return Color(0.98, 0.88, 1.00, 1.0)
		GmDiceDefinition.MATERIAL_REPRO_CYAN:
			return Color(0.78, 1.00, 0.96, 1.0)
		GmDiceDefinition.MATERIAL_REPRO_BLUE, GmDiceDefinition.MATERIAL_REPRO_SILVERWHITE, GmDiceDefinition.MATERIAL_CRYSTAL:
			return Color(0.86, 0.95, 1.00, 1.0)
		_:
			return fallback_color


static func face_label_outline_color(material_id: StringName) -> Color:
	match GmDiceDefinition.normalize_material_id(material_id):
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
