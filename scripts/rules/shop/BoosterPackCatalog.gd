extends RefCounted
class_name BoosterPackCatalog


const BoosterPackDef = preload("res://scripts/data_defs/BoosterPackDef.gd")


const PACK_FACE_BASIC := &"pack_face_basic"
const PACK_FACE_LARGE := &"pack_face_large"
const PACK_FACE_MEGA := &"pack_face_mega"
const PACK_COMBO_BASIC := &"pack_combo_basic"
const PACK_COMBO_LARGE := &"pack_combo_large"
const PACK_COMBO_MEGA := &"pack_combo_mega"
const PACK_RELIC_BASIC := &"pack_relic_basic"
const PACK_RELIC_LARGE := &"pack_relic_large"
const PACK_RELIC_MEGA := &"pack_relic_mega"

const ALL_IDS := [
	PACK_FACE_BASIC,
	PACK_FACE_LARGE,
	PACK_FACE_MEGA,
	PACK_COMBO_BASIC,
	PACK_COMBO_LARGE,
	PACK_COMBO_MEGA,
	PACK_RELIC_BASIC,
	PACK_RELIC_LARGE,
	PACK_RELIC_MEGA,
]

const FIRST_CIRCLE_FIRST_SHOP_IDS := [
	PACK_FACE_BASIC,
	PACK_FACE_LARGE,
	PACK_COMBO_BASIC,
	PACK_COMBO_LARGE,
	PACK_RELIC_BASIC,
	PACK_RELIC_LARGE,
]

const BASIC_PACK_IDS := [
	PACK_FACE_BASIC,
	PACK_COMBO_BASIC,
	PACK_RELIC_BASIC,
]

const LARGE_PACK_IDS := [
	PACK_FACE_LARGE,
	PACK_COMBO_LARGE,
	PACK_RELIC_LARGE,
]


static func get_all_defs() -> Array[BoosterPackDef]:
	return [
		BoosterPackDef.create(PACK_FACE_BASIC, "骰面改造包", BoosterPackDef.KIND_FACE, 4, 3, 1),
		BoosterPackDef.create(PACK_FACE_LARGE, "大型骰面改造包", BoosterPackDef.KIND_FACE, 6, 5, 1),
		BoosterPackDef.create(PACK_FACE_MEGA, "豪华骰面改造包", BoosterPackDef.KIND_FACE, 8, 5, 2),
		BoosterPackDef.create(PACK_COMBO_BASIC, "主骰型包", BoosterPackDef.KIND_COMBO, 4, 3, 1),
		BoosterPackDef.create(PACK_COMBO_LARGE, "大型主骰型包", BoosterPackDef.KIND_COMBO, 6, 5, 1),
		BoosterPackDef.create(PACK_COMBO_MEGA, "豪华主骰型包", BoosterPackDef.KIND_COMBO, 8, 5, 2),
		BoosterPackDef.create(PACK_RELIC_BASIC, "骰具包", BoosterPackDef.KIND_RELIC, 4, 2, 1),
		BoosterPackDef.create(PACK_RELIC_LARGE, "大型骰具包", BoosterPackDef.KIND_RELIC, 6, 4, 1),
		BoosterPackDef.create(PACK_RELIC_MEGA, "豪华骰具包", BoosterPackDef.KIND_RELIC, 8, 4, 2),
	]


static func get_catalog() -> Dictionary:
	var result := {}
	for def in get_all_defs():
		result[def.pack_id] = def
	return result


static func get_def(pack_id: StringName) -> BoosterPackDef:
	var catalog := get_catalog()
	if not catalog.has(pack_id):
		return null
	return (catalog[pack_id] as BoosterPackDef).clone()


static func has_pack(pack_id: StringName) -> bool:
	return ALL_IDS.has(pack_id)


static func get_all_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in ALL_IDS:
		result.append(id)
	return result


static func get_basic_pack_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in BASIC_PACK_IDS:
		result.append(id)
	return result


static func is_basic_pack(pack_id: StringName) -> bool:
	return BASIC_PACK_IDS.has(pack_id)


static func is_large_pack(pack_id: StringName) -> bool:
	return LARGE_PACK_IDS.has(pack_id)


static func is_mega_pack(pack_id: StringName) -> bool:
	match pack_id:
		PACK_FACE_MEGA, PACK_COMBO_MEGA, PACK_RELIC_MEGA:
			return true
		_:
			return false


static func display_name_for_id(pack_id: StringName) -> String:
	var def := get_def(pack_id)
	return def.display_name if def != null else str(pack_id)


static func required_item_slots_before_purchase(pack_id: StringName) -> int:
	return 0


static func required_relic_slots_before_purchase(pack_id: StringName) -> int:
	match pack_id:
		PACK_RELIC_MEGA:
			return 2
		PACK_RELIC_BASIC, PACK_RELIC_LARGE:
			return 1
		_:
			return 0


static func get_pack_ids_for_shop(run_state = null, options: Dictionary = {}) -> Array[StringName]:
	var result: Array[StringName] = []
	var source_ids: Array = FIRST_CIRCLE_FIRST_SHOP_IDS if bool(options.get("first_circle_first_shop", false)) else get_all_ids()
	for pack_id in source_ids:
		var def := get_def(pack_id)
		if def == null:
			continue
		if not [BoosterPackDef.KIND_FACE, BoosterPackDef.KIND_COMBO, BoosterPackDef.KIND_RELIC].has(def.pack_kind):
			continue
		result.append(pack_id)
	return result


static func shop_weight_for_pack_id(pack_id: StringName, run_state = null, options: Dictionary = {}) -> int:
	var def := get_def(pack_id)
	if def == null:
		return 0
	if bool(options.get("first_circle_first_shop", false)) and is_mega_pack(pack_id):
		return 0
	var weight := 1.0
	if bool(options.get("first_circle_first_shop", false)):
		if is_basic_pack(pack_id):
			weight = 4.0
		elif is_large_pack(pack_id):
			weight = 1.0
	if run_state != null:
		match def.pack_kind:
			BoosterPackDef.KIND_FACE:
				weight *= max(1.0, float(run_state.shop_face_pack_weight_multiplier))
			BoosterPackDef.KIND_COMBO:
				weight *= max(1.0, float(run_state.shop_combo_pack_weight_multiplier))
	return max(1, int(round(weight)))
