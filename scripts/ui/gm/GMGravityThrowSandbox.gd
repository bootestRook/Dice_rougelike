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

var viewport_container: SubViewportContainer = null
var sub_viewport: SubViewport = null
var camera: Camera3D = null
var world_root: Node3D = null
var physics_root: Node3D = null
var cube_body: RigidBody3D = null
var floor_body: StaticBody3D = null
var boundary_bodies: Array[StaticBody3D] = []
var throw_button: Button = null
var face_buttons: Array[Button] = []
var back_button: Button = null
var status_label: Label = null
var throw_count: int = 0
var last_throw_started: bool = false
var last_throw_started_above: bool = false
var last_cube_class_name: String = ""
var last_initial_linear_velocity: Vector3 = Vector3.ZERO
var last_face_up_completed: bool = false
var last_throw_total_seconds: float = 0.0
var last_target_face_index: int = 0
var last_fake_face_index: int = 0
var last_bounce_touched_ground: bool = false
var last_final_push_seconds: float = 0.0
var last_landing_used_gravity_curve: bool = false
var last_bounce_started_on_ground: bool = false
var last_adjusted_during_bounce: bool = false


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
	for face_index in range(face_buttons.size()):
		if _click_hits_control(mouse_event.global_position, face_buttons[face_index]):
			get_viewport().set_input_as_handled()
			_throw_die(face_index)
			return
	if _click_hits_control(mouse_event.global_position, back_button):
		get_viewport().set_input_as_handled()
		clear_sandbox()
		back_requested.emit()


func clear_sandbox() -> void:
	last_throw_started = false
	last_throw_started_above = false
	last_cube_class_name = ""
	last_initial_linear_velocity = Vector3.ZERO
	last_face_up_completed = false
	last_throw_total_seconds = 0.0
	last_target_face_index = 0
	last_fake_face_index = 0
	last_bounce_touched_ground = false
	last_final_push_seconds = 0.0
	last_landing_used_gravity_curve = false
	last_bounce_started_on_ground = false
	last_adjusted_during_bounce = false
	_clear_cube()
	if status_label != null:
		status_label.text = "等待投掷。"


func start_throw() -> void:
	_throw_die(0)


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
	return face_buttons.size()


func get_visible_pip_count() -> int:
	if cube_body == null or not is_instance_valid(cube_body):
		return 0
	return cube_body.find_children("Pip*", "MeshInstance3D", true, false).size()


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
	return cube_body != null and is_instance_valid(cube_body)


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
	footer.add_theme_constant_override("separation", 18)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(footer)

	var face_label := Label.new()
	face_label.text = "指定面"
	face_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	face_label.add_theme_font_size_override("font_size", 26)
	face_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86, 1.0))
	footer.add_child(face_label)

	face_buttons.clear()
	for face_index in range(6):
		var face_number := face_index + 1
		var target_face_index := face_index
		var face_button := _make_button("%d面" % [face_number], Color(0.05, 0.34, 0.78, 0.96), Color(0.08, 0.48, 0.96, 0.98))
		face_button.name = "FaceButton_%d" % [face_number]
		face_button.custom_minimum_size = Vector2(92, 66)
		face_button.pressed.connect(func() -> void:
			_throw_die(target_face_index)
		)
		face_buttons.append(face_button)
		footer.add_child(face_button)
	if not face_buttons.is_empty():
		throw_button = face_buttons[0]

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
	camera.position = Vector3(0.0, 20.0, 820.0)
	camera.rotation_degrees = Vector3.ZERO
	camera.current = true
	world_root.add_child(camera)

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


func _throw_die(target_face_index: int = 0) -> void:
	_ensure_world()
	_sync_viewport_size()
	if physics_root == null:
		return

	_clear_cube()
	throw_count += 1
	last_throw_started = true
	last_target_face_index = clampi(target_face_index, 0, 5)

	cube_body = RigidBody3D.new()
	cube_body.name = "GMThrowDie"
	cube_body.mass = 1.0
	cube_body.gravity_scale = 42.0
	cube_body.linear_damp = 0.0
	cube_body.angular_damp = 0.05
	cube_body.contact_monitor = true
	cube_body.max_contacts_reported = 8
	cube_body.physics_material_override = _cube_physics_material()
	cube_body.position = _start_position_for_throw(throw_count)
	cube_body.rotation = Vector3(0.38 * float(throw_count), 0.52, 0.31)
	cube_body.linear_velocity = Vector3(-cube_body.position.x * 0.32, 0.0, 54.0 * sin(float(throw_count) * 1.31))
	cube_body.angular_velocity = Vector3(9.6 + float(throw_count % 3) * 0.52, -7.2, 10.4)
	last_initial_linear_velocity = cube_body.linear_velocity
	last_throw_started_above = cube_body.position.y > 0.0
	last_cube_class_name = cube_body.get_class()
	last_face_up_completed = false
	last_throw_total_seconds = 0.0
	last_fake_face_index = last_target_face_index
	last_bounce_touched_ground = false
	last_final_push_seconds = 0.0
	last_landing_used_gravity_curve = false
	last_bounce_started_on_ground = false
	last_adjusted_during_bounce = false

	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(cube_side, cube_side, cube_side)
	collision.shape = shape
	cube_body.add_child(collision)

	_add_dice_visuals(cube_body)

	physics_root.add_child(cube_body)
	_play_throw_animation(throw_count, last_target_face_index)
	if status_label != null:
		status_label.text = "投掷目标：%d面" % [last_target_face_index + 1]


func _clear_cube() -> void:
	if cube_body == null:
		return
	if is_instance_valid(cube_body):
		physics_root.remove_child(cube_body)
		cube_body.queue_free()
	cube_body = null


func _start_position_for_throw(index: int) -> Vector3:
	return Vector3(
		sin(float(index) * 1.73) * 128.0,
		fall_height,
		cos(float(index) * 1.21) * 46.0
	)


func _cube_physics_material() -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.friction = 0.74
	material.bounce = 0.20
	return material


func _play_throw_animation(token: int, target_face_index: int) -> void:
	if cube_body == null or not is_instance_valid(cube_body):
		return
	cube_body.freeze = true

	var start_position := cube_body.position
	var ground_position := _face_up_position(start_position)
	var start_rotation := cube_body.rotation
	var fake_face_index := _fake_face_index(target_face_index, token)
	last_fake_face_index = fake_face_index
	var contact_rotation := target_rotation_for_face_index(fake_face_index) + Vector3(TAU * 0.24, -TAU * 0.18, TAU * 0.16)
	var landing_seconds := clampf(landing_phase_seconds, 0.25, 0.40)

	last_landing_used_gravity_curve = true
	var landing_tween := create_tween()
	landing_tween.tween_method(
		func(t: float) -> void:
			_apply_landing_frame(start_position, ground_position, start_rotation, contact_rotation, t),
		0.0,
		1.0,
		landing_seconds
	)
	await landing_tween.finished
	if token != throw_count or cube_body == null or not is_instance_valid(cube_body):
		return

	cube_body.position = ground_position
	cube_body.rotation = contact_rotation
	last_bounce_started_on_ground = _is_on_floor(cube_body.position)

	var bounce_seconds := minf(clampf(bounce_roll_phase_seconds, 0.5, 0.8), maxf(0.02, max_throw_seconds - landing_seconds))
	var target_rotation := target_rotation_for_face_index(target_face_index)
	var bounce_tween := create_tween()
	bounce_tween.tween_method(
		func(t: float) -> void:
			_apply_bounce_adjust_frame(ground_position, contact_rotation, target_rotation, t),
		0.0,
		1.0,
		bounce_seconds
	)
	await bounce_tween.finished
	if token != throw_count or cube_body == null or not is_instance_valid(cube_body):
		return

	cube_body.position = ground_position
	cube_body.rotation = target_rotation
	last_bounce_touched_ground = _is_on_floor(cube_body.position)
	last_adjusted_during_bounce = true
	last_final_push_seconds = 0.0
	last_face_up_completed = true
	last_throw_total_seconds = landing_seconds + bounce_seconds
	if status_label != null:
		status_label.text = "%d面朝上：%.2f秒" % [target_face_index + 1, last_throw_total_seconds]


func _face_up_position(raw_position: Vector3) -> Vector3:
	var floor_surface_y := -250.0 + 14.0
	return Vector3(
		clampf(raw_position.x, -300.0, 300.0),
		floor_surface_y + cube_side * 0.5,
		clampf(raw_position.z, -90.0, 90.0)
	)


func _apply_landing_frame(
	start_position: Vector3,
	ground_position: Vector3,
	start_rotation: Vector3,
	contact_rotation: Vector3,
	t: float
) -> void:
	if cube_body == null or not is_instance_valid(cube_body):
		return
	var gravity_t := t * t
	var drift_t := t
	cube_body.position = Vector3(
		lerpf(start_position.x, ground_position.x, drift_t),
		lerpf(start_position.y, ground_position.y, gravity_t),
		lerpf(start_position.z, ground_position.z, drift_t)
	)
	var spin := Vector3(TAU * 1.10, -TAU * 0.72, TAU * 0.54) * t
	cube_body.rotation = start_rotation.lerp(contact_rotation, t) + spin


func _apply_bounce_adjust_frame(
	ground_position: Vector3,
	contact_rotation: Vector3,
	target_rotation: Vector3,
	t: float
) -> void:
	if cube_body == null or not is_instance_valid(cube_body):
		return
	var bounce_height := 118.0
	var y_offset := bounce_height * 4.0 * t * (1.0 - t)
	var x_drift := 42.0 * sin(t * PI) * (1.0 - t)
	cube_body.position = ground_position + Vector3(x_drift, y_offset, 0.0)
	var adjust_t := t * t * (3.0 - 2.0 * t)
	var residual_spin := Vector3(TAU * 0.62, -TAU * 0.38, TAU * 0.24) * (1.0 - t)
	cube_body.rotation = contact_rotation.lerp(target_rotation, adjust_t) + residual_spin


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
