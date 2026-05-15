extends RefCounted
class_name FaceState


var pip: int = 1
var material_id: StringName = &""
var mark_id: StringName = &""
var rune_id: StringName = &""
var level: int = 1


func clone() -> FaceState:
	var cloned := FaceState.new()
	cloned.pip = pip
	cloned.material_id = material_id
	cloned.mark_id = mark_id
	cloned.rune_id = rune_id
	cloned.level = level
	return cloned
