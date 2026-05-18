extends RefCounted
class_name RolledFace


const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")


var die_index: int = -1
var face_index: int = -1
var die_id: StringName = &""
var face_instance_id: String = ""
var die: DieState = null
var face: FaceState = null
var rolled_pip: int = 0
var locked: bool = false # deprecated: independent lock operation removed
var selected: bool = false
var was_rerolled: bool = false
var is_scored: bool = false
var is_unscored_stay: bool = false
var is_temporary: bool = false


func set_roll(new_die_index: int, new_face_index: int, new_face: FaceState, new_die: DieState = null) -> void:
	die_index = new_die_index
	face_index = new_face_index
	die = new_die
	if die != null:
		die_id = die.die_id if die.die_id != &"" else die.id
	else:
		die_id = StringName("die_%d" % [die_index])
	face_instance_id = make_face_instance_id(die_id, die_index, face_index)
	face = new_face
	rolled_pip = face.pip if face != null else 0


static func make_face_instance_id(source_die_id: StringName, source_die_index: int, source_face_index: int) -> String:
	var id_text := str(source_die_id)
	if id_text == "":
		id_text = "die_%d" % [source_die_index]
	return "%s:%d" % [id_text, source_face_index]
