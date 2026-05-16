extends Node
class_name ContentDB


const EncounterDef = preload("res://scripts/data_defs/EncounterDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const RelicDef = preload("res://scripts/data_defs/RelicDef.gd")


var forge_pieces: Dictionary = {}
var encounters: Dictionary = {}
var relics: Dictionary = {}


func register_forge_piece(def: ForgePieceDef) -> void:
	forge_pieces[def.id] = def


func register_encounter(def: EncounterDef) -> void:
	encounters[def.id] = def


func register_relic(def: RelicDef) -> void:
	relics[def.id] = def


func get_forge_piece(id: StringName) -> ForgePieceDef:
	return forge_pieces.get(id) as ForgePieceDef


func get_encounter(id: StringName) -> EncounterDef:
	return encounters.get(id) as EncounterDef


func get_relic(id: StringName) -> RelicDef:
	return relics.get(id) as RelicDef
