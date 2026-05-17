extends Control
class_name DiceInfoPopup


const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")


signal close_requested()
signal ornament_link_requested(id: StringName)
signal mark_link_requested(id: StringName)
signal face_selected(face_index: int)
signal install_requested(face_index: int)


var style_config: BattleUiStyleConfig = null
var icon_library: BattleIconLibrary = null
var face_info_card_scene: PackedScene = null
var tail_local_x: float = -1.0
var install_mode_enabled: bool = false
var install_piece_name: String = ""
var selected_face_index: int = -1
var current_die_index: int = -1
var face_cards: Array[Control] = []
var install_button: Button = null

@onready var margin: MarginContainer = %PopupMargin
@onready var frame_panel: PanelContainer = %FramePanel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var face_scroll: ScrollContainer = $FramePanel/PopupMargin/Rows/FaceScroll
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
	if face_scroll != null:
		face_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(func() -> void: close_requested.emit())
	_ensure_install_button()
	_apply_style()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and (mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if _scroll_faces(mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
				accept_event()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not event is InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return

	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if _is_point_inside_face_scroll(mouse_event.position) and _scroll_faces(mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			get_viewport().set_input_as_handled()
		return

	if install_mode_enabled and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if _select_face_at_global_point(mouse_event.position):
			get_viewport().set_input_as_handled()


func set_install_context(enabled: bool, piece_name: String = "") -> void:
	install_mode_enabled = enabled
	install_piece_name = piece_name
	if not install_mode_enabled:
		selected_face_index = -1
	_refresh_install_button()
	_refresh_face_selection()


func render(die_data: DieViewData) -> void:
	_apply_style()
	_clear_children(face_grid)
	face_cards.clear()

	if die_data == null:
		current_die_index = -1
		selected_face_index = -1
		title_label.text = str(TranslationServer.translate(&"AUTO.TEXT.23ADBAE60C54"))
		body_label.text = str(TranslationServer.translate(&"AUTO.TEXT.DEEF03E6A8A7"))
		_refresh_install_button()
		return

	if current_die_index != die_data.die_index:
		selected_face_index = -1
	current_die_index = die_data.die_index
	var die_number := die_data.die_index + 1
	title_label.text = str(TranslationServer.translate(&"AUTO.TEXT.184D0F87C28C")) % [die_number, die_data.body_name, die_data.face_count]
	body_label.text = str(TranslationServer.translate(&"AUTO.TEXT.6A1C9F7BDE32")) % [die_number, die_data.body_name]
	if install_mode_enabled:
		var install_line := str(TranslationServer.translate(&"AUTO.TEXT.B6CF819FA0AC"))
		if install_piece_name != "":
			install_line = "%s: %s" % [install_line, install_piece_name]
		body_label.text = "%s\n%s" % [body_label.text, install_line]
	var face_total := die_data.faces.size()
	face_grid.columns = mini(3, max(1, face_total)) if face_total <= 6 else 4
	if selected_face_index >= face_total:
		selected_face_index = -1

	for face_data in die_data.faces:
		var card := _make_face_card()
		face_grid.add_child(card)
		face_cards.append(card)
		card.set_meta("face_index", face_data.face_index)
		if card.has_signal("ornament_link_pressed"):
			card.ornament_link_pressed.connect(func(id: StringName) -> void: ornament_link_requested.emit(id))
		if card.has_signal("mark_link_pressed"):
			card.mark_link_pressed.connect(func(id: StringName) -> void: mark_link_requested.emit(id))
		if card.has_signal("face_pressed"):
			card.face_pressed.connect(_on_face_card_pressed)
		if card.has_method("render"):
			card.render(face_data, icon_library, style_config)
		if card.has_method("set_install_selectable"):
			card.set_install_selectable(install_mode_enabled)
		if card.has_method("set_install_selected"):
			card.set_install_selected(install_mode_enabled and face_data.face_index == selected_face_index)
	_refresh_install_button()


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
	if install_button != null:
		style_config.apply_button(install_button)
		install_button.add_theme_font_size_override("font_size", style_config.small_font_size)
	if face_scroll != null:
		face_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	face_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	face_grid.add_theme_constant_override("h_separation", style_config.card_gap)
	face_grid.add_theme_constant_override("v_separation", style_config.card_gap)
	popup_tail.add_theme_stylebox_override("panel", style_config.get_popup_style())
	popup_tail_bridge.add_theme_stylebox_override("panel", style_config.get_popup_tail_cover_style())
	_update_tail()
	_refresh_install_button()


func _make_face_card() -> Control:
	if face_info_card_scene != null:
		var card := face_info_card_scene.instantiate()
		if card is Control:
			return card

	var fallback := Label.new()
	fallback.text = str(TranslationServer.translate(&"AUTO.TEXT.8E7B07850ED5"))
	return fallback


func _ensure_install_button() -> void:
	if install_button != null or title_label == null:
		return
	var header := title_label.get_parent()
	if header == null:
		return
	install_button = Button.new()
	install_button.name = "InstallButton"
	install_button.text = str(TranslationServer.translate(&"AUTO.TEXT.402052AA36CD"))
	install_button.focus_mode = Control.FOCUS_NONE
	install_button.custom_minimum_size = Vector2(96.0, 34.0)
	install_button.pressed.connect(_on_install_button_pressed)
	header.add_child(install_button)
	header.move_child(install_button, max(0, header.get_child_count() - 2))
	_refresh_install_button()


func _on_face_card_pressed(face_index: int) -> void:
	if not install_mode_enabled:
		return
	if face_index < 0:
		return
	_select_face(face_index)


func _on_install_button_pressed() -> void:
	if not install_mode_enabled or selected_face_index < 0:
		return
	call_deferred("_emit_install_requested", selected_face_index)


func _refresh_face_selection() -> void:
	for card in face_cards:
		if card == null:
			continue
		var face_index := -1
		if card.has_meta("face_index"):
			face_index = int(card.get_meta("face_index"))
		if card.has_method("set_install_selectable"):
			card.set_install_selectable(install_mode_enabled)
		if card.has_method("set_install_selected"):
			card.set_install_selected(install_mode_enabled and face_index == selected_face_index)


func _refresh_install_button() -> void:
	if install_button == null:
		return
	install_button.visible = install_mode_enabled
	install_button.disabled = not install_mode_enabled or selected_face_index < 0


func _select_face_at_global_point(global_point: Vector2) -> bool:
	for card in face_cards:
		if card == null or not is_instance_valid(card):
			continue
		if not card.visible:
			continue
		if not (card as Control).get_global_rect().has_point(global_point):
			continue
		var face_index := int(card.get_meta("face_index", -1))
		if face_index < 0:
			return false
		_select_face(face_index)
		return true
	return false


func _select_face(face_index: int) -> void:
	selected_face_index = face_index
	_refresh_face_selection()
	_refresh_install_button()
	call_deferred("_emit_face_selected", selected_face_index)


func _emit_face_selected(face_index: int) -> void:
	if not is_instance_valid(self):
		return
	face_selected.emit(face_index)


func _emit_install_requested(face_index: int) -> void:
	if not is_instance_valid(self):
		return
	install_requested.emit(face_index)


func _is_point_inside_face_scroll(global_point: Vector2) -> bool:
	if face_scroll == null:
		return get_global_rect().has_point(global_point)
	return face_scroll.get_global_rect().has_point(global_point)


func _scroll_faces(scroll_down: bool) -> bool:
	if face_scroll == null:
		return false
	var bar := face_scroll.get_v_scroll_bar()
	if bar == null:
		return false
	var step := maxf(28.0, bar.page * 0.28)
	var direction := 1.0 if scroll_down else -1.0
	var next_value := clampf(float(face_scroll.scroll_vertical) + step * direction, bar.min_value, bar.max_value)
	if is_equal_approx(next_value, float(face_scroll.scroll_vertical)):
		return false
	face_scroll.scroll_vertical = int(round(next_value))
	return true


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
		child.queue_free()
