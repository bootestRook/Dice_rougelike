extends Button
class_name DiceView


const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")
const DiceVisualLibrary = preload("res://scripts/ui/battle/resources/DiceVisualLibrary.gd")


signal die_pressed(index: int)
signal die_hovered(index: int)
signal die_info_requested(index: int)


var die_data: DieViewData = null
var info_focused: bool = false
var style_config: BattleUiStyleConfig = null
var icon_library: BattleIconLibrary = null
var dice_visual_library: DiceVisualLibrary = null

@onready var title_label: Label = %TitleLabel
@onready var body_icon: TextureRect = %BodyIcon
@onready var pip_icon: TextureRect = %PipIcon
@onready var pip_label: Label = %PipLabel
@onready var ornament_icon: TextureRect = %OrnamentIcon
@onready var mark_icon: TextureRect = %MarkIcon
@onready var state_overlay: TextureRect = %StateOverlay
@onready var state_label: Label = %StateLabel


func _ready() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_descendant_mouse_filter(self, Control.MOUSE_FILTER_IGNORE)
	_apply_empty_button_style()
	mouse_entered.connect(_emit_hovered)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			_emit_pressed()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			accept_event()
			if die_data != null:
				die_info_requested.emit(die_data.die_index)


func render(
	new_die_data: DieViewData,
	new_style_config: BattleUiStyleConfig,
	new_icon_library: BattleIconLibrary,
	new_dice_visual_library: DiceVisualLibrary
) -> void:
	die_data = new_die_data
	info_focused = false
	style_config = new_style_config
	icon_library = new_icon_library
	dice_visual_library = new_dice_visual_library
	_apply_empty_button_style()

	if style_config != null:
		custom_minimum_size = style_config.dice_display_size
		style_config.apply_label(state_label, style_config.small_font_size, Color(1.0, 0.78, 0.16))
		style_config.apply_label(pip_label, style_config.score_font_size)

	if die_data == null:
		disabled = true
		_clear_visuals()
		return

	title_label.text = "骰子 %d" % [die_data.die_index + 1]
	title_label.visible = false
	button_pressed = die_data.selected
	disabled = die_data.disabled
	tooltip_text = "%s / D%d" % [die_data.body_name, die_data.face_count]
	_refresh_visuals()


func set_info_focused(value: bool) -> void:
	info_focused = value
	_refresh_visuals()


func _refresh_visuals() -> void:
	if die_data == null:
		_clear_visuals()
		return

	body_icon.texture = dice_visual_library.get_custom_body_texture(die_data.body_id, die_data.die_index) if dice_visual_library != null else null
	body_icon.visible = body_icon.texture != null

	var face = die_data.current_face
	if face == null:
		pip_icon.texture = null
		pip_icon.visible = false
		pip_label.text = ""
		ornament_icon.visible = false
		mark_icon.visible = false
	else:
		_set_pip_visual(face.pip)
		_set_face_icon(ornament_icon, _ornament_texture(face.ornament_id), not _is_none_id(face.ornament_id))
		_set_face_icon(mark_icon, _mark_texture(face.mark_id), not _is_none_id(face.mark_id))

	state_overlay.texture = _state_overlay_texture()
	state_overlay.visible = state_overlay.texture != null
	_render_state()


func _set_pip_visual(pip: int) -> void:
	var texture := dice_visual_library.get_pip_texture(pip) if dice_visual_library != null else null
	pip_icon.texture = texture
	pip_icon.visible = texture != null
	pip_label.visible = texture == null
	pip_label.text = str(pip) if texture == null else ""


func _set_face_icon(target: TextureRect, texture: Texture2D, should_show: bool) -> void:
	target.texture = texture
	target.visible = should_show and texture != null


func _ornament_texture(id: StringName) -> Texture2D:
	if _is_none_id(id):
		return null
	var texture := dice_visual_library.get_ornament_texture(id) if dice_visual_library != null else null
	if texture != null:
		return texture
	return icon_library.get_ornament_icon(id) if icon_library != null else null


func _mark_texture(id: StringName) -> Texture2D:
	if _is_none_id(id):
		return null
	var texture := dice_visual_library.get_mark_texture(id) if dice_visual_library != null else null
	if texture != null:
		return texture
	return icon_library.get_mark_icon(id) if icon_library != null else null


func _state_overlay_texture() -> Texture2D:
	if dice_visual_library == null or die_data == null:
		return null
	return dice_visual_library.get_focus_state_overlay_texture(
		die_data.selected,
		info_focused,
		die_data.rerollable,
		die_data.scored,
		die_data.disabled
	)


func _render_state() -> void:
	if die_data == null:
		state_label.text = ""
		return
	if die_data.disabled:
		state_label.text = "禁用"
	elif die_data.scored:
		state_label.text = "已结算"
	elif info_focused:
		state_label.text = "查看中"
	elif die_data.selected:
		state_label.text = "已选择"
	else:
		state_label.text = ""


func _clear_visuals() -> void:
	for texture_rect in [body_icon, pip_icon, ornament_icon, mark_icon, state_overlay]:
		texture_rect.texture = null
		texture_rect.visible = false
	pip_label.text = ""
	state_label.text = ""


func _is_none_id(id: StringName) -> bool:
	return id == &"" or id == &"none" or id == &"orn_none" or id == &"mark_none"


func _apply_empty_button_style() -> void:
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, empty)


func _emit_pressed() -> void:
	if die_data != null:
		die_pressed.emit(die_data.die_index)


func _emit_hovered() -> void:
	if die_data != null:
		die_hovered.emit(die_data.die_index)


func _set_descendant_mouse_filter(node: Node, filter: int) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = filter
		_set_descendant_mouse_filter(child, filter)
