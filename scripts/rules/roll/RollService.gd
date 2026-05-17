extends RefCounted
class_name RollService


const DieState = preload("res://scripts/core/dice/DieState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")


var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func roll_all(dice: Array[DieState]) -> Array[RolledFace]:
	var results: Array[RolledFace] = []

	for die_index in range(dice.size()):
		results.append(roll_die(dice[die_index], die_index))

	return results


func reroll_unlocked(dice: Array[DieState], current: Array[RolledFace]) -> Array[RolledFace]:
	var results: Array[RolledFace] = []
	var roll_count: int = min(dice.size(), current.size())

	for die_index in range(roll_count):
		var current_roll := current[die_index]

		if current_roll.locked:
			results.append(current_roll)
		else:
			var rerolled := roll_die(dice[die_index], die_index)
			rerolled.was_rerolled = true
			results.append(rerolled)

	return results


func reroll_selected(dice: Array[DieState], current: Array[RolledFace]) -> Array[RolledFace]:
	var results: Array[RolledFace] = []
	var roll_count: int = min(dice.size(), current.size())

	for die_index in range(roll_count):
		var current_roll := current[die_index]

		if current_roll.selected:
			var rerolled := roll_die(dice[die_index], die_index)
			rerolled.was_rerolled = true
			results.append(rerolled)
		else:
			current_roll.locked = false
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
