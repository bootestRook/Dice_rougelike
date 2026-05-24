extends Control
class_name HoverInfoOverlay


const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const DiceHoverRing = preload("res://scripts/ui/battle/components/DiceHoverRing.gd")


signal revealed(target_id: StringName)


var style_config: BattleUiStyleConfig = null
var panel_node_name := "DiceHoverFaceInfoPanel"
var base_panel_size := Vector2(340.0, 156.0)
var current_target_id: StringName = &""
var current_global_rect := Rect2()
var current_title := ""
var current_rows: Array[Dictionary] = []
var info_revealed := false
var interrupted_target_id: StringName = &""

var hover_ring: DiceHoverRing = null
var info_panel: PanelContainer = null
var margin: MarginContainer = null
var title_label: Label = null
var rows_container: VBoxContainer = null


func setup(new_style_config: BattleUiStyleConfig, new_panel_node_name: String = "", new_base_panel_size: Vector2 = Vector2.ZERO) -> void:
	style_config = new_style_config
	if new_panel_node_name != "":
		panel_node_name = new_panel_node_name
	if new_base_panel_size != Vector2.ZERO:
		base_panel_size = new_base_panel_size
	if is_node_ready():
		_ensure_nodes()
		_apply_style()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ensure_nodes()
	_apply_style()


func show_hover(target_id: StringName, global_rect: Rect2, title: String, rows: Array[Dictionary]) -> void:
	_ensure_nodes()
	if target_id == &"" or global_rect.size.x <= 0.0 or global_rect.size.y <= 0.0:
		hide_hover()
		return
	if interrupted_target_id != &"" and target_id == interrupted_target_id:
		current_target_id = target_id
		current_global_rect = global_rect
		info_revealed = false
		if hover_ring != null:
			hover_ring.stop()
		if info_panel != null:
			info_panel.visible = false
		return
	if interrupted_target_id != &"" and target_id != interrupted_target_id:
		interrupted_target_id = &""
	var is_new_target := target_id != current_target_id
	current_target_id = target_id
	current_global_rect = global_rect
	current_title = title
	current_rows = rows.duplicate(true)
	_render_info()
	if is_new_target:
		info_revealed = false
		if hover_ring != null:
			hover_ring.restart()
		if info_panel != null:
			info_panel.visible = false
	elif info_revealed:
		if hover_ring != null:
			hover_ring.visible = false
		if info_panel != null:
			info_panel.visible = true
	elif hover_ring != null and not hover_ring.visible:
		hover_ring.restart()
	_position_widgets()


func update_target_rect(global_rect: Rect2) -> void:
	if current_target_id == &"":
		return
	current_global_rect = global_rect
	_position_widgets()


func hide_hover() -> void:
	current_target_id = &""
	interrupted_target_id = &""
	info_revealed = false
	if hover_ring != null:
		hover_ring.stop()
	if info_panel != null:
		info_panel.visible = false


func interrupt_target(target_id: StringName) -> void:
	if target_id == &"":
		return
	_ensure_nodes()
	interrupted_target_id = target_id
	current_target_id = target_id
	info_revealed = false
	if hover_ring != null:
		hover_ring.stop()
	if info_panel != null:
		info_panel.visible = false


func is_ring_visible() -> bool:
	return hover_ring != null and hover_ring.visible


func is_info_visible() -> bool:
	return info_panel != null and info_panel.visible


func is_current_target(target_id: StringName) -> bool:
	return current_target_id == target_id


func set_fill_seconds(seconds: float) -> void:
	_ensure_nodes()
	if hover_ring != null:
		hover_ring.fill_seconds = seconds


func _ensure_nodes() -> void:
	if hover_ring == null:
		hover_ring = DiceHoverRing.new()
		hover_ring.name = "DiceHoverRing"
		hover_ring.visible = false
		hover_ring.completed.connect(_on_ring_completed)
		add_child(hover_ring)
	if info_panel == null:
		info_panel = _make_info_panel()
		info_panel.visible = false
		add_child(info_panel)


func _make_info_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = base_panel_size

	margin = MarginContainer.new()
	margin.name = "HoverInfoMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var rows := VBoxContainer.new()
	rows.name = "HoverInfoRows"
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(rows)
	rows_container = rows

	title_label = Label.new()
	title_label.name = "HoverTitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(title_label)
	return panel


func _render_info() -> void:
	if title_label == null or rows_container == null:
		return
	title_label.text = current_title
	_clear_dynamic_rows()
	for row in current_rows:
		rows_container.add_child(_make_info_row(
			str(row.get("key", row.get("name", ""))),
			str(row.get("name", "")),
			str(row.get("effect", ""))
		))
	_apply_style()


func _make_info_row(key: String, caption: String, value: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "%sRow" % [key]
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)

	var caption_label := Label.new()
	caption_label.name = "%sCaptionLabel" % [key]
	caption_label.text = caption
	caption_label.custom_minimum_size = Vector2(62.0, 0.0)
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(caption_label)

	var value_label := Label.new()
	value_label.name = "%sValueLabel" % [key]
	value_label.text = value
	value_label.custom_minimum_size = Vector2(210.0, 0.0)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value_label)
	return row


func _apply_style() -> void:
	if info_panel == null:
		return
	info_panel.add_theme_stylebox_override("panel", _make_info_panel_style())
	if margin != null:
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_bottom", 12)
	if rows_container != null:
		rows_container.add_theme_constant_override("separation", 7)
	if title_label != null:
		if style_config != null:
			style_config.apply_label(title_label, style_config.small_font_size + 2, Color(0.95, 0.92, 0.78))
		title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.88))
		title_label.add_theme_constant_override("outline_size", 4)
	for row in _dynamic_rows():
		if row.get_child_count() < 2:
			continue
		var caption := row.get_child(0) as Label
		var value := row.get_child(1) as Label
		if caption != null:
			if style_config != null:
				style_config.apply_label(caption, style_config.small_font_size, Color(0.62, 0.92, 0.86))
			caption.autowrap_mode = TextServer.AUTOWRAP_OFF
			caption.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			caption.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.86))
			caption.add_theme_constant_override("outline_size", 3)
		if value != null:
			if style_config != null:
				style_config.apply_label(value, style_config.small_font_size, Color(0.96, 0.94, 0.86))
			value.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			value.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.88))
			value.add_theme_constant_override("outline_size", 3)


func _make_info_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.060, 0.88)
	style.border_color = Color(0.44, 0.78, 0.74, 0.96)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


func _position_widgets() -> void:
	if hover_ring == null or info_panel == null:
		return
	if current_target_id == &"" or (not hover_ring.visible and not info_panel.visible):
		return
	var local_rect := _global_rect_to_local_rect(current_global_rect)
	var center := local_rect.get_center()
	var ring_side := clampf(maxf(local_rect.size.x, local_rect.size.y) * 0.74, 56.0, 88.0)
	hover_ring.position = center - Vector2(ring_side, ring_side) * 0.5
	hover_ring.size = Vector2(ring_side, ring_side)
	hover_ring.queue_redraw()

	var bounds := size
	if bounds.x <= 0.0 or bounds.y <= 0.0:
		bounds = get_viewport_rect().size
	var panel_size := _resolved_panel_size()
	info_panel.size = panel_size
	var panel_position := Vector2(center.x - panel_size.x * 0.5, local_rect.position.y - panel_size.y - 18.0)
	if panel_position.y < 18.0:
		panel_position.y = local_rect.position.y + local_rect.size.y + 18.0
	panel_position.x = clampf(panel_position.x, 18.0, maxf(18.0, bounds.x - panel_size.x - 18.0))
	panel_position.y = clampf(panel_position.y, 18.0, maxf(18.0, bounds.y - panel_size.y - 18.0))
	info_panel.position = panel_position


func _resolved_panel_size() -> Vector2:
	var row_count := maxi(1, current_rows.size())
	var width := maxf(base_panel_size.x, 340.0)
	var height := maxf(base_panel_size.y, 54.0 + float(row_count) * 34.0)
	if row_count > 4:
		width = maxf(width, 420.0)
	return Vector2(width, height)


func _global_rect_to_local_rect(global_rect: Rect2) -> Rect2:
	var inverse := get_global_transform_with_canvas().affine_inverse()
	var local_position := inverse * global_rect.position
	var local_end := inverse * (global_rect.position + global_rect.size)
	return Rect2(local_position, local_end - local_position)


func _on_ring_completed() -> void:
	if current_target_id == &"" or current_target_id == interrupted_target_id:
		return
	info_revealed = true
	if hover_ring != null:
		hover_ring.stop()
	if info_panel != null:
		info_panel.visible = true
	_position_widgets()
	revealed.emit(current_target_id)


func _clear_dynamic_rows() -> void:
	for row in _dynamic_rows():
		rows_container.remove_child(row)
		row.queue_free()


func _dynamic_rows() -> Array[Control]:
	var result: Array[Control] = []
	if rows_container == null:
		return result
	for child in rows_container.get_children():
		if child != title_label and child is Control:
			result.append(child as Control)
	return result
