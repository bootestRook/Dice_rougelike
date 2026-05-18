extends RefCounted
class_name BattleState


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")


var config: BattleConfig = BattleConfig.new()
var dice: Array[DieState] = []
var current_hand: HandState = null
var hands_played: int = 0
var total_score: int = 0
var battle_started: bool = false
var battle_finished: bool = false
var victory: bool = false
var purple_mark_triggered_this_battle: Dictionary = {}
var white_mark_active_faces: Dictionary = {}
var body_triggered_flags_this_battle: Dictionary = {}
var boss_rule_disabled: bool = false
var boss_rule_triggered_this_round: bool = false
var long_term_boss_rule_grace_used: bool = false
var current_round_rerolled_face_count: int = 0
var current_round_rerolled_four_pip_count: int = 0
var temporary_faces: Array[RolledFace] = []


func setup(new_config: BattleConfig, battle_dice: Array[DieState]) -> void:
	config = new_config.clone()
	dice.clear()

	for die in battle_dice:
		dice.append(die.clone())

	current_hand = null
	hands_played = 0
	total_score = 0
	battle_started = true
	battle_finished = false
	victory = false
	boss_rule_disabled = false
	boss_rule_triggered_this_round = false
	long_term_boss_rule_grace_used = false
	current_round_rerolled_face_count = 0
	current_round_rerolled_four_pip_count = 0
	temporary_faces.clear()
	purple_mark_triggered_this_battle.clear()
	_refresh_white_mark_active_faces()
	body_triggered_flags_this_battle.clear()


func can_start_next_hand() -> bool:
	return battle_started and not battle_finished and hands_played < config.hands_per_battle


func add_score(score: int) -> void:
	total_score += score
	if total_score >= config.target_score:
		victory = true
		battle_finished = true


func refresh_white_mark_active_faces() -> void:
	_refresh_white_mark_active_faces()


func face_instance_id(die_index: int, face_index: int) -> String:
	if die_index >= 0 and die_index < dice.size():
		var die := dice[die_index]
		if die != null:
			return RolledFace.make_face_instance_id(die.die_id if die.die_id != &"" else die.id, die_index, face_index)
	return RolledFace.make_face_instance_id(&"", die_index, face_index)


func _refresh_white_mark_active_faces() -> void:
	white_mark_active_faces.clear()
	for die_index in range(dice.size()):
		var die := dice[die_index]
		if die == null:
			continue
		for face_index in range(die.faces.size()):
			var face := die.faces[face_index]
			if face != null and FaceState.normalize_mark_id(face.mark_id) == FaceState.MARK_WHITE:
				white_mark_active_faces[face_instance_id(die_index, face_index)] = true
