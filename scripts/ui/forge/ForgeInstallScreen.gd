extends Control
class_name ForgeInstallScreen


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const ForgeService = preload("res://scripts/rules/forge/ForgeService.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


var game_flow_controller: GameFlowController = null
var run_state: RunState = null
var piece: ForgePieceDef = null
var forge_service := ForgeService.new()
var selected_die_index: int = -1
var selected_face_index: int = -1
var target_label: Label = null
var install_preview_label: Label = null
var warning_label: Label = null
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

	root.add_child(_make_text_label("安装铸骰件", 28, Color(0.95, 0.92, 0.84)))
	root.add_child(_make_text_label("选择一个骰面", 16, Color(0.78, 0.86, 0.78)))
	root.add_child(_make_text_label(_piece_text(), 15, Color(0.86, 0.86, 0.8)))

	var dice_row := HBoxContainer.new()
	dice_row.add_theme_constant_override("separation", 10)
	root.add_child(dice_row)

	if run_state == null:
		root.add_child(_make_text_label("没有当前局状态。", 16, Color(0.95, 0.78, 0.72)))
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
	box.add_child(_make_text_label("骰子 %d\n骰胚：%s\n面数：D%d" % [
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


func _piece_text() -> String:
	if piece == null:
		return "尚未选择铸骰件。"
	return piece.get_display_text()


func _format_face_button(face_index: int, face) -> String:
	return "面 %d：%s" % [face_index + 1, DisplayNames.face_summary(face).replace("\n", " / ")]


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

	box.add_child(_make_text_label("安装预览", 18, Color(0.95, 0.88, 0.66)))

	target_label = _make_text_label("", 15, Color(0.88, 0.88, 0.8))
	box.add_child(target_label)

	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 16)
	detail_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(detail_row)

	var preview_scroll := ScrollContainer.new()
	preview_scroll.custom_minimum_size = Vector2(520, 170)
	preview_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(preview_scroll)

	install_preview_label = _make_text_label("", 14, Color(0.9, 0.88, 0.8))
	install_preview_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_scroll.add_child(install_preview_label)

	var warning_scroll := ScrollContainer.new()
	warning_scroll.custom_minimum_size = Vector2(360, 170)
	warning_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(warning_scroll)

	warning_label = _make_text_label("", 14, Color(0.95, 0.78, 0.58))
	warning_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning_scroll.add_child(warning_label)

	confirm_install_button = Button.new()
	confirm_install_button.text = "确认安装"
	confirm_install_button.custom_minimum_size = Vector2(160, 36)
	confirm_install_button.pressed.connect(_on_confirm_install_pressed)
	box.add_child(confirm_install_button)

	return panel


func _refresh_install_preview() -> void:
	if target_label == null or install_preview_label == null or warning_label == null:
		return

	if piece == null:
		target_label.text = "当前铸骰件：无"
		install_preview_label.text = "请先选择铸骰件。"
		warning_label.text = ""
		_update_confirm_button()
		return

	var piece_name := piece.get_display_name()
	if selected_die_index < 0 or selected_face_index < 0:
		target_label.text = "当前铸骰件：%s\n安装目标：未选择" % [piece_name]
		install_preview_label.text = "点击一个骰面后，会在这里显示安装前和安装后。"
		warning_label.text = "替换提示：\n未选择目标。"
		_update_confirm_button()
		return

	var face = _selected_face()
	target_label.text = "当前铸骰件：%s\n安装目标：骰子 %d / 面 %d" % [
		piece_name,
		selected_die_index + 1,
		selected_face_index + 1,
	]
	install_preview_label.text = forge_service.get_install_preview_text(piece, face)

	var warning_text := forge_service.get_install_warning_text(piece, face)
	if warning_text == "":
		warning_label.text = "替换提示：\n不会替换已有面饰或印记。"
	else:
		warning_label.text = "注意：\n%s" % [warning_text]

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
