extends RefCounted
class_name TagEvaluator


const ALL_ODD := &"all_odd"
const ALL_EVEN := &"all_even"
const LOW_TOTAL := &"low_total"
const HIGH_TOTAL := &"high_total"
const CONTAINS_SIX := &"contains_six"
const MANY_SIXES := &"many_sixes"
const FEW_SCORED := &"few_scored"
const REROLLED := &"rerolled"
const LAST_HAND := &"last_hand"


func evaluate_tags(context) -> Array[StringName]:
	var tags: Array[StringName] = []

	if context.selected_faces.is_empty():
		return tags

	var total_pips := 0
	var selected_count := 0
	var six_count := 0
	var all_odd := true
	var all_even := true

	for rolled_face in context.selected_faces:
		if rolled_face.face == null:
			continue

		var pip: int = int(rolled_face.face.pip)
		selected_count += 1
		total_pips += pip
		if pip == 6:
			six_count += 1
		all_odd = all_odd and pip % 2 == 1
		all_even = all_even and pip % 2 == 0

	if selected_count == 0:
		return tags

	if all_odd:
		tags.append(ALL_ODD)
	if all_even:
		tags.append(ALL_EVEN)

	if total_pips <= 10:
		tags.append(LOW_TOTAL)
	if total_pips >= 25:
		tags.append(HIGH_TOTAL)
	if six_count >= 1:
		tags.append(CONTAINS_SIX)
	if six_count >= 3:
		tags.append(MANY_SIXES)
	if selected_count >= 1 and selected_count <= 3:
		tags.append(FEW_SCORED)
	if context.hand_state != null and context.hand_state.rerolls_used > 0:
		tags.append(REROLLED)
	if _is_last_hand(context):
		tags.append(LAST_HAND)

	return tags


func _is_last_hand(context) -> bool:
	if context.battle_state == null:
		return false

	var last_hand_index: int = max(0, int(context.battle_state.config.hands_per_battle) - 1)

	if context.hand_state != null:
		return context.hand_state.hand_index >= last_hand_index

	return context.battle_state.hands_played >= last_hand_index
