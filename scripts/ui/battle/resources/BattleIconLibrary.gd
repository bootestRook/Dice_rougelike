extends Resource
class_name BattleIconLibrary


@export var fallback_icon: Texture2D = null
@export var relic_icons: Dictionary = {}
@export var item_icons: Dictionary = {}
@export var ornament_icons: Dictionary = {}
@export var mark_icons: Dictionary = {}
@export var body_icons: Dictionary = {}

var _generated_fallback_icon: Texture2D = null


func get_relic_icon(id: StringName) -> Texture2D:
	return _get_icon(relic_icons, id)


func get_item_icon(id: StringName) -> Texture2D:
	return _get_icon(item_icons, id)


func get_ornament_icon(id: StringName) -> Texture2D:
	var optional := get_optional_ornament_icon(id)
	if optional != null:
		return optional
	return _get_fallback_icon()


func get_optional_ornament_icon(id: StringName) -> Texture2D:
	var icon := _get_optional_icon(ornament_icons, id)
	if icon != null:
		return icon
	return _get_optional_icon(ornament_icons, _legacy_ornament_id(id))


func get_mark_icon(id: StringName) -> Texture2D:
	var optional := _get_optional_icon(mark_icons, id)
	if optional != null:
		return optional
	optional = _get_optional_icon(mark_icons, _legacy_mark_id(id))
	if optional != null:
		return optional
	return _get_fallback_icon()


func get_optional_mark_icon(id: StringName) -> Texture2D:
	var optional := _get_optional_icon(mark_icons, id)
	if optional != null:
		return optional
	return _get_optional_icon(mark_icons, _legacy_mark_id(id))


func get_body_icon(id: StringName) -> Texture2D:
	return _get_icon(body_icons, id)


func get_icon(category: StringName, id: StringName) -> Texture2D:
	match category:
		&"relic":
			return get_relic_icon(id)
		&"item":
			return get_item_icon(id)
		&"ornament":
			return get_ornament_icon(id)
		&"mark":
			return get_mark_icon(id)
		&"body":
			return get_body_icon(id)
		_:
			return _get_fallback_icon()


func _get_icon(source: Dictionary, id: StringName) -> Texture2D:
	var optional := _get_optional_icon(source, id)
	if optional != null:
		return optional
	return _get_fallback_icon()


func _get_optional_icon(source: Dictionary, id: StringName) -> Texture2D:
	if source.has(id) and source[id] is Texture2D:
		return source[id]
	var string_id := str(id)
	if source.has(string_id) and source[string_id] is Texture2D:
		return source[string_id]
	return null


func _get_fallback_icon() -> Texture2D:
	if fallback_icon != null:
		return fallback_icon
	if _generated_fallback_icon == null:
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.7, 0.72, 0.66, 1.0))
		_generated_fallback_icon = ImageTexture.create_from_image(image)
	return _generated_fallback_icon


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
