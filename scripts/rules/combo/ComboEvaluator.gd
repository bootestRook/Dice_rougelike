extends RefCounted
class_name ComboEvaluator


const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")


const MIN_PIP := 1
const MAX_PIP := 8
const LOW_DOMAIN_PIPS := [1, 2, 3, 4]
const HIGH_DOMAIN_PIPS := [5, 6, 7, 8]

const FIVE_KIND := &"five_kind"
const STRAIGHT := &"straight"
const FOUR_KIND := &"four_kind"
const FULL_HOUSE := &"full_house"
const THREE_KIND := &"three_kind"
const TWO_PAIR := &"two_pair"
const PAIR := &"pair"
const SCATTER := &"scatter"

const HIGH_CARD := SCATTER
const SMALL_STRAIGHT := STRAIGHT
const LARGE_STRAIGHT := STRAIGHT
const COMBO_HIGH_CARD := SCATTER

const CONTAINS_PAIR := &"contains_pair"
const CONTAINS_TWO_PAIR := &"contains_two_pair"
const CONTAINS_THREE_KIND := &"contains_three_kind"
const CONTAINS_FULL_HOUSE := &"contains_full_house"
const CONTAINS_FOUR_KIND := &"contains_four_kind"
const CONTAINS_FIVE_KIND := &"contains_five_kind"


func evaluate(pips: Array[int]) -> StringName:
	return evaluate_primary_combo(pips)


func resolve(
	scored_faces: Array,
	rolled_faces: Array = [],
	has_rerolled_this_hand: bool = false,
	is_last_hand: bool = false,
	context: ScoreContext = null
) -> Dictionary:
	var pips := _pips_from_values(scored_faces, context)

	var counts := _get_pip_counts(pips)
	var unique_pips := _get_sorted_unique_pips(counts)
	var pip_sum := _sum_pips_for_values(scored_faces, context)
	var primary := resolve_primary_combo(counts, unique_pips)
	var facts := _build_facts(
		pips,
		counts,
		pip_sum,
		scored_faces.size(),
		rolled_faces.size(),
		has_rerolled_this_hand,
		is_last_hand
	)
	var active_tags: Array[StringName] = []

	return {
		"primary_combo_id": primary,
		"primary_combo": primary,
		"facts": facts,
		"active_tags": active_tags,
		"condition_tags": [],
		"operation_tags": [],
		"state_tags": [],
	}


func evaluate_primary_combo(pips: Array[int]) -> StringName:
	var pip_counts := _get_pip_counts(pips)

	if pip_counts.is_empty():
		return SCATTER

	var unique_pips := _get_sorted_unique_pips(pip_counts)
	return resolve_primary_combo(pip_counts, unique_pips)


func resolve_primary_combo(pip_counts: Dictionary, unique_pips: Array[int]) -> StringName:
	var max_count := _get_max_count(pip_counts)

	if max_count >= 5:
		return FIVE_KIND
	if _has_straight(unique_pips, 5):
		return STRAIGHT
	if max_count >= 4:
		return FOUR_KIND
	if _is_full_house(pip_counts):
		return FULL_HOUSE
	if max_count >= 3:
		return THREE_KIND
	if _has_two_pair(pip_counts):
		return TWO_PAIR
	if max_count >= 2:
		return PAIR

	return SCATTER


func evaluate_contained_patterns(pips: Array[int]) -> Array[StringName]:
	var result: Array[StringName] = []
	return result


func evaluate_display_combos(pips: Array[int]) -> Array[StringName]:
	var result: Array[StringName] = []
	result.append(evaluate(pips))
	return result


func evaluate_rolls(selected_faces: Array[RolledFace]) -> StringName:
	return evaluate(_pips_from_rolls(selected_faces))


func evaluate_facts(
	scored_faces: Array,
	rolled_faces: Array = [],
	has_rerolled_this_hand: bool = false,
	is_last_hand: bool = false,
	context: ScoreContext = null
) -> Dictionary:
	return resolve(scored_faces, rolled_faces, has_rerolled_this_hand, is_last_hand, context)["facts"]


func normalize_combo_id(combo_id: StringName) -> StringName:
	match combo_id:
		&"FIVE_KIND", &"five_kind":
			return FIVE_KIND
		&"LARGE_STRAIGHT", &"SMALL_STRAIGHT", &"large_straight", &"small_straight", &"straight":
			return STRAIGHT
		&"FOUR_KIND", &"four_kind":
			return FOUR_KIND
		&"FULL_HOUSE", &"full_house":
			return FULL_HOUSE
		&"THREE_KIND", &"three_kind":
			return THREE_KIND
		&"TWO_PAIR", &"two_pair":
			return TWO_PAIR
		&"PAIR", &"pair":
			return PAIR
		&"HIGH_CARD", &"high_card", &"scatter":
			return SCATTER
		_:
			return combo_id


func _get_pip_counts(pips: Array[int]) -> Dictionary:
	var pip_counts := {}

	for pip in pips:
		pip_counts[pip] = int(pip_counts.get(pip, 0)) + 1

	return pip_counts


func _pips_from_values(values: Array, context: ScoreContext = null) -> Array[int]:
	var pips: Array[int] = []

	for value in values:
		var pip := _effective_pip_from_value(value, context)
		if pip > 0:
			pips.append(pip)

	return pips


func _sum_pips_for_values(values: Array, context: ScoreContext = null) -> int:
	var total := 0

	for value in values:
		var pip := _sum_pip_from_value(value, context)
		if pip > 0:
			total += pip

	return total


func _effective_pip_from_value(value, context: ScoreContext = null) -> int:
	if value is RolledFace and context != null:
		var pip = get_effective_pip_for_point_logic(value, context)
		return int(pip) if pip != null else 0
	return _pip_from_value(value)


func _sum_pip_from_value(value, context: ScoreContext = null) -> int:
	if value is RolledFace and context != null:
		var pip = get_pip_for_sum(value, context)
		return int(pip) if pip != null else 0
	return _pip_from_value(value)


static func get_effective_pip_for_point_logic(face_ref: RolledFace, context: ScoreContext) -> Variant:
	if face_ref == null or face_ref.face == null:
		return null

	var ornament_id := _effective_ornament_id_for_roll(face_ref, context)
	if ornament_id == FaceState.ORN_STONE:
		return null

	var key := "%d:%d" % [face_ref.die_index, face_ref.face_index]
	if ornament_id == FaceState.ORN_WILD and context != null and context.wild_effective_pips.has(key):
		return int(context.wild_effective_pips[key])

	return face_ref.face.pip


static func get_pip_for_sum(face_ref: RolledFace, _context: ScoreContext = null) -> Variant:
	if face_ref == null or face_ref.face == null:
		return null
	if _effective_ornament_id_for_roll(face_ref, _context) == FaceState.ORN_STONE:
		return null
	return face_ref.face.pip


static func _effective_ornament_id_for_roll(roll: RolledFace, context: ScoreContext = null) -> StringName:
	if roll == null:
		return FaceState.ORN_NONE

	var rolled_id := FaceState.ORN_NONE
	if roll.face != null:
		rolled_id = roll.face.get_effective_ornament_id()
		if rolled_id != FaceState.ORN_NONE:
			return rolled_id

	var source_face := _source_face_for_roll(roll, context)
	if source_face != null:
		return source_face.get_effective_ornament_id()
	return rolled_id


static func _source_face_for_roll(roll: RolledFace, context: ScoreContext = null) -> FaceState:
	if roll == null or context == null:
		return null
	if roll.die != null and roll.face_index >= 0 and roll.face_index < roll.die.faces.size():
		return roll.die.faces[roll.face_index]
	if roll.die_index >= 0 and roll.die_index < context.source_dice.size():
		var source_die = context.source_dice[roll.die_index]
		if source_die != null and roll.face_index >= 0 and roll.face_index < source_die.faces.size():
			return source_die.faces[roll.face_index]
	if context.battle_state != null and roll.die_index >= 0 and roll.die_index < context.battle_state.dice.size():
		var battle_die = context.battle_state.dice[roll.die_index]
		if battle_die != null and roll.face_index >= 0 and roll.face_index < battle_die.faces.size():
			return battle_die.faces[roll.face_index]
	return null


func _pip_from_value(value) -> int:
	if value == null:
		return 0
	if value is int:
		return int(value)
	if value is FaceState:
		return int(value.pip)
	if value is RolledFace:
		if value.face == null:
			return 0
		return int(value.face.pip)
	if value is Dictionary and value.has("pip"):
		return int(value["pip"])
	return 0


func _pips_from_rolls(selected_faces: Array[RolledFace]) -> Array[int]:
	var pips: Array[int] = []

	for rolled_face in selected_faces:
		if rolled_face.face != null:
			pips.append(rolled_face.face.pip)

	return pips


func _sum_pips(pips: Array[int]) -> int:
	var total := 0

	for pip in pips:
		total += pip

	return total


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


func _has_two_pair(pip_counts: Dictionary) -> bool:
	return _pair_count(pip_counts) >= 2


func _is_full_house(pip_counts: Dictionary) -> bool:
	for three_pip in pip_counts.keys():
		if int(pip_counts[three_pip]) < 3:
			continue
		for pair_pip in pip_counts.keys():
			if pair_pip == three_pip:
				continue
			if int(pip_counts[pair_pip]) >= 2:
				return true

	return false


func _has_straight(unique_pips: Array[int], length: int) -> bool:
	if unique_pips.size() < length:
		return false

	for start_pip in range(MIN_PIP, MAX_PIP - length + 2):
		var complete := true

		for offset in range(length):
			if not unique_pips.has(start_pip + offset):
				complete = false
				break

		if complete:
			return true

	return false


func _build_facts(
	pips: Array[int],
	counts: Dictionary,
	pip_sum: int,
	scored_count: int,
	rolled_count: int,
	has_rerolled_this_hand: bool,
	is_last_hand: bool
) -> Dictionary:
	if pips.is_empty():
		return {
			"has_pair_shape": false,
			"has_three_kind_shape": false,
			"has_four_kind_shape": false,
			"is_all_odd": false,
			"is_all_even": false,
			"is_all_low": false,
			"is_all_high": false,
			"is_low_total": false,
			"is_high_total": false,
			"contains_six": false,
			"has_many_sixes": false,
			"is_few_scored": scored_count >= 1 and scored_count <= 3,
			"has_rerolled": has_rerolled_this_hand,
			"is_first_roll_scored": not has_rerolled_this_hand,
			"is_last_hand": is_last_hand,
			"has_unscored_stay": rolled_count > scored_count,
		}

	return {
		"has_pair_shape": _has_count_at_least(counts, 2),
		"has_three_kind_shape": _has_count_at_least(counts, 3),
		"has_four_kind_shape": _has_count_at_least(counts, 4),
		"is_all_odd": _all_pips_in(pips, [1, 3, 5, 7]),
		"is_all_even": _all_pips_in(pips, [2, 4, 6, 8]),
		"is_all_low": _all_pips_in(pips, LOW_DOMAIN_PIPS),
		"is_all_high": _all_pips_in(pips, HIGH_DOMAIN_PIPS),
		"is_low_total": pip_sum <= 10,
		"is_high_total": pip_sum >= 25,
		"contains_six": pips.has(6),
		"has_many_sixes": int(counts.get(6, 0)) >= 3,
		"is_few_scored": scored_count >= 1 and scored_count <= 3,
		"has_rerolled": has_rerolled_this_hand,
		"is_first_roll_scored": not has_rerolled_this_hand,
		"is_last_hand": is_last_hand,
		"has_unscored_stay": rolled_count > scored_count,
	}


func _has_count_at_least(counts: Dictionary, threshold: int) -> bool:
	for count in counts.values():
		if int(count) >= threshold:
			return true

	return false


func _all_pips_in(pips: Array[int], allowed_pips: Array) -> bool:
	if pips.is_empty():
		return false

	for pip in pips:
		if not allowed_pips.has(pip):
			return false

	return true
