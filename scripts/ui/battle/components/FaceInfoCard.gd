extends PanelContainer
class_name FaceInfoCard


const FaceViewData = preload("res://scripts/ui/battle/view_models/FaceViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")


signal ornament_link_pressed(id: StringName)
signal mark_link_pressed(id: StringName)


var title_label: Label = null
var pip_label: Label = null
var ornament_value_container: Control = null
var mark_value_container: Control = null


func render(face_data: FaceViewData, _icon_library: BattleIconLibrary, style_config: BattleUiStyleConfig) -> void:
	_rebuild_layout(style_config)

	if face_data == null:
		title_label.text = str(TranslationServer.translate(&"AUTO.TEXT.9C931D7AD49C"))
		pip_label.text = str(TranslationServer.translate(&"AUTO.TEXT.EA4600C595EC"))
		_set_link_value(ornament_value_container, &"", str(TranslationServer.translate(&"AUTO.TEXT.72077749F794")), &"ornament", style_config)
		_set_link_value(mark_value_container, &"", str(TranslationServer.translate(&"AUTO.TEXT.72077749F794")), &"mark", style_config)
		return

	title_label.text = str(TranslationServer.translate(&"AUTO.TEXT.51C2E5D71139")) % [face_data.face_index + 1]
	pip_label.text = str(TranslationServer.translate(&"AUTO.TEXT.3BD4F422F927")) % [face_data.pip]
	_set_link_value(
		ornament_value_container,
		face_data.ornament_id,
		_none_text(face_data.ornament_id, face_data.ornament_name),
		&"ornament",
		style_config
	)
	_set_link_value(
		mark_value_container,
		face_data.mark_id,
		_none_text(face_data.mark_id, face_data.mark_name),
		&"mark",
		style_config
	)


func _rebuild_layout(style_config: BattleUiStyleConfig) -> void:
	_clear_children(self)

	if style_config != null:
		add_theme_stylebox_override("panel", style_config.get_panel_style())
		custom_minimum_size = style_config.face_card_size

	var margin := MarginContainer.new()
	add_child(margin)
	if style_config != null:
		style_config.apply_margin(margin, max(8, style_config.panel_padding - 4))
	else:
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	margin.add_child(rows)

	title_label = _make_label(style_config, true)
	pip_label = _make_label(style_config, false)
	rows.add_child(title_label)
	rows.add_child(pip_label)

	var ornament_row := _make_value_row(str(TranslationServer.translate(&"AUTO.TEXT.191A3BBC896F")), style_config)
	ornament_value_container = ornament_row.get_node("ValueContainer")
	rows.add_child(ornament_row)

	var mark_row := _make_value_row(str(TranslationServer.translate(&"AUTO.TEXT.A4CA68633FD1")), style_config)
	mark_value_container = mark_row.get_node("ValueContainer")
	rows.add_child(mark_row)


func _make_value_row(label_text: String, style_config: BattleUiStyleConfig) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN

	var key_label := _make_label(style_config, false)
	key_label.text = label_text
	key_label.custom_minimum_size.x = 70.0
	key_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(key_label)

	var value_container := HBoxContainer.new()
	value_container.name = "ValueContainer"
	value_container.custom_minimum_size = Vector2(104, 28)
	value_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value_container)
	return row


func _make_label(style_config: BattleUiStyleConfig, centered: bool) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if style_config != null:
		style_config.apply_label(label, style_config.body_font_size if centered else style_config.small_font_size)
	return label


func _set_link_value(
	container: Control,
	id: StringName,
	display_name: String,
	kind: StringName,
	style_config: BattleUiStyleConfig
) -> void:
	if container == null:
		return
	_clear_children(container)

	if _is_none_id(id):
		var label := _make_label(style_config, false)
		label.text = display_name
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(label)
		return

	var link := RichTextLabel.new()
	link.bbcode_enabled = true
	link.fit_content = true
	link.scroll_active = false
	link.autowrap_mode = TextServer.AUTOWRAP_OFF
	link.mouse_filter = Control.MOUSE_FILTER_STOP
	link.custom_minimum_size = Vector2(104, 28)
	link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if style_config != null:
		link.add_theme_font_size_override("normal_font_size", style_config.small_font_size)
		link.add_theme_font_size_override("bold_font_size", style_config.small_font_size)
		if style_config.font != null:
			link.add_theme_font_override("normal_font", style_config.font)
			link.add_theme_font_override("bold_font", style_config.font)
	var color := style_config.info_link_text_color.to_html(false) if style_config != null else "ff9300"
	link.text = "[url=%s:%s][u][color=#%s]%s[/color][/u][/url]" % [
		str(kind),
		str(id),
		color,
		_escape_bbcode(display_name),
	]
	link.meta_clicked.connect(_on_link_clicked)
	container.add_child(link)


func _on_link_clicked(meta) -> void:
	var text := str(meta)
	if text.begins_with("ornament:"):
		ornament_link_pressed.emit(StringName(text.trim_prefix("ornament:")))
	elif text.begins_with("mark:"):
		mark_link_pressed.emit(StringName(text.trim_prefix("mark:")))


func _none_text(id: StringName, fallback: String) -> String:
	return str(TranslationServer.translate(&"AUTO.TEXT.72077749F794")) if _is_none_id(id) else fallback


func _is_none_id(id: StringName) -> bool:
	return id == &"" or id == &"none" or id == &"orn_none" or id == &"mark_none"


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "\\[").replace("]", "\\]")


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
