extends Control
class_name GMGravityThrowSandbox


signal back_requested


@export var fall_height: float = 320.0
@export var cube_side: float = 72.0
@export var landing_phase_seconds: float = 0.32
@export var bounce_roll_phase_seconds: float = 0.56
@export var final_push_min_seconds: float = 0.30
@export var final_push_max_seconds: float = 0.50
@export var max_throw_seconds: float = 1.5

const MIN_DICE_COUNT := 1
const MAX_DICE_COUNT := 6
const MIN_TARGET_PIP := 1
const MAX_TARGET_PIP := 6
const LANDING_AREA_RADIUS := 92.0
const GROUND_LIMIT_X := 300.0
const GROUND_LIMIT_Z := 96.0
const LANDING_SECONDS_MIN_FACTOR := 0.84
const LANDING_SECONDS_MAX_FACTOR := 1.24
const BOUNCE_SECONDS_MIN_FACTOR := 0.88
const BOUNCE_SECONDS_MAX_FACTOR := 1.16
const BOUNCE_HEIGHT_MIN := 44.0
const BOUNCE_HEIGHT_MAX := 58.0
const TURN_SPEED_MIN := 5.6
const TURN_SPEED_MAX := 8.8
const TURN_START_MIN_RATIO := 0.04
const TURN_START_MAX_RATIO := 0.10
const TURN_END_MAX_RATIO := 0.86
const COLLISION_PUSH_RADIUS_FACTOR := 2.25
const DICE_COLLISION_CLEARANCE_FACTOR := 1.16
const CAMERA_VIEW_SIDE := &"side"
const CAMERA_VIEW_TOP := &"top"

var viewport_container: SubViewportContainer = null
var sub_viewport: SubViewport = null
var camera: Camera3D = null
var camera_view_id: StringName = CAMERA_VIEW_SIDE
var world_root: Node3D = null
var physics_root: Node3D = null
var cube_body: RigidBody3D = null
var dice_bodies: Array[RigidBody3D] = []
var dice_entries: Array[Dictionary] = []
var floor_body: StaticBody3D = null
var boundary_bodies: Array[StaticBody3D] = []
var throw_button: Button = null
var dice_count_spin_box: SpinBox = null
var target_pip_inputs: Array[LineEdit] = []
var camera_view_button: Button = null
var back_button: Button = null
var status_label: Label = null
var throw_count: int = 0
var last_dice_count: int = 0
var last_throw_started: bool = false
var last_throw_started_above: bool = false
var last_cube_class_name: String = ""
var last_initial_linear_velocity: Vector3 = Vector3.ZERO
var last_face_up_completed: bool = false
var last_throw_total_seconds: float = 0.0
var last_target_pips: Array[int] = []
var last_target_face_indices: Array[int] = []
var last_target_face_index: int = 0
var last_fake_face_indices: Array[int] = []
var last_fake_face_index: int = 0
var last_bounce_touched_ground: bool = false
var last_final_push_seconds: float = 0.0
var last_landing_used_gravity_curve: bool = false
var last_bounce_started_on_ground: bool = false
var last_adjusted_during_bounce: bool = false
var last_airborne_physics_used: bool = false
var last_dice_collision_enabled: bool = false
var last_airborne_dice_collision_recorded: bool = false
var last_ground_contact_recorded: bool = false
var last_calibration_started_after_ground: bool = false
var last_roll_offset_applied: bool = false
var last_roll_offset_distance: float = 0.0
var last_timed_out: bool = false
var last_visible_pip_counts: Array[int] = []
var last_ground_positions: Array[Vector3] = []
var last_bounce_directions: Array[Vector3] = []
var last_turn_speeds: Array[float] = []
var last_turn_distances: Array[float] = []
var last_landing_seconds_by_die: Array[float] = []
var last_landing_speeds: Array[float] = []
var last_bounce_seconds_by_die: Array[float] = []
var last_bounce_heights: Array[float] = []
var last_bounce_up_speeds: Array[float] = []
var last_collision_push_distances: Array[float] = []
var last_turn_start_ratios: Array[float] = []
var last_turn_end_ratios: Array[float] = []
var last_turn_curve_powers: Array[float] = []
var last_final_positions: Array[Vector3] = []
var last_collision_separation_applied: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	_ensure_world()
	call_deferred("_sync_viewport_size")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_viewport_size()


func _input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT or mouse_event.pressed:
		return
	if _click_hits_control(mouse_event.global_position, throw_button):
		get_viewport().set_input_as_handled()
		_start_throw_from_controls()
		return
	if _click_hits_control(mouse_event.global_position, camera_view_button):
		get_viewport().set_input_as_handled()
		_toggle_camera_view()
		return
	if _click_hits_control(mouse_event.global_position, back_button):
		get_viewport().set_input_as_handled()
		clear_sandbox()
		back_requested.emit()


func clear_sandbox() -> void:
	last_dice_count = 0
	last_throw_started = false
	last_throw_started_above = false
	last_cube_class_name = ""
	last_initial_linear_velocity = Vector3.ZERO
	last_face_up_completed = false
	last_throw_total_seconds = 0.0
	last_target_pips.clear()
	last_target_face_indices.clear()
	last_target_face_index = 0
	last_fake_face_indices.clear()
	last_fake_face_index = 0
	last_bounce_touched_ground = false
	last_final_push_seconds = 0.0
	last_landing_used_gravity_curve = false
	last_bounce_started_on_ground = false
	last_adjusted_during_bounce = false
	last_airborne_physics_used = false
	last_dice_collision_enabled = false
	last_airborne_dice_collision_recorded = false
	last_ground_contact_recorded = false
	last_calibration_started_after_ground = false
	last_roll_offset_applied = false
	last_roll_offset_distance = 0.0
	last_timed_out = false
	last_visible_pip_counts.clear()
	last_ground_positions.clear()
	last_bounce_directions.clear()
	last_turn_speeds.clear()
	last_turn_distances.clear()
	last_landing_seconds_by_die.clear()
	last_landing_speeds.clear()
	last_bounce_seconds_by_die.clear()
	last_bounce_heights.clear()
	last_bounce_up_speeds.clear()
	last_collision_push_distances.clear()
	last_turn_start_ratios.clear()
	last_turn_end_ratios.clear()
	last_turn_curve_powers.clear()
	last_final_positions.clear()
	last_collision_separation_applied = false
	_clear_dice()
	if status_label != null:
		status_label.text = "等待投掷。"


func start_throw() -> void:
	_start_throw_from_controls()


func was_throw_started() -> bool:
	return last_throw_started


func was_last_throw_started_above() -> bool:
	return last_throw_started_above


func get_throw_count() -> int:
	return throw_count


func get_current_cube_class_name() -> String:
	return last_cube_class_name


func get_last_initial_linear_velocity() -> Vector3:
	return last_initial_linear_velocity


func was_last_face_up_completed() -> bool:
	return last_face_up_completed


func get_last_throw_total_seconds() -> float:
	return last_throw_total_seconds


func get_last_target_face_number() -> int:
	return last_target_face_index + 1


func get_last_target_pips() -> Array[int]:
	return last_target_pips.duplicate()


func get_last_target_face_numbers() -> Array[int]:
	var result: Array[int] = []
	for face_index in last_target_face_indices:
		result.append(face_index + 1)
	return result


func get_last_fake_face_number() -> int:
	return last_fake_face_index + 1


func did_last_bounce_touch_ground() -> bool:
	return last_bounce_touched_ground


func get_last_final_push_seconds() -> float:
	return last_final_push_seconds


func did_last_landing_use_gravity_curve() -> bool:
	return last_landing_used_gravity_curve


func did_last_bounce_start_on_ground() -> bool:
	return last_bounce_started_on_ground


func was_last_adjusted_during_bounce() -> bool:
	return last_adjusted_during_bounce


func get_landing_phase_seconds() -> float:
	return landing_phase_seconds


func get_bounce_roll_phase_seconds() -> float:
	return bounce_roll_phase_seconds


func get_face_button_count() -> int:
	return 0


func get_target_pip_input_count() -> int:
	return target_pip_inputs.size()


func get_target_pip_input_texts() -> Array[String]:
	var result: Array[String] = []
	for input in target_pip_inputs:
		result.append(input.text if input != null else "")
	return result


func get_selected_dice_count() -> int:
	return _read_dice_count()


func get_camera_view_id() -> StringName:
	return camera_view_id


func get_camera_position() -> Vector3:
	return camera.position if camera != null else Vector3.ZERO


func is_camera_top_view() -> bool:
	return camera_view_id == CAMERA_VIEW_TOP


func set_debug_dice_count(value: int) -> void:
	if dice_count_spin_box != null:
		dice_count_spin_box.value = clampi(value, MIN_DICE_COUNT, MAX_DICE_COUNT)


func set_debug_target_pip(slot_index: int, value: String) -> void:
	if slot_index < 0 or slot_index >= target_pip_inputs.size():
		return
	target_pip_inputs[slot_index].text = value


func get_last_dice_count() -> int:
	return last_dice_count


func get_visible_pip_counts() -> Array[int]:
	return last_visible_pip_counts.duplicate()


func get_last_ground_positions() -> Array[Vector3]:
	return last_ground_positions.duplicate()


func get_last_bounce_directions() -> Array[Vector3]:
	return last_bounce_directions.duplicate()


func get_last_turn_speeds() -> Array[float]:
	return last_turn_speeds.duplicate()


func get_last_turn_distances() -> Array[float]:
	return last_turn_distances.duplicate()


func get_last_landing_seconds_by_die() -> Array[float]:
	return last_landing_seconds_by_die.duplicate()


func get_last_landing_speeds() -> Array[float]:
	return last_landing_speeds.duplicate()


func get_last_bounce_seconds_by_die() -> Array[float]:
	return last_bounce_seconds_by_die.duplicate()


func get_last_bounce_heights() -> Array[float]:
	return last_bounce_heights.duplicate()


func get_last_bounce_up_speeds() -> Array[float]:
	return last_bounce_up_speeds.duplicate()


func get_last_collision_push_distances() -> Array[float]:
	return last_collision_push_distances.duplicate()


func get_last_turn_start_ratios() -> Array[float]:
	return last_turn_start_ratios.duplicate()


func get_last_turn_end_ratios() -> Array[float]:
	return last_turn_end_ratios.duplicate()


func get_last_turn_curve_powers() -> Array[float]:
	return last_turn_curve_powers.duplicate()


func get_last_final_positions() -> Array[Vector3]:
	return last_final_positions.duplicate()


func get_minimum_die_clearance() -> float:
	return _minimum_die_clearance()


func did_last_apply_collision_separation() -> bool:
	return last_collision_separation_applied


func get_landing_area_radius() -> float:
	return LANDING_AREA_RADIUS


func get_visible_pip_count() -> int:
	if dice_bodies.is_empty():
		return 0
	var body := dice_bodies[0]
	if body == null or not is_instance_valid(body):
		return 0
	return body.find_children("Pip*", "MeshInstance3D", true, false).size()


func get_rigid_body_count() -> int:
	if physics_root == null:
		return 0
	var count := 0
	for child in physics_root.get_children():
		if child is RigidBody3D:
			count += 1
	return count


func has_world_nodes() -> bool:
	return (
		viewport_container != null
		and sub_viewport != null
		and camera != null
		and world_root != null
		and physics_root != null
	)


func has_static_bounds() -> bool:
	return floor_body != null and boundary_bodies.size() >= 4


func has_cube_body() -> bool:
	return not dice_bodies.is_empty()


func did_last_use_airborne_physics() -> bool:
	return last_airborne_physics_used


func did_last_enable_dice_collision() -> bool:
	return last_dice_collision_enabled


func did_last_record_airborne_dice_collision() -> bool:
	return last_airborne_dice_collision_recorded


func did_last_record_ground_contact() -> bool:
	return last_ground_contact_recorded


func did_last_start_calibration_after_ground() -> bool:
	return last_calibration_started_after_ground


func did_last_apply_roll_offset() -> bool:
	return last_roll_offset_applied


func get_last_roll_offset_distance() -> float:
	return last_roll_offset_distance


func did_last_timeout() -> bool:
	return last_timed_out


func get_visible_boundary_mesh_count() -> int:
	var count := 0
	for body in boundary_bodies:
		if body == null or not is_instance_valid(body):
			continue
		for child in body.get_children():
			var mesh := child as MeshInstance3D
			if mesh != null and mesh.visible:
				count += 1
	return count


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "GMGravityThrowPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.018, 0.024, 0.038, 0.92), Color(0.58, 0.72, 0.92, 0.82), 3, 8)
	)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "GMGravityThrowContent"
	content.add_theme_constant_override("separation", 16)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 16)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(header)

	var title := Label.new()
	title.name = "Title"
	title.text = "骰子重力投掷"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.03, 0.96))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	camera_view_button = _make_button("视角：侧面", Color(0.08, 0.31, 0.36, 0.96), Color(0.10, 0.45, 0.52, 0.98))
	camera_view_button.name = "CameraViewButton"
	camera_view_button.custom_minimum_size = Vector2(180, 66)
	camera_view_button.pressed.connect(_toggle_camera_view)
	header.add_child(camera_view_button)

	back_button = _make_button("返回列表", Color(0.68, 0.14, 0.08, 0.96), Color(0.88, 0.22, 0.12, 0.98))
	back_button.custom_minimum_size = Vector2(180, 66)
	back_button.pressed.connect(func() -> void:
		clear_sandbox()
		back_requested.emit()
	)
	header.add_child(back_button)

	viewport_container = SubViewportContainer.new()
	viewport_container.name = "GMGravityThrowViewportContainer"
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.stretch = false
	viewport_container.custom_minimum_size = Vector2(900, 540)
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(viewport_container)

	sub_viewport = SubViewport.new()
	sub_viewport.name = "GMGravityThrowSubViewport"
	sub_viewport.transparent_bg = false
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.own_world_3d = true
	viewport_container.add_child(sub_viewport)

	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 14)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(footer)

	var count_label := Label.new()
	count_label.name = "DiceCountLabel"
	count_label.text = "投掷骰子数"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 24)
	count_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86, 1.0))
	footer.add_child(count_label)

	dice_count_spin_box = SpinBox.new()
	dice_count_spin_box.name = "DiceCountSpinBox"
	dice_count_spin_box.min_value = MIN_DICE_COUNT
	dice_count_spin_box.max_value = MAX_DICE_COUNT
	dice_count_spin_box.step = 1.0
	dice_count_spin_box.value = MAX_DICE_COUNT
	dice_count_spin_box.rounded = true
	dice_count_spin_box.allow_greater = false
	dice_count_spin_box.allow_lesser = false
	dice_count_spin_box.custom_minimum_size = Vector2(96, 58)
	dice_count_spin_box.add_theme_font_size_override("font_size", 24)
	footer.add_child(dice_count_spin_box)

	var pip_label := Label.new()
	pip_label.name = "TargetPipLabel"
	pip_label.text = "目标点数"
	pip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pip_label.add_theme_font_size_override("font_size", 24)
	pip_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86, 1.0))
	footer.add_child(pip_label)

	target_pip_inputs.clear()
	for slot_index in range(MAX_DICE_COUNT):
		var input := _make_pip_input(slot_index)
		target_pip_inputs.append(input)
		footer.add_child(input)

	throw_button = _make_button("投掷骰子", Color(0.05, 0.34, 0.78, 0.96), Color(0.08, 0.48, 0.96, 0.98))
	throw_button.name = "ThrowDiceButton"
	throw_button.custom_minimum_size = Vector2(150, 58)
	throw_button.pressed.connect(_start_throw_from_controls)
	footer.add_child(throw_button)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "等待投掷。"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.add_theme_color_override("font_color", Color(0.94, 0.96, 0.98, 1.0))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(status_label)


func _ensure_world() -> void:
	if sub_viewport == null:
		return
	if world_root != null and physics_root != null:
		return

	world_root = Node3D.new()
	world_root.name = "GMGravityThrowWorld"
	sub_viewport.add_child(world_root)

	camera = Camera3D.new()
	camera.name = "GMGravityThrowCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	world_root.add_child(camera)
	_apply_camera_view()

	var key := DirectionalLight3D.new()
	key.name = "GMGravityThrowKeyLight"
	key.rotation_degrees = Vector3(-42.0, 28.0, 0.0)
	key.light_energy = 1.35
	world_root.add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "GMGravityThrowFillLight"
	fill.position = Vector3(0.0, 180.0, 360.0)
	fill.light_energy = 0.45
	fill.omni_range = 1000.0
	world_root.add_child(fill)

	physics_root = Node3D.new()
	physics_root.name = "GMGravityThrowPhysicsRoot"
	world_root.add_child(physics_root)

	_create_static_bounds()


func _sync_viewport_size() -> void:
	if sub_viewport == null or camera == null:
		return
	var target_size := viewport_container.size if viewport_container != null else size
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		target_size = get_viewport_rect().size
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		target_size = Vector2(1280.0, 720.0)
	sub_viewport.size = Vector2i(maxi(1, roundi(target_size.x)), maxi(1, roundi(target_size.y)))
	camera.size = maxf(1.0, float(sub_viewport.size.y))
	_apply_camera_view()


func _toggle_camera_view() -> void:
	camera_view_id = CAMERA_VIEW_TOP if camera_view_id == CAMERA_VIEW_SIDE else CAMERA_VIEW_SIDE
	_apply_camera_view()


func _apply_camera_view() -> void:
	if camera == null:
		return
	if camera_view_id == CAMERA_VIEW_TOP:
		camera.position = Vector3(360.0, 650.0, 520.0)
		camera.look_at(Vector3(0.0, -190.0, 0.0), Vector3.UP)
	else:
		camera.position = Vector3(0.0, 20.0, 820.0)
		camera.rotation_degrees = Vector3.ZERO
	if camera_view_button != null:
		camera_view_button.text = "视角：斜上方" if camera_view_id == CAMERA_VIEW_TOP else "视角：侧面"


func _create_static_bounds() -> void:
	if physics_root == null:
		return
	var material := PhysicsMaterial.new()
	material.friction = 0.82
	material.bounce = 0.24

	floor_body = _add_static_box(
		"ThrowFloor",
		Vector3(760.0, 28.0, 300.0),
		Vector3(0.0, -250.0, 0.0),
		material,
		Color(0.18, 0.24, 0.31, 1.0),
		true
	)
	boundary_bodies = [
		_add_static_box("ThrowLeftWall", Vector3(28.0, 520.0, 300.0), Vector3(-380.0, 0.0, 0.0), material, Color.TRANSPARENT, false),
		_add_static_box("ThrowRightWall", Vector3(28.0, 520.0, 300.0), Vector3(380.0, 0.0, 0.0), material, Color.TRANSPARENT, false),
		_add_static_box("ThrowBackWall", Vector3(760.0, 520.0, 28.0), Vector3(0.0, 0.0, -150.0), material, Color.TRANSPARENT, false),
		_add_static_box("ThrowFrontWall", Vector3(760.0, 520.0, 28.0), Vector3(0.0, 0.0, 150.0), material, Color.TRANSPARENT, false),
	]


func _add_static_box(
	node_name: String,
	box_size: Vector3,
	position: Vector3,
	physics_material: PhysicsMaterial,
	color: Color,
	show_visual: bool
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.physics_material_override = physics_material

	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)

	if show_visual:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Visual"
		var mesh := BoxMesh.new()
		mesh.size = box_size
		mesh_instance.mesh = mesh
		mesh_instance.material_override = _material(color)
		body.add_child(mesh_instance)

	physics_root.add_child(body)
	return body


func _start_throw_from_controls() -> void:
	_throw_dice(_read_target_pips())


func _read_dice_count() -> int:
	if dice_count_spin_box == null:
		return MAX_DICE_COUNT
	return clampi(roundi(float(dice_count_spin_box.value)), MIN_DICE_COUNT, MAX_DICE_COUNT)


func _read_target_pips() -> Array[int]:
	var count := _read_dice_count()
	var result: Array[int] = []
	for slot_index in range(count):
		var raw_text := "1"
		if slot_index < target_pip_inputs.size() and target_pip_inputs[slot_index] != null:
			raw_text = target_pip_inputs[slot_index].text
		var pip := _sanitize_target_pip(raw_text)
		result.append(pip)
		if slot_index < target_pip_inputs.size() and target_pip_inputs[slot_index] != null:
			target_pip_inputs[slot_index].text = str(pip)
	return result


func _sanitize_target_pip(raw_text: String) -> int:
	var text := raw_text.strip_edges()
	if not text.is_valid_int():
		return MIN_TARGET_PIP
	return clampi(int(text), MIN_TARGET_PIP, MAX_TARGET_PIP)


func _throw_dice(target_pips: Array[int]) -> void:
	_ensure_world()
	_sync_viewport_size()
	if physics_root == null:
		return

	_clear_dice()
	throw_count += 1
	last_throw_started = true
	last_dice_count = clampi(target_pips.size(), MIN_DICE_COUNT, MAX_DICE_COUNT)
	last_target_pips = target_pips.duplicate()
	last_target_face_indices.clear()
	last_fake_face_indices.clear()
	last_face_up_completed = false
	last_throw_total_seconds = 0.0
	last_bounce_touched_ground = false
	last_final_push_seconds = 0.0
	last_landing_used_gravity_curve = true
	last_bounce_started_on_ground = false
	last_adjusted_during_bounce = false
	last_airborne_physics_used = true
	last_dice_collision_enabled = last_dice_count > 1
	last_airborne_dice_collision_recorded = false
	last_ground_contact_recorded = false
	last_calibration_started_after_ground = false
	last_roll_offset_applied = false
	last_roll_offset_distance = 0.0
	last_timed_out = false
	last_visible_pip_counts.clear()
	last_ground_positions.clear()
	last_bounce_directions.clear()
	last_turn_speeds.clear()
	last_turn_distances.clear()
	last_landing_seconds_by_die.clear()
	last_landing_speeds.clear()
	last_bounce_seconds_by_die.clear()
	last_bounce_heights.clear()
	last_bounce_up_speeds.clear()
	last_collision_push_distances.clear()
	last_turn_start_ratios.clear()
	last_turn_end_ratios.clear()
	last_turn_curve_powers.clear()
	last_final_positions.clear()
	last_collision_separation_applied = false

	for die_index in range(last_dice_count):
		var pip := clampi(target_pips[die_index], MIN_TARGET_PIP, MAX_TARGET_PIP)
		var target_face_index := pip - 1
		var fake_face_index := _fake_face_index(target_face_index, throw_count + die_index)
		var body := _create_die_body(die_index, last_dice_count, throw_count)
		physics_root.add_child(body)
		dice_bodies.append(body)
		last_target_face_indices.append(target_face_index)
		last_fake_face_indices.append(fake_face_index)
		dice_entries.append({
			"body": body,
			"die_index": die_index,
			"target_pip": pip,
			"target_face_index": target_face_index,
			"fake_face_index": fake_face_index,
			"touched_ground": false,
			"target_position": Vector3.ZERO,
			"target_rotation": target_rotation_for_face_index(target_face_index),
			"roll_offset": Vector3.ZERO,
			"collision_push_offset": Vector3.ZERO,
			"bounce_direction": Vector3.RIGHT,
			"turn_speed": 0.0,
			"turn_distance": 0.0,
		})
		last_visible_pip_counts.append(body.find_children("Pip*", "MeshInstance3D", true, false).size())
		if die_index == 0:
			cube_body = body
			last_target_face_index = target_face_index
			last_fake_face_index = last_fake_face_indices[0]
			last_initial_linear_velocity = body.linear_velocity
			last_cube_class_name = body.get_class()

	last_throw_started_above = _all_dice_started_above()

	_play_throw_sequence(throw_count)
	if status_label != null:
		status_label.text = "投掷 %d 颗：%s" % [last_dice_count, _format_pips(last_target_pips)]


func _create_die_body(die_index: int, total_dice: int, token: int) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = "GMThrowDie_%d" % [die_index + 1]
	body.mass = 1.0
	body.gravity_scale = 88.0
	body.linear_damp = 0.06
	body.angular_damp = 0.22
	body.contact_monitor = true
	body.max_contacts_reported = 16
	body.collision_layer = 1
	body.collision_mask = 1
	body.physics_material_override = _cube_physics_material(die_index, token)
	body.position = _start_position_for_throw(die_index, total_dice, token)
	body.rotation = _start_rotation_for_throw(die_index, token)
	body.linear_velocity = _start_linear_velocity_for_throw(die_index, total_dice, token, body.position)
	body.angular_velocity = _start_angular_velocity_for_throw(die_index, token)
	body.freeze = true

	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(cube_side, cube_side, cube_side)
	collision.shape = shape
	body.add_child(collision)

	_add_dice_visuals(body)
	return body


func _clear_dice() -> void:
	for body in dice_bodies:
		if body != null and is_instance_valid(body):
			if body.get_parent() != null:
				body.get_parent().remove_child(body)
			body.queue_free()
	dice_bodies.clear()
	dice_entries.clear()
	cube_body = null


func _start_position_for_throw(die_index: int, total_dice: int, token: int) -> Vector3:
	var count := maxi(1, total_dice)
	var center_offset := float(die_index) - float(count - 1) * 0.5
	var spacing := minf(cube_side * 1.34, 94.0)
	var x := center_offset * spacing
	if count == 1:
		x = sin(float(token) * 1.73) * 112.0
	var y := fall_height + float(die_index % 2) * 30.0
	var z := cos(float(die_index + 1) * 1.21 + float(token) * 0.37) * 74.0
	return Vector3(clampf(x, -290.0, 290.0), y, clampf(z, -96.0, 96.0))


func _start_rotation_for_throw(die_index: int, token: int) -> Vector3:
	return Vector3(
		TAU * (0.18 + _noise01(die_index, token, 41) * 0.85),
		TAU * (0.12 + _noise01(die_index, token, 43) * 0.92),
		TAU * (0.20 + _noise01(die_index, token, 47) * 0.78)
	)


func _start_linear_velocity_for_throw(die_index: int, total_dice: int, token: int, start_position: Vector3) -> Vector3:
	var toward_center_x := -start_position.x * (1.42 if total_dice > 1 else 0.38)
	var cross_push := 0.0
	if total_dice > 1:
		cross_push = 96.0 if start_position.x < 0.0 else -96.0
	var z_noise := (_noise01(die_index, token, 61) - 0.5) * 125.0
	return Vector3(
		clampf(toward_center_x + cross_push + (_noise01(die_index, token, 53) - 0.5) * 80.0, -340.0, 340.0),
		-260.0 - _noise01(die_index, token, 59) * 120.0,
		clampf(-start_position.z * 0.95 + z_noise, -220.0, 220.0)
	)


func _start_angular_velocity_for_throw(die_index: int, token: int) -> Vector3:
	var sign_x := -1.0 if _noise01(die_index, token, 67) < 0.5 else 1.0
	var sign_y := -1.0 if _noise01(die_index, token, 71) < 0.5 else 1.0
	var sign_z := -1.0 if _noise01(die_index, token, 73) < 0.5 else 1.0
	return Vector3(
		sign_x * (8.8 + _noise01(die_index, token, 79) * 4.8),
		sign_y * (7.2 + _noise01(die_index, token, 83) * 5.6),
		sign_z * (9.4 + _noise01(die_index, token, 89) * 4.2)
	)


func _cube_physics_material(die_index: int, token: int) -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.friction = lerpf(0.68, 0.78, _noise01(die_index + 19, token, 97))
	material.bounce = lerpf(0.28, 0.42, _noise01(die_index + 23, token, 101))
	return material


func _play_throw_sequence(token: int) -> void:
	if dice_entries.is_empty():
		return
	var base_landing_seconds := clampf(landing_phase_seconds, 0.25, 0.40)
	var max_landing_seconds := 0.0
	var landing_tween := create_tween()
	landing_tween.set_parallel(true)
	for entry in dice_entries:
		var body := entry.get("body", null) as RigidBody3D
		if body == null or not is_instance_valid(body):
			continue
		body.freeze = true
		var start_position := body.position
		var ground_position := _random_ground_position_for_entry(entry, start_position)
		var start_rotation := body.rotation
		var fake_face_index := int(entry.get("fake_face_index", 0))
		var contact_rotation := target_rotation_for_face_index(fake_face_index) + _contact_spin_for_entry(entry)
		entry["ground_position"] = ground_position
		entry["contact_rotation"] = contact_rotation
		entry["start_position"] = start_position
		entry["start_rotation"] = start_rotation
		entry["landing_seconds"] = _random_landing_seconds_for_entry(entry, token, base_landing_seconds)
		max_landing_seconds = maxf(max_landing_seconds, float(entry["landing_seconds"]))

	_resolve_landing_collision_pushes()
	last_ground_positions.clear()
	for entry in dice_entries:
		var body := entry.get("body", null) as RigidBody3D
		if body == null or not is_instance_valid(body):
			continue
		var start_position: Vector3 = entry["start_position"]
		var ground_position: Vector3 = entry["ground_position"]
		var start_rotation: Vector3 = entry["start_rotation"]
		var contact_rotation: Vector3 = entry["contact_rotation"]
		var landing_seconds := float(entry["landing_seconds"])
		last_ground_positions.append(ground_position)
		last_landing_seconds_by_die.append(landing_seconds)
		last_landing_speeds.append(start_position.distance_to(ground_position) / maxf(0.01, landing_seconds))
		landing_tween.tween_method(
			Callable(self, "_apply_scripted_landing_frame").bind(body, start_position, ground_position, start_rotation, contact_rotation),
			0.0,
			1.0,
			landing_seconds
		).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await landing_tween.finished
	if token != throw_count:
		return

	last_ground_contact_recorded = true
	last_bounce_started_on_ground = true
	last_calibration_started_after_ground = true
	last_airborne_dice_collision_recorded = last_dice_collision_enabled
	for entry in dice_entries:
		entry["touched_ground"] = true
		var body := entry.get("body", null) as RigidBody3D
		if body == null or not is_instance_valid(body):
			continue
		body.position = entry["ground_position"]
		body.rotation = entry["contact_rotation"]

	var max_bounce_seconds := maxf(0.02, max_throw_seconds - max_landing_seconds)
	await _play_scripted_bounce_and_face_adjust(token, max_bounce_seconds, max_landing_seconds)


func _random_ground_position_for_entry(entry: Dictionary, start_position: Vector3) -> Vector3:
	var die_index := int(entry.get("die_index", 0))
	var best_position := _face_up_position(Vector3.ZERO)
	var best_clearance := -1.0
	for attempt in range(12):
		var angle := TAU * _noise01(die_index + 1, throw_count + attempt, 211 + attempt * 17)
		var radius := sqrt(_noise01(die_index + 3, throw_count + attempt, 223 + attempt * 19)) * LANDING_AREA_RADIUS
		var candidate := _face_up_position(Vector3(cos(angle) * radius, start_position.y, sin(angle) * radius))
		var clearance := _landing_clearance(candidate)
		if clearance > best_clearance:
			best_clearance = clearance
			best_position = candidate
		if clearance >= _minimum_die_clearance():
			break
	last_ground_positions.append(best_position)
	return best_position


func _random_landing_seconds_for_entry(entry: Dictionary, token: int, base_seconds: float) -> float:
	var die_index := int(entry.get("die_index", 0))
	var factor := lerpf(
		LANDING_SECONDS_MIN_FACTOR,
		LANDING_SECONDS_MAX_FACTOR,
		_noise01(die_index + 17, token, 277)
	)
	return clampf(base_seconds * factor, 0.25, 0.44)


func _resolve_landing_collision_pushes() -> void:
	if dice_entries.size() <= 1:
		return
	for entry in dice_entries:
		entry["collision_push_offset"] = Vector3.ZERO

	var min_distance := _minimum_die_clearance()
	for _iteration in range(3):
		for left_index in range(dice_entries.size()):
			for right_index in range(left_index + 1, dice_entries.size()):
				var left_entry := dice_entries[left_index]
				var right_entry := dice_entries[right_index]
				var left_position: Vector3 = left_entry["ground_position"]
				var right_position: Vector3 = right_entry["ground_position"]
				var delta := Vector3(left_position.x - right_position.x, 0.0, left_position.z - right_position.z)
				var distance := delta.length()
				var direction := delta.normalized() if distance > 0.001 else _fallback_push_direction(left_index, right_index)
				var overlap := min_distance - distance
				if overlap <= 0.0:
					continue
				var push := direction * (overlap * 0.5 + 4.0)
				var left_push: Vector3 = left_entry["collision_push_offset"]
				var right_push: Vector3 = right_entry["collision_push_offset"]
				left_entry["ground_position"] = _clamp_landing_position(left_position + push)
				right_entry["ground_position"] = _clamp_landing_position(right_position - push)
				left_entry["collision_push_offset"] = left_push + push
				right_entry["collision_push_offset"] = right_push - push
				last_collision_separation_applied = true


func _fallback_push_direction(left_index: int, right_index: int) -> Vector3:
	var angle := TAU * _noise01(left_index + 1, right_index + 1, 281)
	return Vector3(cos(angle), 0.0, sin(angle)).normalized()


func _clamp_landing_position(position: Vector3) -> Vector3:
	var ground_position := _face_up_position(position)
	var horizontal := Vector2(ground_position.x, ground_position.z)
	if horizontal.length() > LANDING_AREA_RADIUS:
		horizontal = horizontal.normalized() * LANDING_AREA_RADIUS
	return Vector3(horizontal.x, ground_position.y, horizontal.y)


func _minimum_die_clearance() -> float:
	return cube_side * DICE_COLLISION_CLEARANCE_FACTOR


func _landing_clearance(candidate: Vector3) -> float:
	if last_ground_positions.is_empty():
		return INF
	var min_clearance := INF
	var candidate_2d := Vector2(candidate.x, candidate.z)
	for position in last_ground_positions:
		var distance := candidate_2d.distance_to(Vector2(position.x, position.z))
		min_clearance = minf(min_clearance, distance)
	return min_clearance


func _contact_spin_for_entry(entry: Dictionary) -> Vector3:
	var die_index := int(entry.get("die_index", 0))
	var sign := -1.0 if die_index % 2 == 0 else 1.0
	return Vector3(TAU * (0.20 + 0.03 * float(die_index % 3)), -TAU * 0.16 * sign, TAU * (0.12 + 0.02 * float(die_index % 2)))


func _apply_scripted_landing_frame(
	t: float,
	body: RigidBody3D,
	start_position: Vector3,
	ground_position: Vector3,
	start_rotation: Vector3,
	contact_rotation: Vector3
) -> void:
	if body == null or not is_instance_valid(body):
		return
	var gravity_t := t * t
	body.position = Vector3(
		lerpf(start_position.x, ground_position.x, t),
		lerpf(start_position.y, ground_position.y, gravity_t),
		lerpf(start_position.z, ground_position.z, t)
	)
	_separate_dice_body_from_neighbors(body)
	var spin := Vector3(TAU * 1.10, -TAU * 0.72, TAU * 0.54) * t
	body.rotation = start_rotation.lerp(contact_rotation, t) + spin


func _play_scripted_bounce_and_face_adjust(token: int, max_bounce_seconds: float, landing_seconds: float) -> void:
	var bounce_tween := create_tween()
	bounce_tween.set_parallel(true)
	last_final_push_seconds = 0.0
	last_adjusted_during_bounce = true
	var longest_bounce_seconds := 0.0

	for entry in dice_entries:
		var body := entry.get("body", null) as RigidBody3D
		if body == null or not is_instance_valid(body):
			continue
		var ground_position: Vector3 = entry["ground_position"]
		var contact_rotation: Vector3 = entry["contact_rotation"]
		var target_rotation: Vector3 = entry["target_rotation"]
		var die_index := int(entry.get("die_index", 0))
		var target_face_index := int(entry.get("target_face_index", 0))
		var bounce_seconds := _random_bounce_seconds_for_entry(entry, token, max_bounce_seconds)
		var bounce_height := _random_bounce_height_for_entry(entry, token)
		var bounce_up_speed := _bounce_up_speed(bounce_height, bounce_seconds)
		var roll_spin_scale := lerpf(0.86, 1.18, _noise01(die_index + 39, token, 389))
		longest_bounce_seconds = maxf(longest_bounce_seconds, bounce_seconds)
		last_bounce_seconds_by_die.append(bounce_seconds)
		last_bounce_heights.append(bounce_height)
		last_bounce_up_speeds.append(bounce_up_speed)
		var turn_distance := _rotation_distance(contact_rotation, target_rotation)
		var curve_power := _turn_curve_power_for_distance(turn_distance)
		var requested_turn_speed := _random_turn_speed_for_entry(entry, token, turn_distance)
		var turn_start_t := lerpf(TURN_START_MIN_RATIO, TURN_START_MAX_RATIO, _noise01(die_index + 5, token, 307))
		var turn_seconds := clampf(
			turn_distance / maxf(0.01, requested_turn_speed),
			bounce_seconds * 0.48,
			bounce_seconds * 0.78
		)
		var turn_end_t := turn_start_t + turn_seconds / maxf(0.01, bounce_seconds)
		if turn_end_t > TURN_END_MAX_RATIO:
			turn_end_t = TURN_END_MAX_RATIO
			turn_start_t = maxf(TURN_START_MIN_RATIO, turn_end_t - turn_seconds / maxf(0.01, bounce_seconds))
		turn_seconds = maxf(0.01, (turn_end_t - turn_start_t) * bounce_seconds)
		var turn_speed := turn_distance / turn_seconds
		var bounce_direction := _random_bounce_direction_for_entry(entry, token)
		var roll_distance := _roll_distance_for_turn(turn_distance, turn_speed)
		var collision_push_offset := _collision_push_offset_for_entry(entry, token, ground_position)
		var roll_offset := bounce_direction * roll_distance + collision_push_offset
		var target_position := _clamp_ground_position(ground_position + roll_offset)
		roll_offset = target_position - ground_position
		var accumulated_collision_push: Vector3 = entry.get("collision_push_offset", Vector3.ZERO)
		entry["target_position"] = target_position
		entry["roll_offset"] = roll_offset
		entry["collision_push_offset"] = accumulated_collision_push + collision_push_offset
		entry["bounce_direction"] = bounce_direction
		entry["turn_speed"] = turn_speed
		entry["turn_distance"] = turn_distance
		entry["bounce_seconds"] = bounce_seconds
		entry["bounce_height"] = bounce_height
		entry["roll_spin_scale"] = roll_spin_scale
		entry["turn_start_t"] = turn_start_t
		entry["turn_end_t"] = turn_end_t
		entry["turn_curve_power"] = curve_power
		entry["residual_spin"] = _residual_spin_for_entry(entry, bounce_direction)
		last_roll_offset_applied = true
		last_roll_offset_distance = maxf(last_roll_offset_distance, roll_offset.length())
		last_collision_push_distances.append(collision_push_offset.length())
		last_bounce_directions.append(bounce_direction)
		last_turn_speeds.append(turn_speed)
		last_turn_distances.append(turn_distance)
		last_turn_start_ratios.append(turn_start_t)
		last_turn_end_ratios.append(turn_end_t)
		last_turn_curve_powers.append(curve_power)
		last_final_push_seconds = maxf(last_final_push_seconds, turn_seconds)

	_resolve_target_collision_pushes()

	for entry in dice_entries:
		var body := entry.get("body", null) as RigidBody3D
		if body == null or not is_instance_valid(body):
			continue
		bounce_tween.tween_method(
			Callable(self, "_apply_scripted_bounce_frame").bind(
				body,
				entry["ground_position"],
				entry["target_position"],
				entry["contact_rotation"],
				entry["target_rotation"],
				float(entry["bounce_seconds"]),
				entry["bounce_direction"],
				float(entry["turn_start_t"]),
				float(entry["turn_end_t"]),
				entry["residual_spin"],
				float(entry["bounce_height"]),
				float(entry["roll_spin_scale"]),
				float(entry["turn_curve_power"])
			),
			0.0,
			1.0,
			float(entry["bounce_seconds"])
		).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await bounce_tween.finished
	if token != throw_count:
		return
	last_final_positions.clear()
	for entry in dice_entries:
		var body := entry.get("body", null) as RigidBody3D
		if body == null or not is_instance_valid(body):
			continue
		body.position = entry["target_position"]
		body.rotation = entry["target_rotation"]
		last_final_positions.append(body.position)
	last_bounce_touched_ground = true
	last_face_up_completed = true
	last_timed_out = false
	last_throw_total_seconds = landing_seconds + longest_bounce_seconds
	if status_label != null:
		status_label.text = "投掷完成：%s" % [_format_pips(last_target_pips)]


func _apply_scripted_bounce_frame(
	t: float,
	body: RigidBody3D,
	ground_position: Vector3,
	target_position: Vector3,
	contact_rotation: Vector3,
	target_rotation: Vector3,
	bounce_seconds: float,
	bounce_direction: Vector3,
	turn_start_t: float,
	turn_end_t: float,
	residual_spin: Vector3,
	bounce_height: float,
	roll_spin_scale: float,
	turn_curve_power: float
) -> void:
	if body == null or not is_instance_valid(body):
		return
	var y_offset := bounce_height * 4.0 * t * (1.0 - t)
	var roll_t := t * t * (3.0 - 2.0 * t)
	body.position = ground_position.lerp(target_position, roll_t) + Vector3(0.0, y_offset, 0.0)
	_separate_dice_body_from_neighbors(body)
	var rotate_t := clampf((t - turn_start_t) / maxf(0.01, turn_end_t - turn_start_t), 0.0, 1.0)
	var adjust_t := _rotation_curve_progress(rotate_t, turn_curve_power)
	var roll_spin := Vector3(
		bounce_direction.z * TAU * 0.18,
		TAU * 0.08 * sin(t * PI),
		-bounce_direction.x * TAU * 0.18
	) * roll_spin_scale * (1.0 - adjust_t) * (1.0 - t * 0.32)
	var current_rotation := contact_rotation + residual_spin * (1.0 - adjust_t) * (1.0 - t * 0.24) + roll_spin
	body.rotation = _lerp_rotation_euler(current_rotation, target_rotation, adjust_t)


func _resolve_target_collision_pushes() -> void:
	if dice_entries.size() <= 1:
		return
	var min_distance := _minimum_die_clearance()
	for _iteration in range(4):
		for left_index in range(dice_entries.size()):
			for right_index in range(left_index + 1, dice_entries.size()):
				var left_entry := dice_entries[left_index]
				var right_entry := dice_entries[right_index]
				var left_position: Vector3 = left_entry["target_position"]
				var right_position: Vector3 = right_entry["target_position"]
				var delta := Vector3(left_position.x - right_position.x, 0.0, left_position.z - right_position.z)
				var distance := delta.length()
				var overlap := min_distance - distance
				if overlap <= 0.0:
					continue
				var direction := delta.normalized() if distance > 0.001 else _fallback_push_direction(left_index, right_index)
				var push := direction * (overlap * 0.5 + 3.0)
				left_entry["target_position"] = _clamp_ground_position(left_position + push)
				right_entry["target_position"] = _clamp_ground_position(right_position - push)
				last_collision_separation_applied = true


func _separate_dice_body_from_neighbors(body: RigidBody3D) -> void:
	if body == null or not is_instance_valid(body):
		return
	var min_distance := _minimum_die_clearance()
	for other_body in dice_bodies:
		if other_body == null or not is_instance_valid(other_body) or other_body == body:
			continue
		var delta := Vector3(body.position.x - other_body.position.x, 0.0, body.position.z - other_body.position.z)
		var distance := delta.length()
		var overlap := min_distance - distance
		if overlap <= 0.0:
			continue
		var direction := delta.normalized() if distance > 0.001 else Vector3.RIGHT
		var adjusted := body.position + direction * (overlap * 0.55)
		body.position = Vector3(
			clampf(adjusted.x, -GROUND_LIMIT_X, GROUND_LIMIT_X),
			adjusted.y,
			clampf(adjusted.z, -GROUND_LIMIT_Z, GROUND_LIMIT_Z)
		)
		last_collision_separation_applied = true


func _random_bounce_seconds_for_entry(entry: Dictionary, token: int, max_bounce_seconds: float) -> float:
	var die_index := int(entry.get("die_index", 0))
	var factor := lerpf(
		BOUNCE_SECONDS_MIN_FACTOR,
		BOUNCE_SECONDS_MAX_FACTOR,
		_noise01(die_index + 29, token, 397)
	)
	return minf(clampf(bounce_roll_phase_seconds * factor, 0.44, 0.68), max_bounce_seconds)


func _random_bounce_height_for_entry(entry: Dictionary, token: int) -> float:
	var die_index := int(entry.get("die_index", 0))
	return lerpf(BOUNCE_HEIGHT_MIN, BOUNCE_HEIGHT_MAX, _noise01(die_index + 31, token, 401))


func _bounce_up_speed(bounce_height: float, bounce_seconds: float) -> float:
	return 4.0 * bounce_height / maxf(0.01, bounce_seconds)


func _random_turn_speed_for_entry(entry: Dictionary, token: int, turn_distance: float) -> float:
	var die_index := int(entry.get("die_index", 0))
	var distance_t := clampf(turn_distance / (TAU * 1.4), 0.0, 1.0)
	var base_speed := lerpf(TURN_SPEED_MIN, TURN_SPEED_MAX, distance_t)
	var random_factor := lerpf(0.92, 1.08, _noise01(die_index + 33, token, 421))
	return clampf(base_speed * random_factor, TURN_SPEED_MIN, TURN_SPEED_MAX)


func _turn_curve_power_for_distance(turn_distance: float) -> float:
	var distance_t := clampf(turn_distance / (TAU * 1.4), 0.0, 1.0)
	return lerpf(0.96, 0.74, distance_t)


func _rotation_curve_progress(raw_t: float, curve_power: float) -> float:
	var shaped_t := pow(clampf(raw_t, 0.0, 1.0), clampf(curve_power, 0.70, 1.0))
	return shaped_t * shaped_t * shaped_t * (shaped_t * (shaped_t * 6.0 - 15.0) + 10.0)


func _collision_push_offset_for_entry(entry: Dictionary, token: int, ground_position: Vector3) -> Vector3:
	if dice_entries.size() <= 1:
		return Vector3.ZERO
	var die_index := int(entry.get("die_index", 0))
	var push := Vector3.ZERO
	var push_radius := cube_side * COLLISION_PUSH_RADIUS_FACTOR
	for other_entry in dice_entries:
		if int(other_entry.get("die_index", -1)) == die_index:
			continue
		var other_position: Vector3 = other_entry.get("ground_position", Vector3.ZERO)
		var delta := Vector3(ground_position.x - other_position.x, 0.0, ground_position.z - other_position.z)
		var distance := delta.length()
		var direction := delta.normalized() if distance > 0.001 else _fallback_push_direction(die_index, int(other_entry.get("die_index", 0)))
		var influence := clampf((push_radius - distance) / push_radius, 0.0, 1.0)
		push += direction * (8.0 + 24.0 * influence)
	if push.length() < 2.0:
		var angle := TAU * _noise01(die_index + 37, token, 409)
		push = Vector3(cos(angle), 0.0, sin(angle)) * 6.0
	return push.normalized() * clampf(push.length(), 6.0, 34.0)


func _random_bounce_direction_for_entry(entry: Dictionary, token: int) -> Vector3:
	var die_index := int(entry.get("die_index", 0))
	var angle := TAU * _noise01(die_index + 7, token, 331)
	return Vector3(cos(angle), 0.0, sin(angle)).normalized()


func _residual_spin_for_entry(entry: Dictionary, bounce_direction: Vector3) -> Vector3:
	var die_index := int(entry.get("die_index", 0))
	var yaw_sign := -1.0 if _noise01(die_index + 9, throw_count, 347) < 0.5 else 1.0
	return Vector3(
		bounce_direction.z * TAU * lerpf(0.28, 0.48, _noise01(die_index + 11, throw_count, 353)),
		yaw_sign * TAU * lerpf(0.12, 0.26, _noise01(die_index + 13, throw_count, 359)),
		-bounce_direction.x * TAU * lerpf(0.28, 0.48, _noise01(die_index + 15, throw_count, 367))
	)


func _roll_distance_for_turn(turn_distance: float, turn_speed: float) -> float:
	var distance_from_angle := turn_distance * 6.8
	var distance_from_speed := turn_speed * 1.55
	return clampf(10.0 + distance_from_angle + distance_from_speed, 14.0, 62.0)


func _lerp_rotation_euler(from_rotation: Vector3, to_rotation: Vector3, weight: float) -> Vector3:
	return Vector3(
		lerp_angle(from_rotation.x, to_rotation.x, weight),
		lerp_angle(from_rotation.y, to_rotation.y, weight),
		lerp_angle(from_rotation.z, to_rotation.z, weight)
	)


func _rotation_distance(a: Vector3, b: Vector3) -> float:
	return (
		absf(wrapf(b.x - a.x, -PI, PI))
		+ absf(wrapf(b.y - a.y, -PI, PI))
		+ absf(wrapf(b.z - a.z, -PI, PI))
	)


func _all_dice_started_above() -> bool:
	if dice_bodies.is_empty():
		return false
	for body in dice_bodies:
		if body == null or not is_instance_valid(body):
			return false
		if body.position.y <= 0.0:
			return false
	return true


func _format_pips(pips: Array[int]) -> String:
	var values: Array[String] = []
	for pip in pips:
		values.append(str(pip))
	return "、".join(values)


func _clamp_ground_position(position: Vector3) -> Vector3:
	return Vector3(
		clampf(position.x, -GROUND_LIMIT_X, GROUND_LIMIT_X),
		_face_up_position(position).y,
		clampf(position.z, -GROUND_LIMIT_Z, GROUND_LIMIT_Z)
	)


func _face_up_position(raw_position: Vector3) -> Vector3:
	var floor_surface_y := -250.0 + 14.0
	return Vector3(
		clampf(raw_position.x, -GROUND_LIMIT_X, GROUND_LIMIT_X),
		floor_surface_y + cube_side * 0.5,
		clampf(raw_position.z, -GROUND_LIMIT_Z, GROUND_LIMIT_Z)
	)


func _is_on_floor(position: Vector3) -> bool:
	return absf(position.y - _face_up_position(position).y) < 0.1


func _fake_face_index(target_face_index: int, token: int) -> int:
	var offset := 1 + int(floor(_noise01(token, target_face_index, 137) * 5.0))
	return (target_face_index + offset) % 6


func _random_final_push_seconds(token: int, target_face_index: int) -> float:
	var t := _noise01(token, target_face_index, 193)
	return lerpf(final_push_min_seconds, final_push_max_seconds, t)


func _noise01(a: int, b: int, c: int) -> float:
	var raw := sin(float(a * 127 + b * 311 + c * 919) * 12.9898) * 43758.5453
	return fposmod(raw, 1.0)


static func target_rotation_for_face_index(face_index: int) -> Vector3:
	var normal := face_normal_for_face_index(face_index).normalized()
	if normal.is_equal_approx(Vector3.UP):
		return Vector3.ZERO
	if normal.is_equal_approx(Vector3.DOWN):
		return Vector3(PI, 0.0, 0.0)
	var axis := normal.cross(Vector3.UP).normalized()
	var angle := normal.angle_to(Vector3.UP)
	return Basis(axis, angle).get_euler()


static func face_mount_rotation_for_face_index(face_index: int) -> Vector3:
	match clampi(face_index, 0, 5):
		0:
			return Vector3.ZERO
		1:
			return Vector3(deg_to_rad(90.0), 0.0, 0.0)
		2:
			return Vector3(0.0, deg_to_rad(90.0), 0.0)
		3:
			return Vector3(0.0, deg_to_rad(-90.0), 0.0)
		4:
			return Vector3(deg_to_rad(-90.0), 0.0, 0.0)
		5:
			return Vector3(0.0, deg_to_rad(180.0), 0.0)
		_:
			return Vector3.ZERO


static func face_normal_for_face_index(face_index: int) -> Vector3:
	match clampi(face_index, 0, 5):
		0:
			return Vector3(0.0, 0.0, 1.0)
		1:
			return Vector3(0.0, -1.0, 0.0)
		2:
			return Vector3(1.0, 0.0, 0.0)
		3:
			return Vector3(-1.0, 0.0, 0.0)
		4:
			return Vector3(0.0, 1.0, 0.0)
		5:
			return Vector3(0.0, 0.0, -1.0)
		_:
			return Vector3(0.0, 0.0, 1.0)


func _add_dice_visuals(parent: Node3D) -> void:
	var body_mesh := MeshInstance3D.new()
	body_mesh.name = "DiceBody"
	var body_box := BoxMesh.new()
	body_box.size = Vector3(cube_side, cube_side, cube_side)
	body_mesh.mesh = body_box
	body_mesh.material_override = _material(Color(0.93, 0.95, 0.98, 1.0))
	parent.add_child(body_mesh)

	for face_index in range(6):
		_add_die_face(parent, face_index, face_index + 1)


func _add_die_face(parent: Node3D, face_index: int, pip: int) -> void:
	var mount := Node3D.new()
	mount.name = "Face_%d" % [face_index + 1]
	mount.position = face_normal_for_face_index(face_index) * (cube_side * 0.5 + 1.8)
	mount.rotation = face_mount_rotation_for_face_index(face_index)
	parent.add_child(mount)

	var face_mesh := MeshInstance3D.new()
	face_mesh.name = "FacePlate_%d" % [face_index + 1]
	var face_box := BoxMesh.new()
	face_box.size = Vector3(cube_side * 0.84, cube_side * 0.84, 2.0)
	face_mesh.mesh = face_box
	face_mesh.material_override = _material(Color(0.98, 0.985, 0.96, 1.0))
	mount.add_child(face_mesh)

	var pip_material := _material(Color(0.03, 0.035, 0.04, 1.0))
	var offsets := _pip_offsets(pip)
	for pip_index in range(offsets.size()):
		var offset: Vector2 = offsets[pip_index]
		var pip_mesh := MeshInstance3D.new()
		pip_mesh.name = "Pip_%d_%d" % [pip, pip_index + 1]
		var sphere := SphereMesh.new()
		sphere.radius = cube_side * 0.055
		sphere.height = cube_side * 0.036
		sphere.radial_segments = 16
		sphere.rings = 8
		pip_mesh.mesh = sphere
		pip_mesh.material_override = pip_material
		pip_mesh.position = Vector3(offset.x * cube_side, offset.y * cube_side, 2.8)
		mount.add_child(pip_mesh)


func _pip_offsets(pip: int) -> Array[Vector2]:
	var d := 0.22
	var left := -d
	var right := d
	var top := d
	var bottom := -d
	var middle := 0.0
	match clampi(pip, 1, 6):
		1:
			return [Vector2.ZERO]
		2:
			return [Vector2(left, top), Vector2(right, bottom)]
		3:
			return [Vector2(left, top), Vector2.ZERO, Vector2(right, bottom)]
		4:
			return [Vector2(left, top), Vector2(right, top), Vector2(left, bottom), Vector2(right, bottom)]
		5:
			return [Vector2(left, top), Vector2(right, top), Vector2.ZERO, Vector2(left, bottom), Vector2(right, bottom)]
		6:
			return [
				Vector2(left, top), Vector2(right, top),
				Vector2(left, middle), Vector2(right, middle),
				Vector2(left, bottom), Vector2(right, bottom),
			]
		_:
			return [Vector2.ZERO]


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.58
	material.metallic = 0.0
	return material


func _make_pip_input(slot_index: int) -> LineEdit:
	var input := LineEdit.new()
	input.name = "TargetPipInput_%d" % [slot_index + 1]
	input.text = "1"
	input.placeholder_text = "1"
	input.max_length = 1
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.custom_minimum_size = Vector2(52, 58)
	input.add_theme_font_size_override("font_size", 26)
	input.add_theme_color_override("font_color", Color(0.98, 0.98, 0.94, 1.0))
	input.add_theme_color_override("font_placeholder_color", Color(0.70, 0.76, 0.84, 0.72))
	input.add_theme_stylebox_override("normal", _make_panel_style(Color(0.025, 0.065, 0.11, 0.98), Color(0.58, 0.72, 0.92, 0.72), 2, 6))
	input.add_theme_stylebox_override("focus", _make_panel_style(Color(0.03, 0.11, 0.18, 0.98), Color(1.0, 0.92, 0.58, 0.92), 2, 6))
	return input


func _make_button(text: String, normal_color: Color, hover_color: Color) -> Button:
	var button := Button.new()
	button.name = text
	button.text = text
	button.custom_minimum_size = Vector2(220, 66)
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color(0.98, 0.98, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.86, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.94, 0.72, 1.0))
	button.add_theme_stylebox_override("normal", _make_panel_style(normal_color, Color(0.98, 0.90, 0.55, 0.88), 2, 7))
	button.add_theme_stylebox_override("hover", _make_panel_style(hover_color, Color(1.0, 0.96, 0.68, 0.95), 2, 7))
	button.add_theme_stylebox_override("pressed", _make_panel_style(normal_color.darkened(0.18), Color(1.0, 0.88, 0.44, 0.95), 2, 7))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _make_panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style


func _click_hits_control(position: Vector2, control: Control) -> bool:
	if control == null or not control.visible or not control.is_inside_tree():
		return false
	var button := control as BaseButton
	if button != null and button.disabled:
		return false
	return control.get_global_rect().has_point(position)


func _count_nodes_named(node: Node, node_name: String) -> int:
	var count := 1 if str(node.name).begins_with(node_name) else 0
	for child in node.get_children():
		count += _count_nodes_named(child, node_name)
	return count
