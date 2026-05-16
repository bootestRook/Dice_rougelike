extends RefCounted
class_name ItemInstance


const ComboUpgradeItem = preload("res://scripts/rules/combo/ComboUpgradeItem.gd")


const TYPE_GENERIC := &"generic"
const TYPE_FORGE_ITEM := &"forge_item"
const TYPE_COMBO_UPGRADE := &"combo_upgrade"
const TYPE_DICE_TOOL := &"dice_tool"


var item_id: StringName = &""
var item_type: StringName = TYPE_GENERIC
var display_name: String = ""
var source_id: StringName = &""
var sell_value: int = 0
var metadata: Dictionary = {}


static func create(new_item_id: StringName, new_item_type: StringName = TYPE_GENERIC, new_display_name: String = ""):
	var item = load("res://scripts/core/items/ItemInstance.gd").new()
	item.item_id = new_item_id
	item.item_type = new_item_type
	item.display_name = new_display_name if new_display_name != "" else str(new_item_id)
	return item


static func create_combo_upgrade(new_item_id: StringName):
	var combo_item := ComboUpgradeItem.from_item_id(new_item_id)
	var name := combo_item.display_name if combo_item != null else str(new_item_id)
	return create(new_item_id, TYPE_COMBO_UPGRADE, name)


static func create_forge_item(new_item_id: StringName, new_display_name: String = ""):
	return create(new_item_id, TYPE_FORGE_ITEM, new_display_name)


static func create_dice_tool(new_item_id: StringName, new_display_name: String = "", new_sell_value: int = 0):
	var item = create(new_item_id, TYPE_DICE_TOOL, new_display_name)
	item.sell_value = new_sell_value
	return item


func clone_as_new():
	var cloned = get_script().new()
	cloned.item_id = item_id
	cloned.item_type = item_type
	cloned.display_name = display_name
	cloned.source_id = source_id
	cloned.sell_value = sell_value
	cloned.metadata = metadata.duplicate(true)
	return cloned
