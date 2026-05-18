extends RefCounted
class_name ForgeItemCatalog


const ForgeItemDef = preload("res://scripts/data_defs/ForgeItemDef.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")


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

static func get_all_defs() -> Array[ForgeItemDef]:
	return [
		_make_def(FORGE_ECHO_COPY, str(TranslationServer.translate(&"AUTO.TEXT.4C71E4837BD8")), str(TranslationServer.translate(&"AUTO.TEXT.FB2DE85039C5")), EFFECT_ECHO_COPY, TARGET_NONE, 0, 1, true, [&"copy", &"generate"]),
		_make_ornament_def(FORGE_LUCKY_ORNAMENT, str(TranslationServer.translate(&"AUTO.TEXT.321D0B6368EA")), str(TranslationServer.translate(&"AUTO.TEXT.35E4AB333428")), &"orn_lucky", 2, [&"ornament", &"lucky"]),
		_make_def(FORGE_COMBO_UPGRADE_PACK, str(TranslationServer.translate(&"AUTO.TEXT.F1236349614D")), str(TranslationServer.translate(&"AUTO.TEXT.32B0EAAA1AD6")), EFFECT_COMBO_UPGRADE_PACK, TARGET_NONE, 0, 2, true, [&"generate", &"combo_upgrade"]),
		_make_ornament_def(FORGE_MULT_ORNAMENT, str(TranslationServer.translate(&"AUTO.TEXT.173BD09E981C")), str(TranslationServer.translate(&"AUTO.TEXT.2C0D680889AC")), &"orn_mult", 2, [&"ornament", &"mult"]),
		_make_def(FORGE_ITEM_PACK, str(TranslationServer.translate(&"AUTO.TEXT.B8FF1BD85267")), str(TranslationServer.translate(&"AUTO.TEXT.E55AE381E0BA")), EFFECT_FORGE_ITEM_PACK, TARGET_NONE, 0, 2, true, [&"generate", &"forge_item"]),
		_make_ornament_def(FORGE_CHIP_ORNAMENT, str(TranslationServer.translate(&"AUTO.TEXT.04E30DB10857")), str(TranslationServer.translate(&"AUTO.TEXT.22729A98C185")), &"orn_chip", 2, [&"ornament", &"chips"]),
		_make_ornament_def(FORGE_WILD_ORNAMENT, str(TranslationServer.translate(&"AUTO.TEXT.604BB0C7A531")), str(TranslationServer.translate(&"AUTO.TEXT.1D11D52F2398")), &"orn_wild", 1, [&"ornament", &"wild"]),
		_make_ornament_def(FORGE_STAY_ORNAMENT, str(TranslationServer.translate(&"AUTO.TEXT.92D099C18405")), str(TranslationServer.translate(&"AUTO.TEXT.AEF306CDBA53")), &"orn_stay", 1, [&"ornament", &"stay"]),
		_make_ornament_def(FORGE_BURST_ORNAMENT, str(TranslationServer.translate(&"AUTO.TEXT.B51063C6E564")), str(TranslationServer.translate(&"AUTO.TEXT.64E8C5F4335A")), &"orn_burst", 1, [&"ornament", &"burst"]),
		_make_def(FORGE_COIN_DOUBLER, str(TranslationServer.translate(&"AUTO.TEXT.1EDEC0EDA200")), str(TranslationServer.translate(&"AUTO.TEXT.C8A584D4E818")), EFFECT_COIN_DOUBLER, TARGET_NONE, 0, 0, false, [&"coins"]),
		_make_def(FORGE_RARE_ORNAMENT_ROLL, str(TranslationServer.translate(&"AUTO.TEXT.2695C11DEAEA")), str(TranslationServer.translate(&"AUTO.TEXT.99C45E4A9A98")), EFFECT_RARE_ORNAMENT_ROLL, TARGET_FACES, 1, 0, false, [&"ornament", &"rare"]),
		_make_def(FORGE_PIP_UP, str(TranslationServer.translate(&"AUTO.TEXT.9911BC4FBEEC")), str(TranslationServer.translate(&"AUTO.TEXT.10D2FEDBF8A1")), EFFECT_PIP_UP, TARGET_FACES, 2, 0, false, [&"pip"]),
		_make_def(FORGE_FACE_COPY, str(TranslationServer.translate(&"AUTO.TEXT.0FA61CB1B30A")), str(TranslationServer.translate(&"AUTO.TEXT.CD0A30A4BB1E")), EFFECT_FACE_COPY, TARGET_FACE_PAIR, 1, 0, false, [&"copy"]),
		_make_def(FORGE_TOOL_VALUE_CASH, str(TranslationServer.translate(&"AUTO.TEXT.434BA5C01C24")), str(TranslationServer.translate(&"AUTO.TEXT.2F18107B0CB9")), EFFECT_TOOL_VALUE_CASH, TARGET_NONE, 0, 0, false, [&"coins", &"dice_tool"]),
		_make_ornament_def(FORGE_GOLD_ORNAMENT, str(TranslationServer.translate(&"AUTO.TEXT.093DDBA0EF5F")), str(TranslationServer.translate(&"AUTO.TEXT.0E84F9EF1AFF")), &"orn_gold", 1, [&"ornament", &"gold"]),
		_make_ornament_def(FORGE_STONE_ORNAMENT, str(TranslationServer.translate(&"AUTO.TEXT.DF2D6C3AF8F4")), str(TranslationServer.translate(&"AUTO.TEXT.6BE7C15543DA")), &"orn_stone", 1, [&"ornament", &"stone"]),
		_make_reroll_def(FORGE_EVEN_REROLL, str(TranslationServer.translate(&"AUTO.TEXT.183A039CC4B1")), str(TranslationServer.translate(&"AUTO.TEXT.95B010C66CFF")), &"even", [&"pip", &"even"]),
		_make_reroll_def(FORGE_LOW_REROLL, str(TranslationServer.translate(&"AUTO.TEXT.6B6FB4EF372F")), str(TranslationServer.translate(&"AUTO.TEXT.2C105E1AA48C")), &"low", [&"pip", &"low"]),
		_make_reroll_def(FORGE_ODD_REROLL, str(TranslationServer.translate(&"AUTO.TEXT.475454217E69")), str(TranslationServer.translate(&"AUTO.TEXT.45BF986F654F")), &"odd", [&"pip", &"odd"]),
		_make_def(FORGE_TOOL_PACK, str(TranslationServer.translate(&"AUTO.TEXT.CD26A3E1462F")), str(TranslationServer.translate(&"AUTO.TEXT.9ED5A40576BA")), EFFECT_DICE_TOOL_PACK, TARGET_NONE, 0, 1, true, [&"generate", &"dice_tool"]),
		_make_reroll_def(FORGE_HIGH_REROLL, str(TranslationServer.translate(&"AUTO.TEXT.3361B11E8B48")), str(TranslationServer.translate(&"AUTO.TEXT.3F474E4F22E5")), &"high", [&"pip", &"high"]),
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
	return DiceToolCatalog.get_item_pool_for_rarity()


static func display_name_for_id(id: StringName) -> String:
	var def := get_def(id)
	if def != null:
		return def.get_display_name()
	for tool_data in get_dice_tool_item_pool():
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
