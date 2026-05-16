extends RefCounted
class_name ComboInfoRowData


var combo_id: StringName = &""
var combo_name: String = ""
var level: int = 1
var chips: int = 0
var mult: int = 1
var occurrence_count: int = 0
var highlighted: bool = false


func setup(
	new_combo_id: StringName,
	new_combo_name: String,
	new_level: int,
	new_chips: int,
	new_mult: int,
	new_occurrence_count: int,
	new_highlighted: bool = false
) -> void:
	combo_id = new_combo_id
	combo_name = new_combo_name
	level = max(1, new_level)
	chips = max(0, new_chips)
	mult = max(1, new_mult)
	occurrence_count = max(0, new_occurrence_count)
	highlighted = new_highlighted
