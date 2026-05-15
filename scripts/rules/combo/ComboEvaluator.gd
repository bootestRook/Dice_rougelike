extends RefCounted
class_name ComboEvaluator


const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")


const HIGH_CARD := &"HIGH_CARD"
const PAIR := &"PAIR"
const TWO_PAIR := &"TWO_PAIR"
const THREE_KIND := &"THREE_KIND"
const SMALL_STRAIGHT := &"SMALL_STRAIGHT"
const FULL_HOUSE := &"FULL_HOUSE"
const FOUR_KIND := &"FOUR_KIND"
const LARGE_STRAIGHT := &"LARGE_STRAIGHT"
const FIVE_KIND := &"FIVE_KIND"

const COMBO_HIGH_CARD := HIGH_CARD


func evaluate(pips: Array[int]) -> StringName:
	var pip_counts := _get_pip_counts(pips)

	if pip_counts.is_empty():
		return HIGH_CARD

	var unique_pips := _get_sorted_unique_pips(pip_counts)
	var max_count := _get_max_count(pip_counts)

	if max_count >= 5:
		return FIVE_KIND
	if _has_straight(unique_pips, 5):
		return LARGE_STRAIGHT
	if max_count >= 4:
		return FOUR_KIND
	if _is_full_house(pip_counts):
		return FULL_HOUSE
	if _has_straight(unique_pips, 4):
		return SMALL_STRAIGHT
	if max_count >= 3:
		return THREE_KIND
	if _pair_count(pip_counts) >= 2:
		return TWO_PAIR
	if max_count >= 2:
		return PAIR

	return HIGH_CARD


func evaluate_rolls(selected_faces: Array[RolledFace]) -> StringName:
	return evaluate(_pips_from_rolls(selected_faces))


func _get_pip_counts(pips: Array[int]) -> Dictionary:
	var pip_counts := {}

	for pip in pips:
		pip_counts[pip] = int(pip_counts.get(pip, 0)) + 1

	return pip_counts


func _pips_from_rolls(selected_faces: Array[RolledFace]) -> Array[int]:
	var pips: Array[int] = []

	for rolled_face in selected_faces:
		if rolled_face.face != null:
			pips.append(rolled_face.face.pip)

	return pips


func _get_sorted_unique_pips(pip_counts: Dictionary) -> Array[int]:
	var unique_pips: Array[int] = []

	for pip in pip_counts.keys():
		unique_pips.append(int(pip))

	unique_pips.sort()
	return unique_pips


func _get_max_count(pip_counts: Dictionary) -> int:
	var max_count := 0

	for count in pip_counts.values():
		max_count = max(max_count, int(count))

	return max_count


func _pair_count(pip_counts: Dictionary) -> int:
	var pairs := 0

	for count in pip_counts.values():
		if int(count) >= 2:
			pairs += 1

	return pairs


func _is_full_house(pip_counts: Dictionary) -> bool:
	var has_three := false
	var has_pair := false

	for count in pip_counts.values():
		var pip_count := int(count)
		has_three = has_three or pip_count == 3
		has_pair = has_pair or pip_count == 2

	return has_three and has_pair


func _has_straight(unique_pips: Array[int], length: int) -> bool:
	for start_pip in range(1, 8 - length):
		var complete := true

		for offset in range(length):
			if not unique_pips.has(start_pip + offset):
				complete = false
				break

		if complete:
			return true

	return false
