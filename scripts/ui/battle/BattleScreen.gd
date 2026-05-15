extends Control
class_name BattleScreen


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocalizedButton = preload("res://scripts/i18n/LocalizedButton.gd")
const LocalizedLabel = preload("res://scripts/i18n/LocalizedLabel.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


var controller: BattleController = null
var game_flow_controller: GameFlowController = null
var run_state: RunState = null
var score_label: Label = null
var hand_label: Label = null
var reroll_label: Label = null
var status_label: Label = null
var debug_label: Label = null
var preview_label: Label = null
var log_label: Label = null
var reroll_button: Button = null
var reroll_count_label: Label = null
var score_button: Button = null
var die_buttons: Array[Button] = []
var status_key: StringName = &"UI.BATTLE.STATUS_READY"
var status_args: Dictionary = {}
var log_key: StringName = &"UI.BATTLE.LOG_EMPTY"
var log_args: Dictionary = {}
var last_score_result: ScoreResult = null


func setup(new_game_flow_controller: GameFlowController = null, new_run_state: RunState = null) -> void:
	game_flow_controller = new_game_flow_controller
	run_state = new_run_state


func _ready() -> void:
	if not Loc.locale_changed.is_connected(_on_locale_changed):
		Loc.locale_changed.connect(_on_locale_changed)
	_build_view()
	_create_controller()
	controller.start_battle(null, run_state)


func _build_view() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.075, 0.07)
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
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	root.add_child(_make_loc_label(&"UI.BATTLE.TITLE", {}, 28))

	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 24)
	score_label = _make_label(18)
	hand_label = _make_label(18)
	reroll_label = _make_label(18)
	score_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	hand_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	reroll_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	score_label.custom_minimum_size = Vector2(220, 0)
	hand_label.custom_minimum_size = Vector2(170, 0)
	reroll_label.custom_minimum_size = Vector2(140, 0)
	info_row.add_child(score_label)
	info_row.add_child(hand_label)
	info_row.add_child(reroll_label)
	root.add_child(info_row)

	var dice_row := HBoxContainer.new()
	dice_row.add_theme_constant_override("separation", 10)
	root.add_child(dice_row)

	for die_index in range(6):
		var die_button := Button.new()
		die_button.text = "-"
		die_button.toggle_mode = true
		die_button.custom_minimum_size = Vector2(132, 88)
		die_button.pressed.connect(_on_die_pressed.bind(die_index))
		die_buttons.append(die_button)
		dice_row.add_child(die_button)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 12)
	reroll_button = LocalizedButton.new()
	reroll_button.set_loc_key(&"UI.BATTLE.REROLL")
	reroll_button.pressed.connect(_on_reroll_pressed)
	reroll_count_label = _make_label(16)
	reroll_count_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	reroll_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reroll_count_label.custom_minimum_size = Vector2(72, 0)
	score_button = LocalizedButton.new()
	score_button.set_loc_key(&"UI.BATTLE.SCORE_SELECTED")
	score_button.pressed.connect(_on_score_pressed)
	action_row.add_child(reroll_button)
	action_row.add_child(reroll_count_label)
	action_row.add_child(score_button)
	root.add_child(action_row)

	status_label = _make_label(18)
	root.add_child(status_label)

	debug_label = _make_label(13)
	root.add_child(debug_label)

	preview_label = _make_label(15)
	preview_label.custom_minimum_size = Vector2(0, 130)
	root.add_child(preview_label)

	log_label = _make_label(14)
	log_label.custom_minimum_size = Vector2(0, 360)
	root.add_child(log_label)
	_refresh_localized_text()


func _create_controller() -> void:
	controller = BattleController.new()
	add_child(controller)
	controller.battle_started.connect(_on_battle_started)
	controller.hand_started.connect(_on_hand_started)
	controller.dice_changed.connect(_on_dice_changed)
	controller.rerolls_changed.connect(_on_rerolls_changed)
	controller.score_changed.connect(_on_score_changed)
	controller.selection_changed.connect(_on_selection_changed)
	controller.hand_scored.connect(_on_hand_scored)
	controller.battle_won.connect(_on_battle_won)
	controller.battle_lost.connect(_on_battle_lost)
	controller.phase_changed.connect(_on_phase_changed)
	controller.score_preview_changed.connect(_on_score_preview_changed)


func _on_battle_started() -> void:
	last_score_result = null
	_set_status(&"UI.BATTLE.STATUS_STARTED")
	_set_log_message(&"UI.BATTLE.LOG_HINT")
	_refresh_preview(null)
	_refresh_debug()


func _on_hand_started(hand_index: int) -> void:
	hand_label.text = Loc.t(&"UI.BATTLE.HAND", {
		"hand": hand_index + 1,
		"hands": controller.get_hands_per_battle(),
	})
	_set_status(&"UI.BATTLE.STATUS_CHOOSE")
	_update_buttons()
	_refresh_preview(null)
	_refresh_debug()


func _on_dice_changed(rolls: Array) -> void:
	for index in range(die_buttons.size()):
		if index >= rolls.size():
			die_buttons[index].text = "-"
			die_buttons[index].button_pressed = false
			_apply_die_button_state(die_buttons[index], false)
			continue

		var rolled_face = rolls[index]
		var face_text := "-"
		if rolled_face.face != null:
			face_text = _format_face_text(rolled_face.face)

		var selected_text := Loc.t(&"UI.BATTLE.SELECTED") if rolled_face.selected else Loc.t(&"UI.BATTLE.UNSELECTED")
		die_buttons[index].text = "%s\n%s" % [face_text, selected_text]
		die_buttons[index].button_pressed = rolled_face.selected
		_apply_die_button_state(die_buttons[index], rolled_face.selected)

	_update_buttons()
	_refresh_debug()


func _on_rerolls_changed(rerolls_left: int) -> void:
	var total_rerolls := controller.get_rerolls_per_hand() if controller != null else 0
	var reroll_count_text := _format_reroll_count(rerolls_left, total_rerolls)
	reroll_label.text = Loc.t(&"UI.BATTLE.REROLL_LEFT", {"rerolls": reroll_count_text})
	if reroll_count_label != null:
		reroll_count_label.text = reroll_count_text
	_update_buttons()
	_refresh_debug()


func _on_score_changed(total_score: int, target_score: int) -> void:
	score_label.text = Loc.t(&"UI.BATTLE.SCORE", {
		"score": total_score,
		"target": target_score,
	})
	_refresh_debug()


func _on_selection_changed(selected_count: int) -> void:
	_set_status(&"UI.BATTLE.SELECTED_COUNT", {
		"count": selected_count,
		"max": controller.get_max_selected_dice() if controller != null else 5,
	})
	_update_buttons()
	_refresh_debug()


func _on_hand_scored(result: ScoreResult) -> void:
	last_score_result = result
	log_key = &""
	log_args.clear()
	_refresh_log()
	if game_flow_controller != null:
		game_flow_controller.record_hand_score(result.final_score)
	_refresh_debug()


func _on_battle_won() -> void:
	_set_status(&"UI.BATTLE.VICTORY")
	_update_buttons()
	if game_flow_controller != null:
		call_deferred("_notify_battle_won")


func _on_battle_lost() -> void:
	_set_status(&"UI.BATTLE.DEFEAT")
	_update_buttons()
	if game_flow_controller != null:
		call_deferred("_notify_battle_lost")


func _on_phase_changed(phase: int) -> void:
	if phase == BattleController.BattlePhase.VICTORY or phase == BattleController.BattlePhase.DEFEAT:
		_update_buttons()
	_refresh_debug()


func _on_score_preview_changed(result: ScoreResult) -> void:
	_refresh_preview(result)


func _on_die_pressed(index: int) -> void:
	controller.toggle_select(index)


func _on_reroll_pressed() -> void:
	controller.reroll()


func _on_score_pressed() -> void:
	controller.score_selected()


func _update_buttons() -> void:
	if controller == null:
		return

	reroll_button.disabled = not controller.can_reroll()
	score_button.disabled = not controller.can_score()
	var dice_enabled := controller.get_phase() == BattleController.BattlePhase.WAITING_ACTION
	var rolls := controller.get_current_rolls()
	var selected_count := 0
	for roll in rolls:
		if roll.selected:
			selected_count += 1
	var max_selected := controller.get_max_selected_dice()

	for index in range(die_buttons.size()):
		var roll_exists := index < rolls.size()
		var locked_by_limit := (
			dice_enabled
			and roll_exists
			and max_selected > 0
			and selected_count >= max_selected
			and not rolls[index].selected
		)
		die_buttons[index].disabled = not dice_enabled or not roll_exists or locked_by_limit


func _make_loc_label(key: StringName, args: Dictionary, font_size: int) -> Label:
	var label := LocalizedLabel.new()
	label.set_loc_key(key, args)
	_apply_label_theme(label, font_size)
	return label


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	_apply_label_theme(label, font_size)
	return label


func _apply_label_theme(label: Label, font_size: int) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))


func _apply_die_button_state(button: Button, selected: bool) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.95, 0.94, 0.88))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.46, 0.4))
	button.add_theme_stylebox_override("normal", _make_die_style(selected, false))
	button.add_theme_stylebox_override("hover", _make_die_style(selected, true))
	button.add_theme_stylebox_override("pressed", _make_die_style(true, true))
	button.add_theme_stylebox_override("focus", _make_die_style(true, true))
	button.add_theme_stylebox_override("disabled", _make_die_style(selected, false))


func _make_die_style(selected: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.26, 0.2, 0.08) if selected else Color(0.11, 0.115, 0.105)
	if hover and not selected:
		style.bg_color = Color(0.16, 0.16, 0.14)
	style.border_color = Color(0.95, 0.72, 0.22) if selected else Color(0.18, 0.18, 0.16)
	style.set_border_width_all(2 if selected else 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _notify_battle_won() -> void:
	game_flow_controller.on_battle_won()


func _notify_battle_lost() -> void:
	game_flow_controller.on_battle_lost()


func _format_face_text(face) -> String:
	var lines := PackedStringArray()
	lines.append(str(face.pip))
	if not _is_none_id(face.material_id):
		lines.append(Loc.t(&"UI.FACE.MATERIAL", {"material": Loc.t(LocKeys.material_name_key(face.material_id))}))
	if not _is_none_id(face.mark_id):
		lines.append(Loc.t(&"UI.FACE.IMPRINT", {"imprint": Loc.t(LocKeys.imprint_name_key(face.mark_id))}))
	if not _is_none_id(face.rune_id):
		lines.append(Loc.t(&"UI.FACE.RUNE", {"rune": Loc.t(LocKeys.rune_name_key(face.rune_id))}))
	if face.level > 1:
		lines.append(Loc.t(&"UI.FACE.LEVEL", {"level": face.level}))
	return "\n".join(lines)


func _is_none_id(value: StringName) -> bool:
	return value == &"" or value == &"none"


func _set_status(key: StringName, args: Dictionary = {}) -> void:
	status_key = key
	status_args = args.duplicate()
	status_label.text = Loc.t(status_key, status_args)


func _set_log_message(key: StringName, args: Dictionary = {}) -> void:
	last_score_result = null
	log_key = key
	log_args = args.duplicate()
	_refresh_log()


func _refresh_localized_text() -> void:
	if controller != null:
		_on_score_changed(controller.get_total_score(), controller.get_target_score())
		_on_rerolls_changed(controller.get_rerolls_left())
		hand_label.text = Loc.t(&"UI.BATTLE.HAND", {
			"hand": controller.get_current_hand_number(),
			"hands": controller.get_hands_per_battle(),
		})
		_on_dice_changed(controller.get_current_rolls())
	else:
		score_label.text = Loc.t(&"UI.BATTLE.SCORE", {"score": 0, "target": 0})
		hand_label.text = Loc.t(&"UI.BATTLE.HAND", {"hand": 0, "hands": 0})
		var reroll_count_text := _format_reroll_count(0, 0)
		reroll_label.text = Loc.t(&"UI.BATTLE.REROLL_LEFT", {"rerolls": reroll_count_text})
		if reroll_count_label != null:
			reroll_count_label.text = reroll_count_text

	status_label.text = Loc.t(status_key, status_args)
	_refresh_preview(controller.preview_selected_score() if controller != null else null)
	_refresh_debug()
	_refresh_log()


func _refresh_log() -> void:
	if last_score_result != null:
		var lines := PackedStringArray()
		lines.append(Loc.t(&"UI.BATTLE.LOG_LAST_TITLE"))
		lines.append(last_score_result.get_summary_text())
		lines.append("")
		lines.append(Loc.t(&"UI.BATTLE.LOG_SECTION_TITLE"))
		for entry in last_score_result.logs:
			lines.append(entry.get_text())
		log_label.text = "\n".join(lines)
		return

	if log_key == &"":
		log_label.text = ""
		return

	log_label.text = Loc.t(log_key, log_args)


func _refresh_preview(result: ScoreResult) -> void:
	if preview_label == null:
		return
	if result == null:
		preview_label.text = Loc.t(&"UI.BATTLE.PREVIEW_EMPTY")
		return

	preview_label.text = Loc.t(&"UI.BATTLE.PREVIEW", {"summary": result.get_summary_text()})


func _refresh_debug() -> void:
	if debug_label == null:
		return
	if controller == null:
		debug_label.text = ""
		return

	var selected_count := 0
	for roll in controller.get_current_rolls():
		if roll.selected:
			selected_count += 1

	var battle_number := 1
	var max_battles := 5
	if run_state != null:
		battle_number = run_state.battle_index + 1
		max_battles = run_state.max_battles

	debug_label.text = Loc.t(&"UI.BATTLE.DEBUG_INFO", {
		"battle": battle_number,
		"max_battles": max_battles,
		"target": controller.get_target_score(),
		"hand": controller.get_current_hand_number(),
		"hands": controller.get_hands_per_battle(),
		"rerolls": controller.get_rerolls_left(),
		"selected": selected_count,
		"phase": Loc.t(LocKeys.battle_phase_key(StringName(controller.get_phase_name()))),
	})


func _format_reroll_count(rerolls_left: int, total_rerolls: int) -> String:
	return "%d / %d" % [rerolls_left, total_rerolls]


func _on_locale_changed(_locale: String) -> void:
	_refresh_localized_text()
