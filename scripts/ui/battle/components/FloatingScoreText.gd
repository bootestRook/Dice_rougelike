extends Label
class_name FloatingScoreText


const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")


func render(text: String, style_config: BattleUiStyleConfig) -> void:
	if style_config != null:
		custom_minimum_size = style_config.floating_score_size
		size = style_config.floating_score_size
		style_config.apply_label(self, style_config.floating_score_font_size)
	else:
		custom_minimum_size = Vector2(220, 54)
		size = custom_minimum_size
	self.text = text
	autowrap_mode = TextServer.AUTOWRAP_OFF
	clip_text = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	add_theme_color_override("font_outline_color", Color(0.04, 0.035, 0.02, 1.0))
	add_theme_constant_override("outline_size", 4)
	add_theme_color_override("font_shadow_color", Color(1.0, 0.72, 0.08, 0.62))
	add_theme_constant_override("shadow_offset_x", 0)
	add_theme_constant_override("shadow_offset_y", 3)


func set_floating_color(color: Color) -> void:
	add_theme_color_override("font_color", color)
