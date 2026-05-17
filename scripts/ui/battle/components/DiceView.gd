extends Button
class_name DiceView


const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")
const DiceVisualLibrary = preload("res://scripts/ui/battle/resources/DiceVisualLibrary.gd")


signal die_pressed(index: int)
signal die_hovered(index: int)
signal die_info_requested(index: int)


const HOVER_SHAKE_SECONDS := 0.18
const HOVER_RESPONSE_SPEED := 18.0
const HOVER_RETURN_SPEED := 14.0
const HOVER_PRESS_STRENGTH := 0.055
const HOVER_CENTER_PRESS := 0.028
const HOVER_SHIFT_PIXELS := 5.0
const HOVER_TILT_RADIANS := 0.045
const HOVER_SHAKE_PIXELS := 4.5
const HOVER_SHAKE_TILT_RADIANS := 0.055


var die_data: DieViewData = null
var info_focused: bool = false
var style_config: BattleUiStyleConfig = null
var icon_library: BattleIconLibrary = null
var dice_visual_library: DiceVisualLibrary = null
var hover_effect_active: bool = false
var hover_shake_time_left: float = 0.0
var hover_target_position: Vector2 = Vector2.ZERO
var hover_target_scale: Vector2 = Vector2.ONE
var hover_target_rotation: float = 0.0

@onready var visual_root: Control = $VisualRoot
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
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_process(false)


func _process(delta: float) -> void:
	if visual_root == null:
		set_process(false)
		return

	var should_press := hover_effect_active and _can_play_hover_effect()
	if should_press:
		_update_hover_press_targets()
	else:
		hover_effect_active = false
		hover_shake_time_left = 0.0
		hover_target_position = Vector2.ZERO
		hover_target_scale = Vector2.ONE
		hover_target_rotation = 0.0

	var shake_position := Vector2.ZERO
	var shake_rotation := 0.0
	if hover_shake_time_left > 0.0:
		hover_shake_time_left = maxf(0.0, hover_shake_time_left - delta)
		var progress := 1.0 - hover_shake_time_left / HOVER_SHAKE_SECONDS
		var damp := 1.0 - progress
		shake_position = Vector2(
			sin(progress * TAU * 3.0) * HOVER_SHAKE_PIXELS * damp,
			cos(progress * TAU * 4.0) * HOVER_SHAKE_PIXELS * 0.45 * damp
		)
		shake_rotation = sin(progress * TAU * 4.5) * HOVER_SHAKE_TILT_RADIANS * damp

	var target_position := hover_target_position + shake_position
	var target_rotation := hover_target_rotation + shake_rotation
	var speed := HOVER_RESPONSE_SPEED if should_press else HOVER_RETURN_SPEED
	var blend := clampf(delta * speed, 0.0, 1.0)
	visual_root.position = visual_root.position.lerp(target_position, blend)
	visual_root.scale = visual_root.scale.lerp(hover_target_scale, blend)
	visual_root.rotation = lerpf(visual_root.rotation, target_rotation, blend)

	if not should_press and hover_shake_time_left <= 0.0 and _hover_transform_is_at_rest():
		_reset_hover_transform()
		set_process(false)


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
	elif event is InputEventMouseMotion:
		if hover_effect_active and _can_play_hover_effect():
			_update_hover_press_targets()


func render(
	new_die_data: DieViewData,
	new_style_config: BattleUiStyleConfig,
	new_icon_library: BattleIconLibrary,
	new_dice_visual_library: DiceVisualLibrary
) -> void:
	if not is_node_ready():
		call_deferred("render", new_die_data, new_style_config, new_icon_library, new_dice_visual_library)
		return

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
		_stop_hover_effect(true)
		return

	title_label.text = str(TranslationServer.translate(&"AUTO.TEXT.F5833D7A3D75")) % [die_data.die_index + 1]
	title_label.visible = false
	button_pressed = die_data.selected
	disabled = die_data.disabled
	tooltip_text = "%s / D%d" % [die_data.body_name, die_data.face_count]
	_refresh_visuals()
	if not _can_play_hover_effect():
		_stop_hover_effect(false)


func set_info_focused(value: bool) -> void:
	info_focused = value
	_refresh_visuals()


func get_magic_fx_global_rect() -> Rect2:
	if body_icon != null and body_icon.visible:
		return body_icon.get_global_rect()
	return get_global_rect()


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
		state_label.text = str(TranslationServer.translate(&"AUTO.TEXT.BE70BE5A2E12"))
	elif die_data.scored:
		state_label.text = str(TranslationServer.translate(&"AUTO.TEXT.4C8D3F952240"))
	elif info_focused:
		state_label.text = str(TranslationServer.translate(&"AUTO.TEXT.BAF2E11995C5"))
	elif die_data.selected:
		state_label.text = str(TranslationServer.translate(&"AUTO.TEXT.743AAF951E5D"))
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


func _on_mouse_entered() -> void:
	_emit_hovered()
	if not _can_play_hover_effect():
		return
	hover_effect_active = true
	hover_shake_time_left = HOVER_SHAKE_SECONDS
	_update_hover_press_targets()
	set_process(true)


func _on_mouse_exited() -> void:
	_stop_hover_effect(false)


func _can_play_hover_effect() -> bool:
	return die_data != null and die_data.rerollable and not die_data.disabled and not disabled


func _stop_hover_effect(immediate: bool) -> void:
	hover_effect_active = false
	hover_shake_time_left = 0.0
	hover_target_position = Vector2.ZERO
	hover_target_scale = Vector2.ONE
	hover_target_rotation = 0.0
	if immediate:
		_reset_hover_transform()
		set_process(false)
	else:
		set_process(true)


func _update_hover_press_targets() -> void:
	if visual_root == null:
		return
	var visual_size := visual_root.size
	if visual_size.x <= 0.0 or visual_size.y <= 0.0:
		return

	var local_mouse := get_local_mouse_position()
	var normalized := Vector2(
		clampf(local_mouse.x / visual_size.x, 0.0, 1.0) * 2.0 - 1.0,
		clampf(local_mouse.y / visual_size.y, 0.0, 1.0) * 2.0 - 1.0
	)
	var horizontal_press := absf(normalized.x) * HOVER_PRESS_STRENGTH
	var vertical_press := absf(normalized.y) * HOVER_PRESS_STRENGTH
	var center_press := (1.0 - clampf(normalized.length() / sqrt(2.0), 0.0, 1.0)) * HOVER_CENTER_PRESS
	hover_target_scale = Vector2(
		1.0 - center_press - horizontal_press + vertical_press * 0.36,
		1.0 - center_press - vertical_press + horizontal_press * 0.36
	)
	hover_target_position = -normalized * HOVER_SHIFT_PIXELS
	hover_target_rotation = -normalized.x * HOVER_TILT_RADIANS


func _hover_transform_is_at_rest() -> bool:
	return (
		visual_root.position.distance_to(Vector2.ZERO) <= 0.08
		and visual_root.scale.distance_to(Vector2.ONE) <= 0.002
		and absf(visual_root.rotation) <= 0.002
	)


func _reset_hover_transform() -> void:
	if visual_root == null:
		return
	visual_root.position = Vector2.ZERO
	visual_root.scale = Vector2.ONE
	visual_root.rotation = 0.0


func _set_descendant_mouse_filter(node: Node, filter: int) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = filter
		_set_descendant_mouse_filter(child, filter)
