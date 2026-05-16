extends RefCounted
class_name ComboLevelDef


var upgrade_id: StringName = &""
var display_name: String = ""
var combo_id: StringName = &""
var priority: int = 0
var lv1_chips_bonus: int = 0
var lv1_mult: int = 1
var chips_per_level: int = 0
var mult_per_level: int = 0


func get_chips_bonus(level: int) -> int:
	var safe_level: int = max(1, level)
	return lv1_chips_bonus + (safe_level - 1) * chips_per_level


func get_mult(level: int) -> int:
	var safe_level: int = max(1, level)
	return lv1_mult + (safe_level - 1) * mult_per_level
