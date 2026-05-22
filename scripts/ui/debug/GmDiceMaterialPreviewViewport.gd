extends SubViewportContainer
class_name GmDiceMaterialPreviewViewport


signal preview_clicked(material_id: StringName)


const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const GmDiceMaterialResolver = preload("res://scripts/ui/debug/gm_dice_port/GmDiceMaterialResolver.gd")


const VIEWPORT_SIZE := Vector2i(512, 384)
const DEFAULT_ROTATION := Vector3(-0.31415927, 0.59341195, 0.17453292)
const DEFAULT_ZOOM := 1.0
const DIE_SCALE := 1.36
const FACE_OFFSET := 0.708


var material_id: StringName = GmDiceDefinition.MATERIAL_STANDARD
var material_name := ""
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
var world_environment: WorldEnvironment = null
var key_light: DirectionalLight3D = null
var fill_light: OmniLight3D = null
var face_labels: Array[Label3D] = []
var lighting_config := {
	"key_energy": 1.35,
	"key_yaw": 45.0,
	"ambient_energy": 0.40,
	"fill_energy": 0.62,
}


func build(new_material_id: StringName, new_interactive := false) -> void:
	material_id = GmDiceDefinition.normalize_material_id(new_material_id)
	material_name = GmDiceDefinition.material_name(material_id)
	interactive = new_interactive
	name = "InspectorPreviewViewport" if interactive else "MaterialPreviewViewport_%s" % str(material_id)
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
			accept_event()


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
			label.visible = show_pips


func apply_lighting(config: Dictionary) -> void:
	lighting_config = _normalized_lighting(config)
	if key_light != null:
		key_light.light_energy = float(lighting_config["key_energy"])
		key_light.rotation_degrees = Vector3(-52.0, float(lighting_config["key_yaw"]), 0.0)
	if fill_light != null:
		fill_light.light_energy = float(lighting_config["fill_energy"])
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.ambient_light_energy = float(lighting_config["ambient_energy"])


func apply_lighting_preset(preset_id: StringName) -> Dictionary:
	match preset_id:
		&"bright":
			apply_lighting({
				"key_energy": 1.90,
				"key_yaw": 32.0,
				"ambient_energy": 0.58,
				"fill_energy": 0.92,
			})
		&"dark":
			apply_lighting({
				"key_energy": 0.82,
				"key_yaw": 70.0,
				"ambient_energy": 0.22,
				"fill_energy": 0.34,
			})
		_:
			apply_lighting({
				"key_energy": 1.35,
				"key_yaw": 45.0,
				"ambient_energy": 0.40,
				"fill_energy": 0.62,
			})
	return lighting_config.duplicate(true)


func get_snapshot() -> Dictionary:
	var material := dice_mesh.material_override if dice_mesh != null else null
	return {
		"material_id": str(material_id),
		"material_name": material_name,
		"material_resource_path": material.resource_path if material != null else "",
		"mesh_resource_path": dice_mesh.mesh.resource_path if dice_mesh != null and dice_mesh.mesh != null else "",
		"interactive": interactive,
		"show_pips": show_pips,
		"auto_rotate": auto_rotate,
		"zoom": zoom,
		"rotation": rotation_value,
		"lighting": lighting_config.duplicate(true),
	}


func _handle_interactive_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			drag_active = mouse_event.pressed
			accept_event()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 0.08, 0.55, 1.80)
			_apply_view_transform()
			accept_event()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 0.08, 0.55, 1.80)
			_apply_view_transform()
			accept_event()
			return
	if event is InputEventMouseMotion and drag_active:
		var motion := event as InputEventMouseMotion
		rotation_value.y += motion.relative.x * 0.012
		rotation_value.x += motion.relative.y * 0.010
		rotation_value.x = clampf(rotation_value.x, deg_to_rad(-80.0), deg_to_rad(80.0))
		_apply_view_transform()
		accept_event()


func _build_viewport() -> void:
	sub_viewport = SubViewport.new()
	sub_viewport.name = "PreviewSubViewport"
	sub_viewport.size = VIEWPORT_SIZE
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.transparent_bg = false
	add_child(sub_viewport)

	world_root = Node3D.new()
	world_root.name = "PreviewWorld"
	sub_viewport.add_child(world_root)

	_build_environment()
	_build_dice()
	_build_camera()
	apply_lighting(lighting_config)


func _build_environment() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "PreviewWorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.028, 0.040, 0.090)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.36, 0.42, 0.60)
	environment.ambient_light_energy = float(lighting_config["ambient_energy"])
	environment.ambient_light_sky_contribution = 0.10
	_set_existing(environment, ["tonemap_mode"], 3)
	_set_existing(environment, ["tonemap_exposure"], 1.05)
	_set_existing(environment, ["glow_enabled"], true)
	_set_existing(environment, ["glow_intensity"], 0.32)
	_set_existing(environment, ["glow_strength"], 0.62)
	world_environment.environment = environment
	world_root.add_child(world_environment)

	key_light = DirectionalLight3D.new()
	key_light.name = "PreviewKeyLight"
	key_light.light_energy = float(lighting_config["key_energy"])
	key_light.light_specular = 0.56
	key_light.shadow_enabled = true
	key_light.rotation_degrees = Vector3(-52.0, float(lighting_config["key_yaw"]), 0.0)
	world_root.add_child(key_light)

	fill_light = OmniLight3D.new()
	fill_light.name = "PreviewFillLight"
	fill_light.position = Vector3(-2.5, 2.5, 3.3)
	fill_light.light_color = Color(0.58, 0.80, 1.00)
	fill_light.light_energy = float(lighting_config["fill_energy"])
	fill_light.light_specular = 0.22
	fill_light.omni_range = 8.0
	world_root.add_child(fill_light)


func _build_dice() -> void:
	dice_root = Node3D.new()
	dice_root.name = "PreviewDiceRoot"
	world_root.add_child(dice_root)

	dice_mesh = MeshInstance3D.new()
	dice_mesh.name = "PreviewDiceMesh"
	var mesh := GmDiceMaterialResolver.load_body_mesh(material_id)
	if mesh != null:
		dice_mesh.mesh = mesh
		dice_mesh.scale = Vector3.ONE * DIE_SCALE
	else:
		var fallback_mesh := BoxMesh.new()
		fallback_mesh.size = Vector3.ONE * DIE_SCALE
		dice_mesh.mesh = fallback_mesh
	dice_mesh.material_override = GmDiceMaterialResolver.make_body_material(_body_color_for_material(), material_id)
	dice_root.add_child(dice_mesh)
	_create_face_labels()


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "PreviewCamera"
	camera.fov = 34.0
	camera.current = true
	world_root.add_child(camera)
	_apply_view_transform()


func _create_face_labels() -> void:
	face_labels.clear()
	var text_color := GmDiceMaterialResolver.face_label_color(material_id)
	var outline_color := GmDiceMaterialResolver.face_label_outline_color(material_id)
	var rows := [
		{"name": "Face1", "position": Vector3(0.0, FACE_OFFSET, 0.0), "rotation": Vector3(-PI * 0.5, 0.0, 0.0)},
		{"name": "Face6", "position": Vector3(0.0, -FACE_OFFSET, 0.0), "rotation": Vector3(PI * 0.5, 0.0, 0.0)},
		{"name": "Face2", "position": Vector3(0.0, 0.0, -FACE_OFFSET), "rotation": Vector3(0.0, PI, 0.0)},
		{"name": "Face5", "position": Vector3(0.0, 0.0, FACE_OFFSET), "rotation": Vector3.ZERO},
		{"name": "Face3", "position": Vector3(FACE_OFFSET, 0.0, 0.0), "rotation": Vector3(0.0, PI * 0.5, 0.0)},
		{"name": "Face4", "position": Vector3(-FACE_OFFSET, 0.0, 0.0), "rotation": Vector3(0.0, -PI * 0.5, 0.0)},
	]
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		var label := Label3D.new()
		label.name = str(row["name"])
		label.text = str(index + 1)
		label.position = row["position"]
		label.rotation = row["rotation"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.double_sided = true
		label.no_depth_test = false
		label.shaded = false
		label.font_size = 76
		label.pixel_size = 0.0044
		label.outline_size = 9
		label.modulate = text_color
		label.outline_modulate = outline_color
		label.visible = show_pips
		dice_root.add_child(label)
		face_labels.append(label)


func _apply_view_transform() -> void:
	if dice_root != null:
		dice_root.rotation = rotation_value
	if camera != null:
		var distance := 4.35 * zoom
		camera.position = Vector3(0.0, 1.65 * zoom, distance)
		camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)


func _body_color_for_material() -> Color:
	match material_id:
		GmDiceDefinition.MATERIAL_REPRO_PURPLE:
			return Color(0.64, 0.52, 1.00)
		GmDiceDefinition.MATERIAL_REPRO_CYAN:
			return Color(0.18, 0.86, 0.72)
		GmDiceDefinition.MATERIAL_REPRO_GOLD, GmDiceDefinition.MATERIAL_GOLD:
			return Color(0.96, 0.82, 0.32)
		GmDiceDefinition.MATERIAL_REPRO_SILVERWHITE:
			return Color(0.84, 0.92, 1.00)
		GmDiceDefinition.MATERIAL_BRONZE:
			return Color(0.58, 0.38, 0.20)
		GmDiceDefinition.MATERIAL_CRYSTAL, GmDiceDefinition.MATERIAL_GLASS:
			return Color(0.52, 0.90, 1.00)
		GmDiceDefinition.MATERIAL_IRON:
			return Color(0.70, 0.76, 0.84)
		_:
			return Color(0.40, 0.78, 1.00)


func _normalized_lighting(config: Dictionary) -> Dictionary:
	return {
		"key_energy": clampf(float(config.get("key_energy", lighting_config.get("key_energy", 1.35))), 0.0, 3.0),
		"key_yaw": clampf(float(config.get("key_yaw", lighting_config.get("key_yaw", 45.0))), -180.0, 180.0),
		"ambient_energy": clampf(float(config.get("ambient_energy", lighting_config.get("ambient_energy", 0.40))), 0.0, 1.4),
		"fill_energy": clampf(float(config.get("fill_energy", lighting_config.get("fill_energy", 0.62))), 0.0, 2.4),
	}


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _set_existing(object: Object, names: Array, value) -> bool:
	var properties := {}
	for item in object.get_property_list():
		properties[item["name"]] = true
	for property_name in names:
		if properties.has(property_name):
			object.set(property_name, value)
			return true
	return false
