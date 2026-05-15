extends Node
class_name BattleController


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const RollService = preload("res://scripts/rules/roll/RollService.gd")
const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")
const TagEvaluator = preload("res://scripts/rules/combo/TagEvaluator.gd")


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
var dice: Array[DieState] = []
var phase: int = BattlePhase.INIT

var roll_service := RollService.new()
var combo_evaluator := ComboEvaluator.new()
var tag_evaluator := TagEvaluator.new()
var score_engine := ScoreEngine.new()


func start_battle(config: BattleConfig = null, run_state: RunState = null) -> void:
	var active_config: BattleConfig = config
	if active_config == null:
		active_config = BattleConfig.new()
	else:
		active_config = active_config.clone()

	if run_state != null:
		run_state.ensure_starting_dice()
		if not run_state.dice.is_empty():
			dice = run_state.dice
			active_config.dice_count = dice.size()
			active_config.target_score = run_state.get_target_score()
		else:
			dice = _create_normal_dice(active_config.dice_count)
	else:
		dice = _create_normal_dice(active_config.dice_count)

	battle_state = BattleState.new()
	battle_state.setup(active_config, dice)
	hand_state = null
	_set_phase(BattlePhase.INIT)
	battle_started.emit()
	score_changed.emit(battle_state.total_score, battle_state.config.target_score)
	start_next_hand()


func toggle_lock(index: int) -> void:
	if not _can_change_dice_flags() or not _is_valid_roll_index(index):
		return

	hand_state.rolled_faces[index].locked = not hand_state.rolled_faces[index].locked
	dice_changed.emit(get_current_rolls())
	_emit_score_preview()


func toggle_select(index: int) -> void:
	if not _can_change_dice_flags() or not _is_valid_roll_index(index):
		return

	var rolled_face := hand_state.rolled_faces[index]

	if rolled_face.selected:
		rolled_face.selected = false
	else:
		if _selected_count() < battle_state.config.max_selected_dice:
			rolled_face.selected = true

	selection_changed.emit(_selected_count())
	dice_changed.emit(get_current_rolls())
	_emit_score_preview()


func reroll() -> void:
	if phase != BattlePhase.WAITING_ACTION or hand_state == null:
		return
	if not can_reroll():
		return

	hand_state.rolled_faces = roll_service.reroll_selected(dice, hand_state.rolled_faces)
	hand_state.rerolls_used += 1
	dice_changed.emit(get_current_rolls())
	rerolls_changed.emit(_rerolls_left())
	selection_changed.emit(_selected_count())
	_emit_score_preview()


func score_selected() -> void:
	if phase != BattlePhase.WAITING_ACTION or not can_score():
		return

	_set_phase(BattlePhase.SCORING)
	var context := _build_score_context()
	var selected_pips := _selected_pips(context.selected_faces)
	context.combo_id = combo_evaluator.evaluate(selected_pips)
	context.combo_type = context.combo_id
	context.display_combo_ids = combo_evaluator.evaluate_display_combos(selected_pips)
	context.tags = tag_evaluator.evaluate_tags(context)

	var result := score_engine.score(context)
	hand_state.scored = true
	hand_state.score_result = result
	battle_state.total_score += result.final_score
	battle_state.hands_played += 1
	hand_scored.emit(result)
	score_preview_changed.emit(null)
	score_changed.emit(battle_state.total_score, battle_state.config.target_score)

	if battle_state.total_score >= battle_state.config.target_score:
		battle_state.victory = true
		battle_state.battle_finished = true
		_set_phase(BattlePhase.VICTORY)
		battle_won.emit()
		return

	if battle_state.hands_played >= battle_state.config.hands_per_battle:
		battle_state.victory = false
		battle_state.battle_finished = true
		_set_phase(BattlePhase.DEFEAT)
		battle_lost.emit()
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
	hand_state.rolled_faces = roll_service.roll_all(dice)
	battle_state.current_hand = hand_state
	_set_phase(BattlePhase.WAITING_ACTION)
	hand_started.emit(hand_state.hand_index)
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
		and hand_state.rerolls_used < battle_state.config.rerolls_per_hand
		and _selected_count() >= 1
	)


func can_score() -> bool:
	var selected_count := _selected_count()
	return (
		hand_state != null
		and phase == BattlePhase.WAITING_ACTION
		and selected_count >= 1
		and selected_count <= get_max_selected_dice()
	)


func preview_selected_score() -> ScoreResult:
	if hand_state == null or battle_state == null:
		return null
	var selected_count := _selected_count()
	if selected_count <= 0 or selected_count > get_max_selected_dice():
		return null

	var context := _build_score_context()
	var selected_pips := _selected_pips(context.selected_faces)
	context.combo_id = combo_evaluator.evaluate(selected_pips)
	context.combo_type = context.combo_id
	context.display_combo_ids = combo_evaluator.evaluate_display_combos(selected_pips)
	context.tags = tag_evaluator.evaluate_tags(context)
	return score_engine.score(context)


func get_rerolls_left() -> int:
	return _rerolls_left()


func get_rerolls_per_hand() -> int:
	if battle_state == null:
		return 0

	return battle_state.config.rerolls_per_hand


func get_max_selected_dice() -> int:
	if battle_state == null:
		return 0

	return battle_state.config.max_selected_dice


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


func _create_normal_dice(count: int) -> Array[DieState]:
	var result: Array[DieState] = []

	for die_index in range(count):
		result.append(DieState.create_normal_d6(StringName("battle_d6_%d" % [die_index + 1])))

	return result


func _build_score_context() -> ScoreContext:
	var context := ScoreContext.new()
	context.selected_faces = hand_state.selected_faces()
	context.all_rolled_faces = hand_state.rolled_faces
	context.battle_state = battle_state
	context.hand_state = hand_state
	context.rerolls_used = hand_state.rerolls_used
	context.used_reroll = hand_state.rerolls_used > 0
	context.is_last_hand = _is_last_hand()
	return context


func _selected_pips(selected_faces: Array[RolledFace]) -> Array[int]:
	var pips: Array[int] = []

	for rolled_face in selected_faces:
		if rolled_face.face != null:
			pips.append(rolled_face.face.pip)

	return pips


func _can_change_dice_flags() -> bool:
	return hand_state != null and phase == BattlePhase.WAITING_ACTION


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


func _set_phase(new_phase: int) -> void:
	phase = new_phase
	phase_changed.emit(phase)
