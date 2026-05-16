extends Control
class_name RunResultScreen


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


var game_flow_controller: GameFlowController = null
var run_state: RunState = null


func setup(new_game_flow_controller: GameFlowController, new_run_state: RunState) -> void:
	game_flow_controller = new_game_flow_controller
	run_state = new_run_state


func _ready() -> void:
	_build_view()


func _build_view() -> void:
	_clear_view()

	var background := ColorRect.new()
	background.color = Color(0.06, 0.065, 0.075)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	root.add_child(_make_text_label(_title_text(), 30, Color(0.95, 0.92, 0.84)))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	var restart_button := Button.new()
	restart_button.text = "重新开始"
	restart_button.custom_minimum_size = Vector2(180, 38)
	restart_button.pressed.connect(_on_restart_pressed)
	button_row.add_child(restart_button)

	var main_button := Button.new()
	main_button.text = "返回主界面"
	main_button.custom_minimum_size = Vector2(180, 38)
	main_button.pressed.connect(_on_back_to_main_pressed)
	button_row.add_child(main_button)
	root.add_child(button_row)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	root.add_child(columns)

	var summary := TextEdit.new()
	summary.custom_minimum_size = Vector2(360, 520)
	summary.editable = false
	summary.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	summary.text = _summary_text()
	columns.add_child(summary)

	var dice_text := TextEdit.new()
	dice_text.custom_minimum_size = Vector2(520, 520)
	dice_text.editable = false
	dice_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	dice_text.text = _dice_collection_text()
	columns.add_child(dice_text)


func _title_text() -> String:
	if run_state != null and run_state.run_won:
		return "通关成功"
	return "挑战失败"


func _summary_text() -> String:
	if run_state == null:
		return "没有当前局状态。"
	return run_state.get_run_summary_text()


func _dice_collection_text() -> String:
	if run_state == null:
		return "没有骰子。"

	var lines := PackedStringArray()
	lines.append("最终骰组")
	for die_index in range(run_state.dice.size()):
		lines.append("")
		lines.append("骰子 %d" % [die_index + 1])
		lines.append(DisplayNames.die_summary(run_state.dice[die_index]))
	return "\n".join(lines)


func _on_restart_pressed() -> void:
	if game_flow_controller != null:
		game_flow_controller.start_new_run()


func _on_back_to_main_pressed() -> void:
	if game_flow_controller != null:
		game_flow_controller.back_to_main()


func _make_text_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _clear_view() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
