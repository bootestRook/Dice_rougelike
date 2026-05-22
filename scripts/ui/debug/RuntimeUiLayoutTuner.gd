extends Control
class_name RuntimeUiLayoutTuner


const DEFAULT_EXPORT_PATH := "res://tests_or_debug/ui_layout_tuning/latest_ui_layout_tuning.json"
const MIN_SELECTABLE_SIZE := Vector2(6.0, 6.0)
const EDIT_MODE_MOVE := &"move"
const EDIT_MODE_SCALE := &"scale"
const EDIT_MODE_ROTATE := &"rotate"


var target_root: Control = null
var export_path := DEFAULT_EXPORT_PATH
var selected_control: Control = null
var selectable_paths: Array[NodePath] = []
var original_layout_by_path: Dictionary = {}
var edited_layout_by_path: Dictionary = {}
var forced_layout_by_path: Dictionary = {}
var syncing_fields := false
var pick_mode := false
var edit_mode: StringName = EDIT_MODE_MOVE
var dragging := false
var drag_start_mouse := Vector2.ZERO
var drag_start_rect := Rect2()
var drag_start_rotation_degrees := 0.0

var panel: PanelContainer = null
var title_label: Label = null
var mode_label: Label = null
var control_picker: OptionButton = null
var path_label: Label = null
var status_label: Label = null
var pick_button: PanelContainer = null
var outline: Panel = null
var field_rows: Dictionary = {}
var mode_buttons: Dictionary = {}


func setup(new_target_root: Control, new_export_path: String = DEFAULT_EXPORT_PATH) -> void:
	target_root = new_target_root
	export_path = new_export_path
	if is_node_ready():
		_refresh_control_list()


func _ready() -> void:
	name = "RuntimeUiLayoutTuner"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 2000
	_build_view()
	visible = false
	set_process_input(true)


func _process(_delta: float) -> void:
	_reapply_forced_layouts()
	_update_outline()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		_handle_tuner_key(event as InputEventKey)
		return
	if pick_mode:
		_handle_pick_input(event)
		return
	_handle_edit_drag_input(event)


func _handle_pick_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _panel_has_point(mouse_event.position):
		return
	var picked := _pick_control_at(mouse_event.position)
	if picked != null:
		select_control(picked)
		pick_mode = false
		_refresh_pick_button()
		get_viewport().set_input_as_handled()


func _handle_edit_drag_input(event: InputEvent) -> void:
	if selected_control == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			if _panel_has_point(mouse_event.position):
				return
			_start_drag(mouse_event.position)
			get_viewport().set_input_as_handled()
		elif dragging:
			dragging = false
			_record_current_layout(selected_control)
			_sync_fields_from_selection()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and dragging:
		var motion_event := event as InputEventMouseMotion
		_apply_drag_transform(motion_event.position)
		get_viewport().set_input_as_handled()


func open_tuner() -> void:
	visible = true
	pick_mode = false
	_refresh_control_list()
	_refresh_pick_button()
	_sync_fields_from_selection()
	_update_status("P：点选控件；S：保存 JSON；Esc：退出点选或隐藏。")


func close_tuner() -> void:
	visible = false
	pick_mode = false
	_refresh_pick_button()


func toggle_tuner() -> void:
	if visible:
		close_tuner()
	else:
		open_tuner()


func is_tuner_visible() -> bool:
	return visible


func select_control(control: Control) -> void:
	if control == null or control == self or is_ancestor_of(control):
		return
	selected_control = control
	_remember_original_layout(control)
	_refresh_picker_selection()
	_sync_fields_from_selection()
	_update_path_label()
	if control.name == "MapStagePerspective3DView":
		_update_status("当前选中的是 3D 视口，会连同中间骰子一起移动；只调地面请点“选地面背景”。")
	elif control.name == "MapStageTabletopBackgroundTexture":
		_update_status("已选中地面背景图，可以单独调整它。")
	else:
		_update_status("已选择：%s" % [control.name])


func automation_select_control_by_name(control_name: String) -> bool:
	_refresh_control_list()
	return _select_control_by_name(control_name)


func automation_select_tabletop_background() -> bool:
	_refresh_control_list()
	return _select_control_by_name("MapStageTabletopBackgroundTexture")


func _select_control_by_name(control_name: String) -> bool:
	var candidates := _visible_selectable_controls()
	for control in candidates:
		if control.name == control_name:
			select_control(control)
			return true
	return false


func automation_set_selected_global_rect(rect: Rect2, new_z_index: int = 0, change_z_index: bool = false) -> bool:
	if selected_control == null:
		return false
	var z_index := new_z_index if change_z_index else _selected_preview_z_index()
	_apply_global_rect_to_selected(rect, z_index, _selected_preview_rotation_degrees())
	_record_current_layout(selected_control)
	_sync_fields_from_selection()
	return true


func automation_set_selected_rotation_degrees(rotation_degrees: float) -> bool:
	if selected_control == null:
		return false
	_store_forced_layout(selected_control, _selected_preview_rect(), _selected_preview_z_index(), rotation_degrees)
	_apply_target_layout_to_control(selected_control, _selected_preview_rect(), _selected_preview_z_index(), rotation_degrees)
	_record_current_layout(selected_control)
	_sync_fields_from_selection()
	return true


func automation_set_edit_mode(new_mode: StringName) -> bool:
	return _set_edit_mode(new_mode)


func automation_drag_selected(delta: Vector2) -> bool:
	if selected_control == null:
		return false
	var start_position := _selected_preview_rect().get_center()
	if edit_mode == EDIT_MODE_ROTATE:
		start_position += Vector2(maxf(12.0, _selected_preview_rect().size.x * 0.5), 0.0)
	_start_drag(start_position)
	_apply_drag_transform(drag_start_mouse + delta)
	dragging = false
	_record_current_layout(selected_control)
	_sync_fields_from_selection()
	return true


func automation_save_snapshot(new_export_path: String = "") -> String:
	if new_export_path != "":
		export_path = new_export_path
	return save_snapshot()


func automation_get_snapshot() -> Dictionary:
	return {
		"visible": visible,
		"pick_mode": pick_mode,
		"edit_mode": str(edit_mode),
		"selected_path": _selected_relative_path(),
		"selected_name": selected_control.name if selected_control != null else "",
		"selected_preview_rect": _rect_to_dict(_selected_preview_rect()),
		"selected_preview_rotation_degrees": _selected_preview_rotation_degrees(),
		"selected_preview_z_index": _selected_preview_z_index(),
		"candidate_count": selectable_paths.size(),
		"edited_count": edited_layout_by_path.size(),
		"export_path": export_path,
		"export_absolute_path": ProjectSettings.globalize_path(export_path),
	}


func save_snapshot() -> String:
	var payload := _build_export_payload()
	var directory := export_path.get_base_dir()
	var absolute_directory := ProjectSettings.globalize_path(directory)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if dir_error != OK:
		_update_status("保存失败：无法创建目录 %s" % [absolute_directory])
		return ""

	var file := FileAccess.open(export_path, FileAccess.WRITE)
	if file == null:
		_update_status("保存失败：%s" % [error_string(FileAccess.get_open_error())])
		return ""

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	var absolute_path := ProjectSettings.globalize_path(export_path)
	DisplayServer.clipboard_set(absolute_path)
	_update_status("已保存并复制路径：%s" % [absolute_path])
	return absolute_path


func reset_selected_control() -> void:
	if selected_control == null:
		return
	var path := _selected_relative_path()
	if not original_layout_by_path.has(path):
		return
	forced_layout_by_path.erase(path)
	_apply_layout_payload(selected_control, original_layout_by_path[path])
	edited_layout_by_path.erase(path)
	_sync_fields_from_selection()
	_update_status("已重置当前控件。")


func _build_view() -> void:
	outline = Panel.new()
	outline.name = "RuntimeUiLayoutSelectionOutline"
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outline.z_index = 2001
	outline.add_theme_stylebox_override("panel", _make_outline_style())
	add_child(outline)

	panel = PanelContainer.new()
	panel.name = "RuntimeUiLayoutTunerPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = 2002
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -442.0
	panel.offset_top = 18.0
	panel.offset_right = -18.0
	panel.offset_bottom = 720.0
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.name = "RuntimeUiLayoutTunerRoot"
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	title_label = Label.new()
	title_label.name = "RuntimeUiLayoutTunerTitle"
	title_label.text = "UI 调节器"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.72, 1.0))
	root.add_child(title_label)

	var hint_label := Label.new()
	hint_label.name = "RuntimeUiLayoutTunerHint"
	hint_label.text = "点选组件后，用 W / R / E 切换移动、缩放、旋转。"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.82, 0.92, 0.86, 1.0))
	root.add_child(hint_label)

	control_picker = OptionButton.new()
	control_picker.name = "RuntimeUiControlPicker"
	control_picker.focus_mode = Control.FOCUS_NONE
	control_picker.fit_to_longest_item = false
	control_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	control_picker.add_theme_font_size_override("font_size", 13)
	control_picker.add_theme_color_override("font_color", Color(0.94, 0.95, 0.89, 1.0))
	control_picker.item_selected.connect(_on_picker_item_selected)
	root.add_child(control_picker)

	path_label = Label.new()
	path_label.name = "RuntimeUiSelectedPath"
	path_label.text = "先点“点选控件”，再点画面上的 UI；或用顶部下拉框选择。"
	path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	path_label.add_theme_font_size_override("font_size", 11)
	path_label.add_theme_color_override("font_color", Color(0.82, 0.92, 0.86, 1.0))
	root.add_child(path_label)

	mode_label = Label.new()
	mode_label.name = "RuntimeUiEditModeLabel"
	mode_label.text = _edit_mode_text()
	mode_label.add_theme_font_size_override("font_size", 13)
	mode_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 1.0))
	root.add_child(mode_label)

	var mode_row := HBoxContainer.new()
	mode_row.name = "RuntimeUiEditModeButtons"
	mode_row.add_theme_constant_override("separation", 8)
	root.add_child(mode_row)

	var move_button := _make_tool_button("W 移动", func() -> void:
		_set_edit_mode(EDIT_MODE_MOVE)
	)
	move_button.name = "RuntimeUiMoveModeButton"
	mode_row.add_child(move_button)
	mode_buttons[EDIT_MODE_MOVE] = move_button

	var scale_button := _make_tool_button("R 缩放", func() -> void:
		_set_edit_mode(EDIT_MODE_SCALE)
	)
	scale_button.name = "RuntimeUiScaleModeButton"
	mode_row.add_child(scale_button)
	mode_buttons[EDIT_MODE_SCALE] = scale_button

	var rotate_button := _make_tool_button("E 旋转", func() -> void:
		_set_edit_mode(EDIT_MODE_ROTATE)
	)
	rotate_button.name = "RuntimeUiRotateModeButton"
	mode_row.add_child(rotate_button)
	mode_buttons[EDIT_MODE_ROTATE] = rotate_button

	_create_field_row(root, "屏幕 X", "x", -4096.0, 4096.0, 1.0)
	_create_field_row(root, "屏幕 Y", "y", -4096.0, 4096.0, 1.0)
	_create_field_row(root, "宽", "w", 1.0, 8192.0, 1.0)
	_create_field_row(root, "高", "h", 1.0, 8192.0, 1.0)
	_create_field_row(root, "旋转", "rot", -360.0, 360.0, 0.5)
	_create_field_row(root, "层级", "z", -4096.0, 4096.0, 1.0)

	var action_grid := GridContainer.new()
	action_grid.name = "RuntimeUiTunerActions"
	action_grid.columns = 2
	action_grid.add_theme_constant_override("h_separation", 8)
	action_grid.add_theme_constant_override("v_separation", 8)
	root.add_child(action_grid)

	pick_button = _make_tool_button("点选控件", func() -> void:
		_toggle_pick_mode()
	)
	pick_button.name = "RuntimeUiPickButton"
	action_grid.add_child(pick_button)

	var background_button := _make_tool_button("选地面背景", func() -> void:
		if not _select_control_by_name("MapStageTabletopBackgroundTexture"):
			_update_status("当前画面没有找到地面背景图。")
	)
	background_button.name = "RuntimeUiMapBackgroundButton"
	action_grid.add_child(background_button)

	var refresh_button := _make_tool_button("刷新列表", func() -> void:
		_refresh_control_list()
	)
	refresh_button.name = "RuntimeUiRefreshButton"
	action_grid.add_child(refresh_button)

	var save_button := _make_tool_button("保存 JSON", func() -> void:
		save_snapshot()
	)
	save_button.name = "RuntimeUiSaveButton"
	action_grid.add_child(save_button)

	var reset_button := _make_tool_button("重置选中", func() -> void:
		reset_selected_control()
	)
	reset_button.name = "RuntimeUiResetButton"
	action_grid.add_child(reset_button)

	var close_button := _make_tool_button("隐藏面板", func() -> void:
		close_tuner()
	)
	close_button.name = "RuntimeUiCloseButton"
	action_grid.add_child(close_button)

	var copy_path_button := _make_tool_button("复制路径", func() -> void:
		DisplayServer.clipboard_set(ProjectSettings.globalize_path(export_path))
		_update_status("已复制导出路径。")
	)
	copy_path_button.name = "RuntimeUiCopyExportPathButton"
	action_grid.add_child(copy_path_button)

	status_label = Label.new()
	status_label.name = "RuntimeUiTunerStatus"
	status_label.text = "快捷键：P 点选，S 保存，Esc 隐藏。"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 1.0))
	root.add_child(status_label)
	_refresh_mode_button_styles()


func _create_field_row(parent: VBoxContainer, label_text: String, key: String, min_value: float, max_value: float, step: float) -> void:
	var row := HBoxContainer.new()
	row.name = "RuntimeUiField_%s" % [key]
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(62.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.94, 0.91, 0.78, 1.0))
	row.add_child(label)

	var spin := SpinBox.new()
	spin.name = "Value"
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(156.0, 0.0)
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.focus_mode = Control.FOCUS_CLICK
	spin.value_changed.connect(func(value: float) -> void:
		_set_field_value(key, value)
	)
	row.add_child(spin)

	field_rows[key] = {
		"spin": spin,
	}


func _make_tool_button(text: String, callback: Callable) -> PanelContainer:
	var button := PanelContainer.new()
	button.custom_minimum_size = Vector2(0.0, 34.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_stylebox_override("panel", _make_tool_button_style(false, false))

	var label := Label.new()
	label.name = "VisibleButtonLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	button.add_child(label)

	button.mouse_entered.connect(func() -> void:
		button.add_theme_stylebox_override("panel", _make_tool_button_style(true, _is_mode_button_active(button)))
	)
	button.mouse_exited.connect(func() -> void:
		button.add_theme_stylebox_override("panel", _make_tool_button_style(false, _is_mode_button_active(button)))
	)
	button.gui_input.connect(func(event: InputEvent) -> void:
		if not event is InputEventMouseButton:
			return
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			return
		callback.call()
		button.add_theme_stylebox_override("panel", _make_tool_button_style(false, _is_mode_button_active(button)))
	)
	return button


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.055, 0.045, 0.92)
	style.border_color = Color(0.74, 0.62, 0.33, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _make_tool_button_style(hovered: bool, active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if active:
		style.bg_color = Color(0.30, 0.24, 0.10, 0.98)
		style.border_color = Color(1.0, 0.82, 0.28, 0.95)
	elif hovered:
		style.bg_color = Color(0.20, 0.34, 0.28, 0.98)
		style.border_color = Color(0.95, 0.82, 0.48, 0.75)
	else:
		style.bg_color = Color(0.12, 0.23, 0.19, 0.96)
		style.border_color = Color(0.95, 0.82, 0.48, 0.48)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _make_outline_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.45, 1.0, 0.36, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(2)
	return style


func _toggle_pick_mode() -> void:
	pick_mode = not pick_mode
	_refresh_pick_button()
	_update_status("点击画面上的控件进行选择。" if pick_mode else "已退出点选模式。")


func _set_edit_mode(new_mode: StringName) -> bool:
	if not [EDIT_MODE_MOVE, EDIT_MODE_SCALE, EDIT_MODE_ROTATE].has(new_mode):
		return false
	edit_mode = new_mode
	if mode_label != null:
		mode_label.text = _edit_mode_text()
	_refresh_mode_button_styles()
	_update_status(_edit_mode_help_text())
	return true


func _edit_mode_text() -> String:
	match edit_mode:
		EDIT_MODE_SCALE:
			return "当前模式：R 缩放"
		EDIT_MODE_ROTATE:
			return "当前模式：E 旋转"
		_:
			return "当前模式：W 移动"


func _edit_mode_help_text() -> String:
	match edit_mode:
		EDIT_MODE_SCALE:
			return "缩放模式：按住左键拖动，向右/下放大，向左/上缩小。"
		EDIT_MODE_ROTATE:
			return "旋转模式：按住左键绕选中控件中心拖动。"
		_:
			return "移动模式：按住左键拖动选中控件。"


func _handle_tuner_key(key_event: InputEventKey) -> void:
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_W:
			_set_edit_mode(EDIT_MODE_MOVE)
			get_viewport().set_input_as_handled()
		KEY_R:
			_set_edit_mode(EDIT_MODE_SCALE)
			get_viewport().set_input_as_handled()
		KEY_E:
			_set_edit_mode(EDIT_MODE_ROTATE)
			get_viewport().set_input_as_handled()
		KEY_P:
			_toggle_pick_mode()
			get_viewport().set_input_as_handled()
		KEY_S:
			save_snapshot()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if pick_mode:
				pick_mode = false
				_refresh_pick_button()
				_update_status("已退出点选模式。")
			else:
				close_tuner()
			get_viewport().set_input_as_handled()


func _refresh_pick_button() -> void:
	if pick_button == null:
		return
	_set_tool_button_text(pick_button, "取消点选" if pick_mode else "点选控件")


func _set_tool_button_text(button: Control, text: String) -> void:
	if button == null:
		return
	var visible_label := button.get_node_or_null("VisibleButtonLabel") as Label
	if visible_label != null:
		visible_label.text = text


func _refresh_mode_button_styles() -> void:
	for mode in mode_buttons.keys():
		var button := mode_buttons[mode] as PanelContainer
		if button != null:
			button.add_theme_stylebox_override("panel", _make_tool_button_style(false, mode == edit_mode))


func _is_mode_button_active(button: Control) -> bool:
	for mode in mode_buttons.keys():
		if mode_buttons[mode] == button:
			return mode == edit_mode
	return false


func _on_picker_item_selected(index: int) -> void:
	if index < 0 or index >= selectable_paths.size() or target_root == null:
		return
	var control := target_root.get_node_or_null(selectable_paths[index]) as Control
	if control != null:
		select_control(control)


func _set_field_value(key: String, value: float) -> void:
	if syncing_fields or selected_control == null:
		return
	var rect := _selected_preview_rect()
	var z_value := _selected_preview_z_index()
	var rotation_value := _selected_preview_rotation_degrees()
	match key:
		"x":
			rect.position.x = value
		"y":
			rect.position.y = value
		"w":
			rect.size.x = maxf(1.0, value)
		"h":
			rect.size.y = maxf(1.0, value)
		"rot":
			rotation_value = value
		"z":
			z_value = int(value)
	_apply_global_rect_to_selected(rect, z_value, rotation_value)
	_record_current_layout(selected_control)
	_sync_fields_from_selection()


func _start_drag(mouse_position: Vector2) -> void:
	if selected_control == null:
		return
	dragging = true
	drag_start_mouse = mouse_position
	drag_start_rect = _selected_preview_rect()
	drag_start_rotation_degrees = _selected_preview_rotation_degrees()
	_remember_original_layout(selected_control)


func _apply_drag_transform(mouse_position: Vector2) -> void:
	if selected_control == null:
		return
	var delta := mouse_position - drag_start_mouse
	match edit_mode:
		EDIT_MODE_SCALE:
			var scaled_rect := drag_start_rect
			scaled_rect.size = Vector2(
				maxf(1.0, drag_start_rect.size.x + delta.x),
				maxf(1.0, drag_start_rect.size.y + delta.y)
			)
			_apply_global_rect_to_selected(scaled_rect, _selected_preview_z_index(), _selected_preview_rotation_degrees())
		EDIT_MODE_ROTATE:
			var center := drag_start_rect.position + drag_start_rect.size * 0.5
			var start_vector := drag_start_mouse - center
			var current_vector := mouse_position - center
			if start_vector.length() > 0.001 and current_vector.length() > 0.001:
				var rotation := drag_start_rotation_degrees + rad_to_deg(current_vector.angle() - start_vector.angle())
				_store_forced_layout(selected_control, drag_start_rect, _selected_preview_z_index(), rotation)
				_record_current_layout(selected_control)
		_:
			var moved_rect := drag_start_rect
			moved_rect.position += delta
			_apply_global_rect_to_selected(moved_rect, _selected_preview_z_index(), _selected_preview_rotation_degrees())
	_sync_fields_from_selection()


func _apply_global_rect_to_selected(rect: Rect2, z_index: int, rotation_degrees: float) -> void:
	if selected_control == null:
		return
	_remember_original_layout(selected_control)
	_store_forced_layout(selected_control, rect, z_index, rotation_degrees)
	_apply_target_layout_to_control(selected_control, rect, z_index, rotation_degrees)
	_record_current_layout(selected_control)


func _store_forced_layout(control: Control, rect: Rect2, z_index: int, rotation_degrees: float) -> void:
	if control == null or target_root == null:
		return
	var path := str(target_root.get_path_to(control))
	forced_layout_by_path[path] = {
		"rect": _rect_to_dict(rect),
		"z_index": z_index,
		"rotation_degrees": rotation_degrees,
	}


func _apply_target_layout_to_control(control: Control, rect: Rect2, z_index: int, rotation_degrees: float) -> void:
	if control == null:
		return
	var parent_canvas := control.get_parent() as CanvasItem
	if parent_canvas == null:
		return
	var parent_transform := parent_canvas.get_global_transform_with_canvas()
	var local_position := parent_transform.affine_inverse() * rect.position
	var scale_x := maxf(parent_transform.x.length(), 0.001)
	var scale_y := maxf(parent_transform.y.length(), 0.001)
	var local_size := Vector2(rect.size.x / scale_x, rect.size.y / scale_y)

	control.set_as_top_level(false)
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = local_position.x
	control.offset_top = local_position.y
	control.offset_right = local_position.x + local_size.x
	control.offset_bottom = local_position.y + local_size.y
	control.custom_minimum_size = local_size
	control.pivot_offset = local_size * 0.5
	control.rotation_degrees = rotation_degrees
	control.z_index = z_index


func _sync_fields_from_selection() -> void:
	if field_rows.is_empty():
		return
	syncing_fields = true
	var rect := _selected_preview_rect()
	var values := {
		"x": rect.position.x,
		"y": rect.position.y,
		"w": rect.size.x,
		"h": rect.size.y,
		"rot": _selected_preview_rotation_degrees(),
		"z": _selected_preview_z_index(),
	}
	for key in field_rows.keys():
		var row: Dictionary = field_rows[key]
		var spin := row.get("spin") as SpinBox
		if spin != null:
			spin.value = float(values.get(key, 0.0))
	syncing_fields = false
	_update_outline()
	_update_path_label()


func _refresh_control_list() -> void:
	if control_picker == null or target_root == null:
		return
	var previous_path := _selected_relative_path()
	selectable_paths.clear()
	control_picker.clear()
	var controls := _visible_selectable_controls()
	for control in controls:
		var path := target_root.get_path_to(control)
		selectable_paths.append(path)
		control_picker.add_item(_display_name_for_control(control))
	if previous_path != "":
		for index in range(selectable_paths.size()):
			if str(selectable_paths[index]) == previous_path:
				control_picker.select(index)
				return
	if selected_control == null and not selectable_paths.is_empty():
		var first := target_root.get_node_or_null(selectable_paths[0]) as Control
		if first != null:
			select_control(first)


func _refresh_picker_selection() -> void:
	if control_picker == null or selected_control == null or target_root == null:
		return
	var selected_path := str(target_root.get_path_to(selected_control))
	for index in range(selectable_paths.size()):
		if str(selectable_paths[index]) == selected_path:
			control_picker.select(index)
			return


func _visible_selectable_controls() -> Array[Control]:
	var result: Array[Control] = []
	if target_root == null:
		return result
	_collect_visible_controls(target_root, result)
	return result


func _display_name_for_control(control: Control) -> String:
	if control == null:
		return ""
	match String(control.name):
		"MapStagePerspective3DView":
			return "%s  |  3D 视口（含骰子）" % [control.name]
		"MapStageTabletopBackgroundTexture":
			return "%s  |  地面背景图" % [control.name]
		_:
			return "%s  |  %s" % [control.name, control.get_class()]


func _trim_middle(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	if max_chars <= 8:
		return text.left(max_chars)
	var side := int(floor(float(max_chars - 3) * 0.5))
	var right_count := max_chars - 3 - side
	return "%s...%s" % [text.left(side), text.substr(text.length() - right_count, right_count)]


func _collect_visible_controls(node: Node, result: Array[Control]) -> void:
	for child in node.get_children():
		var control := child as Control
		if control != null and _is_selectable_control(control):
			result.append(control)
		_collect_visible_controls(child, result)


func _is_selectable_control(control: Control) -> bool:
	if control == null or control == target_root or control == self or is_ancestor_of(control):
		return false
	if not control.is_visible_in_tree():
		return false
	var rect := control.get_global_rect()
	return rect.size.x >= MIN_SELECTABLE_SIZE.x and rect.size.y >= MIN_SELECTABLE_SIZE.y


func _pick_control_at(point: Vector2) -> Control:
	var controls := _visible_selectable_controls()
	var best: Control = null
	var best_area := INF
	for control in controls:
		var rect := control.get_global_rect()
		if not rect.has_point(point):
			continue
		var area := rect.size.x * rect.size.y
		if best == null or area < best_area or (is_equal_approx(area, best_area) and control.z_index >= best.z_index):
			best = control
			best_area = area
	return best


func _panel_has_point(point: Vector2) -> bool:
	return panel != null and panel.visible and panel.get_global_rect().has_point(point)


func _remember_original_layout(control: Control) -> void:
	if control == null or target_root == null:
		return
	var path := str(target_root.get_path_to(control))
	if original_layout_by_path.has(path):
		return
	original_layout_by_path[path] = _control_layout_payload(control)


func _record_current_layout(control: Control) -> void:
	if control == null or target_root == null:
		return
	var path := str(target_root.get_path_to(control))
	edited_layout_by_path[path] = {
		"original": original_layout_by_path.get(path, _control_layout_payload(control)),
		"current": _control_layout_payload(control),
	}


func _apply_layout_payload(control: Control, payload: Dictionary) -> void:
	control.set_as_top_level(bool(payload.get("top_level", false)))
	control.custom_minimum_size = _dict_to_vector(payload.get("custom_minimum_size", _vector_to_dict(control.custom_minimum_size)))
	control.rotation_degrees = float(payload.get("rotation_degrees", control.rotation_degrees))
	control.pivot_offset = _dict_to_vector(payload.get("pivot_offset", _vector_to_dict(control.pivot_offset)))
	var anchors: Dictionary = payload.get("anchors", {})
	control.anchor_left = float(anchors.get("left", control.anchor_left))
	control.anchor_top = float(anchors.get("top", control.anchor_top))
	control.anchor_right = float(anchors.get("right", control.anchor_right))
	control.anchor_bottom = float(anchors.get("bottom", control.anchor_bottom))
	var offsets: Dictionary = payload.get("offsets", {})
	control.offset_left = float(offsets.get("left", control.offset_left))
	control.offset_top = float(offsets.get("top", control.offset_top))
	control.offset_right = float(offsets.get("right", control.offset_right))
	control.offset_bottom = float(offsets.get("bottom", control.offset_bottom))
	control.z_index = int(payload.get("z_index", control.z_index))


func _control_layout_payload(control: Control) -> Dictionary:
	var path := str(target_root.get_path_to(control)) if target_root != null else str(control.get_path())
	var payload := {
		"name": control.name,
		"class": control.get_class(),
		"path": path,
		"absolute_path": str(control.get_path()),
		"parent_path": str(target_root.get_path_to(control.get_parent())) if target_root != null and control.get_parent() != null and target_root.is_ancestor_of(control.get_parent()) else "",
		"global_rect": _rect_to_dict(control.get_global_rect()),
		"local_rect": _rect_to_dict(Rect2(control.position, control.size)),
		"custom_minimum_size": _vector_to_dict(control.custom_minimum_size),
		"anchors": {
			"left": control.anchor_left,
			"top": control.anchor_top,
			"right": control.anchor_right,
			"bottom": control.anchor_bottom,
		},
		"offsets": {
			"left": control.offset_left,
			"top": control.offset_top,
			"right": control.offset_right,
			"bottom": control.offset_bottom,
		},
		"z_index": control.z_index,
		"rotation_degrees": control.rotation_degrees,
		"pivot_offset": _vector_to_dict(control.pivot_offset),
		"top_level": control.is_set_as_top_level(),
		"visible": control.visible,
		"preview_only": false,
	}
	if forced_layout_by_path.has(path):
		var forced := forced_layout_by_path[path] as Dictionary
		payload["target_global_rect"] = forced.get("rect", payload["global_rect"])
		payload["target_z_index"] = int(forced.get("z_index", control.z_index))
		payload["target_rotation_degrees"] = float(forced.get("rotation_degrees", control.rotation_degrees))
		payload["preview_only"] = true
	return payload


func _build_export_payload() -> Dictionary:
	var edited_items: Array = []
	for path in edited_layout_by_path.keys():
		edited_items.append(edited_layout_by_path[path])
	return {
		"format": "dice_roguelike_runtime_ui_layout_tuning",
		"version": 1,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"viewport_size": _vector_to_dict(get_viewport_rect().size),
		"target_root_path": str(target_root.get_path()) if target_root != null else "",
		"target_root_name": target_root.name if target_root != null else "",
		"selected_path": _selected_relative_path(),
		"edit_mode": str(edit_mode),
		"candidate_count": selectable_paths.size(),
		"edited": edited_items,
		"visible_snapshot": _visible_snapshot_payload(),
	}


func _visible_snapshot_payload() -> Array:
	var result: Array = []
	var controls := _visible_selectable_controls()
	for control in controls:
		result.append(_control_layout_payload(control))
	return result


func _rect_to_dict(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"w": rect.size.x,
		"h": rect.size.y,
	}


func _dict_to_rect(payload) -> Rect2:
	if not payload is Dictionary:
		return Rect2()
	var rect_payload := payload as Dictionary
	return Rect2(
		Vector2(float(rect_payload.get("x", 0.0)), float(rect_payload.get("y", 0.0))),
		Vector2(float(rect_payload.get("w", 0.0)), float(rect_payload.get("h", 0.0)))
	)


func _vector_to_dict(vector: Vector2) -> Dictionary:
	return {
		"x": vector.x,
		"y": vector.y,
	}


func _dict_to_vector(payload) -> Vector2:
	if not payload is Dictionary:
		return Vector2.ZERO
	var vector_payload := payload as Dictionary
	return Vector2(float(vector_payload.get("x", 0.0)), float(vector_payload.get("y", 0.0)))


func _selected_preview_rect() -> Rect2:
	if selected_control == null:
		return Rect2()
	var path := _selected_relative_path()
	if forced_layout_by_path.has(path):
		var payload := forced_layout_by_path[path] as Dictionary
		return _dict_to_rect(payload.get("rect", {}))
	return selected_control.get_global_rect()


func _selected_preview_rotation_degrees() -> float:
	if selected_control == null:
		return 0.0
	var path := _selected_relative_path()
	if forced_layout_by_path.has(path):
		var payload := forced_layout_by_path[path] as Dictionary
		return float(payload.get("rotation_degrees", selected_control.rotation_degrees))
	return selected_control.rotation_degrees


func _selected_preview_z_index() -> int:
	if selected_control == null:
		return 0
	var path := _selected_relative_path()
	if forced_layout_by_path.has(path):
		var payload := forced_layout_by_path[path] as Dictionary
		return int(payload.get("z_index", selected_control.z_index))
	return selected_control.z_index


func _reapply_forced_layouts() -> void:
	if target_root == null or forced_layout_by_path.is_empty():
		return
	for path in forced_layout_by_path.keys():
		var control := target_root.get_node_or_null(NodePath(path)) as Control
		if control == null:
			continue
		var payload := forced_layout_by_path[path] as Dictionary
		var rect := _dict_to_rect(payload.get("rect", {}))
		var z_index := int(payload.get("z_index", control.z_index))
		var rotation_degrees := float(payload.get("rotation_degrees", control.rotation_degrees))
		_apply_target_layout_to_control(control, rect, z_index, rotation_degrees)


func _selected_relative_path() -> String:
	if selected_control == null or target_root == null:
		return ""
	return str(target_root.get_path_to(selected_control))


func _update_outline() -> void:
	if outline == null:
		return
	if not visible or selected_control == null or not is_instance_valid(selected_control) or not selected_control.is_visible_in_tree():
		outline.visible = false
		return
	outline.visible = true
	var rect := _selected_preview_rect()
	outline.set_as_top_level(true)
	outline.global_position = rect.position
	outline.size = rect.size
	outline.rotation_degrees = _selected_preview_rotation_degrees()
	outline.pivot_offset = outline.size * 0.5


func _update_path_label() -> void:
	if path_label == null:
		return
	if selected_control == null:
		path_label.text = "未选择控件"
		return
	path_label.text = "选中：%s\n类型：%s\n路径：%s" % [
		selected_control.name,
		selected_control.get_class(),
		_trim_middle(_selected_relative_path(), 58),
	]


func _update_status(text: String) -> void:
	if status_label != null:
		status_label.text = text
