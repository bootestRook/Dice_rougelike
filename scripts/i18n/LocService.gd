extends RefCounted
class_name LocService


const DEFAULT_LOCALE := "zh_Hans"


static var current_locale: String = DEFAULT_LOCALE


static func set_locale(locale: String) -> String:
	current_locale = TranslationServer.standardize_locale(locale)
	TranslationServer.set_locale(current_locale)
	return current_locale


static func get_locale() -> String:
	return current_locale


static func t(key: StringName, args: Dictionary = {}, context: StringName = &"") -> String:
	var raw_key := str(key)
	var translated := str(TranslationServer.translate(key, context))

	if translated == raw_key:
		push_warning("Missing localization key: %s" % raw_key)

	if args.is_empty():
		return translated

	return translated.format(args)


static func tn(
	singular_key: StringName,
	plural_key: StringName,
	count: int,
	args: Dictionary = {},
	context: StringName = &""
) -> String:
	var translated := str(TranslationServer.translate_plural(
		singular_key,
		plural_key,
		count,
		context
	))

	var final_args := args.duplicate()
	final_args["count"] = count
	return translated.format(final_args)
