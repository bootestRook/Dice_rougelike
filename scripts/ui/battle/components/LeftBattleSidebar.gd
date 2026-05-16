extends PanelContainer
class_name LeftBattleSidebar


const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")


signal info_pressed()
signal options_pressed()


var style_config: BattleUiStyleConfig = null

@onready var margin: MarginContainer = %SidebarMargin
@onready var rows: VBoxContainer = %Rows
@onready var target_score_panel: PanelContainer = %TargetScorePanel
@onready var current_score_panel: PanelContainer = %CurrentScorePanel
@onready var core_combo_panel: PanelContainer = %CoreComboPanel
@onready var formula_panel: PanelContainer = %ScoreFormulaPanel
@onready var action_panel: PanelContainer = %ActionButtonPanel
@onready var resource_panel: PanelContainer = %BattleResourcePanel
@onready var target_title: Label = %TargetTitle
@onready var current_title: Label = %CurrentTitle
@onready var combo_title: Label = %ComboTitle
@onready var formula_title: Label = %FormulaTitle
@onready var target_value: Label = %TargetValue
@onready var reward_label: Label = %RewardLabel
@onready var current_score_value: Label = %CurrentScoreValue
@onready var combo_value: Label = %ComboValue
@onready var formula_value: Label = %FormulaValue
@onready var info_button: Button = %InfoButton
@onready var options_button: Button = %OptionsButton
@onready var hand_value: Label = %HandValue
@onready var reroll_value: Label = %RerollValue
@onready var battle_value: Label = %BattleValue
@onready var max_battle_value: Label = %MaxBattleValue
@onready var money_value: Label = %MoneyValue
@onready var target_icon: TextureRect = %TargetIcon
@onready var current_icon: TextureRect = %CurrentIcon


func _ready() -> void:
	info_button.pressed.connect(func() -> void: info_pressed.emit())
	options_button.pressed.connect(func() -> void: options_pressed.emit())
	_apply_style()


func setup_style(new_style_config: BattleUiStyleConfig) -> void:
	style_config = new_style_config
	if is_node_ready():
		_apply_style()


func render(state: BattleHudState) -> void:
	if state == null:
		return

	target_value.text = _format_number(state.target_score)
	reward_label.text = "达成以获得 %s" % [state.reward_level]
	current_score_value.text = _format_number(state.current_score)
	combo_value.text = state.core_combo_name
	_set_formula_text(state)
	hand_value.text = "%d / %d" % [state.current_hand, state.max_hands]
	reroll_value.text = "%d / %d" % [state.rerolls_left, state.rerolls_total]
	battle_value.text = str(state.battle_number)
	max_battle_value.text = str(state.max_battles)
	money_value.text = "$%d" % [state.money]


func _apply_style() -> void:
	if not is_node_ready() or style_config == null:
		return

	custom_minimum_size.x = style_config.left_sidebar_width
	add_theme_stylebox_override("panel", style_config.get_panel_style())
	style_config.apply_margin(margin, style_config.panel_padding)
	rows.add_theme_constant_override("separation", style_config.card_gap)

	for panel in [target_score_panel, current_score_panel, core_combo_panel, formula_panel, action_panel, resource_panel]:
		panel.add_theme_stylebox_override("panel", style_config.get_strong_panel_style())
	target_icon.texture = style_config.target_score_icon
	current_icon.texture = style_config.current_score_icon
	target_icon.visible = target_icon.texture != null
	current_icon.visible = current_icon.texture != null

	for label in [target_title, current_title, combo_title, formula_title]:
		style_config.apply_label(label, style_config.title_font_size)
	style_config.apply_label(target_value, style_config.score_font_size, Color(1.0, 0.25, 0.22))
	style_config.apply_label(reward_label, style_config.body_font_size)
	style_config.apply_label(current_score_value, style_config.score_font_size)
	style_config.apply_label(combo_value, style_config.title_font_size)
	style_config.apply_label(formula_value, style_config.score_font_size)
	for label in [hand_value, reroll_value, battle_value, max_battle_value, money_value]:
		style_config.apply_label(label, style_config.body_font_size)
		_apply_resource_label_constraints(label, 86)
	for label in _resource_title_labels():
		style_config.apply_label(label, style_config.small_font_size)
		_apply_resource_label_constraints(label, 118)
	style_config.apply_button(info_button)
	style_config.apply_button(options_button)
	_apply_button_background(info_button, style_config.info_button_background)
	_apply_button_background(options_button, style_config.options_button_background)


func _apply_button_background(button: Button, background: StyleBox) -> void:
	if button == null or background == null:
		return
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, background)


func _resource_title_labels() -> Array[Label]:
	return [%HandTitle, %RerollTitle, %BattleTitle, %MaxBattleTitle, %MoneyTitle]


func _apply_resource_label_constraints(label: Label, min_width: int) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.custom_minimum_size.x = min_width
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _set_formula_text(state: BattleHudState) -> void:
	formula_value.text = "%s × %s × %s = %s" % [
		_format_number(state.base_chips),
		_format_number(state.base_mult),
		_format_xmult(state.xmult),
		_format_number(state.formula_score),
	]


func _format_number(value: int) -> String:
	var text := str(value)
	var result := PackedStringArray()
	var count := 0
	for index in range(text.length() - 1, -1, -1):
		result.append(text[index])
		count += 1
		if count % 3 == 0 and index > 0:
			result.append(",")
	result.reverse()
	return "".join(result)


func _format_xmult(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.2f" % [value]
