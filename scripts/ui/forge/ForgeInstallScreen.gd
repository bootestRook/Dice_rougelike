extends Control
class_name ForgeInstallScreen


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocalizedLabel = preload("res://scripts/i18n/LocalizedLabel.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


var game_flow_controller: GameFlowController = null
var run_state: RunState = null
var piece: ForgePieceDef = null


func setup(new_game_flow_controller: GameFlowController, new_run_state: RunState, new_piece: ForgePieceDef) -> void:
	game_flow_controller = new_game_flow_controller
	run_state = new_run_state
	piece = new_piece


func _ready() -> void:
	if not Loc.locale_changed.is_connected(_on_locale_changed):
		Loc.locale_changed.connect(_on_locale_changed)
	_build_view()


func _build_view() -> void:
	_clear_view()

	var background := ColorRect.new()
	background.color = Color(0.06, 0.075, 0.07)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	root.add_child(_make_loc_label(&"UI.INSTALL.TITLE", {}, 28, Color(0.95, 0.92, 0.84)))
	root.add_child(_make_text_label(_piece_text(), 15, Color(0.86, 0.86, 0.8)))

	var dice_row := HBoxContainer.new()
	dice_row.add_theme_constant_override("separation", 10)
	root.add_child(dice_row)

	if run_state == null:
		root.add_child(_make_loc_label(&"UI.INSTALL.NO_RUN", {}, 16, Color(0.95, 0.78, 0.72)))
		return

	run_state.ensure_starting_dice()
	for die_index in range(run_state.dice.size()):
		dice_row.add_child(_make_die_panel(die_index))


func _make_die_panel(die_index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(138, 420)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_theme_constant_override("margin_left", 8)
	box.add_theme_constant_override("margin_top", 8)
	box.add_theme_constant_override("margin_right", 8)
	box.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(box)

	var die := run_state.dice[die_index]
	box.add_child(_make_loc_label(&"UI.INSTALL.DIE", {"die": die_index + 1}, 14, Color(0.92, 0.86, 0.68)))

	for face_index in range(die.faces.size()):
		var face_button := Button.new()
		face_button.text = _format_face_button(face_index, die.faces[face_index])
		face_button.custom_minimum_size = Vector2(122, 54)
		face_button.pressed.connect(_on_face_pressed.bind(die_index, face_index))
		box.add_child(face_button)

	return panel


func _piece_text() -> String:
	if piece == null:
		return Loc.t(&"UI.INSTALL.NO_PIECE")
	return piece.get_display_text()


func _format_face_button(face_index: int, face) -> String:
	var lines := PackedStringArray()
	lines.append(Loc.t(&"UI.INSTALL.FACE", {
		"face": face_index + 1,
		"pip": face.pip,
	}))
	if not _is_none_id(face.material_id):
		lines.append(Loc.t(&"UI.INSTALL.MATERIAL", {"material": Loc.t(LocKeys.material_name_key(face.material_id))}))
	if not _is_none_id(face.mark_id):
		lines.append(Loc.t(&"UI.INSTALL.IMPRINT", {"imprint": Loc.t(LocKeys.imprint_name_key(face.mark_id))}))
	if not _is_none_id(face.rune_id):
		lines.append(Loc.t(&"UI.INSTALL.RUNE", {"rune": Loc.t(LocKeys.rune_name_key(face.rune_id))}))
	if face.level > 1:
		lines.append(Loc.t(&"UI.INSTALL.LEVEL", {"level": face.level}))
	return "\n".join(lines)


func _on_face_pressed(die_index: int, face_index: int) -> void:
	if game_flow_controller == null:
		return
	game_flow_controller.install_pending_piece(die_index, face_index)


func _make_loc_label(key: StringName, args: Dictionary, font_size: int, color: Color) -> Label:
	var label := LocalizedLabel.new()
	label.set_loc_key(key, args)
	_apply_label_theme(label, font_size, color)
	return label


func _make_text_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	_apply_label_theme(label, font_size, color)
	return label


func _apply_label_theme(label: Label, font_size: int, color: Color) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


func _is_none_id(value: StringName) -> bool:
	return value == &"" or value == &"none"


func _on_locale_changed(_locale: String) -> void:
	_build_view()


func _clear_view() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
