extends Node
class_name GameRng


var rng := RandomNumberGenerator.new()
var seed_value: int = 0


func _ready() -> void:
	randomize_seed()


func randomize_seed() -> void:
	rng.randomize()
	seed_value = rng.seed


func set_seed_value(new_seed: int) -> void:
	seed_value = new_seed
	rng.seed = seed_value


func randi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)


func randf() -> float:
	return rng.randf()
