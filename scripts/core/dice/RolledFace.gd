extends RefCounted
class_name RolledFace


const FaceState = preload("res://scripts/core/dice/FaceState.gd")


var die_index: int = -1
var face_index: int = -1
var face: FaceState = null
var locked: bool = false
var selected: bool = false


func set_roll(new_die_index: int, new_face_index: int, new_face: FaceState) -> void:
	die_index = new_die_index
	face_index = new_face_index
	face = new_face
