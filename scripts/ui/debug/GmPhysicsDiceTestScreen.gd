extends Control
class_name GmPhysicsDiceTestScreen


const PhysicsDiceThrowService = preload("res://scripts/rules/physics_dice/PhysicsDiceThrowService.gd")

signal back_requested


const TABLE_WIDTH := 12.8
const TABLE_DEPTH := 9.2
const TABLE_THICKNESS := 0.26
const WALL_HEIGHT := 0.74
const WALL_THICKNESS := 0.34
const DIE_SIZE := 0.72
const DIE_HALF := DIE_SIZE * 0.5
const DIE_ROUND_RADIUS := 0.085
const PIP_RADIUS := 0.038
const PIP_DEPTH := 0.018
const PIP_SPACING := 0.165
const QUIET_LINEAR := 0.065
const QUIET_ANGULAR := 0.11
const QUIET_FRAMES := 42
const SLOW_TIME_SCALE := 0.34

const DICE_PALETTE := [
	Color(0.243, 0.784, 1.0),
	Color(0.545, 0.361, 0.965),
	Color(0.965, 0.647, 0.271),
	Color(1.0, 0.361, 0.541),
	Color(0.259, 0.827, 0.572),
	Color(0.976, 0.451, 0.086),
]
const IVORY_PALETTE := [
	Color(0.973, 0.98, 0.988),
	Color(0.945, 0.961, 0.976),
	Color(0.98, 0.969, 0.937),
	Color(0.961, 0.945, 0.91),
	Color(0.973, 0.98, 0.988),
	Color(0.945, 0.961, 0.976),
]

const FACE_DEFINITIONS := [
	{"value": 1, "normal": Vector3.UP, "u": Vector3.RIGHT, "v": Vector3.FORWARD},
	{"value": 6, "normal": Vector3.DOWN, "u": Vector3.RIGHT, "v": Vector3.BACK},
	{"value": 2, "normal": Vector3.BACK, "u": Vector3.RIGHT, "v": Vector3.UP},
	{"value": 5, "normal": Vector3.FORWARD, "u": Vector3.LEFT, "v": Vector3.UP},
	{"value": 3, "normal": Vector3.RIGHT, "u": Vector3.FORWARD, "v": Vector3.UP},
	{"value": 4, "normal": Vector3.LEFT, "u": Vector3.BACK, "v": Vector3.UP},
]


var back_callback: Callable
var rng := RandomNumberGenerator.new()
var scene_root: Node3D = null
var visible_root: Node3D = null
var camera: Camera3D = null
var dice_physics_material: PhysicsMaterial = null
var table_physics_material: PhysicsMaterial = null
var wall_physics_material: PhysicsMaterial = null
var rounded_die_mesh: Mesh = null
var pip_mesh: Mesh = null
var pip_white_material: StandardMaterial3D = null
var pip_dark_material: StandardMaterial3D = null

var dice: Array[RigidBody3D] = []
var active_targets: Array = []
var last_values: Array[int] = []
var target_controls: Array[OptionButton] = []
var target_cells: Array[Control] = []

var dice_count_slider: HSlider = null
var dice_count_value_label: Label = null
var drop_button: Button = null
var reset_button: Button = null
var camera_button: Button = null
var random_target_button: Button = null
var clear_target_button: Button = null
var back_button: Button = null
var slow_toggle: CheckBox = null
var color_toggle: CheckBox = null
var sum_value_label: Label = null
var sum_suffix_label: Label = null
var faces_container: HFlowContainer = null
var status_label: Label = null
var progress_bar: ProgressBar = null

var rolling := false
var planning := false
var recorded_playback := false
var recorded_elapsed := 0.0
var recorded_duration := 0.0
var recorded_trajectories: Array = []
var settle_timer := 0.0
var quiet_frame_count := 0
var has_announced_result := false
var camera_target := Vector3(0.0, 0.2, 0.0)
var camera_distance := 12.15
var camera_yaw := 0.665
var camera_pitch := 0.685
var camera_dragging := false
var throw_service: PhysicsDiceThrowService = PhysicsDiceThrowService.new()
var last_target_plan_latency_ms := 0
var last_target_plan_source := "随机"
var last_target_min_path_separation := INF
var last_target_min_table_margin := INF


func setup(return_callback: Callable = Callable()) -> void:
	back_callback = return_callback


func _ready() -> void:
	name = "GmPhysicsDiceTestRoot"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	rng.randomize()
	_build_3d_scene()
	_build_ui()
	_reset_camera()
	_refresh_target_controls()
	_update_result_ui([], "等待投掷", "选择数量和目标点数后点击“落下 / 重投”。", _read_targets(4))
	call_deferred("_drop_initial_throw")


func _exit_tree() -> void:
	if absf(Engine.time_scale - 1.0) > 0.001:
		Engine.time_scale = 1.0


func _physics_process(delta: float) -> void:
	_apply_slow_motion_state()
	if recorded_playback:
		_update_recorded_playback(delta)
		return
	if not rolling or dice.is_empty() or has_announced_result or planning:
		return

	var all_quiet := true
	for body in dice:
		if not _is_body_quiet(body):
			all_quiet = false
			break

	if all_quiet:
		quiet_frame_count += 1
		settle_timer += delta
	else:
		quiet_frame_count = 0
		settle_timer = 0.0

	if quiet_frame_count >= QUIET_FRAMES or settle_timer > 0.75:
		var values: Array[int] = []
		for body in dice:
			values.append(_get_up_face_value(body))
		last_values = values
		has_announced_result = true
		rolling = false
		_update_result_ui(values, "共 %d 颗骰子" % values.size(), "已落定。指定点数来自快速生成的初始投掷参数，停止后不做转面校正。", active_targets)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_RIGHT or mouse_button.button_index == MOUSE_BUTTON_MIDDLE:
			camera_dragging = mouse_button.pressed
			get_viewport().set_input_as_handled()
		elif mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = maxf(6.2, camera_distance - 0.7)
			_update_camera()
		elif mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = minf(16.0, camera_distance + 0.7)
			_update_camera()
	elif event is InputEventMouseMotion and camera_dragging:
		var motion := event as InputEventMouseMotion
		camera_yaw -= motion.relative.x * 0.006
		camera_pitch = clampf(camera_pitch - motion.relative.y * 0.004, 0.18, 1.25)
		_update_camera()
		get_viewport().set_input_as_handled()


func _build_3d_scene() -> void:
	scene_root = Node3D.new()
	scene_root.name = "PhysicsScene"
	add_child(scene_root)

	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.039, 0.063, 0.125)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.91, 1.0)
	env.ambient_light_energy = 0.55
	environment.environment = env
	scene_root.add_child(environment)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 45.0
	camera.near = 0.1
	camera.far = 100.0
	camera.current = true
	scene_root.add_child(camera)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_energy = 3.35
	key_light.shadow_enabled = true
	key_light.position = Vector3(-4.8, 9.5, 5.6)
	scene_root.add_child(key_light)
	key_light.look_at(Vector3.ZERO)

	var cyan_light := OmniLight3D.new()
	cyan_light.name = "CyanRimLight"
	cyan_light.omni_range = 14.0
	cyan_light.light_energy = 1.0
	cyan_light.light_color = Color(0.404, 0.91, 0.976)
	cyan_light.position = Vector3(-5.0, 3.1, 4.2)
	scene_root.add_child(cyan_light)

	var pink_light := OmniLight3D.new()
	pink_light.name = "PinkRimLight"
	pink_light.omni_range = 14.0
	pink_light.light_energy = 1.25
	pink_light.light_color = Color(0.957, 0.447, 0.714)
	pink_light.position = Vector3(4.7, 3.4, -4.6)
	scene_root.add_child(pink_light)

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
	pip_white_material = _make_standard_material(Color.WHITE, 0.32, 0.02)
	pip_dark_material = _make_standard_material(Color(0.067, 0.094, 0.153), 0.42, 0.02)

	_create_table_scene()
	_create_ambient_particles()


func _create_table_scene() -> void:
	var table_material := _make_standard_material(Color(0.075, 0.102, 0.16), 0.64, 0.0)
	var wall_material := _make_standard_material(Color(0.106, 0.14, 0.22), 0.52, 0.0)

	_add_static_box(
		visible_root,
		"PhysicsTable",
		Vector3(0.0, -TABLE_THICKNESS * 0.5, 0.0),
		Vector3(TABLE_WIDTH, TABLE_THICKNESS, TABLE_DEPTH),
		table_material,
		table_physics_material,
		true
	)
	_add_static_box(
		visible_root,
		"LeftWall",
		Vector3(-TABLE_WIDTH * 0.5 - WALL_THICKNESS * 0.5, WALL_HEIGHT * 0.5, 0.0),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, TABLE_DEPTH + WALL_THICKNESS * 2.0),
		wall_material,
		wall_physics_material,
		true
	)
	_add_static_box(
		visible_root,
		"RightWall",
		Vector3(TABLE_WIDTH * 0.5 + WALL_THICKNESS * 0.5, WALL_HEIGHT * 0.5, 0.0),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, TABLE_DEPTH + WALL_THICKNESS * 2.0),
		wall_material,
		wall_physics_material,
		true
	)
	_add_static_box(
		visible_root,
		"BackWall",
		Vector3(0.0, WALL_HEIGHT * 0.5, -TABLE_DEPTH * 0.5 - WALL_THICKNESS * 0.5),
		Vector3(TABLE_WIDTH + WALL_THICKNESS * 2.0, WALL_HEIGHT, WALL_THICKNESS),
		wall_material,
		wall_physics_material,
		true
	)
	_add_static_box(
		visible_root,
		"FrontWall",
		Vector3(0.0, WALL_HEIGHT * 0.5, TABLE_DEPTH * 0.5 + WALL_THICKNESS * 0.5),
		Vector3(TABLE_WIDTH + WALL_THICKNESS * 2.0, WALL_HEIGHT, WALL_THICKNESS),
		wall_material,
		wall_physics_material,
		true
	)
	_add_drop_zone_visuals()


func _add_static_box(
	parent: Node,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material,
	physics_material: PhysicsMaterial,
	with_mesh: bool
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.physics_material_override = physics_material
	parent.add_child(body)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)

	if with_mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "%sMesh" % node_name
		var box_mesh := BoxMesh.new()
		box_mesh.size = size
		mesh_instance.mesh = box_mesh
		mesh_instance.material_override = material
		body.add_child(mesh_instance)

	return body


func _add_drop_zone_visuals() -> void:
	var disc := MeshInstance3D.new()
	disc.name = "DropZoneDisc"
	disc.mesh = _make_cylinder_mesh(1.12, 0.012, 80)
	disc.material_override = _make_standard_material(Color(0.388, 0.4, 0.945, 0.14), 0.55, 0.0, false, true)
	disc.position = Vector3(0.0, 0.017, 0.0)
	visible_root.add_child(disc)

	var outer_ring := MeshInstance3D.new()
	outer_ring.name = "DropZoneOuterRing"
	outer_ring.mesh = _make_annulus_mesh(1.17, 1.23, 96, 0.0, TAU)
	outer_ring.material_override = _make_standard_material(Color(0.388, 0.4, 0.945, 0.32), 0.5, 0.0, false, true)
	outer_ring.position = Vector3(0.0, 0.026, 0.0)
	visible_root.add_child(outer_ring)

	var dash_material := _make_standard_material(Color(0.957, 0.447, 0.714, 0.48), 0.5, 0.0, false, true)
	for i in range(12):
		var dash := MeshInstance3D.new()
		dash.name = "DropZoneDash%02d" % i
		var start := float(i) / 12.0 * TAU
		dash.mesh = _make_annulus_mesh(0.76, 0.81, 8, start, TAU / 24.0)
		dash.material_override = dash_material
		dash.position = Vector3(0.0, 0.032, 0.0)
		visible_root.add_child(dash)

	var label := Label3D.new()
	label.name = "DropZoneLabel"
	label.text = "投掷区"
	label.font_size = 42
	label.pixel_size = 0.012
	label.modulate = Color(0.56, 0.64, 0.82, 0.5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector3(0.0, 0.045, 1.68)
	label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	visible_root.add_child(label)


func _create_ambient_particles() -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 90
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.028
	particle_mesh.height = 0.056
	particle_mesh.radial_segments = 8
	particle_mesh.rings = 4
	multimesh.mesh = particle_mesh
	for i in range(multimesh.instance_count):
		var position := Vector3(
			rng.randf_range(-TABLE_WIDTH * 0.46, TABLE_WIDTH * 0.46),
			rng.randf_range(0.03, 0.07),
			rng.randf_range(-TABLE_DEPTH * 0.45, TABLE_DEPTH * 0.45)
		)
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, position))

	var particles := MultiMeshInstance3D.new()
	particles.name = "AmbientTableParticles"
	particles.multimesh = multimesh
	particles.material_override = _make_emissive_material(Color(1.0, 0.878, 0.541, 0.46), 0.28)
	visible_root.add_child(particles)


func _build_ui() -> void:
	var hud := HBoxContainer.new()
	hud.name = "Hud"
	hud.add_theme_constant_override("separation", 16)
	hud.anchor_left = 0.0
	hud.anchor_right = 1.0
	hud.anchor_top = 0.0
	hud.anchor_bottom = 0.0
	hud.offset_left = 18.0
	hud.offset_right = -18.0
	hud.offset_top = 18.0
	hud.offset_bottom = 410.0
	add_child(hud)

	var left_panel := _make_panel_container("ControlPanel", Vector2(500, 0))
	hud.add_child(left_panel)
	var left_margin := _make_margin_container(16, 16, 16, 16)
	left_panel.add_child(left_margin)
	var left_box := VBoxContainer.new()
	left_box.name = "ControlPanelContent"
	left_box.add_theme_constant_override("separation", 10)
	left_margin.add_child(left_box)

	var title_row := HBoxContainer.new()
	title_row.name = "TitleRow"
	title_row.add_theme_constant_override("separation", 12)
	left_box.add_child(title_row)
	var title := _make_label("3D 骰子下落物理模拟", 18, Color(0.972, 0.98, 0.988), true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var badge := _make_badge_label("最多 6 颗")
	title_row.add_child(badge)

	var subcopy := _make_label("指定点数时会即时生成目标面朝上的投掷参数，然后交给 Godot 物理引擎正式落下。正式播放中不强制转面、不停稳后校正。", 13, Color(0.714, 0.761, 0.851), false)
	subcopy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(subcopy)

	var control_row := HBoxContainer.new()
	control_row.name = "CountAndDropRow"
	control_row.add_theme_constant_override("separation", 12)
	left_box.add_child(control_row)
	var slider_box := VBoxContainer.new()
	slider_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control_row.add_child(slider_box)
	var slider_label_row := HBoxContainer.new()
	slider_box.add_child(slider_label_row)
	var count_label := _make_label("骰子数量", 12, Color(0.86, 0.918, 0.996), true)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_label_row.add_child(count_label)
	dice_count_value_label = _make_label("4", 14, Color(0.431, 0.906, 0.976), true)
	dice_count_value_label.name = "DiceCountValueLabel"
	slider_label_row.add_child(dice_count_value_label)
	dice_count_slider = HSlider.new()
	dice_count_slider.name = "DiceCountSlider"
	dice_count_slider.min_value = 1.0
	dice_count_slider.max_value = 6.0
	dice_count_slider.step = 1.0
	dice_count_slider.value = 4.0
	dice_count_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dice_count_slider.value_changed.connect(func(value: float) -> void:
		dice_count_value_label.text = str(int(value))
		_refresh_target_controls()
	)
	slider_box.add_child(dice_count_slider)

	drop_button = _make_button("落下 / 重投", "DropButton", true)
	drop_button.custom_minimum_size = Vector2(124, 46)
	drop_button.pressed.connect(_on_drop_pressed)
	control_row.add_child(drop_button)

	var button_row := HBoxContainer.new()
	button_row.name = "ActionButtonRow"
	button_row.add_theme_constant_override("separation", 10)
	left_box.add_child(button_row)
	reset_button = _make_button("清空桌面", "ResetButton", false)
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.pressed.connect(func() -> void: _clear_dice(true))
	button_row.add_child(reset_button)
	camera_button = _make_button("重置视角", "CameraButton", false)
	camera_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	camera_button.pressed.connect(_reset_camera)
	button_row.add_child(camera_button)

	var target_block := PanelContainer.new()
	target_block.name = "TargetBlock"
	target_block.add_theme_stylebox_override("panel", _make_panel_style(Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.13), 1, 18))
	left_box.add_child(target_block)
	var target_margin := _make_margin_container(13, 13, 13, 13)
	target_block.add_child(target_margin)
	var target_box := VBoxContainer.new()
	target_box.add_theme_constant_override("separation", 8)
	target_margin.add_child(target_box)
	var target_head := HBoxContainer.new()
	target_head.name = "TargetHeader"
	target_head.add_theme_constant_override("separation", 8)
	target_box.add_child(target_head)
	var target_title := _make_label("每颗骰子的最终点数", 12, Color(0.86, 0.918, 0.996), true)
	target_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_head.add_child(target_title)
	random_target_button = _make_button("随机填目标", "FillTargetsButton", false, 12)
	random_target_button.pressed.connect(_fill_random_targets)
	target_head.add_child(random_target_button)
	clear_target_button = _make_button("全部随机", "ClearTargetsButton", false, 12)
	clear_target_button.pressed.connect(_clear_targets)
	target_head.add_child(clear_target_button)

	var target_help := _make_label("选择“随机”会完全读取物理结果；选择 1-6 点会快速生成对应初始姿态，再播放真实物理落骰。", 11, Color(0.796, 0.835, 0.882), false)
	target_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_box.add_child(target_help)

	var target_grid := GridContainer.new()
	target_grid.name = "TargetGrid"
	target_grid.columns = 3
	target_grid.add_theme_constant_override("h_separation", 8)
	target_grid.add_theme_constant_override("v_separation", 8)
	target_box.add_child(target_grid)
	for i in range(6):
		var cell := HBoxContainer.new()
		cell.name = "TargetCell%d" % (i + 1)
		cell.add_theme_constant_override("separation", 6)
		cell.custom_minimum_size = Vector2(136, 34)
		var id_label := _make_label("#%d" % (i + 1), 12, Color(0.431, 0.906, 0.976), true)
		id_label.custom_minimum_size = Vector2(28, 0)
		cell.add_child(id_label)
		var option := OptionButton.new()
		option.name = "TargetSelect%d" % (i + 1)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.add_item("随机", 0)
		for value in range(1, 7):
			option.add_item("%d 点" % value, value)
		option.selected = 0
		cell.add_child(option)
		target_grid.add_child(cell)
		target_cells.append(cell)
		target_controls.append(option)

	var option_row := HBoxContainer.new()
	option_row.name = "OptionRow"
	option_row.add_theme_constant_override("separation", 8)
	left_box.add_child(option_row)
	slow_toggle = CheckBox.new()
	slow_toggle.name = "SlowToggle"
	slow_toggle.text = "慢动作"
	slow_toggle.focus_mode = Control.FOCUS_NONE
	option_row.add_child(slow_toggle)
	color_toggle = CheckBox.new()
	color_toggle.name = "ColorToggle"
	color_toggle.text = "彩色骰子"
	color_toggle.button_pressed = true
	color_toggle.focus_mode = Control.FOCUS_NONE
	color_toggle.toggled.connect(func(_pressed: bool) -> void:
		if not planning and not rolling and not dice.is_empty():
			_rebuild_visible_dice_materials()
	)
	option_row.add_child(color_toggle)
	back_button = _make_button("返回主菜单", "BackButton", false)
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(_on_back_pressed)
	option_row.add_child(back_button)

	var spacer := Control.new()
	spacer.name = "HudSpacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(spacer)

	var result_panel := _make_panel_container("ResultPanel", Vector2(330, 0))
	hud.add_child(result_panel)
	var result_margin := _make_margin_container(14, 14, 14, 14)
	result_panel.add_child(result_margin)
	var result_box := VBoxContainer.new()
	result_box.name = "ResultPanelContent"
	result_box.add_theme_constant_override("separation", 10)
	result_margin.add_child(result_box)
	result_box.add_child(_make_label("当前结果", 12, Color(0.714, 0.761, 0.851), true))
	var sum_row := HBoxContainer.new()
	sum_row.name = "SumRow"
	sum_row.add_theme_constant_override("separation", 10)
	result_box.add_child(sum_row)
	sum_value_label = _make_label("—", 42, Color(0.972, 0.98, 0.988), true)
	sum_value_label.name = "SumValue"
	sum_row.add_child(sum_value_label)
	sum_suffix_label = _make_label("等待投掷", 13, Color(0.714, 0.761, 0.851), false)
	sum_suffix_label.name = "SumSuffix"
	sum_suffix_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	sum_suffix_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sum_row.add_child(sum_suffix_label)
	faces_container = HFlowContainer.new()
	faces_container.name = "Faces"
	faces_container.add_theme_constant_override("h_separation", 8)
	faces_container.add_theme_constant_override("v_separation", 8)
	faces_container.custom_minimum_size = Vector2(0, 42)
	result_box.add_child(faces_container)
	status_label = _make_label("", 12, Color(0.714, 0.761, 0.851), false)
	status_label.name = "StatusText"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_box.add_child(status_label)
	progress_bar = ProgressBar.new()
	progress_bar.name = "TargetCacheProgress"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 7)
	progress_bar.visible = false
	result_box.add_child(progress_bar)

	var note := Label.new()
	note.name = "CornerNote"
	note.text = "右键或中键拖动旋转视角，滚轮缩放。蓝色描边表示该骰子使用了指定目标点数。"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.886, 0.91, 0.941, 0.82))
	note.anchor_left = 0.45
	note.anchor_right = 1.0
	note.anchor_top = 1.0
	note.anchor_bottom = 1.0
	note.offset_left = 0.0
	note.offset_right = -18.0
	note.offset_top = -44.0
	note.offset_bottom = -18.0
	add_child(note)


func _drop_initial_throw() -> void:
	if is_inside_tree() and dice.is_empty() and not planning:
		_drop_with_current_settings(true)


func _on_drop_pressed() -> void:
	_drop_with_current_settings(true)


func _drop_with_current_settings(use_targets: bool) -> void:
	if planning:
		return
	var count := _current_dice_count()
	var targets := _read_targets(count) if use_targets else _make_null_targets(count)
	active_targets = targets
	last_values.clear()
	_clear_dice(false)
	rolling = false
	quiet_frame_count = 0
	settle_timer = 0.0
	has_announced_result = false

	var has_targets := _has_explicit_targets(targets)
	_update_result_ui([], "生成中" if has_targets else "投掷中", "正在生成目标点数投掷参数。" if has_targets else "等待骰子完全停止。", targets)

	if has_targets:
		var start_ms := Time.get_ticks_msec()
		var result := throw_service.solve_throw(count, targets, {
			"entry_height": 3.25,
			"max_attempts_per_die": 512,
			"min_path_separation": 0.9,
			"min_final_separation": 0.9,
			"min_table_margin": 0.55,
		})
		last_target_plan_latency_ms = int(result.get("latency_ms", int(Time.get_ticks_msec() - start_ms)))
		last_target_plan_source = str(result.get("source", ""))
		var plan: Array = result.get("plans", [])
		if plan.is_empty():
			_update_result_ui([], "生成失败", "目标投掷参数生成失败，请重新投掷。", targets)
			return
		_update_result_ui([], "投掷中", "已生成%s轨迹，用时 %d ms。正在播放完整物理投掷。" % [last_target_plan_source, last_target_plan_latency_ms], targets)
		_apply_plan(plan)
		return

	var random_result := throw_service.solve_throw(count, _make_null_targets(count), {
		"entry_height": 3.35,
		"max_attempts_per_die": 32,
	})
	last_target_plan_latency_ms = int(random_result.get("latency_ms", 0))
	last_target_plan_source = str(random_result.get("source", "随机"))
	var random_plan: Array = random_result.get("plans", [])
	if random_plan.is_empty():
		for i in range(count):
			random_plan.append(_make_initial_params(i, count, false))
	_apply_plan(random_plan)


func _target_solver_ready() -> bool:
	return throw_service != null and throw_service.has_native_solver()


func _apply_plan(plan: Array) -> void:
	_clear_dice(false)
	rolling = true
	recorded_playback = _plan_has_complete_trajectories(plan)
	recorded_elapsed = 0.0
	recorded_duration = 0.0
	recorded_trajectories.clear()
	last_target_min_path_separation = INF
	last_target_min_table_margin = INF
	has_announced_result = false
	quiet_frame_count = 0
	settle_timer = 0.0
	for i in range(plan.size()):
		var body := _create_die_body(true, i)
		visible_root.add_child(body)
		_apply_params_to_body(body, plan[i], Vector3.ZERO)
		if recorded_playback:
			var trajectory: Array = plan[i].get("trajectory", [])
			recorded_trajectories.append(trajectory)
			recorded_duration = maxf(recorded_duration, maxf(0.0, float(trajectory.size() - 1) / 60.0))
			body.freeze = true
			_apply_trajectory_frame(body, trajectory, 0.0)
		dice.append(body)
	if recorded_playback:
		last_target_min_path_separation = _plan_min_temporal_xz_separation(recorded_trajectories)
		last_target_min_table_margin = _plan_min_table_margin(recorded_trajectories)


func _clear_dice(reset_result: bool = true) -> void:
	for body in dice:
		if body != null and is_instance_valid(body):
			body.queue_free()
	dice.clear()
	rolling = false
	recorded_playback = false
	recorded_elapsed = 0.0
	recorded_duration = 0.0
	recorded_trajectories.clear()
	last_target_min_path_separation = INF
	last_target_min_table_margin = INF
	has_announced_result = false
	quiet_frame_count = 0
	settle_timer = 0.0
	_apply_slow_motion_state()
	if reset_result:
		last_values.clear()
		_update_result_ui([], "等待投掷", "选择数量和目标点数后点击“落下 / 重投”。", _read_targets(_current_dice_count()))


func _plan_has_complete_trajectories(plan: Array) -> bool:
	if plan.is_empty():
		return false
	for item in plan:
		if not (item is Dictionary):
			return false
		var trajectory: Array = (item as Dictionary).get("trajectory", [])
		if trajectory.size() < 2:
			return false
	return true


func _update_recorded_playback(delta: float) -> void:
	if not rolling or has_announced_result:
		return
	recorded_elapsed += delta
	for i in range(dice.size()):
		if i >= recorded_trajectories.size():
			continue
		var body := dice[i]
		if body == null or not is_instance_valid(body):
			continue
		_apply_trajectory_frame(body, recorded_trajectories[i] as Array, recorded_elapsed)
	if recorded_elapsed >= recorded_duration:
		var values: Array[int] = []
		for body in dice:
			values.append(_get_up_face_value(body))
		last_values = values
		has_announced_result = true
		rolling = false
		recorded_playback = false
		_update_result_ui(values, "共 %d 颗骰子" % values.size(), "已落定。指定点数来自原生物理快进轨迹，播放中不做转面校正。", active_targets)


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


func _create_die_body(with_visual: bool, index: int) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = "PhysicsDie%d" % (index + 1) if with_visual else "CacheDie%d" % (index + 1)
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

	if with_visual:
		body.add_child(_create_die_visual(index))
	return body


func _create_die_visual(index: int) -> Node3D:
	var group := Node3D.new()
	group.name = "DieVisual"
	var use_colors := color_toggle == null or color_toggle.button_pressed
	var color: Color = DICE_PALETTE[index % DICE_PALETTE.size()] if use_colors else IVORY_PALETTE[index % IVORY_PALETTE.size()]
	var pip_material: Material = pip_white_material if use_colors else pip_dark_material

	var cube := MeshInstance3D.new()
	cube.name = "RoundedDieBody"
	cube.mesh = rounded_die_mesh
	cube.material_override = _make_die_material(color)
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


func _rebuild_visible_dice_materials() -> void:
	for i in range(dice.size()):
		var body := dice[i]
		if body == null or not is_instance_valid(body):
			continue
		var old_visual := body.get_node_or_null("DieVisual")
		if old_visual != null:
			old_visual.queue_free()
		body.add_child(_create_die_visual(i))


func _apply_params_to_body(body: RigidBody3D, params: Dictionary, offset: Vector3) -> void:
	var q := params["quaternion"] as Quaternion
	body.global_transform = Transform3D(Basis(q), (params["position"] as Vector3) + offset)
	body.linear_velocity = params["velocity"] as Vector3
	body.angular_velocity = params["angular_velocity"] as Vector3
	body.sleeping = false


func _make_initial_params(index: int, count: int, target_mode: bool, target_value = null) -> Dictionary:
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
	var lateral := 1.15
	var cross := 1.2
	var y := 3.25 + float(index) * 0.1 + rng.randf_range(0.0, 0.65)
	return {
		"position": Vector3(lane_x + rng.randf_range(-0.18, 0.18), y, lane_z + rng.randf_range(-0.18, 0.18)),
		"quaternion": q,
		"velocity": Vector3(rng.randf_range(-lateral, lateral), rng.randf_range(-0.64, 0.08), rng.randf_range(-cross, cross)),
		"angular_velocity": Vector3(
			rng.randf_range(-8.8, 8.8),
			rng.randf_range(-8.8, 8.8),
			rng.randf_range(-8.8, 8.8)
		),
	}


func _is_body_quiet(body: RigidBody3D) -> bool:
	if body == null or not is_instance_valid(body):
		return true
	return body.global_position.y < 1.1 and body.linear_velocity.length() < QUIET_LINEAR and body.angular_velocity.length() < QUIET_ANGULAR


func _is_body_safe_relative(body: RigidBody3D, offset: Vector3) -> bool:
	var relative := body.global_position - offset
	return absf(relative.x) < TABLE_WIDTH * 0.5 - 0.75 and absf(relative.z) < TABLE_DEPTH * 0.5 - 0.75 and relative.y > -0.08 and relative.y < 1.1


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


func _make_rounded_cube_mesh(size: float, radius: float, grid: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	var inner := half - radius
	for face in FACE_DEFINITIONS:
		var normal := face["normal"] as Vector3
		var u := face["u"] as Vector3
		var v := face["v"] as Vector3
		for y in range(grid):
			for x in range(grid):
				var p00 := _rounded_cube_vertex(normal, u, v, x, y, grid, half, inner, radius)
				var p10 := _rounded_cube_vertex(normal, u, v, x + 1, y, grid, half, inner, radius)
				var p11 := _rounded_cube_vertex(normal, u, v, x + 1, y + 1, grid, half, inner, radius)
				var p01 := _rounded_cube_vertex(normal, u, v, x, y + 1, grid, half, inner, radius)
				_add_mesh_vertex(st, p00)
				_add_mesh_vertex(st, p10)
				_add_mesh_vertex(st, p11)
				_add_mesh_vertex(st, p00)
				_add_mesh_vertex(st, p11)
				_add_mesh_vertex(st, p01)
	return st.commit()


func _make_flat_beveled_cube_mesh(size: float, bevel: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
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


func _rounded_cube_vertex(normal: Vector3, u: Vector3, v: Vector3, x: int, y: int, grid: int, half: float, inner: float, radius: float) -> Dictionary:
	var sx := -half + _size_ratio(x, grid) * half * 2.0
	var sy := -half + _size_ratio(y, grid) * half * 2.0
	var raw := normal * half + u * sx + v * sy
	var clamped := Vector3(
		clampf(raw.x, -inner, inner),
		clampf(raw.y, -inner, inner),
		clampf(raw.z, -inner, inner)
	)
	var rounded_normal := raw - clamped
	if rounded_normal.length_squared() < 0.000001:
		rounded_normal = normal
	else:
		rounded_normal = rounded_normal.normalized()
	return {
		"position": clamped + rounded_normal * radius,
		"normal": rounded_normal,
	}


func _size_ratio(value: int, max_value: int) -> float:
	return float(value) / float(maxi(1, max_value))


func _add_mesh_vertex(st: SurfaceTool, data: Dictionary) -> void:
	st.set_normal(data["normal"] as Vector3)
	st.add_vertex(data["position"] as Vector3)


func _make_cylinder_mesh(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return mesh


func _make_annulus_mesh(inner_radius: float, outer_radius: float, segments: int, start_angle: float, arc_angle: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(segments):
		var a0 := start_angle + arc_angle * float(i) / float(segments)
		var a1 := start_angle + arc_angle * float(i + 1) / float(segments)
		var p00 := Vector3(cos(a0) * inner_radius, 0.0, sin(a0) * inner_radius)
		var p10 := Vector3(cos(a1) * inner_radius, 0.0, sin(a1) * inner_radius)
		var p11 := Vector3(cos(a1) * outer_radius, 0.0, sin(a1) * outer_radius)
		var p01 := Vector3(cos(a0) * outer_radius, 0.0, sin(a0) * outer_radius)
		for point in [p00, p10, p11, p00, p11, p01]:
			st.set_normal(Vector3.UP)
			st.add_vertex(point)
	return st.commit()


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


func _make_standard_material(color: Color, roughness: float, metallic: float, unshaded: bool = false, transparent: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if transparent or color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _make_standard_material(color, 0.5, 0.0, false, color.a < 0.999)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _make_panel_container(node_name: String, minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.067, 0.094, 0.153, 0.82), Color(1, 1, 1, 0.18), 1, 22))
	return panel


func _make_margin_container(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


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
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _make_label(text: String, font_size: int, color: Color, bold: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.45))
	return label


func _make_badge_label(text: String) -> Label:
	var badge := Label.new()
	badge.text = text
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color(0.875, 0.98, 1.0))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(78, 26)
	badge.add_theme_stylebox_override("normal", _make_panel_style(Color(0.031, 0.569, 0.698, 0.18), Color(0.431, 0.906, 0.976, 0.35), 1, 13))
	return badge


func _make_button(text: String, node_name: String, primary: bool, font_size: int = 14) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.027, 0.067, 0.122) if primary else Color(0.972, 0.98, 0.988))
	button.add_theme_stylebox_override(
		"normal",
		_make_panel_style(Color(0.431, 0.906, 0.976, 0.95) if primary else Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.14), 1 if not primary else 0, 16)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_panel_style(Color(0.655, 0.953, 0.816, 0.98) if primary else Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.18), 1 if not primary else 0, 16)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_panel_style(Color(0.329, 0.82, 0.91, 0.95) if primary else Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.18), 1 if not primary else 0, 16)
	)
	return button


func _current_dice_count() -> int:
	return clampi(int(round(dice_count_slider.value if dice_count_slider != null else 4.0)), 1, 6)


func _refresh_target_controls() -> void:
	var count := _current_dice_count()
	for i in range(target_controls.size()):
		var active := i < count
		target_controls[i].disabled = not active or planning
		target_cells[i].modulate = Color(1, 1, 1, 1) if active else Color(1, 1, 1, 0.36)


func _read_targets(count: int) -> Array:
	var targets: Array = []
	for i in range(count):
		var selected_id := target_controls[i].get_selected_id() if i < target_controls.size() else 0
		targets.append(selected_id if selected_id >= 1 and selected_id <= 6 else null)
	return targets


func _make_null_targets(count: int) -> Array:
	var targets: Array = []
	for _i in range(count):
		targets.append(null)
	return targets


func _has_explicit_targets(targets: Array) -> bool:
	for value in targets:
		if value != null:
			return true
	return false


func _fill_random_targets() -> void:
	var count := _current_dice_count()
	for i in range(count):
		_select_option_by_id(target_controls[i], rng.randi_range(1, 6))
	_refresh_target_controls()


func _clear_targets() -> void:
	for option in target_controls:
		_select_option_by_id(option, 0)
	_refresh_target_controls()


func _select_option_by_id(option: OptionButton, id: int) -> void:
	for item_index in range(option.item_count):
		if option.get_item_id(item_index) == id:
			option.select(item_index)
			return


func _set_planning(value: bool) -> void:
	planning = value
	drop_button.disabled = value
	reset_button.disabled = value
	camera_button.disabled = value
	random_target_button.disabled = value
	clear_target_button.disabled = value
	back_button.disabled = value
	dice_count_slider.editable = not value
	progress_bar.visible = value
	if not value:
		progress_bar.value = 0.0
	_refresh_target_controls()


func _update_result_ui(values: Array, suffix: String, status: String, targets: Array) -> void:
	for child in faces_container.get_children():
		child.queue_free()
	if values.is_empty():
		sum_value_label.text = "—"
	else:
		var sum := 0
		for value in values:
			sum += int(value)
		sum_value_label.text = str(sum)
		for i in range(values.size()):
			faces_container.add_child(_make_face_token(int(values[i]), i < targets.size() and targets[i] != null))
	sum_suffix_label.text = suffix
	status_label.text = status


func _make_face_token(value: int, targeted: bool) -> Control:
	var panel := PanelContainer.new()
	panel.name = "FaceToken%d" % value
	panel.custom_minimum_size = Vector2(36, 36)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.92, 0.95, 0.98), Color(0.431, 0.906, 0.976, 0.9) if targeted else Color(0, 0, 0, 0.0), 2 if targeted else 0, 12))
	var label := _make_label(str(value), 18, Color(0.024, 0.067, 0.122), true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _apply_slow_motion_state() -> void:
	var wants_slow := rolling and slow_toggle != null and slow_toggle.button_pressed and not planning
	var target_scale := SLOW_TIME_SCALE if wants_slow else 1.0
	if absf(Engine.time_scale - target_scale) > 0.001:
		Engine.time_scale = target_scale


func _reset_camera() -> void:
	var default_position := Vector3(5.8, 7.7, 7.4)
	camera_distance = default_position.distance_to(camera_target)
	camera_pitch = asin((default_position.y - camera_target.y) / camera_distance)
	camera_yaw = atan2(default_position.x - camera_target.x, default_position.z - camera_target.z)
	_update_camera()


func _update_camera() -> void:
	if camera == null:
		return
	var x := sin(camera_yaw) * cos(camera_pitch) * camera_distance
	var y := sin(camera_pitch) * camera_distance
	var z := cos(camera_yaw) * cos(camera_pitch) * camera_distance
	camera.global_position = camera_target + Vector3(x, y, z)
	camera.look_at(camera_target)


func _on_back_pressed() -> void:
	_clear_dice(false)
	back_requested.emit()
	if back_callback.is_valid():
		back_callback.call()


func automation_get_snapshot() -> Dictionary:
	return {
		"dice_count": _current_dice_count(),
		"active_dice": dice.size(),
		"rolling": rolling,
		"planning": planning,
		"recorded_playback": recorded_playback,
		"recorded_duration": recorded_duration,
		"targets": _read_targets(_current_dice_count()),
		"last_values": last_values.duplicate(),
		"status": status_label.text if status_label != null else "",
		"camera_yaw": camera_yaw,
		"camera_pitch": camera_pitch,
		"camera_distance": camera_distance,
		"target_plan_latency_ms": last_target_plan_latency_ms,
		"target_plan_source": last_target_plan_source,
		"target_solver_ready": _target_solver_ready(),
		"target_cache_ready": _target_solver_ready(),
		"target_cache_counts": _target_solver_counts(),
		"dice_positions": _dice_positions_snapshot(),
		"target_min_path_separation": last_target_min_path_separation,
		"target_min_table_margin": last_target_min_table_margin,
	}


func _plan_min_table_margin(trajectories: Array) -> float:
	if trajectories.is_empty():
		return INF
	var safe_half_width := TABLE_WIDTH * 0.5 - 0.78
	var safe_half_depth := TABLE_DEPTH * 0.5 - 0.78
	var min_margin := INF
	for trajectory_value in trajectories:
		var trajectory := trajectory_value as Array
		for frame_value in trajectory:
			var frame := frame_value as Dictionary
			var position := frame["position"] as Vector3
			if position.y > 1.55:
				continue
			var x_margin := safe_half_width - absf(position.x)
			var z_margin := safe_half_depth - absf(position.z)
			min_margin = minf(min_margin, minf(x_margin, z_margin))
	return min_margin


func _plan_min_temporal_xz_separation(trajectories: Array) -> float:
	if trajectories.size() < 2:
		return INF
	var min_distance := INF
	for i in range(trajectories.size()):
		var a_trajectory := trajectories[i] as Array
		for j in range(i + 1, trajectories.size()):
			var b_trajectory := trajectories[j] as Array
			if a_trajectory.is_empty() or b_trajectory.is_empty():
				continue
			var max_size := maxi(a_trajectory.size(), b_trajectory.size())
			for frame_index in range(max_size):
				var a_frame := a_trajectory[mini(frame_index, a_trajectory.size() - 1)] as Dictionary
				var b_frame := b_trajectory[mini(frame_index, b_trajectory.size() - 1)] as Dictionary
				var a_position := a_frame["position"] as Vector3
				var b_position := b_frame["position"] as Vector3
				if absf(a_position.y - b_position.y) > DIE_SIZE * 0.92:
					continue
				var a_xz := Vector2(a_position.x, a_position.z)
				var b_xz := Vector2(b_position.x, b_position.z)
				min_distance = minf(min_distance, a_xz.distance_to(b_xz))
	return min_distance


func _dice_positions_snapshot() -> Array:
	var positions: Array = []
	for body in dice:
		if body != null and is_instance_valid(body):
			positions.append(body.global_position)
	return positions


func _target_solver_counts() -> Dictionary:
	return {
		"native_solver": 1 if _target_solver_ready() else 0,
	}


func automation_set_dice_count(count: int) -> void:
	if dice_count_slider == null:
		return
	dice_count_slider.value = clampi(count, 1, 6)
	dice_count_value_label.text = str(_current_dice_count())
	_refresh_target_controls()


func automation_set_targets(values: Array) -> void:
	for i in range(target_controls.size()):
		var value = values[i] if i < values.size() else null
		_select_option_by_id(target_controls[i], int(value) if value != null else 0)
	_refresh_target_controls()


func automation_drop_random(count: int = 2) -> void:
	automation_set_dice_count(count)
	automation_set_targets([])
	active_targets = _make_null_targets(_current_dice_count())
	var plan: Array = []
	for i in range(_current_dice_count()):
		plan.append(_make_initial_params(i, _current_dice_count(), false))
	_apply_plan(plan)


func automation_clear() -> void:
	_clear_dice(true)
