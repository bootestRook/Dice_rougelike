extends RefCounted
class_name ComboUpgradeItem


const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")


var item_id: StringName = &""
var target_combo_id: StringName = &""
var display_name: String = ""


static func create_for_combo(primary_combo_id: StringName) -> ComboUpgradeItem:
	var combo_id := ComboUpgradeCatalog.normalize_combo_id(primary_combo_id)
	if not ComboUpgradeCatalog.has_combo(combo_id):
		return null

	var item := ComboUpgradeItem.new()
	item.item_id = ComboUpgradeCatalog.item_id_for_combo(combo_id)
	item.target_combo_id = combo_id
	item.display_name = ComboUpgradeCatalog.display_name_for_combo(combo_id)
	return item


static func from_item_id(id: StringName) -> ComboUpgradeItem:
	var combo_id := ComboUpgradeCatalog.combo_id_from_item_id(id)
	if combo_id == &"" or not ComboUpgradeCatalog.has_combo(combo_id):
		return null

	var item := create_for_combo(combo_id)
	item.item_id = id
	return item


func apply_to_combo_levels(combo_levels: Dictionary) -> bool:
	if target_combo_id == &"" or not ComboUpgradeCatalog.has_combo(target_combo_id):
		return false
	var current_level: int = max(1, int(combo_levels.get(target_combo_id, 1)))
	combo_levels[target_combo_id] = current_level + 1
	return true
