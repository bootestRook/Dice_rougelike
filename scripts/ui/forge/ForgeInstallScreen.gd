extends Control
class_name ForgeInstallScreen


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const ForgeService = preload("res://scripts/rules/forge/ForgeService.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RichTextHighlighter = preload("res://scripts/ui/RichTextHighlighter.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


var game_flow_controller: GameFlowController = null
var run_state: RunState = null
var piece: ForgePieceDef = null
var forge_service := ForgeService.new()
var selected_die_index: int = -1
var selected_face_index: int = -1
var target_label: RichTextLabel = null
var install_preview_label: RichTextLabel = null
var warning_label: RichTextLabel = null
var confirm_install_button: Button = null
var face_buttons: Dictionary = {}


func setup(new_game_flow_controller: GameFlowController, new_run_state: RunState, new_piece: ForgePieceDef) -> void:
	game_flow_controller = new_game_flow_controller
	run_state = new_run_state
	piece = new_piece


func _ready() -> void:
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

	var main_scroll := ScrollContainer.new()
	main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(main_scroll)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_scroll.add_child(root)

	root.add_child(_make_text_label(str(TranslationServer.translate(&"AUTO.TEXT.B6CF819FA0AC")), 28, Color(0.95, 0.92, 0.84)))
	root.add_child(_make_text_label(str(TranslationServer.translate(&"AUTO.TEXT.56B08BE6F8EA")), 16, Color(0.78, 0.86, 0.78)))
	root.add_child(_make_piece_info_panel())

	var dice_row := HBoxContainer.new()
	dice_row.add_theme_constant_override("separation", 10)
	root.add_child(dice_row)

	if run_state == null:
		root.add_child(_make_text_label(str(TranslationServer.translate(&"AUTO.TEXT.7C5B19F7D25E")), 16, Color(0.95, 0.78, 0.72)))
		return

	run_state.ensure_starting_dice()
	for die_index in range(run_state.dice.size()):
		dice_row.add_child(_make_die_panel(die_index))

	root.add_child(_make_install_preview_panel())
	_refresh_install_preview()


func _make_die_panel(die_index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(148, 450)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var die := run_state.dice[die_index]
	box.add_child(_make_text_label(str(TranslationServer.translate(&"AUTO.TEXT.5C0A3E2E5B09")) % [
		die_index + 1,
		DisplayNames.body_name(die.body_id),
		die.face_count,
	], 14, Color(0.92, 0.86, 0.68)))

	for face_index in range(die.faces.size()):
		var face_button := Button.new()
		face_button.text = _format_face_button(face_index, die.faces[face_index])
		face_button.toggle_mode = true
		face_button.custom_minimum_size = Vector2(132, 60)
		face_button.pressed.connect(_on_face_pressed.bind(die_index, face_index))
		face_buttons[_face_button_key(die_index, face_index)] = face_button
		box.add_child(face_button)

	return panel


func _make_piece_info_panel() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if piece == null:
		box.add_child(_make_text_label(str(TranslationServer.translate(&"AUTO.TEXT.0E689E7F4286")), 15, Color(0.86, 0.86, 0.8)))
		return box

	box.add_child(_make_text_label(piece.get_display_name(), 16, Color(0.96, 0.88, 0.62)))
	box.add_child(_make_rich_text_label(piece.get_description(), 15, Color(0.86, 0.86, 0.8)))
	box.add_child(_make_text_label(str(TranslationServer.translate(&"AUTO.TEXT.6DB5DF72B910")) % [piece.get_rarity_display_name()], 14, Color(0.72, 0.82, 0.92)))
	box.add_child(_make_text_label(str(TranslationServer.translate(&"AUTO.TEXT.ABAAFC3C7A71")) % [piece.get_tags_display_text()], 14, Color(0.78, 0.88, 0.72)))
	box.add_child(_make_rich_text_label(piece.get_effect_text(), 14, Color(0.84, 0.84, 0.78)))
	return box


func _format_face_button(face_index: int, face) -> String:
	return str(TranslationServer.translate(&"AUTO.TEXT.6F4FAC813D23")) % [face_index + 1, DisplayNames.face_summary(face).replace("\n", " / ")]


func _on_face_pressed(die_index: int, face_index: int) -> void:
	selected_die_index = die_index
	selected_face_index = face_index
	_refresh_face_button_selection()
	_refresh_install_preview()


func _install_on_face(die_index: int, face_index: int) -> void:
	if game_flow_controller == null:
		return
	game_flow_controller.install_pending_piece(die_index, face_index)


func _on_confirm_install_pressed() -> void:
	if selected_die_index < 0 or selected_face_index < 0:
		return
	_install_on_face(selected_die_index, selected_face_index)


func _needs_replace_confirmation(die_index: int, face_index: int) -> bool:
	if piece == null or run_state == null:
		return false
	if die_index < 0 or die_index >= run_state.dice.size():
		return false
	var die := run_state.dice[die_index]
	if die == null or face_index < 0 or face_index >= die.faces.size():
		return false
	if run_state.has_installed_piece_on_face(die_index, face_index):
		return true
	return forge_service.face_has_forge_effect(die.faces[face_index], face_index + 1)


func _make_install_preview_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 260)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	box.add_child(_make_text_label(str(TranslationServer.translate(&"AUTO.TEXT.9F0F3B3AEC00")), 18, Color(0.95, 0.88, 0.66)))

	target_label = _make_rich_text_label("", 15, Color(0.88, 0.88, 0.8))
	box.add_child(target_label)

	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 16)
	detail_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(detail_row)

	var preview_scroll := ScrollContainer.new()
	preview_scroll.custom_minimum_size = Vector2(520, 170)
	preview_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(preview_scroll)

	install_preview_label = _make_rich_text_label("", 14, Color(0.9, 0.88, 0.8))
	install_preview_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_scroll.add_child(install_preview_label)

	var warning_scroll := ScrollContainer.new()
	warning_scroll.custom_minimum_size = Vector2(360, 170)
	warning_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(warning_scroll)

	warning_label = _make_rich_text_label("", 14, Color(0.95, 0.78, 0.58))
	warning_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning_scroll.add_child(warning_label)

	confirm_install_button = Button.new()
	confirm_install_button.text = str(TranslationServer.translate(&"AUTO.TEXT.402052AA36CD"))
	confirm_install_button.custom_minimum_size = Vector2(160, 36)
	confirm_install_button.pressed.connect(_on_confirm_install_pressed)
	box.add_child(confirm_install_button)

	return panel


func _refresh_install_preview() -> void:
	if target_label == null or install_preview_label == null or warning_label == null:
		return

	if piece == null:
		_set_rich_text(target_label, str(TranslationServer.translate(&"AUTO.TEXT.4C9A59CFBD20")))
		_set_rich_text(install_preview_label, str(TranslationServer.translate(&"AUTO.TEXT.2E03906910DE")))
		_set_rich_text(warning_label, "")
		_update_confirm_button()
		return

	var piece_name := piece.get_display_name()
	if selected_die_index < 0 or selected_face_index < 0:
		_set_rich_text(target_label, str(TranslationServer.translate(&"AUTO.TEXT.97D68D60CCD1")) % [piece_name])
		_set_rich_text(install_preview_label, str(TranslationServer.translate(&"AUTO.TEXT.C44738A97251")))
		_set_rich_text(warning_label, str(TranslationServer.translate(&"AUTO.TEXT.C0469EBB56C8")))
		_update_confirm_button()
		return

	var face = _selected_face()
	_set_rich_text(target_label, str(TranslationServer.translate(&"AUTO.TEXT.A211180FE768")) % [
		piece_name,
		selected_die_index + 1,
		selected_face_index + 1,
	])
	_set_rich_text(install_preview_label, forge_service.get_install_preview_text(piece, face))

	var warning_text := forge_service.get_install_warning_text(piece, face)
	if warning_text == "":
		_set_rich_text(warning_label, str(TranslationServer.translate(&"AUTO.TEXT.D88E4EABA242")))
	else:
		_set_rich_text(warning_label, str(TranslationServer.translate(&"AUTO.TEXT.59C606C9E3EF")) % [warning_text])

	_update_confirm_button()


func _update_confirm_button() -> void:
	if confirm_install_button == null:
		return
	confirm_install_button.disabled = (
		game_flow_controller == null
		or piece == null
		or run_state == null
		or selected_die_index < 0
		or selected_face_index < 0
	)


func _selected_face():
	if run_state == null:
		return null
	if selected_die_index < 0 or selected_die_index >= run_state.dice.size():
		return null
	var die := run_state.dice[selected_die_index]
	if die == null or selected_face_index < 0 or selected_face_index >= die.faces.size():
		return null
	return die.faces[selected_face_index]


func _refresh_face_button_selection() -> void:
	for key in face_buttons.keys():
		var button = face_buttons[key]
		if button == null:
			continue
		button.button_pressed = key == _face_button_key(selected_die_index, selected_face_index)


func _face_button_key(die_index: int, face_index: int) -> String:
	return "%d:%d" % [die_index, face_index]


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


func _set_rich_text(label: RichTextLabel, text: String) -> void:
	RichTextHighlighter.set_rich_text(label, text)


func _clear_view() -> void:
	selected_die_index = -1
	selected_face_index = -1
	target_label = null
	install_preview_label = null
	warning_label = null
	confirm_install_button = null
	face_buttons.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
