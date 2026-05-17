extends PanelContainer
class_name ScoreLogRow


const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const RichTextHighlighter = preload("res://scripts/ui/RichTextHighlighter.gd")


@onready var text_label: RichTextLabel = %TextLabel


func render(text: String, style_config: BattleUiStyleConfig) -> void:
	if style_config != null:
		add_theme_stylebox_override("panel", style_config.get_panel_style())
		RichTextHighlighter.setup_rich_label(text_label, text, style_config.small_font_size, Color(0.92, 0.9, 0.82), style_config.font)
	else:
		RichTextHighlighter.setup_rich_label(text_label, text, 14, Color(0.92, 0.9, 0.82))
