extends Control
class_name RewardScreen


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const MapEventChoice = preload("res://scripts/data_defs/MapEventChoice.gd")
const RichTextHighlighter = preload("res://scripts/ui/RichTextHighlighter.gd")


var game_flow_controller: GameFlowController = null
var choices: Array = []


func setup(new_game_flow_controller: GameFlowController, new_choices: Array) -> void:
	game_flow_controller = new_game_flow_controller
	choices.clear()
	for choice in new_choices:
		if choice != null:
			choices.append(choice)


func _ready() -> void:
	_build_view()


func _build_view() -> void:
	_clear_view()

	var background := ColorRect.new()
	background.color = Color(0.065, 0.07, 0.085)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	if _is_map_event_choices():
		_build_map_event_view(root)
		return

	root.add_child(_make_text_label(str(TranslationServer.translate(&"AUTO.TEXT.B8CBB985D0FD")), 28, Color(0.95, 0.92, 0.84)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)

	for index in range(choices.size()):
		row.add_child(_make_choice_card(choices[index]))

	if choices.is_empty():
		root.add_child(_make_text_label(str(TranslationServer.translate(&"AUTO.TEXT.E7B22B2652B2")), 16, Color(0.9, 0.82, 0.78)))


func _build_map_event_view(root: VBoxContainer) -> void:
	var first_choice := choices[0] as MapEventChoice
	root.add_child(_make_text_label(first_choice.get_event_title(), 30, Color(0.96, 0.9, 0.72)))
	var type_text := first_choice.get_event_type_display_name()
	if type_text != "":
		root.add_child(_make_text_label("类型：%s" % [type_text], 15, Color(0.72, 0.82, 0.92)))
	var scene_text := first_choice.get_scene_text()
	if scene_text != "":
		var scene_label := _make_rich_text_label(scene_text, 16, Color(0.88, 0.88, 0.82))
		scene_label.custom_minimum_size = Vector2(0, 92)
		root.add_child(scene_label)
	var npc_text := first_choice.get_npc_text()
	if npc_text != "":
		root.add_child(_make_text_label("“%s”" % [npc_text], 16, Color(0.94, 0.82, 0.62)))

	var options_panel := PanelContainer.new()
	options_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_panel.custom_minimum_size = Vector2(820, 0)
	root.add_child(options_panel)

	var option_list := VBoxContainer.new()
	option_list.add_theme_constant_override("separation", 12)
	options_panel.add_child(option_list)

	for choice in choices:
		option_list.add_child(_make_event_option_row(choice))


func _make_event_option_row(choice) -> Control:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	row.add_child(box)

	var button := Button.new()
	button.text = _choice_button_text(choice)
	button.custom_minimum_size = Vector2(0, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var unavailable_reason := _choice_unavailable_reason(choice)
	button.disabled = unavailable_reason != ""
	button.pressed.connect(_on_choice_pressed.bind(choice))
	box.add_child(button)

	var effect_text := _choice_effect_text(choice)
	if unavailable_reason != "":
		effect_text = "%s\n不可用：%s。" % [effect_text, unavailable_reason]
	var effect_label := _make_rich_text_label(effect_text, 15, Color(0.86, 0.86, 0.78) if unavailable_reason == "" else Color(0.62, 0.62, 0.62))
	effect_label.custom_minimum_size = Vector2(0, 46)
	box.add_child(effect_label)
	return row


func _make_choice_card(choice) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 280)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	box.add_child(_make_text_label(_choice_display_name(choice), 20, Color(0.96, 0.88, 0.62)))
	box.add_child(_make_rich_text_label(_choice_description(choice), 15, Color(0.88, 0.88, 0.82)))
	var meta_text := _choice_meta_text(choice)
	if meta_text != "":
		box.add_child(_make_text_label(meta_text, 14, Color(0.72, 0.82, 0.92)))

	var operations_label := _make_rich_text_label(_choice_effect_text(choice), 14, Color(0.84, 0.84, 0.78))
	operations_label.custom_minimum_size = Vector2(0, 90)
	box.add_child(operations_label)

	var choose_button := Button.new()
	choose_button.text = str(TranslationServer.translate(&"AUTO.TEXT.70B208202CE5"))
	choose_button.custom_minimum_size = Vector2(0, 38)
	choose_button.pressed.connect(_on_choice_pressed.bind(choice))
	box.add_child(choose_button)
	return panel


func _on_choice_pressed(choice) -> void:
	if game_flow_controller == null:
		return
	game_flow_controller.choose_reward(choice)


func _choice_display_name(choice) -> String:
	var object := choice as Object
	if object != null and object.has_method("get_display_name"):
		return str(object.call("get_display_name"))
	return str(choice)


func _choice_button_text(choice) -> String:
	var object := choice as Object
	if object != null and object.has_method("get_button_text"):
		return str(object.call("get_button_text"))
	return _choice_display_name(choice)


func _choice_description(choice) -> String:
	var object := choice as Object
	if object != null and object.has_method("get_description"):
		return str(object.call("get_description"))
	return ""


func _choice_unavailable_reason(choice) -> String:
	var object := choice as Object
	if object != null and object.has_method("get_unavailable_reason"):
		var run_state = game_flow_controller.get_run_state() if game_flow_controller != null and game_flow_controller.has_method("get_run_state") else null
		return str(object.call("get_unavailable_reason", run_state))
	return ""


func _choice_effect_text(choice) -> String:
	var object := choice as Object
	if object != null and object.has_method("get_effect_text"):
		return str(object.call("get_effect_text"))
	return ""


func _choice_meta_text(choice) -> String:
	var object := choice as Object
	var lines := PackedStringArray()
	if object != null and object.has_method("get_rarity_display_name"):
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.6DB5DF72B910")) % [object.call("get_rarity_display_name")])
	if object != null and object.has_method("get_tags_display_text"):
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.ABAAFC3C7A71")) % [object.call("get_tags_display_text")])
	return "\n".join(lines)


func _is_map_event_choices() -> bool:
	if choices.is_empty():
		return false
	var first_choice := choices[0] as MapEventChoice
	if first_choice == null:
		return false
	for choice in choices:
		var event_choice := choice as MapEventChoice
		if event_choice == null or event_choice.event_id != first_choice.event_id:
			return false
	return true


func _make_text_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	_apply_label_theme(label, font_size, color)
	return label


func _apply_label_theme(label: Label, font_size: int, color: Color) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


func _make_rich_text_label(text: String, font_size: int, color: Color) -> RichTextLabel:
	var label := RichTextLabel.new()
	RichTextHighlighter.setup_rich_label(label, text, font_size, color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _clear_view() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
