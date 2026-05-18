extends RefCounted
class_name DiceToolDef


var tool_id: StringName = &""
var display_name: String = ""
var balatro_source_name: String = ""
var source_index: int = 0
var rarity: StringName = &"common"
var effect_text: String = ""
var trigger_timing: StringName = &""
var mechanic_tags: Array[StringName] = []
var archetype_tags: Array[StringName] = []
var implementation_status: StringName = &"formal"
var drop_pool_reserved: StringName = &"TBD"
var drop_weight_reserved = "TBD"
var state_fields: Array[StringName] = []
var notes: String = ""


func clone() -> DiceToolDef:
	var cloned := DiceToolDef.new()
	cloned.tool_id = tool_id
	cloned.display_name = display_name
	cloned.balatro_source_name = balatro_source_name
	cloned.source_index = source_index
	cloned.rarity = rarity
	cloned.effect_text = effect_text
	cloned.trigger_timing = trigger_timing
	cloned.mechanic_tags = mechanic_tags.duplicate()
	cloned.archetype_tags = archetype_tags.duplicate()
	cloned.implementation_status = implementation_status
	cloned.drop_pool_reserved = drop_pool_reserved
	cloned.drop_weight_reserved = drop_weight_reserved
	cloned.state_fields = state_fields.duplicate()
	cloned.notes = notes
	return cloned


func is_formal() -> bool:
	return implementation_status == &"formal"
