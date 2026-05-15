extends RefCounted
class_name ScoreLogEntry


var source: String = ""
var text: String = ""
var chips_delta: int = 0
var mult_delta: int = 0
var xmult_factor: float = 1.0


func setup(new_source: String, new_text: String, new_chips_delta: int = 0, new_mult_delta: int = 0, new_xmult_factor: float = 1.0) -> void:
	source = new_source
	text = new_text
	chips_delta = new_chips_delta
	mult_delta = new_mult_delta
	xmult_factor = new_xmult_factor
