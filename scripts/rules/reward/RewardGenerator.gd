extends RefCounted
class_name RewardGenerator


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


func generate_forge_piece_choices(run_state: RunState, count: int = 3) -> Array[ForgePieceDef]:
	var choices: Array[ForgePieceDef] = []
	return choices
