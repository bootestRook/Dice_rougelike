extends RefCounted
class_name ForgeItemCatalog


const ForgeItemDef = preload("res://scripts/data_defs/ForgeItemDef.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")


const DROP_POOL_RESERVED := &"reserved"
const DROP_POOL_REGULAR := &"regular"
const DROP_POOL_ADVANCED := &"advanced"
const DROP_POOL_RARE := &"rare"
const DROP_POOL_SPECIAL_GENERATED := &"special_generated"
const RESERVED_DROP_POOLS := [
	DROP_POOL_REGULAR,
	DROP_POOL_ADVANCED,
	DROP_POOL_RARE,
	DROP_POOL_SPECIAL_GENERATED,
]

const TARGET_NONE := &"none"
const TARGET_FACES := &"faces"
const TARGET_FACE_PAIR := &"face_pair"

const EFFECT_ECHO_COPY := &"echo_copy"
const EFFECT_SET_ORNAMENT := &"set_ornament"
const EFFECT_COMBO_UPGRADE_PACK := &"combo_upgrade_pack"
const EFFECT_FORGE_ITEM_PACK := &"forge_item_pack"
const EFFECT_COIN_DOUBLER := &"coin_doubler"
const EFFECT_RARE_ORNAMENT_ROLL := &"rare_ornament_roll"
const EFFECT_PIP_UP := &"pip_up"
const EFFECT_FACE_COPY := &"face_copy"
const EFFECT_TOOL_VALUE_CASH := &"tool_value_cash"
const EFFECT_PIP_REROLL := &"pip_reroll"
const EFFECT_DICE_TOOL_PACK := &"dice_tool_pack"

const FORGE_ECHO_COPY := &"forge_echo_copy"
const FORGE_LUCKY_ORNAMENT := &"forge_lucky_ornament"
const FORGE_COMBO_UPGRADE_PACK := &"forge_combo_upgrade_pack"
const FORGE_MULT_ORNAMENT := &"forge_mult_ornament"
const FORGE_ITEM_PACK := &"forge_item_pack"
const FORGE_CHIP_ORNAMENT := &"forge_chip_ornament"
const FORGE_WILD_ORNAMENT := &"forge_wild_ornament"
const FORGE_STAY_ORNAMENT := &"forge_stay_ornament"
const FORGE_BURST_ORNAMENT := &"forge_burst_ornament"
const FORGE_COIN_DOUBLER := &"forge_coin_doubler"
const FORGE_RARE_ORNAMENT_ROLL := &"forge_rare_ornament_roll"
const FORGE_PIP_UP := &"forge_pip_up"
const FORGE_FACE_COPY := &"forge_face_copy"
const FORGE_TOOL_VALUE_CASH := &"forge_tool_value_cash"
const FORGE_GOLD_ORNAMENT := &"forge_gold_ornament"
const FORGE_STONE_ORNAMENT := &"forge_stone_ornament"
const FORGE_EVEN_REROLL := &"forge_even_reroll"
const FORGE_LOW_REROLL := &"forge_low_reroll"
const FORGE_ODD_REROLL := &"forge_odd_reroll"
const FORGE_TOOL_PACK := &"forge_tool_pack"
const FORGE_HIGH_REROLL := &"forge_high_reroll"

const OFFICIAL_IDS := [
	FORGE_ECHO_COPY,
	FORGE_LUCKY_ORNAMENT,
	FORGE_COMBO_UPGRADE_PACK,
	FORGE_MULT_ORNAMENT,
	FORGE_ITEM_PACK,
	FORGE_CHIP_ORNAMENT,
	FORGE_WILD_ORNAMENT,
	FORGE_STAY_ORNAMENT,
	FORGE_BURST_ORNAMENT,
	FORGE_COIN_DOUBLER,
	FORGE_RARE_ORNAMENT_ROLL,
	FORGE_PIP_UP,
	FORGE_FACE_COPY,
	FORGE_TOOL_VALUE_CASH,
	FORGE_GOLD_ORNAMENT,
	FORGE_STONE_ORNAMENT,
	FORGE_EVEN_REROLL,
	FORGE_LOW_REROLL,
	FORGE_ODD_REROLL,
	FORGE_TOOL_PACK,
	FORGE_HIGH_REROLL,
]

const RARE_ORNAMENT_IDS := [
	&"orn_foil",
	&"orn_holo",
	&"orn_poly",
]

const DICE_TOOL_ITEM_POOL := [
	{
		"id": &"dice_tool_chip_core",
		"name": "战力骰具",
		"sell_value": 12,
	},
	{
		"id": &"dice_tool_mult_core",
		"name": "倍率骰具",
		"sell_value": 16,
	},
	{
		"id": &"dice_tool_gold_core",
		"name": "金币骰具",
		"sell_value": 20,
	},
]


static func get_all_defs() -> Array[ForgeItemDef]:
	return [
		_make_def(FORGE_ECHO_COPY, "回响铸模", "复制本局最近一次使用过的可复制铸骰件或骰型升级件，复制物进入道具槽位。", EFFECT_ECHO_COPY, TARGET_NONE, 0, 1, true, [&"copy", &"generate"]),
		_make_ornament_def(FORGE_LUCKY_ORNAMENT, "幸运面贴", "将最多 2 个选中骰面安装为幸运面饰。", &"orn_lucky", 2, [&"ornament", &"lucky"]),
		_make_def(FORGE_COMBO_UPGRADE_PACK, "骰型补给匣", "生成最多 2 个随机骰型升级件，生成物进入道具槽位。", EFFECT_COMBO_UPGRADE_PACK, TARGET_NONE, 0, 2, true, [&"generate", &"combo_upgrade"]),
		_make_ornament_def(FORGE_MULT_ORNAMENT, "倍率面贴", "将最多 2 个选中骰面安装为倍率面饰。", &"orn_mult", 2, [&"ornament", &"mult"]),
		_make_def(FORGE_ITEM_PACK, "铸件补给匣", "生成最多 2 个随机铸骰件；随机池排除铸件补给匣与回响铸模。", EFFECT_FORGE_ITEM_PACK, TARGET_NONE, 0, 2, true, [&"generate", &"forge_item"]),
		_make_ornament_def(FORGE_CHIP_ORNAMENT, "战力面贴", "将最多 2 个选中骰面安装为战力面饰。", &"orn_chip", 2, [&"ornament", &"chips"]),
		_make_ornament_def(FORGE_WILD_ORNAMENT, "通配面贴", "将 1 个选中骰面安装为通配面饰。", &"orn_wild", 1, [&"ornament", &"wild"]),
		_make_ornament_def(FORGE_STAY_ORNAMENT, "留场面贴", "将 1 个选中骰面安装为留场面饰。", &"orn_stay", 1, [&"ornament", &"stay"]),
		_make_ornament_def(FORGE_BURST_ORNAMENT, "爆裂面贴", "将 1 个选中骰面安装为爆裂面饰。", &"orn_burst", 1, [&"ornament", &"burst"]),
		_make_def(FORGE_COIN_DOUBLER, "聚币匣", "获得等同于当前金币数的金币，最多获得 20。", EFFECT_COIN_DOUBLER, TARGET_NONE, 0, 0, false, [&"coins"]),
		_make_def(FORGE_RARE_ORNAMENT_ROLL, "稀饰校准器", "25% 概率随机得到箔光、幻彩或多彩面饰，并安装到 1 个选中骰面；失败时无效果。", EFFECT_RARE_ORNAMENT_ROLL, TARGET_FACES, 1, 0, false, [&"ornament", &"rare"]),
		_make_def(FORGE_PIP_UP, "递增点数片", "将最多 2 个选中骰面点数 +1；超过所属骰子的面数后循环到 1。", EFFECT_PIP_UP, TARGET_FACES, 2, 0, false, [&"pip"]),
		_make_def(FORGE_FACE_COPY, "骰面复写器", "先选目标面，再选来源面；目标面复制来源面的点数、面饰与印记。", EFFECT_FACE_COPY, TARGET_FACE_PAIR, 1, 0, false, [&"copy"]),
		_make_def(FORGE_TOOL_VALUE_CASH, "骰具估价单", "获得当前已安装骰具总卖价对应金币，最多获得 50；不卖掉骰具。", EFFECT_TOOL_VALUE_CASH, TARGET_NONE, 0, 0, false, [&"coins", &"dice_tool"]),
		_make_ornament_def(FORGE_GOLD_ORNAMENT, "金辉面贴", "将 1 个选中骰面安装为金辉面饰。", &"orn_gold", 1, [&"ornament", &"gold"]),
		_make_ornament_def(FORGE_STONE_ORNAMENT, "石质面贴", "将 1 个选中骰面安装为石质面饰。", &"orn_stone", 1, [&"ornament", &"stone"]),
		_make_reroll_def(FORGE_EVEN_REROLL, "偶数重铸片", "将最多 3 个选中骰面随机改为合法偶数点数。", &"even", [&"pip", &"even"]),
		_make_reroll_def(FORGE_LOW_REROLL, "低点重铸片", "将最多 3 个选中骰面随机改为合法低域点数。", &"low", [&"pip", &"low"]),
		_make_reroll_def(FORGE_ODD_REROLL, "奇数重铸片", "将最多 3 个选中骰面随机改为合法奇数点数。", &"odd", [&"pip", &"odd"]),
		_make_def(FORGE_TOOL_PACK, "骰具补给匣", "生成 1 个随机骰具道具，生成物进入道具槽位。", EFFECT_DICE_TOOL_PACK, TARGET_NONE, 0, 1, true, [&"generate", &"dice_tool"]),
		_make_reroll_def(FORGE_HIGH_REROLL, "高点重铸片", "将最多 3 个选中骰面随机改为合法高域点数；D4 骰面不可作为目标。", &"high", [&"pip", &"high"]),
	]


static func get_catalog() -> Dictionary:
	var result := {}
	for def in get_all_defs():
		result[def.id] = def
	return result


static func get_def(id: StringName) -> ForgeItemDef:
	var catalog := get_catalog()
	if not catalog.has(id):
		return null
	return (catalog[id] as ForgeItemDef).clone()


static func has_forge_item(id: StringName) -> bool:
	return OFFICIAL_IDS.has(id)


static func get_all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in OFFICIAL_IDS:
		ids.append(id)
	return ids


static func get_forge_item_pack_pool_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in OFFICIAL_IDS:
		if id == FORGE_ITEM_PACK or id == FORGE_ECHO_COPY:
			continue
		ids.append(id)
	return ids


static func get_combo_upgrade_pool_ids() -> Array[StringName]:
	return ComboUpgradeCatalog.get_item_ids()


static func get_dice_tool_item_pool() -> Array:
	return DICE_TOOL_ITEM_POOL.duplicate(true)


static func display_name_for_id(id: StringName) -> String:
	var def := get_def(id)
	if def != null:
		return def.get_display_name()
	for tool_data in DICE_TOOL_ITEM_POOL:
		if StringName(str(tool_data.get("id", &""))) == id:
			return str(tool_data.get("name", id))
	return str(id)


static func _make_ornament_def(
	id: StringName,
	display_name: String,
	description: String,
	ornament_id: StringName,
	max_targets: int,
	tags: Array
) -> ForgeItemDef:
	var def := _make_def(id, display_name, description, EFFECT_SET_ORNAMENT, TARGET_FACES, max_targets, 0, false, tags)
	def.payload["ornament_id"] = ornament_id
	return def


static func _make_reroll_def(
	id: StringName,
	display_name: String,
	description: String,
	pip_pool_type: StringName,
	tags: Array
) -> ForgeItemDef:
	var def := _make_def(id, display_name, description, EFFECT_PIP_REROLL, TARGET_FACES, 3, 0, false, tags)
	def.payload["pip_pool_type"] = pip_pool_type
	return def


static func _make_def(
	id: StringName,
	display_name: String,
	description: String,
	effect_type: StringName,
	target_type: StringName,
	max_targets: int,
	generated_count: int,
	requires_item_slot: bool,
	tags: Array
) -> ForgeItemDef:
	var def := ForgeItemDef.new()
	def.id = id
	def.display_name = display_name
	def.description = description
	def.effect_type = effect_type
	def.target_type = target_type
	def.max_targets = max_targets
	def.generated_count = generated_count
	def.requires_item_slot = requires_item_slot
	def.drop_pool_id = DROP_POOL_RESERVED
	def.drop_weight = -1.0
	def.implementation_status = &"formal"
	for tag in tags:
		if tag is StringName:
			def.tags.append(tag)
		else:
			def.tags.append(StringName(str(tag)))
	return def
