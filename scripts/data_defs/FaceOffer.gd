extends RefCounted
class_name FaceOffer


const FaceState = preload("res://scripts/core/dice/FaceState.gd")


const COVER_FULL_FACE := &"full_face"
const COVER_PIP_ONLY := &"pip_only"
const COVER_ORNAMENT_ONLY := &"ornament_only"
const COVER_MARK_ONLY := &"mark_only"
const COVER_PIP_ORNAMENT := &"pip_ornament"
const COVER_PIP_MARK := &"pip_mark"
const COVER_ORNAMENT_MARK := &"ornament_mark"


var offer_id: StringName = &""
var display_name: String = ""
var cover_mode: StringName = COVER_PIP_ONLY
var pip: int = 0
var ornament_id: StringName = FaceState.ORN_NONE
var mark_id: StringName = FaceState.MARK_NONE


static func create(
	new_offer_id: StringName,
	new_display_name: String,
	new_cover_mode: StringName,
	new_pip: int = 0,
	new_ornament_id: StringName = FaceState.ORN_NONE,
	new_mark_id: StringName = FaceState.MARK_NONE
):
	var offer = load("res://scripts/data_defs/FaceOffer.gd").new()
	offer.offer_id = new_offer_id
	offer.display_name = new_display_name
	offer.cover_mode = new_cover_mode
	offer.pip = new_pip
	offer.ornament_id = FaceState.normalize_ornament_id(new_ornament_id)
	offer.mark_id = FaceState.normalize_mark_id(new_mark_id)
	return offer


func covers_pip() -> bool:
	return cover_mode == COVER_FULL_FACE or cover_mode == COVER_PIP_ONLY or cover_mode == COVER_PIP_ORNAMENT or cover_mode == COVER_PIP_MARK


func covers_ornament() -> bool:
	return cover_mode == COVER_FULL_FACE or cover_mode == COVER_ORNAMENT_ONLY or cover_mode == COVER_PIP_ORNAMENT or cover_mode == COVER_ORNAMENT_MARK


func covers_mark() -> bool:
	return cover_mode == COVER_FULL_FACE or cover_mode == COVER_MARK_ONLY or cover_mode == COVER_PIP_MARK or cover_mode == COVER_ORNAMENT_MARK


func clone():
	var cloned = get_script().new()
	cloned.offer_id = offer_id
	cloned.display_name = display_name
	cloned.cover_mode = cover_mode
	cloned.pip = pip
	cloned.ornament_id = ornament_id
	cloned.mark_id = mark_id
	return cloned


func to_dict() -> Dictionary:
	return {
		"offer_id": offer_id,
		"display_name": display_name,
		"cover_mode": cover_mode,
		"pip": pip,
		"ornament_id": ornament_id,
		"mark_id": mark_id,
	}


static func from_dict(data: Dictionary):
	return create(
		StringName(str(data.get("offer_id", &""))),
		str(data.get("display_name", "")),
		StringName(str(data.get("cover_mode", COVER_PIP_ONLY))),
		int(data.get("pip", 0)),
		StringName(str(data.get("ornament_id", FaceState.ORN_NONE))),
		StringName(str(data.get("mark_id", FaceState.MARK_NONE)))
	)
