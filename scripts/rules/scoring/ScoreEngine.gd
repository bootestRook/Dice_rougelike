extends RefCounted
class_name ScoreEngine


const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const ComboLevelSystem = preload("res://scripts/rules/combo/ComboLevelSystem.gd")
const EffectResolver = preload("res://scripts/rules/scoring/EffectResolver.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const BattleLogEntry = preload("res://scripts/log/BattleLogEntry.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")
const ResolutionTrace = preload("res://scripts/core/scoring/ResolutionTrace.gd")
const ResolutionStep = preload("res://scripts/core/scoring/ResolutionStep.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")


var effect_resolver := EffectResolver.new()


func score(context: ScoreContext) -> ScoreResult:
	var result := ScoreResult.new()
	_prepare_context(context)
	_ensure_wild_effective_pips(context)
	var total_pips := _selected_pip_sum(context)
	var combo_evaluator := ComboEvaluator.new()
	var resolution := combo_evaluator.resolve(
		context.selected_faces,
		context.all_rolled_faces,
		_has_rerolled(context),
		_context_is_last_hand(context),
		context
	)
	var primary_combo := _primary_combo_for_context(context, combo_evaluator, resolution)
	var contained_patterns := _contained_patterns_for_context(context)
	var facts := _facts_for_context(context, resolution)
	var active_tags := _active_tags_for_context(context)

	context.primary_combo = primary_combo
	context.combo_id = primary_combo
	context.combo_type = primary_combo
	context.display_combo_ids.clear()
	context.display_combo_ids.append(primary_combo)
	context.contained_patterns = contained_patterns
	context.facts = facts
	context.active_tags = active_tags
	context.tags = active_tags
	context.condition_tags.clear()
	context.operation_tags.clear()
	context.state_tags.clear()
	result.primary_combo = primary_combo
	result.combo_id = primary_combo
	result.combo_name_key = LocKeys.combo_key(primary_combo)
	_copy_display_combos(primary_combo, result)
	_copy_contained_patterns(contained_patterns, result)
	result.facts = facts.duplicate(true)
	_copy_active_tags(active_tags, result)

	var base_values := _base_values_for_combo(primary_combo, total_pips, _combo_levels_for_context(context))
	result.scored_point_sum = total_pips
	result.combo_level = int(base_values["level"])
	result.combo_chips_bonus = int(base_values["chips_bonus"])
	result.combo_mult = int(base_values["mult"])
	result.chips = result.combo_chips_bonus
	result.mult = int(base_values["mult"])
	result.xmult = 1.0

	_add_log(result, &"LOG.COMBO", {"combo": LocKeys.combo_key(primary_combo), "level": result.combo_level}, &"combo")
	_add_log(result, &"LOG.CONTAINED_PATTERNS", {"patterns": _contained_patterns_text(contained_patterns)}, &"patterns")
	_add_log(result, &"LOG.COMBO_CHIPS_BONUS", {"chips": result.combo_chips_bonus}, &"base")
	_add_log(result, &"LOG.COMBO_MULT", {"mult": result.combo_mult}, &"base")
	_add_log(result, &"LOG.PIP_SUM", {"sum": total_pips}, &"base")
	_add_log(result, &"LOG.BASE_CHIPS", {"chips": int(base_values["chips"])}, &"base")
	_add_log(result, &"LOG.BASE_MULT", {"mult": result.mult}, &"base")
	_add_log(result, &"LOG.BASE_XMULT", {"xmult": _format_xmult(result.xmult)}, &"base")
	_add_wild_choice_logs(context, result)

	var include_settlement_effects := not context.is_preview
	_apply_selected_rolls_for_resolution(context, result, null, include_settlement_effects)
	if include_settlement_effects:
		effect_resolver.apply_unselected_effects(context, result)
	result.recalculate_final_score()
	_add_log(result, &"LOG.FINAL_SCORE", {
		"chips": result.chips,
		"mult": result.mult,
		"xmult": _format_xmult(result.xmult),
		"score": result.final_score,
	}, &"final")
	effect_resolver.apply_post_score_effects(context, result)
	result.coins_delta = context.coins_delta
	for event in context.score_events:
		result.add_score_event(event)
	context.wild_effective_pips.clear()
	return result


func build_resolution_trace(context: ScoreContext) -> ResolutionTrace:
	var trace := ResolutionTrace.new()
	trace.trace_id = "resolution_%d" % [Time.get_ticks_usec()]
	trace.chips_initial = 0
	trace.mult_initial = 1
	trace.xmult_initial = 1.0

	if context == null:
		return trace

	var previous_defer_runtime_mutations := context.defer_runtime_mutations
	context.defer_runtime_mutations = true
	_prepare_context(context)
	_ensure_wild_effective_pips(context)
	context.selected_faces = _sorted_rolls_for_resolution(context.selected_faces, context.selected_die_order)
	context.scored_faces = context.selected_faces
	_mark_scored_and_unscored(context)
	_capture_trace_snapshots(trace, context)

	var total_pips := _selected_pip_sum(context)
	var combo_evaluator := ComboEvaluator.new()
	var resolution := combo_evaluator.resolve(
		context.selected_faces,
		context.all_rolled_faces,
		_has_rerolled(context),
		_context_is_last_hand(context),
		context
	)
	var primary_combo := _primary_combo_for_context(context, combo_evaluator, resolution)
	var contained_patterns := _contained_patterns_for_context(context)
	var facts := _facts_for_context(context, resolution)
	var active_tags := _active_tags_for_context(context)

	context.primary_combo = primary_combo
	context.combo_id = primary_combo
	context.combo_type = primary_combo
	context.display_combo_ids.clear()
	context.display_combo_ids.append(primary_combo)
	context.contained_patterns = contained_patterns
	context.facts = facts
	context.active_tags = active_tags
	context.tags = active_tags
	context.condition_tags.clear()
	context.operation_tags.clear()
	context.state_tags.clear()

	var base_values := _base_values_for_combo(primary_combo, total_pips, _combo_levels_for_context(context))
	var result := ScoreResult.new()
	result.primary_combo = primary_combo
	result.combo_id = primary_combo
	result.combo_name_key = LocKeys.combo_key(primary_combo)
	_copy_display_combos(primary_combo, result)
	_copy_contained_patterns(contained_patterns, result)
	result.facts = facts.duplicate(true)
	_copy_active_tags(active_tags, result)
	result.scored_point_sum = total_pips
	result.combo_level = int(base_values["level"])
	result.combo_chips_bonus = int(base_values["chips_bonus"])
	result.combo_mult = int(base_values["mult"])
	result.chips = 0
	result.mult = 1
	result.xmult = 1.0

	trace.primary_combo_id = primary_combo
	trace.primary_combo_display_name = DisplayNames.combo_name(primary_combo)
	trace.log_lines.append("Hand resolution")
	trace.log_lines.append("----------------")
	trace.log_lines.append("Primary combo: %s" % [trace.primary_combo_display_name])

	_add_log(result, &"LOG.COMBO", {"combo": LocKeys.combo_key(primary_combo), "level": result.combo_level}, &"combo")
	_add_log(result, &"LOG.CONTAINED_PATTERNS", {"patterns": _contained_patterns_text(contained_patterns)}, &"patterns")
	_add_log(result, &"LOG.COMBO_CHIPS_BONUS", {"chips": result.combo_chips_bonus}, &"base")
	_add_log(result, &"LOG.COMBO_MULT", {"mult": result.combo_mult}, &"base")

	_append_manual_step(
		trace,
		result,
		ResolutionStep.Phase.COMBO_BASE,
		&"combo",
		primary_combo,
		trace.primary_combo_display_name,
		"Primary combo: %s" % [trace.primary_combo_display_name],
		_combo_base_detail_text(result.combo_chips_bonus, result.combo_mult),
		trace.primary_combo_display_name,
		result.chips,
		result.mult,
		result.xmult,
		result.combo_chips_bonus,
		result.combo_mult,
		1.0
	)
	result.chips = result.combo_chips_bonus
	result.mult = result.combo_mult

	_add_wild_choice_logs(context, result)

	_add_log(result, &"LOG.PIP_SUM", {"sum": total_pips}, &"base")
	_add_log(result, &"LOG.BASE_CHIPS", {"chips": int(base_values["chips"])}, &"base")
	_add_log(result, &"LOG.BASE_MULT", {"mult": result.mult}, &"base")
	_add_log(result, &"LOG.BASE_XMULT", {"xmult": _format_xmult(result.xmult)}, &"base")

	_apply_selected_rolls_for_resolution(context, result, trace)
	effect_resolver.apply_unselected_effects(context, result, trace)
	result.recalculate_final_score()
	_add_log(result, &"LOG.FINAL_SCORE", {
		"chips": result.chips,
		"mult": result.mult,
		"xmult": _format_xmult(result.xmult),
		"score": result.final_score,
	}, &"final")

	_append_manual_step(
		trace,
		result,
		ResolutionStep.Phase.FINAL_SCORE,
		&"final",
		&"final_score",
		"Final score",
		"Final score",
		"%d x %d x %s = %d" % [result.chips, result.mult, _format_xmult(result.xmult), result.final_score],
		"+%d" % [result.final_score],
		result.chips,
		result.mult,
		result.xmult,
		result.chips,
		result.mult,
		result.xmult
	)

	result.coins_delta = context.coins_delta
	for event in context.score_events:
		result.add_score_event(event)

	trace.chips_final = result.chips
	trace.mult_final = result.mult
	trace.xmult_final = result.xmult
	trace.hand_score_final = result.final_score
	trace.score_result = result
	context.wild_effective_pips.clear()
	context.defer_runtime_mutations = previous_defer_runtime_mutations
	return trace


func recommend_wild_effective_pips(context: ScoreContext) -> Dictionary:
	_prepare_context(context)
	var wild_faces := _selected_wild_faces(context)
	var recommendations := {}
	if wild_faces.is_empty():
		return recommendations

	var enumerable_count: int = min(4, wild_faces.size())
	var base_choices := context.wild_effective_pips.duplicate(true)
	var best_choices := {}
	var best_rank := -1
	var best_temp_sum := -1
	var combo_evaluator := ComboEvaluator.new()
	var enumerated_choices: Array[Dictionary] = []

	_enumerate_wild_choices(context, wild_faces, enumerable_count, 0, base_choices, enumerated_choices)
	for choices in enumerated_choices:
		context.wild_effective_pips = choices.duplicate(true)
		var resolution := combo_evaluator.resolve(
			context.selected_faces,
			context.all_rolled_faces,
			_has_rerolled(context),
			_context_is_last_hand(context),
			context
		)
		var combo_id := StringName(str(resolution.get("primary_combo_id", ComboEvaluator.SCATTER)))
		var rank := _combo_rank(combo_id)
		var temp_sum := _wild_temp_sum(wild_faces, choices)
		if rank > best_rank or (rank == best_rank and temp_sum > best_temp_sum):
			best_rank = rank
			best_temp_sum = temp_sum
			best_choices = choices.duplicate(true)

	context.wild_effective_pips = base_choices
	for index in range(enumerable_count, wild_faces.size()):
		var roll: RolledFace = wild_faces[index]
		var key := _wild_key(roll)
		if not best_choices.has(key):
			best_choices[key] = _clamped_original_pip(roll)
	return best_choices


func get_effective_pip_for_point_logic(face_ref: RolledFace, context: ScoreContext) -> Variant:
	return ComboEvaluator.get_effective_pip_for_point_logic(face_ref, context)


func get_pip_for_sum(face_ref: RolledFace, context: ScoreContext) -> Variant:
	return ComboEvaluator.get_pip_for_sum(face_ref, context)


func get_effective_ornament_id_for_roll(roll: RolledFace, context: ScoreContext = null) -> StringName:
	return _effective_ornament_id_for_roll(roll, context)


func _sorted_rolls_for_resolution(rolls: Array[RolledFace], selected_die_order: Array[int] = []) -> Array[RolledFace]:
	var sorted: Array[RolledFace] = []
	for roll in rolls:
		if roll != null:
			sorted.append(roll)

	var order_lookup: Dictionary = {}
	for order_index in range(selected_die_order.size()):
		var die_index := int(selected_die_order[order_index])
		if not order_lookup.has(die_index):
			order_lookup[die_index] = order_index

	sorted.sort_custom(func(a: RolledFace, b: RolledFace) -> bool:
		var order_a := int(order_lookup.get(_bench_slot_index(a), 999999))
		var order_b := int(order_lookup.get(_bench_slot_index(b), 999999))
		if order_a == order_b:
			return _bench_slot_index(a) < _bench_slot_index(b)
		return order_a < order_b
	)
	return sorted


func _bench_slot_index(roll: RolledFace) -> int:
	if roll == null:
		return 999999
	return roll.die_index


func _capture_trace_snapshots(trace: ResolutionTrace, context: ScoreContext) -> void:
	if trace == null or context == null:
		return

	trace.selected_dice.clear()
	trace.unselected_dice.clear()
	trace.selected_slot_indices.clear()
	trace.selected_dice_order.clear()

	for roll in context.selected_faces:
		trace.selected_dice.append(_roll_snapshot(roll, context))
		trace.selected_slot_indices.append(roll.die_index)
		trace.selected_dice_order.append(roll.die_index)

	for roll in context.all_rolled_faces:
		if roll == null or _is_face_selected(roll, context):
			continue
		trace.unselected_dice.append(_roll_snapshot(roll, context))


func _roll_snapshot(roll: RolledFace, context: ScoreContext) -> Dictionary:
	if roll == null:
		return {}
	var face = roll.face
	var die = roll.die
	if die == null and context != null and roll.die_index >= 0 and roll.die_index < context.source_dice.size():
		die = context.source_dice[roll.die_index]
	if die == null and context != null and context.battle_state != null and roll.die_index >= 0 and roll.die_index < context.battle_state.dice.size():
		die = context.battle_state.dice[roll.die_index]

	return {
		"die_index": roll.die_index,
		"face_index": roll.face_index,
		"die_id": roll.die_id,
		"face_instance_id": roll.face_instance_id,
		"pip": face.pip if face != null else 0,
		"ornament_id": face.get_effective_ornament_id() if face != null else FaceState.ORN_NONE,
		"mark_id": face.mark_id if face != null else FaceState.MARK_NONE,
		"body_id": die.body_id if die != null else &"none",
		"face_count": die.face_count if die != null else 0,
	}


func _score_snapshot(result: ScoreResult) -> Dictionary:
	return {
		"chips": result.chips if result != null else 0,
		"mult": result.mult if result != null else 1,
		"xmult": result.xmult if result != null else 1.0,
	}


func _apply_selected_rolls_for_resolution(
	context: ScoreContext,
	result: ScoreResult,
	trace: ResolutionTrace = null,
	include_settlement_effects: bool = true
) -> void:
	if context == null or result == null:
		return

	for index in range(context.selected_faces.size()):
		var roll: RolledFace = context.selected_faces[index]
		_apply_roll_pip_score(roll, context, result, trace, index)
		if include_settlement_effects:
			effect_resolver.apply_selected_face_effects_for_roll(roll, context, result, trace)


func _apply_roll_pip_score(
	roll: RolledFace,
	context: ScoreContext,
	result: ScoreResult,
	trace: ResolutionTrace = null,
	resolution_index: int = -1
) -> void:
	if roll == null or result == null:
		return

	var pip = get_pip_for_sum(roll, context)
	var pip_value: int = int(pip) if pip != null else 0
	var before := _score_snapshot(result)
	result.chips += pip_value
	if trace == null:
		return

	_append_manual_step(
		trace,
		result,
		ResolutionStep.Phase.PIP_SCORE,
		&"face",
		&"pip",
		"Pip",
		"Die %d pip" % [roll.die_index + 1],
		"+%d Chips" % [pip_value],
		"+%d Chips" % [pip_value],
		int(before.get("chips", 0)),
		int(before.get("mult", 1)),
		float(before.get("xmult", 1.0)),
		result.chips,
		result.mult,
		result.xmult,
		roll.die_index,
		resolution_index
	)


func _append_manual_step(
	trace: ResolutionTrace,
	result: ScoreResult,
	phase: int,
	source_type: StringName,
	source_id: StringName,
	source_display_name: String,
	title: String,
	detail: String,
	floating_text: String,
	chips_before: int,
	mult_before: int,
	xmult_before: float,
	chips_after: int,
	mult_after: int,
	xmult_after: float,
	bench_slot_index: int = -1,
	resolution_index: int = -1
) -> void:
	if trace == null:
		return

	var step := ResolutionStep.new()
	step.phase = phase
	step.source_type = source_type
	step.source_id = source_id
	step.source_display_name = source_display_name
	step.title = title
	step.detail = detail
	step.floating_text = floating_text
	step.bench_slot_index = bench_slot_index
	step.resolution_index = resolution_index
	step.set_before(chips_before, mult_before, xmult_before)
	step.set_after(chips_after, mult_after, xmult_after)
	if phase == ResolutionStep.Phase.FINAL_SCORE and result != null:
		step.partial_score_after = result.final_score
	step.log_line = _manual_trace_log_line(step)
	trace.append_step(step)


func _manual_trace_log_line(step: ResolutionStep) -> String:
	var prefix := "[Step]"
	match step.phase:
		ResolutionStep.Phase.COMBO_BASE:
			prefix = "[Combo]"
		ResolutionStep.Phase.PIP_SCORE:
			prefix = "[Pip]"
		ResolutionStep.Phase.FINAL_SCORE:
			prefix = "[Final]"
		_:
			prefix = "[Step]"
	return "%s %s: %s" % [prefix, step.title, step.detail]


func _prepare_context(context: ScoreContext) -> void:
	if context == null:
		return
	if context.selected_faces.is_empty() and not context.scored_faces.is_empty():
		context.selected_faces = context.scored_faces
	if context.scored_faces.is_empty():
		context.scored_faces = context.selected_faces
	_mark_scored_and_unscored(context)


func _mark_scored_and_unscored(context: ScoreContext) -> void:
	context.unscored_faces.clear()
	var mutate_roll_resolution_flags := not context.is_preview
	for roll in context.all_rolled_faces:
		if roll == null:
			continue
		var selected := _is_face_selected(roll, context)
		if mutate_roll_resolution_flags:
			roll.is_scored = selected
			roll.is_unscored_stay = not selected
		if not selected:
			context.unscored_faces.append(roll)


func _selected_pip_sum(context: ScoreContext) -> int:
	var total := 0

	for rolled_face in context.selected_faces:
		var pip = get_pip_for_sum(rolled_face, context)
		if pip != null:
			total += int(pip)

	return total


func _ensure_wild_effective_pips(context: ScoreContext) -> void:
	if context == null:
		return
	var missing := false
	for roll in _selected_wild_faces(context):
		if not context.wild_effective_pips.has(_wild_key(roll)):
			missing = true
			break
	if not missing:
		return

	var recommendations := recommend_wild_effective_pips(context)
	for key in recommendations.keys():
		if not context.wild_effective_pips.has(key):
			context.wild_effective_pips[key] = recommendations[key]


func _selected_wild_faces(context: ScoreContext) -> Array[RolledFace]:
	var result: Array[RolledFace] = []
	if context == null:
		return result

	for roll in context.selected_faces:
		if roll == null or roll.face == null:
			continue
		if _effective_ornament_id_for_roll(roll, context) == FaceState.ORN_WILD:
			result.append(roll)
	return result


func _enumerate_wild_choices(
	context: ScoreContext,
	wild_faces: Array[RolledFace],
	enumerable_count: int,
	index: int,
	choices: Dictionary,
	output: Array[Dictionary]
) -> void:
	if index >= enumerable_count:
		output.append(choices.duplicate(true))
		return

	var roll: RolledFace = wild_faces[index]
	var key := _wild_key(roll)
	for pip in get_wild_pip_options(roll, context):
		choices[key] = pip
		_enumerate_wild_choices(context, wild_faces, enumerable_count, index + 1, choices, output)
	choices.erase(key)


func get_wild_pip_options(roll: RolledFace, context: ScoreContext = null) -> Array[int]:
	var options: Array[int] = []
	var face_count := _face_count_for_roll(roll, context)
	for pip in range(1, face_count + 1):
		options.append(pip)
	return options


func get_base_values_for_combo(combo_id: StringName, pip_total: int = 0, combo_levels: Dictionary = {}) -> Dictionary:
	return _base_values_for_combo(combo_id, pip_total, combo_levels).duplicate(true)


func _face_count_for_roll(roll: RolledFace, context: ScoreContext = null) -> int:
	if roll != null and roll.die != null and roll.die.face_count > 0:
		return clampi(roll.die.face_count, 1, FaceState.MAX_PIP)
	if context != null and roll != null and roll.die_index >= 0 and roll.die_index < context.source_dice.size():
		var source_die = context.source_dice[roll.die_index]
		if source_die != null and source_die.face_count > 0:
			return clampi(source_die.face_count, 1, FaceState.MAX_PIP)
	if context != null and context.battle_state != null and roll != null and roll.die_index >= 0 and roll.die_index < context.battle_state.dice.size():
		var battle_die = context.battle_state.dice[roll.die_index]
		if battle_die != null and battle_die.face_count > 0:
			return clampi(battle_die.face_count, 1, FaceState.MAX_PIP)
	return 6


func _clamped_original_pip(roll: RolledFace) -> int:
	if roll == null or roll.face == null:
		return 1
	var face_count := _face_count_for_roll(roll)
	return clampi(roll.face.pip, 1, face_count)


func _wild_key(roll: RolledFace) -> String:
	if roll == null:
		return "-1:-1"
	return "%d:%d" % [roll.die_index, roll.face_index]


func _wild_temp_sum(wild_faces: Array[RolledFace], choices: Dictionary) -> int:
	var total := 0
	for roll in wild_faces:
		var key := _wild_key(roll)
		total += int(choices.get(key, _clamped_original_pip(roll)))
	return total


func _combo_rank(combo_id: StringName) -> int:
	match ComboEvaluator.new().normalize_combo_id(combo_id):
		ComboEvaluator.FIVE_KIND:
			return 7
		ComboEvaluator.STRAIGHT:
			return 6
		ComboEvaluator.FOUR_KIND:
			return 5
		ComboEvaluator.FULL_HOUSE:
			return 4
		ComboEvaluator.THREE_KIND:
			return 3
		ComboEvaluator.TWO_PAIR:
			return 2
		ComboEvaluator.PAIR:
			return 1
		_:
			return 0


func _is_face_selected(roll: RolledFace, context: ScoreContext) -> bool:
	if roll == null or context == null:
		return false

	for selected_roll in context.selected_faces:
		if selected_roll == roll:
			return true
		if selected_roll != null and selected_roll.die_index == roll.die_index and selected_roll.face_index == roll.face_index:
			return true

	return false


func _add_wild_choice_logs(context: ScoreContext, result: ScoreResult) -> void:
	for roll in _selected_wild_faces(context):
		var key := _wild_key(roll)
		if not context.wild_effective_pips.has(key):
			continue
		_add_log(result, &"LOG.ORNAMENT_WILD", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"original": roll.face.pip if roll.face != null else 0,
			"pip": int(context.wild_effective_pips[key]),
		}, &"ornament_wild")


func _effective_ornament_id_for_roll(roll: RolledFace, context: ScoreContext = null) -> StringName:
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


func _source_face_for_roll(roll: RolledFace, context: ScoreContext = null) -> FaceState:
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


func _primary_combo_for_context(context: ScoreContext, combo_evaluator: ComboEvaluator, resolution: Dictionary) -> StringName:
	if context.primary_combo != &"":
		return combo_evaluator.normalize_combo_id(context.primary_combo)
	if context.combo_id != &"":
		return combo_evaluator.normalize_combo_id(context.combo_id)
	return StringName(str(resolution.get("primary_combo_id", ComboEvaluator.SCATTER)))


func _contained_patterns_for_context(context: ScoreContext) -> Array[StringName]:
	var copied: Array[StringName] = []
	for pattern in context.contained_patterns:
		if pattern != &"":
			copied.append(pattern)
	return copied


func _facts_for_context(context: ScoreContext, resolution: Dictionary) -> Dictionary:
	if not context.facts.is_empty():
		return context.facts.duplicate(true)
	return resolution.get("facts", {}).duplicate(true)


func _active_tags_for_context(context: ScoreContext) -> Array[StringName]:
	var source_tags := context.active_tags
	if source_tags.is_empty():
		source_tags = context.tags

	var copied: Array[StringName] = []
	for tag in source_tags:
		if tag != &"":
			copied.append(tag)
	return copied


func _copy_display_combos(primary_combo: StringName, result: ScoreResult) -> void:
	result.display_combo_ids.clear()
	if primary_combo != &"":
		result.display_combo_ids.append(primary_combo)


func _copy_contained_patterns(contained_patterns: Array[StringName], result: ScoreResult) -> void:
	result.contained_patterns.clear()
	for pattern in contained_patterns:
		result.contained_patterns.append(pattern)


func _copy_active_tags(active_tags: Array[StringName], result: ScoreResult) -> void:
	result.active_tags.clear()
	result.tags.clear()
	for tag in active_tags:
		result.active_tags.append(tag)
		result.tags.append(tag)


func _contained_patterns_text(contained_patterns: Array[StringName]) -> String:
	var names: Array[String] = []
	for pattern in contained_patterns:
		names.append(DisplayNames.contained_pattern_name(pattern))
	return DisplayNames.join_names(names)


func _combo_levels_for_context(context: ScoreContext) -> Dictionary:
	if context == null or context.run_state == null:
		return {}
	if context.run_state.has_method("ensure_combo_levels"):
		context.run_state.ensure_combo_levels()
	return context.run_state.combo_levels


func _base_values_for_combo(combo_id: StringName, pip_total: int, combo_levels: Dictionary = {}) -> Dictionary:
	var normalized_id := ComboEvaluator.new().normalize_combo_id(combo_id)
	return ComboLevelSystem.get_base_values(normalized_id, combo_levels, pip_total)


func _add_log(result: ScoreResult, key: StringName, args: Dictionary = {}, category: StringName = &"general") -> void:
	var entry := BattleLogEntry.new(key, args, category)
	result.add_log(entry)


func _format_xmult(value: float) -> String:
	return ScoreResult.format_multiplier(value)


func _combo_base_detail_text(chips_bonus: int, mult_value: int) -> String:
	return str(TranslationServer.translate(&"UI.SCORE_TRACE.COMBO_BASE_DETAIL")) % [chips_bonus, mult_value]


func _has_rerolled(context: ScoreContext) -> bool:
	if context.used_reroll:
		return true
	if context.rerolls_used > 0:
		return true
	if context.hand_state != null and context.hand_state.rerolls_used > 0:
		return true
	return false


func _context_is_last_hand(context: ScoreContext) -> bool:
	if context.is_last_hand:
		return true
	if context.battle_state == null:
		return false

	var last_hand_index: int = max(0, int(context.battle_state.config.hands_per_battle) - 1)
	if context.hand_state != null:
		return context.hand_state.hand_index >= last_hand_index
	return context.battle_state.hands_played >= last_hand_index
