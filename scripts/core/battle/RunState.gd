extends RefCounted
class_name RunState


const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")


var dice: Array[DieState] = []
var relic_ids: Array[StringName] = []
var battle_index: int = 0
var current_battle: BattleState = null


func create_default_loadout() -> void:
	dice.clear()

	for die_index in range(6):
		dice.append(DieState.create_normal_d6(StringName("normal_d6_%d" % [die_index + 1])))


func clone_dice() -> Array[DieState]:
	var cloned_dice: Array[DieState] = []

	for die in dice:
		cloned_dice.append(die.clone())

	return cloned_dice
