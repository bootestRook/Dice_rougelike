extends RefCounted
class_name HandState


const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


var hand_index: int = 0
var rolled_faces: Array[RolledFace] = []
var rerolls_used: int = 0
var scored: bool = false
var score_result: ScoreResult = null


func selected_faces() -> Array[RolledFace]:
	var result: Array[RolledFace] = []

	for rolled_face in rolled_faces:
		if rolled_face.selected:
			result.append(rolled_face)

	return result


func selected_count() -> int:
	return selected_faces().size()


func clear_selection() -> void:
	for rolled_face in rolled_faces:
		rolled_face.selected = false
