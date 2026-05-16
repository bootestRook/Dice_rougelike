extends Label
class_name FloatingScoreText


const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")


func render(text: String, style_config: BattleUiStyleConfig) -> void:
	if style_config != null:
		style_config.apply_label(self, style_config.score_font_size)
	self.text = text
