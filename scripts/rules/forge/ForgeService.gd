extends RefCounted
class_name ForgeService


const DieState = preload("res://scripts/core/dice/DieState.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")


func apply_piece(piece: ForgePieceDef, die: DieState, face_index: int) -> void:
	pass
