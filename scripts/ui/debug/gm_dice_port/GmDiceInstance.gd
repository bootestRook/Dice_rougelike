extends RefCounted
class_name GmDiceInstance


const GmDiceDefinitionScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")


var definition: GmDiceDefinition = null
var run_faces: Array = []
var value: int = 0
var avatar: Node = null
var can_roll: bool = true
var extra_score: int = 0
var buffs: Array = []
var enchanted: Array = []


static func from_definition(p_definition: GmDiceDefinition) -> GmDiceInstance:
	var instance := GmDiceInstance.new()
	instance.definition = p_definition
	if p_definition != null:
		instance.run_faces = p_definition.faces.duplicate(true)
	return instance


func set_face_index(face_index: int) -> void:
	if run_faces.is_empty():
		value = 0
		return
	value = clampi(face_index, 0, run_faces.size() - 1)


func resolve_face_request(requested_face) -> int:
	if run_faces.is_empty():
		return 0
	if requested_face == null:
		return -1
	var requested := int(requested_face)
	if requested < 0:
		return -1
	if requested >= 1 and requested <= 6:
		for index in range(run_faces.size()):
			var face = run_faces[index]
			if face != null and int(face.value) == requested:
				return index
	if requested >= 0 and requested < run_faces.size():
		return requested
	return -1


func get_actual_face_one() -> int:
	if value < 0 or value >= run_faces.size():
		return 0
	var face = run_faces[value]
	if face == null:
		return 0
	return int(face.value)


func get_actual_face_label() -> String:
	if value < 0 or value >= run_faces.size():
		return ""
	var face = run_faces[value]
	if face == null:
		return ""
	return str(face.label)


func get_actual_face() -> Array[int]:
	return [get_actual_face_one()]


func get_score_context() -> Dictionary:
	return {
		"POINT": get_actual_face_one(),
		"FACE_INDEX": value,
		"FACE_LABEL": get_actual_face_label(),
	}


func to_dictionary() -> Dictionary:
	return {
		"definition_id": str(definition.id) if definition != null else "",
		"definition_name": definition.display_name if definition != null else "",
		"value": value,
		"face_value": get_actual_face_one(),
		"face_label": get_actual_face_label(),
		"can_roll": can_roll,
		"extra_score": extra_score,
	}
