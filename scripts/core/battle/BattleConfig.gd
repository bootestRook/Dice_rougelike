extends RefCounted
class_name BattleConfig


var dice_count: int = 6
var max_selected_dice: int = 5
var rerolls_per_hand: int = 2
var hands_per_battle: int = 4
var target_score: int = 1000
var is_boss_battle: bool = false


func clone() -> BattleConfig:
	var cloned := BattleConfig.new()
	cloned.dice_count = dice_count
	cloned.max_selected_dice = max_selected_dice
	cloned.rerolls_per_hand = rerolls_per_hand
	cloned.hands_per_battle = hands_per_battle
	cloned.target_score = target_score
	cloned.is_boss_battle = is_boss_battle
	return cloned
