extends PanelContainer
class_name ComboInfoRow


const ComboInfoRowData = preload("res://scripts/ui/battle/view_models/ComboInfoRowData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")


@onready var level_badge: PanelContainer = %LevelBadge
@onready var chips_badge: PanelContainer = %ChipsBadge
@onready var mult_badge: PanelContainer = %MultBadge
@onready var count_badge: PanelContainer = %CountBadge
@onready var level_label: Label = %LevelLabel
@onready var combo_label: Label = %ComboLabel
@onready var chips_label: Label = %ChipsLabel
@onready var x_label: Label = %XLabel
@onready var mult_label: Label = %MultLabel
@onready var hash_label: Label = %HashLabel
@onready var count_label: Label = %CountLabel


func render(row_data: ComboInfoRowData, style_config: BattleUiStyleConfig) -> void:
	if row_data == null:
		return

	if style_config != null:
		custom_minimum_size.y = style_config.combo_info_row_height
		add_theme_stylebox_override(
			"panel",
			style_config.get_selected_style() if row_data.highlighted else style_config.get_combo_info_row_style()
		)
		level_badge.add_theme_stylebox_override("panel", style_config.get_combo_level_badge_style())
		chips_badge.add_theme_stylebox_override("panel", style_config.get_combo_chips_badge_style())
		mult_badge.add_theme_stylebox_override("panel", style_config.get_combo_mult_badge_style())
		count_badge.add_theme_stylebox_override("panel", style_config.get_combo_count_badge_style())
		style_config.apply_label(level_label, style_config.body_font_size, style_config.combo_info_row_text_color)
		var combo_text_color := style_config.combo_info_selected_text_color if row_data.highlighted else style_config.combo_info_row_text_color
		style_config.apply_label(combo_label, style_config.body_font_size, combo_text_color)
		for label in [chips_label, mult_label, count_label]:
			style_config.apply_label(label, style_config.body_font_size, style_config.combo_info_badge_text_color)
		for label in [x_label, hash_label]:
			style_config.apply_label(label, style_config.body_font_size, style_config.combo_info_soft_text_color)

	level_label.text = "等级%d" % [row_data.level]
	combo_label.text = row_data.combo_name
	chips_label.text = _format_number(row_data.chips)
	x_label.text = "×"
	mult_label.text = _format_number(row_data.mult)
	hash_label.text = "#"
	count_label.text = str(row_data.occurrence_count)


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
