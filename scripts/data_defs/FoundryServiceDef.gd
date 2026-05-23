extends RefCounted
class_name FoundryServiceDef


var service_id: StringName = &""
var display_name: String = ""
var description: String = ""
var service_type: StringName = &""
var implementation_status: StringName = &"formal"
var rarity: StringName = &"common"
var drop_pool: StringName = &"TBD"
var drop_weight: float = -1.0
var requires_item_slot: bool = false
var target_rule: StringName = &"none"
var risk_note: String = ""


func clone():
	var cloned = get_script().new()
	cloned.service_id = service_id
	cloned.display_name = display_name
	cloned.description = description
	cloned.service_type = service_type
	cloned.implementation_status = implementation_status
	cloned.rarity = rarity
	cloned.drop_pool = drop_pool
	cloned.drop_weight = drop_weight
	cloned.requires_item_slot = requires_item_slot
	cloned.target_rule = target_rule
	cloned.risk_note = risk_note
	return cloned


func get_display_name() -> String:
	return display_name if display_name != "" else str(service_id)


func get_description() -> String:
	return description


func is_formal() -> bool:
	return implementation_status == &"formal"
