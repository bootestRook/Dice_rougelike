extends SubViewportContainer
class_name GmDiceMaterialPreviewViewport


signal preview_clicked(material_id: StringName)


const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const GmDiceMaterialResolver = preload("res://scripts/ui/debug/gm_dice_port/GmDiceMaterialResolver.gd")
const PreviewLightingRig = preload("res://scripts/ui/debug/PreviewLightingRig.gd")
const DiceFaceLayerSystem = preload("res://scripts/ui/dice_face_layers/DiceFaceLayerSystem.gd")


const VIEWPORT_SIZE := Vector2i(512, 384)
const DEFAULT_ROTATION := Vector3(-0.31415927, 0.59341195, 0.17453292)
const DEFAULT_ZOOM := 1.0
const DIE_SCALE := 1.36
const FACE_OFFSET := 0.708


var material_id: StringName = GmDiceDefinition.MATERIAL_STANDARD
var material_name := ""
var material_source_path := ""
var interactive := false
var show_pips := true
var auto_rotate := false
var zoom := DEFAULT_ZOOM
var rotation_value := DEFAULT_ROTATION
var drag_active := false
var sub_viewport: SubViewport = null
var world_root: Node3D = null
var dice_root: Node3D = null
var dice_mesh: MeshInstance3D = null
var camera: Camera3D = null
var preview_lighting_rig: PreviewLightingRig = null
var world_environment: WorldEnvironment = null
var key_light: SpotLight3D = null
var fill_light: OmniLight3D = null
var rim_light: SpotLight3D = null
var reflection_probe: Node3D = null
var face_labels: Array[Label3D] = []
var face_layer_system: DiceFaceLayerSystem = null
var face_albedo_texture: Texture2D = null
var lighting_config := {
	"key_energy": 2.35,
	"key_yaw": 36.0,
	"ambient_energy": 0.52,
	"fill_energy": 0.50,
	"rim_energy": 0.66,
}
var clean_body_diagnostic_enabled := false


func build(new_material_id: StringName, new_interactive := false) -> void:
	material_id = GmDiceDefinition.normalize_material_id(new_material_id)
	material_name = GmDiceDefinition.material_name(material_id)
	interactive = new_interactive
	if interactive:
		name = "InspectorPreviewViewport"
	elif name.is_empty() or str(name).begins_with("@"):
		name = "MaterialPreviewViewport_%s" % str(material_id)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(interactive)
	_clear_children()
	_build_viewport()
	reset_view()


func _process(delta: float) -> void:
	if auto_rotate and dice_root != null:
		rotation_value.y += delta * 0.72
		_apply_view_transform()


func _gui_input(event: InputEvent) -> void:
	if interactive:
		_handle_interactive_input(event)
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			preview_clicked.emit(material_id)
			_consume_event()


func reset_view() -> void:
	rotation_value = DEFAULT_ROTATION
	zoom = DEFAULT_ZOOM
	_apply_view_transform()


func set_auto_rotate(enabled: bool) -> void:
	auto_rotate = enabled
	set_process(interactive and auto_rotate)


func set_show_pips(enabled: bool) -> void:
	show_pips = enabled
	for label in face_labels:
		if label != null:
			label.visible = false
	_rebuild_face_layers()
	_apply_body_material()


func apply_lighting(config: Dictionary) -> void:
	if preview_lighting_rig != null:
		lighting_config = preview_lighting_rig.apply_lighting(config)
		world_environment = preview_lighting_rig.world_environment
		key_light = preview_lighting_rig.key_light
		fill_light = preview_lighting_rig.fill_light
		rim_light = preview_lighting_rig.rim_light
		reflection_probe = preview_lighting_rig.reflection_probe
	else:
		lighting_config = PreviewLightingRig.normalized_config(config, lighting_config)


func apply_lighting_preset(preset_id: StringName) -> Dictionary:
	match preset_id:
		&"bright":
			apply_lighting({
				"key_energy": 2.65,
				"key_yaw": 32.0,
				"ambient_energy": 0.58,
				"fill_energy": 0.58,
				"rim_energy": 0.78,
			})
		&"dark":
			apply_lighting({
				"key_energy": 1.36,
				"key_yaw": 64.0,
				"ambient_energy": 0.26,
				"fill_energy": 0.24,
				"rim_energy": 0.50,
			})
		&"body_diagnostic":
			apply_lighting({
				"key_energy": 1.82,
				"key_yaw": 44.0,
				"ambient_energy": 0.46,
				"fill_energy": 0.34,
				"rim_energy": 0.44,
			})
		&"normal_diagnostic":
			apply_lighting({
				"key_energy": 2.05,
				"key_yaw": 56.0,
				"ambient_energy": 0.34,
				"fill_energy": 0.30,
				"rim_energy": 0.82,
			})
		_:
			apply_lighting({
				"key_energy": 2.35,
				"key_yaw": 36.0,
				"ambient_energy": 0.52,
				"fill_energy": 0.50,
				"rim_energy": 0.66,
			})
	return lighting_config.duplicate(true)


func get_snapshot() -> Dictionary:
	var material := dice_mesh.material_override if dice_mesh != null else null
	return {
		"material_id": str(material_id),
		"material_name": material_name,
		"material_source_path": material_source_path,
		"material_resource_path": material.resource_path if material != null else "",
		"preview_instance_id": get_instance_id(),
		"dice_root_instance_id": dice_root.get_instance_id() if dice_root != null else 0,
		"dice_mesh_instance_id": dice_mesh.get_instance_id() if dice_mesh != null else 0,
		"mesh_resource_path": dice_mesh.mesh.resource_path if dice_mesh != null and dice_mesh.mesh != null else "",
		"interactive": interactive,
		"show_pips": show_pips,
		"face_label_count": face_labels.size(),
		"face_label_nodes_visible": _face_label_nodes_visible(),
		"face_albedo_texture_exists": face_albedo_texture != null,
		"face_albedo_texture_size": _face_albedo_texture_size(),
		"face_layer_system": face_layer_system.to_dictionary() if face_layer_system != null else {},
		"body_material_shader_path": _body_material_shader_path(),
		"body_material_face_layer_enabled": _body_material_shader_float("face_layer_enabled"),
		"auto_rotate": auto_rotate,
		"zoom": zoom,
		"rotation": rotation_value,
		"lighting": lighting_config.duplicate(true),
		"has_reflection_probe": reflection_probe != null,
		"has_preview_lighting_rig": preview_lighting_rig != null,
		"lighting_rig": preview_lighting_rig.get_snapshot() if preview_lighting_rig != null else {},
		"clean_body_diagnostic_enabled": clean_body_diagnostic_enabled,
	}


func _handle_interactive_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			drag_active = mouse_event.pressed
			_consume_event()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 0.08, 0.55, 1.80)
			_apply_view_transform()
			_consume_event()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 0.08, 0.55, 1.80)
			_apply_view_transform()
			_consume_event()
			return
	if event is InputEventMouseMotion and drag_active:
		var motion := event as InputEventMouseMotion
		rotation_value.y += motion.relative.x * 0.012
		rotation_value.x += motion.relative.y * 0.010
		rotation_value.x = clampf(rotation_value.x, deg_to_rad(-80.0), deg_to_rad(80.0))
		_apply_view_transform()
		_consume_event()


func _build_viewport() -> void:
	sub_viewport = SubViewport.new()
	sub_viewport.name = "PreviewSubViewport"
	sub_viewport.size = VIEWPORT_SIZE
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.transparent_bg = false
	_set_existing(sub_viewport, ["own_world_3d"], true)
	_set_existing(sub_viewport, ["handle_input_locally"], true)
	add_child(sub_viewport)

	world_root = Node3D.new()
	world_root.name = "PreviewWorld"
	sub_viewport.add_child(world_root)

	_build_environment()
	_build_dice()
	_build_camera()
	apply_lighting(lighting_config)


func _build_environment() -> void:
	preview_lighting_rig = PreviewLightingRig.new()
	preview_lighting_rig.name = "PreviewLightingRig"
	world_root.add_child(preview_lighting_rig)
	preview_lighting_rig.build(lighting_config)
	world_environment = preview_lighting_rig.world_environment
	key_light = preview_lighting_rig.key_light
	fill_light = preview_lighting_rig.fill_light
	rim_light = preview_lighting_rig.rim_light
	reflection_probe = preview_lighting_rig.reflection_probe


func _build_dice() -> void:
	dice_root = Node3D.new()
	dice_root.name = "PreviewDiceRoot"
	world_root.add_child(dice_root)

	dice_mesh = MeshInstance3D.new()
	dice_mesh.name = "PreviewDiceMesh"
	var mesh := GmDiceMaterialResolver.load_preview_mesh(material_id)
	if mesh != null:
		dice_mesh.mesh = mesh
		dice_mesh.scale = Vector3.ONE * DIE_SCALE
	else:
		push_error("Rounded dice preview mesh is unavailable")
	material_source_path = GmDiceMaterialResolver.material_resource_path(material_id)
	_rebuild_face_layers()
	_apply_body_material()
	dice_root.add_child(dice_mesh)
	_create_face_labels()


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "PreviewCamera"
	camera.fov = 34.0
	camera.cull_mask = 1
	camera.current = true
	world_root.add_child(camera)
	_apply_view_transform()


func _create_face_labels() -> void:
	face_labels.clear()
	if dice_root != null:
		dice_root.set_meta("face_marker_source", "DiceFaceLayerSystem")
		dice_root.set_meta("legacy_label3d_display", false)


func _apply_view_transform() -> void:
	if dice_root != null:
		dice_root.rotation = rotation_value
	if camera != null:
		var distance := 4.35 * zoom
		camera.position = Vector3(0.0, 1.65 * zoom, distance)
		camera.look_at_from_position(camera.position, Vector3(0.0, 0.0, 0.0), Vector3.UP)


func _body_color_for_material() -> Color:
	match material_id:
		GmDiceDefinition.MATERIAL_REPRO_PURPLE:
			return Color(0.64, 0.52, 1.00)
		GmDiceDefinition.MATERIAL_REPRO_CYAN:
			return Color(0.18, 0.86, 0.72)
		GmDiceDefinition.MATERIAL_REPRO_GOLD:
			return Color(0.909804, 0.847059, 0.686275)
		GmDiceDefinition.MATERIAL_GOLD:
			return Color(0.850980, 0.713725, 0.227451)
		GmDiceDefinition.MATERIAL_REPRO_SILVERWHITE:
			return Color(0.84, 0.92, 1.00)
		GmDiceDefinition.MATERIAL_BRONZE:
			return Color(0.545098, 0.352941, 0.168627)
		GmDiceDefinition.MATERIAL_CRYSTAL, GmDiceDefinition.MATERIAL_GLASS:
			return Color(0.52, 0.90, 1.00)
		GmDiceDefinition.MATERIAL_IRON:
			return Color(0.70, 0.76, 0.84)
		_:
			return Color(0.40, 0.78, 1.00)


func set_clean_body_diagnostic_enabled(enabled: bool) -> void:
	clean_body_diagnostic_enabled = enabled
	_apply_body_material()


func _apply_body_material() -> void:
	if dice_mesh == null:
		return
	if clean_body_diagnostic_enabled:
		dice_mesh.material_override = _make_clean_body_diagnostic_material()
	else:
		dice_mesh.material_override = GmDiceMaterialResolver.make_body_material_instance(_body_color_for_material(), material_id, face_albedo_texture, show_pips)


func _rebuild_face_layers() -> void:
	var rows: Array = []
	for value in range(1, 7):
		rows.append({"label": str(value), "mark_id": &"none"})
	face_layer_system = DiceFaceLayerSystem.from_face_rows(rows, {
		"number_color": GmDiceMaterialResolver.face_label_color(material_id),
		"enable_numbers": show_pips,
		"enable_marks": false,
	})
	face_albedo_texture = face_layer_system.get_face_albedo_texture()


func _face_albedo_texture_size() -> Vector2i:
	if face_albedo_texture == null:
		return Vector2i.ZERO
	var image := face_albedo_texture.get_image()
	if image == null:
		return Vector2i.ZERO
	return Vector2i(image.get_width(), image.get_height())


func _face_label_nodes_visible() -> bool:
	for label in face_labels:
		if label != null and label.visible:
			return true
	return false


func _body_shader_material() -> ShaderMaterial:
	if dice_mesh == null:
		return null
	return dice_mesh.material_override as ShaderMaterial


func _body_material_shader_path() -> String:
	var material := _body_shader_material()
	if material == null or material.shader == null:
		return ""
	return material.shader.resource_path


func _body_material_shader_float(parameter_name: String) -> float:
	var material := _body_shader_material()
	if material == null:
		return 0.0
	var value = material.get_shader_parameter(parameter_name)
	if value == null:
		return 0.0
	return float(value)


func _make_clean_body_diagnostic_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var body_color := _body_color_for_material()
	material.resource_name = "preview_clean_body_diagnostic_%s" % str(material_id)
	material.albedo_color = body_color.lerp(Color.WHITE, 0.10)
	material.roughness = 0.28
	material.metallic = 0.78
	material.cull_mode = BaseMaterial3D.CULL_BACK
	material.emission_enabled = false
	return material


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _consume_event() -> void:
	accept_event()
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _set_existing(object: Object, names: Array, value) -> bool:
	var properties := {}
	for item in object.get_property_list():
		properties[item["name"]] = true
	for property_name in names:
		if properties.has(property_name):
			object.set(property_name, value)
			return true
	return false
