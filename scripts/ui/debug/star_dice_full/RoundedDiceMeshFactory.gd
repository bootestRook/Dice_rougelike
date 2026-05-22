extends RefCounted
class_name BattleStarRoundedDiceMeshFactory


const GenericRoundedDiceMeshFactory := preload("res://scripts/ui/debug/RoundedDiceMeshFactory.gd")


static func create_rounded_cube(options: Dictionary = {}) -> ArrayMesh:
	return GenericRoundedDiceMeshFactory.create_rounded_cube(options)
