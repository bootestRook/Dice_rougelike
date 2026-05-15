extends RefCounted
class_name ScoreContext


const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")


var selected_faces: Array[RolledFace] = []
var all_rolled_faces: Array[RolledFace] = []
var battle_state: BattleState = null
var hand_state: HandState = null
var combo_id: StringName = &""
var combo_type = &""
var display_combo_ids: Array[StringName] = []
var tags: Array[StringName] = []
var used_reroll: bool = false
var is_last_hand: bool = false
var rerolls_used: int = 0


func clear() -> void:
	selected_faces.clear()
	all_rolled_faces.clear()
	battle_state = null
	hand_state = null
	combo_id = &""
	combo_type = &""
	display_combo_ids.clear()
	tags.clear()
	used_reroll = false
	is_last_hand = false
	rerolls_used = 0
