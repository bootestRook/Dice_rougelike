extends Control
class_name GmDiceHud


signal roll_requested(use_targets: bool)
signal clear_requested
signal back_requested
signal dice_count_changed(count: int)
signal targets_changed(values: Array)
signal throw_tuning_changed(config: Dictionary)
signal camera_tuning_changed(config: Dictionary)


var dice_count_slider: HSlider = null
var dice_count_value_label: Label = null
var dice_count_minus_button: Button = null
var dice_count_plus_button: Button = null
var drop_button: Button = null
var random_drop_button: Button = null
var reset_button: Button = null
var back_button: Button = null
var random_target_button: Button = null
var clear_target_button: Button = null
var tuning_button: Button = null
var tuning_panel: PanelContainer = null
var target_grid: GridContainer = null
var result_list: VBoxContainer = null
var status_label: Label = null
var formula_label: Label = null
var score_label: Label = null
var goal_label: Label = null
var roll_count_label: Label = null
var debug_label: Label = null
var target_controls: Array[OptionButton] = []
var tuning_sliders := {}
var tuning_value_labels := {}
var camera_sliders := {}
var camera_value_labels := {}

var _current_values: Array = []
var _default_tuning := {
	"forward_speed": 10.0,
	"lateral_speed": 5.0,
	"upward_speed": 3.2,
	"angular_speed": 28.0,
	"torque_impulse": 24.0,
}
var _default_camera_tuning := {
	"fov": 38.0,
	"position_y": 18.5,
	"position_z": 1.0,
	"look_at_y": 0.72,
	"look_at_z": -0.04,
	"dice_initial_height": 7.5,
	"key_light_pitch": -63.0,
	"key_light_yaw": 115.0,
}


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	name = "GmDiceHud"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_stage_frame()
	_build_top_icons()
	_build_throw_dock()
	_build_tuning_panel()
	_build_hidden_dev_controls()


func set_dice_count(count: int) -> void:
	var resolved := clampi(count, 1, 6)
	if dice_count_slider != null:
		dice_count_slider.set_value_no_signal(resolved)
	if dice_count_value_label != null:
		dice_count_value_label.text = str(resolved)
	_rebuild_target_controls(resolved)


func get_dice_count() -> int:
	return int(dice_count_slider.value) if dice_count_slider != null else 4


func set_targets(values: Array) -> void:
	_apply_targets(values)
	targets_changed.emit(get_targets())


func get_targets() -> Array:
	var values: Array = []
	for option in target_controls:
		var selected_id := option.get_selected_id()
		values.append(selected_id if selected_id >= 1 and selected_id <= 6 else null)
	return values


func get_throw_tuning() -> Dictionary:
	var config := {}
	for key in _default_tuning.keys():
		var slider = tuning_sliders.get(key)
		config[key] = float(slider.value) if slider is HSlider else float(_default_tuning[key])
	return config


func set_throw_tuning(config: Dictionary) -> void:
	for key in _default_tuning.keys():
		var slider = tuning_sliders.get(key)
		var value_label = tuning_value_labels.get(key)
		var value := float(config.get(key, _default_tuning[key]))
		if slider is HSlider:
			value = clampf(value, float(slider.min_value), float(slider.max_value))
			slider.set_value_no_signal(value)
		if value_label is Label:
			value_label.text = "%.1f" % value
	throw_tuning_changed.emit(get_throw_tuning())


func get_camera_tuning() -> Dictionary:
	var config := {}
	for key in _default_camera_tuning.keys():
		var slider = camera_sliders.get(key)
		config[key] = float(slider.value) if slider is HSlider else float(_default_camera_tuning[key])
	return config


func set_camera_tuning(config: Dictionary) -> void:
	for key in _default_camera_tuning.keys():
		var slider = camera_sliders.get(key)
		var value_label = camera_value_labels.get(key)
		var value := float(config.get(key, _default_camera_tuning[key]))
		if slider is HSlider:
			value = clampf(value, float(slider.min_value), float(slider.max_value))
			slider.set_value_no_signal(value)
		if value_label is Label:
			value_label.text = "%.2f" % value


func update_state(snapshot: Dictionary) -> void:
	_current_values = snapshot.get("last_values", [])
	var face_indices: Array = snapshot.get("last_face_indices", [])
	var rolling := bool(snapshot.get("rolling", false))
	_render_results(_current_values, face_indices)
	if status_label != null:
		status_label.text = "投掷中" if rolling else "待投掷"
	if debug_label != null:
		debug_label.text = _physics_debug_text(snapshot)


func set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text


func _build_stage_frame() -> void:
	var frame := Panel.new()
	frame.name = "StageFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.visible = false
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	var inner_vignette := Panel.new()
	inner_vignette.name = "StagePurpleVignette"
	inner_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_vignette.visible = false
	inner_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inner_vignette)


func _build_top_icons() -> void:
	var row := HBoxContainer.new()
	row.name = "TopIconBar"
	row.anchor_left = 0.845
	row.anchor_top = 0.030
	row.anchor_right = 0.985
	row.anchor_bottom = 0.105
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	tuning_button = _make_icon_button("参数", "TuningButton")
	tuning_button.pressed.connect(func() -> void:
		if tuning_panel != null:
			tuning_panel.visible = not tuning_panel.visible
	)
	row.add_child(tuning_button)
	reset_button = _make_icon_button("清场", "ResetButton")
	reset_button.pressed.connect(func() -> void: clear_requested.emit())
	row.add_child(reset_button)
	back_button = _make_icon_button("返回", "BackButton")
	back_button.pressed.connect(func() -> void: back_requested.emit())
	row.add_child(back_button)


func _build_throw_dock() -> void:
	var dock := PanelContainer.new()
	dock.name = "ThrowDock"
	dock.anchor_left = 0.345
	dock.anchor_top = 0.785
	dock.anchor_right = 0.650
	dock.anchor_bottom = 0.935
	dock.mouse_filter = Control.MOUSE_FILTER_STOP
	dock.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.16, 0.12, 0.94), Color(0.00, 0.96, 0.66, 0.90), 4, 5))
	add_child(dock)

	var margin := _make_margin(18, 8, 18, 10)
	dock.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var icon := _make_label("骰", 42, Color(0.88, 1.00, 0.92))
	icon.custom_minimum_size = Vector2(58, 64)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)

	dice_count_minus_button = _make_button("-", "DiceCountMinusButton", Vector2(50, 54), 30)
	dice_count_minus_button.pressed.connect(func() -> void: _adjust_dice_count(-1))
	row.add_child(dice_count_minus_button)

	var count_chip := PanelContainer.new()
	count_chip.name = "ThrowCountChip"
	count_chip.custom_minimum_size = Vector2(62, 54)
	count_chip.add_theme_stylebox_override("panel", _make_panel_style(Color(0.10, 0.58, 0.45, 0.95), Color(0.64, 1.00, 0.84, 0.92), 2, 4))
	row.add_child(count_chip)
	var count_margin := _make_margin(6, 3, 6, 4)
	count_chip.add_child(count_margin)
	dice_count_value_label = _make_label("4", 31, Color(0.94, 1.00, 0.92))
	dice_count_value_label.name = "DiceCountValueLabel"
	dice_count_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_margin.add_child(dice_count_value_label)

	dice_count_plus_button = _make_button("+", "DiceCountPlusButton", Vector2(50, 54), 30)
	dice_count_plus_button.pressed.connect(func() -> void: _adjust_dice_count(1))
	row.add_child(dice_count_plus_button)

	drop_button = _make_button("投掷", "DropButton", Vector2(190, 70), 42)
	drop_button.pressed.connect(func() -> void: roll_requested.emit(true))
	row.add_child(drop_button)

	random_drop_button = _make_button("随机", "RandomDropButton", Vector2(1, 1), 1)
	random_drop_button.visible = false
	random_drop_button.pressed.connect(func() -> void: roll_requested.emit(false))
	add_child(random_drop_button)


func _build_tuning_panel() -> void:
	tuning_panel = PanelContainer.new()
	tuning_panel.name = "ThrowTuningPanel"
	tuning_panel.anchor_left = 0.690
	tuning_panel.anchor_top = 0.120
	tuning_panel.anchor_right = 0.985
	tuning_panel.anchor_bottom = 0.940
	tuning_panel.visible = false
	tuning_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	tuning_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.040, 0.052, 0.94), Color(0.00, 0.88, 0.66, 0.82), 3, 5))
	add_child(tuning_panel)

	var margin := _make_margin(12, 10, 12, 12)
	tuning_panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	margin.add_child(layout)

	var title := _make_label("投掷参数", 18, Color(0.88, 1.00, 0.94))
	layout.add_child(title)
	_add_tuning_slider(layout, "forward_speed", "前向速度", 1.0, 16.0, _default_tuning["forward_speed"])
	_add_tuning_slider(layout, "lateral_speed", "横向速度", 0.0, 9.0, _default_tuning["lateral_speed"])
	_add_tuning_slider(layout, "upward_speed", "向上速度", 0.0, 7.0, _default_tuning["upward_speed"])
	_add_tuning_slider(layout, "angular_speed", "角速度", 0.0, 48.0, _default_tuning["angular_speed"])
	_add_tuning_slider(layout, "torque_impulse", "扭矩冲量", 0.0, 48.0, _default_tuning["torque_impulse"])


	var camera_title := _make_label("镜头参数", 18, Color(0.88, 1.00, 0.94))
	camera_title.name = "CameraTuningTitle"
	layout.add_child(camera_title)
	_add_camera_slider(layout, "fov", "视野", 25.0, 60.0, _default_camera_tuning["fov"])
	_add_camera_slider(layout, "position_y", "相机高度", 4.0, 30.0, _default_camera_tuning["position_y"])
	_add_camera_slider(layout, "position_z", "相机前后", -1.0, 9.0, _default_camera_tuning["position_z"])
	_add_camera_slider(layout, "look_at_y", "看向高度", -1.0, 3.0, _default_camera_tuning["look_at_y"])
	_add_camera_slider(layout, "look_at_z", "看向前后", -3.0, 3.0, _default_camera_tuning["look_at_z"])
	_add_camera_slider(layout, "dice_initial_height", "骰子初始高度", 0.8, 10.0, _default_camera_tuning["dice_initial_height"])
	_add_camera_slider(layout, "key_light_pitch", "光照俯仰", -90.0, 0.0, _default_camera_tuning["key_light_pitch"])
	_add_camera_slider(layout, "key_light_yaw", "光照方向", -180.0, 180.0, _default_camera_tuning["key_light_yaw"])


func _add_tuning_slider(parent: Control, key: String, label_text: String, min_value: float, max_value: float, default_value: float) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var label := _make_label(label_text, 13, Color(0.86, 0.92, 0.90))
	label.name = "%sLabel" % key.to_pascal_case()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := _make_label("%.1f" % default_value, 13, Color(1.00, 0.94, 0.58))
	value_label.name = "%sValueLabel" % key.to_pascal_case()
	value_label.custom_minimum_size = Vector2(44, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	var slider := HSlider.new()
	slider.name = "%sSlider" % key.to_pascal_case()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.1
	slider.value = default_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%.1f" % value
		throw_tuning_changed.emit(get_throw_tuning())
	)
	box.add_child(slider)
	tuning_sliders[key] = slider
	tuning_value_labels[key] = value_label


func _add_camera_slider(parent: Control, key: String, label_text: String, min_value: float, max_value: float, default_value: float) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var label := _make_label(label_text, 13, Color(0.86, 0.92, 0.90))
	label.name = "Camera%sLabel" % key.to_pascal_case()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := _make_label("%.2f" % default_value, 13, Color(1.00, 0.94, 0.58))
	value_label.name = "Camera%sValueLabel" % key.to_pascal_case()
	value_label.custom_minimum_size = Vector2(52, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	var slider := HSlider.new()
	slider.name = "Camera%sSlider" % key.to_pascal_case()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.01
	slider.value = default_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%.2f" % value
		camera_tuning_changed.emit(get_camera_tuning())
	)
	box.add_child(slider)
	camera_sliders[key] = slider
	camera_value_labels[key] = value_label


func _build_hidden_dev_controls() -> void:
	var panel := PanelContainer.new()
	panel.name = "ScoreBoardPanel"
	panel.visible = false
	add_child(panel)

	var dev_panel := PanelContainer.new()
	dev_panel.name = "TargetPanel"
	dev_panel.visible = false
	add_child(dev_panel)
	var layout := VBoxContainer.new()
	dev_panel.add_child(layout)

	dice_count_slider = HSlider.new()
	dice_count_slider.name = "DiceCountSlider"
	dice_count_slider.min_value = 1
	dice_count_slider.max_value = 6
	dice_count_slider.step = 1
	dice_count_slider.value = 4
	dice_count_slider.value_changed.connect(_on_dice_count_slider_changed)
	layout.add_child(dice_count_slider)

	target_grid = GridContainer.new()
	target_grid.name = "TargetGrid"
	target_grid.columns = 2
	layout.add_child(target_grid)
	_rebuild_target_controls(4)

	random_target_button = Button.new()
	random_target_button.name = "RandomTargetButton"
	random_target_button.text = "随机目标"
	random_target_button.pressed.connect(_on_random_targets_pressed)
	layout.add_child(random_target_button)

	clear_target_button = Button.new()
	clear_target_button.name = "ClearTargetButton"
	clear_target_button.text = "清空目标"
	clear_target_button.pressed.connect(_on_clear_targets_pressed)
	layout.add_child(clear_target_button)

	result_list = VBoxContainer.new()
	result_list.name = "ResultList"
	layout.add_child(result_list)

	debug_label = _make_label("", 12, Color(0.70, 0.76, 0.78))
	debug_label.name = "DebugLabel"
	debug_label.visible = false
	layout.add_child(debug_label)


func _rebuild_target_controls(count: int) -> void:
	if target_grid == null:
		return
	var old_values := get_targets()
	for child in target_grid.get_children():
		target_grid.remove_child(child)
		child.queue_free()
	target_controls.clear()
	for index in range(count):
		var label := _make_label("骰子%d" % [index + 1], 14, Color.WHITE)
		target_grid.add_child(label)
		var option := OptionButton.new()
		option.name = "TargetOption%d" % [index + 1]
		option.add_item("随机", 0)
		for value in range(1, 7):
			option.add_item("%d点" % value, value)
		option.item_selected.connect(_on_target_option_changed)
		target_grid.add_child(option)
		target_controls.append(option)
	if not old_values.is_empty():
		_apply_targets(old_values)


func _apply_targets(values: Array) -> void:
	for index in range(target_controls.size()):
		var option := target_controls[index]
		var value = values[index] if index < values.size() else null
		option.select(0 if value == null else clampi(int(value), 0, 6))


func _render_results(values: Array, face_indices: Array) -> void:
	if result_list == null:
		return
	for child in result_list.get_children():
		result_list.remove_child(child)
		child.queue_free()
	for index in range(values.size()):
		var face_index := int(face_indices[index]) if index < face_indices.size() else -1
		var row := _make_label("骰子%d：%d点（面位 %d）" % [index + 1, int(values[index]), face_index + 1], 12, Color.WHITE)
		row.name = "ResultRow%d" % [index + 1]
		result_list.add_child(row)


func _physics_debug_text(snapshot: Dictionary) -> String:
	var dice_rows: Array = snapshot.get("dice", [])
	var max_linear := 0.0
	var max_angular := 0.0
	var min_stable := 999
	for row in dice_rows:
		if row is Dictionary:
			max_linear = maxf(max_linear, float(row.get("linear_speed", 0.0)))
			max_angular = maxf(max_angular, float(row.get("angular_speed", 0.0)))
			min_stable = mini(min_stable, int(row.get("stable_frames", 0)))
	if dice_rows.is_empty():
		min_stable = 0
	return "线速度 %.2f / 角速度 %.2f / 稳定帧 %d" % [max_linear, max_angular, min_stable]


func _on_dice_count_slider_changed(value: float) -> void:
	var count := int(value)
	if dice_count_value_label != null:
		dice_count_value_label.text = str(count)
	_rebuild_target_controls(count)
	dice_count_changed.emit(count)


func _adjust_dice_count(delta: int) -> void:
	var count := clampi(get_dice_count() + delta, 1, 6)
	set_dice_count(count)
	dice_count_changed.emit(count)


func _on_target_option_changed(_selected: int) -> void:
	targets_changed.emit(get_targets())


func _on_random_targets_pressed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var values: Array = []
	for _i in range(get_dice_count()):
		values.append(rng.randi_range(1, 6))
	set_targets(values)


func _on_clear_targets_pressed() -> void:
	var values: Array = []
	for _i in range(get_dice_count()):
		values.append(null)
	set_targets(values)


func _add_top_badge(parent: Control, text: String, fill: Color) -> void:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(78, 42)
	badge.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.04, 0.05, 0.88), fill, 3, 4))
	parent.add_child(badge)
	var label := _make_label(text, 17, Color(0.94, 0.94, 0.90))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(label)


func _make_icon_button(text: String, node_name: String) -> Button:
	return _make_button(text, node_name, Vector2(72, 42), 16)


func _make_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03))
	label.add_theme_constant_override("outline_size", 5)
	return label


func _make_button(text: String, node_name: String, min_size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = min_size
	button.clip_text = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.06, 0.24, 0.18, 0.96), Color(0.00, 0.88, 0.62, 0.92), 3, 5))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.10, 0.34, 0.25, 0.98), Color(0.30, 1.00, 0.78, 0.98), 3, 5))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.18, 0.13, 0.30, 0.98), Color(0.95, 0.86, 1.00, 0.98), 3, 5))
	button.add_theme_color_override("font_color", Color(0.94, 1.00, 0.95))
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
