extends RefCounted
class_name GmDiceDefinition


const GmDiceFaceDefinitionScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceFaceDefinition.gd")


var id: StringName = &"gm_test_d6"
var display_name: String = "测试骰子"
var dice_type: StringName = &"normal"
var description: String = "GM 复刻原型用的标准六面骰。"
var faces: Array = []
var score_expr: String = "POINT"
var effects: Array[String] = []


static func create_standard_d6() -> GmDiceDefinition:
	var definition := GmDiceDefinition.new()
	definition.id = &"gm_standard_d6"
	definition.display_name = "标准六面骰"
	definition.description = "按 1 到 6 的点数参与测试结算。"
	definition.faces.clear()
	for value in range(1, 7):
		definition.faces.append(GmDiceFaceDefinitionScript.make(value, str(value)))
	return definition


func get_face(index: int) -> GmDiceFaceDefinition:
	if index < 0 or index >= faces.size():
		return null
	return faces[index] as GmDiceFaceDefinition


func get_face_count() -> int:
	return faces.size()


func get_face_index_for_value(face_value: int) -> int:
	for index in range(faces.size()):
		var face := faces[index] as GmDiceFaceDefinition
		if face != null and face.value == face_value:
			return index
	return -1


func to_dictionary() -> Dictionary:
	var face_rows: Array = []
	for face in faces:
		if face != null and face.has_method("to_dictionary"):
			face_rows.append(face.to_dictionary())
	return {
		"id": str(id),
		"display_name": display_name,
		"dice_type": str(dice_type),
		"description": description,
		"faces": face_rows,
		"score_expr": score_expr,
		"effects": effects,
	}
