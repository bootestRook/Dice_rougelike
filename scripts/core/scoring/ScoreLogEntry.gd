extends "res://scripts/log/BattleLogEntry.gd"
class_name ScoreLogEntry


func setup(
	new_source: String,
	_new_text: String,
	_chips_delta: int = 0,
	_mult_delta: int = 0,
	_xmult_factor: float = 1.0
) -> void:
	key = StringName(new_source)
	args = {}
	category = StringName(new_source)
