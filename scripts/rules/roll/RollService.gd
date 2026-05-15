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
			results.append(roll_die(dice[die_index], die_index))

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

	if die.faces.is_empty():
		return rolled_face

	var active_rng := _get_rng(external_rng)
	var face_index := active_rng.randi_range(0, die.faces.size() - 1)
	rolled_face.face_index = face_index
	rolled_face.face = die.faces[face_index].clone()
	return rolled_face


func _get_rng(external_rng: RandomNumberGenerator) -> RandomNumberGenerator:
	if external_rng != null:
		return external_rng

	return rng
