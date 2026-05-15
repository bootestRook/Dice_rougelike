extends RefCounted
class_name BattleState


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")


var config: BattleConfig = BattleConfig.new()
var dice: Array[DieState] = []
var current_hand: HandState = null
var hands_played: int = 0
var total_score: int = 0
var battle_started: bool = false
var battle_finished: bool = false
var victory: bool = false


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


func can_start_next_hand() -> bool:
	return battle_started and not battle_finished and hands_played < config.hands_per_battle


func add_score(score: int) -> void:
	total_score += score
	if total_score >= config.target_score:
		victory = true
		battle_finished = true
