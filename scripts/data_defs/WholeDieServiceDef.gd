extends RefCounted
class_name WholeDieServiceDef


var service_id: StringName = &""
var display_name: String = ""
var description: String = ""
var service_type: StringName = &"whole_die"
var target_rule: StringName = &"die"
var requires_confirmation: bool = true
var implementation_status: StringName = &"formal"
var reserved_drop_pool: StringName = &"TBD"
var reserved_drop_weight: StringName = &"TBD"


func clone() -> WholeDieServiceDef:
	var cloned := WholeDieServiceDef.new()
	cloned.service_id = service_id
	cloned.display_name = display_name
	cloned.description = description
	cloned.service_type = service_type
	cloned.target_rule = target_rule
	cloned.requires_confirmation = requires_confirmation
	cloned.implementation_status = implementation_status
	cloned.reserved_drop_pool = reserved_drop_pool
	cloned.reserved_drop_weight = reserved_drop_weight
	return cloned


func is_formal() -> bool:
	return implementation_status == &"formal"
