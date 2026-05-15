extends Control
class_name MainPrototypeView


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


const BATTLE_SCREEN_PATH := "res://scenes/battle/BattleScreen.tscn"


func _ready() -> void:
	_build_view()


func _build_view() -> void:
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

	layout.add_child(_make_label("Dice Roguelike Prototype", 30, Color(0.95, 0.92, 0.84)))
	layout.add_child(_make_label("Core loop skeleton: 6 D6, reroll, select, score, forge piece reward.", 16, Color(0.78, 0.78, 0.72)))
	layout.add_child(_make_start_button())
	layout.add_child(_make_rules_panel())
	layout.add_child(_make_dice_panel())
	layout.add_child(_make_combo_panel())


func _make_start_button() -> Button:
	var button := Button.new()
	button.text = "Start Battle"
	button.custom_minimum_size = Vector2(220, 44)
	button.pressed.connect(_on_start_battle_pressed)
	return button


func _make_rules_panel() -> Control:
	var config := BattleConfig.new()
	var text := "Battle rules: dice=%d  max selected=%d  rerolls=%d  hands=%d  target=%d" % [
		config.dice_count,
		config.max_selected_dice,
		config.rerolls_per_hand,
		config.hands_per_battle,
		config.target_score,
	]
	return _make_panel("Rules", text)


func _make_dice_panel() -> Control:
	var run_state := RunState.new()
	run_state.create_default_loadout()

	var texts := PackedStringArray()
	for die in run_state.dice:
		var pips := PackedStringArray()
		for face in die.faces:
			pips.append(str(face.pip))
		texts.append("%s: [%s]" % [str(die.id), ", ".join(pips)])

	return _make_panel("Starting Dice", "\n".join(texts))


func _make_combo_panel() -> Control:
	var text := "Use Start Battle to roll, lock, reroll, select, and score one normal battle."
	return _make_panel("Rule Preview", text)


func _make_panel(title: String, body: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 92)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_theme_constant_override("margin_left", 14)
	box.add_theme_constant_override("margin_top", 12)
	box.add_theme_constant_override("margin_right", 14)
	box.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(box)

	box.add_child(_make_label(title, 18, Color(0.92, 0.86, 0.68)))
	box.add_child(_make_label(body, 15, Color(0.86, 0.86, 0.8)))
	return panel


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_start_battle_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCREEN_PATH)
