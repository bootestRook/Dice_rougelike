extends Resource
class_name ForgePieceDef


const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocService = preload("res://scripts/i18n/LocService.gd")


@export var id: StringName = &""
@export var name_key: StringName = &""
@export var desc_key: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var effect_key: StringName = &""
@export var rarity_key: StringName = &""
@export var rarity: StringName = &"common"
@export var operations: Array[ForgeOperationDef] = []
@export var archetype_tags: Array[StringName] = []
@export var tags: Array[StringName] = []

@export var rarity_id: StringName = &""
@export var operation: ForgeOperationDef = null
@export var item_modifier_id: StringName = &"mod_none"
@export var is_negative: bool = false


func get_operations() -> Array[ForgeOperationDef]:
	var result: Array[ForgeOperationDef] = []

	if not operations.is_empty():
		for op_def in operations:
			if op_def != null:
				result.append(op_def)
	elif operation != null:
		result.append(operation)

	return result


func get_rarity() -> StringName:
	if rarity != &"" and rarity != &"common":
		return rarity
	if rarity_id != &"":
		return rarity_id
	if rarity != &"":
		return rarity
	return &"common"


func get_name_key() -> StringName:
	if name_key != &"":
		return name_key
	return LocKeys.forge_part_name_key(id)


func get_desc_key() -> StringName:
	if desc_key != &"":
		return desc_key
	return LocKeys.forge_part_desc_key(id)


func get_rarity_key() -> StringName:
	if rarity_key != &"":
		return rarity_key
	return LocKeys.rarity_key(get_rarity())


func get_effect_key() -> StringName:
	return effect_key


func get_effect_text() -> String:
	if effect_key != &"":
		return LocService.t(effect_key)

	var op_texts := PackedStringArray()
	for op_def in get_operations():
		op_texts.append(op_def.get_display_text())

	if op_texts.is_empty():
		return "效果：无"

	return "效果：\n%s" % ["\n".join(op_texts)]


func get_display_name() -> String:
	if display_name != "":
		return display_name
	return LocService.t(get_name_key())


func get_description() -> String:
	if description != "":
		return description
	return LocService.t(get_desc_key())


func get_rarity_display_name() -> String:
	return DisplayNames.rarity_name(get_rarity())


static func get_tag_display_name(tag: StringName) -> String:
	return DisplayNames.forge_tag_name(tag)


func get_tags() -> Array[StringName]:
	var result: Array[StringName] = []
	for tag in tags:
		if tag != &"" and not result.has(tag):
			result.append(tag)
	for tag in archetype_tags:
		if tag != &"" and not result.has(tag):
			result.append(tag)
	return result


func get_tags_display_text() -> String:
	var tag_texts := PackedStringArray()
	for tag in get_tags():
		tag_texts.append(get_tag_display_name(tag))
	if tag_texts.is_empty():
		return "无"
	return " / ".join(tag_texts)


func get_archetype_tags() -> Array[StringName]:
	return get_tags()


func get_archetype_tag_text() -> String:
	return get_tags_display_text()


func get_display_text() -> String:
	var lines := PackedStringArray()
	lines.append(get_display_name())
	lines.append(get_description())
	lines.append("稀有度：%s" % [get_rarity_display_name()])
	lines.append("标签：%s" % [get_tags_display_text()])
	lines.append(get_effect_text())
	return "\n".join(lines)


func has_negative_modifier() -> bool:
	return is_negative or item_modifier_id == &"mod_negative"


func get_debug_text() -> String:
	return get_display_text()
