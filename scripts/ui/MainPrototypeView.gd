extends Control
class_name MainPrototypeView


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")


const BATTLE_SCREEN_PATH := "res://scenes/battle/BattleScreen.tscn"
const FORGE_INSTALL_SCREEN_PATH := "res://scenes/forge/ForgeInstallScreen.tscn"
const REWARD_SCREEN_PATH := "res://scenes/reward/RewardScreen.tscn"
const RUN_RESULT_SCREEN_PATH := "res://scenes/run/RunResultScreen.tscn"


var game_flow_controller: GameFlowController = null
var current_view_id: StringName = &""


func _ready() -> void:
	_create_flow_controller()
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

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(layout)

	layout.add_child(_make_text_label("骰肉鸽原型", 30, Color(0.95, 0.92, 0.84)))
	layout.add_child(_make_text_label("投 6 颗骰子，选择、重投、结算，并在战斗后安装铸骰件改造骰面。", 16, Color(0.78, 0.78, 0.72)))
	layout.add_child(_make_start_button())
	layout.add_child(_make_text_panel("v0.1 试玩原型", "线性 5 场战斗\n非最终战胜利后获得铸骰件\n骰面效果已启用\n暂无地图 / 商店 / 首领"))
	layout.add_child(_make_text_panel("目标曲线", "1000 / 1150 / 1400 / 1750 / 2300"))
	layout.add_child(_make_rules_panel())
	layout.add_child(_make_dice_panel())
	layout.add_child(_make_text_panel("玩法预览", "选择 1 到 5 颗骰子后，可以重投所选，或直接结算所选。战斗后选择铸骰件并安装到任意骰面。"))


func _show_main_menu() -> void:
	_build_view()


func _make_start_button() -> Button:
	var button := Button.new()
	button.text = "开始一局"
	button.custom_minimum_size = Vector2(220, 44)
	button.pressed.connect(_on_start_battle_pressed)
	return button


func _make_rules_panel() -> Control:
	var config := BattleConfig.new()
	return _make_text_panel(
		"规则",
		"骰子：%d\n最多选择：%d\n每手重投：%d\n每场手数：%d\n第一场目标战力：1000" % [
			config.dice_count,
			config.max_selected_dice,
			config.rerolls_per_hand,
			config.hands_per_battle,
		]
	)


func _make_dice_panel() -> Control:
	var run_state := RunState.new()
	run_state.setup_new_run()

	var texts := PackedStringArray()
	for die_index in range(run_state.dice.size()):
		var die := run_state.dice[die_index]
		var pips := PackedStringArray()
		for face in die.faces:
			pips.append(str(face.pip))
		texts.append("骰子 %d：%s，%s，当前骰面：%s" % [
			die_index + 1,
			DisplayNames.body_name(die.body_id),
			"D%d" % [die.face_count],
			" / ".join(pips),
		])

	return _make_text_panel("初始骰组", "\n".join(texts))


func _make_text_panel(title: String, body: String) -> Control:
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
	panel.add_child(box)
	return box


func _make_text_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


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
	if state_id == &"main":
		_show_main_menu()


func _clear_screen() -> void:
	for child in get_children():
		if child != game_flow_controller:
			remove_child(child)
			child.queue_free()
