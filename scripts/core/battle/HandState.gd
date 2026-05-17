extends RefCounted
class_name HandState


const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


var hand_index: int = 0
var rolled_faces: Array[RolledFace] = []
var rerolls_used: int = 0
var scored: bool = false
var score_result: ScoreResult = null
var rerolled_die_ids_this_round: Dictionary = {}
var body_triggered_flags_this_round: Dictionary = {}


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


func mark_die_rerolled(rolled_face: RolledFace) -> void:
	var die_key := _die_key(rolled_face)
	if die_key != &"":
		rerolled_die_ids_this_round[die_key] = true


func was_die_rerolled(rolled_face: RolledFace) -> bool:
	var die_key := _die_key(rolled_face)
	return die_key != &"" and bool(rerolled_die_ids_this_round.get(die_key, false))


func _die_key(rolled_face: RolledFace) -> StringName:
	if rolled_face == null:
		return &""
	if rolled_face.die_id != &"":
		return rolled_face.die_id
	if rolled_face.die != null:
		if rolled_face.die.die_id != &"":
			return rolled_face.die.die_id
		return rolled_face.die.id
	return StringName("die_%d" % [rolled_face.die_index])
