extends RefCounted
class_name BoosterPackDef


const KIND_FACE := &"face"
const KIND_FORGE := &"forge"
const KIND_COMBO := &"combo"
const KIND_TOOL := &"tool"
const KIND_FOUNDRY := &"foundry"


var pack_id: StringName = &""
var display_name: String = ""
var pack_kind: StringName = &""
var price_coins: int = 0
var candidate_count: int = 0
var choose_count: int = 0
var implementation_status: StringName = &"formal"
var shop_pool_reserved: StringName = &"TBD"
var drop_weight_reserved: StringName = &"TBD"
var notes: String = ""


static func create(
	new_pack_id: StringName,
	new_display_name: String,
	new_pack_kind: StringName,
	new_price_coins: int,
	new_candidate_count: int,
	new_choose_count: int,
	new_notes: String = ""
):
	var def = load("res://scripts/data_defs/BoosterPackDef.gd").new()
	def.pack_id = new_pack_id
	def.display_name = new_display_name
	def.pack_kind = new_pack_kind
	def.price_coins = max(0, new_price_coins)
	def.candidate_count = max(0, new_candidate_count)
	def.choose_count = max(0, new_choose_count)
	def.notes = new_notes
	return def


func is_formal() -> bool:
	return implementation_status == &"formal"


func clone():
	var cloned = get_script().new()
	cloned.pack_id = pack_id
	cloned.display_name = display_name
	cloned.pack_kind = pack_kind
	cloned.price_coins = price_coins
	cloned.candidate_count = candidate_count
	cloned.choose_count = choose_count
	cloned.implementation_status = implementation_status
	cloned.shop_pool_reserved = shop_pool_reserved
	cloned.drop_weight_reserved = drop_weight_reserved
	cloned.notes = notes
	return cloned


func to_dict() -> Dictionary:
	return {
		"pack_id": pack_id,
		"display_name": display_name,
		"pack_kind": pack_kind,
		"price_coins": price_coins,
		"candidate_count": candidate_count,
		"choose_count": choose_count,
		"implementation_status": implementation_status,
		"shop_pool_reserved": shop_pool_reserved,
		"drop_weight_reserved": drop_weight_reserved,
		"notes": notes,
	}
