extends RefCounted
class_name DieState


const FaceState = preload("res://scripts/core/dice/FaceState.gd")


var id: StringName = &""
var faces: Array[FaceState] = []


static func create_normal_d6(id: StringName) -> DieState:
	var die := DieState.new()
	die.id = id

	for pip in range(1, 7):
		var face := FaceState.new()
		face.pip = pip
		die.faces.append(face)

	return die


func clone() -> DieState:
	var cloned := DieState.new()
	cloned.id = id

	for face in faces:
		cloned.faces.append(face.clone())

	return cloned
