extends RefCounted
class_name BattleStarDiceMaterialFactory


const MATERIAL_ORDER := ["blue", "purple", "teal", "gold", "white"]
const MATERIAL_SPECS := {
	"blue": {
		"name": "battle_star_dice_blue",
		"base_albedo": Color(0.035, 0.145, 0.560, 1.0),
		"edge_color": Color(0.55, 0.84, 1.0, 1.0),
		"emission_color": Color(0.10, 0.48, 1.0, 1.0),
		"metallic": 0.24,
		"roughness": 0.30,
		"emission_energy": 0.62,
		"emission_mask_power": 1.12,
		"fake_normal_strength": 0.34,
	},
	"purple": {
		"name": "battle_star_dice_purple",
		"base_albedo": Color(0.245, 0.045, 0.520, 1.0),
		"edge_color": Color(0.92, 0.55, 1.0, 1.0),
		"emission_color": Color(0.70, 0.20, 1.0, 1.0),
		"metallic": 0.20,
		"roughness": 0.31,
		"emission_energy": 0.66,
		"emission_mask_power": 1.18,
		"fake_normal_strength": 0.36,
	},
	"teal": {
		"name": "battle_star_dice_teal",
		"base_albedo": Color(0.010, 0.315, 0.330, 1.0),
		"edge_color": Color(0.58, 1.0, 0.94, 1.0),
		"emission_color": Color(0.06, 0.92, 0.88, 1.0),
		"metallic": 0.18,
		"roughness": 0.32,
		"emission_energy": 0.58,
		"emission_mask_power": 1.04,
		"fake_normal_strength": 0.32,
	},
	"gold": {
		"name": "battle_star_dice_gold",
		"base_albedo": Color(0.909804, 0.847059, 0.686275, 1.0),
		"edge_color": Color(1.0, 0.973, 0.918, 1.0),
		"emission_color": Color(0.960784, 0.949020, 0.909804, 1.0),
		"metallic": 0.96,
		"roughness": 0.18,
		"roughness_body": 0.18,
		"roughness_panel": 0.24,
		"roughness_edge": 0.10,
		"emission_energy": 0.50,
		"emission_mask_power": 1.00,
		"fake_normal_strength": 0.30,
		"panel_shadow_strength": 0.22,
	},
	"white": {
		"name": "battle_star_dice_white",
		"base_albedo": Color(0.640, 0.735, 0.900, 1.0),
		"edge_color": Color(0.98, 1.0, 1.0, 1.0),
		"emission_color": Color(0.50, 0.74, 1.0, 1.0),
		"metallic": 0.36,
		"roughness": 0.30,
		"emission_energy": 0.44,
		"emission_mask_power": 0.94,
		"fake_normal_strength": 0.28,
	},
}


static func material_path(output_dir: String, material_id: String) -> String:
	var spec: Dictionary = MATERIAL_SPECS.get(material_id, MATERIAL_SPECS["blue"])
	return output_dir.path_join("%s.tres" % str(spec["name"]))


static func save_materials(shader_path: String, output_dir: String) -> bool:
	var shader := load(shader_path) as Shader
	if shader == null:
		push_error("Cannot load battle star dice shader: %s" % shader_path)
		return false
	var ok := true
	for material_id in MATERIAL_ORDER:
		var material := make_body_material(material_id, shader)
		var error := ResourceSaver.save(material, material_path(output_dir, material_id))
		if error != OK:
			push_error("Cannot save battle star dice material: %s" % material_id)
			ok = false
	return ok


static func make_body_material(material_id: String, shader: Shader) -> ShaderMaterial:
	var spec: Dictionary = MATERIAL_SPECS.get(material_id, MATERIAL_SPECS["blue"])
	var material := ShaderMaterial.new()
	material.resource_name = str(spec["name"])
	material.shader = shader
	material.set_shader_parameter("base_albedo", spec["base_albedo"])
	material.set_shader_parameter("edge_color", spec["edge_color"])
	material.set_shader_parameter("emission_color", spec["emission_color"])
	material.set_shader_parameter("metallic_value", float(spec["metallic"]))
	material.set_shader_parameter("roughness_value", float(spec.get("roughness_body", spec["roughness"])))
	material.set_shader_parameter("emission_energy", float(spec["emission_energy"]))
	material.set_shader_parameter("emission_mask_power", float(spec["emission_mask_power"]))
	material.set_shader_parameter("fake_normal_strength", float(spec["fake_normal_strength"]))
	material.set_shader_parameter("panel_shadow_strength", float(spec.get("panel_shadow_strength", 0.36)))
	material.set_shader_parameter("micro_detail_strength", 0.055)
	return material


static func make_panel_fill_material(material_id: String, side_darkening: float = 0.0) -> StandardMaterial3D:
	var spec: Dictionary = MATERIAL_SPECS.get(material_id, MATERIAL_SPECS["blue"])
	var base: Color = spec["base_albedo"]
	var edge: Color = spec["edge_color"]
	var fill := base.lerp(edge, 0.14).darkened(side_darkening)
	var material := StandardMaterial3D.new()
	material.resource_name = "battle_star_%s_panel_fill" % material_id
	material.albedo_color = fill
	material.roughness = float(spec.get("roughness_panel", clampf(float(spec["roughness"]) + 0.10, 0.0, 1.0)))
	material.metallic = clampf(float(spec["metallic"]) * 0.42, 0.0, 1.0)
	material.emission_enabled = true
	material.emission = edge.darkened(0.62)
	material.emission_energy_multiplier = 0.055
	return material


static func make_glow_line_material(material_id: String, energy_scale: float = 1.0) -> StandardMaterial3D:
	var spec: Dictionary = MATERIAL_SPECS.get(material_id, MATERIAL_SPECS["blue"])
	var color: Color = spec["edge_color"]
	var material := StandardMaterial3D.new()
	material.resource_name = "battle_star_%s_glow_line" % material_id
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = clampf(float(spec["emission_energy"]) * 1.75 * energy_scale, 0.35, 1.65)
	material.roughness = float(spec.get("roughness_edge", 0.36))
	material.metallic = 0.0
	return material


static func make_digit_material(material_id: String) -> StandardMaterial3D:
	var spec: Dictionary = MATERIAL_SPECS.get(material_id, MATERIAL_SPECS["blue"])
	var color: Color = spec["edge_color"]
	if material_id == "gold":
		color = Color(0.960784, 0.949020, 0.909804, 1.0)
	elif material_id == "white":
		color = Color(0.98, 1.0, 1.0, 1.0)
	var material := StandardMaterial3D.new()
	material.resource_name = "battle_star_%s_digit_glow" % material_id
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.50
	return material


static func make_contact_shadow_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = "battle_star_fake_contact_shadow"
	material.albedo_color = Color(0.0, 0.0, 0.0, 0.50)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	material.metallic = 0.0
	return material


static func emission_color(material_id: String) -> Color:
	var spec: Dictionary = MATERIAL_SPECS.get(material_id, MATERIAL_SPECS["blue"])
	return spec["emission_color"]
