extends RefCounted
class_name DiceToolState


const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")


var tool_id: StringName = &""
var display_name: String = ""
var sell_value: int = 0
var metadata: Dictionary = {}


static func create(new_tool_id: StringName, new_display_name: String = "", new_sell_value: int = 0):
	var tool = load("res://scripts/core/dice/DiceToolState.gd").new()
	tool.tool_id = new_tool_id
	tool.display_name = new_display_name if new_display_name != "" else str(new_tool_id)
	tool.sell_value = new_sell_value
	return tool


static func from_item_instance(item: ItemInstance):
	if item == null or item.item_type != ItemInstance.TYPE_DICE_TOOL:
		return null
	var tool = create(item.item_id, item.display_name, item.sell_value)
	tool.metadata = item.metadata.duplicate(true)
	return tool
