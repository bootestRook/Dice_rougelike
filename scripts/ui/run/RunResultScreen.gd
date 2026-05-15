extends Control
class_name RunResultScreen


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocalizedButton = preload("res://scripts/i18n/LocalizedButton.gd")
const LocalizedLabel = preload("res://scripts/i18n/LocalizedLabel.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


var game_flow_controller: GameFlowController = null
var run_state: RunState = null


func setup(new_game_flow_controller: GameFlowController, new_run_state: RunState) -> void:
	game_flow_controller = new_game_flow_controller
	run_state = new_run_state


func _ready() -> void:
	if not Loc.locale_changed.is_connected(_on_locale_changed):
		Loc.locale_changed.connect(_on_locale_changed)
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

	root.add_child(_make_loc_label(_title_key(), {}, 30, Color(0.95, 0.92, 0.84)))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	var restart_button := LocalizedButton.new()
	restart_button.set_loc_key(&"UI.RUN.RESTART")
	restart_button.custom_minimum_size = Vector2(180, 38)
	restart_button.pressed.connect(_on_restart_pressed)
	button_row.add_child(restart_button)

	var main_button := LocalizedButton.new()
	main_button.set_loc_key(&"UI.RUN.BACK_TO_MAIN")
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


func _title_key() -> StringName:
	if run_state != null and run_state.run_won:
		return &"UI.RUN.VICTORY_TITLE"
	return &"UI.RUN.DEFEAT_TITLE"


func _summary_text() -> String:
	if run_state == null:
		return Loc.t(&"UI.RUN.NO_RUN_STATE")
	return run_state.get_run_summary_text()


func _dice_collection_text() -> String:
	if run_state == null:
		return Loc.t(&"UI.RUN.NO_DICE")

	var lines := PackedStringArray()
	lines.append(Loc.t(&"UI.RUN.FINAL_DICE"))
	for die_index in range(run_state.dice.size()):
		lines.append("")
		lines.append(Loc.t(&"UI.RUN.DIE", {"die": die_index + 1}))
		var die = run_state.dice[die_index]
		for face_index in range(die.faces.size()):
			lines.append(Loc.t(&"UI.RUN.FACE", {
				"face": face_index + 1,
				"details": _format_face(die.faces[face_index]),
			}))
	return "\n".join(lines)


func _format_face(face) -> String:
	var parts := PackedStringArray()
	parts.append(Loc.t(&"UI.RUN.FACE_PIP", {"pip": face.pip}))
	if not _is_none_id(face.material_id):
		parts.append(Loc.t(&"UI.RUN.FACE_MATERIAL", {"material": Loc.t(LocKeys.material_name_key(face.material_id))}))
	if not _is_none_id(face.mark_id):
		parts.append(Loc.t(&"UI.RUN.FACE_IMPRINT", {"imprint": Loc.t(LocKeys.imprint_name_key(face.mark_id))}))
	if not _is_none_id(face.rune_id):
		parts.append(Loc.t(&"UI.RUN.FACE_RUNE", {"rune": Loc.t(LocKeys.rune_name_key(face.rune_id))}))
	if face.level > 1:
		parts.append(Loc.t(&"UI.RUN.FACE_LEVEL", {"level": face.level}))
	return ", ".join(parts)


func _is_none_id(value: StringName) -> bool:
	return value == &"" or value == &"none"


func _on_restart_pressed() -> void:
	if game_flow_controller != null:
		game_flow_controller.start_new_run()


func _on_back_to_main_pressed() -> void:
	if game_flow_controller != null:
		game_flow_controller.back_to_main()


func _make_loc_label(key: StringName, args: Dictionary, font_size: int, color: Color) -> Label:
	var label := LocalizedLabel.new()
	label.set_loc_key(key, args)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_locale_changed(_locale: String) -> void:
	_build_view()


func _clear_view() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
