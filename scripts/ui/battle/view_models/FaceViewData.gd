extends RefCounted
class_name FaceViewData


const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")


var face_index: int = -1
var pip: int = 0
var ornament_id: StringName = &"orn_none"
var ornament_name: String = str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))
var mark_id: StringName = &"mark_none"
var mark_name: String = str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))


func setup_from_face(new_face_index: int, face) -> void:
	face_index = new_face_index

	if face == null:
		return

	pip = int(face.pip)
	ornament_id = _effective_ornament_id(face)
	ornament_name = DisplayNames.ornament_name(ornament_id)
	mark_id = face.mark_id
	mark_name = DisplayNames.mark_name(mark_id)


static func _effective_ornament_id(face) -> StringName:
	if face == null:
		return &"none"
	if face.has_method("get_effective_ornament_id"):
		return face.get_effective_ornament_id()
	return face.ornament_id
