extends RefCounted
class_name LongTermUnlockCatalog


const LongTermUnlockDef = preload("res://scripts/data_defs/LongTermUnlockDef.gd")


const EFFECT_ITEM_SLOT_BONUS := &"item_slot_bonus"
const EFFECT_DICE_TOOL_SLOT_BONUS := &"dice_tool_slot_bonus"
const EFFECT_SHOP_REROLL_BASE_DELTA := &"shop_reroll_base_delta"
const EFFECT_SHOP_RANDOM_ITEM_SLOT_BONUS := &"shop_random_item_slot_bonus"
const EFFECT_SHOP_BOOSTER_SLOT_BONUS := &"shop_booster_slot_bonus"
const EFFECT_BATTLE_HAND_BONUS := &"battle_hand_bonus"
const EFFECT_BATTLE_REROLL_BONUS := &"battle_reroll_bonus"
const EFFECT_SCORE_SLOT_BONUS := &"score_slot_bonus"
const EFFECT_COIN_GAIN := &"coin_gain"
const EFFECT_BOSS_RULE_GRACE := &"boss_rule_grace"

const UNLOCK_ITEM_SLOT_PLUS_ONE := &"unlock_item_slot_plus_one"
const UNLOCK_DICE_TOOL_SLOT_PLUS_ONE := &"unlock_dice_tool_slot_plus_one"
const UNLOCK_SHOP_REROLL_DISCOUNT := &"unlock_shop_reroll_discount"
const UNLOCK_SHOP_RANDOM_ITEM_SLOT_PLUS_ONE := &"unlock_shop_random_item_slot_plus_one"
const UNLOCK_SHOP_BOOSTER_SLOT_PLUS_ONE := &"unlock_shop_booster_slot_plus_one"
const UNLOCK_BATTLE_HAND_PLUS_ONE := &"unlock_battle_hand_plus_one"
const UNLOCK_BATTLE_REROLL_PLUS_ONE := &"unlock_battle_reroll_plus_one"
const UNLOCK_SCORE_SLOT_PLUS_ONE := &"unlock_score_slot_plus_one"
const UNLOCK_COIN_RESERVE := &"unlock_coin_reserve"
const UNLOCK_BOSS_RULE_GRACE := &"unlock_boss_rule_grace"

const ALL_IDS := [
	UNLOCK_ITEM_SLOT_PLUS_ONE,
	UNLOCK_DICE_TOOL_SLOT_PLUS_ONE,
	UNLOCK_SHOP_REROLL_DISCOUNT,
	UNLOCK_SHOP_RANDOM_ITEM_SLOT_PLUS_ONE,
	UNLOCK_SHOP_BOOSTER_SLOT_PLUS_ONE,
	UNLOCK_BATTLE_HAND_PLUS_ONE,
	UNLOCK_BATTLE_REROLL_PLUS_ONE,
	UNLOCK_SCORE_SLOT_PLUS_ONE,
	UNLOCK_COIN_RESERVE,
	UNLOCK_BOSS_RULE_GRACE,
]


static func get_all_defs() -> Array[LongTermUnlockDef]:
	return [
		LongTermUnlockDef.create(UNLOCK_ITEM_SLOT_PLUS_ONE, "道具槽扩容", "本局道具槽位上限 +1。", LongTermUnlockDef.KIND_SLOT_PARAM, 8, EFFECT_ITEM_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_DICE_TOOL_SLOT_PLUS_ONE, "骰具槽扩容", "本局骰具槽位上限 +1。", LongTermUnlockDef.KIND_SLOT_PARAM, 10, EFFECT_DICE_TOOL_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_SHOP_REROLL_DISCOUNT, "刷新议价", "商店刷新基础费用 -1，最低为 1。", LongTermUnlockDef.KIND_SHOP_PARAM, 6, EFFECT_SHOP_REROLL_BASE_DELTA, -1),
		LongTermUnlockDef.create(UNLOCK_SHOP_RANDOM_ITEM_SLOT_PLUS_ONE, "商品陈列位", "后续商店随机商品槽 +1。", LongTermUnlockDef.KIND_SHOP_PARAM, 12, EFFECT_SHOP_RANDOM_ITEM_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_SHOP_BOOSTER_SLOT_PLUS_ONE, "补充包陈列位", "后续商店补充包槽 +1。", LongTermUnlockDef.KIND_SHOP_PARAM, 12, EFFECT_SHOP_BOOSTER_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_BATTLE_HAND_PLUS_ONE, "额外出手机会", "后续战斗可结算回合数 +1。", LongTermUnlockDef.KIND_GLOBAL_RULE, 14, EFFECT_BATTLE_HAND_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_BATTLE_REROLL_PLUS_ONE, "额外重投机会", "后续战斗每回合重投次数 +1。", LongTermUnlockDef.KIND_GLOBAL_RULE, 14, EFFECT_BATTLE_REROLL_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_SCORE_SLOT_PLUS_ONE, "结算位扩容", "后续战斗每回合最大可结算骰面数 +1。", LongTermUnlockDef.KIND_GLOBAL_RULE, 14, EFFECT_SCORE_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_COIN_RESERVE, "金币储备", "立即获得 8 金币。", LongTermUnlockDef.KIND_ECONOMY_PARAM, 5, EFFECT_COIN_GAIN, 8),
		LongTermUnlockDef.create(UNLOCK_BOSS_RULE_GRACE, "首领规则保险", "后续首领战中，首次读取首领规则时将其禁用。", LongTermUnlockDef.KIND_BOSS_HOOK, 16, EFFECT_BOSS_RULE_GRACE, 1),
	]


static func get_catalog() -> Dictionary:
	var result := {}
	for def in get_all_defs():
		result[def.unlock_id] = def
	return result


static func get_def(unlock_id: StringName) -> LongTermUnlockDef:
	var catalog := get_catalog()
	if not catalog.has(unlock_id):
		return null
	return (catalog[unlock_id] as LongTermUnlockDef).clone()


static func has_unlock(unlock_id: StringName) -> bool:
	return ALL_IDS.has(unlock_id)


static func get_all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in ALL_IDS:
		ids.append(id)
	return ids


static func get_shop_pool_ids() -> Array[StringName]:
	return get_all_ids()


static func display_name_for_id(unlock_id: StringName) -> String:
	var def := get_def(unlock_id)
	return def.get_display_name() if def != null else str(unlock_id)


static func description_for_id(unlock_id: StringName) -> String:
	var def := get_def(unlock_id)
	return def.get_description() if def != null else ""


static func price_for_id(unlock_id: StringName) -> int:
	var def := get_def(unlock_id)
	return def.price_coins if def != null else 0
