extends RefCounted
class_name BoosterPackCatalog


const BoosterPackDef = preload("res://scripts/data_defs/BoosterPackDef.gd")


const PACK_FACE_BASIC := &"pack_face_basic"
const PACK_FACE_LARGE := &"pack_face_large"
const PACK_FACE_MEGA := &"pack_face_mega"
const PACK_FORGE_BASIC := &"pack_forge_basic"
const PACK_FORGE_LARGE := &"pack_forge_large"
const PACK_FORGE_MEGA := &"pack_forge_mega"
const PACK_COMBO_BASIC := &"pack_combo_basic"
const PACK_COMBO_LARGE := &"pack_combo_large"
const PACK_COMBO_MEGA := &"pack_combo_mega"
const PACK_TOOL_BASIC := &"pack_tool_basic"
const PACK_TOOL_LARGE := &"pack_tool_large"
const PACK_TOOL_MEGA := &"pack_tool_mega"
const PACK_FOUNDRY_BASIC := &"pack_foundry_basic"
const PACK_FOUNDRY_LARGE := &"pack_foundry_large"
const PACK_FOUNDRY_MEGA := &"pack_foundry_mega"

const ALL_IDS := [
	PACK_FACE_BASIC,
	PACK_FACE_LARGE,
	PACK_FACE_MEGA,
	PACK_FORGE_BASIC,
	PACK_FORGE_LARGE,
	PACK_FORGE_MEGA,
	PACK_COMBO_BASIC,
	PACK_COMBO_LARGE,
	PACK_COMBO_MEGA,
	PACK_TOOL_BASIC,
	PACK_TOOL_LARGE,
	PACK_TOOL_MEGA,
	PACK_FOUNDRY_BASIC,
	PACK_FOUNDRY_LARGE,
	PACK_FOUNDRY_MEGA,
]


static func get_all_defs() -> Array[BoosterPackDef]:
	return [
		BoosterPackDef.create(PACK_FACE_BASIC, "骰面改造包", BoosterPackDef.KIND_FACE, 4, 3, 1),
		BoosterPackDef.create(PACK_FACE_LARGE, "大型骰面改造包", BoosterPackDef.KIND_FACE, 6, 5, 1),
		BoosterPackDef.create(PACK_FACE_MEGA, "豪华骰面改造包", BoosterPackDef.KIND_FACE, 8, 5, 2),
		BoosterPackDef.create(PACK_FORGE_BASIC, "铸骰件包", BoosterPackDef.KIND_FORGE, 4, 3, 1),
		BoosterPackDef.create(PACK_FORGE_LARGE, "大型铸骰件包", BoosterPackDef.KIND_FORGE, 6, 5, 1),
		BoosterPackDef.create(PACK_FORGE_MEGA, "豪华铸骰件包", BoosterPackDef.KIND_FORGE, 8, 5, 2),
		BoosterPackDef.create(PACK_COMBO_BASIC, "主骰型包", BoosterPackDef.KIND_COMBO, 4, 3, 1),
		BoosterPackDef.create(PACK_COMBO_LARGE, "大型主骰型包", BoosterPackDef.KIND_COMBO, 6, 5, 1),
		BoosterPackDef.create(PACK_COMBO_MEGA, "豪华主骰型包", BoosterPackDef.KIND_COMBO, 8, 5, 2),
		BoosterPackDef.create(PACK_TOOL_BASIC, "骰具包", BoosterPackDef.KIND_TOOL, 4, 2, 1),
		BoosterPackDef.create(PACK_TOOL_LARGE, "大型骰具包", BoosterPackDef.KIND_TOOL, 6, 4, 1),
		BoosterPackDef.create(PACK_TOOL_MEGA, "豪华骰具包", BoosterPackDef.KIND_TOOL, 8, 4, 2),
		BoosterPackDef.create(PACK_FOUNDRY_BASIC, "工坊服务包", BoosterPackDef.KIND_FOUNDRY, 4, 2, 1),
		BoosterPackDef.create(PACK_FOUNDRY_LARGE, "大型工坊服务包", BoosterPackDef.KIND_FOUNDRY, 6, 4, 1),
		BoosterPackDef.create(PACK_FOUNDRY_MEGA, "豪华工坊服务包", BoosterPackDef.KIND_FOUNDRY, 8, 4, 2),
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


static func display_name_for_id(pack_id: StringName) -> String:
	var def := get_def(pack_id)
	return def.display_name if def != null else str(pack_id)


static func required_item_slots_before_purchase(pack_id: StringName) -> int:
	match pack_id:
		PACK_TOOL_MEGA:
			return 2
		PACK_TOOL_BASIC, PACK_TOOL_LARGE:
			return 1
		_:
			return 0


static func get_pack_ids_for_shop() -> Array[StringName]:
	return get_all_ids()
