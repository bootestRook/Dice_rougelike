extends Node
class_name BattleController


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const RollService = preload("res://scripts/rules/roll/RollService.gd")
const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")
const ResolutionTrace = preload("res://scripts/core/scoring/ResolutionTrace.gd")
const BattleLogEntry = preload("res://scripts/log/BattleLogEntry.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const DiceToolService = preload("res://scripts/rules/dice_tools/DiceToolService.gd")


enum BattlePhase {
	INIT,
	WAITING_ACTION,
	SCORING,
	VICTORY,
	DEFEAT,
}


signal battle_started()
signal hand_started(hand_index: int)
signal dice_changed(rolls: Array)
signal rerolls_changed(rerolls_left: int)
signal score_changed(total_score: int, target_score: int)
signal selection_changed(selected_count: int)
signal hand_scored(result: ScoreResult)
signal battle_won()
signal battle_lost()
signal phase_changed(phase: int)
signal score_preview_changed(result)


var battle_state: BattleState = null
var hand_state: HandState = null
var run_state: RunState = null
var dice: Array[DieState] = []
var phase: int = BattlePhase.INIT

var roll_service := RollService.new()
var combo_evaluator := ComboEvaluator.new()
var score_engine := ScoreEngine.new()
var reward_generator := RewardGenerator.new()
var dice_tool_service := DiceToolService.new()
var score_rng := RandomNumberGenerator.new()
var pending_mark_logs: Array[BattleLogEntry] = []
var pending_mark_floating_texts: Array[Dictionary] = []
var pending_resolution_trace: ResolutionTrace = null
var pending_resolution_result: ScoreResult = null
var pending_resolution_context: ScoreContext = null
var external_roll_results_enabled: bool = false
var awaiting_initial_roll_results: bool = false
var awaiting_reroll_results: bool = false
var pending_reroll_selected_before: Array[RolledFace] = []
var pending_reroll_die_indices: Array[int] = []


func _init() -> void:
	score_rng.randomize()


func start_battle(config: BattleConfig = null, run_state: RunState = null) -> void:
	self.run_state = run_state
	var active_config: BattleConfig = config
	var battle_start_log_texts: Array[String] = []
	if active_config == null:
		active_config = BattleConfig.new()
	else:
		active_config = active_config.clone()

	if run_state != null:
		run_state.ensure_starting_dice()
		if not run_state.dice.is_empty():
			battle_start_log_texts = dice_tool_service.apply_battle_start_effects(run_state, active_config)
			dice = run_state.dice
			active_config.dice_count = dice.size()
			active_config.target_score = run_state.get_target_score()
			if run_state.is_boss_battle():
				active_config.is_boss_battle = true
			_apply_long_term_battle_parameters(active_config, run_state)
		else:
			dice = _create_normal_dice(active_config.dice_count)
	else:
		dice = _create_normal_dice(active_config.dice_count)

	battle_state = BattleState.new()
	battle_state.setup(active_config, dice)
	if run_state != null:
		run_state.current_battle = battle_state
	hand_state = null
	pending_mark_logs.clear()
	pending_mark_floating_texts.clear()
	_clear_pending_roll_requests()
	for text in battle_start_log_texts:
		if text != "":
			pending_mark_logs.append(BattleLogEntry.new(&"LOG.DICE_TOOL", {"text": text}, &"dice_tool"))
	pending_resolution_trace = null
	pending_resolution_result = null
	pending_resolution_context = null
	_set_phase(BattlePhase.INIT)
	battle_started.emit()
	score_changed.emit(battle_state.total_score, battle_state.config.target_score)
	start_next_hand()


func set_external_roll_results_enabled(enabled: bool) -> void:
	external_roll_results_enabled = enabled


func is_waiting_for_initial_roll_results() -> bool:
	return awaiting_initial_roll_results


func is_waiting_for_reroll_results() -> bool:
	return awaiting_reroll_results


func toggle_select(index: int) -> void:
	if not _can_change_dice_flags() or not _is_valid_roll_index(index):
		return

	var rolled_face := hand_state.rolled_faces[index]

	if rolled_face.selected:
		rolled_face.selected = false
	else:
		rolled_face.selected = true

	selection_changed.emit(_selected_count())
	dice_changed.emit(get_current_rolls())
	_emit_score_preview()


func reroll() -> void:
	if phase != BattlePhase.WAITING_ACTION or hand_state == null:
		return
	if not can_reroll():
		return

	if external_roll_results_enabled:
		return

	var selected_indices := begin_reroll_selected()
	if selected_indices.is_empty():
		return
	var face_results := _random_face_results_for_indices(selected_indices)
	if not commit_selected_reroll_results(face_results):
		cancel_pending_reroll()


func begin_reroll_selected() -> Array[int]:
	var selected_indices: Array[int] = []
	if phase != BattlePhase.WAITING_ACTION or hand_state == null:
		return selected_indices
	if awaiting_reroll_results or awaiting_initial_roll_results:
		return selected_indices
	if not can_reroll():
		return selected_indices

	_trigger_purple_marks_before_reroll()
	var selected_before_reroll := hand_state.selected_faces()
	for text in dice_tool_service.apply_reroll_before_effects(run_state, selected_before_reroll, hand_state, battle_state):
		pending_mark_logs.append(BattleLogEntry.new(&"LOG.DICE_TOOL", {"text": text}, &"dice_tool"))
	_mark_selected_dice_rerolled()

	for roll in selected_before_reroll:
		if roll != null:
			selected_indices.append(roll.die_index)

	pending_reroll_selected_before = selected_before_reroll.duplicate()
	pending_reroll_die_indices = selected_indices.duplicate()
	awaiting_reroll_results = true
	_set_phase(BattlePhase.INIT)
	score_preview_changed.emit(null)
	return selected_indices


func commit_selected_reroll_results(face_results: Dictionary) -> bool:
	if not awaiting_reroll_results or hand_state == null:
		return false
	if not _face_results_cover_indices(face_results, pending_reroll_die_indices):
		return false

	hand_state.rolled_faces = roll_service.reroll_selected_from_face_results(dice, hand_state.rolled_faces, face_results)
	hand_state.rerolls_used += 1
	for text in dice_tool_service.apply_reroll_after_effects(run_state, pending_reroll_selected_before, battle_state):
		pending_mark_logs.append(BattleLogEntry.new(&"LOG.DICE_TOOL", {"text": text}, &"dice_tool"))
	_clear_pending_reroll()
	_set_phase(BattlePhase.WAITING_ACTION)
	dice_changed.emit(get_current_rolls())
	rerolls_changed.emit(_rerolls_left())
	selection_changed.emit(_selected_count())
	_emit_score_preview()
	return true


func cancel_pending_reroll() -> void:
	if not awaiting_reroll_results:
		return
	_clear_pending_reroll()
	_set_phase(BattlePhase.WAITING_ACTION)
	dice_changed.emit(get_current_rolls())
	rerolls_changed.emit(_rerolls_left())
	selection_changed.emit(_selected_count())
	_emit_score_preview()


func score_selected(wild_effective_pips: Dictionary = {}) -> void:
	var trace := request_settle_selected(wild_effective_pips)
	if trace == null:
		return
	commit_pending_resolution()


func request_settle_selected(wild_effective_pips: Dictionary = {}, selected_die_order: Array[int] = []) -> ResolutionTrace:
	if phase != BattlePhase.WAITING_ACTION or not can_score():
		return null

	_set_phase(BattlePhase.SCORING)
	var context := _build_score_context()
	context.wild_effective_pips = wild_effective_pips.duplicate(true)
	context.selected_die_order = selected_die_order.duplicate()
	context.defer_runtime_mutations = true

	var trace := score_engine.build_resolution_trace(context)
	var result := trace.score_result
	if result == null:
		result = ScoreResult.new()
		result.final_score = trace.hand_score_final

	hand_state.scored = true
	hand_state.score_result = result
	pending_resolution_trace = trace
	pending_resolution_result = result
	pending_resolution_context = context
	var log_count_before_pending_marks := result.logs.size()
	_consume_pending_mark_events(result)
	_append_pending_mark_logs_to_trace(trace, result, log_count_before_pending_marks)
	_clear_selection_after_resolution_request()
	score_preview_changed.emit(null)
	return trace


func commit_pending_resolution() -> void:
	if pending_resolution_trace == null:
		return
	if battle_state == null or hand_state == null:
		_clear_pending_resolution()
		return

	var trace := pending_resolution_trace
	var result := pending_resolution_result
	if result == null:
		result = ScoreResult.new()
		result.final_score = trace.hand_score_final

	battle_state.total_score += trace.hand_score_final
	battle_state.hands_played += 1
	_apply_pending_score_events(result)
	if pending_resolution_context != null:
		pending_resolution_context.defer_runtime_mutations = false
		dice_tool_service.apply_round_end_effects(pending_resolution_context, result)
	_apply_pending_post_resolution_mutations(result)

	if battle_state.total_score >= battle_state.config.target_score:
		_mark_battle_finished(true, result)
	elif battle_state.hands_played >= battle_state.config.hands_per_battle:
		var avoided_failure := dice_tool_service.try_apply_bone_safety(run_state, battle_state, result)
		_mark_battle_finished(avoided_failure, result)

	hand_scored.emit(result)
	score_preview_changed.emit(null)
	score_changed.emit(battle_state.total_score, battle_state.config.target_score)
	_clear_pending_resolution()

	if battle_state.battle_finished:
		_emit_battle_finished()
		return

	start_next_hand()


func start_next_hand() -> void:
	if battle_state == null or battle_state.battle_finished:
		return
	if battle_state.hands_played >= battle_state.config.hands_per_battle:
		_set_phase(BattlePhase.DEFEAT)
		battle_lost.emit()
		return

	hand_state = HandState.new()
	hand_state.hand_index = battle_state.hands_played
	if external_roll_results_enabled:
		hand_state.rolled_faces = roll_service.roll_all_from_face_results(dice, {})
		awaiting_initial_roll_results = true
	else:
		hand_state.rolled_faces = roll_service.roll_all(dice)
	battle_state.current_hand = hand_state
	if external_roll_results_enabled:
		_set_phase(BattlePhase.INIT)
	else:
		_apply_round_start_effects()
		_set_phase(BattlePhase.WAITING_ACTION)
	hand_started.emit(hand_state.hand_index)
	dice_changed.emit(get_current_rolls())
	rerolls_changed.emit(_rerolls_left())
	selection_changed.emit(0)
	score_preview_changed.emit(null)


func commit_initial_roll_results(face_results: Dictionary) -> bool:
	if not awaiting_initial_roll_results or battle_state == null or hand_state == null:
		return false
	var required_indices := _all_die_indices()
	if not _face_results_cover_indices(face_results, required_indices):
		return false

	hand_state.rolled_faces = roll_service.roll_all_from_face_results(dice, face_results)
	battle_state.current_hand = hand_state
	awaiting_initial_roll_results = false
	_apply_round_start_effects()
	_set_phase(BattlePhase.WAITING_ACTION)
	dice_changed.emit(get_current_rolls())
	rerolls_changed.emit(_rerolls_left())
	selection_changed.emit(0)
	score_preview_changed.emit(null)
	return true


func cancel_pending_initial_roll() -> void:
	if not awaiting_initial_roll_results:
		return
	awaiting_initial_roll_results = false
	_set_phase(BattlePhase.INIT)
	dice_changed.emit(get_current_rolls())
	rerolls_changed.emit(_rerolls_left())
	selection_changed.emit(0)
	score_preview_changed.emit(null)


func get_current_rolls() -> Array[RolledFace]:
	if hand_state == null:
		var empty: Array[RolledFace] = []
		return empty

	return hand_state.rolled_faces


func can_reroll() -> bool:
	return (
		hand_state != null
		and phase == BattlePhase.WAITING_ACTION
		and not awaiting_initial_roll_results
		and not awaiting_reroll_results
		and hand_state.rerolls_used < battle_state.config.rerolls_per_hand
		and _selected_count() >= 1
	)


func can_score() -> bool:
	var selected_count := _selected_count()
	return (
		hand_state != null
		and phase == BattlePhase.WAITING_ACTION
		and not awaiting_initial_roll_results
		and not awaiting_reroll_results
		and selected_count >= 1
		and selected_count <= get_max_selected_dice()
	)


func preview_selected_score(wild_effective_pips: Dictionary = {}) -> ScoreResult:
	if hand_state == null or battle_state == null:
		return null
	var selected_count := _selected_count()
	if selected_count <= 0 or selected_count > get_max_selected_dice():
		return null

	var context := _build_score_context()
	context.is_preview = true
	context.wild_effective_pips = wild_effective_pips.duplicate(true)
	_fill_missing_wild_preview_pips(context)
	return score_engine.score(context)


func get_selected_wild_face_requests() -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	if hand_state == null:
		return requests

	var context := _build_score_context()
	for roll in context.selected_faces:
		if roll == null or roll.face == null:
			continue
		if score_engine.get_effective_ornament_id_for_roll(roll, context) != FaceState.ORN_WILD:
			continue
		var key := "%d:%d" % [roll.die_index, roll.face_index]
		var options := score_engine.get_wild_pip_options(roll, context)
		requests.append({
			"key": key,
			"die_index": roll.die_index,
			"face_index": roll.face_index,
			"original_pip": roll.face.pip,
			"options": options,
			"default_pip": _clamped_wild_preview_pip(roll, options),
		})

	return requests


func get_rerolls_left() -> int:
	return _rerolls_left()


func get_rerolls_per_hand() -> int:
	if battle_state == null:
		return 0

	return battle_state.config.rerolls_per_hand


func get_max_selected_dice() -> int:
	if battle_state == null:
		return 0

	return battle_state.config.max_scored_faces_per_round


func get_total_score() -> int:
	if battle_state == null:
		return 0

	return battle_state.total_score


func get_target_score() -> int:
	if battle_state == null:
		return 0

	return battle_state.config.target_score


func get_current_hand_number() -> int:
	if hand_state == null:
		return 0

	return hand_state.hand_index + 1


func get_hands_per_battle() -> int:
	if battle_state == null:
		return 0

	return battle_state.config.hands_per_battle


func get_phase() -> int:
	return phase


func get_phase_name() -> String:
	match phase:
		BattlePhase.INIT:
			return "INIT"
		BattlePhase.WAITING_ACTION:
			return "WAITING_ACTION"
		BattlePhase.SCORING:
			return "SCORING"
		BattlePhase.VICTORY:
			return "VICTORY"
		BattlePhase.DEFEAT:
			return "DEFEAT"
		_:
			return "UNKNOWN"


func has_free_item_slot() -> bool:
	return run_state != null and run_state.has_free_item_slot()


func add_item_to_inventory_or_pending(item_id: StringName) -> bool:
	return run_state != null and run_state.add_item_to_inventory_or_pending(item_id)


func is_face_protected_by_white_mark(face_ref, negative_rule_id: StringName) -> bool:
	return score_engine.effect_resolver.is_face_protected_by_white_mark(face_ref, negative_rule_id)


func try_apply_face_negative_rule(face_ref, negative_rule_id: StringName, result: ScoreResult = null) -> bool:
	return score_engine.effect_resolver.try_apply_face_negative_rule(face_ref, negative_rule_id, result)


func _create_normal_dice(count: int) -> Array[DieState]:
	var result: Array[DieState] = []

	for die_index in range(count):
		result.append(DieState.create_normal_d6(StringName("battle_d6_%d" % [die_index + 1])))

	return result


func _apply_long_term_battle_parameters(config: BattleConfig, source_run_state: RunState) -> void:
	if config == null or source_run_state == null:
		return
	config.hands_per_battle = max(1, config.hands_per_battle + source_run_state.battle_rounds_available_delta)
	config.rerolls_per_hand = max(0, config.rerolls_per_hand + source_run_state.battle_rerolls_per_hand_delta)
	config.max_scored_faces_per_round = max(1, config.max_scored_faces_per_round + source_run_state.max_scored_faces_per_round_delta)
	config.max_selected_dice = config.max_scored_faces_per_round


func _build_score_context() -> ScoreContext:
	var context := ScoreContext.new()
	context.selected_faces = hand_state.selected_faces()
	context.all_rolled_faces = hand_state.rolled_faces
	context.battle_state = battle_state
	context.hand_state = hand_state
	context.run_state = run_state
	context.source_dice = dice
	context.rng = score_rng
	context.rerolls_used = hand_state.rerolls_used
	context.used_reroll = hand_state.rerolls_used > 0
	context.is_last_hand = _is_last_hand()
	context.rerolled_die_ids_this_round = hand_state.rerolled_die_ids_this_round
	context.body_triggered_flags_this_round = hand_state.body_triggered_flags_this_round
	context.body_triggered_flags_this_battle = battle_state.body_triggered_flags_this_battle
	return context


func _selected_pips(selected_faces: Array[RolledFace]) -> Array[int]:
	var pips: Array[int] = []

	for rolled_face in selected_faces:
		if rolled_face.face != null:
			pips.append(rolled_face.face.pip)

	return pips


func _apply_combo_context(context: ScoreContext) -> void:
	var resolution := combo_evaluator.resolve(
		context.selected_faces,
		context.all_rolled_faces,
		context.used_reroll,
		context.is_last_hand,
		context
	)
	context.primary_combo = StringName(str(resolution["primary_combo_id"]))
	context.combo_id = context.primary_combo
	context.combo_type = context.primary_combo
	context.display_combo_ids.clear()
	context.display_combo_ids.append(context.primary_combo)
	context.contained_patterns.clear()
	context.facts = resolution["facts"].duplicate(true)
	context.active_tags.clear()
	context.tags.clear()
	context.condition_tags.clear()
	context.operation_tags.clear()
	context.state_tags.clear()


func _can_change_dice_flags() -> bool:
	return hand_state != null and phase == BattlePhase.WAITING_ACTION and not awaiting_initial_roll_results and not awaiting_reroll_results


func _is_valid_roll_index(index: int) -> bool:
	return index >= 0 and hand_state != null and index < hand_state.rolled_faces.size()


func _selected_count() -> int:
	if hand_state == null:
		return 0

	return hand_state.selected_count()


func _rerolls_left() -> int:
	if hand_state == null or battle_state == null:
		return 0

	return max(0, battle_state.config.rerolls_per_hand - hand_state.rerolls_used)


func _is_last_hand() -> bool:
	if hand_state == null or battle_state == null:
		return false

	return hand_state.hand_index >= max(0, battle_state.config.hands_per_battle - 1)


func _emit_score_preview() -> void:
	score_preview_changed.emit(preview_selected_score())


func _apply_round_start_effects() -> void:
	for text in dice_tool_service.apply_round_start_effects(run_state, battle_state, hand_state):
		pending_mark_logs.append(BattleLogEntry.new(&"LOG.DICE_TOOL", {"text": text}, &"dice_tool"))


func _all_die_indices() -> Array[int]:
	var indices: Array[int] = []
	for die_index in range(dice.size()):
		indices.append(die_index)
	return indices


func _random_face_results_for_indices(indices: Array[int]) -> Dictionary:
	var results := {}
	for die_index in indices:
		if die_index < 0 or die_index >= dice.size():
			continue
		var roll := roll_service.roll_die(dice[die_index], die_index)
		results[die_index] = {
			"face_index": roll.face_index,
			"pip": roll.rolled_pip,
		}
	return results


func _face_results_cover_indices(face_results: Dictionary, indices: Array[int]) -> bool:
	for die_index in indices:
		if face_results.has(die_index) or face_results.has(str(die_index)):
			continue
		return false
	return true


func _clear_pending_roll_requests() -> void:
	awaiting_initial_roll_results = false
	_clear_pending_reroll()


func _clear_pending_reroll() -> void:
	awaiting_reroll_results = false
	pending_reroll_selected_before.clear()
	pending_reroll_die_indices.clear()


func _fill_missing_wild_preview_pips(context: ScoreContext) -> void:
	if context == null:
		return
	for roll in context.selected_faces:
		if roll == null or roll.face == null:
			continue
		if score_engine.get_effective_ornament_id_for_roll(roll, context) != FaceState.ORN_WILD:
			continue
		var key := "%d:%d" % [roll.die_index, roll.face_index]
		if context.wild_effective_pips.has(key):
			continue
		context.wild_effective_pips[key] = _clamped_wild_preview_pip(roll, score_engine.get_wild_pip_options(roll, context))


func _clamped_wild_preview_pip(roll: RolledFace, options: Array[int]) -> int:
	if roll == null or roll.face == null:
		return 1
	var original_pip := int(roll.face.pip)
	if options.is_empty():
		return original_pip
	if options.has(original_pip):
		return original_pip
	return int(options[0])


func _trigger_purple_marks_before_reroll() -> void:
	if hand_state == null or battle_state == null:
		return

	for roll in hand_state.rolled_faces:
		if roll == null or roll.face == null or not roll.selected:
			continue
		if FaceState.normalize_mark_id(roll.face.mark_id) != FaceState.MARK_PURPLE:
			continue

		var key := _face_instance_id_for_roll(roll)
		if bool(battle_state.purple_mark_triggered_this_battle.get(key, false)):
			continue

		if not has_free_item_slot():
			_queue_mark_log(&"LOG.MARK_PURPLE_NO_SLOT", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
			}, &"mark_purple", str(TranslationServer.translate(&"AUTO.TEXT.E2E7B1D1350D")), roll)
			continue

		var battle_index := 0
		if run_state != null:
			battle_index = run_state.battle_index
		var item_id := reward_generator.roll_random_forge_item(battle_index)
		if item_id == &"":
			continue
		if add_item_to_inventory_or_pending(item_id):
			battle_state.purple_mark_triggered_this_battle[key] = true
			_queue_mark_log(&"LOG.MARK_PURPLE_GENERATE", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"item": item_id,
			}, &"mark_purple", str(TranslationServer.translate(&"AUTO.TEXT.40F52A25D0F6")), roll)
		else:
			_queue_mark_log(&"LOG.MARK_PURPLE_NO_SLOT", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
			}, &"mark_purple", str(TranslationServer.translate(&"AUTO.TEXT.E2E7B1D1350D")), roll)


func _mark_selected_dice_rerolled() -> void:
	if hand_state == null:
		return
	for roll in hand_state.rolled_faces:
		if roll != null and roll.selected:
			hand_state.mark_die_rerolled(roll)


func _queue_mark_log(key: StringName, args: Dictionary, category: StringName, floating_text: String, roll: RolledFace) -> void:
	pending_mark_logs.append(BattleLogEntry.new(key, args, category))
	if floating_text != "":
		pending_mark_floating_texts.append({
			"text": floating_text,
			"die_index": roll.die_index if roll != null else -1,
			"face_index": roll.face_index if roll != null else -1,
		})


func _consume_pending_mark_events(result: ScoreResult) -> void:
	if result == null:
		pending_mark_logs.clear()
		pending_mark_floating_texts.clear()
		return

	for entry in pending_mark_logs:
		if entry != null:
			result.add_log(entry)
	for event in pending_mark_floating_texts:
		result.add_floating_text(
			str(event.get("text", "")),
			int(event.get("die_index", -1)),
			int(event.get("face_index", -1))
		)
	pending_mark_logs.clear()
	pending_mark_floating_texts.clear()


func _append_pending_mark_logs_to_trace(trace: ResolutionTrace, result: ScoreResult, start_index: int) -> void:
	if trace == null or result == null:
		return
	for index in range(max(0, start_index), result.logs.size()):
		var entry = result.logs[index]
		if entry != null:
			var text := entry.get_text()
			if text != "" and not trace.log_lines.has(text):
				trace.log_lines.append(text)


func _apply_pending_score_events(result: ScoreResult) -> void:
	if result == null or run_state == null:
		return
	for event in result.score_events:
		var event_type := StringName(str(event.get("type", &"")))
		match event_type:
			&"coins":
				var amount := int(event.get("amount", 0))
				if amount == 0:
					continue
				if run_state.has_method("add_coins"):
					run_state.add_coins(amount, &"score_effect")
				else:
					run_state.coins += amount
			&"item":
				var item_id := StringName(str(event.get("item_id", &"")))
				if item_id != &"":
					run_state.add_item_to_inventory_or_pending(item_id)
			&"dice_tool_counter":
				var tool_index := int(event.get("tool_index", -1))
				if tool_index < 0 or tool_index >= run_state.dice_tools.size():
					continue
				var tool: DiceToolState = run_state.dice_tools[tool_index]
				if tool == null:
					continue
				var key := StringName(str(event.get("key", &"")))
				var scope := StringName(str(event.get("scope", &"permanent")))
				if scope == &"combat":
					tool.combat_counters[key] = int(event.get("value", 0))
				else:
					tool.permanent_counters[key] = int(event.get("value", 0))
			&"dice_tool_counter_value":
				var tool_index := int(event.get("tool_index", -1))
				if tool_index < 0 or tool_index >= run_state.dice_tools.size():
					continue
				var tool: DiceToolState = run_state.dice_tools[tool_index]
				if tool == null:
					continue
				var key := StringName(str(event.get("key", &"")))
				var scope := StringName(str(event.get("scope", &"permanent")))
				var value = event.get("value")
				if value is Dictionary or value is Array:
					value = value.duplicate(true)
				if scope == &"combat":
					tool.combat_counters[key] = value
				else:
					tool.permanent_counters[key] = value
			&"pending_face_copy", &"reset_face", &"set_face_ornament":
				dice_tool_service._apply_run_event(run_state, event)
			&"combo_scored_count":
				var combo_id := ComboUpgradeCatalog.normalize_combo_id(StringName(str(event.get("combo_id", &""))))
				if combo_id != &"":
					run_state.combo_scored_counts[combo_id] = int(event.get("count", 0))
			&"combo_upgrade":
				var combo_id := ComboUpgradeCatalog.normalize_combo_id(StringName(str(event.get("combo_id", &""))))
				var amount := int(event.get("amount", 1))
				if combo_id != &"" and amount > 0:
					run_state.increase_combo_level(combo_id, amount)


func _apply_pending_post_resolution_mutations(result: ScoreResult) -> void:
	if pending_resolution_context == null or result == null:
		return
	pending_resolution_context.defer_runtime_mutations = false
	score_engine.effect_resolver.apply_post_score_effects(pending_resolution_context, result)


func _clear_pending_resolution() -> void:
	pending_resolution_trace = null
	pending_resolution_result = null
	pending_resolution_context = null


func _clear_selection_after_resolution_request() -> void:
	if hand_state == null:
		return
	if hand_state.selected_count() <= 0:
		return
	hand_state.clear_selection()
	selection_changed.emit(0)
	dice_changed.emit(get_current_rolls())


func _mark_battle_finished(victory: bool, result: ScoreResult) -> void:
	battle_state.victory = victory
	battle_state.battle_finished = true
	if run_state != null:
		dice_tool_service.apply_battle_end_effects(run_state, result)
	if battle_state.config.is_boss_battle:
		_remove_white_marks_after_boss_battle(result)


func _emit_battle_finished() -> void:
	if battle_state.victory:
		_set_phase(BattlePhase.VICTORY)
		battle_won.emit()
	else:
		_set_phase(BattlePhase.DEFEAT)
		battle_lost.emit()


func _remove_white_marks_after_boss_battle(result: ScoreResult) -> void:
	for die_index in range(dice.size()):
		var die := dice[die_index]
		if die == null:
			continue
		for face_index in range(die.faces.size()):
			var face := die.faces[face_index]
			if face == null or FaceState.normalize_mark_id(face.mark_id) != FaceState.MARK_WHITE:
				continue
			face.mark_id = FaceState.MARK_NONE
			_clear_matching_white_mark_clones(die_index, face_index)
			if result != null:
				result.add_log(BattleLogEntry.new(&"LOG.MARK_WHITE_REMOVED", {
					"die": die_index + 1,
					"face": face_index + 1,
				}, &"mark_white"))
				result.add_floating_text(str(TranslationServer.translate(&"AUTO.TEXT.BAD8CA5F8C4F")), die_index, face_index)
	if battle_state != null:
		battle_state.refresh_white_mark_active_faces()


func _clear_matching_white_mark_clones(die_index: int, face_index: int) -> void:
	if battle_state != null and die_index >= 0 and die_index < battle_state.dice.size():
		var battle_die := battle_state.dice[die_index]
		if battle_die != null and face_index >= 0 and face_index < battle_die.faces.size():
			var battle_face := battle_die.faces[face_index]
			if battle_face != null and FaceState.normalize_mark_id(battle_face.mark_id) == FaceState.MARK_WHITE:
				battle_face.mark_id = FaceState.MARK_NONE
	if hand_state != null:
		for roll in hand_state.rolled_faces:
			if roll != null and roll.die_index == die_index and roll.face_index == face_index and roll.face != null:
				if FaceState.normalize_mark_id(roll.face.mark_id) == FaceState.MARK_WHITE:
					roll.face.mark_id = FaceState.MARK_NONE


func _face_instance_id_for_roll(roll: RolledFace) -> String:
	if roll == null:
		return ""
	if roll.face_instance_id != "":
		return roll.face_instance_id
	if roll.die != null:
		return RolledFace.make_face_instance_id(roll.die.die_id if roll.die.die_id != &"" else roll.die.id, roll.die_index, roll.face_index)
	if roll.die_index >= 0 and roll.die_index < dice.size():
		var die := dice[roll.die_index]
		if die != null:
			return RolledFace.make_face_instance_id(die.die_id if die.die_id != &"" else die.id, roll.die_index, roll.face_index)
	return RolledFace.make_face_instance_id(&"", roll.die_index, roll.face_index)


func _set_phase(new_phase: int) -> void:
	phase = new_phase
	phase_changed.emit(phase)
