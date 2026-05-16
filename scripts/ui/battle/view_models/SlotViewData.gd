extends RefCounted
class_name SlotViewData


var id: StringName = &""
var display_name: String = ""
var icon_id: StringName = &""
var count: int = 0
var stack: int = 0
var tooltip: String = ""
var disabled: bool = false
var empty: bool = false


func setup_from_id(new_id: StringName, new_display_name: String = "", new_icon_id: StringName = &"") -> void:
	id = new_id
	display_name = new_display_name if new_display_name != "" else str(new_id)
	icon_id = new_icon_id if new_icon_id != &"" else new_id


func setup_empty() -> void:
	empty = true
	disabled = true
	display_name = ""
	icon_id = &""
