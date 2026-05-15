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
var tags: Array[StringName] = []


func clear() -> void:
	selected_faces.clear()
	all_rolled_faces.clear()
	battle_state = null
	hand_state = null
	combo_id = &""
	tags.clear()
