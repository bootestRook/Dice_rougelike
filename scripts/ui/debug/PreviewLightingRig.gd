extends Node3D
class_name PreviewLightingRig


const BACKGROUND_COLOR := Color(0.075, 0.090, 0.115, 1.0)
const AMBIENT_COLOR := Color(0.34, 0.36, 0.39, 1.0)
const KEY_LIGHT_COLOR := Color(1.0, 0.952, 0.870, 1.0)
const FILL_LIGHT_COLOR := Color(0.650, 0.790, 1.0, 1.0)
const RIM_LIGHT_COLOR := Color(1.0, 0.982, 0.940, 1.0)
const DEFAULT_CONFIG := {
	"key_energy": 2.35,
	"key_yaw": 36.0,
	"ambient_energy": 0.52,
	"fill_energy": 0.50,
	"rim_energy": 0.66,
}


var lighting_config := DEFAULT_CONFIG.duplicate(true)
var world_environment: WorldEnvironment = null
var key_light: SpotLight3D = null
var fill_light: OmniLight3D = null
var rim_light: SpotLight3D = null
var reflection_probe: Node3D = null
var light_cards: Array[MeshInstance3D] = []


func build(config: Dictionary = {}) -> void:
	name = "PreviewLightingRig"
	_clear_children()
	lighting_config = normalized_config(config, DEFAULT_CONFIG)
	_build_world_environment()
	_build_lights()
	_build_light_cards()
	_build_reflection_probe()
	apply_lighting(lighting_config)


func apply_lighting(config: Dictionary) -> Dictionary:
	lighting_config = normalized_config(config, lighting_config)
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.ambient_light_energy = float(lighting_config["ambient_energy"])
	if key_light != null:
		key_light.light_energy = float(lighting_config["key_energy"])
		key_light.position = _key_position(float(lighting_config["key_yaw"]))
		_aim_at_origin(key_light)
	if fill_light != null:
		fill_light.light_energy = float(lighting_config["fill_energy"])
	if rim_light != null:
		rim_light.light_energy = float(lighting_config["rim_energy"])
		_aim_at_origin(rim_light)
	return lighting_config.duplicate(true)


func get_snapshot() -> Dictionary:
	return {
		"config": lighting_config.duplicate(true),
		"background_color": BACKGROUND_COLOR,
		"ambient_color": AMBIENT_COLOR,
		"world_environment": world_environment != null,
		"key_light": key_light != null and key_light is SpotLight3D,
		"fill_light": fill_light != null and fill_light is OmniLight3D,
		"rim_light": rim_light != null and rim_light is SpotLight3D,
		"reflection_probe": reflection_probe != null,
		"light_card_count": light_cards.size(),
	}


static func normalized_config(config: Dictionary, fallback: Dictionary = DEFAULT_CONFIG) -> Dictionary:
	return {
		"key_energy": clampf(float(config.get("key_energy", fallback.get("key_energy", DEFAULT_CONFIG["key_energy"]))), 0.0, 4.0),
		"key_yaw": clampf(float(config.get("key_yaw", fallback.get("key_yaw", DEFAULT_CONFIG["key_yaw"]))), -180.0, 180.0),
		"ambient_energy": clampf(float(config.get("ambient_energy", fallback.get("ambient_energy", DEFAULT_CONFIG["ambient_energy"]))), 0.0, 1.4),
		"fill_energy": clampf(float(config.get("fill_energy", fallback.get("fill_energy", DEFAULT_CONFIG["fill_energy"]))), 0.0, 2.4),
		"rim_energy": clampf(float(config.get("rim_energy", fallback.get("rim_energy", DEFAULT_CONFIG["rim_energy"]))), 0.0, 2.4),
	}


func _build_world_environment() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = BACKGROUND_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = AMBIENT_COLOR
	environment.ambient_light_energy = float(lighting_config["ambient_energy"])
	environment.ambient_light_sky_contribution = 0.08
	_set_existing(environment, ["tonemap_mode"], 3)
	_set_existing(environment, ["tonemap_exposure"], 1.10)
	_set_existing(environment, ["tonemap_white"], 1.0)
	_set_existing(environment, ["glow_enabled"], true)
	_set_existing(environment, ["glow_intensity"], 0.22)
	_set_existing(environment, ["glow_strength"], 0.44)
	world_environment.environment = environment
	add_child(world_environment)


func _build_lights() -> void:
	key_light = SpotLight3D.new()
	key_light.name = "KeyLight_Spot"
	key_light.light_color = KEY_LIGHT_COLOR
	key_light.light_energy = float(lighting_config["key_energy"])
	key_light.light_specular = 0.95
	key_light.shadow_enabled = true
	key_light.spot_range = 8.0
	key_light.spot_angle = 34.0
	key_light.spot_angle_attenuation = 1.35
	add_child(key_light)

	fill_light = OmniLight3D.new()
	fill_light.name = "FillLight_Omni"
	fill_light.position = Vector3(2.35, 0.68, 2.45)
	fill_light.light_color = FILL_LIGHT_COLOR
	fill_light.light_energy = float(lighting_config["fill_energy"])
	fill_light.light_specular = 0.16
	fill_light.shadow_enabled = false
	fill_light.omni_range = 5.8
	add_child(fill_light)

	rim_light = SpotLight3D.new()
	rim_light.name = "RimLight_Spot"
	rim_light.position = Vector3(1.05, 2.95, -3.20)
	rim_light.light_color = RIM_LIGHT_COLOR
	rim_light.light_energy = float(lighting_config["rim_energy"])
	rim_light.light_specular = 0.86
	rim_light.shadow_enabled = false
	rim_light.spot_range = 7.0
	rim_light.spot_angle = 42.0
	rim_light.spot_angle_attenuation = 1.15
	add_child(rim_light)


func _build_light_cards() -> void:
	light_cards.clear()
	_add_light_card(
		"KeyReflectionCard",
		Vector3(-1.20, 2.45, 2.10),
		Vector3(1.75, 0.05, 1.00),
		KEY_LIGHT_COLOR,
		0.92
	)
	_add_light_card(
		"RimReflectionCard",
		Vector3(0.95, 2.15, -2.75),
		Vector3(2.20, 0.05, 0.72),
		RIM_LIGHT_COLOR,
		0.55
	)
	_add_light_card(
		"CoolFillReflectionCard",
		Vector3(2.75, 0.86, 1.05),
		Vector3(0.05, 1.25, 1.75),
		FILL_LIGHT_COLOR,
		0.20
	)


func _add_light_card(card_name: String, position: Vector3, size: Vector3, color: Color, energy: float) -> void:
	var card := MeshInstance3D.new()
	card.name = card_name
	card.layers = 2
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	card.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	card.mesh = mesh
	var material := StandardMaterial3D.new()
	material.resource_name = "%sMaterial" % card_name
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	card.material_override = material
	add_child(card)
	light_cards.append(card)


func _build_reflection_probe() -> void:
	reflection_probe = null
	if not ClassDB.class_exists("ReflectionProbe"):
		return
	var probe := ClassDB.instantiate("ReflectionProbe") as Node3D
	if probe == null:
		return
	probe.name = "ReflectionProbe"
	probe.position = Vector3(0.0, 0.45, 0.0)
	_set_existing(probe, ["size"], Vector3(4.8, 3.6, 4.8))
	_set_existing(probe, ["origin_offset"], Vector3(0.0, 0.18, 0.0))
	_set_existing(probe, ["intensity"], 1.28)
	_set_existing(probe, ["max_distance"], 7.5)
	_set_existing(probe, ["box_projection"], true)
	_set_existing(probe, ["enable_shadows"], false)
	_set_existing(probe, ["cull_mask"], 3)
	add_child(probe)
	reflection_probe = probe


func _key_position(yaw_degrees: float) -> Vector3:
	var yaw := deg_to_rad(yaw_degrees)
	return Vector3(-sin(yaw) * 2.70, 3.05, cos(yaw) * 2.95)


func _aim_at_origin(light: Node3D) -> void:
	light.look_at_from_position(light.position, Vector3(0.0, 0.0, 0.0), Vector3.UP)


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	light_cards.clear()
	world_environment = null
	key_light = null
	fill_light = null
	rim_light = null
	reflection_probe = null


func _set_existing(object: Object, names: Array, value) -> bool:
	var properties := {}
	for item in object.get_property_list():
		properties[item["name"]] = true
	for property_name in names:
		if properties.has(property_name):
			object.set(property_name, value)
			return true
	return false
