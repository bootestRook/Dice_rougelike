extends Control
class_name BattleScreen


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


var controller: BattleController = null
var score_label: Label = null
var hand_label: Label = null
var reroll_label: Label = null
var status_label: Label = null
var log_label: Label = null
var reroll_button: Button = null
var score_button: Button = null
var die_buttons: Array[Button] = []
var lock_buttons: Array[Button] = []


func _ready() -> void:
	_build_view()
	_create_controller()
	controller.start_battle()


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

	root.add_child(_make_label("Battle", 28))

	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 24)
	score_label = _make_label("Score: 0 / 0", 18)
	hand_label = _make_label("Hand: 0 / 0", 18)
	reroll_label = _make_label("Rerolls: 0", 18)
	info_row.add_child(score_label)
	info_row.add_child(hand_label)
	info_row.add_child(reroll_label)
	root.add_child(info_row)

	var dice_row := HBoxContainer.new()
	dice_row.add_theme_constant_override("separation", 10)
	root.add_child(dice_row)

	for die_index in range(6):
		var die_box := VBoxContainer.new()
		die_box.custom_minimum_size = Vector2(128, 112)
		die_box.add_theme_constant_override("separation", 6)

		var die_button := Button.new()
		die_button.text = "-"
		die_button.custom_minimum_size = Vector2(128, 72)
		die_button.pressed.connect(_on_die_pressed.bind(die_index))
		die_buttons.append(die_button)
		die_box.add_child(die_button)

		var lock_button := Button.new()
		lock_button.text = "Lock"
		lock_button.custom_minimum_size = Vector2(128, 32)
		lock_button.pressed.connect(_on_lock_pressed.bind(die_index))
		lock_buttons.append(lock_button)
		die_box.add_child(lock_button)

		dice_row.add_child(die_box)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 12)
	reroll_button = Button.new()
	reroll_button.text = "Reroll"
	reroll_button.pressed.connect(_on_reroll_pressed)
	score_button = Button.new()
	score_button.text = "Score Selected"
	score_button.pressed.connect(_on_score_pressed)
	action_row.add_child(reroll_button)
	action_row.add_child(score_button)
	root.add_child(action_row)

	status_label = _make_label("Ready", 18)
	root.add_child(status_label)

	log_label = _make_label("Last score log will appear here.", 15)
	log_label.custom_minimum_size = Vector2(0, 180)
	root.add_child(log_label)


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


func _on_battle_started() -> void:
	status_label.text = "Battle started."
	log_label.text = "Select 1 to 5 dice, then score. Lock dice before rerolling."


func _on_hand_started(hand_index: int) -> void:
	hand_label.text = "Hand: %d / %d" % [hand_index + 1, controller.get_hands_per_battle()]
	status_label.text = "Choose dice to score, or lock and reroll."
	_update_buttons()


func _on_dice_changed(rolls: Array) -> void:
	for index in range(die_buttons.size()):
		if index >= rolls.size():
			die_buttons[index].text = "-"
			lock_buttons[index].text = "Lock"
			continue

		var rolled_face = rolls[index]
		var pip_text := "-"
		if rolled_face.face != null:
			pip_text = str(rolled_face.face.pip)

		var selected_text := "Selected" if rolled_face.selected else "Not selected"
		var locked_text := "Locked" if rolled_face.locked else "Unlocked"
		die_buttons[index].text = "Pip %s\n%s\n%s" % [pip_text, selected_text, locked_text]
		lock_buttons[index].text = "Unlock" if rolled_face.locked else "Lock"

	_update_buttons()


func _on_rerolls_changed(rerolls_left: int) -> void:
	reroll_label.text = "Rerolls: %d" % [rerolls_left]
	_update_buttons()


func _on_score_changed(total_score: int, target_score: int) -> void:
	score_label.text = "Score: %d / %d" % [total_score, target_score]


func _on_selection_changed(selected_count: int) -> void:
	status_label.text = "Selected: %d / 5" % [selected_count]
	_update_buttons()


func _on_hand_scored(result: ScoreResult) -> void:
	var lines := PackedStringArray()
	for entry in result.logs:
		lines.append(entry.text)

	log_label.text = "\n".join(lines)


func _on_battle_won() -> void:
	status_label.text = "Victory."
	_update_buttons()


func _on_battle_lost() -> void:
	status_label.text = "Defeat."
	_update_buttons()


func _on_phase_changed(phase: int) -> void:
	if phase == BattleController.BattlePhase.VICTORY or phase == BattleController.BattlePhase.DEFEAT:
		_update_buttons()


func _on_die_pressed(index: int) -> void:
	controller.toggle_select(index)


func _on_lock_pressed(index: int) -> void:
	controller.toggle_lock(index)


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

	for die_button in die_buttons:
		die_button.disabled = not dice_enabled
	for lock_button in lock_buttons:
		lock_button.disabled = not dice_enabled


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
	return label
