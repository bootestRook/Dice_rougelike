extends RefCounted
class_name BoosterOfferDef


const PAYLOAD_FACE_OFFER := &"face_offer"
const PAYLOAD_FORGE_ITEM := &"forge_item"
const PAYLOAD_COMBO_UPGRADE_ITEM := &"combo_upgrade_item"
const PAYLOAD_DICE_TOOL_ITEM := &"dice_tool_item"
const PAYLOAD_FOUNDRY_SERVICE := &"foundry_service"


var offer_id: StringName = &""
var display_name: String = ""
var pack_kind: StringName = &""
var payload_kind: StringName = &""
var payload_id: StringName = &""
var payload_data: Dictionary = {}
var is_selectable: bool = true
var disabled_reason: String = ""


static func create(
	new_offer_id: StringName,
	new_display_name: String,
	new_pack_kind: StringName,
	new_payload_kind: StringName,
	new_payload_id: StringName,
	new_payload_data: Dictionary = {}
):
	var offer = load("res://scripts/data_defs/BoosterOfferDef.gd").new()
	offer.offer_id = new_offer_id
	offer.display_name = new_display_name
	offer.pack_kind = new_pack_kind
	offer.payload_kind = new_payload_kind
	offer.payload_id = new_payload_id
	offer.payload_data = new_payload_data.duplicate(true)
	return offer


func mark_disabled(reason: String):
	is_selectable = false
	disabled_reason = reason
	return self


func clone():
	var cloned = get_script().new()
	cloned.offer_id = offer_id
	cloned.display_name = display_name
	cloned.pack_kind = pack_kind
	cloned.payload_kind = payload_kind
	cloned.payload_id = payload_id
	cloned.payload_data = payload_data.duplicate(true)
	cloned.is_selectable = is_selectable
	cloned.disabled_reason = disabled_reason
	return cloned


func to_dict() -> Dictionary:
	return {
		"offer_id": offer_id,
		"display_name": display_name,
		"pack_kind": pack_kind,
		"payload_kind": payload_kind,
		"payload_id": payload_id,
		"payload_data": payload_data.duplicate(true),
		"is_selectable": is_selectable,
		"disabled_reason": disabled_reason,
	}


static func from_dict(data: Dictionary):
	var offer = load("res://scripts/data_defs/BoosterOfferDef.gd").new()
	offer.offer_id = StringName(str(data.get("offer_id", &"")))
	offer.display_name = str(data.get("display_name", ""))
	offer.pack_kind = StringName(str(data.get("pack_kind", &"")))
	offer.payload_kind = StringName(str(data.get("payload_kind", &"")))
	offer.payload_id = StringName(str(data.get("payload_id", &"")))
	offer.payload_data = Dictionary(data.get("payload_data", {})).duplicate(true)
	offer.is_selectable = bool(data.get("is_selectable", true))
	offer.disabled_reason = str(data.get("disabled_reason", ""))
	return offer
