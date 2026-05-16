extends Resource
class_name DiceVisualLibrary


@export var fallback_die_texture: Texture2D = null
@export var body_textures: Dictionary = {}
@export var placeholder_body_textures: Array[Texture2D] = []
@export var placeholder_body_texture_paths: PackedStringArray = PackedStringArray()
@export var pip_textures: Dictionary = {}
@export var ornament_textures: Dictionary = {}
@export var mark_textures: Dictionary = {}
@export var state_overlay_textures: Dictionary = {}
@export var body_colors: Dictionary = {}
@export var pip_colors: Dictionary = {}
@export var default_body_color: Color = Color(0.12, 0.48, 0.68)
@export var default_top_color: Color = Color(0.92, 0.94, 0.88)
@export var default_pip_color: Color = Color(0.08, 0.1, 0.1)
@export var selected_outline_color: Color = Color(1.0, 0.05, 0.02)
@export var viewing_outline_color: Color = Color(1.0, 0.72, 0.18)
@export var disabled_tint_color: Color = Color(0.45, 0.48, 0.44)
@export var default_die_style: StyleBox = null
@export var selected_die_style: StyleBox = null
@export var rerollable_die_style: StyleBox = null
@export var scored_die_style: StyleBox = null
@export var disabled_die_style: StyleBox = null

var _generated_die_texture: Texture2D = null
var _loaded_placeholder_body_textures: Array[Texture2D] = []


func get_body_texture(body_id: StringName) -> Texture2D:
	return _get_texture(body_textures, body_id, _get_fallback_die_texture())


func get_custom_body_texture(body_id: StringName, _die_index: int = -1) -> Texture2D:
	var texture := _get_texture(body_textures, body_id, null)
	if texture != null:
		return texture
	if fallback_die_texture != null:
		return fallback_die_texture
	if not placeholder_body_textures.is_empty():
		return placeholder_body_textures[0]
	texture = _get_placeholder_body_texture_from_path()
	if texture != null:
		return texture
	return null


func get_pip_texture(pip: int) -> Texture2D:
	return _get_texture(pip_textures, StringName(str(pip)), null)


func get_ornament_texture(ornament_id: StringName) -> Texture2D:
	var texture := _get_texture(ornament_textures, ornament_id, null)
	if texture != null:
		return texture
	return _get_texture(ornament_textures, _legacy_ornament_id(ornament_id), null)


func get_mark_texture(mark_id: StringName) -> Texture2D:
	var texture := _get_texture(mark_textures, mark_id, null)
	if texture != null:
		return texture
	return _get_texture(mark_textures, _legacy_mark_id(mark_id), null)


func get_state_overlay_texture(selected: bool, rerollable: bool, scored: bool, disabled: bool) -> Texture2D:
	if disabled:
		return _get_texture(state_overlay_textures, &"disabled", null)
	if scored:
		return _get_texture(state_overlay_textures, &"scored", null)
	if selected:
		return _get_texture(state_overlay_textures, &"selected", null)
	if rerollable:
		return _get_texture(state_overlay_textures, &"rerollable", null)
	return null


func get_focus_state_overlay_texture(selected: bool, info_focused: bool, rerollable: bool, scored: bool, disabled: bool) -> Texture2D:
	if disabled:
		return _get_texture(state_overlay_textures, &"disabled", null)
	if info_focused:
		return _get_texture(state_overlay_textures, &"viewing", null)
	return get_state_overlay_texture(selected, rerollable, scored, disabled)


func get_die_style(selected: bool, rerollable: bool, scored: bool, disabled: bool) -> StyleBox:
	if disabled and disabled_die_style != null:
		return disabled_die_style
	if scored and scored_die_style != null:
		return scored_die_style
	if selected and selected_die_style != null:
		return selected_die_style
	if rerollable and rerollable_die_style != null:
		return rerollable_die_style
	if default_die_style != null:
		return default_die_style
	return StyleBoxEmpty.new()


func get_body_color(body_id: StringName) -> Color:
	return _get_color(body_colors, body_id, default_body_color)


func get_top_color(body_id: StringName) -> Color:
	var key := StringName("%s_top" % [str(body_id)])
	return _get_color(body_colors, key, default_top_color)


func get_pip_color(pip: int) -> Color:
	return _get_color(pip_colors, StringName(str(pip)), default_pip_color)


func get_outline_color(selected: bool, info_focused: bool, disabled: bool) -> Color:
	if disabled:
		return disabled_tint_color
	if info_focused:
		return viewing_outline_color
	if selected:
		return selected_outline_color
	return Color(0.07, 0.12, 0.12)


func _get_texture(source: Dictionary, id: StringName, fallback: Texture2D) -> Texture2D:
	if source.has(id) and source[id] is Texture2D:
		return source[id]
	var string_id := str(id)
	if source.has(string_id) and source[string_id] is Texture2D:
		return source[string_id]
	return fallback


func _get_color(source: Dictionary, id: StringName, fallback: Color) -> Color:
	if source.has(id) and source[id] is Color:
		return source[id]
	var string_id := str(id)
	if source.has(string_id) and source[string_id] is Color:
		return source[string_id]
	return fallback


func _legacy_ornament_id(id: StringName) -> StringName:
	match id:
		&"orn_chip":
			return &"chip"
		&"orn_mult":
			return &"mult"
		&"orn_burst":
			return &"burst"
		&"orn_stay":
			return &"stay"
		&"orn_stone":
			return &"stone"
		&"orn_gold":
			return &"gold"
		&"orn_lucky":
			return &"lucky"
		&"orn_foil":
			return &"foil"
		&"orn_holo":
			return &"holo"
		&"orn_poly":
			return &"poly"
		_:
			return id


func _legacy_mark_id(id: StringName) -> StringName:
	match id:
		&"mark_red":
			return &"red"
		&"mark_blue":
			return &"blue"
		&"mark_purple":
			return &"purple"
		&"mark_gold":
			return &"gold"
		&"mark_white":
			return &"white"
		_:
			return id


func _get_fallback_die_texture() -> Texture2D:
	if fallback_die_texture != null:
		return fallback_die_texture
	if _generated_die_texture == null:
		var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.88, 0.88, 0.82, 1.0))
		_generated_die_texture = ImageTexture.create_from_image(image)
	return _generated_die_texture


func _get_placeholder_body_texture_from_path() -> Texture2D:
	if placeholder_body_texture_paths.is_empty():
		return null
	_ensure_placeholder_body_textures_loaded()
	if _loaded_placeholder_body_textures.is_empty():
		return null
	return _loaded_placeholder_body_textures[0]


func _ensure_placeholder_body_textures_loaded() -> void:
	if not _loaded_placeholder_body_textures.is_empty():
		return
	for path in placeholder_body_texture_paths:
		var resource := ResourceLoader.load(path, "Texture2D")
		if resource is Texture2D:
			_loaded_placeholder_body_textures.append(resource)
			continue
		var image := Image.new()
		if image.load(path) != OK:
			continue
		_loaded_placeholder_body_textures.append(ImageTexture.create_from_image(image))
