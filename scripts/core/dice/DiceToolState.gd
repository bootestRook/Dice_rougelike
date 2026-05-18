extends RefCounted
class_name DiceToolState


const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")


var tool_id: StringName = &""
var display_name: String = ""
var sell_value: int = 0
var rarity: StringName = &"common"
var is_negative: bool = false
var permanent_flags: Dictionary = {}
var permanent_counters: Dictionary = {}
var combat_counters: Dictionary = {}
var runtime_counters: Dictionary = {}
var metadata: Dictionary = {}


static func create(new_tool_id: StringName, new_display_name: String = "", new_sell_value: int = 0, new_rarity: StringName = &"common"):
	var tool = load("res://scripts/core/dice/DiceToolState.gd").new()
	tool.tool_id = new_tool_id
	tool.display_name = new_display_name if new_display_name != "" else str(new_tool_id)
	tool.sell_value = new_sell_value
	tool.rarity = new_rarity
	return tool


static func from_item_instance(item: ItemInstance):
	if item == null or item.item_type != ItemInstance.TYPE_DICE_TOOL:
		return null
	var tool = create(item.item_id, item.display_name, item.sell_value)
	tool.metadata = item.metadata.duplicate(true)
	tool.rarity = StringName(str(item.metadata.get("rarity", &"common")))
	tool.is_negative = bool(item.metadata.get("is_negative", false))
	tool.permanent_flags = item.metadata.get("permanent_flags", {}).duplicate(true)
	tool.permanent_counters = item.metadata.get("permanent_counters", {}).duplicate(true)
	tool.combat_counters = item.metadata.get("combat_counters", {}).duplicate(true)
	tool.runtime_counters = item.metadata.get("runtime_counters", {}).duplicate(true)
	return tool


func clone_without_combat_counters(copy_is_negative: bool = false):
	var cloned = get_script().new()
	cloned.tool_id = tool_id
	cloned.display_name = display_name
	cloned.sell_value = sell_value
	cloned.rarity = rarity
	cloned.is_negative = is_negative if copy_is_negative else false
	cloned.permanent_flags = permanent_flags.duplicate(true)
	cloned.permanent_counters = permanent_counters.duplicate(true)
	cloned.combat_counters = {}
	cloned.runtime_counters = {}
	cloned.metadata = metadata.duplicate(true)
	return cloned
