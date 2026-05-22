extends RefCounted
class_name GmDiceFaceDefinition


const DiceFaceLayerSetScript := preload("res://scripts/ui/dice_face_layers/DiceFaceLayerSet.gd")


var value: int = 1
var face_type: StringName = &"point"
var label: String = "1"
var effect_expr: String = ""
var layer_set: DiceFaceLayerSet = null


static func make(p_value: int, p_label: String = "", p_face_type: StringName = &"point", p_effect_expr: String = "") -> GmDiceFaceDefinition:
	var face := GmDiceFaceDefinition.new()
	face.value = p_value
	face.label = p_label if not p_label.is_empty() else str(p_value)
	face.face_type = p_face_type
	face.effect_expr = p_effect_expr
	return face


func clone() -> GmDiceFaceDefinition:
	var face := make(value, label, face_type, effect_expr)
	face.layer_set = layer_set.clone() if layer_set != null else null
	return face


func to_dictionary() -> Dictionary:
	return {
		"value": value,
		"face_type": str(face_type),
		"label": label,
		"effect_expr": effect_expr,
		"layer_set": layer_set.to_dictionary() if layer_set != null else {},
	}
