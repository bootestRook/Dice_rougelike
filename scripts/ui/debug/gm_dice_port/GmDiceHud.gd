extends Control
class_name GmDiceHud


const GmDiceDefinitionScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")


signal roll_requested(use_targets: bool)
signal clear_requested
signal back_requested
signal dice_exit_requested
signal dice_return_requested
signal dice_count_changed(count: int)
signal targets_changed(values: Array)
signal dice_replace_requested(material_id: StringName, face_pips: Array, apply_to_all: bool)
signal idle_drift_tuning_changed(config: Dictionary)
signal throw_speed_tuning_changed(config: Dictionary)
signal throw_spin_tuning_changed(config: Dictionary)
signal exit_return_tuning_changed(config: Dictionary)
signal camera_tuning_changed(config: Dictionary)
signal projected_ui_board_visibility_changed(enabled: bool)
signal projected_ui_board_flat_mode_changed(enabled: bool)


var dice_count_slider: HSlider = null
var dice_count_value_label: Label = null
var dice_count_minus_button: Button = null
var dice_count_plus_button: Button = null
var drop_button: Button = null
var random_drop_button: Button = null
var fly_exit_button: Button = null
var return_button: Button = null
var reset_button: Button = null
var back_button: Button = null
var random_target_button: Button = null
var clear_target_button: Button = null
var tuning_button: Button = null
var dice_edit_button: Button = null
var dice_edit_panel: PanelContainer = null
var dice_edit_drag_handle: Label = null
var dice_material_option: OptionButton = null
var dice_edit_summary_label: Label = null
var apply_selected_dice_edit_button: Button = null
var apply_all_dice_edit_button: Button = null
var tuning_panel: PanelContainer = null
var projected_ui_board_visible_check: CheckBox = null
var projected_ui_board_flat_check: CheckBox = null
var target_grid: GridContainer = null
var result_list: VBoxContainer = null
var status_label: Label = null
var formula_label: Label = null
var score_label: Label = null
var goal_label: Label = null
var roll_count_label: Label = null
var debug_label: Label = null
var target_controls: Array[OptionButton] = []
var idle_drift_sliders := {}
var idle_drift_value_labels := {}
var throw_speed_sliders := {}
var throw_speed_value_labels := {}
var throw_spin_sliders := {}
var throw_spin_value_labels := {}
var exit_return_sliders := {}
var exit_return_value_labels := {}
var camera_sliders := {}
var camera_value_labels := {}
var face_pip_options: Array[OptionButton] = []
var _dice_edit_dragging := false

var _current_values: Array = []
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
var _default_idle_drift_tuning := {
	"min_seconds": 1.15,
	"max_seconds": 2.35,
	"max_distance": 0.07,
	"speed": 0.05,
}
var _default_throw_speed_tuning := {
	"linear_speed_min": 8.0,
	"linear_speed_max": 12.0,
}
var _default_throw_spin_tuning := {
	"angular_speed_min": 4.0,
	"angular_speed_max": 9.5,
	"torque_min": 2.0,
	"torque_max": 5.0,
}
var _default_exit_return_tuning := {
	"screen_x": 0.66,
	"screen_y": 0.44,
	"spawn_y": 20.0,
}


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	if get_child_count() > 0:
		return
	name = "GmDiceHud"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_stage_frame()
	_build_top_icons()
	_build_projected_ui_board_controls()
	_build_throw_dock()
	_build_dice_edit_panel()
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


func get_idle_drift_tuning() -> Dictionary:
	var min_slider = idle_drift_sliders.get("min_seconds")
	var max_slider = idle_drift_sliders.get("max_seconds")
	var min_seconds := float(min_slider.value) if min_slider is HSlider else float(_default_idle_drift_tuning["min_seconds"])
	var max_seconds := float(max_slider.value) if max_slider is HSlider else float(_default_idle_drift_tuning["max_seconds"])
	if max_seconds < min_seconds:
		max_seconds = min_seconds
	var distance_slider = idle_drift_sliders.get("max_distance")
	var speed_slider = idle_drift_sliders.get("speed")
	return {
		"min_seconds": min_seconds,
		"max_seconds": max_seconds,
		"max_distance": float(distance_slider.value) if distance_slider is HSlider else float(_default_idle_drift_tuning["max_distance"]),
		"speed": float(speed_slider.value) if speed_slider is HSlider else float(_default_idle_drift_tuning["speed"]),
	}


func set_idle_drift_tuning(config: Dictionary) -> void:
	var min_seconds := float(config.get("min_seconds", _default_idle_drift_tuning["min_seconds"]))
	var max_seconds := float(config.get("max_seconds", _default_idle_drift_tuning["max_seconds"]))
	if max_seconds < min_seconds:
		max_seconds = min_seconds
	var resolved := {
		"min_seconds": min_seconds,
		"max_seconds": max_seconds,
		"max_distance": float(config.get("max_distance", _default_idle_drift_tuning["max_distance"])),
		"speed": float(config.get("speed", _default_idle_drift_tuning["speed"])),
	}
	for key in _default_idle_drift_tuning.keys():
		var slider = idle_drift_sliders.get(key)
		var value_label = idle_drift_value_labels.get(key)
		var value := float(resolved.get(key, _default_idle_drift_tuning[key]))
		if slider is HSlider:
			value = clampf(value, float(slider.min_value), float(slider.max_value))
			slider.set_value_no_signal(value)
		if value_label is Label:
			value_label.text = "%.2f" % value
	idle_drift_tuning_changed.emit(get_idle_drift_tuning())


func get_throw_speed_tuning() -> Dictionary:
	var min_slider = throw_speed_sliders.get("linear_speed_min")
	var max_slider = throw_speed_sliders.get("linear_speed_max")
	var speed_min := float(min_slider.value) if min_slider is HSlider else float(_default_throw_speed_tuning["linear_speed_min"])
	var speed_max := float(max_slider.value) if max_slider is HSlider else float(_default_throw_speed_tuning["linear_speed_max"])
	if speed_max < speed_min:
		speed_max = speed_min
	return {
		"linear_speed_min": speed_min,
		"linear_speed_max": speed_max,
	}


func set_throw_speed_tuning(config: Dictionary) -> void:
	var speed_min := float(config.get("linear_speed_min", _default_throw_speed_tuning["linear_speed_min"]))
	var speed_max := float(config.get("linear_speed_max", _default_throw_speed_tuning["linear_speed_max"]))
	if speed_max < speed_min:
		speed_max = speed_min
	var resolved := {
		"linear_speed_min": speed_min,
		"linear_speed_max": speed_max,
	}
	for key in _default_throw_speed_tuning.keys():
		var slider = throw_speed_sliders.get(key)
		var value_label = throw_speed_value_labels.get(key)
		var value := float(resolved.get(key, _default_throw_speed_tuning[key]))
		if slider is HSlider:
			value = clampf(value, float(slider.min_value), float(slider.max_value))
			slider.set_value_no_signal(value)
		if value_label is Label:
			value_label.text = "%.1f" % value
	throw_speed_tuning_changed.emit(get_throw_speed_tuning())


func get_throw_spin_tuning() -> Dictionary:
	var angular_min_slider = throw_spin_sliders.get("angular_speed_min")
	var angular_max_slider = throw_spin_sliders.get("angular_speed_max")
	var torque_min_slider = throw_spin_sliders.get("torque_min")
	var torque_max_slider = throw_spin_sliders.get("torque_max")
	var angular_min := float(angular_min_slider.value) if angular_min_slider is HSlider else float(_default_throw_spin_tuning["angular_speed_min"])
	var angular_max := float(angular_max_slider.value) if angular_max_slider is HSlider else float(_default_throw_spin_tuning["angular_speed_max"])
	var torque_min := float(torque_min_slider.value) if torque_min_slider is HSlider else float(_default_throw_spin_tuning["torque_min"])
	var torque_max := float(torque_max_slider.value) if torque_max_slider is HSlider else float(_default_throw_spin_tuning["torque_max"])
	if angular_max < angular_min:
		angular_max = angular_min
	if torque_max < torque_min:
		torque_max = torque_min
	return {
		"angular_speed_min": angular_min,
		"angular_speed_max": angular_max,
		"torque_min": torque_min,
		"torque_max": torque_max,
	}


func set_throw_spin_tuning(config: Dictionary) -> void:
	var angular_min := float(config.get("angular_speed_min", _default_throw_spin_tuning["angular_speed_min"]))
	var angular_max := float(config.get("angular_speed_max", _default_throw_spin_tuning["angular_speed_max"]))
	var torque_min := float(config.get("torque_min", _default_throw_spin_tuning["torque_min"]))
	var torque_max := float(config.get("torque_max", _default_throw_spin_tuning["torque_max"]))
	if angular_max < angular_min:
		angular_max = angular_min
	if torque_max < torque_min:
		torque_max = torque_min
	var resolved := {
		"angular_speed_min": angular_min,
		"angular_speed_max": angular_max,
		"torque_min": torque_min,
		"torque_max": torque_max,
	}
	for key in _default_throw_spin_tuning.keys():
		var slider = throw_spin_sliders.get(key)
		var value_label = throw_spin_value_labels.get(key)
		var value := float(resolved.get(key, _default_throw_spin_tuning[key]))
		if slider is HSlider:
			value = clampf(value, float(slider.min_value), float(slider.max_value))
			slider.set_value_no_signal(value)
		if value_label is Label:
			value_label.text = "%.1f" % value
	throw_spin_tuning_changed.emit(get_throw_spin_tuning())


func get_exit_return_tuning() -> Dictionary:
	var screen_x_slider = exit_return_sliders.get("screen_x")
	var screen_y_slider = exit_return_sliders.get("screen_y")
	var spawn_y_slider = exit_return_sliders.get("spawn_y")
	return {
		"screen_x": float(screen_x_slider.value) if screen_x_slider is HSlider else float(_default_exit_return_tuning["screen_x"]),
		"screen_y": float(screen_y_slider.value) if screen_y_slider is HSlider else float(_default_exit_return_tuning["screen_y"]),
		"spawn_y": float(spawn_y_slider.value) if spawn_y_slider is HSlider else float(_default_exit_return_tuning["spawn_y"]),
	}


func set_exit_return_tuning(config: Dictionary) -> void:
	var resolved_config := config.duplicate(true)
	if resolved_config.has("spawn_x") and not resolved_config.has("screen_x"):
		resolved_config["screen_x"] = clampf(float(resolved_config["spawn_x"]) / 8.0, 0.0, 1.0)
	for key in _default_exit_return_tuning.keys():
		var slider = exit_return_sliders.get(key)
		var value_label = exit_return_value_labels.get(key)
		var value := float(resolved_config.get(key, _default_exit_return_tuning[key]))
		if slider is HSlider:
			value = clampf(value, float(slider.min_value), float(slider.max_value))
			slider.set_value_no_signal(value)
		if value_label is Label:
			value_label.text = "%.2f" % value
	exit_return_tuning_changed.emit(get_exit_return_tuning())


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


func set_projected_ui_board_controls(visible_enabled: bool, flat_enabled: bool) -> void:
	if projected_ui_board_visible_check != null:
		projected_ui_board_visible_check.set_pressed_no_signal(visible_enabled)
	if projected_ui_board_flat_check != null:
		projected_ui_board_flat_check.set_pressed_no_signal(flat_enabled)


func update_state(snapshot: Dictionary) -> void:
	_current_values = snapshot.get("last_values", [])
	var face_indices: Array = snapshot.get("last_face_indices", [])
	var selected_indices: Array = snapshot.get("selected_dice_indices", [])
	var rolling := bool(snapshot.get("rolling", false))
	var active_dice := int(snapshot.get("active_dice", 0))
	var dice_exit_animating := bool(snapshot.get("dice_exit_animating", false))
	var dice_exit_completed := bool(snapshot.get("dice_exit_completed", false))
	var dice_exit_return_animating := bool(snapshot.get("dice_exit_return_animating", false))
	var dice_ready_to_return := dice_exit_completed or _all_dice_exited(snapshot)
	var edit_locked := rolling or dice_exit_animating or dice_exit_return_animating or dice_ready_to_return
	_render_results(_current_values, face_indices)
	if drop_button != null:
		drop_button.disabled = rolling or dice_exit_animating or dice_exit_return_animating or dice_ready_to_return or selected_indices.is_empty()
		drop_button.text = "投掷所选" if not selected_indices.is_empty() else "选择骰子"
	if fly_exit_button != null:
		fly_exit_button.disabled = rolling or dice_exit_animating or dice_exit_return_animating or dice_ready_to_return or active_dice <= 0
	if return_button != null:
		return_button.disabled = dice_exit_animating or dice_exit_return_animating or not dice_ready_to_return
	if status_label != null:
		status_label.text = "投掷中" if rolling else ("已选 %d 颗骰子" % selected_indices.size() if not selected_indices.is_empty() else "请选择骰子")
	if debug_label != null:
		debug_label.text = _physics_debug_text(snapshot)
	_update_dice_edit_state(edit_locked, active_dice, selected_indices)


func set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text


func toggle_dice_edit_panel() -> bool:
	if dice_edit_panel == null:
		return false
	dice_edit_panel.visible = not dice_edit_panel.visible
	return dice_edit_panel.visible


func apply_crystal_dice_preset() -> void:
	_set_edit_material_id(GmDiceDefinitionScript.MATERIAL_CRYSTAL)
	_set_edit_face_pips([1, 2, 3, 4, 5, 6])


func _build_stage_frame() -> void:
	var frame := Panel.new()
	frame.name = "StageFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.visible = false
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.006, 0.014, 0.040, 0.08), Color(0.78, 0.52, 0.28, 0.70), 2, 4))
	add_child(frame)

	var inner_vignette := Panel.new()
	inner_vignette.name = "StagePurpleVignette"
	inner_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_vignette.visible = false
	inner_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_vignette.add_theme_stylebox_override("panel", _make_panel_style(Color(0.005, 0.009, 0.028, 0.05), Color(0.26, 0.37, 0.58, 0.28), 1, 0))
	add_child(inner_vignette)


func _build_top_icons() -> void:
	var row := HBoxContainer.new()
	row.name = "TopIconBar"
	row.anchor_left = 0.570
	row.anchor_top = 0.030
	row.anchor_right = 0.985
	row.anchor_bottom = 0.105
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	fly_exit_button = _make_icon_button("飞走", "FlyAwayButton")
	fly_exit_button.pressed.connect(func() -> void: dice_exit_requested.emit())
	row.add_child(fly_exit_button)
	return_button = _make_icon_button("回归", "ReturnButton")
	return_button.disabled = true
	return_button.pressed.connect(func() -> void: dice_return_requested.emit())
	row.add_child(return_button)
	tuning_button = _make_icon_button("参数", "TuningButton")
	tuning_button.pressed.connect(func() -> void:
		if tuning_panel != null:
			tuning_panel.visible = not tuning_panel.visible
	)
	row.add_child(tuning_button)
	dice_edit_button = _make_icon_button("改骰", "DiceEditButton")
	dice_edit_button.pressed.connect(toggle_dice_edit_panel)
	row.add_child(dice_edit_button)
	reset_button = _make_icon_button("清场", "ResetButton")
	reset_button.pressed.connect(func() -> void: clear_requested.emit())
	row.add_child(reset_button)
	back_button = _make_icon_button("返回", "BackButton")
	back_button.pressed.connect(func() -> void: back_requested.emit())
	row.add_child(back_button)


func _build_projected_ui_board_controls() -> void:
	var panel := PanelContainer.new()
	panel.name = "ProjectedUiBoardPanel"
	panel.anchor_left = 0.015
	panel.anchor_top = 0.125
	panel.anchor_right = 0.125
	panel.anchor_bottom = 0.275
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.040, 0.052, 0.94), Color(0.00, 0.88, 0.66, 0.82), 3, 5))
	add_child(panel)

	var margin := _make_margin(10, 8, 10, 8)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.name = "ProjectedUiBoardRows"
	rows.add_theme_constant_override("separation", 4)
	margin.add_child(rows)

	var title := _make_label("3D界面", 15, Color(0.88, 1.00, 0.94))
	title.name = "ProjectedUiBoardTitle"
	rows.add_child(title)

	projected_ui_board_visible_check = _make_projected_ui_check("显示", "ProjectedUiBoardVisibleCheck", true)
	projected_ui_board_visible_check.toggled.connect(func(enabled: bool) -> void:
		projected_ui_board_visibility_changed.emit(enabled)
	)
	rows.add_child(projected_ui_board_visible_check)

	projected_ui_board_flat_check = _make_projected_ui_check("放平", "ProjectedUiBoardFlatCheck", false)
	projected_ui_board_flat_check.toggled.connect(func(enabled: bool) -> void:
		projected_ui_board_flat_mode_changed.emit(enabled)
	)
	rows.add_child(projected_ui_board_flat_check)


func _build_throw_dock() -> void:
	var dock := PanelContainer.new()
	dock.name = "ThrowDock"
	dock.anchor_left = 0.135
	dock.anchor_top = 0.125
	dock.anchor_right = 0.440
	dock.anchor_bottom = 0.275
	dock.mouse_filter = Control.MOUSE_FILTER_STOP
	dock.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.045, 0.095, 0.92), Color(0.78, 0.50, 0.26, 0.88), 3, 5))
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
	count_chip.add_theme_stylebox_override("panel", _make_panel_style(Color(0.13, 0.20, 0.34, 0.96), Color(0.86, 0.68, 0.36, 0.92), 2, 4))
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

	drop_button = _make_button("选择骰子", "DropButton", Vector2(190, 70), 42)
	drop_button.disabled = true
	drop_button.pressed.connect(func() -> void: roll_requested.emit(true))
	row.add_child(drop_button)

	random_drop_button = _make_button("随机", "RandomDropButton", Vector2(1, 1), 1)
	random_drop_button.visible = false
	random_drop_button.pressed.connect(func() -> void: roll_requested.emit(false))
	add_child(random_drop_button)


func _build_dice_edit_panel() -> void:
	dice_edit_panel = PanelContainer.new()
	dice_edit_panel.name = "DiceEditPanel"
	dice_edit_panel.anchor_left = 0.135
	dice_edit_panel.anchor_top = 0.295
	dice_edit_panel.anchor_right = 0.440
	dice_edit_panel.anchor_bottom = 0.655
	dice_edit_panel.visible = false
	dice_edit_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dice_edit_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.018, 0.030, 0.066, 0.95), Color(0.74, 0.50, 0.28, 0.86), 3, 5))
	add_child(dice_edit_panel)

	var margin := _make_margin(12, 10, 12, 12)
	dice_edit_panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.name = "DiceEditLayout"
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 7)
	margin.add_child(layout)

	dice_edit_drag_handle = _make_label("改骰", 19, Color(0.90, 1.00, 0.96))
	dice_edit_drag_handle.name = "DiceEditTitle"
	dice_edit_drag_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	dice_edit_drag_handle.mouse_default_cursor_shape = Control.CURSOR_MOVE
	dice_edit_drag_handle.gui_input.connect(_on_dice_edit_drag_handle_gui_input)
	layout.add_child(dice_edit_drag_handle)

	dice_edit_summary_label = _make_label("请选择骰子，或直接全部替换", 13, Color(0.78, 0.88, 0.86))
	dice_edit_summary_label.name = "DiceEditSummaryLabel"
	layout.add_child(dice_edit_summary_label)

	var material_row := HBoxContainer.new()
	material_row.name = "DiceMaterialRow"
	material_row.add_theme_constant_override("separation", 8)
	layout.add_child(material_row)
	var material_label := _make_label("骰胚", 14, Color(0.86, 0.94, 0.90))
	material_label.custom_minimum_size = Vector2(52, 0)
	material_row.add_child(material_label)
	dice_material_option = OptionButton.new()
	dice_material_option.name = "DiceMaterialOption"
	dice_material_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_material_options()
	material_row.add_child(dice_material_option)

	var faces_grid := GridContainer.new()
	faces_grid.name = "DiceFacePipGrid"
	faces_grid.columns = 4
	faces_grid.add_theme_constant_override("h_separation", 8)
	faces_grid.add_theme_constant_override("v_separation", 5)
	layout.add_child(faces_grid)
	face_pip_options.clear()
	for index in range(6):
		var face_label := _make_label("面%d" % [index + 1], 13, Color(0.86, 0.94, 0.90))
		faces_grid.add_child(face_label)
		var option := OptionButton.new()
		option.name = "EditFace%dOption" % [index + 1]
		option.custom_minimum_size = Vector2(66, 30)
		for pip in range(1, 7):
			option.add_item("%d点" % pip, pip)
		option.select(index)
		faces_grid.add_child(option)
		face_pip_options.append(option)

	var button_row := HBoxContainer.new()
	button_row.name = "DiceEditButtonRow"
	button_row.add_theme_constant_override("separation", 8)
	layout.add_child(button_row)
	apply_selected_dice_edit_button = _make_button("替换所选", "ApplySelectedDiceEditButton", Vector2(92, 38), 15)
	apply_selected_dice_edit_button.pressed.connect(func() -> void:
		dice_replace_requested.emit(_get_edit_material_id(), _get_edit_face_pips(), false)
	)
	button_row.add_child(apply_selected_dice_edit_button)
	apply_all_dice_edit_button = _make_button("全部替换", "ApplyAllDiceEditButton", Vector2(92, 38), 15)
	apply_all_dice_edit_button.pressed.connect(func() -> void:
		dice_replace_requested.emit(_get_edit_material_id(), _get_edit_face_pips(), true)
	)
	button_row.add_child(apply_all_dice_edit_button)


func _build_tuning_panel() -> void:
	tuning_panel = PanelContainer.new()
	tuning_panel.name = "TuningPanel"
	tuning_panel.anchor_left = 0.690
	tuning_panel.anchor_top = 0.120
	tuning_panel.anchor_right = 0.985
	tuning_panel.anchor_bottom = 0.940
	tuning_panel.visible = false
	tuning_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	tuning_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.018, 0.026, 0.058, 0.94), Color(0.74, 0.50, 0.28, 0.82), 3, 5))
	add_child(tuning_panel)

	var margin := _make_margin(12, 10, 12, 12)
	tuning_panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "TuningScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var layout := VBoxContainer.new()
	layout.name = "ThrowTuningLayout"
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 7)
	scroll.add_child(layout)

	var throw_speed_group := _add_tuning_group(layout, "ThrowSpeedTuningGroup", "投掷初速度")
	_add_throw_speed_slider(throw_speed_group, "linear_speed_min", "初速度下限", 0.0, 12.0, _default_throw_speed_tuning["linear_speed_min"])
	_add_throw_speed_slider(throw_speed_group, "linear_speed_max", "初速度上限", 0.0, 12.0, _default_throw_speed_tuning["linear_speed_max"])

	var throw_spin_group := _add_tuning_group(layout, "ThrowSpinTuningGroup", "投掷旋转参数")
	_add_throw_spin_slider(throw_spin_group, "angular_speed_min", "角速度下限", 0.0, 24.0, _default_throw_spin_tuning["angular_speed_min"])
	_add_throw_spin_slider(throw_spin_group, "angular_speed_max", "角速度上限", 0.0, 24.0, _default_throw_spin_tuning["angular_speed_max"])
	_add_throw_spin_slider(throw_spin_group, "torque_min", "扭矩下限", 0.0, 16.0, _default_throw_spin_tuning["torque_min"])
	_add_throw_spin_slider(throw_spin_group, "torque_max", "扭矩上限", 0.0, 16.0, _default_throw_spin_tuning["torque_max"])

	var idle_group := _add_tuning_group(layout, "IdleDriftTuningGroup", "漂浮参数")
	_add_idle_drift_slider(idle_group, "min_seconds", "最短漂浮时间", 0.2, 6.0, _default_idle_drift_tuning["min_seconds"])
	_add_idle_drift_slider(idle_group, "max_seconds", "最长漂浮时间", 0.2, 8.0, _default_idle_drift_tuning["max_seconds"])
	_add_idle_drift_slider(idle_group, "max_distance", "最远漂浮距离", 0.0, 1.2, _default_idle_drift_tuning["max_distance"])
	_add_idle_drift_slider(idle_group, "speed", "漂浮速度", 0.0, 0.8, _default_idle_drift_tuning["speed"])

	var exit_return_group := _add_tuning_group(layout, "ExitReturnTuningGroup", "回归入口点")
	_add_exit_return_slider(exit_return_group, "screen_x", "画面X", 0.0, 1.0, _default_exit_return_tuning["screen_x"])
	_add_exit_return_slider(exit_return_group, "screen_y", "画面Y", 0.0, 1.0, _default_exit_return_tuning["screen_y"])
	_add_exit_return_slider(exit_return_group, "spawn_y", "入口高度", 0.0, 30.0, _default_exit_return_tuning["spawn_y"])

	var camera_group := _add_tuning_group(layout, "CameraTuningGroup", "镜头参数")
	_add_camera_slider(camera_group, "fov", "视野", 25.0, 60.0, _default_camera_tuning["fov"])
	_add_camera_slider(camera_group, "position_y", "相机高度", 4.0, 30.0, _default_camera_tuning["position_y"])
	_add_camera_slider(camera_group, "position_z", "相机前后", -1.0, 9.0, _default_camera_tuning["position_z"])
	_add_camera_slider(camera_group, "look_at_y", "看向高度", -1.0, 3.0, _default_camera_tuning["look_at_y"])
	_add_camera_slider(camera_group, "look_at_z", "看向前后", -3.0, 3.0, _default_camera_tuning["look_at_z"])
	_add_camera_slider(camera_group, "dice_initial_height", "骰子初始高度", 0.8, 10.0, _default_camera_tuning["dice_initial_height"])
	_add_camera_slider(camera_group, "key_light_pitch", "光照俯仰", -90.0, 0.0, _default_camera_tuning["key_light_pitch"])
	_add_camera_slider(camera_group, "key_light_yaw", "光照方向", -180.0, 180.0, _default_camera_tuning["key_light_yaw"])


func _add_tuning_group(parent: Control, group_name: String, title_text: String) -> VBoxContainer:
	var group := VBoxContainer.new()
	group.name = group_name
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group.add_theme_constant_override("separation", 6)
	parent.add_child(group)

	var title := _make_label(title_text, 18, Color(0.88, 1.00, 0.94))
	title.name = "%sTitle" % group_name
	group.add_child(title)
	return group


func _add_idle_drift_slider(parent: Control, key: String, label_text: String, min_value: float, max_value: float, default_value: float) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var label := _make_label(label_text, 13, Color(0.86, 0.92, 0.90))
	label.name = "IdleDrift%sLabel" % key.to_pascal_case()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := _make_label("%.2f" % default_value, 13, Color(1.00, 0.94, 0.58))
	value_label.name = "IdleDrift%sValueLabel" % key.to_pascal_case()
	value_label.custom_minimum_size = Vector2(52, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	var slider := HSlider.new()
	slider.name = "IdleDrift%sSlider" % key.to_pascal_case()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.01
	slider.value = default_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%.2f" % value
		_sync_idle_drift_seconds(key)
		idle_drift_tuning_changed.emit(get_idle_drift_tuning())
	)
	box.add_child(slider)
	idle_drift_sliders[key] = slider
	idle_drift_value_labels[key] = value_label


func _sync_idle_drift_seconds(changed_key: String) -> void:
	var min_slider = idle_drift_sliders.get("min_seconds")
	var max_slider = idle_drift_sliders.get("max_seconds")
	if not (min_slider is HSlider and max_slider is HSlider):
		return
	var min_value := float(min_slider.value)
	var max_value := float(max_slider.value)
	if max_value >= min_value:
		return
	if changed_key == "max_seconds":
		min_slider.set_value_no_signal(max_value)
		_set_idle_drift_value_label("min_seconds", max_value)
	else:
		max_slider.set_value_no_signal(min_value)
		_set_idle_drift_value_label("max_seconds", min_value)


func _set_idle_drift_value_label(key: String, value: float) -> void:
	var value_label = idle_drift_value_labels.get(key)
	if value_label is Label:
		value_label.text = "%.2f" % value


func _add_throw_speed_slider(parent: Control, key: String, label_text: String, min_value: float, max_value: float, default_value: float) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var label := _make_label(label_text, 13, Color(0.86, 0.92, 0.90))
	label.name = "ThrowSpeed%sLabel" % key.to_pascal_case()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := _make_label("%.1f" % default_value, 13, Color(1.00, 0.94, 0.58))
	value_label.name = "ThrowSpeed%sValueLabel" % key.to_pascal_case()
	value_label.custom_minimum_size = Vector2(52, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	var slider := HSlider.new()
	slider.name = "ThrowSpeed%sSlider" % key.to_pascal_case()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.1
	slider.value = default_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%.1f" % value
		_sync_throw_speed_ranges(key)
		throw_speed_tuning_changed.emit(get_throw_speed_tuning())
	)
	box.add_child(slider)
	throw_speed_sliders[key] = slider
	throw_speed_value_labels[key] = value_label


func _sync_throw_speed_ranges(changed_key: String) -> void:
	var min_slider = throw_speed_sliders.get("linear_speed_min")
	var max_slider = throw_speed_sliders.get("linear_speed_max")
	if not (min_slider is HSlider and max_slider is HSlider):
		return
	var min_value := float(min_slider.value)
	var max_value := float(max_slider.value)
	if max_value >= min_value:
		return
	if changed_key == "linear_speed_max":
		min_slider.set_value_no_signal(max_value)
		_set_throw_speed_value_label("linear_speed_min", max_value)
	elif changed_key == "linear_speed_min":
		max_slider.set_value_no_signal(min_value)
		_set_throw_speed_value_label("linear_speed_max", min_value)


func _set_throw_speed_value_label(key: String, value: float) -> void:
	var value_label = throw_speed_value_labels.get(key)
	if value_label is Label:
		value_label.text = "%.1f" % value


func _add_throw_spin_slider(parent: Control, key: String, label_text: String, min_value: float, max_value: float, default_value: float) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var label := _make_label(label_text, 13, Color(0.86, 0.92, 0.90))
	label.name = "ThrowSpin%sLabel" % key.to_pascal_case()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := _make_label("%.1f" % default_value, 13, Color(1.00, 0.94, 0.58))
	value_label.name = "ThrowSpin%sValueLabel" % key.to_pascal_case()
	value_label.custom_minimum_size = Vector2(52, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	var slider := HSlider.new()
	slider.name = "ThrowSpin%sSlider" % key.to_pascal_case()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.1
	slider.value = default_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%.1f" % value
		_sync_throw_spin_ranges(key)
		throw_spin_tuning_changed.emit(get_throw_spin_tuning())
	)
	box.add_child(slider)
	throw_spin_sliders[key] = slider
	throw_spin_value_labels[key] = value_label


func _sync_throw_spin_ranges(changed_key: String) -> void:
	_sync_throw_spin_pair("angular_speed_min", "angular_speed_max", changed_key)
	_sync_throw_spin_pair("torque_min", "torque_max", changed_key)


func _sync_throw_spin_pair(min_key: String, max_key: String, changed_key: String) -> void:
	var min_slider = throw_spin_sliders.get(min_key)
	var max_slider = throw_spin_sliders.get(max_key)
	if not (min_slider is HSlider and max_slider is HSlider):
		return
	var min_value := float(min_slider.value)
	var max_value := float(max_slider.value)
	if max_value >= min_value:
		return
	if changed_key == max_key:
		min_slider.set_value_no_signal(max_value)
		_set_throw_spin_value_label(min_key, max_value)
	elif changed_key == min_key:
		max_slider.set_value_no_signal(min_value)
		_set_throw_spin_value_label(max_key, min_value)


func _set_throw_spin_value_label(key: String, value: float) -> void:
	var value_label = throw_spin_value_labels.get(key)
	if value_label is Label:
		value_label.text = "%.1f" % value


func _add_exit_return_slider(parent: Control, key: String, label_text: String, min_value: float, max_value: float, default_value: float) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var label := _make_label(label_text, 13, Color(0.86, 0.92, 0.90))
	label.name = "ExitReturn%sLabel" % key.to_pascal_case()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := _make_label("%.2f" % default_value, 13, Color(1.00, 0.94, 0.58))
	value_label.name = "ExitReturn%sValueLabel" % key.to_pascal_case()
	value_label.custom_minimum_size = Vector2(52, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	var slider := HSlider.new()
	slider.name = "ExitReturn%sSlider" % key.to_pascal_case()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.01
	slider.value = default_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%.2f" % value
		exit_return_tuning_changed.emit(get_exit_return_tuning())
	)
	box.add_child(slider)
	exit_return_sliders[key] = slider
	exit_return_value_labels[key] = value_label


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


func _populate_material_options() -> void:
	if dice_material_option == null:
		return
	dice_material_option.clear()
	var options := GmDiceDefinitionScript.get_material_options()
	for index in range(options.size()):
		var option: Dictionary = options[index]
		dice_material_option.add_item(str(option.get("name", "")), index)
		dice_material_option.set_item_metadata(index, option.get("id", GmDiceDefinitionScript.MATERIAL_STANDARD))
	_set_edit_material_id(GmDiceDefinitionScript.MATERIAL_STANDARD)


func _get_edit_material_id() -> StringName:
	if dice_material_option == null or dice_material_option.get_item_count() <= 0:
		return GmDiceDefinitionScript.MATERIAL_STANDARD
	var selected_index := dice_material_option.selected
	if selected_index < 0:
		selected_index = 0
	return GmDiceDefinitionScript.normalize_material_id(StringName(str(dice_material_option.get_item_metadata(selected_index))))


func _set_edit_material_id(material_id: StringName) -> void:
	if dice_material_option == null:
		return
	var normalized_id := GmDiceDefinitionScript.normalize_material_id(material_id)
	for index in range(dice_material_option.get_item_count()):
		if GmDiceDefinitionScript.normalize_material_id(StringName(str(dice_material_option.get_item_metadata(index)))) == normalized_id:
			dice_material_option.select(index)
			return


func _get_edit_face_pips() -> Array:
	var pips: Array = []
	for option in face_pip_options:
		var selected_id := option.get_selected_id()
		pips.append(clampi(selected_id, 1, 6))
	return pips


func _set_edit_face_pips(face_pips: Array) -> void:
	for index in range(face_pip_options.size()):
		var option := face_pip_options[index]
		var pip := index + 1
		if index < face_pips.size() and face_pips[index] != null:
			pip = clampi(int(face_pips[index]), 1, 6)
		option.select(pip - 1)


func _on_dice_edit_drag_handle_gui_input(event: InputEvent) -> void:
	if dice_edit_panel == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		_dice_edit_dragging = mouse_event.pressed
		if _dice_edit_dragging:
			dice_edit_panel.move_to_front()
		accept_event()
	elif event is InputEventMouseMotion and _dice_edit_dragging:
		var motion_event := event as InputEventMouseMotion
		_move_dice_edit_panel_by_delta(motion_event.relative)
		accept_event()


func _move_dice_edit_panel_by_delta(delta: Vector2) -> void:
	if dice_edit_panel == null:
		return
	var viewport_size := get_viewport_rect().size
	var panel_size := dice_edit_panel.size
	var next_position := dice_edit_panel.global_position + delta
	next_position.x = clampf(next_position.x, 0.0, maxf(0.0, viewport_size.x - panel_size.x))
	next_position.y = clampf(next_position.y, 0.0, maxf(0.0, viewport_size.y - panel_size.y))
	dice_edit_panel.global_position = next_position


func _update_dice_edit_state(edit_locked: bool, active_dice: int, selected_indices: Array) -> void:
	if dice_edit_button != null:
		dice_edit_button.disabled = active_dice <= 0
	if apply_selected_dice_edit_button != null:
		apply_selected_dice_edit_button.disabled = edit_locked or selected_indices.is_empty()
	if apply_all_dice_edit_button != null:
		apply_all_dice_edit_button.disabled = edit_locked or active_dice <= 0
	if dice_edit_summary_label == null:
		return
	if edit_locked:
		dice_edit_summary_label.text = "投掷或退场动画中不能改骰"
	elif selected_indices.is_empty():
		dice_edit_summary_label.text = "未选择骰子；可使用全部替换"
	elif selected_indices.size() == 1:
		dice_edit_summary_label.text = "将替换骰子%d" % [int(selected_indices[0]) + 1]
	else:
		dice_edit_summary_label.text = "将替换 %d 颗所选骰子" % [selected_indices.size()]


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


func _all_dice_exited(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary) or not bool(row.get("exited", false)):
			return false
	return true


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


func _make_projected_ui_check(text: String, node_name: String, pressed: bool) -> CheckBox:
	var check := CheckBox.new()
	check.name = node_name
	check.text = text
	check.button_pressed = pressed
	check.custom_minimum_size = Vector2(0, 26)
	check.focus_mode = Control.FOCUS_NONE
	check.add_theme_font_size_override("font_size", 14)
	check.add_theme_color_override("font_color", Color(0.90, 0.96, 0.92, 1.0))
	check.add_theme_color_override("font_pressed_color", Color(1.00, 0.94, 0.58, 1.0))
	check.add_theme_color_override("font_hover_color", Color(0.98, 1.00, 0.94, 1.0))
	return check


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
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.030, 0.052, 0.105, 0.96), Color(0.72, 0.46, 0.24, 0.88), 2, 4))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.055, 0.084, 0.160, 0.98), Color(0.92, 0.70, 0.36, 0.98), 2, 4))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.16, 0.060, 0.075, 0.98), Color(1.00, 0.66, 0.38, 0.98), 2, 4))
	button.add_theme_color_override("font_color", Color(0.98, 0.94, 0.84))
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
