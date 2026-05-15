extends Resource
class_name ForgePieceDef


const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")


@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity_id: StringName = &"common"
@export var operation: ForgeOperationDef = null
