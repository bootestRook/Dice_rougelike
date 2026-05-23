extends RefCounted
class_name ShopOfferDef


const KIND_RANDOM_ITEM := &"random_item"
const KIND_BOOSTER_PACK := &"booster_pack"
const KIND_LONG_TERM_UNLOCK := &"long_term_unlock"

const PAYLOAD_FORGE_ITEM := &"forge_item"
const PAYLOAD_DICE_TOOL_ITEM := &"dice_tool_item"
const PAYLOAD_COMBO_UPGRADE_ITEM := &"combo_upgrade_item"
const PAYLOAD_FACE_SHOP_ITEM := &"face_shop_item"
const PAYLOAD_BOOSTER_PACK := &"booster_pack"
const PAYLOAD_LONG_TERM_UNLOCK := &"long_term_unlock"


var offer_id: StringName = &""
var display_name: String = ""
var offer_kind: StringName = &""
var payload_id: StringName = &""
var payload_kind: StringName = &""
var price_coins: int = 0
var shop_pool_reserved: StringName = &"TBD"
var drop_weight_reserved: StringName = &"TBD"
var source_note: String = ""


static func create(
	new_offer_id: StringName,
	new_display_name: String,
	new_offer_kind: StringName,
	new_payload_id: StringName,
	new_payload_kind: StringName,
	new_price_coins: int,
	new_source_note: String = ""
):
	var offer = load("res://scripts/data_defs/ShopOfferDef.gd").new()
	offer.offer_id = new_offer_id
	offer.display_name = new_display_name
	offer.offer_kind = new_offer_kind
	offer.payload_id = new_payload_id
	offer.payload_kind = new_payload_kind
	offer.price_coins = max(0, new_price_coins)
	offer.source_note = new_source_note
	return offer


func is_random_item() -> bool:
	return offer_kind == KIND_RANDOM_ITEM


func is_booster_pack() -> bool:
	return offer_kind == KIND_BOOSTER_PACK


func is_long_term_unlock() -> bool:
	return offer_kind == KIND_LONG_TERM_UNLOCK


func clone():
	var cloned = get_script().new()
	cloned.offer_id = offer_id
	cloned.display_name = display_name
	cloned.offer_kind = offer_kind
	cloned.payload_id = payload_id
	cloned.payload_kind = payload_kind
	cloned.price_coins = price_coins
	cloned.shop_pool_reserved = shop_pool_reserved
	cloned.drop_weight_reserved = drop_weight_reserved
	cloned.source_note = source_note
	return cloned


func to_dict() -> Dictionary:
	return {
		"offer_id": offer_id,
		"display_name": display_name,
		"offer_kind": offer_kind,
		"payload_id": payload_id,
		"payload_kind": payload_kind,
		"price_coins": price_coins,
		"shop_pool_reserved": shop_pool_reserved,
		"drop_weight_reserved": drop_weight_reserved,
		"source_note": source_note,
	}


static func from_dict(data: Dictionary):
	var offer = load("res://scripts/data_defs/ShopOfferDef.gd").new()
	offer.offer_id = StringName(str(data.get("offer_id", &"")))
	offer.display_name = str(data.get("display_name", ""))
	offer.offer_kind = StringName(str(data.get("offer_kind", &"")))
	offer.payload_id = StringName(str(data.get("payload_id", &"")))
	offer.payload_kind = StringName(str(data.get("payload_kind", &"")))
	offer.price_coins = max(0, int(data.get("price_coins", 0)))
	offer.shop_pool_reserved = StringName(str(data.get("shop_pool_reserved", &"TBD")))
	offer.drop_weight_reserved = StringName(str(data.get("drop_weight_reserved", &"TBD")))
	offer.source_note = str(data.get("source_note", ""))
	return offer
