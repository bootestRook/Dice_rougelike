extends RefCounted
class_name BattleLogEntry


const LocService = preload("res://scripts/i18n/LocService.gd")


var key: StringName
var args: Dictionary
var category: StringName


func _init(
	p_key: StringName,
	p_args: Dictionary = {},
	p_category: StringName = &"general"
) -> void:
	key = p_key
	args = p_args.duplicate()
	category = p_category


func get_text() -> String:
	var formatted_args := {}

	for arg_key in args.keys():
		var value = args[arg_key]

		if value is StringName:
			formatted_args[arg_key] = LocService.t(value)
		else:
			formatted_args[arg_key] = value

	return LocService.t(key, formatted_args)
