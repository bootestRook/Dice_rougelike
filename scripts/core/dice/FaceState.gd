extends RefCounted
class_name FaceState


const MIN_PIP := 1
const MAX_PIP := 8

const ORN_NONE := &"orn_none"
const ORN_CHIP := &"orn_chip"
const ORN_MULT := &"orn_mult"
const ORN_WILD := &"orn_wild"
const ORN_BURST := &"orn_burst"
const ORN_STAY := &"orn_stay"
const ORN_STONE := &"orn_stone"
const ORN_GOLD := &"orn_gold"
const ORN_LUCKY := &"orn_lucky"
const ORN_FOIL := &"orn_foil"
const ORN_HOLO := &"orn_holo"
const ORN_POLY := &"orn_poly"
const ORN_NEGATIVE := &"orn_negative"

const MARK_NONE := &"mark_none"
const MARK_RED := &"mark_red"
const MARK_BLUE := &"mark_blue"
const MARK_PURPLE := &"mark_purple"
const MARK_GOLD := &"mark_gold"
const MARK_WHITE := &"mark_white"

var pip: int = 1
var ornament_id: StringName = ORN_NONE
var mark_id: StringName = MARK_NONE

var material_id: StringName = &"none" # deprecated: use ornament_id
var rune_id: StringName = &"none" # deprecated: disabled in current design
var level: int = 1 # deprecated: disabled in current design


func _init(new_pip: int = 1, new_ornament_id: StringName = ORN_NONE, new_mark_id: StringName = MARK_NONE) -> void:
	assert(is_valid_pip(new_pip))
	pip = clampi(new_pip, MIN_PIP, MAX_PIP)
	ornament_id = normalize_ornament_id(new_ornament_id)
	mark_id = normalize_mark_id(new_mark_id)


func clone() -> FaceState:
	var cloned := FaceState.new()
	cloned.pip = pip
	cloned.ornament_id = ornament_id
	cloned.mark_id = mark_id
	cloned.material_id = material_id
	cloned.rune_id = rune_id
	cloned.level = level
	return cloned


func normalize_legacy_fields() -> void:
	if _is_none_id(ornament_id) and not _is_none_id(material_id):
		ornament_id = _legacy_material_to_ornament(material_id)
	else:
		ornament_id = normalize_ornament_id(ornament_id)
	mark_id = normalize_mark_id(mark_id)


func get_effective_ornament_id() -> StringName:
	if not _is_none_id(ornament_id):
		return normalize_ornament_id(ornament_id)
	return _legacy_material_to_ornament(material_id)


static func legacy_material_to_ornament(id: StringName) -> StringName:
	return _legacy_material_to_ornament(id)


static func normalize_ornament_id(id: StringName) -> StringName:
	match id:
		&"", &"none", &"orn_none":
			return ORN_NONE
		&"chip", &"orn_chip":
			return ORN_CHIP
		&"mult", &"orn_mult":
			return ORN_MULT
		&"wild", &"orn_wild":
			return ORN_WILD
		&"burst", &"glass", &"orn_burst":
			return ORN_BURST
		&"stay", &"steel", &"orn_stay":
			return ORN_STAY
		&"stone", &"orn_stone":
			return ORN_STONE
		&"gold", &"orn_gold":
			return ORN_GOLD
		&"lucky", &"orn_lucky":
			return ORN_LUCKY
		&"foil", &"orn_foil":
			return ORN_FOIL
		&"holo", &"orn_holo":
			return ORN_HOLO
		&"poly", &"orn_poly":
			return ORN_POLY
		&"negative", &"orn_negative":
			return ORN_NEGATIVE
		_:
			return id


static func normalize_mark_id(id: StringName) -> StringName:
	match id:
		&"", &"none", &"mark_none":
			return MARK_NONE
		&"red", &"mark_red":
			return MARK_RED
		&"blue", &"mark_blue":
			return MARK_BLUE
		&"purple", &"mark_purple":
			return MARK_PURPLE
		&"gold", &"mark_gold":
			return MARK_GOLD
		&"white", &"mark_white":
			return MARK_WHITE
		&"mark_black":
			return &"black"
		_:
			return id


static func is_valid_face_ornament_id(id: StringName) -> bool:
	return normalize_ornament_id(id) != ORN_NEGATIVE


static func is_valid_pip(value: int) -> bool:
	return value >= MIN_PIP and value <= MAX_PIP


static func _legacy_material_to_ornament(id: StringName) -> StringName:
	return normalize_ornament_id(id)


static func _is_none_id(id: StringName) -> bool:
	return id == &"" or id == &"none" or id == ORN_NONE or id == MARK_NONE
