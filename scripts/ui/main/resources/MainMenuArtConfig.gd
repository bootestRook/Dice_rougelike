extends Resource
class_name MainMenuArtConfig


@export var background_texture: Texture2D = null
@export var logo_texture: Texture2D = null
@export var button_panel_texture: Texture2D = null
@export var start_button_normal_texture: Texture2D = null
@export var start_button_hover_texture: Texture2D = null
@export var start_button_pressed_texture: Texture2D = null
@export var exit_button_normal_texture: Texture2D = null
@export var exit_button_hover_texture: Texture2D = null
@export var exit_button_pressed_texture: Texture2D = null

@export var title_text: String = "Dice King"
@export var version_text: String = "1.0.0-FULL"

@export var background_fallback_color: Color = Color(0.015, 0.018, 0.032)
@export var overlay_color: Color = Color(0.0, 0.0, 0.0, 0.12)
@export var button_panel_color: Color = Color(0.05, 0.06, 0.075, 0.82)
@export var start_button_color: Color = Color(0.025, 0.42, 0.95, 0.94)
@export var start_button_hover_color: Color = Color(0.04, 0.54, 1.0, 0.98)
@export var start_button_pressed_color: Color = Color(0.02, 0.26, 0.72, 0.98)
@export var exit_button_color: Color = Color(0.86, 0.08, 0.07, 0.94)
@export var exit_button_hover_color: Color = Color(1.0, 0.14, 0.12, 0.98)
@export var exit_button_pressed_color: Color = Color(0.58, 0.03, 0.03, 0.98)
@export var text_color: Color = Color(0.98, 0.98, 0.95)
@export var dark_text_shadow_color: Color = Color(0.02, 0.02, 0.035, 0.95)
@export var blue_glow_color: Color = Color(0.0, 0.45, 1.0, 0.72)
@export var red_glow_color: Color = Color(1.0, 0.08, 0.02, 0.72)

@export var logo_area: Rect2 = Rect2(0.15, 0.06, 0.70, 0.46)
@export var version_position: Vector2 = Vector2(0.88, 0.045)
@export var button_bar_area: Rect2 = Rect2(0.22, 0.76, 0.56, 0.13)
@export var start_button_size: Vector2 = Vector2(360, 104)
@export var exit_button_size: Vector2 = Vector2(280, 104)
