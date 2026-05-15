extends RichTextLabel


@export var loc_key: StringName
@export var loc_args: Dictionary = {}


func _ready() -> void:
	if not Loc.locale_changed.is_connected(_refresh):
		Loc.locale_changed.connect(_refresh)
	_refresh(Loc.get_locale())


func set_loc_key(key: StringName, args: Dictionary = {}) -> void:
	loc_key = key
	loc_args = args
	_refresh(Loc.get_locale())


func set_loc_args(args: Dictionary) -> void:
	loc_args = args
	_refresh(Loc.get_locale())


func _refresh(_locale: String = "") -> void:
	if loc_key == &"":
		text = ""
		return
	text = Loc.t(loc_key, loc_args)
