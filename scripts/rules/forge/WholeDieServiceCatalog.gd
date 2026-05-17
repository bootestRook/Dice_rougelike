extends RefCounted
class_name WholeDieServiceCatalog


const WholeDieServiceDef = preload("res://scripts/data_defs/WholeDieServiceDef.gd")


const IMPLEMENTATION_FORMAL := &"formal"
const DROP_POOL_TBD := &"TBD"
const DROP_WEIGHT_TBD := &"TBD"

const TARGET_DIE := &"die"
const TARGET_DIE_WITH_KEPT_FACES := &"die_with_kept_faces"
const TARGET_DIE_WITH_KEPT_FACE := &"die_with_kept_face"
const TARGET_DIE_WITH_BODY := &"die_with_body"

const TYPE_FACE_COUNT_CONVERT := &"face_count_convert"
const TYPE_BODY_CHANGE := &"body_change"
const TYPE_FULL_REFORGE := &"full_reforge"

const DIE_CONVERT_D4 := &"die_convert_d4"
const DIE_CONVERT_D6 := &"die_convert_d6"
const DIE_CONVERT_D8 := &"die_convert_d8"
const DIE_CHANGE_BODY := &"die_change_body"
const DIE_FULL_REFORGE := &"die_full_reforge"

const OFFICIAL_IDS := [
	DIE_CONVERT_D4,
	DIE_CONVERT_D6,
	DIE_CONVERT_D8,
	DIE_CHANGE_BODY,
	DIE_FULL_REFORGE,
]


static func get_all_defs() -> Array[WholeDieServiceDef]:
	return [
		_make_def(DIE_CONVERT_D4, "转换为 D4", "选择 1 颗 D6 或 D8，保留 4 个现有面位，其余移除；非法点数重置为 4。", TYPE_FACE_COUNT_CONVERT, TARGET_DIE_WITH_KEPT_FACES),
		_make_def(DIE_CONVERT_D6, "转换为 D6", "选择 1 颗 D4 或 D8。D4 会新增 2 个普通面；D8 需保留 6 个现有面位，7/8 点重置为 6。", TYPE_FACE_COUNT_CONVERT, TARGET_DIE_WITH_KEPT_FACES),
		_make_def(DIE_CONVERT_D8, "转换为 D8", "选择 1 颗 D4 或 D6，保留原有面位并新增普通面直到 8 面。", TYPE_FACE_COUNT_CONVERT, TARGET_DIE),
		_make_def(DIE_CHANGE_BODY, "更换骰胚", "选择 1 颗骰子并替换骰胚，保留面数和所有骰面。", TYPE_BODY_CHANGE, TARGET_DIE_WITH_BODY),
		_make_def(DIE_FULL_REFORGE, "整骰重铸", "选择 1 颗骰子，保留 1 个指定面位，其余全部重置为该骰子的合法普通面。", TYPE_FULL_REFORGE, TARGET_DIE_WITH_KEPT_FACE),
	]


static func get_catalog() -> Dictionary:
	var result := {}
	for def in get_all_defs():
		result[def.service_id] = def
	return result


static func get_def(service_id: StringName) -> WholeDieServiceDef:
	var catalog := get_catalog()
	if not catalog.has(service_id):
		return null
	return (catalog[service_id] as WholeDieServiceDef).clone()


static func has_service(service_id: StringName) -> bool:
	return OFFICIAL_IDS.has(service_id)


static func get_all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in OFFICIAL_IDS:
		ids.append(id)
	return ids


static func _make_def(
	service_id: StringName,
	display_name: String,
	description: String,
	service_type: StringName,
	target_rule: StringName
) -> WholeDieServiceDef:
	var def := WholeDieServiceDef.new()
	def.service_id = service_id
	def.display_name = display_name
	def.description = description
	def.service_type = service_type
	def.target_rule = target_rule
	def.requires_confirmation = true
	def.implementation_status = IMPLEMENTATION_FORMAL
	def.reserved_drop_pool = DROP_POOL_TBD
	def.reserved_drop_weight = DROP_WEIGHT_TBD
	return def
