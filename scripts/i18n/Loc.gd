extends Node


const LocService = preload("res://scripts/i18n/LocService.gd")


signal locale_changed(locale: String)


const DEFAULT_LOCALE := LocService.DEFAULT_LOCALE


var _current_locale: String = DEFAULT_LOCALE


func _ready() -> void:
	set_locale(DEFAULT_LOCALE)


func set_locale(locale: String) -> void:
	_current_locale = LocService.set_locale(locale)
	locale_changed.emit(_current_locale)


func get_locale() -> String:
	return _current_locale


func t(key: StringName, args: Dictionary = {}, context: StringName = &"") -> String:
	return LocService.t(key, args, context)


func tn(
	singular_key: StringName,
	plural_key: StringName,
	count: int,
	args: Dictionary = {},
	context: StringName = &""
) -> String:
	return LocService.tn(singular_key, plural_key, count, args, context)
