extends RefCounted
class_name DieViewData


const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceViewData = preload("res://scripts/ui/battle/view_models/FaceViewData.gd")


var die_id: StringName = &""
var die_index: int = -1
var face_count: int = 0
var body_id: StringName = &"none"
var body_name: String = str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))
var current_face_index: int = -1
var current_face: FaceViewData = null
var faces: Array[FaceViewData] = []
var selected: bool = false
var rerollable: bool = false
var scored: bool = false
var disabled: bool = false


func setup_from_die(
	die,
	new_die_index: int,
	rolled_face = null,
	is_rerollable: bool = false,
	is_scored: bool = false,
	is_disabled: bool = false
) -> void:
	die_index = new_die_index

	if die == null:
		disabled = true
		return

	die_id = die.id
	face_count = int(die.face_count)
	body_id = DieState.normalize_body_id(die.body_id)
	body_name = DisplayNames.body_name(body_id)

	for face_index in range(die.faces.size()):
		var face_data = FaceViewData.new()
		face_data.setup_from_face(face_index, die.faces[face_index])
		faces.append(face_data)

	if face_count <= 0:
		face_count = faces.size()

	if rolled_face != null:
		current_face_index = int(rolled_face.face_index)
		current_face = FaceViewData.new()
		current_face.setup_from_face(current_face_index, rolled_face.face)
		selected = bool(rolled_face.selected)
	else:
		current_face = null

	rerollable = is_rerollable
	scored = is_scored
	disabled = is_disabled
