extends PanelContainer
class_name ScoreLogRow


const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")


@onready var text_label: Label = %TextLabel


func render(text: String, style_config: BattleUiStyleConfig) -> void:
	if style_config != null:
		add_theme_stylebox_override("panel", style_config.get_panel_style())
		style_config.apply_label(text_label, style_config.small_font_size)
	text_label.text = text
