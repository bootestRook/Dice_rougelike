extends Resource
class_name DiceTemplateDef


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")


@export var id: StringName = &""
@export var name_key: StringName = &""
@export var desc_key: StringName = &""
@export var face_pips: PackedInt32Array = PackedInt32Array([1, 2, 3, 4, 5, 6])
@export var face_material_ids: Array[StringName] = []
@export var face_mark_ids: Array[StringName] = []
@export var face_rune_ids: Array[StringName] = []
@export var face_levels: PackedInt32Array = PackedInt32Array([])


func create_die_state(die_id: StringName) -> DieState:
	var die := DieState.new()
	die.id = die_id

	for face_index in range(face_pips.size()):
		var face := FaceState.new()
		face.pip = face_pips[face_index]
		face.material_id = _string_name_at(face_material_ids, face_index)
		face.mark_id = _string_name_at(face_mark_ids, face_index)
		face.rune_id = _string_name_at(face_rune_ids, face_index)
		face.level = _int_at(face_levels, face_index, 1)
		die.faces.append(face)

	return die


func _string_name_at(values: Array[StringName], index: int) -> StringName:
	if index < values.size():
		return values[index]

	return &""


func _int_at(values: PackedInt32Array, index: int, fallback: int) -> int:
	if index < values.size():
		return values[index]

	return fallback
