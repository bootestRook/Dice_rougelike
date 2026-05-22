extends Node3D
class_name BattleStarLightingRig


const DiceMaterialFactory := preload("res://scripts/ui/debug/star_dice_full/DiceMaterialFactory.gd")


static func create_environment(postprocess_enabled: bool) -> Environment:
	var env := Environment.new()
	env.resource_name = "battle_star_dice_full_environment"
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.095, 0.115, 0.140, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.36, 0.40, 1.0)
	env.ambient_light_energy = 0.56
	_set_existing(env, ["ambient_light_sky_contribution"], 0.12)
	_set_existing(env, ["reflected_light_source"], 0)
	_set_postprocess(env, postprocess_enabled)
	return env


static func set_postprocess_enabled(env: Environment, enabled: bool) -> void:
	_set_postprocess(env, enabled)


static func populate(parent: Node3D, dice_positions: Array, material_ids: Array) -> Node3D:
	var rig := Node3D.new()
	rig.name = "LightingRig"
	parent.add_child(rig)
	_add_warm_key_light(rig)
	_add_blue_fill_light(rig)
	_add_warm_rim_light(rig)
	_add_dice_emission_helpers(rig, dice_positions, material_ids)
	_add_fake_contact_shadows(rig, dice_positions)
	return rig


static func _set_postprocess(env: Environment, enabled: bool) -> void:
	_set_existing(env, ["glow_enabled"], enabled)
	_set_existing(env, ["glow_intensity"], 0.58 if enabled else 0.0)
	_set_existing(env, ["glow_strength"], 0.86 if enabled else 0.0)
	_set_existing(env, ["glow_bloom"], 0.18 if enabled else 0.0)
	_set_existing(env, ["glow_hdr_threshold"], 0.66)
	_set_existing(env, ["tonemap_mode"], 3)
	_set_existing(env, ["tonemap_exposure"], 1.06 if enabled else 0.94)
	_set_existing(env, ["tonemap_white"], 1.55)
	_set_existing(env, ["ssao_enabled"], enabled)
	_set_existing(env, ["ssao_radius"], 1.18)
	_set_existing(env, ["ssao_intensity"], 0.52)
	_set_existing(env, ["adjustment_enabled"], enabled)
	_set_existing(env, ["adjustment_brightness"], 1.02)
	_set_existing(env, ["adjustment_contrast"], 1.10)
	_set_existing(env, ["adjustment_saturation"], 1.08)


static func _add_warm_key_light(parent: Node3D) -> void:
	var key := DirectionalLight3D.new()
	key.name = "WarmKeyLight"
	key.rotation_degrees = Vector3(-47.0, 36.0, 0.0)
	key.light_color = Color(1.0, 0.949, 0.839, 1.0)
	key.light_energy = 1.90
	key.light_specular = 0.72
	key.shadow_enabled = true
	parent.add_child(key)


static func _add_blue_fill_light(parent: Node3D) -> void:
	var fill := OmniLight3D.new()
	fill.name = "BlueFillLight"
	fill.position = Vector3(-3.7, 2.15, 3.0)
	fill.light_color = Color(0.722, 0.843, 1.0, 1.0)
	fill.light_energy = 0.53
	fill.light_specular = 0.32
	fill.omni_range = 8.2
	fill.omni_attenuation = 0.68
	parent.add_child(fill)


static func _add_warm_rim_light(parent: Node3D) -> void:
	var rim := OmniLight3D.new()
	rim.name = "WarmRimLight"
	rim.position = Vector3(3.7, 2.55, -2.65)
	rim.light_color = Color(1.0, 0.973, 0.918, 1.0)
	rim.light_energy = 0.38
	rim.light_specular = 0.62
	rim.omni_range = 7.6
	rim.omni_attenuation = 0.62
	parent.add_child(rim)


static func _add_dice_emission_helpers(parent: Node3D, dice_positions: Array, material_ids: Array) -> void:
	var helper_root := Node3D.new()
	helper_root.name = "DiceEmissionHelperLights"
	parent.add_child(helper_root)
	for i in range(dice_positions.size()):
		var position: Vector3 = dice_positions[i]
		var material_id := str(material_ids[i]) if i < material_ids.size() else "blue"
		var light := OmniLight3D.new()
		light.name = "DiceEmissionHelper_%02d" % [i + 1]
		light.position = position + Vector3(0.0, 0.44, 0.03)
		light.light_color = DiceMaterialFactory.emission_color(material_id)
		light.light_energy = 0.045
		light.light_specular = 0.12
		light.omni_range = 1.22
		light.omni_attenuation = 1.18
		helper_root.add_child(light)


static func _add_fake_contact_shadows(parent: Node3D, dice_positions: Array) -> void:
	var shadows := Node3D.new()
	shadows.name = "FakeContactShadowPlanes"
	parent.add_child(shadows)
	var shadow_material: StandardMaterial3D = DiceMaterialFactory.make_contact_shadow_material()
	for i in range(dice_positions.size()):
		var position: Vector3 = dice_positions[i]
		var shadow := MeshInstance3D.new()
		shadow.name = "FakeContactShadow_%02d" % [i + 1]
		shadow.mesh = make_contact_shadow_mesh(0.48, 0.24, 96)
		shadow.position = Vector3(position.x, 0.036, position.z + 0.03)
		shadow.rotation.y = 0.10 * float(i - 2)
		shadow.material_override = shadow_material
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shadows.add_child(shadow)


static func make_contact_shadow_mesh(radius_x: float, radius_z: float, segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	uvs.append(Vector2(0.5, 0.5))
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		var point := Vector3(cos(angle) * radius_x, 0.0, sin(angle) * radius_z)
		vertices.append(point)
		normals.append(Vector3.UP)
		uvs.append(Vector2(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))
	for i in range(segments):
		var a := 1 + i
		var b := 1 + ((i + 1) % segments)
		indices.append_array(PackedInt32Array([0, b, a]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.resource_name = "FakeContactShadowPlane"
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _set_existing(object: Object, names: Array, value) -> bool:
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
