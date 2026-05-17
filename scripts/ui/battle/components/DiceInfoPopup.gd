extends Control
class_name DiceInfoPopup


const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")


signal close_requested()
signal ornament_link_requested(id: StringName)
signal mark_link_requested(id: StringName)


var style_config: BattleUiStyleConfig = null
var icon_library: BattleIconLibrary = null
var face_info_card_scene: PackedScene = null
var tail_local_x: float = -1.0

@onready var margin: MarginContainer = %PopupMargin
@onready var frame_panel: PanelContainer = %FramePanel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var face_grid: GridContainer = %FaceGrid
@onready var close_button: Button = %CloseButton
@onready var popup_tail: Panel = %PopupTail
@onready var popup_tail_bridge: Panel = %PopupTailBridge


func setup(
	new_style_config: BattleUiStyleConfig,
	new_icon_library: BattleIconLibrary,
	new_face_info_card_scene: PackedScene
) -> void:
	style_config = new_style_config
	icon_library = new_icon_library
	face_info_card_scene = new_face_info_card_scene
	if is_node_ready():
		_apply_style()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	close_button.pressed.connect(func() -> void: close_requested.emit())
	_apply_style()


func render(die_data: DieViewData) -> void:
	_apply_style()
	_clear_children(face_grid)

	if die_data == null:
		title_label.text = str(TranslationServer.translate(&"AUTO.TEXT.23ADBAE60C54"))
		body_label.text = str(TranslationServer.translate(&"AUTO.TEXT.DEEF03E6A8A7"))
		return

	var die_number := die_data.die_index + 1
	title_label.text = str(TranslationServer.translate(&"AUTO.TEXT.184D0F87C28C")) % [die_number, die_data.body_name, die_data.face_count]
	body_label.text = str(TranslationServer.translate(&"AUTO.TEXT.6A1C9F7BDE32")) % [die_number, die_data.body_name]
	var face_total := die_data.faces.size()
	face_grid.columns = mini(3, max(1, face_total)) if face_total <= 6 else 4

	for face_data in die_data.faces:
		var card := _make_face_card()
		face_grid.add_child(card)
		if card.has_signal("ornament_link_pressed"):
			card.ornament_link_pressed.connect(func(id: StringName) -> void: ornament_link_requested.emit(id))
		if card.has_signal("mark_link_pressed"):
			card.mark_link_pressed.connect(func(id: StringName) -> void: mark_link_requested.emit(id))
		if card.has_method("render"):
			card.render(face_data, icon_library, style_config)


func set_tail_target_global_x(global_x: float) -> void:
	var transform := get_global_transform_with_canvas()
	var local_point := transform.affine_inverse() * Vector2(global_x, transform.origin.y)
	tail_local_x = local_point.x
	_update_tail()


func clear_tail() -> void:
	tail_local_x = -1.0
	_update_tail()


func _apply_style() -> void:
	if not is_node_ready() or style_config == null:
		return
	frame_panel.add_theme_stylebox_override("panel", style_config.get_popup_style())
	style_config.apply_margin(margin, style_config.panel_padding)
	style_config.apply_label(title_label, style_config.title_font_size)
	style_config.apply_label(body_label, style_config.small_font_size)
	style_config.apply_button(close_button)
	face_grid.add_theme_constant_override("h_separation", style_config.card_gap)
	face_grid.add_theme_constant_override("v_separation", style_config.card_gap)
	popup_tail.add_theme_stylebox_override("panel", style_config.get_popup_style())
	popup_tail_bridge.add_theme_stylebox_override("panel", style_config.get_popup_tail_cover_style())
	_update_tail()


func _make_face_card() -> Control:
	if face_info_card_scene != null:
		var card := face_info_card_scene.instantiate()
		if card is Control:
			return card

	var fallback := Label.new()
	fallback.text = str(TranslationServer.translate(&"AUTO.TEXT.8E7B07850ED5"))
	return fallback


func _update_tail() -> void:
	if popup_tail == null:
		return
	if tail_local_x < 0.0:
		popup_tail.visible = false
		popup_tail_bridge.visible = false
		return
	var tail_size := style_config.popup_tail_size if style_config != null else Vector2(42, 42)
	var tail_half_width := tail_size.length() * 0.5
	var x := clampf(tail_local_x, tail_half_width, maxf(tail_half_width, size.x - tail_half_width))
	popup_tail.visible = true
	popup_tail.size = tail_size
	popup_tail.pivot_offset = tail_size * 0.5
	popup_tail.rotation = PI * 0.25
	popup_tail.position = Vector2(x - tail_size.x * 0.5, size.y - tail_size.y * 0.5)
	popup_tail_bridge.visible = true
	popup_tail_bridge.size = Vector2(tail_size.x * 1.25, 5.0)
	popup_tail_bridge.position = Vector2(x - popup_tail_bridge.size.x * 0.5, size.y - 2.0)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.free()
