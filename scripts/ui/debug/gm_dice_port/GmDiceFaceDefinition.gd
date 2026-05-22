extends RefCounted
class_name GmDiceFaceDefinition


var value: int = 1
var face_type: StringName = &"point"
var label: String = "1"
var effect_expr: String = ""


static func make(p_value: int, p_label: String = "", p_face_type: StringName = &"point", p_effect_expr: String = "") -> GmDiceFaceDefinition:
	var face := GmDiceFaceDefinition.new()
	face.value = p_value
	face.label = p_label if not p_label.is_empty() else str(p_value)
	face.face_type = p_face_type
	face.effect_expr = p_effect_expr
	return face


func clone() -> GmDiceFaceDefinition:
	return make(value, label, face_type, effect_expr)


func to_dictionary() -> Dictionary:
	return {
		"value": value,
		"face_type": str(face_type),
		"label": label,
		"effect_expr": effect_expr,
	}
