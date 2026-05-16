extends Resource
class_name BattleUiStyleConfig


@export var background_color: Color = Color(0.045, 0.105, 0.075)
@export var panel_background: StyleBox = null
@export var strong_panel_background: StyleBox = null
@export var slot_background: StyleBox = null
@export var popup_background: StyleBox = null
@export var popup_tail_cover_background: StyleBox = null
@export var selected_outline: StyleBox = null
@export var info_button_background: StyleBox = null
@export var options_button_background: StyleBox = null
@export var combo_info_row_background: StyleBox = null
@export var combo_level_badge_background: StyleBox = null
@export var combo_chips_badge_background: StyleBox = null
@export var combo_mult_badge_background: StyleBox = null
@export var combo_count_badge_background: StyleBox = null
@export var target_score_icon: Texture2D = null
@export var current_score_icon: Texture2D = null
@export var modal_scrim_color: Color = Color(0.0, 0.0, 0.0, 0.42)
@export var combo_info_row_text_color: Color = Color(0.08, 0.14, 0.12)
@export var combo_info_selected_text_color: Color = Color(0.96, 0.95, 0.88)
@export var combo_info_badge_text_color: Color = Color(0.96, 0.95, 0.88)
@export var combo_info_soft_text_color: Color = Color(0.92, 0.9, 0.82)
@export var info_link_text_color: Color = Color(1.0, 0.58, 0.02)
@export var info_link_hover_color: Color = Color(1.0, 0.76, 0.18)
@export var font: Font = null
@export var title_font_size: int = 34
@export var body_font_size: int = 22
@export var small_font_size: int = 18
@export var score_font_size: int = 50
@export var layout_gap: int = 14
@export var panel_padding: int = 12
@export var card_gap: int = 10
@export var left_sidebar_width: int = 456
@export var top_inventory_bar_height: int = 168
@export var bottom_dice_area_height: int = 280
@export var icon_size: Vector2 = Vector2(70, 70)
@export var small_icon_size: Vector2 = Vector2(32, 32)
@export var dice_display_size: Vector2 = Vector2(132, 150)
@export var inventory_slot_size: Vector2 = Vector2(92, 92)
@export var face_card_size: Vector2 = Vector2(220, 170)
@export var popup_tail_size: Vector2 = Vector2(42, 42)
@export var combo_info_popup_size: Vector2 = Vector2(960, 820)
@export var combo_info_row_height: int = 58
@export var outer_margin: int = 4


func get_panel_style() -> StyleBox:
	return panel_background if panel_background != null else StyleBoxEmpty.new()


func get_strong_panel_style() -> StyleBox:
	return strong_panel_background if strong_panel_background != null else StyleBoxEmpty.new()


func get_slot_style() -> StyleBox:
	return slot_background if slot_background != null else StyleBoxEmpty.new()


func get_popup_style() -> StyleBox:
	return popup_background if popup_background != null else StyleBoxEmpty.new()


func get_popup_tail_cover_style() -> StyleBox:
	if popup_tail_cover_background != null:
		return popup_tail_cover_background
	return popup_background if popup_background != null else StyleBoxEmpty.new()


func get_selected_style() -> StyleBox:
	return selected_outline if selected_outline != null else StyleBoxEmpty.new()


func get_combo_info_row_style() -> StyleBox:
	return combo_info_row_background if combo_info_row_background != null else get_slot_style()


func get_combo_level_badge_style() -> StyleBox:
	return combo_level_badge_background if combo_level_badge_background != null else StyleBoxEmpty.new()


func get_combo_chips_badge_style() -> StyleBox:
	return combo_chips_badge_background if combo_chips_badge_background != null else StyleBoxEmpty.new()


func get_combo_mult_badge_style() -> StyleBox:
	return combo_mult_badge_background if combo_mult_badge_background != null else StyleBoxEmpty.new()


func get_combo_count_badge_style() -> StyleBox:
	return combo_count_badge_background if combo_count_badge_background != null else StyleBoxEmpty.new()


func apply_label(label: Label, size: int = -1, color: Color = Color(0.92, 0.9, 0.82)) -> void:
	if label == null:
		return
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", body_font_size if size <= 0 else size)
	label.add_theme_color_override("font_color", color)


func apply_button(button: Button) -> void:
	if button == null:
		return
	if font != null:
		button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", body_font_size)


func apply_margin(margin: MarginContainer, value: int = -1) -> void:
	if margin == null:
		return
	var resolved := panel_padding if value < 0 else value
	margin.add_theme_constant_override("margin_left", resolved)
	margin.add_theme_constant_override("margin_top", resolved)
	margin.add_theme_constant_override("margin_right", resolved)
	margin.add_theme_constant_override("margin_bottom", resolved)
