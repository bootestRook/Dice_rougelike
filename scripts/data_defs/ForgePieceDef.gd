extends Resource
class_name ForgePieceDef


const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocService = preload("res://scripts/i18n/LocService.gd")


@export var id: StringName = &""
@export var name_key: StringName = &""
@export var desc_key: StringName = &""
@export var effect_key: StringName = &""
@export var rarity_key: StringName = &""
@export var rarity: StringName = &"common"
@export var operations: Array[ForgeOperationDef] = []
@export var archetype_tags: Array[StringName] = []

@export var rarity_id: StringName = &""
@export var operation: ForgeOperationDef = null


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
		return LocService.t(&"UI.REWARD.EFFECT_NONE")

	return LocService.t(&"UI.REWARD.EFFECT", {"effects": "\n".join(op_texts)})


func get_archetype_tags() -> Array[StringName]:
	var result: Array[StringName] = []
	for tag in archetype_tags:
		if tag != &"" and not result.has(tag):
			result.append(tag)
	return result


func get_archetype_tag_text() -> String:
	var tags := get_archetype_tags()
	if tags.is_empty():
		return LocService.t(&"UI.REWARD.ARCHETYPE_TAG_NONE")

	var tag_texts := PackedStringArray()
	for tag in tags:
		tag_texts.append(LocService.t(LocKeys.tag_key(tag)))
	return ", ".join(tag_texts)


func get_display_text() -> String:
	var lines := PackedStringArray()

	lines.append(LocService.t(get_name_key()))
	lines.append(LocService.t(get_desc_key()))
	lines.append(LocService.t(&"UI.REWARD.RARITY", {"rarity": LocService.t(get_rarity_key())}))
	lines.append(LocService.t(&"UI.REWARD.ARCHETYPE_TAGS", {"tags": get_archetype_tag_text()}))
	lines.append(get_effect_text())

	return "\n".join(lines)


func get_debug_text() -> String:
	return get_display_text()
