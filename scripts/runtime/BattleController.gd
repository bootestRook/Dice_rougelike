extends Node
class_name BattleController


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")
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


var battle_state: BattleState = null
var hand_state: HandState = null
var dice: Array[DieState] = []
var phase: int = BattlePhase.INIT

var roll_service := RollService.new()
var combo_evaluator := ComboEvaluator.new()
var tag_evaluator := TagEvaluator.new()
var score_engine := ScoreEngine.new()


func start_battle(config: BattleConfig = null) -> void:
	var active_config: BattleConfig = config
	if active_config == null:
		active_config = BattleConfig.new()

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


func toggle_select(index: int) -> void:
	if not _can_change_dice_flags() or not _is_valid_roll_index(index):
		return

	var rolled_face := hand_state.rolled_faces[index]

	if rolled_face.selected:
		rolled_face.selected = false
	else:
		if _selected_count() >= battle_state.config.max_selected_dice:
			return

		rolled_face.selected = true

	selection_changed.emit(_selected_count())
	dice_changed.emit(get_current_rolls())


func reroll() -> void:
	if phase != BattlePhase.WAITING_ACTION or hand_state == null:
		return
	if not can_reroll():
		return

	hand_state.rolled_faces = roll_service.reroll_unlocked(dice, hand_state.rolled_faces)
	hand_state.rerolls_used += 1
	dice_changed.emit(get_current_rolls())
	rerolls_changed.emit(_rerolls_left())
	selection_changed.emit(_selected_count())


func score_selected() -> void:
	if phase != BattlePhase.WAITING_ACTION or not can_score():
		return

	_set_phase(BattlePhase.SCORING)
	var context := _build_score_context()
	context.combo_id = combo_evaluator.evaluate(_selected_pips(context.selected_faces))
	context.tags = tag_evaluator.evaluate_tags(context)

	var result := score_engine.score(context)
	hand_state.scored = true
	hand_state.score_result = result
	battle_state.total_score += result.final_score
	battle_state.hands_played += 1
	hand_scored.emit(result)
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


func get_current_rolls() -> Array[RolledFace]:
	if hand_state == null:
		var empty: Array[RolledFace] = []
		return empty

	return hand_state.rolled_faces


func can_reroll() -> bool:
	return hand_state != null and phase == BattlePhase.WAITING_ACTION and hand_state.rerolls_used < battle_state.config.rerolls_per_hand


func can_score() -> bool:
	return hand_state != null and phase == BattlePhase.WAITING_ACTION and _selected_count() >= 1


func get_rerolls_left() -> int:
	return _rerolls_left()


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


func _set_phase(new_phase: int) -> void:
	phase = new_phase
	phase_changed.emit(phase)
