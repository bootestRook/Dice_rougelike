extends RefCounted
class_name FoundryServiceCatalog


const FoundryServiceDef = preload("res://scripts/data_defs/FoundryServiceDef.gd")


const IMPLEMENTATION_FORMAL := &"formal"
const DROP_POOL_TBD := &"TBD"
const DROP_WEIGHT_TBD := -1.0

const TARGET_NONE := &"none"
const TARGET_DIE := &"die"
const TARGET_FACE := &"face"
const TARGET_MULTI_FACES := &"multi_faces"
const TARGET_FACE_DOUBLE_COPY := &"face_double_copy"

const TYPE_FACE_REFORGE := &"face_reforge"
const TYPE_MARK_INSTALL := &"mark_install"
const TYPE_RARE_ORNAMENT_INSTALL := &"rare_ornament_install"
const TYPE_TOOL_ITEM_GENERATE := &"tool_item_generate"
const TYPE_PIP_SYNC := &"pip_sync"
const TYPE_TOOL_SLOT := &"tool_slot"
const TYPE_ECONOMY := &"economy"
const TYPE_TOOL_COPY := &"tool_copy"
const TYPE_ORNAMENT_GAMBLE := &"ornament_gamble"
const TYPE_FACE_COPY := &"face_copy"
const TYPE_COMBO_UPGRADE := &"combo_upgrade"

const FOUNDRY_HIGH_PIP_REFORGE := &"foundry_high_pip_reforge"
const FOUNDRY_SIX_PIP_REFORGE := &"foundry_six_pip_reforge"
const FOUNDRY_RANDOM_PIP_REFORGE := &"foundry_random_pip_reforge"
const FOUNDRY_GOLD_MARK := &"foundry_gold_mark"
const FOUNDRY_RARE_ORNAMENT := &"foundry_rare_ornament"
const FOUNDRY_RARE_TOOL_PACK := &"foundry_rare_tool_pack"
const FOUNDRY_SAME_PIP_SYNC := &"foundry_same_pip_sync"
const FOUNDRY_NEGATIVE_TOOL_SLOT := &"foundry_negative_tool_slot"
const FOUNDRY_BURN_FOR_COINS := &"foundry_burn_for_coins"
const FOUNDRY_TOOL_CLONE_PURGE := &"foundry_tool_clone_purge"
const FOUNDRY_RED_MARK := &"foundry_red_mark"
const FOUNDRY_POLY_GAMBLE := &"foundry_poly_gamble"
const FOUNDRY_BLUE_MARK := &"foundry_blue_mark"
const FOUNDRY_PURPLE_MARK := &"foundry_purple_mark"
const FOUNDRY_FACE_DOUBLE_COPY := &"foundry_face_double_copy"
const FOUNDRY_LEGENDARY_TOOL_PACK := &"foundry_legendary_tool_pack"
const FOUNDRY_ALL_COMBO_UPGRADE := &"foundry_all_combo_upgrade"

const OFFICIAL_IDS := [
	FOUNDRY_HIGH_PIP_REFORGE,
	FOUNDRY_SIX_PIP_REFORGE,
	FOUNDRY_RANDOM_PIP_REFORGE,
	FOUNDRY_GOLD_MARK,
	FOUNDRY_RARE_ORNAMENT,
	FOUNDRY_RARE_TOOL_PACK,
	FOUNDRY_SAME_PIP_SYNC,
	FOUNDRY_NEGATIVE_TOOL_SLOT,
	FOUNDRY_BURN_FOR_COINS,
	FOUNDRY_TOOL_CLONE_PURGE,
	FOUNDRY_RED_MARK,
	FOUNDRY_POLY_GAMBLE,
	FOUNDRY_BLUE_MARK,
	FOUNDRY_PURPLE_MARK,
	FOUNDRY_FACE_DOUBLE_COPY,
	FOUNDRY_LEGENDARY_TOOL_PACK,
	FOUNDRY_ALL_COMBO_UPGRADE,
]

const ORDINARY_ORNAMENT_POOL := [
	&"orn_none",
	&"orn_chip",
	&"orn_mult",
	&"orn_wild",
	&"orn_burst",
	&"orn_stay",
	&"orn_stone",
	&"orn_gold",
	&"orn_lucky",
]

const RARE_ORNAMENT_POOL := [
	&"orn_foil",
	&"orn_holo",
	&"orn_poly",
]

const RARE_DICE_TOOL_ITEM_POOL := [
	{
		"id": &"dice_tool_rare_chip_core",
		"name": "稀有筹码核心",
		"rarity": &"rare",
		"sell_value": 24,
	},
	{
		"id": &"dice_tool_rare_mult_core",
		"name": "稀有倍率核心",
		"rarity": &"rare",
		"sell_value": 28,
	},
	{
		"id": &"dice_tool_rare_gold_core",
		"name": "稀有金流核心",
		"rarity": &"rare",
		"sell_value": 32,
	},
]

const LEGENDARY_DICE_TOOL_ITEM_POOL := [
	{
		"id": &"dice_tool_legendary_sun_core",
		"name": "传奇日冕核心",
		"rarity": &"legendary",
		"sell_value": 60,
	},
	{
		"id": &"dice_tool_legendary_void_core",
		"name": "传奇虚空核心",
		"rarity": &"legendary",
		"sell_value": 64,
	},
]


static func get_all_defs() -> Array[FoundryServiceDef]:
	return [
		_make_def(FOUNDRY_HIGH_PIP_REFORGE, "高位回炉", "随机牺牲目标骰的一面，从 3 个高点普通候选面中选择 1 个覆盖。", TYPE_FACE_REFORGE, TARGET_DIE, false, "会随机牺牲 1 个现有骰面。", &"uncommon"),
		_make_def(FOUNDRY_SIX_PIP_REFORGE, "六点熔刻", "随机牺牲目标骰的一面，从 2 个六点普通候选面中选择 1 个覆盖。", TYPE_FACE_REFORGE, TARGET_DIE, false, "会随机牺牲 1 个现有骰面；仅 D6 / D8 可用。", &"rare"),
		_make_def(FOUNDRY_RANDOM_PIP_REFORGE, "数面回炉", "随机牺牲目标骰的一面，从 4 个合法点数普通候选面中选择 1 个覆盖。", TYPE_FACE_REFORGE, TARGET_DIE, false, "会随机牺牲 1 个现有骰面。", &"uncommon"),
		_make_def(FOUNDRY_GOLD_MARK, "金印压印", "将 1 个目标骰面的印记替换为金印。", TYPE_MARK_INSTALL, TARGET_FACE, false, "若目标已有印记，将替换现有印记。", &"uncommon"),
		_make_def(FOUNDRY_RARE_ORNAMENT, "稀饰灌注", "随机安装箔光、幻彩或多彩中的 1 个稀有面饰。", TYPE_RARE_ORNAMENT_INSTALL, TARGET_FACE, false, "会替换目标骰面的现有面饰。", &"rare"),
		_make_def(FOUNDRY_RARE_TOOL_PACK, "稀有骰具匣", "生成 1 个随机稀有骰具道具进入道具槽位，并清空当前金币。", TYPE_TOOL_ITEM_GENERATE, TARGET_NONE, true, "需要空道具槽位；金币变为 0。", &"epic"),
		_make_def(FOUNDRY_SAME_PIP_SYNC, "同点同调", "选择 2 到 5 个骰面，统一为共同合法随机点数，并清空面饰和印记。", TYPE_PIP_SYNC, TARGET_MULTI_FACES, false, "会清空所有目标骰面的面饰和印记。", &"rare"),
		_make_def(FOUNDRY_NEGATIVE_TOOL_SLOT, "负载扩槽", "随机将 1 个已安装且非负载骰具设为负载骰具，并清空当前金币。", TYPE_TOOL_SLOT, TARGET_NONE, false, "随机目标；金币变为 0。", &"epic"),
		_make_def(FOUNDRY_BURN_FOR_COINS, "熔毁换金", "随机重置 5 个现有骰面，获得 20 金币。", TYPE_ECONOMY, TARGET_NONE, false, "会随机重置 5 个骰面的点数、面饰和印记。", &"uncommon"),
		_make_def(FOUNDRY_TOOL_CLONE_PURGE, "骰具孤本复刻", "随机复制 1 个已安装骰具，并摧毁其他已安装骰具。", TYPE_TOOL_COPY, TARGET_NONE, false, "会摧毁来源与复制体之外的所有已安装骰具。", &"epic"),
		_make_def(FOUNDRY_RED_MARK, "红印压印", "将 1 个目标骰面的印记替换为红印。", TYPE_MARK_INSTALL, TARGET_FACE, false, "若目标已有印记，将替换现有印记。", &"rare"),
		_make_def(FOUNDRY_POLY_GAMBLE, "多彩孤注", "随机令目标骰的 1 个骰面获得多彩面饰，并清空同骰其他面饰。", TYPE_ORNAMENT_GAMBLE, TARGET_DIE, false, "会清空同一颗骰子其他骰面的面饰。", &"epic"),
		_make_def(FOUNDRY_BLUE_MARK, "蓝印压印", "将 1 个目标骰面的印记替换为蓝印。", TYPE_MARK_INSTALL, TARGET_FACE, false, "若目标已有印记，将替换现有印记。", &"rare"),
		_make_def(FOUNDRY_PURPLE_MARK, "紫印压印", "将 1 个目标骰面的印记替换为紫印。", TYPE_MARK_INSTALL, TARGET_FACE, false, "若目标已有印记，将替换现有印记。", &"rare"),
		_make_def(FOUNDRY_FACE_DOUBLE_COPY, "骰面双写", "将 1 个来源骰面的三槽位完整复制到 2 个合法目标骰面。", TYPE_FACE_COPY, TARGET_FACE_DOUBLE_COPY, false, "会覆盖两个目标骰面的点数、面饰和印记。", &"legendary"),
		_make_def(FOUNDRY_LEGENDARY_TOOL_PACK, "传奇骰具匣", "生成 1 个随机传奇骰具道具进入道具槽位。", TYPE_TOOL_ITEM_GENERATE, TARGET_NONE, true, "需要空道具槽位。", &"legendary"),
		_make_def(FOUNDRY_ALL_COMBO_UPGRADE, "全主骰型升阶", "8 个主骰型等级全部 +1。", TYPE_COMBO_UPGRADE, TARGET_NONE, false, "只升级主骰型等级。", &"legendary"),
	]


static func get_catalog() -> Dictionary:
	var result := {}
	for def in get_all_defs():
		result[def.service_id] = def
	return result


static func get_def(service_id: StringName) -> FoundryServiceDef:
	var catalog := get_catalog()
	if not catalog.has(service_id):
		return null
	return (catalog[service_id] as FoundryServiceDef).clone()


static func has_service(service_id: StringName) -> bool:
	return OFFICIAL_IDS.has(service_id)


static func get_all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in OFFICIAL_IDS:
		ids.append(id)
	return ids


static func get_ordinary_ornament_pool() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in ORDINARY_ORNAMENT_POOL:
		result.append(id)
	return result


static func get_rare_ornament_pool() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in RARE_ORNAMENT_POOL:
		result.append(id)
	return result


static func get_rare_dice_tool_item_pool() -> Array:
	return RARE_DICE_TOOL_ITEM_POOL.duplicate(true)


static func get_legendary_dice_tool_item_pool() -> Array:
	return LEGENDARY_DICE_TOOL_ITEM_POOL.duplicate(true)


static func _make_def(
	service_id: StringName,
	display_name: String,
	description: String,
	service_type: StringName,
	target_rule: StringName,
	requires_item_slot: bool,
	risk_note: String,
	rarity: StringName = &"common"
) -> FoundryServiceDef:
	var def := FoundryServiceDef.new()
	def.service_id = service_id
	def.display_name = display_name
	def.description = description
	def.service_type = service_type
	def.target_rule = target_rule
	def.requires_item_slot = requires_item_slot
	def.risk_note = risk_note
	def.rarity = rarity
	def.implementation_status = IMPLEMENTATION_FORMAL
	def.drop_pool = DROP_POOL_TBD
	def.drop_weight = DROP_WEIGHT_TBD
	return def
