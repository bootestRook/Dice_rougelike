extends Control
class_name RewardScreen


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")


var game_flow_controller: GameFlowController = null
var choices: Array[ForgePieceDef] = []


func setup(new_game_flow_controller: GameFlowController, new_choices: Array) -> void:
	game_flow_controller = new_game_flow_controller
	choices.clear()
	for choice in new_choices:
		if choice is ForgePieceDef:
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
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	root.add_child(_make_text_label("选择一个铸骰件", 28, Color(0.95, 0.92, 0.84)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)

	for index in range(choices.size()):
		row.add_child(_make_choice_card(choices[index]))

	if choices.is_empty():
		root.add_child(_make_text_label("没有生成奖励。", 16, Color(0.9, 0.82, 0.78)))


func _make_choice_card(piece: ForgePieceDef) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 280)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	box.add_child(_make_text_label(piece.get_display_name(), 20, Color(0.96, 0.88, 0.62)))
	box.add_child(_make_text_label(piece.get_description(), 15, Color(0.88, 0.88, 0.82)))
	box.add_child(_make_text_label("稀有度：%s" % [piece.get_rarity_display_name()], 14, Color(0.72, 0.82, 0.92)))
	box.add_child(_make_text_label("标签：%s" % [piece.get_tags_display_text()], 14, Color(0.78, 0.88, 0.72)))

	var operations_label := _make_text_label(piece.get_effect_text(), 14, Color(0.84, 0.84, 0.78))
	operations_label.custom_minimum_size = Vector2(0, 90)
	box.add_child(operations_label)

	var choose_button := Button.new()
	choose_button.text = "选择"
	choose_button.custom_minimum_size = Vector2(0, 38)
	choose_button.pressed.connect(_on_choice_pressed.bind(piece))
	box.add_child(choose_button)
	return panel


func _on_choice_pressed(piece: ForgePieceDef) -> void:
	if game_flow_controller == null:
		return
	game_flow_controller.choose_reward(piece)


func _make_text_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	_apply_label_theme(label, font_size, color)
	return label


func _apply_label_theme(label: Label, font_size: int, color: Color) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


func _clear_view() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
