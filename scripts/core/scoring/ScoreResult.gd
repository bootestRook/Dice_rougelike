extends RefCounted
class_name ScoreResult


const ScoreLogEntry = preload("res://scripts/core/scoring/ScoreLogEntry.gd")


var chips: int = 0
var mult: int = 1
var xmult: float = 1.0
var final_score: int = 0
var logs: Array[ScoreLogEntry] = []


func recalculate_final_score() -> void:
	final_score = int(round(float(chips * mult) * xmult))


func add_log(entry: ScoreLogEntry) -> void:
	logs.append(entry)
