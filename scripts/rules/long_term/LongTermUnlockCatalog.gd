extends RefCounted
class_name LongTermUnlockCatalog


const LongTermUnlockDef = preload("res://scripts/data_defs/LongTermUnlockDef.gd")


const EFFECT_SHOP_RANDOM_ITEM_SLOT_BONUS := &"shop_random_item_slot_bonus"
const EFFECT_SHOP_BOOSTER_SLOT_BONUS := &"shop_booster_slot_bonus"
const EFFECT_RANDOM_ITEM_DISCOUNT := &"random_item_discount"
const EFFECT_FIRST_NON_UNLOCK_PURCHASE_DISCOUNT := &"first_non_unlock_purchase_discount"
const EFFECT_FACE_PACK_EXTRA_CANDIDATES := &"face_pack_extra_candidates"
const EFFECT_ADVANCED_ORNAMENT_WEIGHT_MULTIPLIER := &"advanced_ornament_weight_multiplier"
const EFFECT_SHOP_REROLL_BASE_DELTA := &"shop_reroll_base_delta"
const EFFECT_FIRST_REROLL_FREE := &"first_reroll_free"
const EFFECT_ITEM_SLOT_BONUS := &"item_slot_bonus"
const EFFECT_COMBO_PACK_INCLUDE_MOST_PLAYED := &"combo_pack_include_most_played"
const EFFECT_OBSERVATORY_ENABLED := &"observatory_enabled"
const EFFECT_BATTLE_HAND_BONUS := &"battle_hand_bonus"
const EFFECT_FIRST_SCORE_ECHO_ENABLED := &"first_score_echo_enabled"
const EFFECT_BATTLE_REROLL_BONUS := &"battle_reroll_bonus"
const EFFECT_UNUSED_REROLL_GOLD_ENABLED := &"unused_reroll_gold_enabled"
const EFFECT_COMBO_UPGRADE_SHOP_UPGRADE := &"combo_upgrade_shop_upgrade"
const EFFECT_COMBO_PACK_WEIGHT_MULTIPLIER := &"combo_pack_weight_multiplier"
const EFFECT_INTEREST_CAP := &"interest_cap"
const EFFECT_MONEY_TREE_ENABLED := &"money_tree_enabled"
const EFFECT_CONTRACT_TOOL_SLOT_BONUS := &"contract_tool_slot_bonus"
const EFFECT_DICE_TOOL_SLOT_BONUS := &"dice_tool_slot_bonus"
const EFFECT_FACE_PACK_WEIGHT_MULTIPLIER := &"face_pack_weight_multiplier"
const EFFECT_ADVANCED_FACE_PACK_REWARDS_ENABLED := &"advanced_face_pack_rewards_enabled"
const EFFECT_EARLY_BATTLE_DANGER_REDUCE := &"early_battle_danger_reduce"
const EFFECT_BOSS_DANGER_REDUCE := &"boss_danger_reduce"
const EFFECT_BOSS_RULE_FREE_REROLL := &"boss_rule_free_reroll"
const EFFECT_BOSS_RULE_CHOICE := &"boss_rule_choice"
const EFFECT_SCORE_SLOT_BONUS := &"score_slot_bonus"
const EFFECT_BATTLE_REWARD_CHOICE_BONUS := &"battle_reward_choice_bonus"

const UNLOCK_SHOP_RANDOM_SLOT_PLUS_1 := &"unlock_shop_random_slot_plus_1"
const UNLOCK_SHOP_PACK_SLOT_PLUS_1 := &"unlock_shop_pack_slot_plus_1"
const UNLOCK_RANDOM_ITEM_DISCOUNT_25 := &"unlock_random_item_discount_25"
const UNLOCK_FIRST_PURCHASE_HALF_PRICE := &"unlock_first_purchase_half_price"
const UNLOCK_FACE_PACK_EXTRA_CANDIDATE := &"unlock_face_pack_extra_candidate"
const UNLOCK_ADVANCED_ORNAMENT_WEIGHT_X2 := &"unlock_advanced_ornament_weight_x2"
const UNLOCK_SHOP_REROLL_DISCOUNT_2 := &"unlock_shop_reroll_discount_2"
const UNLOCK_SHOP_FIRST_REROLL_FREE := &"unlock_shop_first_reroll_free"
const UNLOCK_ITEM_SLOT_PLUS_1 := &"unlock_item_slot_plus_1"
const UNLOCK_COMBO_PACK_PREFERRED_UPGRADE := &"unlock_combo_pack_preferred_upgrade"
const UNLOCK_OBSERVATORY_COMBO_BONUS := &"unlock_observatory_combo_bonus"
const UNLOCK_SCORING_ROUND_PLUS_1 := &"unlock_scoring_round_plus_1"
const UNLOCK_FIRST_SCORE_ECHO := &"unlock_first_score_echo"
const UNLOCK_REROLL_PER_ROUND_PLUS_1 := &"unlock_reroll_per_round_plus_1"
const UNLOCK_UNUSED_REROLL_TO_GOLD := &"unlock_unused_reroll_to_gold"
const UNLOCK_COMBO_UPGRADE_SHOP_WEIGHT_X2 := &"unlock_combo_upgrade_shop_weight_x2"
const UNLOCK_COMBO_UPGRADE_SHOP_UPGRADE := &"unlock_combo_upgrade_shop_upgrade"
const UNLOCK_INTEREST_CAP_8 := &"unlock_interest_cap_8"
const UNLOCK_FLAT_GOLD_AFTER_BATTLE := &"unlock_flat_gold_after_battle"
const UNLOCK_CONTRACT_TOOL_SLOT := &"unlock_contract_tool_slot"
const UNLOCK_TOOL_SLOT_PLUS_1 := &"unlock_tool_slot_plus_1"
const UNLOCK_BASIC_FACE_SHOP_ITEMS := &"unlock_basic_face_shop_items"
const UNLOCK_ADVANCED_FACE_DISPLAY := &"unlock_advanced_face_display"
const UNLOCK_EARLY_BATTLE_DANGER_REDUCE := &"unlock_early_battle_danger_reduce"
const UNLOCK_BOSS_DANGER_REDUCE := &"unlock_boss_danger_reduce"
const UNLOCK_BOSS_RULE_FREE_REROLL := &"unlock_boss_rule_free_reroll"
const UNLOCK_BOSS_RULE_CHOICE := &"unlock_boss_rule_choice"
const UNLOCK_MAX_SCORED_FACES_PLUS_1 := &"unlock_max_scored_faces_plus_1"
const UNLOCK_BATTLE_REWARD_EXTRA_CHOICE := &"unlock_battle_reward_extra_choice"

const ALL_IDS := [
	UNLOCK_SHOP_RANDOM_SLOT_PLUS_1,
	UNLOCK_SHOP_PACK_SLOT_PLUS_1,
	UNLOCK_RANDOM_ITEM_DISCOUNT_25,
	UNLOCK_FIRST_PURCHASE_HALF_PRICE,
	UNLOCK_FACE_PACK_EXTRA_CANDIDATE,
	UNLOCK_ADVANCED_ORNAMENT_WEIGHT_X2,
	UNLOCK_SHOP_REROLL_DISCOUNT_2,
	UNLOCK_SHOP_FIRST_REROLL_FREE,
	UNLOCK_ITEM_SLOT_PLUS_1,
	UNLOCK_COMBO_PACK_PREFERRED_UPGRADE,
	UNLOCK_OBSERVATORY_COMBO_BONUS,
	UNLOCK_SCORING_ROUND_PLUS_1,
	UNLOCK_FIRST_SCORE_ECHO,
	UNLOCK_REROLL_PER_ROUND_PLUS_1,
	UNLOCK_UNUSED_REROLL_TO_GOLD,
	UNLOCK_COMBO_UPGRADE_SHOP_WEIGHT_X2,
	UNLOCK_COMBO_UPGRADE_SHOP_UPGRADE,
	UNLOCK_INTEREST_CAP_8,
	UNLOCK_FLAT_GOLD_AFTER_BATTLE,
	UNLOCK_CONTRACT_TOOL_SLOT,
	UNLOCK_TOOL_SLOT_PLUS_1,
	UNLOCK_BASIC_FACE_SHOP_ITEMS,
	UNLOCK_ADVANCED_FACE_DISPLAY,
	UNLOCK_EARLY_BATTLE_DANGER_REDUCE,
	UNLOCK_BOSS_DANGER_REDUCE,
	UNLOCK_BOSS_RULE_FREE_REROLL,
	UNLOCK_BOSS_RULE_CHOICE,
	UNLOCK_MAX_SCORED_FACES_PLUS_1,
	UNLOCK_BATTLE_REWARD_EXTRA_CHOICE,
]

const SHOP_POOL_IDS := [
	UNLOCK_SHOP_RANDOM_SLOT_PLUS_1,
	UNLOCK_SHOP_PACK_SLOT_PLUS_1,
	UNLOCK_RANDOM_ITEM_DISCOUNT_25,
	UNLOCK_FIRST_PURCHASE_HALF_PRICE,
	UNLOCK_FACE_PACK_EXTRA_CANDIDATE,
	UNLOCK_ADVANCED_ORNAMENT_WEIGHT_X2,
	UNLOCK_SHOP_REROLL_DISCOUNT_2,
	UNLOCK_SHOP_FIRST_REROLL_FREE,
	UNLOCK_ITEM_SLOT_PLUS_1,
	UNLOCK_COMBO_PACK_PREFERRED_UPGRADE,
	UNLOCK_OBSERVATORY_COMBO_BONUS,
	UNLOCK_SCORING_ROUND_PLUS_1,
	UNLOCK_FIRST_SCORE_ECHO,
	UNLOCK_REROLL_PER_ROUND_PLUS_1,
	UNLOCK_UNUSED_REROLL_TO_GOLD,
	UNLOCK_COMBO_UPGRADE_SHOP_WEIGHT_X2,
	UNLOCK_COMBO_UPGRADE_SHOP_UPGRADE,
	UNLOCK_INTEREST_CAP_8,
	UNLOCK_FLAT_GOLD_AFTER_BATTLE,
	UNLOCK_CONTRACT_TOOL_SLOT,
	UNLOCK_TOOL_SLOT_PLUS_1,
	UNLOCK_BASIC_FACE_SHOP_ITEMS,
	UNLOCK_ADVANCED_FACE_DISPLAY,
	UNLOCK_EARLY_BATTLE_DANGER_REDUCE,
	UNLOCK_BOSS_DANGER_REDUCE,
	UNLOCK_BOSS_RULE_FREE_REROLL,
	UNLOCK_BOSS_RULE_CHOICE,
	UNLOCK_MAX_SCORED_FACES_PLUS_1,
	UNLOCK_BATTLE_REWARD_EXTRA_CHOICE,
]


static func get_all_defs() -> Array[LongTermUnlockDef]:
	return [
		LongTermUnlockDef.create(UNLOCK_SHOP_RANDOM_SLOT_PLUS_1, "扩展货架", "遗物货架槽 +1，可刷新的骰具遗物从 2 个变 3 个。", LongTermUnlockDef.KIND_SHOP_PARAM, 10, EFFECT_SHOP_RANDOM_ITEM_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_SHOP_PACK_SLOT_PLUS_1, "满载货架", "商店骰包槽 +1，骰包从 2 个变 3 个。", LongTermUnlockDef.KIND_SHOP_PARAM, 12, EFFECT_SHOP_BOOSTER_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_RANDOM_ITEM_DISCOUNT_25, "清仓折扣", "遗物货架中的骰具遗物价格 -25%。", LongTermUnlockDef.KIND_SHOP_PARAM, 10, EFFECT_RANDOM_ITEM_DISCOUNT, 25),
		LongTermUnlockDef.create(UNLOCK_FIRST_PURCHASE_HALF_PRICE, "清仓甩卖", "每个骰商铺第一个购买的非长期解锁商品 -50%，可作用于遗物或骰包。", LongTermUnlockDef.KIND_SHOP_PARAM, 12, EFFECT_FIRST_NON_UNLOCK_PURCHASE_DISCOUNT, 50),
		LongTermUnlockDef.create(UNLOCK_FACE_PACK_EXTRA_CANDIDATE, "精工打磨", "骰面改造包候选数 +1。", LongTermUnlockDef.KIND_SHOP_PARAM, 10, EFFECT_FACE_PACK_EXTRA_CANDIDATES, 1),
		LongTermUnlockDef.create(UNLOCK_ADVANCED_ORNAMENT_WEIGHT_X2, "精工增辉", "骰面改造包内箔光 / 幻彩 / 多彩权重 ×2。", LongTermUnlockDef.KIND_SHOP_PARAM, 12, EFFECT_ADVANCED_ORNAMENT_WEIGHT_MULTIPLIER, 2),
		LongTermUnlockDef.create(UNLOCK_SHOP_REROLL_DISCOUNT_2, "刷新补贴", "骰商铺刷新费用 -2，最低 1。", LongTermUnlockDef.KIND_SHOP_PARAM, 8, EFFECT_SHOP_REROLL_BASE_DELTA, -2),
		LongTermUnlockDef.create(UNLOCK_SHOP_FIRST_REROLL_FREE, "刷新过载", "每个骰商铺第一次刷新免费。", LongTermUnlockDef.KIND_SHOP_PARAM, 10, EFFECT_FIRST_REROLL_FREE, 1),
		LongTermUnlockDef.create(UNLOCK_ITEM_SLOT_PLUS_1, "储物水晶", "道具槽位 +1；只影响非遗物道具，不影响骰具遗物槽。", LongTermUnlockDef.KIND_SLOT_PARAM, 12, EFFECT_ITEM_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_COMBO_PACK_PREFERRED_UPGRADE, "主型望远镜", "主骰型包必定包含本局最常结算主骰型的升级件。", LongTermUnlockDef.KIND_SHOP_PARAM, 10, EFFECT_COMBO_PACK_INCLUDE_MOST_PLAYED, 1),
		LongTermUnlockDef.create(UNLOCK_OBSERVATORY_COMBO_BONUS, "随身观测站", "每场战斗第一次结算本局最常结算主骰型时，终倍率 ×1.5。", LongTermUnlockDef.KIND_GLOBAL_RULE, 14, EFFECT_OBSERVATORY_ENABLED, 1),
		LongTermUnlockDef.create(UNLOCK_SCORING_ROUND_PLUS_1, "追加结算", "每场战斗可结算回合数 +1。", LongTermUnlockDef.KIND_GLOBAL_RULE, 14, EFFECT_BATTLE_HAND_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_FIRST_SCORE_ECHO, "双重追加结算", "每场战斗第一次结算后，额外追加一次 50% 得分。", LongTermUnlockDef.KIND_GLOBAL_RULE, 16, EFFECT_FIRST_SCORE_ECHO_ENABLED, 1),
		LongTermUnlockDef.create(UNLOCK_REROLL_PER_ROUND_PLUS_1, "追加重投", "每回合重投次数 +1。", LongTermUnlockDef.KIND_GLOBAL_RULE, 10, EFFECT_BATTLE_REROLL_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_UNUSED_REROLL_TO_GOLD, "重投回收", "战斗结束时，每剩余 2 次未使用重投获得 1 金币，最多 5 金币。", LongTermUnlockDef.KIND_ECONOMY_PARAM, 10, EFFECT_UNUSED_REROLL_GOLD_ENABLED, 1),
		LongTermUnlockDef.create(UNLOCK_COMBO_UPGRADE_SHOP_WEIGHT_X2, "主型商人", "商店骰包槽中，主骰型包出现权重 ×2。", LongTermUnlockDef.KIND_SHOP_PARAM, 8, EFFECT_COMBO_PACK_WEIGHT_MULTIPLIER, 2),
		LongTermUnlockDef.create(UNLOCK_COMBO_UPGRADE_SHOP_UPGRADE, "主型大亨", "主骰型包候选数 +1。", LongTermUnlockDef.KIND_SHOP_PARAM, 12, EFFECT_COMBO_UPGRADE_SHOP_UPGRADE, 1),
		LongTermUnlockDef.create(UNLOCK_INTEREST_CAP_8, "利息本金", "战斗胜利后，每 5 金币获得 1 金币利息，上限 8。", LongTermUnlockDef.KIND_ECONOMY_PARAM, 10, EFFECT_INTEREST_CAP, 8),
		LongTermUnlockDef.create(UNLOCK_FLAT_GOLD_AFTER_BATTLE, "摇钱树", "战斗胜利后获得 2 金币；若当前金币 ≥25，改为获得 4 金币。", LongTermUnlockDef.KIND_ECONOMY_PARAM, 12, EFFECT_MONEY_TREE_ENABLED, 1),
		LongTermUnlockDef.create(UNLOCK_CONTRACT_TOOL_SLOT, "空白契约", "获得 1 个契约遗物槽，只能装备普通 / 罕见骰具遗物。", LongTermUnlockDef.KIND_SLOT_PARAM, 8, EFFECT_CONTRACT_TOOL_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_TOOL_SLOT_PLUS_1, "反物质槽", "遗物槽位 +1，无稀有度限制。", LongTermUnlockDef.KIND_SLOT_PARAM, 16, EFFECT_DICE_TOOL_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_BASIC_FACE_SHOP_ITEMS, "骰面陈列", "商店骰包槽中，骰面改造包出现权重 ×2。", LongTermUnlockDef.KIND_SHOP_PARAM, 10, EFFECT_FACE_PACK_WEIGHT_MULTIPLIER, 2),
		LongTermUnlockDef.create(UNLOCK_ADVANCED_FACE_DISPLAY, "幻彩陈列", "商店骰面改造包允许出现更高级骰面奖励；不直接开售骰面商品。", LongTermUnlockDef.KIND_SHOP_PARAM, 14, EFFECT_ADVANCED_FACE_PACK_REWARDS_ENABLED, 1),
		LongTermUnlockDef.create(UNLOCK_EARLY_BATTLE_DANGER_REDUCE, "象形回退", "每圈前 2 次战斗，危急值按少 1 次行动计算。", LongTermUnlockDef.KIND_GLOBAL_RULE, 10, EFFECT_EARLY_BATTLE_DANGER_REDUCE, 1),
		LongTermUnlockDef.create(UNLOCK_BOSS_DANGER_REDUCE, "岩刻回退", "Boss 战危急值按少 2 次行动计算。", LongTermUnlockDef.KIND_BOSS_HOOK, 12, EFFECT_BOSS_DANGER_REDUCE, 2),
		LongTermUnlockDef.create(UNLOCK_BOSS_RULE_FREE_REROLL, "Boss 重拟", "每圈 Boss 战前，可免费重掷 1 次 Boss 规则。", LongTermUnlockDef.KIND_BOSS_HOOK, 10, EFFECT_BOSS_RULE_FREE_REROLL, 1),
		LongTermUnlockDef.create(UNLOCK_BOSS_RULE_CHOICE, "Boss 追溯", "Boss 战前显示 2 条 Boss 规则，玩家选择其中 1 条。", LongTermUnlockDef.KIND_BOSS_HOOK, 12, EFFECT_BOSS_RULE_CHOICE, 2),
		LongTermUnlockDef.create(UNLOCK_MAX_SCORED_FACES_PLUS_1, "宽幅画笔", "每回合最大可结算骰面数 +1。", LongTermUnlockDef.KIND_GLOBAL_RULE, 14, EFFECT_SCORE_SLOT_BONUS, 1),
		LongTermUnlockDef.create(UNLOCK_BATTLE_REWARD_EXTRA_CHOICE, "宽幅调色板", "战斗胜利奖励候选数 +1。", LongTermUnlockDef.KIND_GLOBAL_RULE, 16, EFFECT_BATTLE_REWARD_CHOICE_BONUS, 1),
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
	var ids: Array[StringName] = []
	for id in SHOP_POOL_IDS:
		ids.append(id)
	return ids


static func display_name_for_id(unlock_id: StringName) -> String:
	var def := get_def(unlock_id)
	return def.get_display_name() if def != null else str(unlock_id)


static func description_for_id(unlock_id: StringName) -> String:
	var def := get_def(unlock_id)
	return def.get_description() if def != null else ""


static func price_for_id(unlock_id: StringName) -> int:
	var def := get_def(unlock_id)
	return def.price_coins if def != null else 0
