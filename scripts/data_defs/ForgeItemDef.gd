extends RefCounted
class_name ForgeItemDef


var id: StringName = &""
var display_name: String = ""
var description: String = ""
var effect_type: StringName = &""
var target_type: StringName = &""
var max_targets: int = 0
var generated_count: int = 0
var requires_item_slot: bool = false
var drop_pool_id: StringName = &"reserved"
var drop_weight: float = -1.0
var tags: Array[StringName] = []
var implementation_status: StringName = &"formal"
var payload: Dictionary = {}


func clone():
	var cloned = get_script().new()
	cloned.id = id
	cloned.display_name = display_name
	cloned.description = description
	cloned.effect_type = effect_type
	cloned.target_type = target_type
	cloned.max_targets = max_targets
	cloned.generated_count = generated_count
	cloned.requires_item_slot = requires_item_slot
	cloned.drop_pool_id = drop_pool_id
	cloned.drop_weight = drop_weight
	cloned.implementation_status = implementation_status
	cloned.payload = payload.duplicate(true)
	for tag in tags:
		cloned.tags.append(tag)
	return cloned


func get_display_name() -> String:
	return display_name if display_name != "" else str(id)


func get_description() -> String:
	return description


func is_formal() -> bool:
	return implementation_status == &"formal"
