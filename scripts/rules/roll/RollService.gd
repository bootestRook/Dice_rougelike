extends RefCounted
class_name RollService


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")


var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func roll_all(dice: Array[DieState]) -> Array[RolledFace]:
	var results: Array[RolledFace] = []

	for die_index in range(dice.size()):
		results.append(roll_die(dice[die_index], die_index))

	return results


func roll_all_from_face_results(dice: Array[DieState], face_results: Dictionary) -> Array[RolledFace]:
	var results: Array[RolledFace] = []

	for die_index in range(dice.size()):
		var face_index := _face_index_from_results(face_results, die_index, 0)
		results.append(roll_die_at_face_index(dice[die_index], die_index, face_index))

	return results


func reroll_selected(dice: Array[DieState], current: Array[RolledFace]) -> Array[RolledFace]:
	var results: Array[RolledFace] = []
	var roll_count: int = current.size()

	for die_index in range(roll_count):
		var current_roll := current[die_index]

		if current_roll.selected:
			var rerolled := roll_temp_face(current_roll) if current_roll.is_temporary else roll_die(dice[die_index], die_index)
			rerolled.was_rerolled = true
			results.append(rerolled)
		else:
			results.append(current_roll)

	return results


func reroll_selected_from_face_results(
	dice: Array[DieState],
	current: Array[RolledFace],
	face_results: Dictionary
) -> Array[RolledFace]:
	var results: Array[RolledFace] = []
	var roll_count: int = current.size()

	for die_index in range(roll_count):
		var current_roll := current[die_index]

		if current_roll.selected:
			var rerolled := roll_temp_face(current_roll) if current_roll.is_temporary else roll_die_at_face_index(
				dice[die_index],
				die_index,
				_face_index_from_results(face_results, die_index, current_roll.face_index)
			)
			rerolled.was_rerolled = true
			results.append(rerolled)
		else:
			results.append(current_roll)

	return results


func roll_dice(dice: Array[DieState], external_rng: RandomNumberGenerator = null) -> Array[RolledFace]:
	var active_rng := _get_rng(external_rng)
	var results: Array[RolledFace] = []

	for die_index in range(dice.size()):
		results.append(roll_die(dice[die_index], die_index, active_rng))

	return results


func roll_die(die: DieState, die_index: int, external_rng: RandomNumberGenerator = null) -> RolledFace:
	var rolled_face := RolledFace.new()
	rolled_face.die_index = die_index

	if die == null:
		return rolled_face
	if not die.has_valid_shape():
		push_warning("RollService.roll_die invalid die shape: %s" % ["; ".join(die.get_shape_errors())])
		return rolled_face
	if die.faces.is_empty():
		return rolled_face

	var active_rng := _get_rng(external_rng)
	var face_index := _roll_face_index(die, active_rng)
	rolled_face.face_index = face_index
	rolled_face.die_id = die.die_id if die.die_id != &"" else die.id
	rolled_face.face_instance_id = RolledFace.make_face_instance_id(rolled_face.die_id, die_index, face_index)
	rolled_face.die = die
	rolled_face.face = die.faces[face_index].clone()
	rolled_face.rolled_pip = rolled_face.face.pip
	return rolled_face


func roll_die_at_face_index(die: DieState, die_index: int, face_index: int) -> RolledFace:
	var rolled_face := RolledFace.new()
	rolled_face.die_index = die_index

	if die == null:
		return rolled_face
	if not die.has_valid_shape():
		push_warning("RollService.roll_die_at_face_index invalid die shape: %s" % ["; ".join(die.get_shape_errors())])
		return rolled_face
	if die.faces.is_empty():
		return rolled_face

	var resolved_face_index := clampi(face_index, 0, die.faces.size() - 1)
	rolled_face.face_index = resolved_face_index
	rolled_face.die_id = die.die_id if die.die_id != &"" else die.id
	rolled_face.face_instance_id = RolledFace.make_face_instance_id(rolled_face.die_id, die_index, resolved_face_index)
	rolled_face.die = die
	rolled_face.face = die.faces[resolved_face_index].clone()
	rolled_face.rolled_pip = rolled_face.face.pip
	return rolled_face


func roll_temp_face(current_roll: RolledFace = null) -> RolledFace:
	var mark_id := FaceState.MARK_NONE
	var die_index := 1000
	var face_index := 0
	if current_roll != null:
		die_index = current_roll.die_index
		face_index = current_roll.face_index
		if current_roll.face != null:
			mark_id = current_roll.face.mark_id
	var face := FaceState.new(rng.randi_range(1, 6), FaceState.ORN_NONE, mark_id)
	var rolled_face := RolledFace.new()
	rolled_face.set_roll(die_index, face_index, face, null)
	rolled_face.is_temporary = true
	return rolled_face


func _roll_face_index(die: DieState, active_rng: RandomNumberGenerator) -> int:
	if die.face_weights.is_empty():
		return active_rng.randi_range(0, die.faces.size() - 1)
	if die.face_weights.size() != die.face_count:
		return active_rng.randi_range(0, die.faces.size() - 1)

	var total_weight := 0
	for weight in die.face_weights:
		total_weight += max(0, weight)
	if total_weight <= 0:
		return active_rng.randi_range(0, die.faces.size() - 1)

	var roll := active_rng.randi_range(1, total_weight)
	var running := 0
	for index in range(die.face_weights.size()):
		running += max(0, die.face_weights[index])
		if roll <= running:
			return index
	return die.faces.size() - 1


func _get_rng(external_rng: RandomNumberGenerator) -> RandomNumberGenerator:
	if external_rng != null:
		return external_rng

	return rng


func _face_index_from_results(face_results: Dictionary, die_index: int, fallback_face_index: int = 0) -> int:
	if face_results.has(die_index):
		return _face_index_from_result_value(face_results[die_index], fallback_face_index)
	var die_key := str(die_index)
	if face_results.has(die_key):
		return _face_index_from_result_value(face_results[die_key], fallback_face_index)
	return fallback_face_index


func _face_index_from_result_value(value, fallback_face_index: int) -> int:
	if value is Dictionary:
		return int((value as Dictionary).get("face_index", fallback_face_index))
	return int(value)
