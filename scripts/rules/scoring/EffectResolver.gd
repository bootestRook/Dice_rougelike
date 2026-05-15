extends RefCounted
class_name EffectResolver


const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


func resolve(context: ScoreContext, result: ScoreResult) -> ScoreResult:
	return result
