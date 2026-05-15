extends Control
class_name MainPrototypeView


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const LocalizedButton = preload("res://scripts/i18n/LocalizedButton.gd")
const LocalizedLabel = preload("res://scripts/i18n/LocalizedLabel.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


const BATTLE_SCREEN_PATH := "res://scenes/battle/BattleScreen.tscn"
const FORGE_INSTALL_SCREEN_PATH := "res://scenes/forge/ForgeInstallScreen.tscn"
const REWARD_SCREEN_PATH := "res://scenes/reward/RewardScreen.tscn"
const RUN_RESULT_SCREEN_PATH := "res://scenes/run/RunResultScreen.tscn"


var game_flow_controller: GameFlowController = null
var current_view_id: StringName = &""


func _ready() -> void:
	_create_flow_controller()
	if not Loc.locale_changed.is_connected(_on_locale_changed):
		Loc.locale_changed.connect(_on_locale_changed)
	_show_main_menu()


func _create_flow_controller() -> void:
	game_flow_controller = GameFlowController.new()
	add_child(game_flow_controller)
	game_flow_controller.battle_requested.connect(_on_battle_requested)
	game_flow_controller.reward_requested.connect(_on_reward_requested)
	game_flow_controller.forge_install_requested.connect(_on_forge_install_requested)
	game_flow_controller.run_result_requested.connect(_on_run_result_requested)
	game_flow_controller.flow_state_changed.connect(_on_flow_state_changed)


func _build_view() -> void:
	current_view_id = &"main"
	_clear_screen()

	var background := ColorRect.new()
	background.color = Color(0.08, 0.085, 0.075)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	layout.add_child(_make_loc_label(&"UI.MAIN.TITLE", {}, 30, Color(0.95, 0.92, 0.84)))
	layout.add_child(_make_loc_label(&"UI.MAIN.DESCRIPTION", {}, 16, Color(0.78, 0.78, 0.72)))
	layout.add_child(_make_start_button())
	layout.add_child(_make_panel(&"UI.MAIN.VERSION_TITLE", &"UI.MAIN.VERSION_BODY"))
	layout.add_child(_make_literal_panel("Target Curve", "1000 / 1150 / 1400 / 1750 / 2300"))
	layout.add_child(_make_rules_panel())
	layout.add_child(_make_dice_panel())
	layout.add_child(_make_combo_panel())


func _show_main_menu() -> void:
	_build_view()


func _make_start_button() -> Button:
	var button := LocalizedButton.new()
	button.set_loc_key(&"UI.MAIN.START")
	button.custom_minimum_size = Vector2(220, 44)
	button.pressed.connect(_on_start_battle_pressed)
	return button


func _make_rules_panel() -> Control:
	var config := BattleConfig.new()
	return _make_panel(&"UI.MAIN.RULES_TITLE", &"UI.MAIN.RULES_BODY", {
		"dice": config.dice_count,
		"max_selected": config.max_selected_dice,
		"rerolls": config.rerolls_per_hand,
		"hands": config.hands_per_battle,
		"target": config.target_score,
	})


func _make_dice_panel() -> Control:
	var run_state := RunState.new()
	run_state.setup_new_run()

	var texts := PackedStringArray()
	for die_index in range(run_state.dice.size()):
		var die := run_state.dice[die_index]
		var pips := PackedStringArray()
		for face in die.faces:
			pips.append(str(face.pip))
		texts.append(Loc.t(&"UI.MAIN.DIE_LINE", {
			"die": die_index + 1,
			"pips": ", ".join(pips),
		}))

	return _make_text_panel(&"UI.MAIN.INITIAL_DICE_TITLE", "\n".join(texts))


func _make_combo_panel() -> Control:
	return _make_panel(&"UI.MAIN.PREVIEW_TITLE", &"UI.MAIN.PREVIEW_BODY")


func _make_panel(title_key: StringName, body_key: StringName, body_args: Dictionary = {}) -> Control:
	var panel := _make_panel_container()
	var box := _make_panel_box(panel)

	box.add_child(_make_loc_label(title_key, {}, 18, Color(0.92, 0.86, 0.68)))
	box.add_child(_make_loc_label(body_key, body_args, 15, Color(0.86, 0.86, 0.8)))
	return panel


func _make_text_panel(title_key: StringName, body: String) -> Control:
	var panel := _make_panel_container()
	var box := _make_panel_box(panel)

	box.add_child(_make_loc_label(title_key, {}, 18, Color(0.92, 0.86, 0.68)))
	box.add_child(_make_text_label(body, 15, Color(0.86, 0.86, 0.8)))
	return panel


func _make_literal_panel(title: String, body: String) -> Control:
	var panel := _make_panel_container()
	var box := _make_panel_box(panel)

	box.add_child(_make_text_label(title, 18, Color(0.92, 0.86, 0.68)))
	box.add_child(_make_text_label(body, 15, Color(0.86, 0.86, 0.8)))
	return panel


func _make_panel_container() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 92)
	return panel


func _make_panel_box(panel: PanelContainer) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_theme_constant_override("margin_left", 14)
	box.add_theme_constant_override("margin_top", 12)
	box.add_theme_constant_override("margin_right", 14)
	box.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(box)
	return box


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


func _on_start_battle_pressed() -> void:
	game_flow_controller.start_new_run()


func _on_battle_requested(requested_run_state: RunState) -> void:
	current_view_id = &"battle"
	_clear_screen()
	var battle_screen = load(BATTLE_SCREEN_PATH).instantiate()
	battle_screen.setup(game_flow_controller, requested_run_state)
	add_child(battle_screen)


func _on_reward_requested(choices: Array) -> void:
	current_view_id = &"reward"
	_clear_screen()
	var reward_screen = load(REWARD_SCREEN_PATH).instantiate()
	reward_screen.setup(game_flow_controller, choices)
	add_child(reward_screen)


func _on_forge_install_requested(piece) -> void:
	current_view_id = &"forge"
	_clear_screen()
	var forge_screen = load(FORGE_INSTALL_SCREEN_PATH).instantiate()
	forge_screen.setup(game_flow_controller, game_flow_controller.get_run_state(), piece)
	add_child(forge_screen)


func _on_run_result_requested(result_run_state: RunState) -> void:
	current_view_id = &"run_result"
	_clear_screen()
	var run_result_screen = load(RUN_RESULT_SCREEN_PATH).instantiate()
	run_result_screen.setup(game_flow_controller, result_run_state)
	add_child(run_result_screen)


func _on_flow_state_changed(state_id: StringName) -> void:
	if state_id == &"defeat":
		_show_defeat_screen()
	elif state_id == &"main":
		_show_main_menu()


func _show_defeat_screen() -> void:
	current_view_id = &"defeat"
	_clear_screen()

	var background := ColorRect.new()
	background.color = Color(0.075, 0.055, 0.055)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)
	layout.add_child(_make_loc_label(&"UI.MAIN.DEFEAT_TITLE", {}, 30, Color(0.95, 0.82, 0.78)))
	layout.add_child(_make_loc_label(&"UI.MAIN.DEFEAT_BODY", {}, 16, Color(0.86, 0.82, 0.78)))

	var button := LocalizedButton.new()
	button.set_loc_key(&"UI.MAIN.BACK_TO_MAIN")
	button.custom_minimum_size = Vector2(220, 44)
	button.pressed.connect(_show_main_menu)
	layout.add_child(button)


func _on_locale_changed(_locale: String) -> void:
	if current_view_id == &"main":
		_build_view()
	elif current_view_id == &"defeat":
		_show_defeat_screen()


func _clear_screen() -> void:
	for child in get_children():
		if child != game_flow_controller:
			remove_child(child)
			child.queue_free()
