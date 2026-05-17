extends RefCounted
class_name DieState


const FaceState = preload("res://scripts/core/dice/FaceState.gd")


const VALID_FACE_COUNTS := [4, 6, 8]
const LOW_DOMAIN_PIPS := [1, 2, 3, 4]
const HIGH_DOMAIN_PIPS := [5, 6, 7, 8]
const BODY_STANDARD := &"body_standard"
const BODY_IRON := &"body_iron"
const BODY_GLASS := &"body_glass"
const BODY_BIASED := &"body_biased"
const BODY_HOLLOW := &"body_hollow"
const BODY_MIRROR := &"body_mirror"
const BODY_CRACKED := &"body_cracked"
const BODY_MERCHANT := &"body_merchant"
const PIP_ID_TO_VALUE := {
	&"pip_1": 1,
	&"pip_2": 2,
	&"pip_3": 3,
	&"pip_4": 4,
	&"pip_5": 5,
	&"pip_6": 6,
	&"pip_7": 7,
	&"pip_8": 8,
}


var die_id: StringName = &""
var id: StringName = &""
var face_count: int = 6
var body_id: StringName = BODY_STANDARD
var face_weights: Array[int] = []
var faces: Array[FaceState] = []


static func create_normal_d6(id: StringName) -> DieState:
	var die := DieState.new()
	die.id = id
	die.die_id = id
	die.face_count = 6
	die.body_id = BODY_STANDARD
	die.face_weights.clear()

	for pip in range(1, 7):
		var face := FaceState.new(pip)
		die.faces.append(face)
		die.face_weights.append(1)

	return die


static func is_valid_pip(value: int) -> bool:
	return FaceState.is_valid_pip(value)


static func is_valid_face_count(value: int) -> bool:
	return VALID_FACE_COUNTS.has(value)


static func normalize_body_id(value: StringName) -> StringName:
	match value:
		&"", &"none", &"standard", BODY_STANDARD:
			return BODY_STANDARD
		&"iron", BODY_IRON:
			return BODY_IRON
		&"glass", BODY_GLASS:
			return BODY_GLASS
		&"biased", BODY_BIASED:
			return BODY_BIASED
		&"hollow", BODY_HOLLOW:
			return BODY_HOLLOW
		&"mirror", BODY_MIRROR:
			return BODY_MIRROR
		&"cracked", BODY_CRACKED:
			return BODY_CRACKED
		&"merchant", BODY_MERCHANT:
			return BODY_MERCHANT
		_:
			return value


static func get_legal_pips(value: int) -> Array[int]:
	var result: Array[int] = []
	match value:
		4:
			result.append_array([1, 2, 3, 4])
		6:
			result.append_array([1, 2, 3, 4, 5, 6])
		8:
			result.append_array([1, 2, 3, 4, 5, 6, 7, 8])
		_:
			push_error("Unsupported face_count: %s" % [value])
	return result


static func clamp_or_reset_pip_for_face_count(pip: int, value: int) -> int:
	if pip <= value:
		return pip
	if value == 4:
		return 4
	if value == 6:
		return 6
	return pip


static func pip_id_to_value(pip_id: StringName) -> int:
	return int(PIP_ID_TO_VALUE.get(pip_id, 0))


static func is_low_domain_pip(value: int) -> bool:
	return LOW_DOMAIN_PIPS.has(value)


static func is_high_domain_pip(value: int) -> bool:
	return HIGH_DOMAIN_PIPS.has(value)


func set_face_pip(face_index: int, new_pip: int) -> void:
	assert(is_valid_pip(new_pip))
	if face_index < 0 or face_index >= faces.size():
		push_warning("DieState.set_face_pip face_index out of range: %d" % [face_index])
		return
	if not is_valid_pip(new_pip):
		push_warning("DieState.set_face_pip invalid pip: %d" % [new_pip])
		return
	faces[face_index].pip = new_pip


func has_valid_shape() -> bool:
	return get_shape_errors().is_empty()


func get_shape_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if not is_valid_face_count(face_count):
		errors.append("invalid face_count: %d" % [face_count])
	if faces.size() != face_count:
		errors.append("faces.size() must equal face_count: %d != %d" % [faces.size(), face_count])
	if not face_weights.is_empty() and face_weights.size() != face_count:
		errors.append("face_weights.size() must equal face_count when weights are used: %d != %d" % [face_weights.size(), face_count])

	for face_index in range(faces.size()):
		var face := faces[face_index]
		if face == null:
			errors.append("faces[%d] is null" % [face_index])
			continue
		if not is_valid_pip(face.pip):
			errors.append("faces[%d].pip is out of range: %d" % [face_index, face.pip])
		elif not get_legal_pips(face_count).has(face.pip):
			errors.append("faces[%d].pip is illegal for D%d: %d" % [face_index, face_count, face.pip])
		if not FaceState.is_valid_face_ornament_id(face.ornament_id):
			errors.append("faces[%d].ornament_id cannot be installed on a face: %s" % [face_index, str(face.ornament_id)])

	return errors


func clone() -> DieState:
	var cloned := DieState.new()
	cloned.die_id = die_id if die_id != &"" else id
	cloned.id = id
	cloned.face_count = face_count
	cloned.body_id = normalize_body_id(body_id)
	for weight in face_weights:
		cloned.face_weights.append(weight)

	for face in faces:
		cloned.faces.append(face.clone())

	return cloned
