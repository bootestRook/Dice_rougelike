extends Resource
class_name MapStageArtConfig


@export_group("地图板")
@export var backdrop_texture: Texture2D
@export var board_texture: Texture2D
@export var path_floor_texture: Texture2D
@export var center_panel_texture: Texture2D
@export var map_stage_skin_texture: Texture2D
@export var battle_stage_skin_texture: Texture2D

@export_group("节点")
@export var start_node_texture: Texture2D
@export var battle_node_texture: Texture2D
@export var elite_node_texture: Texture2D
@export var boss_node_texture: Texture2D
@export var shop_node_texture: Texture2D
@export var forge_node_texture: Texture2D
@export var reward_node_texture: Texture2D
@export var penalty_node_texture: Texture2D
@export var event_node_texture: Texture2D
@export var rest_node_texture: Texture2D
@export var player_marker_texture: Texture2D

@export_group("按钮")
@export var button_normal_texture: Texture2D
@export var button_hover_texture: Texture2D
@export var button_pressed_texture: Texture2D
@export var button_disabled_texture: Texture2D

@export_group("尺寸")
@export var board_margin: float = 42.0
@export var route_margin: float = 92.0
@export var path_tile_size: Vector2 = Vector2(104.0, 104.0)
@export var node_size: Vector2 = Vector2(100.0, 100.0)
@export var player_marker_size: Vector2 = Vector2(62.0, 62.0)
@export var player_marker_offset: Vector2 = Vector2.ZERO
@export var center_area_minimum_size: Vector2 = Vector2(520.0, 260.0)
@export var movement_step_label_offset: Vector2 = Vector2(0.0, -54.0)

@export_group("动画")
@export var board_raise_duration: float = 0.85
@export var board_lower_duration: float = 0.55
@export var marker_step_duration: float = 0.28
@export var map_refresh_pause_duration: float = 2.0
@export var board_slide_distance_ratio: float = 1.08

@export_group("文字")
@export var title_font_size: int = 34
@export var body_font_size: int = 24
@export var button_font_size: int = 30
@export var node_font_size: int = 20
@export var movement_step_font_size: int = 30
@export var show_node_text_labels: bool = true
@export var node_label_size: Vector2 = Vector2(94.0, 40.0)
@export var node_label_offset: Vector2 = Vector2(5.0, 64.0)
@export var node_label_text_color: Color = Color(1.0, 0.9, 0.45, 1.0)
@export var node_label_background_color: Color = Color(0.01, 0.11, 0.12, 0.96)
@export var node_label_border_color: Color = Color(0.82, 0.64, 0.32, 0.92)
@export var text_color: Color = Color(1.0, 0.95, 0.78, 1.0)
@export var muted_text_color: Color = Color(0.78, 0.88, 0.86, 1.0)
@export var accent_text_color: Color = Color(1.0, 0.84, 0.38, 1.0)
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.88)


func node_texture_for_type(node_type: StringName) -> Texture2D:
	match node_type:
		&"start":
			return start_node_texture
		&"battle":
			return battle_node_texture
		&"elite":
			return elite_node_texture
		&"boss":
			return boss_node_texture
		&"shop":
			return shop_node_texture
		&"forge":
			return forge_node_texture
		&"reward":
			return reward_node_texture
		&"penalty":
			return penalty_node_texture
		&"event":
			return event_node_texture
		&"rest":
			return rest_node_texture
		_:
			return event_node_texture


func resolved_disabled_button_texture() -> Texture2D:
	if button_disabled_texture != null:
		return button_disabled_texture
	return button_normal_texture
