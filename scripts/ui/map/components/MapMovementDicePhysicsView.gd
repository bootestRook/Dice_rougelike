extends Control
class_name MapMovementDicePhysicsView


signal die_pressed(index: int)


const PhysicsDiceThrowService = preload("res://scripts/rules/physics_dice/PhysicsDiceThrowService.gd")

const TABLE_WIDTH := 12.8
const TABLE_DEPTH := 9.2
const TABLE_THICKNESS := 0.26
const WALL_HEIGHT := 0.74
const WALL_THICKNESS := 0.34
const DIE_SIZE := 0.72
const DIE_HALF := DIE_SIZE * 0.5
const PIP_RADIUS := 0.038
const PIP_DEPTH := 0.018
const PIP_SPACING := 0.165
const QUIET_LINEAR := 0.065
const QUIET_ANGULAR := 0.11
const QUIET_FRAMES := 42
const MAX_ROLL_SECONDS := 4.2
const DEFAULT_CAMERA_FOV := 43.25
const DEFAULT_CAMERA_POSITION := Vector3(0.0, 12.0, 4.8)
const DEFAULT_CAMERA_TARGET := Vector3(0.0, -1.0, 1.45)
const DEFAULT_VIEW_OFFSET := Vector2.ZERO

const FACE_DEFINITIONS := [
	{"value": 1, "normal": Vector3.UP, "u": Vector3.RIGHT, "v": Vector3.FORWARD},
	{"value": 6, "normal": Vector3.DOWN, "u": Vector3.RIGHT, "v": Vector3.BACK},
	{"value": 2, "normal": Vector3.BACK, "u": Vector3.RIGHT, "v": Vector3.UP},
	{"value": 5, "normal": Vector3.FORWARD, "u": Vector3.LEFT, "v": Vector3.UP},
	{"value": 3, "normal": Vector3.RIGHT, "u": Vector3.FORWARD, "v": Vector3.UP},
	{"value": 4, "normal": Vector3.LEFT, "u": Vector3.BACK, "v": Vector3.UP},
]


var rng := RandomNumberGenerator.new()
var throw_service: PhysicsDiceThrowService = PhysicsDiceThrowService.new()
var art_config: Resource = null
var viewport_container: SubViewportContainer = null
var viewport: SubViewport = null
var scene_root: Node3D = null
var visible_root: Node3D = null
var board_mesh_instance: MeshInstance3D = null
var map_node_root: Node3D = null
var player_marker_sprite: Sprite3D = null
var table_visual_nodes: Array[Node3D] = []
var node_visuals: Array[Node3D] = []
var camera: Camera3D = null
var dice_physics_material: PhysicsMaterial = null
var table_physics_material: PhysicsMaterial = null
var wall_physics_material: PhysicsMaterial = null
var rounded_die_mesh: Mesh = null
var pip_mesh: Mesh = null
var die_body_material: StandardMaterial3D = null
var pip_material: StandardMaterial3D = null
var selection_buttons: Array[Button] = []
var dice: Array = []
var selected_indices: Array[int] = [0, 1]
var rolled_indices: Array[int] = []
var display_values: Array[int] = [1, 1]
var target_values: Array[int] = [0, 0]
var last_values: Array[int] = [0, 0]
var recorded_trajectories: Array = []
var rolling := false
var recorded_playback := false
var recorded_elapsed := 0.0
var recorded_duration := 0.0
var roll_elapsed := 0.0
var quiet_frame_count := 0
var settle_timer := 0.0
var interactions_disabled := false
var map_nodes: Array = []
var current_map_index := 0
var map_visuals_enabled := false
var camera_fov := DEFAULT_CAMERA_FOV
var camera_position := DEFAULT_CAMERA_POSITION
var camera_target := DEFAULT_CAMERA_TARGET
var view_offset := DEFAULT_VIEW_OFFSET
var pov_tuner_panel: PanelContainer = null
var pov_tuner_summary_label: Label = null
var pov_tuner_status_label: Label = null
var pov_tuner_rows: Dictionary = {}
var pov_tuner_syncing := false


func _ready() -> void:
	if name.is_empty():
		name = "MovementDicePhysicsView"
	custom_minimum_size = Vector2(960.0, 540.0)
	mouse_filter = Control.MOUSE_FILTER_PASS
	rng.randomize()
	_build_view()
	_refresh_map_visuals()
	_set_idle_dice(display_values)
	_update_selection_buttons()
	set_physics_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_resize_viewport()
		_layout_selection_buttons()


func set_selected_indices(indices: Array[int]) -> void:
	selected_indices = _normalize_indices(indices)
	_update_selection_buttons()


func set_interaction_disabled(disabled: bool) -> void:
	interactions_disabled = disabled
	_update_selection_buttons()


func set_map_visual_state(new_art_config: Resource, nodes: Array, current_index: int, show_map_visuals: bool = false) -> void:
	art_config = new_art_config
	map_nodes = nodes.duplicate(true)
	current_map_index = current_index
	map_visuals_enabled = show_map_visuals
	if is_node_ready():
		_refresh_board_material()
		_refresh_map_visuals()
		_sync_map_visual_visibility()


func animate_marker_to_index(index: int, duration: float) -> void:
	current_map_index = index
	if not map_visuals_enabled or player_marker_sprite == null:
		return
	var target_position := _route_world_position(index, max(1, map_nodes.size())) + Vector3(0.0, 0.18, 0.0)
	var tween := create_tween()
	tween.tween_property(player_marker_sprite, "position", target_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func set_display_state(rolls: Array, new_selected_indices: Array[int], disabled: bool) -> void:
	set_selected_indices(new_selected_indices)
	set_interaction_disabled(disabled)
	if rolling:
		return

	var next_values := display_values.duplicate()
	for index in range(2):
		if index < rolls.size() and int(rolls[index]) > 0:
			next_values[index] = clampi(int(rolls[index]), 1, 6)

	if not _has_valid_dice() or next_values != display_values:
		_set_idle_dice(next_values)


func play_roll(rolls: Array, new_selected_indices: Array[int]) -> Array[int]:
	var normalized_indices := _normalize_indices(new_selected_indices)
	if normalized_indices.is_empty():
		normalized_indices.append(0)
	set_selected_indices(normalized_indices)
	_start_roll(rolls, normalized_indices)
	while rolling and is_inside_tree():
		await get_tree().physics_frame
	return last_values.duplicate()


func get_die_button(index: int) -> Button:
	if index < 0 or index >= selection_buttons.size():
		return null
	return selection_buttons[index]


func automation_get_snapshot() -> Dictionary:
	return {
		"active_dice": _active_dice_count(),
		"display_values": display_values.duplicate(),
		"last_values": last_values.duplicate(),
		"rolling": rolling,
		"recorded_playback": recorded_playback,
		"recorded_duration": recorded_duration,
		"selected_indices": selected_indices.duplicate(),
		"rolled_indices": rolled_indices.duplicate(),
		"dice_positions": _dice_positions_snapshot(),
		"initial_positions": [_idle_position_for_die(0), _idle_position_for_die(1)],
		"has_physics_viewport": viewport != null,
		"button_count": selection_buttons.size(),
		"map_node_count": map_nodes.size(),
		"visible_node_count": _visible_node_count(),
		"has_board_texture": _board_texture() != null,
		"board_visible": board_mesh_instance != null and board_mesh_instance.visible,
		"map_visuals_enabled": map_visuals_enabled,
		"fixed_camera": true,
		"has_pov_tuner": pov_tuner_panel != null,
		"pov_tuner_visible": pov_tuner_panel != null and pov_tuner_panel.visible,
		"pov_tuner_text": _format_pov_parameters(),
		"camera_fov": camera.fov if camera != null else camera_fov,
		"camera_position": camera.global_position if camera != null else Vector3.ZERO,
		"camera_rotation": camera.global_rotation if camera != null else Vector3.ZERO,
		"camera_target": camera_target,
		"view_offset": view_offset,
		"control_size": size,
	}


func automation_set_camera_pov(new_fov: float, new_position: Vector3, new_target: Vector3, new_view_offset: Vector2 = DEFAULT_VIEW_OFFSET) -> void:
	camera_fov = clampf(new_fov, 25.0, 85.0)
	camera_position = new_position
	camera_target = new_target
	view_offset = new_view_offset
	_update_camera()
	_apply_viewport_offset()
	_sync_pov_tuner_values()


func _build_view() -> void:
	clip_contents = true
	viewport_container = SubViewportContainer.new()
	viewport_container.name = "MovementDiceViewportContainer"
	viewport_container.stretch = false
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_viewport_offset()
	add_child(viewport_container)

	viewport = SubViewport.new()
	viewport.name = "MovementDicePhysicsViewport"
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)

	scene_root = Node3D.new()
	scene_root.name = "PhysicsScene"
	viewport.add_child(scene_root)

	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.018, 0.035, 0.052, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.94, 0.98)
	env.ambient_light_energy = 0.72
	environment.environment = env
	scene_root.add_child(environment)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = camera_fov
	camera.near = 0.05
	camera.far = 100.0
	camera.current = true
	scene_root.add_child(camera)
	_update_camera()

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_energy = 3.2
	key_light.shadow_enabled = true
	key_light.position = Vector3(-4.8, 9.5, 5.6)
	scene_root.add_child(key_light)
	key_light.look_at(Vector3.ZERO)

	var fill_light := OmniLight3D.new()
	fill_light.name = "SoftFillLight"
	fill_light.omni_range = 9.0
	fill_light.light_energy = 0.72
	fill_light.light_color = Color(0.96, 0.92, 0.84)
	fill_light.position = Vector3(3.4, 3.4, 3.8)
	scene_root.add_child(fill_light)

	visible_root = Node3D.new()
	visible_root.name = "VisiblePhysicsRoot"
	scene_root.add_child(visible_root)

	dice_physics_material = PhysicsMaterial.new()
	dice_physics_material.friction = 0.52
	dice_physics_material.bounce = 0.24

	table_physics_material = PhysicsMaterial.new()
	table_physics_material.friction = 0.55
	table_physics_material.bounce = 0.28

	wall_physics_material = PhysicsMaterial.new()
	wall_physics_material.friction = 0.42
	wall_physics_material.bounce = 0.22

	rounded_die_mesh = _make_flat_beveled_cube_mesh(DIE_SIZE, 0.045)
	pip_mesh = _make_cylinder_mesh(PIP_RADIUS, PIP_DEPTH, 26)
	die_body_material = _make_die_material(Color(0.965, 0.953, 0.914))
	pip_material = _make_standard_material(Color(0.035, 0.04, 0.046), 0.42, 0.02)

	_create_table_scene()
	_create_map_node_scene()
	_create_selection_buttons()
	_create_pov_tuner_panel()
	_sync_map_visual_visibility()
	_resize_viewport()
	_layout_selection_buttons()


func _resize_viewport() -> void:
	if viewport == null:
		return
	var target_size := Vector2i(maxi(1, int(size.x)), maxi(1, int(size.y)))
	viewport.size = target_size
	_apply_viewport_offset()


func _apply_viewport_offset() -> void:
	if viewport_container == null:
		return
	viewport_container.offset_left = view_offset.x
	viewport_container.offset_top = view_offset.y
	viewport_container.offset_right = view_offset.x
	viewport_container.offset_bottom = view_offset.y


func _update_camera() -> void:
	if camera == null:
		return
	camera.fov = camera_fov
	camera.global_position = camera_position
	if camera_position.distance_to(camera_target) > 0.01:
		camera.look_at(camera_target)
	_refresh_pov_tuner_summary()
	if not selection_buttons.is_empty():
		_layout_selection_buttons()


func _create_table_scene() -> void:
	var table_material := _make_standard_material(Color(0.11, 0.15, 0.23), 0.62, 0.0)
	var wall_material := _make_standard_material(Color(0.17, 0.22, 0.34), 0.56, 0.0)

	board_mesh_instance = MeshInstance3D.new()
	board_mesh_instance.name = "PerspectiveMapBoard"
	var plane := PlaneMesh.new()
	plane.size = Vector2(TABLE_WIDTH, TABLE_DEPTH)
	board_mesh_instance.mesh = plane
	board_mesh_instance.position = Vector3(0.0, 0.012, 0.0)
	visible_root.add_child(board_mesh_instance)
	_refresh_board_material()

	_add_static_box(
		"PhysicsTable",
		Vector3(0.0, -TABLE_THICKNESS * 0.5, 0.0),
		Vector3(TABLE_WIDTH, TABLE_THICKNESS, TABLE_DEPTH),
		table_physics_material,
		table_material
	)
	_add_static_box(
		"LeftWall",
		Vector3(-TABLE_WIDTH * 0.5 - WALL_THICKNESS * 0.5, WALL_HEIGHT * 0.5, 0.0),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, TABLE_DEPTH + WALL_THICKNESS * 2.0),
		wall_physics_material,
		wall_material
	)
	_add_static_box(
		"RightWall",
		Vector3(TABLE_WIDTH * 0.5 + WALL_THICKNESS * 0.5, WALL_HEIGHT * 0.5, 0.0),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, TABLE_DEPTH + WALL_THICKNESS * 2.0),
		wall_physics_material,
		wall_material
	)
	_add_static_box(
		"BackWall",
		Vector3(0.0, WALL_HEIGHT * 0.5, -TABLE_DEPTH * 0.5 - WALL_THICKNESS * 0.5),
		Vector3(TABLE_WIDTH + WALL_THICKNESS * 2.0, WALL_HEIGHT, WALL_THICKNESS),
		wall_physics_material,
		wall_material
	)
	_add_static_box(
		"FrontWall",
		Vector3(0.0, WALL_HEIGHT * 0.5, TABLE_DEPTH * 0.5 + WALL_THICKNESS * 0.5),
		Vector3(TABLE_WIDTH + WALL_THICKNESS * 2.0, WALL_HEIGHT, WALL_THICKNESS),
		wall_physics_material,
		wall_material
	)


func _add_static_box(
	node_name: String,
	position: Vector3,
	box_size: Vector3,
	physics_material: PhysicsMaterial,
	visual_material: Material = null
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.physics_material_override = physics_material
	visible_root.add_child(body)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = box_size
	shape.shape = box
	body.add_child(shape)

	if visual_material != null:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "%sMesh" % node_name
		var box_mesh := BoxMesh.new()
		box_mesh.size = box_size
		mesh_instance.mesh = box_mesh
		mesh_instance.material_override = visual_material
		body.add_child(mesh_instance)
		table_visual_nodes.append(body)
	return body


func _create_map_node_scene() -> void:
	map_node_root = Node3D.new()
	map_node_root.name = "MapRouteNodeRoot3D"
	visible_root.add_child(map_node_root)

	player_marker_sprite = Sprite3D.new()
	player_marker_sprite.name = "PlayerMarker3D"
	player_marker_sprite.pixel_size = 0.0045
	player_marker_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	player_marker_sprite.texture = _player_marker_texture()
	player_marker_sprite.position = _route_world_position(current_map_index, max(1, map_nodes.size())) + Vector3(0.0, 0.18, 0.0)
	visible_root.add_child(player_marker_sprite)
	_sync_map_visual_visibility()


func _refresh_board_material() -> void:
	if board_mesh_instance == null:
		return
	var material := _make_standard_material(Color(0.92, 0.75, 0.44), 0.68, 0.0)
	material.albedo_texture = _board_texture()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	board_mesh_instance.material_override = material
	_sync_map_visual_visibility()


func _refresh_map_visuals() -> void:
	if map_node_root == null:
		return
	if not map_visuals_enabled:
		_sync_map_visual_visibility()
		return

	_ensure_node_visuals(map_nodes.size())
	for index in range(node_visuals.size()):
		var node_visual := node_visuals[index]
		var active := index < map_nodes.size()
		node_visual.visible = active
		if not active:
			continue

		var node_data := map_nodes[index] as Dictionary
		var node_type := StringName(str(node_data.get("node_type", "event")))
		var is_current := int(node_data.get("index", index)) == current_map_index
		var is_cleared := bool(node_data.get("is_cleared", false))
		node_visual.position = _route_world_position(index, map_nodes.size())
		node_visual.scale = Vector3.ONE * (1.15 if is_current else 1.0)

		var sprite := node_visual.get_node("NodeSprite") as Sprite3D
		sprite.texture = _node_texture_for_type(node_type)
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.72 if is_cleared else 1.0)

		var label := node_visual.get_node("NodeLabel") as Label3D
		label.text = _node_short_name(node_type)
		label.modulate = Color(1.0, 0.86, 0.31, 1.0 if not is_cleared else 0.7)

	if player_marker_sprite != null:
		player_marker_sprite.texture = _player_marker_texture()
		player_marker_sprite.visible = map_visuals_enabled and not map_nodes.is_empty()
		player_marker_sprite.position = _route_world_position(current_map_index, max(1, map_nodes.size())) + Vector3(0.0, 0.18, 0.0)
	_sync_map_visual_visibility()


func _sync_map_visual_visibility() -> void:
	if board_mesh_instance != null:
		board_mesh_instance.visible = map_visuals_enabled
	if map_node_root != null:
		map_node_root.visible = map_visuals_enabled
	if player_marker_sprite != null:
		player_marker_sprite.visible = map_visuals_enabled and not map_nodes.is_empty()
	for visual_node in table_visual_nodes:
		if visual_node != null and is_instance_valid(visual_node):
			visual_node.visible = map_visuals_enabled
	if pov_tuner_panel != null:
		pov_tuner_panel.visible = map_visuals_enabled


func _ensure_node_visuals(count: int) -> void:
	while node_visuals.size() < count:
		var index := node_visuals.size()
		var root := Node3D.new()
		root.name = "MapNode3D_%02d" % [index]
		map_node_root.add_child(root)

		var sprite := Sprite3D.new()
		sprite.name = "NodeSprite"
		sprite.pixel_size = 0.0046
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.position = Vector3(0.0, 0.16, 0.0)
		root.add_child(sprite)

		var label := Label3D.new()
		label.name = "NodeLabel"
		label.font_size = 46
		label.pixel_size = 0.0047
		label.outline_size = 7
		label.outline_modulate = Color(0.0, 0.0, 0.0, 0.86)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0.0, -0.16, 0.0)
		root.add_child(label)

		node_visuals.append(root)


func _route_world_position(index: int, count: int) -> Vector3:
	var positions := _route_world_positions(maxi(1, count))
	if positions.is_empty():
		return Vector3.ZERO
	return positions[wrapi(index, 0, positions.size())]


func _route_world_positions(count: int) -> Array[Vector3]:
	if count == 32:
		return _route_world_positions_for_32_nodes()

	var result: Array[Vector3] = []
	var left := -TABLE_WIDTH * 0.5 + 0.78
	var right := TABLE_WIDTH * 0.5 - 0.78
	var top := -TABLE_DEPTH * 0.5 + 0.72
	var bottom := TABLE_DEPTH * 0.5 - 0.72
	var width := maxf(1.0, right - left)
	var depth := maxf(1.0, bottom - top)
	var perimeter := width * 2.0 + depth * 2.0
	for route_index in range(count):
		var distance := perimeter * float(route_index) / float(maxi(1, count))
		var position := Vector3.ZERO
		if distance <= width:
			position = Vector3(left + distance, 0.11, top)
		elif distance <= width + depth:
			position = Vector3(right, 0.11, top + distance - width)
		elif distance <= width * 2.0 + depth:
			position = Vector3(right - (distance - width - depth), 0.11, bottom)
		else:
			position = Vector3(left, 0.11, bottom - (distance - width * 2.0 - depth))
		result.append(position)
	return result


func _route_world_positions_for_32_nodes() -> Array[Vector3]:
	var left := -TABLE_WIDTH * 0.5 + 0.78
	var right := TABLE_WIDTH * 0.5 - 0.78
	var top := -TABLE_DEPTH * 0.5 + 0.72
	var bottom := TABLE_DEPTH * 0.5 - 0.72
	var result: Array[Vector3] = []
	result.append_array(_line_world_positions(Vector3(left, 0.11, top), Vector3(right, 0.11, top), 11))
	result.append_array(_line_world_positions(Vector3(right, 0.11, top), Vector3(right, 0.11, bottom), 7).slice(1, 6))
	result.append_array(_line_world_positions(Vector3(right, 0.11, bottom), Vector3(left, 0.11, bottom), 11))
	result.append_array(_line_world_positions(Vector3(left, 0.11, bottom), Vector3(left, 0.11, top), 7).slice(1, 6))
	return result


func _line_world_positions(start: Vector3, end: Vector3, count: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if count <= 1:
		result.append(start)
		return result
	for index in range(count):
		var t := float(index) / float(count - 1)
		result.append(start.lerp(end, t))
	return result


func _create_selection_buttons() -> void:
	for index in range(2):
		var button := Button.new()
		button.name = "MovementDice_%d" % [index + 1]
		button.text = ""
		button.toggle_mode = false
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.z_index = 420
		button.tooltip_text = "点击选择是否投掷；至少选择一颗普通六面骰"
		button.pressed.connect(func() -> void:
			die_pressed.emit(index)
		)
		add_child(button)
		selection_buttons.append(button)


func _create_pov_tuner_panel() -> void:
	pov_tuner_panel = PanelContainer.new()
	pov_tuner_panel.name = "MapPovTunerPanel"
	pov_tuner_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pov_tuner_panel.z_index = 520
	pov_tuner_panel.anchor_left = 1.0
	pov_tuner_panel.anchor_top = 0.0
	pov_tuner_panel.anchor_right = 1.0
	pov_tuner_panel.anchor_bottom = 0.0
	pov_tuner_panel.offset_left = -386.0
	pov_tuner_panel.offset_top = 14.0
	pov_tuner_panel.offset_right = -14.0
	pov_tuner_panel.offset_bottom = 456.0
	pov_tuner_panel.add_theme_stylebox_override("panel", _make_pov_panel_style())
	add_child(pov_tuner_panel)

	var root := VBoxContainer.new()
	root.name = "MapPovTunerRoot"
	root.add_theme_constant_override("separation", 8)
	pov_tuner_panel.add_child(root)

	var title := Label.new()
	title.text = "地图视角调节"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.93, 0.72, 1.0))
	root.add_child(title)

	pov_tuner_summary_label = Label.new()
	pov_tuner_summary_label.name = "MapPovTunerSummary"
	pov_tuner_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pov_tuner_summary_label.add_theme_font_size_override("font_size", 13)
	pov_tuner_summary_label.add_theme_color_override("font_color", Color(0.86, 0.94, 0.89, 1.0))
	root.add_child(pov_tuner_summary_label)

	_create_pov_slider_row(root, "视野角", "fov", 25.0, 85.0, 0.25)
	_create_pov_slider_row(root, "位置 X", "pos_x", -6.0, 6.0, 0.05)
	_create_pov_slider_row(root, "位置 Y", "pos_y", 2.0, 18.0, 0.05)
	_create_pov_slider_row(root, "位置 Z", "pos_z", 0.0, 16.0, 0.05)
	_create_pov_slider_row(root, "看向 X", "target_x", -6.0, 6.0, 0.05)
	_create_pov_slider_row(root, "看向 Y", "target_y", -5.0, 5.0, 0.05)
	_create_pov_slider_row(root, "看向 Z", "target_z", -6.0, 6.0, 0.05)
	_create_pov_slider_row(root, "画面 X", "view_x", -520.0, 520.0, 1.0)
	_create_pov_slider_row(root, "画面 Y", "view_y", -520.0, 520.0, 1.0)

	var button_row := HBoxContainer.new()
	button_row.name = "MapPovTunerButtons"
	button_row.add_theme_constant_override("separation", 8)
	root.add_child(button_row)

	var copy_button := Button.new()
	copy_button.name = "CopyMapPovButton"
	copy_button.text = "复制参数"
	copy_button.focus_mode = Control.FOCUS_NONE
	copy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_button.add_theme_stylebox_override("normal", _make_pov_button_style(Color(0.18, 0.31, 0.26, 0.96)))
	copy_button.add_theme_stylebox_override("hover", _make_pov_button_style(Color(0.24, 0.42, 0.34, 0.98)))
	copy_button.add_theme_stylebox_override("pressed", _make_pov_button_style(Color(0.14, 0.25, 0.21, 1.0)))
	copy_button.pressed.connect(_copy_pov_parameters)
	button_row.add_child(copy_button)

	var reset_button := Button.new()
	reset_button.name = "ResetMapPovButton"
	reset_button.text = "重置默认"
	reset_button.focus_mode = Control.FOCUS_NONE
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.add_theme_stylebox_override("normal", _make_pov_button_style(Color(0.28, 0.22, 0.14, 0.96)))
	reset_button.add_theme_stylebox_override("hover", _make_pov_button_style(Color(0.42, 0.32, 0.18, 0.98)))
	reset_button.add_theme_stylebox_override("pressed", _make_pov_button_style(Color(0.22, 0.17, 0.11, 1.0)))
	reset_button.pressed.connect(_reset_pov_parameters)
	button_row.add_child(reset_button)

	pov_tuner_status_label = Label.new()
	pov_tuner_status_label.name = "MapPovTunerStatus"
	pov_tuner_status_label.text = "调好后把上面的参数发给我。"
	pov_tuner_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pov_tuner_status_label.add_theme_font_size_override("font_size", 13)
	pov_tuner_status_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 1.0))
	root.add_child(pov_tuner_status_label)

	_sync_pov_tuner_values()


func _create_pov_slider_row(parent: VBoxContainer, label_text: String, key: String, min_value: float, max_value: float, step: float) -> void:
	var row := HBoxContainer.new()
	row.name = "MapPovTuner_%s" % [key]
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(58.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.94, 0.91, 0.78, 1.0))
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = "Slider"
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(value: float) -> void:
		_set_pov_value(key, value)
	)
	row.add_child(slider)

	var spin := SpinBox.new()
	spin.name = "Value"
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(82.0, 0.0)
	spin.focus_mode = Control.FOCUS_CLICK
	spin.value_changed.connect(func(value: float) -> void:
		_set_pov_value(key, value)
	)
	row.add_child(spin)

	pov_tuner_rows[key] = {
		"slider": slider,
		"spin": spin,
	}


func _set_pov_value(key: String, value: float) -> void:
	if pov_tuner_syncing:
		return
	match key:
		"fov":
			camera_fov = value
		"pos_x":
			camera_position.x = value
		"pos_y":
			camera_position.y = value
		"pos_z":
			camera_position.z = value
		"target_x":
			camera_target.x = value
		"target_y":
			camera_target.y = value
		"target_z":
			camera_target.z = value
		"view_x":
			view_offset.x = value
			_apply_viewport_offset()
		"view_y":
			view_offset.y = value
			_apply_viewport_offset()
	_update_camera()
	_sync_pov_tuner_values()


func _sync_pov_tuner_values() -> void:
	if pov_tuner_rows.is_empty():
		_refresh_pov_tuner_summary()
		return
	pov_tuner_syncing = true
	var values := _pov_values()
	for key in pov_tuner_rows.keys():
		var row: Dictionary = pov_tuner_rows[key]
		var value := float(values.get(key, 0.0))
		var slider := row.get("slider") as Range
		if slider != null:
			slider.value = value
		var spin := row.get("spin") as Range
		if spin != null:
			spin.value = value
	pov_tuner_syncing = false
	_refresh_pov_tuner_summary()


func _pov_values() -> Dictionary:
	return {
		"fov": camera_fov,
		"pos_x": camera_position.x,
		"pos_y": camera_position.y,
		"pos_z": camera_position.z,
		"target_x": camera_target.x,
		"target_y": camera_target.y,
		"target_z": camera_target.z,
		"view_x": view_offset.x,
		"view_y": view_offset.y,
	}


func _refresh_pov_tuner_summary() -> void:
	if pov_tuner_summary_label == null:
		return
	pov_tuner_summary_label.text = _format_pov_parameters()


func _format_pov_parameters() -> String:
	return "视野角 %.2f｜位置 (%.2f, %.2f, %.2f)｜看向 (%.2f, %.2f, %.2f)｜画面偏移 (%.0f, %.0f)" % [
		camera_fov,
		camera_position.x,
		camera_position.y,
		camera_position.z,
		camera_target.x,
		camera_target.y,
		camera_target.z,
		view_offset.x,
		view_offset.y,
	]


func _copy_pov_parameters() -> void:
	DisplayServer.clipboard_set(_format_pov_parameters())
	if pov_tuner_status_label != null:
		pov_tuner_status_label.text = "已复制，把参数发给我即可。"


func _reset_pov_parameters() -> void:
	camera_fov = DEFAULT_CAMERA_FOV
	camera_position = DEFAULT_CAMERA_POSITION
	camera_target = DEFAULT_CAMERA_TARGET
	view_offset = DEFAULT_VIEW_OFFSET
	_update_camera()
	_apply_viewport_offset()
	_sync_pov_tuner_values()
	if pov_tuner_status_label != null:
		pov_tuner_status_label.text = "已恢复默认视角。"


func _make_pov_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.055, 0.045, 0.88)
	style.border_color = Color(0.74, 0.62, 0.33, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	return style


func _make_pov_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.95, 0.82, 0.48, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style


func _layout_selection_buttons() -> void:
	if selection_buttons.is_empty():
		return
	var max_width := maxf(1.0, size.x)
	var max_height := maxf(1.0, size.y)
	var base_button_size := Vector2(98.0, 112.0)
	var scale_factor := clampf(minf(max_width / 1280.0, max_height / 720.0), 0.72, 1.22)
	var button_size := base_button_size * scale_factor
	for index in range(selection_buttons.size()):
		var button := selection_buttons[index]
		button.size = button_size
		var center := _project_world_to_control(_idle_position_for_die(index) + Vector3(0.0, 0.28, 0.0), Vector2(max_width, max_height))
		button.position = center - button_size * 0.5


func _update_selection_buttons() -> void:
	for index in range(selection_buttons.size()):
		var button := selection_buttons[index]
		var is_selected := selected_indices.has(index)
		button.button_pressed = is_selected
		button.disabled = interactions_disabled
		_apply_button_style(button, is_selected)


func _apply_button_style(button: Button, selected: bool) -> void:
	var normal := _make_selection_button_style(selected, false)
	var hover := _make_selection_button_style(selected, true)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)


func _make_selection_button_style(selected: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.93, 0.70, 0.08 if selected else 0.0)
	style.border_color = Color(1.0, 0.78, 0.24, 0.92 if selected else 0.0)
	if hover and not selected:
		style.border_color = Color(1.0, 0.9, 0.58, 0.42)
	style.set_border_width_all(2 if selected or hover else 0)
	style.set_corner_radius_all(8)
	return style


func _start_roll(rolls: Array, indices: Array[int]) -> void:
	_clear_dice()
	rolling = true
	rolled_indices = indices.duplicate()
	target_values = [0, 0]
	last_values = [0, 0]
	quiet_frame_count = 0
	settle_timer = 0.0
	roll_elapsed = 0.0
	recorded_elapsed = 0.0
	recorded_duration = 0.0
	recorded_trajectories = [[], []]

	var targets := [null, null]
	for index in rolled_indices:
		var pip := _roll_value_at(rolls, index)
		targets[index] = pip
		target_values[index] = pip

	var result := throw_service.solve_throw(2, targets, {
		"entry_height": 3.25,
		"max_attempts_per_die": 512,
		"min_path_separation": 0.9,
		"min_final_separation": 0.9,
		"min_table_margin": 0.55,
	})
	var plans: Array = result.get("plans", [])
	recorded_playback = _plans_have_selected_trajectories(plans, rolled_indices)

	dice.resize(2)
	for die_index in range(2):
		var body := _create_die_body(die_index)
		visible_root.add_child(body)
		dice[die_index] = body
		if rolled_indices.has(die_index):
			var params: Dictionary = plans[die_index] if die_index < plans.size() and plans[die_index] is Dictionary else _make_initial_params(die_index, 2)
			_apply_params_to_body(body, params)
			if recorded_playback:
				var trajectory: Array = params.get("trajectory", [])
				recorded_trajectories[die_index] = trajectory
				recorded_duration = maxf(recorded_duration, maxf(0.0, float(trajectory.size() - 1) / 60.0))
				body.freeze = true
				_apply_trajectory_frame(body, trajectory, 0.0)
		else:
			_place_idle_body(body, die_index, display_values[die_index])

	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not rolling:
		set_physics_process(false)
		return

	roll_elapsed += delta
	if recorded_playback:
		_update_recorded_playback(delta)
		return

	var all_quiet := true
	for die_index in rolled_indices:
		var body := dice[die_index] as RigidBody3D
		if not _is_body_quiet(body):
			all_quiet = false
			break

	if all_quiet:
		quiet_frame_count += 1
		settle_timer += delta
	else:
		quiet_frame_count = 0
		settle_timer = 0.0

	if quiet_frame_count >= QUIET_FRAMES or settle_timer > 0.75 or roll_elapsed >= MAX_ROLL_SECONDS:
		_finish_roll()


func _update_recorded_playback(delta: float) -> void:
	recorded_elapsed += delta
	for die_index in rolled_indices:
		var body := dice[die_index] as RigidBody3D
		var trajectory := recorded_trajectories[die_index] as Array
		if body == null or not is_instance_valid(body):
			continue
		_apply_trajectory_frame(body, trajectory, recorded_elapsed)
	if recorded_elapsed >= recorded_duration:
		_finish_roll()


func _finish_roll() -> void:
	for die_index in rolled_indices:
		var body := dice[die_index] as RigidBody3D
		if body == null or not is_instance_valid(body):
			continue
		last_values[die_index] = _get_up_face_value(body)
		display_values[die_index] = last_values[die_index]
		body.freeze = true

	rolling = false
	recorded_playback = false
	set_physics_process(false)


func _set_idle_dice(values: Array[int]) -> void:
	_clear_dice()
	display_values = [
		_roll_value_at(values, 0),
		_roll_value_at(values, 1),
	]
	last_values = [0, 0]
	dice.resize(2)
	for die_index in range(2):
		var body := _create_die_body(die_index)
		visible_root.add_child(body)
		dice[die_index] = body
		_place_idle_body(body, die_index, display_values[die_index])


func _clear_dice() -> void:
	for body_value in dice:
		var body := body_value as RigidBody3D
		if body != null and is_instance_valid(body):
			body.queue_free()
	dice.clear()
	rolling = false
	recorded_playback = false
	recorded_elapsed = 0.0
	recorded_duration = 0.0
	recorded_trajectories.clear()


func _create_die_body(index: int) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = "MapPhysicsDie%d" % [index + 1]
	body.mass = 1.0
	body.linear_damp = 0.018
	body.angular_damp = 0.038
	body.can_sleep = true
	body.physics_material_override = dice_physics_material

	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(DIE_SIZE, DIE_SIZE, DIE_SIZE)
	shape.shape = box
	body.add_child(shape)
	body.add_child(_create_die_visual())
	return body


func _create_die_visual() -> Node3D:
	var group := Node3D.new()
	group.name = "DieVisual"

	var cube := MeshInstance3D.new()
	cube.name = "RoundedDieBody"
	cube.mesh = rounded_die_mesh
	cube.material_override = die_body_material
	group.add_child(cube)

	for face in FACE_DEFINITIONS:
		var value := int(face["value"])
		var normal := face["normal"] as Vector3
		var u := face["u"] as Vector3
		var v := face["v"] as Vector3
		for offsets in _get_pip_pattern(value):
			var pip := MeshInstance3D.new()
			pip.name = "Pip%d" % value
			pip.mesh = pip_mesh
			pip.material_override = pip_material
			pip.position = normal * (DIE_HALF + PIP_DEPTH * 0.5 + 0.003) + u * float(offsets[0]) + v * float(offsets[1])
			pip.basis = _basis_from_y_to(normal)
			group.add_child(pip)
	return group


func _place_idle_body(body: RigidBody3D, die_index: int, pip: int) -> void:
	body.freeze = true
	body.global_transform = Transform3D(_basis_for_up_value(pip), _idle_position_for_die(die_index))
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.sleeping = true


func _idle_position_for_die(index: int) -> Vector3:
	var spacing := 1.22
	return Vector3((float(index) - 0.5) * spacing, DIE_HALF + 0.08, 0.45)


func _project_world_to_control(world_position: Vector3, fallback_size: Vector2) -> Vector2:
	if camera == null:
		return fallback_size * 0.5
	var projected := camera.unproject_position(world_position)
	return Vector2(projected.x, projected.y) + view_offset


func _apply_params_to_body(body: RigidBody3D, params: Dictionary) -> void:
	var q := params["quaternion"] as Quaternion
	body.freeze = false
	body.global_transform = Transform3D(Basis(q), params["position"] as Vector3)
	body.linear_velocity = params["velocity"] as Vector3
	body.angular_velocity = params["angular_velocity"] as Vector3
	body.sleeping = false


func _apply_trajectory_frame(body: RigidBody3D, trajectory: Array, elapsed: float) -> void:
	if trajectory.is_empty():
		return
	var frame_position := elapsed * 60.0
	var frame_index := clampi(int(floor(frame_position)), 0, trajectory.size() - 1)
	var next_index := clampi(frame_index + 1, 0, trajectory.size() - 1)
	var t := clampf(frame_position - float(frame_index), 0.0, 1.0)
	var frame := trajectory[frame_index] as Dictionary
	var next_frame := trajectory[next_index] as Dictionary
	var position := (frame["position"] as Vector3).lerp(next_frame["position"] as Vector3, t)
	var q := (frame["quaternion"] as Quaternion).slerp(next_frame["quaternion"] as Quaternion, t).normalized()
	body.global_transform = Transform3D(Basis(q), position)
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO


func _make_initial_params(index: int, count: int) -> Dictionary:
	var cols := int(ceil(float(count) / 2.0))
	var col := index % cols
	var row := int(floor(float(index) / float(cols)))
	var spacing_x := 1.18
	var spacing_z := 1.0
	var lane_x := (float(col) - (float(cols) - 1.0) * 0.5) * spacing_x
	var lane_z := (float(row) - 0.5) * spacing_z
	var q := Basis.from_euler(Vector3(
		rng.randf_range(0.0, TAU),
		rng.randf_range(0.0, TAU),
		rng.randf_range(0.0, TAU)
	)).get_rotation_quaternion()
	return {
		"position": Vector3(lane_x + rng.randf_range(-0.18, 0.18), 3.25 + rng.randf_range(0.0, 0.65), lane_z + rng.randf_range(-0.18, 0.18)),
		"quaternion": q,
		"velocity": Vector3(rng.randf_range(-1.15, 1.15), rng.randf_range(-0.64, 0.08), rng.randf_range(-1.2, 1.2)),
		"angular_velocity": Vector3(
			rng.randf_range(-8.8, 8.8),
			rng.randf_range(-8.8, 8.8),
			rng.randf_range(-8.8, 8.8)
		),
	}


func _plans_have_selected_trajectories(plans: Array, indices: Array[int]) -> bool:
	if plans.size() < 2:
		return false
	for die_index in indices:
		if die_index < 0 or die_index >= plans.size() or not (plans[die_index] is Dictionary):
			return false
		var trajectory: Array = (plans[die_index] as Dictionary).get("trajectory", [])
		if trajectory.size() < 2:
			return false
	return true


func _has_valid_dice() -> bool:
	if dice.size() < 2:
		return false
	for index in range(2):
		var body := dice[index] as RigidBody3D
		if body == null or not is_instance_valid(body):
			return false
	return true


func _active_dice_count() -> int:
	var count := 0
	for body_value in dice:
		var body := body_value as RigidBody3D
		if body != null and is_instance_valid(body):
			count += 1
	return count


func _is_body_quiet(body: RigidBody3D) -> bool:
	if body == null or not is_instance_valid(body):
		return true
	return body.global_position.y < 1.1 and body.linear_velocity.length() < QUIET_LINEAR and body.angular_velocity.length() < QUIET_ANGULAR


func _get_up_face_value(body: RigidBody3D) -> int:
	var best_value := 1
	var best_dot := -INF
	var basis := body.global_transform.basis
	for face in FACE_DEFINITIONS:
		var normal := basis * (face["normal"] as Vector3)
		var dot := normal.dot(Vector3.UP)
		if dot > best_dot:
			best_dot = dot
			best_value = int(face["value"])
	return best_value


func _basis_for_up_value(value: int) -> Basis:
	var face_normal := Vector3.UP
	for face in FACE_DEFINITIONS:
		if int(face["value"]) == clampi(value, 1, 6):
			face_normal = face["normal"] as Vector3
			break
	return _basis_from_to(face_normal, Vector3.UP)


func _basis_from_to(source_normal: Vector3, target_normal: Vector3) -> Basis:
	var source := source_normal.normalized()
	var target := target_normal.normalized()
	if source.is_equal_approx(target):
		return Basis.IDENTITY
	if source.is_equal_approx(-target):
		var helper := Vector3.RIGHT if absf(source.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
		return Basis(source.cross(helper).normalized(), PI)
	var axis := source.cross(target).normalized()
	var angle := acos(clampf(source.dot(target), -1.0, 1.0))
	return Basis(axis, angle)


func _get_pip_pattern(value: int) -> Array:
	var d := PIP_SPACING
	match value:
		1:
			return [[0.0, 0.0]]
		2:
			return [[-d, -d], [d, d]]
		3:
			return [[-d, -d], [0.0, 0.0], [d, d]]
		4:
			return [[-d, -d], [-d, d], [d, -d], [d, d]]
		5:
			return [[-d, -d], [-d, d], [0.0, 0.0], [d, -d], [d, d]]
		6:
			return [[-d, -d], [-d, 0.0], [-d, d], [d, -d], [d, 0.0], [d, d]]
		_:
			return []


func _make_flat_beveled_cube_mesh(cube_size: float, bevel: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := cube_size * 0.5
	var inner := half - bevel
	var axis_data := [
		{"normal": Vector3.RIGHT, "u": Vector3.BACK, "v": Vector3.UP},
		{"normal": Vector3.LEFT, "u": Vector3.FORWARD, "v": Vector3.UP},
		{"normal": Vector3.UP, "u": Vector3.RIGHT, "v": Vector3.FORWARD},
		{"normal": Vector3.DOWN, "u": Vector3.RIGHT, "v": Vector3.BACK},
		{"normal": Vector3.BACK, "u": Vector3.RIGHT, "v": Vector3.UP},
		{"normal": Vector3.FORWARD, "u": Vector3.LEFT, "v": Vector3.UP},
	]

	for face in axis_data:
		var normal := face["normal"] as Vector3
		var u := face["u"] as Vector3
		var v := face["v"] as Vector3
		_add_flat_quad(
			st,
			normal * half + u * -inner + v * -inner,
			normal * half + u * inner + v * -inner,
			normal * half + u * inner + v * inner,
			normal * half + u * -inner + v * inner,
			normal
		)

	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var normal_xy := Vector3(sx, sy, 0.0).normalized()
			_add_flat_quad(
				st,
				Vector3(sx * half, sy * inner, -inner),
				Vector3(sx * half, sy * inner, inner),
				Vector3(sx * inner, sy * half, inner),
				Vector3(sx * inner, sy * half, -inner),
				normal_xy
			)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var normal_xz := Vector3(sx, 0.0, sz).normalized()
			_add_flat_quad(
				st,
				Vector3(sx * half, -inner, sz * inner),
				Vector3(sx * inner, -inner, sz * half),
				Vector3(sx * inner, inner, sz * half),
				Vector3(sx * half, inner, sz * inner),
				normal_xz
			)
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var normal_yz := Vector3(0.0, sy, sz).normalized()
			_add_flat_quad(
				st,
				Vector3(-inner, sy * half, sz * inner),
				Vector3(inner, sy * half, sz * inner),
				Vector3(inner, sy * inner, sz * half),
				Vector3(-inner, sy * inner, sz * half),
				normal_yz
			)

	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var corner_normal := Vector3(sx, sy, sz).normalized()
				_add_flat_triangle(
					st,
					Vector3(sx * half, sy * inner, sz * inner),
					Vector3(sx * inner, sy * half, sz * inner),
					Vector3(sx * inner, sy * inner, sz * half),
					corner_normal
				)
	return st.commit()


func _add_flat_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, normal: Vector3) -> void:
	for point in [p0, p1, p2, p0, p2, p3]:
		st.set_normal(normal)
		st.add_vertex(point)


func _add_flat_triangle(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, normal: Vector3) -> void:
	for point in [p0, p1, p2]:
		st.set_normal(normal)
		st.add_vertex(point)


func _make_cylinder_mesh(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return mesh


func _basis_from_y_to(normal: Vector3) -> Basis:
	var target := normal.normalized()
	if target.is_equal_approx(Vector3.UP):
		return Basis.IDENTITY
	if target.is_equal_approx(Vector3.DOWN):
		return Basis(Vector3.RIGHT, PI)
	var axis := Vector3.UP.cross(target).normalized()
	var angle := acos(clampf(Vector3.UP.dot(target), -1.0, 1.0))
	return Basis(axis, angle)


func _make_die_material(color: Color) -> StandardMaterial3D:
	var material := _make_standard_material(color, 0.34, 0.02)
	material.clearcoat_enabled = true
	material.clearcoat = 0.36
	material.clearcoat_roughness = 0.32
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _make_standard_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return material


func _normalize_indices(raw_indices: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for raw_index in raw_indices:
		var index := int(raw_index)
		if index < 0 or index >= 2:
			continue
		if result.has(index):
			continue
		result.append(index)
	result.sort()
	return result


func _roll_value_at(values: Array, index: int) -> int:
	if index < 0 or index >= values.size():
		return 1
	var value := int(values[index])
	return clampi(value, 1, 6) if value > 0 else 1


func _dice_positions_snapshot() -> Array:
	var positions: Array = []
	for body_value in dice:
		var body := body_value as RigidBody3D
		if body != null and is_instance_valid(body):
			positions.append(body.global_position)
	return positions


func _visible_node_count() -> int:
	if not map_visuals_enabled or map_node_root == null or not map_node_root.visible:
		return 0
	var count := 0
	for node_visual in node_visuals:
		if node_visual != null and is_instance_valid(node_visual) and node_visual.visible:
			count += 1
	return count


func _board_texture() -> Texture2D:
	if art_config != null:
		return art_config.get("board_texture") as Texture2D
	return null


func _player_marker_texture() -> Texture2D:
	if art_config != null:
		return art_config.get("player_marker_texture") as Texture2D
	return null


func _node_texture_for_type(node_type: StringName) -> Texture2D:
	if art_config == null:
		return null
	if art_config.has_method("node_texture_for_type"):
		return art_config.call("node_texture_for_type", node_type)
	return null


func _node_short_name(node_type: StringName) -> String:
	match node_type:
		&"start":
			return "起点"
		&"battle":
			return "战斗"
		&"elite":
			return "精英"
		&"boss":
			return "首领"
		&"shop":
			return "商店"
		&"forge":
			return "铸骰"
		&"reward":
			return "奖励"
		&"penalty":
			return "惩罚"
		&"event":
			return "奇遇"
		&"rest":
			return "休整"
		_:
			return "?"
