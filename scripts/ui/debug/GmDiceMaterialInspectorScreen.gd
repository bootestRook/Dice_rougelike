extends Control
class_name GmDiceMaterialInspectorScreen


const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const GmDiceMaterialResolver = preload("res://scripts/ui/debug/gm_dice_port/GmDiceMaterialResolver.gd")
const GmDiceMaterialPreviewViewport = preload("res://scripts/ui/debug/GmDiceMaterialPreviewViewport.gd")


signal back_requested


var back_callback: Callable
var material_rows: Array[Dictionary] = []
var cabinet_grid: GridContainer = null
var popup_layer: Control = null
var inspector_popup: PanelContainer = null
var inspector_preview: GmDiceMaterialPreviewViewport = null
var popup_drag_active := false
var popup_drag_offset := Vector2.ZERO
var light_sliders := {}


func setup(return_callback: Callable = Callable()) -> void:
	back_callback = return_callback


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	name = "GmDiceMaterialInspectorRoot"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_clear_children()
	material_rows = GmDiceMaterialResolver.get_material_rows()
	_build_background()
	_build_layout()
	_build_popup_layer()


func automation_get_snapshot() -> Dictionary:
	var cards: Array[Dictionary] = []
	for row in material_rows:
		var material_id := str(row.get("id_text", row.get("id", "")))
		cards.append({
			"id": material_id,
			"name": str(row.get("name", "")),
			"resource_path": str(row.get("resource_path", "")),
			"has_resource": bool(row.get("has_resource", false)),
			"programmatic": bool(row.get("programmatic", false)),
			"card_exists": _find_node_by_name(self, "MaterialCard_%s" % material_id) != null,
		})
	return {
		"view": "gm_dice_material_inspector",
		"material_count": cards.size(),
		"materials": cards,
		"popup_open": inspector_popup != null and is_instance_valid(inspector_popup),
		"popup": _popup_snapshot(),
	}


func automation_open_material(material_id_text: String) -> Dictionary:
	var material_id := GmDiceDefinition.normalize_material_id(StringName(material_id_text))
	for row in material_rows:
		if GmDiceDefinition.normalize_material_id(StringName(str(row.get("id", "")))) == material_id:
			_open_inspector(row)
			return {"success": true, "snapshot": automation_get_snapshot()}
	return {"success": false, "reason": "未找到材质", "snapshot": automation_get_snapshot()}


func automation_close_popup() -> void:
	_close_inspector_popup()


func automation_apply_light_preset(preset_id: StringName) -> void:
	if inspector_preview != null:
		var config := inspector_preview.apply_lighting_preset(preset_id)
		_sync_light_sliders(config)


func _build_background() -> void:
	var background := ColorRect.new()
	background.name = "MaterialInspectorBackdrop"
	background.color = Color(0.025, 0.036, 0.078, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)


func _build_layout() -> void:
	var root_margin := MarginContainer.new()
	root_margin.name = "MaterialInspectorMargin"
	root_margin.add_theme_constant_override("margin_left", 34)
	root_margin.add_theme_constant_override("margin_top", 28)
	root_margin.add_theme_constant_override("margin_right", 34)
	root_margin.add_theme_constant_override("margin_bottom", 30)
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_margin)

	var layout := VBoxContainer.new()
	layout.name = "MaterialInspectorLayout"
	layout.add_theme_constant_override("separation", 20)
	root_margin.add_child(layout)

	var header := HBoxContainer.new()
	header.name = "MaterialInspectorHeader"
	header.add_theme_constant_override("separation", 14)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.name = "MaterialInspectorTitleBox"
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := _make_label("骰子材质检查", 34, Color(1.00, 0.95, 0.78, 1.0))
	title.name = "MaterialInspectorTitle"
	title_box.add_child(title)

	var subtitle := _make_label("GM 材质橱柜", 17, Color(0.72, 0.84, 0.96, 1.0))
	subtitle.name = "MaterialInspectorSubtitle"
	title_box.add_child(subtitle)

	var back_button := _make_button("返回主菜单", "MaterialInspectorBackButton", Vector2(150, 46), 19)
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)

	var scroll := ScrollContainer.new()
	scroll.name = "MaterialCabinetScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	cabinet_grid = GridContainer.new()
	cabinet_grid.name = "MaterialCabinetGrid"
	cabinet_grid.columns = 4
	cabinet_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabinet_grid.add_theme_constant_override("h_separation", 16)
	cabinet_grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(cabinet_grid)

	for row in material_rows:
		_add_material_card(row)


func _build_popup_layer() -> void:
	popup_layer = Control.new()
	popup_layer.name = "MaterialInspectorPopupLayer"
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_layer.z_index = 80
	popup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(popup_layer)


func _add_material_card(row: Dictionary) -> void:
	if cabinet_grid == null:
		return
	var material_id := GmDiceDefinition.normalize_material_id(StringName(str(row.get("id", ""))))
	var material_id_text := str(material_id)
	var card := PanelContainer.new()
	card.name = "MaterialCard_%s" % material_id_text
	card.custom_minimum_size = Vector2(250, 250)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.045, 0.065, 0.120, 0.96), Color(0.30, 0.50, 0.70, 0.78), 2, 6))
	cabinet_grid.add_child(card)

	var margin := _make_margin(12, 12, 12, 12)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "MaterialCardLayout"
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var preview := GmDiceMaterialPreviewViewport.new()
	preview.name = "MaterialPreview_%s" % material_id_text
	preview.custom_minimum_size = Vector2(220, 150)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.preview_clicked.connect(func(clicked_id: StringName) -> void:
		_open_inspector(_row_for_material(clicked_id))
	)
	layout.add_child(preview)
	preview.build(material_id, false)

	var name_label := _make_label(str(row.get("name", "")), 19, Color(0.96, 0.98, 1.0, 1.0))
	name_label.name = "MaterialNameLabel_%s" % material_id_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(name_label)

	var type_label_text := "资源材质" if bool(row.get("has_resource", false)) else "程序材质"
	var type_label := _make_label(type_label_text, 13, Color(0.66, 0.78, 0.88, 1.0))
	type_label.name = "MaterialTypeLabel_%s" % material_id_text
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(type_label)

	var open_button := _make_button("查看", "OpenMaterialInspectorButton_%s" % material_id_text, Vector2(96, 34), 15)
	open_button.pressed.connect(func() -> void:
		_open_inspector(row)
	)
	layout.add_child(open_button)


func _open_inspector(row: Dictionary) -> void:
	if row.is_empty():
		return
	_close_inspector_popup()
	var material_id := GmDiceDefinition.normalize_material_id(StringName(str(row.get("id", ""))))
	var material_name := str(row.get("name", GmDiceDefinition.material_name(material_id)))

	inspector_popup = PanelContainer.new()
	inspector_popup.name = "DiceMaterialInspectorPopup"
	inspector_popup.custom_minimum_size = Vector2(860, 590)
	inspector_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	inspector_popup.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.048, 0.092, 0.98), Color(0.86, 0.78, 0.52, 0.88), 3, 7))
	inspector_popup.position = Vector2(260, 120)
	popup_layer.add_child(inspector_popup)

	var margin := _make_margin(16, 14, 16, 16)
	inspector_popup.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "InspectorPopupLayout"
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var title_bar := HBoxContainer.new()
	title_bar.name = "InspectorDragHandle"
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.add_theme_constant_override("separation", 10)
	title_bar.gui_input.connect(_on_popup_drag_handle_gui_input)
	layout.add_child(title_bar)

	var title := _make_label("%s 检查" % material_name, 24, Color(1.0, 0.95, 0.78, 1.0))
	title.name = "InspectorTitleLabel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(title)

	var close_button := _make_button("关闭", "InspectorCloseButton", Vector2(86, 36), 16)
	close_button.pressed.connect(_close_inspector_popup)
	title_bar.add_child(close_button)

	var body := HBoxContainer.new()
	body.name = "InspectorPopupBody"
	body.add_theme_constant_override("separation", 16)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	inspector_preview = GmDiceMaterialPreviewViewport.new()
	inspector_preview.name = "InspectorPreviewViewport"
	inspector_preview.custom_minimum_size = Vector2(520, 430)
	inspector_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(inspector_preview)
	inspector_preview.build(material_id, true)

	var controls := _build_popup_controls()
	body.add_child(controls)


func _build_popup_controls() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "InspectorControlScroll"
	scroll.custom_minimum_size = Vector2(280, 420)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var layout := VBoxContainer.new()
	layout.name = "InspectorControlList"
	layout.add_theme_constant_override("separation", 10)
	scroll.add_child(layout)

	var reset_button := _make_button("重置视角", "ResetViewButton", Vector2(190, 36), 16)
	reset_button.pressed.connect(func() -> void:
		if inspector_preview != null:
			inspector_preview.reset_view()
	)
	layout.add_child(reset_button)

	var auto_rotate := CheckButton.new()
	auto_rotate.name = "AutoRotateCheckButton"
	auto_rotate.text = "自动旋转"
	auto_rotate.add_theme_font_size_override("font_size", 16)
	auto_rotate.toggled.connect(func(enabled: bool) -> void:
		if inspector_preview != null:
			inspector_preview.set_auto_rotate(enabled)
	)
	layout.add_child(auto_rotate)

	var show_pips := CheckButton.new()
	show_pips.name = "ShowPipsCheckButton"
	show_pips.text = "显示点数"
	show_pips.button_pressed = true
	show_pips.add_theme_font_size_override("font_size", 16)
	show_pips.toggled.connect(func(enabled: bool) -> void:
		if inspector_preview != null:
			inspector_preview.set_show_pips(enabled)
	)
	layout.add_child(show_pips)

	var preset_label := _make_label("光照预设", 16, Color(0.84, 0.92, 1.0, 1.0))
	layout.add_child(preset_label)

	var preset_row := HBoxContainer.new()
	preset_row.name = "LightPresetRow"
	preset_row.add_theme_constant_override("separation", 6)
	layout.add_child(preset_row)
	preset_row.add_child(_make_preset_button("明亮", "LightPresetBrightButton", &"bright"))
	preset_row.add_child(_make_preset_button("中性", "LightPresetNeutralButton", &"neutral"))
	preset_row.add_child(_make_preset_button("暗场", "LightPresetDarkButton", &"dark"))

	light_sliders.clear()
	_add_light_slider(layout, "主光强度", "KeyLightEnergySlider", "key_energy", 0.0, 3.0, 1.35)
	_add_light_slider(layout, "主光方向", "KeyLightYawSlider", "key_yaw", -180.0, 180.0, 45.0)
	_add_light_slider(layout, "环境光", "AmbientLightEnergySlider", "ambient_energy", 0.0, 1.4, 0.40)
	_add_light_slider(layout, "补光强度", "FillLightEnergySlider", "fill_energy", 0.0, 2.4, 0.62)
	return scroll


func _make_preset_button(text: String, node_name: String, preset_id: StringName) -> Button:
	var button := _make_button(text, node_name, Vector2(74, 34), 14)
	button.pressed.connect(func() -> void:
		automation_apply_light_preset(preset_id)
	)
	return button


func _add_light_slider(parent: Control, label_text: String, slider_name: String, key: String, min_value: float, max_value: float, default_value: float) -> void:
	var label := _make_label(label_text, 15, Color(0.78, 0.88, 0.96, 1.0))
	parent.add_child(label)
	var slider := HSlider.new()
	slider.name = slider_name
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.01
	slider.value = default_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	light_sliders[key] = slider
	slider.value_changed.connect(func(_value: float) -> void:
		_apply_light_slider_values()
	)
	parent.add_child(slider)


func _apply_light_slider_values() -> void:
	if inspector_preview == null:
		return
	inspector_preview.apply_lighting({
		"key_energy": _slider_value("key_energy", 1.35),
		"key_yaw": _slider_value("key_yaw", 45.0),
		"ambient_energy": _slider_value("ambient_energy", 0.40),
		"fill_energy": _slider_value("fill_energy", 0.62),
	})


func _sync_light_sliders(config: Dictionary) -> void:
	for key in light_sliders.keys():
		var slider := light_sliders[key] as HSlider
		if slider == null:
			continue
		var value := float(config.get(key, slider.value))
		slider.set_value_no_signal(value)


func _slider_value(key: String, fallback: float) -> float:
	var slider := light_sliders.get(key) as HSlider
	return float(slider.value) if slider != null else fallback


func _close_inspector_popup() -> void:
	if inspector_popup != null and is_instance_valid(inspector_popup):
		inspector_popup.queue_free()
	inspector_popup = null
	inspector_preview = null
	popup_drag_active = false


func _on_popup_drag_handle_gui_input(event: InputEvent) -> void:
	if inspector_popup == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		popup_drag_active = mouse_event.pressed
		if popup_drag_active:
			popup_drag_offset = mouse_event.global_position - inspector_popup.global_position
			inspector_popup.move_to_front()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and popup_drag_active:
		var motion := event as InputEventMouseMotion
		inspector_popup.global_position = motion.global_position - popup_drag_offset
		get_viewport().set_input_as_handled()


func _on_back_pressed() -> void:
	back_requested.emit()
	if back_callback.is_valid():
		back_callback.call()


func _popup_snapshot() -> Dictionary:
	if inspector_popup == null or not is_instance_valid(inspector_popup):
		return {}
	var title_label := _find_node_by_name(inspector_popup, "InspectorTitleLabel") as Label
	return {
		"title": title_label.text if title_label != null else "",
		"position": inspector_popup.global_position,
		"preview": inspector_preview.get_snapshot() if inspector_preview != null else {},
		"has_close_button": _find_node_by_name(inspector_popup, "InspectorCloseButton") is Button,
		"has_reset_button": _find_node_by_name(inspector_popup, "ResetViewButton") is Button,
		"has_auto_rotate": _find_node_by_name(inspector_popup, "AutoRotateCheckButton") is CheckButton,
		"has_show_pips": _find_node_by_name(inspector_popup, "ShowPipsCheckButton") is CheckButton,
		"has_key_light_slider": _find_node_by_name(inspector_popup, "KeyLightEnergySlider") is HSlider,
		"has_key_direction_slider": _find_node_by_name(inspector_popup, "KeyLightYawSlider") is HSlider,
		"has_ambient_slider": _find_node_by_name(inspector_popup, "AmbientLightEnergySlider") is HSlider,
		"has_fill_slider": _find_node_by_name(inspector_popup, "FillLightEnergySlider") is HSlider,
	}


func _row_for_material(material_id: StringName) -> Dictionary:
	var normalized_id := GmDiceDefinition.normalize_material_id(material_id)
	for row in material_rows:
		if GmDiceDefinition.normalize_material_id(StringName(str(row.get("id", "")))) == normalized_id:
			return row
	return {}


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _make_button(text: String, node_name: String, minimum_size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(1.0, 0.98, 0.90, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.90, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.98, 0.90, 1.0))
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.16, 0.30, 0.46, 0.96), Color(0.70, 0.86, 1.0, 0.72), 2, 5))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.20, 0.38, 0.56, 0.98), Color(0.82, 0.94, 1.0, 0.90), 2, 5))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.10, 0.22, 0.34, 0.98), Color(0.64, 0.78, 0.95, 0.82), 2, 5))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _make_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
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
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null
