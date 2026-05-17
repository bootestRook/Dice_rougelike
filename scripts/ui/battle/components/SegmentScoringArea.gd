extends PanelContainer
class_name SegmentScoringArea


const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")
const DiceVisualLibrary = preload("res://scripts/ui/battle/resources/DiceVisualLibrary.gd")


signal reward_choice_pressed(choice)


var style_config: BattleUiStyleConfig = null
var icon_library: BattleIconLibrary = null
var dice_visual_library: DiceVisualLibrary = null
var score_log_row_scene: PackedScene = null
var floating_score_text_scene: PackedScene = null
var dice_view_scene: PackedScene = null
var reward_overlay: Control = null
var reward_choices: Array = []
var round_marker_layer: Control = null
var round_caption_label: Label = null
var round_value_label: Label = null
var round_marker_font: Font = null

@onready var margin: MarginContainer = %ScoringMargin
@onready var title_label: Label = %TitleLabel
@onready var stage_panel: PanelContainer = %StagePanel
@onready var settlement_slots: HBoxContainer = %SettlementSlots
@onready var preview_label: Label = %PreviewLabel
@onready var status_label: Label = %StatusLabel
@onready var log_rows: VBoxContainer = %LogRows
@onready var floating_layer: Control = %FloatingScoreLayer


func setup(
	new_style_config: BattleUiStyleConfig,
	new_score_log_row_scene: PackedScene,
	new_floating_score_text_scene: PackedScene,
	new_dice_view_scene: PackedScene = null,
	new_icon_library: BattleIconLibrary = null,
	new_dice_visual_library: DiceVisualLibrary = null
) -> void:
	style_config = new_style_config
	score_log_row_scene = new_score_log_row_scene
	floating_score_text_scene = new_floating_score_text_scene
	dice_view_scene = new_dice_view_scene
	icon_library = new_icon_library
	dice_visual_library = new_dice_visual_library
	if is_node_ready():
		_apply_style()


func _ready() -> void:
	_ensure_round_marker()
	_apply_round_marker_style()
	_apply_style()
	floating_layer.visible = true
	clear_resolution_dice()


func render(state: BattleHudState) -> void:
	if state == null:
		return

	status_label.text = _stage_status_text(state)
	preview_label.text = ""
	_set_round_marker_text(state.current_hand)
	_render_log(state.score_log)


func _apply_style() -> void:
	if not is_node_ready() or style_config == null:
		return
	add_theme_stylebox_override("panel", style_config.get_panel_style())
	stage_panel.add_theme_stylebox_override("panel", style_config.get_panel_style())
	style_config.apply_margin(margin, style_config.panel_padding)
	style_config.apply_label(title_label, style_config.title_font_size)
	style_config.apply_label(preview_label, style_config.small_font_size)
	style_config.apply_label(status_label, style_config.body_font_size)
	_apply_round_marker_style()
	title_label.visible = false
	preview_label.visible = false
	preview_label.clip_text = true
	preview_label.max_lines_visible = 2
	log_rows.add_theme_constant_override("separation", max(2, style_config.card_gap / 2))
	settlement_slots.add_theme_constant_override("separation", style_config.layout_gap)
	for slot in settlement_slots.get_children():
		if slot is PanelContainer:
			(slot as PanelContainer).add_theme_stylebox_override("panel", style_config.get_slot_style())
	if reward_overlay != null:
		reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_reward_choices(choices: Array) -> void:
	reward_choices = choices.duplicate()
	_ensure_reward_overlay()
	_rebuild_reward_overlay()
	if reward_overlay != null:
		reward_overlay.visible = true
	status_label.text = str(TranslationServer.translate(&"AUTO.TEXT.BD9FEA62A9DC"))


func hide_reward_choices() -> void:
	reward_choices.clear()
	if reward_overlay != null:
		reward_overlay.visible = false


func _ensure_reward_overlay() -> void:
	if reward_overlay != null or stage_panel == null:
		return
	reward_overlay = Control.new()
	reward_overlay.name = "RewardChoiceOverlay"
	reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	reward_overlay.z_index = 70
	reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_panel.add_child(reward_overlay)


func _rebuild_reward_overlay() -> void:
	if reward_overlay == null:
		return
	_clear_children(reward_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	reward_overlay.add_child(center)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", max(24, style_config.layout_gap if style_config != null else 14))
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(row)

	if reward_choices.is_empty():
		row.add_child(_make_reward_label(str(TranslationServer.translate(&"AUTO.TEXT.E7B22B2652B2")), 22, Color(0.95, 0.86, 0.72)))
		return

	for choice in reward_choices:
		row.add_child(_make_reward_choice_card(choice))


func _make_reward_choice_card(choice) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(306.0, 346.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.add_theme_stylebox_override("panel", _make_reward_card_style())
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
				reward_choice_pressed.emit(choice)
	)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var title := _make_reward_label(_choice_display_name(choice), 24, Color(1.0, 0.88, 0.48))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0.0, 54.0)
	title.max_lines_visible = 2
	box.add_child(title)

	var meta := _make_reward_label(_choice_meta_text(choice), 13, Color(0.70, 0.86, 0.74))
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta.custom_minimum_size = Vector2(0.0, 44.0)
	meta.max_lines_visible = 2
	box.add_child(meta)

	var desc := _make_reward_label(_choice_description(choice), 15, Color(0.90, 0.92, 0.84))
	desc.custom_minimum_size = Vector2(0.0, 88.0)
	desc.max_lines_visible = 4
	box.add_child(desc)

	var effect := _make_reward_label(_choice_effect_text(choice), 14, Color(1.0, 0.80, 0.42))
	effect.custom_minimum_size = Vector2(0.0, 58.0)
	effect.max_lines_visible = 3
	box.add_child(effect)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var button := Button.new()
	button.text = str(TranslationServer.translate(&"AUTO.TEXT.70B208202CE5"))
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.custom_minimum_size = Vector2(0.0, 42.0)
	if style_config != null:
		style_config.apply_button(button)
	button.pressed.connect(func() -> void: reward_choice_pressed.emit(choice))
	box.add_child(button)
	return panel


func _make_reward_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if style_config != null:
		style_config.apply_label(label, font_size, color)
	else:
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)
	return label


func _choice_display_name(choice) -> String:
	var object := choice as Object
	if object != null and object.has_method("get_display_name"):
		return str(object.call("get_display_name"))
	if object != null and object.has_method("get_name"):
		return str(object.call("get_name"))
	return str(choice)


func _choice_description(choice) -> String:
	var object := choice as Object
	if object != null and object.has_method("get_description"):
		return str(object.call("get_description"))
	if object != null and object.has_method("get_display_text"):
		var display_text := str(object.call("get_display_text"))
		var lines := display_text.split("\n")
		return str(lines[1]) if lines.size() > 1 else display_text
	return ""


func _choice_meta_text(choice) -> String:
	var object := choice as Object
	var parts := PackedStringArray()
	if object != null and object.has_method("get_rarity_display_name"):
		parts.append(str(TranslationServer.translate(&"AUTO.TEXT.6DB5DF72B910")) % [object.call("get_rarity_display_name")])
	if object != null and object.has_method("get_tags_display_text"):
		parts.append(str(TranslationServer.translate(&"AUTO.TEXT.ABAAFC3C7A71")) % [object.call("get_tags_display_text")])
	return "\n".join(parts)


func _choice_effect_text(choice) -> String:
	var object := choice as Object
	if object != null and object.has_method("get_effect_text"):
		return str(object.call("get_effect_text")).replace("\n", " / ")
	return ""


func _make_reward_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.135, 0.095, 0.98)
	style.border_color = Color(1.0, 0.68, 0.18, 0.92)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0.0, 6.0)
	return style


func _ensure_round_marker() -> void:
	if round_marker_layer != null or stage_panel == null:
		return

	round_marker_layer = Control.new()
	round_marker_layer.name = "RoundMarkerLayer"
	round_marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	round_marker_layer.visible = false
	stage_panel.add_child(round_marker_layer)
	stage_panel.move_child(round_marker_layer, 0)
	round_marker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var marker_margin := MarginContainer.new()
	marker_margin.name = "RoundMarkerMargin"
	marker_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_margin.add_theme_constant_override("margin_bottom", 340)
	round_marker_layer.add_child(marker_margin)
	marker_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var marker_center := CenterContainer.new()
	marker_center.name = "RoundMarkerCenter"
	marker_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marker_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	marker_margin.add_child(marker_center)

	var marker_rows := VBoxContainer.new()
	marker_rows.name = "RoundMarkerRows"
	marker_rows.custom_minimum_size = Vector2(310, 120)
	marker_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_rows.alignment = BoxContainer.ALIGNMENT_CENTER
	marker_rows.add_theme_constant_override("separation", 0)
	marker_center.add_child(marker_rows)

	round_caption_label = Label.new()
	round_caption_label.name = "RoundCaption"
	round_caption_label.text = str(TranslationServer.translate(&"AUTO.TEXT.52D27A21F811"))
	round_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	round_caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_rows.add_child(round_caption_label)

	round_value_label = Label.new()
	round_value_label.name = "RoundValue"
	round_value_label.text = "1"
	round_value_label.custom_minimum_size = Vector2(70, 78)
	round_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	round_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_rows.add_child(round_value_label)


func _apply_round_marker_style() -> void:
	_ensure_round_marker()
	if round_marker_layer == null:
		return
	var caption_size := 22
	var value_size := 74
	if style_config != null:
		caption_size = style_config.small_font_size + 2
	if round_caption_label != null:
		round_caption_label.text = str(TranslationServer.translate(&"AUTO.TEXT.52D27A21F811"))
		_apply_marker_label_style(round_caption_label, caption_size, Color(0.50, 0.57, 0.78, 0.34))
	if round_value_label != null:
		_apply_marker_label_style(round_value_label, value_size, Color(0.48, 0.55, 0.82, 0.36))
		round_value_label.add_theme_font_override("font", _get_round_marker_font())
		round_value_label.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.04, 0.10))
		round_value_label.add_theme_constant_override("outline_size", 3)


func _apply_marker_label_style(label: Label, font_size: int, color: Color) -> void:
	if label == null:
		return
	if style_config != null and style_config.font != null:
		label.add_theme_font_override("font", style_config.font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _get_round_marker_font() -> Font:
	if round_marker_font == null:
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Impact", "Arial Black", "Bahnschrift Display", "Bahnschrift", "Arial"])
		round_marker_font = font
	return round_marker_font


func _set_round_marker_text(current_hand: int) -> void:
	_ensure_round_marker()
	if round_marker_layer == null or round_value_label == null:
		return
	round_marker_layer.visible = current_hand > 0
	round_value_label.text = str(maxi(0, current_hand))


func _stage_status_text(state: BattleHudState) -> String:
	if state == null:
		return ""
	if state.max_selected_dice <= 0:
		return state.status_text
	var selected_text := str(TranslationServer.translate(&"AUTO.TEXT.34EB0A73B9C4")) % [
		state.selected_dice_indices.size(),
		state.max_selected_dice,
	]
	return "" if state.status_text == selected_text else state.status_text


func _render_log(lines: Array[String]) -> void:
	_clear_children(log_rows)
	if lines.is_empty():
		_add_log_row(str(TranslationServer.translate(&"AUTO.TEXT.FA5D45A99246")))
		return

	for line in lines:
		_add_log_row(line)


func _add_log_row(text: String) -> void:
	var row := _make_log_row()
	log_rows.add_child(row)
	if row.has_method("render"):
		row.render(text, style_config)
	elif row is Label:
		row.text = text


func _compact_preview(text: String) -> String:
	var lines := text.split("\n", false)
	if lines.size() <= 2:
		return text
	return "%s\n%s" % [lines[0], lines[1]]


func _make_log_row() -> Control:
	if score_log_row_scene != null:
		var row := score_log_row_scene.instantiate()
		if row is Control:
			return row

	var fallback := Label.new()
	if style_config != null:
		style_config.apply_label(fallback, style_config.small_font_size)
	return fallback


func show_floating_score(text: String) -> void:
	var floating := _make_floating_score(text)
	if floating == null:
		return
	_position_floating(floating, Vector2(-999999.0, -999999.0))
	_animate_and_free_floating(floating)


func show_floating_score_at(text: String, global_position: Vector2) -> void:
	var floating := _make_floating_score(text)
	if floating == null:
		return
	_position_floating(floating, global_position)
	_animate_and_free_floating(floating)


func play_floating_score(text: String) -> void:
	var floating := _make_floating_score(text)
	if floating == null:
		return
	_position_floating(floating, Vector2(-999999.0, -999999.0))
	await _animate_and_free_floating(floating)


func play_floating_score_at(text: String, global_position: Vector2) -> void:
	var floating := _make_floating_score(text)
	if floating == null:
		return
	_position_floating(floating, global_position)
	await _animate_and_free_floating(floating)


func _make_floating_score(text: String) -> Control:
	if floating_score_text_scene == null:
		return null
	var floating := floating_score_text_scene.instantiate()
	if not floating is Control:
		return null
	floating_layer.add_child(floating)
	var display_text := _floating_display_text(text)
	var display_color := _floating_display_color(text)
	if floating.has_method("render"):
		floating.render(display_text, style_config)
	if floating.has_method("set_floating_color"):
		floating.set_floating_color(display_color)
	elif floating is Label:
		(floating as Label).add_theme_color_override("font_color", display_color)
	return floating as Control


func show_resolution_dice(dice_data: Array[DieViewData], transparent: bool = false) -> void:
	_clear_children(settlement_slots)
	for data in dice_data:
		var view := _make_dice_view()
		view.set_meta("resolution_index", settlement_slots.get_child_count())
		view.set_meta("die_index", data.die_index)
		settlement_slots.add_child(view)
		if view.has_method("render"):
			view.render(data, style_config, icon_library, dice_visual_library)
		view.modulate.a = 0.0 if transparent else 1.0


func clear_resolution_dice() -> void:
	if settlement_slots != null:
		_clear_children(settlement_slots)
	clear_highlights()


func set_resolution_dice_visible(value: bool) -> void:
	for child in settlement_slots.get_children():
		if child is Control:
			(child as Control).modulate.a = 1.0 if value else 0.0


func set_resolution_index_visible(index: int, value: bool) -> void:
	var view := _resolution_view_at(index)
	if view != null:
		view.modulate.a = 1.0 if value else 0.0


func get_resolution_dice_global_position(index: int) -> Vector2:
	var view := _resolution_view_at(index)
	if view == null:
		return settlement_slots.get_global_rect().get_center()
	return view.global_position


func get_resolution_dice_global_center(index: int) -> Vector2:
	var view := _resolution_view_at(index)
	if view == null:
		return settlement_slots.get_global_rect().get_center()
	return view.get_global_rect().get_center()


func get_resolution_dice_global_rect(index: int) -> Rect2:
	var view := _resolution_view_at(index)
	if view == null:
		return Rect2(settlement_slots.get_global_rect().get_center(), Vector2.ZERO)
	return view.get_global_rect()


func get_resolution_dice_global_floating_anchor(index: int) -> Vector2:
	var view := _resolution_view_at(index)
	if view == null:
		return settlement_slots.get_global_rect().get_center()
	var rect := view.get_global_rect()
	var floating_height := 36.0
	var gap := 8.0
	if style_config != null:
		floating_height = style_config.floating_score_size.y
		gap = style_config.floating_score_above_dice_gap
	return Vector2(rect.get_center().x, rect.position.y - gap - floating_height * 0.5)


func highlight_resolution_index(index: int) -> void:
	for child in settlement_slots.get_children():
		if not child is Control:
			continue
		var view := child as Control
		var active := int(view.get_meta("resolution_index", -1)) == index
		view.modulate = Color(1.0, 0.92, 0.45, 1.0) if active else Color.WHITE
		view.scale = Vector2(1.05, 1.05) if active else Vector2.ONE


func clear_highlights() -> void:
	if settlement_slots == null:
		return
	for child in settlement_slots.get_children():
		if child is Control:
			(child as Control).modulate = Color.WHITE
			(child as Control).scale = Vector2.ONE


func show_step_text(title: String, detail: String) -> void:
	status_label.text = title
	preview_label.text = ""


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _make_dice_view() -> Control:
	if dice_view_scene != null:
		var view := dice_view_scene.instantiate()
		if view is Control:
			return view
	var fallback := PanelContainer.new()
	if style_config != null:
		fallback.custom_minimum_size = style_config.dice_display_size
		fallback.add_theme_stylebox_override("panel", style_config.get_slot_style())
	return fallback


func _resolution_view_at(index: int) -> Control:
	for child in settlement_slots.get_children():
		if child is Control and int(child.get_meta("resolution_index", -1)) == index:
			return child as Control
	return null


func _floating_display_text(raw_text: String) -> String:
	var stripped := raw_text.strip_edges()
	var lower := stripped.to_lower()
	if lower.ends_with(" chips"):
		return stripped.split(" ", false)[0]
	if lower.ends_with(" mult"):
		return "X %s" % [_unsigned_number_token(stripped.split(" ", false)[0])]
	if lower.begins_with("x"):
		return "X %s" % [_xmult_number_token(stripped)]
	return stripped


func _floating_display_color(raw_text: String) -> Color:
	var lower := raw_text.strip_edges().to_lower()
	if lower.ends_with(" mult") or lower.begins_with("x"):
		return style_config.floating_mult_text_color if style_config != null else Color(1.0, 0.78, 0.16)
	return style_config.floating_chips_text_color if style_config != null else Color(0.96, 0.95, 0.88)


func _unsigned_number_token(token: String) -> String:
	var value := token.strip_edges().trim_prefix("+")
	if value.is_valid_float():
		return str(ceili(value.to_float()))
	return value


func _xmult_number_token(text: String) -> String:
	var first_token := text.strip_edges().split(" ", false)[0]
	var value := first_token.trim_prefix("X").trim_prefix("x").strip_edges()
	if value.is_valid_float():
		return str(ceili(value.to_float()))
	return value if value != "" else "1"


func _position_floating(floating: Control, global_position: Vector2) -> void:
	if floating == null:
		return
	var local_position := floating_layer.size * 0.5
	if global_position.x > -900000.0:
		local_position = floating_layer.get_global_transform_with_canvas().affine_inverse() * global_position
	var floating_size := floating.get_combined_minimum_size()
	if floating.size != Vector2.ZERO:
		floating_size = floating.size
	floating.position = local_position - floating_size * 0.5
	floating.position.x = clampf(floating.position.x, 0.0, maxf(0.0, floating_layer.size.x - floating_size.x))
	floating.position.y = clampf(floating.position.y, 0.0, maxf(0.0, floating_layer.size.y - floating_size.y))
	floating.modulate.a = 1.0


func _animate_and_free_floating(floating: Control) -> void:
	if floating == null:
		return
	var duration_seconds := 1.0
	var slide_pixels := 28.0
	var shake_pixels := 5.0
	if style_config != null:
		duration_seconds = style_config.floating_score_duration_seconds
		slide_pixels = style_config.floating_score_slide_pixels
		shake_pixels = style_config.floating_score_shake_pixels
	if not is_instance_valid(floating):
		return

	duration_seconds = maxf(0.1, duration_seconds)
	var appear_seconds := duration_seconds * 0.22
	var fade_seconds := duration_seconds * 0.26
	var shake_step_seconds := (duration_seconds - appear_seconds - fade_seconds) / 8.0
	var rest_position := floating.position
	floating.pivot_offset = floating.size * 0.5
	floating.position = rest_position - Vector2(slide_pixels, 0.0)
	floating.scale = Vector2(0.5, 0.86)
	floating.modulate.a = 0.0
	var impact_echo := _make_floating_impact_echo(floating, rest_position)

	var tween := create_tween()
	tween.tween_property(floating, "position:x", rest_position.x, appear_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(floating, "scale", Vector2(1.34, 1.34), appear_seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(floating, "modulate:a", 1.0, appear_seconds * 0.75)
	if impact_echo != null:
		tween.parallel().tween_property(impact_echo, "scale", Vector2(1.82, 1.82), appear_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(impact_echo, "modulate:a", 0.0, appear_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var shake_offsets: Array[Vector2] = [
		Vector2(shake_pixels, 0.0),
		Vector2(-shake_pixels * 0.7, shake_pixels * 0.25),
		Vector2(shake_pixels * 0.55, -shake_pixels * 0.2),
		Vector2(-shake_pixels * 0.4, 0.0),
		Vector2(shake_pixels * 0.3, shake_pixels * 0.15),
		Vector2(-shake_pixels * 0.2, -shake_pixels * 0.1),
		Vector2(shake_pixels * 0.12, 0.0),
		Vector2.ZERO,
	]
	for offset in shake_offsets:
		tween.tween_property(floating, "position", rest_position + offset, shake_step_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(floating, "modulate:a", 0.0, fade_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(floating, "scale", Vector2(1.48, 1.48), fade_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(floating, "position:x", rest_position.x + slide_pixels * 0.35, fade_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(impact_echo):
		impact_echo.queue_free()
	if is_instance_valid(floating):
		floating.queue_free()


func _make_floating_impact_echo(floating: Control, rest_position: Vector2) -> Label:
	if floating == null or not floating is Label:
		return null
	var source := floating as Label
	var echo := Label.new()
	echo.text = source.text
	echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	echo.custom_minimum_size = floating.size
	echo.size = floating.size
	echo.position = rest_position
	echo.pivot_offset = echo.size * 0.5
	echo.scale = Vector2(0.9, 0.9)
	echo.z_index = max(0, floating.z_index - 1)
	echo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	echo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	echo.autowrap_mode = TextServer.AUTOWRAP_OFF
	echo.clip_text = true
	echo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var font := source.get_theme_font("font")
	if font != null:
		echo.add_theme_font_override("font", font)
	echo.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size") + 8)
	echo.add_theme_color_override("font_color", Color(1.0, 0.98, 0.72, 0.88))
	echo.add_theme_color_override("font_outline_color", Color(1.0, 0.38, 0.02, 0.64))
	echo.add_theme_constant_override("outline_size", 7)
	floating_layer.add_child(echo)
	return echo
