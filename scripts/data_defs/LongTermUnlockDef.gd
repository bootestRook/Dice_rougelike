extends RefCounted
class_name LongTermUnlockDef


const KIND_GLOBAL_RULE := &"global_rule"
const KIND_SHOP_PARAM := &"shop_param"
const KIND_SLOT_PARAM := &"slot_param"
const KIND_ECONOMY_PARAM := &"economy_param"
const KIND_BOSS_HOOK := &"boss_hook"


var unlock_id: StringName = &""
var display_name: String = ""
var description: String = ""
var unlock_kind: StringName = &""
var price_coins: int = 0
var effect_type: StringName = &""
var effect_value: int = 0
var effect_params: Dictionary = {}
var implementation_status: StringName = &"formal"
var shop_pool_reserved: StringName = &"TBD"
var drop_weight_reserved: StringName = &"TBD"
var notes: String = ""


static func create(
	new_unlock_id: StringName,
	new_display_name: String,
	new_description: String,
	new_unlock_kind: StringName,
	new_price_coins: int,
	new_effect_type: StringName,
	new_effect_value: int,
	new_notes: String = "",
	new_effect_params: Dictionary = {}
):
	var def = load("res://scripts/data_defs/LongTermUnlockDef.gd").new()
	def.unlock_id = new_unlock_id
	def.display_name = new_display_name
	def.description = new_description
	def.unlock_kind = new_unlock_kind
	def.price_coins = max(0, new_price_coins)
	def.effect_type = new_effect_type
	def.effect_value = new_effect_value
	def.effect_params = new_effect_params.duplicate(true)
	def.notes = new_notes
	return def


func clone():
	var cloned = get_script().new()
	cloned.unlock_id = unlock_id
	cloned.display_name = display_name
	cloned.description = description
	cloned.unlock_kind = unlock_kind
	cloned.price_coins = price_coins
	cloned.effect_type = effect_type
	cloned.effect_value = effect_value
	cloned.effect_params = effect_params.duplicate(true)
	cloned.implementation_status = implementation_status
	cloned.shop_pool_reserved = shop_pool_reserved
	cloned.drop_weight_reserved = drop_weight_reserved
	cloned.notes = notes
	return cloned


func get_display_name() -> String:
	return display_name if display_name != "" else str(unlock_id)


func get_description() -> String:
	return description


func is_formal() -> bool:
	return implementation_status == &"formal"
