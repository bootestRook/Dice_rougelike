extends RefCounted
class_name DieBodyDef


var body_id: StringName = &""
var display_name: String = ""
var description: String = ""
var implementation_status: StringName = &"formal"
var reserved_drop_pool: StringName = &"TBD"
var reserved_drop_weight: StringName = &"TBD"


func clone() -> DieBodyDef:
	var cloned := DieBodyDef.new()
	cloned.body_id = body_id
	cloned.display_name = display_name
	cloned.description = description
	cloned.implementation_status = implementation_status
	cloned.reserved_drop_pool = reserved_drop_pool
	cloned.reserved_drop_weight = reserved_drop_weight
	return cloned


func is_formal() -> bool:
	return implementation_status == &"formal"
