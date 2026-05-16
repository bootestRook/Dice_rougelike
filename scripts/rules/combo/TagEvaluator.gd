extends RefCounted
class_name TagEvaluator


const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")


const ALL_ODD := &"all_odd"
const ALL_EVEN := &"all_even"
const ALL_LOW := &"all_low"
const ALL_HIGH := &"all_high"
const LOW_TOTAL := &"low_total"
const HIGH_TOTAL := &"high_total"
const CONTAINS_SIX := &"contains_six"
const MANY_SIXES := &"many_sixes"
const FEW_SCORED := &"few_scored"
const REROLLED := &"rerolled"
const FIRST_ROLL_SCORED := &"first_roll_scored"
const LAST_HAND := &"last_hand"
const UNSCORED_STAY := &"unscored_stay"


func evaluate_tags(context) -> Array[StringName]:
	var tags: Array[StringName] = []

	if context == null:
		return tags

	if context.active_tags != null and not context.active_tags.is_empty():
		for tag in context.active_tags:
			if tag != &"":
				tags.append(tag)
		return tags

	for tag in context.tags:
		if tag != &"":
			tags.append(tag)

	return tags


func evaluate_facts(context) -> Dictionary:
	if context == null:
		return {}

	var resolver := ComboEvaluator.new()
	return resolver.evaluate_facts(
		context.selected_faces,
		context.all_rolled_faces,
		_has_rerolled(context),
		_is_last_hand(context),
		context
	)


func _is_last_hand(context) -> bool:
	if context.is_last_hand:
		return true

	if context.battle_state == null:
		return false

	var last_hand_index: int = max(0, int(context.battle_state.config.hands_per_battle) - 1)

	if context.hand_state != null:
		return context.hand_state.hand_index >= last_hand_index

	return context.battle_state.hands_played >= last_hand_index


func _has_rerolled(context) -> bool:
	if context.used_reroll:
		return true
	if context.rerolls_used > 0:
		return true
	if context.hand_state != null and context.hand_state.rerolls_used > 0:
		return true
	return false
