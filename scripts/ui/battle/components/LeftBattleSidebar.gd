extends PanelContainer
class_name LeftBattleSidebar


const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")


signal info_pressed()
signal options_pressed()


var style_config: BattleUiStyleConfig = null
var hand_number_row: HBoxContainer = null
var hand_current_value: Label = null
var hand_separator_value: Label = null
var hand_total_value: Label = null
var hand_current_font: Font = null
var last_rendered_hand: int = -1
var last_rendered_rerolls: int = -1
var last_rendered_money: int = -1
var pending_reroll_target: int = -1
var pending_money_target: int = -1
var reroll_feedback_id: int = 0
var money_feedback_id: int = 0
var hand_count_tween: Tween = null
var money_count_tween: Tween = null

@onready var margin: MarginContainer = %SidebarMargin
@onready var rows: VBoxContainer = %Rows
@onready var target_score_panel: PanelContainer = %TargetScorePanel
@onready var current_score_panel: PanelContainer = %CurrentScorePanel
@onready var core_combo_panel: PanelContainer = %CoreComboPanel
@onready var formula_panel: PanelContainer = %ScoreFormulaPanel
@onready var action_panel: PanelContainer = %ActionButtonPanel
@onready var resource_panel: PanelContainer = %BattleResourcePanel
@onready var target_hint: Label = %TargetHint
@onready var current_score_box: PanelContainer = %CurrentScoreBox
@onready var combo_level_label: Label = %ComboLevelLabel
@onready var combo_header: HBoxContainer = $SidebarMargin/Rows/CoreComboPanel/ComboMargin/ComboRows/ComboHeader
@onready var hand_stat_panel: PanelContainer = %HandStatPanel
@onready var reroll_stat_panel: PanelContainer = %RerollStatPanel
@onready var money_stat_panel: PanelContainer = %MoneyStatPanel
@onready var battle_progress_row: HBoxContainer = $SidebarMargin/Rows/BottomRow/BattleResourcePanel/ResourceMargin/ResourceRows/BattleProgressRow
@onready var battle_stat_panel: PanelContainer = %BattleStatPanel
@onready var max_battle_stat_panel: PanelContainer = %MaxBattleStatPanel
@onready var current_title: Label = %CurrentTitle
@onready var combo_title: Label = %ComboTitle
@onready var formula_title: Label = %FormulaTitle
@onready var target_value: Label = %TargetValue
@onready var reward_label: Label = %RewardLabel
@onready var current_score_value: Label = %CurrentScoreValue
@onready var combo_value: Label = %ComboValue
@onready var formula_value: Label = %FormulaValue
@onready var formula_badges: HBoxContainer = %FormulaBadges
@onready var formula_chips_badge: Control = %FormulaChipsBadge
@onready var formula_mult_badge: Control = %FormulaMultBadge
@onready var formula_xmult_badge: Control = %FormulaXMultBadge
@onready var formula_chips_texture: TextureRect = %FormulaChipsTexture
@onready var formula_mult_texture: TextureRect = %FormulaMultTexture
@onready var formula_xmult_texture: TextureRect = %FormulaXMultTexture
@onready var formula_chips_value: Label = %FormulaChipsValue
@onready var formula_mult_value: Label = %FormulaMultValue
@onready var formula_xmult_value: Label = %FormulaXMultValue
@onready var formula_x_label: Label = %FormulaXLabel
@onready var formula_xmult_label: Label = %FormulaXMultLabel
@onready var info_button: Button = %InfoButton
@onready var options_button: Button = %OptionsButton
@onready var hand_value: Label = %HandValue
@onready var reroll_value: Label = %RerollValue
@onready var battle_value: Label = %BattleValue
@onready var max_battle_value: Label = %MaxBattleValue
@onready var money_value: Label = %MoneyValue
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
	reward_label.text = str(TranslationServer.translate(&"AUTO.TEXT.2091A36B7297")) % [state.reward_level]
	current_score_value.text = _format_number(state.current_score)
	combo_level_label.visible = false
	if state.final_score_display_visible:
		combo_value.text = _format_number(state.formula_score) if state.formula_score > 0 else ""
		combo_level_label.text = ""
		combo_level_label.visible = false
		_apply_runtime_label_style(combo_value, 44, Color(1.0, 0.22, 0.20, 1.0))
	elif state.combo_display_visible:
		var combo_font_size := 30
		combo_value.text = state.core_combo_name
		combo_level_label.text = str(TranslationServer.translate(&"AUTO.TEXT.2219F266B80D")) % [maxi(1, state.core_combo_level)]
		combo_level_label.visible = true
		_apply_runtime_label_style(combo_value, combo_font_size, Color(0.95, 0.94, 0.86, 1.0))
		_apply_runtime_label_style(combo_level_label, roundi(float(combo_font_size) * 0.75), Color(0.95, 0.94, 0.86, 1.0))
	else:
		combo_value.text = ""
		combo_level_label.text = ""
		combo_level_label.visible = false
	_update_combo_label_min_widths()
	_set_formula_text(state)
	_set_hand_counter_text(state.current_hand, state.max_hands)
	_set_reroll_text(state.rerolls_left)
	battle_value.text = "1"
	max_battle_value.text = str(state.max_battles)
	_set_money_text(state.money)


func play_final_score_pop() -> void:
	if not is_node_ready():
		await ready
	if combo_value == null:
		return
	await get_tree().process_frame
	combo_value.pivot_offset = combo_value.size * 0.5
	combo_value.scale = Vector2(0.78, 0.78)
	combo_value.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(combo_value, "scale", Vector2(1.32, 1.32), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(combo_value, "modulate:a", 1.0, 0.08)
	tween.tween_property(combo_value, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	if is_instance_valid(combo_value):
		combo_value.scale = Vector2.ONE
		combo_value.modulate.a = 1.0


func _apply_style() -> void:
	if not is_node_ready() or style_config == null:
		return

	custom_minimum_size.x = style_config.left_sidebar_width
	add_theme_stylebox_override("panel", _make_flat_box(Color(0.035, 0.075, 0.065, 1.0), Color(0.32, 0.45, 0.22, 1.0), 2, 4))
	style_config.apply_margin(margin, style_config.panel_padding)
	rows.add_theme_constant_override("separation", style_config.card_gap)
	_apply_fixed_panel_heights()

	var card_style := _make_flat_box(Color(0.04, 0.085, 0.075, 0.98), Color(0.22, 0.37, 0.20, 1.0), 2, 6)
	for panel in [target_score_panel, current_score_panel, core_combo_panel, action_panel, resource_panel]:
		panel.add_theme_stylebox_override("panel", card_style)
	formula_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	current_score_box.add_theme_stylebox_override("panel", _make_flat_box(Color(0.12, 0.17, 0.16, 1.0), Color(0.27, 0.36, 0.33, 1.0), 2, 8))
	for panel in [hand_stat_panel, reroll_stat_panel, money_stat_panel, battle_stat_panel, max_battle_stat_panel]:
		panel.add_theme_stylebox_override("panel", _make_flat_box(Color(0.12, 0.17, 0.16, 1.0), Color(0.22, 0.32, 0.29, 1.0), 2, 7))
	battle_progress_row.visible = true
	current_icon.texture = style_config.current_score_icon
	current_icon.visible = current_icon.texture != null
	current_icon.modulate = Color(1.0, 0.22, 0.20, 1.0)
	_ensure_hand_counter_nodes()

	style_config.apply_label(target_hint, 18, Color(0.95, 0.94, 0.86, 1.0))
	style_config.apply_label(current_title, 24, Color(0.95, 0.94, 0.86, 1.0))
	style_config.apply_label(combo_title, style_config.title_font_size)
	formula_title.visible = false
	style_config.apply_label(target_value, style_config.score_font_size, Color(1.0, 0.22, 0.20, 1.0))
	style_config.apply_label(reward_label, 20, Color(0.95, 0.94, 0.86, 1.0))
	style_config.apply_label(current_score_value, 42, Color(0.95, 0.94, 0.86, 1.0))
	style_config.apply_label(combo_value, 44, Color(1.0, 0.22, 0.20, 1.0))
	style_config.apply_label(combo_level_label, 16, Color(0.95, 0.94, 0.86, 1.0))
	combo_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combo_header.custom_minimum_size.y = 44
	combo_header.alignment = BoxContainer.ALIGNMENT_CENTER
	combo_value.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	combo_value.custom_minimum_size.y = 44
	combo_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_level_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	combo_level_label.custom_minimum_size.y = 44
	combo_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_level_label.visible = false
	style_config.apply_label(formula_value, style_config.score_font_size)
	formula_value.visible = false
	formula_badges.add_theme_constant_override("separation", style_config.formula_badge_gap)
	formula_badges.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var formula_badge_size: Vector2 = style_config.formula_badge_size
	for badge in [formula_chips_badge, formula_mult_badge, formula_xmult_badge]:
		badge.custom_minimum_size = formula_badge_size
		badge.clip_contents = true
	formula_chips_texture.texture = style_config.formula_chips_badge_texture
	formula_mult_texture.texture = style_config.formula_mult_badge_texture
	formula_xmult_texture.texture = style_config.formula_xmult_badge_texture
	for texture in [formula_chips_texture, formula_mult_texture, formula_xmult_texture]:
		texture.stretch_mode = TextureRect.STRETCH_SCALE
	for label in [formula_chips_value, formula_mult_value]:
		style_config.apply_label(label, style_config.formula_badge_font_size, style_config.combo_info_badge_text_color)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	style_config.apply_label(formula_xmult_value, style_config.formula_badge_font_size, Color(0.22, 0.10, 0.0, 1.0))
	formula_xmult_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formula_xmult_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for separator_label in [formula_x_label, formula_xmult_label]:
		style_config.apply_label(separator_label, style_config.formula_separator_font_size, Color(1.0, 0.25, 0.22))
		separator_label.custom_minimum_size = Vector2(style_config.formula_separator_width, formula_badge_size.y)
		separator_label.text = "x"
		separator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		separator_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_hand_counter_style()
	_apply_value_label_constraints()
	style_config.apply_label(reroll_value, 38, Color(1.0, 0.72, 0.02, 1.0))
	reroll_value.add_theme_font_override("font", _get_hand_current_font())
	reroll_value.add_theme_color_override("font_outline_color", Color(0.18, 0.07, 0.0, 1.0))
	reroll_value.add_theme_constant_override("outline_size", 2)
	reroll_value.custom_minimum_size = Vector2(32.0, 40.0)
	for label in [reroll_value, battle_value, max_battle_value]:
		if label != reroll_value:
			style_config.apply_label(label, 26, Color(0.95, 0.94, 0.86, 1.0))
		_apply_single_line_label(label)
	style_config.apply_label(money_value, 38, Color(1.0, 0.72, 0.02, 1.0))
	money_value.add_theme_font_override("font", _get_hand_current_font())
	money_value.add_theme_color_override("font_outline_color", Color(0.18, 0.07, 0.0, 1.0))
	money_value.add_theme_constant_override("outline_size", 2)
	money_value.custom_minimum_size = Vector2(72.0, 40.0)
	_apply_single_line_label(money_value)
	for label in _resource_title_labels():
		style_config.apply_label(label, 18, Color(0.95, 0.94, 0.86, 1.0))
		_apply_single_line_label(label)
	style_config.apply_button(info_button)
	style_config.apply_button(options_button)
	_apply_button_background(info_button, style_config.info_button_background)
	_apply_button_background(options_button, style_config.options_button_background)
	_apply_button_text_style(info_button)
	_apply_button_text_style(options_button)


func _apply_button_background(button: Button, background: StyleBox) -> void:
	if button == null or background == null:
		return
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, background)


func _apply_button_text_style(button: Button) -> void:
	if button == null:
		return
	button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.88, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.94, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.98, 0.96, 0.88, 1.0))
	button.add_theme_font_size_override("font_size", 22)


func _apply_runtime_label_style(label: Label, font_size: int, color: Color) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


func _update_combo_label_min_widths() -> void:
	_set_label_minimum_width_to_text(combo_value, 10.0)
	if combo_level_label.visible:
		_set_label_minimum_width_to_text(combo_level_label, 6.0)
	else:
		combo_level_label.custom_minimum_size.x = 0.0


func _set_label_minimum_width_to_text(label: Label, horizontal_padding: float) -> void:
	if label == null:
		return
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var text_width := 0.0
	if label.text != "":
		text_width = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	label.custom_minimum_size.x = ceili(text_width + horizontal_padding)


func _ensure_hand_counter_nodes() -> void:
	if hand_number_row != null:
		return
	if hand_value == null:
		return
	var parent := hand_value.get_parent()
	if parent == null:
		return
	hand_value.visible = false
	hand_number_row = HBoxContainer.new()
	hand_number_row.name = "HandNumberRow"
	hand_number_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_number_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hand_number_row.custom_minimum_size = Vector2(76.0, 42.0)
	hand_number_row.add_theme_constant_override("separation", 0)
	parent.add_child(hand_number_row)

	hand_current_value = Label.new()
	hand_current_value.name = "HandCurrentValue"
	hand_separator_value = Label.new()
	hand_separator_value.name = "HandSeparatorValue"
	hand_total_value = Label.new()
	hand_total_value.name = "HandTotalValue"
	for label in [hand_current_value, hand_separator_value, hand_total_value]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand_number_row.add_child(label)
		_apply_single_line_label(label)


func _apply_hand_counter_style() -> void:
	_ensure_hand_counter_nodes()
	if hand_current_value == null:
		return
	var current_color := Color(1.0, 0.72, 0.02, 1.0)
	var secondary_color := Color(0.72, 0.93, 0.95, 1.0)
	style_config.apply_label(hand_current_value, 38, current_color)
	style_config.apply_label(hand_separator_value, 18, secondary_color)
	style_config.apply_label(hand_total_value, 18, secondary_color)
	hand_current_value.add_theme_font_override("font", _get_hand_current_font())
	hand_current_value.add_theme_color_override("font_outline_color", Color(0.18, 0.07, 0.0, 1.0))
	hand_current_value.add_theme_constant_override("outline_size", 2)
	hand_current_value.custom_minimum_size = Vector2(32.0, 40.0)
	hand_separator_value.custom_minimum_size = Vector2(12.0, 30.0)
	hand_total_value.custom_minimum_size = Vector2(28.0, 30.0)


func _get_hand_current_font() -> Font:
	if hand_current_font == null:
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Impact", "Arial Black", "Bahnschrift Display", "Bahnschrift", "Arial"])
		hand_current_font = font
	return hand_current_font


func _set_hand_counter_text(current_hand: int, max_hands: int) -> void:
	_ensure_hand_counter_nodes()
	if hand_current_value == null:
		hand_value.text = "%d / %d" % [current_hand, max_hands]
		return
	var changed := last_rendered_hand >= 0 and current_hand != last_rendered_hand
	hand_current_value.text = str(current_hand)
	hand_separator_value.text = "/"
	hand_total_value.text = str(max_hands)
	if changed:
		_play_hand_count_pop()
	last_rendered_hand = current_hand


func _play_hand_count_pop() -> void:
	if not is_node_ready():
		await ready
	if hand_current_value == null:
		return
	await get_tree().process_frame
	if hand_count_tween != null and hand_count_tween.is_valid():
		hand_count_tween.kill()
	hand_current_value.pivot_offset = hand_current_value.size * 0.5
	hand_current_value.scale = Vector2.ONE
	hand_count_tween = create_tween()
	hand_count_tween.tween_property(hand_current_value, "scale", Vector2(1.34, 1.34), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hand_count_tween.tween_property(hand_current_value, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await hand_count_tween.finished
	if is_instance_valid(hand_current_value):
		hand_current_value.scale = Vector2.ONE


func _set_money_text(money: int) -> void:
	if last_rendered_money < 0:
		last_rendered_money = money
		money_value.text = "$%d" % [money]
		return
	if pending_money_target >= 0:
		if money == pending_money_target:
			return
		if money < last_rendered_money:
			money_feedback_id += 1
			pending_money_target = money
			_play_money_decrease(last_rendered_money - money, money, money_feedback_id)
			return
		pending_money_target = -1
		money_feedback_id += 1
	if money < last_rendered_money:
		money_feedback_id += 1
		pending_money_target = money
		_play_money_decrease(last_rendered_money - money, money, money_feedback_id)
		return
	var changed_up := money > last_rendered_money
	money_value.text = "$%d" % [money]
	if changed_up:
		_play_money_count_pop()
	last_rendered_money = money


func _set_reroll_text(rerolls: int) -> void:
	if last_rendered_rerolls < 0:
		last_rendered_rerolls = rerolls
		reroll_value.text = str(rerolls)
		return
	if pending_reroll_target >= 0:
		if rerolls == pending_reroll_target:
			return
		if rerolls < last_rendered_rerolls:
			reroll_feedback_id += 1
			pending_reroll_target = rerolls
			_play_reroll_decrease(last_rendered_rerolls - rerolls, rerolls, reroll_feedback_id)
			return
		pending_reroll_target = -1
		reroll_feedback_id += 1
	if rerolls < last_rendered_rerolls:
		reroll_feedback_id += 1
		pending_reroll_target = rerolls
		_play_reroll_decrease(last_rendered_rerolls - rerolls, rerolls, reroll_feedback_id)
		return
	reroll_value.text = str(rerolls)
	last_rendered_rerolls = rerolls


func _play_money_decrease(amount: int, target_money: int, feedback_id: int) -> void:
	await _play_decrease_feedback(money_stat_panel, "-%d" % [maxi(0, amount)])
	if feedback_id != money_feedback_id:
		return
	pending_money_target = -1
	last_rendered_money = target_money
	money_value.text = "$%d" % [target_money]


func _play_reroll_decrease(amount: int, target_rerolls: int, feedback_id: int) -> void:
	await _play_decrease_feedback(reroll_stat_panel, "-%d" % [maxi(0, amount)])
	if feedback_id != reroll_feedback_id:
		return
	pending_reroll_target = -1
	last_rendered_rerolls = target_rerolls
	reroll_value.text = str(target_rerolls)


func _play_decrease_feedback(target_panel: Control, text: String) -> void:
	if not is_node_ready():
		await ready
	if target_panel == null:
		return
	await get_tree().process_frame
	var panel_size := target_panel.size
	if panel_size == Vector2.ZERO:
		panel_size = target_panel.get_global_rect().size
	if panel_size == Vector2.ZERO:
		return

	var overlay := Control.new()
	overlay.name = "DecreaseFeedbackOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.clip_contents = true
	overlay.z_index = 90
	overlay.position = Vector2.ZERO
	overlay.size = panel_size
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	target_panel.add_child(overlay)

	var fill := PanelContainer.new()
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size = panel_size
	fill.position = Vector2(-panel_size.x, 0.0)
	fill.add_theme_stylebox_override("panel", _make_flat_box(Color(0.92, 0.05, 0.04, 0.96), Color(1.0, 0.32, 0.18, 1.0), 2, 7))
	overlay.add_child(fill)

	var floating := Label.new()
	floating.text = text
	floating.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating.size = panel_size
	floating.position = Vector2.ZERO
	floating.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_child(floating)
	if style_config != null:
		style_config.apply_label(floating, 40, Color(1.0, 0.96, 0.92, 1.0))
	floating.add_theme_font_override("font", _get_hand_current_font())
	floating.add_theme_color_override("font_outline_color", Color(0.34, 0.0, 0.0, 1.0))
	floating.add_theme_constant_override("outline_size", 4)
	floating.pivot_offset = floating.size * 0.5
	floating.scale = Vector2(0.62, 0.62)
	floating.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(fill, "position:x", 0.0, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(floating, "scale", Vector2(1.28, 1.28), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(floating, "modulate:a", 1.0, 0.07)
	tween.tween_interval(0.08)
	tween.tween_property(fill, "position:x", panel_size.x, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(floating, "position:x", panel_size.x, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(floating, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(overlay):
		overlay.queue_free()


func _play_money_count_pop() -> void:
	if not is_node_ready():
		await ready
	if money_value == null:
		return
	await get_tree().process_frame
	if money_count_tween != null and money_count_tween.is_valid():
		money_count_tween.kill()
	money_value.pivot_offset = money_value.size * 0.5
	money_value.scale = Vector2.ONE
	money_count_tween = create_tween()
	money_count_tween.tween_property(money_value, "scale", Vector2(1.28, 1.28), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	money_count_tween.tween_property(money_value, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await money_count_tween.finished
	if is_instance_valid(money_value):
		money_value.scale = Vector2.ONE


func _make_flat_box(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.border_color = border
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_right = radius
	box.corner_radius_bottom_left = radius
	return box


func _apply_fixed_panel_heights() -> void:
	_apply_fixed_height(target_score_panel, style_config.left_target_score_panel_height)
	_apply_fixed_height(current_score_panel, style_config.left_current_score_panel_height)
	_apply_fixed_height(core_combo_panel, style_config.left_core_combo_panel_height)
	_apply_fixed_height(formula_panel, style_config.left_score_formula_panel_height)


func _apply_fixed_height(control: Control, height: int) -> void:
	if control == null:
		return
	control.custom_minimum_size.y = height
	control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _apply_value_label_constraints() -> void:
	for label in [target_value, reward_label, current_score_value, combo_value, combo_level_label, formula_chips_value, formula_mult_value, formula_xmult_value, formula_x_label, formula_xmult_label, hand_current_value, hand_separator_value, hand_total_value]:
		_apply_single_line_label(label)
	_apply_single_line_label(formula_value)
	formula_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	formula_value.custom_minimum_size.y = style_config.score_font_size + 10


func _apply_single_line_label(label: Label) -> void:
	if label == null:
		return
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _resource_title_labels() -> Array[Label]:
	return [%HandTitle, %RerollTitle, %BattleTitle, %MaxBattleTitle]


func _apply_resource_label_constraints(label: Label, min_width: int) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.custom_minimum_size.x = min_width
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _set_formula_text(state: BattleHudState) -> void:
	var chips_text: String = _format_number(state.base_chips)
	var mult_text: String = _format_number(state.base_mult)
	var xmult_text: String = _format_xmult(state.xmult)
	formula_chips_value.text = chips_text
	formula_mult_value.text = mult_text
	formula_xmult_value.text = xmult_text
	formula_value.text = "%s x %s x %s" % [chips_text, mult_text, xmult_text]
	formula_panel.tooltip_text = formula_value.text
	_fit_formula_badge_font_sizes()
	call_deferred("_fit_formula_badge_font_sizes")


func _fit_formula_badge_font_sizes() -> void:
	if style_config == null:
		return
	_fit_label_to_width(formula_chips_value, formula_chips_badge.size.x - 16.0, style_config.formula_badge_font_size, style_config.body_font_size)
	_fit_label_to_width(formula_mult_value, formula_mult_badge.size.x - 16.0, style_config.formula_badge_font_size, style_config.body_font_size)
	_fit_label_to_width(formula_xmult_value, formula_xmult_badge.size.x - 16.0, style_config.formula_badge_font_size, style_config.body_font_size)


func _remaining_hands(state: BattleHudState) -> int:
	if state == null or state.max_hands <= 0:
		return 0
	if state.current_hand <= 0:
		return state.max_hands
	return clampi(state.max_hands - state.current_hand + 1, 0, state.max_hands)


func _fit_label_to_width(label: Label, available_width: float, max_font_size: int, min_font_size: int) -> void:
	if label == null:
		return
	if available_width <= 0.0:
		available_width = label.size.x

	var font := label.get_theme_font("font")
	var resolved_size := max_font_size
	while resolved_size > min_font_size and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, resolved_size).x > available_width:
		resolved_size -= 1

	label.add_theme_font_size_override("font_size", resolved_size)


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
	return str(int(roundf(value)))
