extends RefCounted
class_name DieBodyCatalog


const DieState = preload("res://scripts/core/dice/DieState.gd")
const DieBodyDef = preload("res://scripts/data_defs/DieBodyDef.gd")


const IMPLEMENTATION_FORMAL := &"formal"
const DROP_POOL_TBD := &"TBD"
const DROP_WEIGHT_TBD := &"TBD"

const BODY_STANDARD := DieState.BODY_STANDARD
const BODY_IRON := DieState.BODY_IRON
const BODY_GLASS := DieState.BODY_GLASS
const BODY_BIASED := DieState.BODY_BIASED
const BODY_HOLLOW := DieState.BODY_HOLLOW
const BODY_MIRROR := DieState.BODY_MIRROR
const BODY_CRACKED := DieState.BODY_CRACKED
const BODY_MERCHANT := DieState.BODY_MERCHANT

const OFFICIAL_IDS := [
	BODY_STANDARD,
	BODY_IRON,
	BODY_GLASS,
	BODY_BIASED,
	BODY_HOLLOW,
	BODY_MIRROR,
	BODY_CRACKED,
	BODY_MERCHANT,
]


static func get_all_defs() -> Array[DieBodyDef]:
	return [
		_make_def(BODY_STANDARD, "标准骰胚", "无额外效果。"),
		_make_def(BODY_IRON, "铁质骰胚", "每回合每颗最多触发 1 次。最终投出但未被选择结算时，+10 基础战力；若带有留场面饰，额外 +2 倍率。"),
		_make_def(BODY_GLASS, "玻璃骰胚", "该骰子的爆裂面饰触发时，爆裂终倍率加成 +25%。"),
		_make_def(BODY_BIASED, "偏心骰胚", "选择 1 个偏心面位，该面位投出权重 +1。"),
		_make_def(BODY_HOLLOW, "空心骰胚", "本回合至少被重投过 1 次并最终被选择结算时，+5 基础战力、+1 倍率。每回合每颗最多触发 1 次。"),
		_make_def(BODY_MIRROR, "镜面骰胚", "本回合被选择结算，且其他被结算骰面存在相同有效点数时，当前面饰额外触发 1 次。每回合每颗最多触发 1 次。"),
		_make_def(BODY_CRACKED, "裂纹骰胚", "每场战斗中，该骰子的爆裂面饰第一次破碎判定成功时，取消本次破碎。"),
		_make_def(BODY_MERCHANT, "商人骰胚", "该骰子的当前投出面通过金印或金辉面饰获得金币时，该次金币收益额外 +1。"),
	]


static func get_catalog() -> Dictionary:
	var result := {}
	for def in get_all_defs():
		result[def.body_id] = def
	return result


static func get_def(body_id: StringName) -> DieBodyDef:
	var normalized_id := normalize_body_id(body_id)
	var catalog := get_catalog()
	if not catalog.has(normalized_id):
		return null
	return (catalog[normalized_id] as DieBodyDef).clone()


static func get_all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in OFFICIAL_IDS:
		ids.append(id)
	return ids


static func has_body(body_id: StringName) -> bool:
	return OFFICIAL_IDS.has(normalize_body_id(body_id))


static func normalize_body_id(body_id: StringName) -> StringName:
	return DieState.normalize_body_id(body_id)


static func _make_def(body_id: StringName, display_name: String, description: String) -> DieBodyDef:
	var def := DieBodyDef.new()
	def.body_id = body_id
	def.display_name = display_name
	def.description = description
	def.implementation_status = IMPLEMENTATION_FORMAL
	def.reserved_drop_pool = DROP_POOL_TBD
	def.reserved_drop_weight = DROP_WEIGHT_TBD
	return def
