extends RefCounted
class_name DiceToolCatalog


const DiceToolDef = preload("res://scripts/data_defs/DiceToolDef.gd")


const IMPLEMENTATION_FORMAL := &"formal"
const DROP_POOL_TBD := &"TBD"
const DROP_WEIGHT_TBD := "TBD"

const TOOL_BASIC_MULT := &"tool_basic_mult"
const TOOL_EVEN_MULT := &"tool_even_mult"
const TOOL_ODD_MULT := &"tool_odd_mult"
const TOOL_HIGH_PIP_MULT := &"tool_high_pip_mult"
const TOOL_LOW_PIP_MULT := &"tool_low_pip_mult"
const TOOL_PAIR_MULT := &"tool_pair_mult"
const TOOL_THREE_KIND_MULT := &"tool_three_kind_mult"
const TOOL_TWO_PAIR_MULT := &"tool_two_pair_mult"
const TOOL_STRAIGHT_MULT := &"tool_straight_mult"
const TOOL_ALIGNED_FACT_MULT := &"tool_aligned_fact_mult"
const TOOL_PAIR_CHIPS := &"tool_pair_chips"
const TOOL_THREE_KIND_CHIPS := &"tool_three_kind_chips"
const TOOL_TWO_PAIR_CHIPS := &"tool_two_pair_chips"
const TOOL_STRAIGHT_CHIPS := &"tool_straight_chips"
const TOOL_ALIGNED_FACT_CHIPS := &"tool_aligned_fact_chips"
const TOOL_FEW_SCORED_MULT := &"tool_few_scored_mult"
const TOOL_EMPTY_SLOT_XMULT := &"tool_empty_slot_xmult"
const TOOL_SHORT_STRAIGHT_RULE := &"tool_short_straight_rule"
const TOOL_UNSCORED_RETRIGGER := &"tool_unscored_retrigger"
const TOOL_CREDIT_DEBT := &"tool_credit_debt"
const TOOL_SELL_VALUE_DAGGER := &"tool_sell_value_dagger"
const TOOL_REMAINING_REROLL_CHIPS := &"tool_remaining_reroll_chips"
const TOOL_ZERO_REROLL_MULT := &"tool_zero_reroll_mult"
const TOOL_STONE_SEED := &"tool_stone_seed"
const TOOL_SIX_ROUND_XMULT := &"tool_six_round_xmult"
const TOOL_SIX_FORGE_GENERATOR := &"tool_six_forge_generator"
const TOOL_RANDOM_MULT := &"tool_random_mult"
const TOOL_FINAL_ROUND_RETRIGGER := &"tool_final_round_retrigger"
const TOOL_LOWEST_UNSCORED_MULT := &"tool_lowest_unscored_mult"
const TOOL_FREE_SHOP_REROLL := &"tool_free_shop_reroll"
const TOOL_FIBONACCI_MULT := &"tool_fibonacci_mult"
const TOOL_STAY_ORNAMENT_XMULT := &"tool_stay_ornament_xmult"
const TOOL_HIGH_PIP_CHIPS := &"tool_high_pip_chips"
const TOOL_TOOL_COUNT_MULT := &"tool_tool_count_mult"
const TOOL_NO_REROLL_INCOME := &"tool_no_reroll_income"
const TOOL_LOW_MID_RETRIGGER := &"tool_low_mid_retrigger"
const TOOL_ALL_FACES_HIGH_FOR_TOOLS := &"tool_all_faces_high_for_tools"
const TOOL_RISKY_MULT_SELF_DESTRUCT := &"tool_risky_mult_self_destruct"
const TOOL_EVEN_PLUS_FOUR_MULT := &"tool_even_plus_four_mult"
const TOOL_ODD_CHIPS := &"tool_odd_chips"
const TOOL_SIX_SCHOLAR := &"tool_six_scholar"
const TOOL_HIGH_INCOME_CHANCE := &"tool_high_income_chance"
const TOOL_COMBO_COUNT_MULT := &"tool_combo_count_mult"
const TOOL_NO_HIGH_STREAK_MULT := &"tool_no_high_streak_mult"
const TOOL_SPACE_COMBO_UPGRADE := &"tool_space_combo_upgrade"
const TOOL_GROWING_SELL_VALUE := &"tool_growing_sell_value"
const TOOL_ROUNDS_FOR_NO_REROLL := &"tool_rounds_for_no_reroll"
const TOOL_UNSCORED_LOW_HIGH_XMULT := &"tool_unscored_low_high_xmult"
const TOOL_STRAIGHT_RUNNER_CHIPS := &"tool_straight_runner_chips"
const TOOL_DECAY_CHIPS := &"tool_decay_chips"
const TOOL_SINGLE_FACE_BLUEPRINT := &"tool_single_face_blueprint"
const TOOL_SPLASH_SCORING := &"tool_splash_scoring"
const TOOL_LEFTOVER_CHIPS := &"tool_leftover_chips"
const TOOL_SINGLE_SIX_REFORGE := &"tool_single_six_reforge"
const TOOL_STAR_COUNTER := &"tool_star_counter"
const TOOL_TRAIL_MARKER := &"tool_trail_marker"
const TOOL_HIGH_REROLL_BOUNTY := &"tool_high_reroll_bounty"
const TOOL_GREEN_METER := &"tool_green_meter"
const TOOL_STRAIGHT_SIX_SUPPLY := &"tool_straight_six_supply"
const TOOL_TARGET_COMBO_CONTRACT := &"tool_target_combo_contract"
const TOOL_UNSTABLE_X3 := &"tool_unstable_x3"
const TOOL_REPEAT_COMBO_X3 := &"tool_repeat_combo_x3"
const TOOL_SKIP_PACK_MULT := &"tool_skip_pack_mult"
const TOOL_MAD_GROWTH := &"tool_mad_growth"
const TOOL_FOUR_FACE_SQUARE := &"tool_four_face_square"
const TOOL_STRAIGHT_FORGE_SUPPLY := &"tool_straight_forge_supply"
const TOOL_COMMON_TOOL_SUPPLY := &"tool_common_tool_supply"
const TOOL_ORNAMENT_VAMPIRE := &"tool_ornament_vampire"
const TOOL_SHORTCUT_STRAIGHT := &"tool_shortcut_straight"
const TOOL_COPY_HOLOGRAM := &"tool_copy_hologram"
const TOOL_POOR_FORGE_SUPPLY := &"tool_poor_forge_supply"
const TOOL_SIX_STAY_KING := &"tool_six_stay_king"
const TOOL_FIVE_FACE_INCOME := &"tool_five_face_income"
const TOOL_ROCKET_INCOME := &"tool_rocket_income"
const TOOL_OBELISK_ROTATION := &"tool_obelisk_rotation"
const TOOL_HIGH_TO_GOLD := &"tool_high_to_gold"
const TOOL_BOSS_RULE_BREAKER := &"tool_boss_rule_breaker"
const TOOL_FIRST_HIGH_X2 := &"tool_first_high_x2"
const TOOL_SELL_VALUE_GROWTH := &"tool_sell_value_growth"
const TOOL_MAX_SCORE_DECAY := &"tool_max_score_decay"
const TOOL_FACE_COUNT_GAP_MULT := &"tool_face_count_gap_mult"
const TOOL_HIGH_STAY_PARKING := &"tool_high_stay_parking"
const TOOL_MAIL_PIP_REBATE := &"tool_mail_pip_rebate"
const TOOL_INTEREST_BOOSTER := &"tool_interest_booster"
const TOOL_PACK_HALLUCINATION := &"tool_pack_hallucination"
const TOOL_FORGE_ITEM_ORACLE := &"tool_forge_item_oracle"
const TOOL_SCORE_SLOT_PLUS_ONE := &"tool_score_slot_plus_one"
const TOOL_REROLL_PLUS_ONE := &"tool_reroll_plus_one"
const TOOL_STONE_FACE_CHIPS := &"tool_stone_face_chips"
const TOOL_ROUND_GOLD_INCOME := &"tool_round_gold_income"
const TOOL_LUCKY_CAT_INTEGER := &"tool_lucky_cat_integer"
const TOOL_UNCOMMON_TEAM_XMULT := &"tool_uncommon_team_xmult"
const TOOL_COIN_CHIPS := &"tool_coin_chips"
const TOOL_DOUBLE_REWARD_TAG := &"tool_double_reward_tag"
const TOOL_SINGLE_REROLL_TRADE := &"tool_single_reroll_trade"
const TOOL_SHOP_REROLL_MULT := &"tool_shop_reroll_mult"
const TOOL_DECAY_POPCORN := &"tool_decay_popcorn"
const TOOL_TWO_PAIR_TROUSERS := &"tool_two_pair_trousers"
const TOOL_ANCIENT_POINT_CLASS := &"tool_ancient_point_class"
const TOOL_REROLL_DECAY_X2 := &"tool_reroll_decay_x2"
const TOOL_SIX_FOUR_BROADCAST := &"tool_six_four_broadcast"
const TOOL_SELTZER_RETRIGGER := &"tool_seltzer_retrigger"
const TOOL_CASTLE_PIP_CLASS := &"tool_castle_pip_class"
const TOOL_HIGH_SMILE_MULT := &"tool_high_smile_mult"
const TOOL_CAMPFIRE_SALES := &"tool_campfire_sales"
const TOOL_GOLD_ORNAMENT_INCOME := &"tool_gold_ornament_income"
const TOOL_BONE_SAFETY := &"tool_bone_safety"
const TOOL_FINAL_ROUND_ACROBAT := &"tool_final_round_acrobat"
const TOOL_HIGH_FACE_RETRIGGER := &"tool_high_face_retrigger"
const TOOL_SELL_VALUE_SWORD := &"tool_sell_value_sword"
const TOOL_TROUBADOUR_SLOTS := &"tool_troubadour_slots"
const TOOL_MARKED_TEMP_FACE := &"tool_marked_temp_face"
const TOOL_FACT_TOLERANCE := &"tool_fact_tolerance"
const TOOL_SKIP_THROWBACK := &"tool_skip_throwback"
const TOOL_FIRST_FACE_RETRIGGER := &"tool_first_face_retrigger"
const TOOL_EVEN_COIN_GEM := &"tool_even_coin_gem"
const TOOL_ODD_BLOODSTONE := &"tool_odd_bloodstone"
const TOOL_HIGH_ARROWHEAD := &"tool_high_arrowhead"
const TOOL_LOW_ONYX_AGATE := &"tool_low_onyx_agate"
const TOOL_BURST_BREAK_GLASS := &"tool_burst_break_glass"
const TOOL_DUPLICATE_SHOWMAN := &"tool_duplicate_showman"
const TOOL_FOUR_FACT_POT := &"tool_four_fact_pot"
const TOOL_RIGHT_COPY_BLUEPRINT := &"tool_right_copy_blueprint"
const TOOL_TWO_PIP_WEEJOKER := &"tool_two_pip_weejoker"
const TOOL_MERRY_REROLLER := &"tool_merry_reroller"
const TOOL_PROBABILITY_DOUBLER := &"tool_probability_doubler"
const TOOL_IDOL_TARGET := &"tool_idol_target"
const TOOL_LOW_PLUS_OTHER_X2 := &"tool_low_plus_other_x2"
const TOOL_BOSS_TRIGGER_BOUNTY := &"tool_boss_trigger_bounty"
const TOOL_FOUR_REROLL_ROAD := &"tool_four_reroll_road"
const TOOL_PAIR_X2 := &"tool_pair_x2"
const TOOL_THREE_KIND_X3 := &"tool_three_kind_x3"
const TOOL_FOUR_KIND_X4 := &"tool_four_kind_x4"
const TOOL_STRAIGHT_X3 := &"tool_straight_x3"
const TOOL_ALIGNED_FACT_X2 := &"tool_aligned_fact_x2"
const TOOL_STUNT_CHIPS := &"tool_stunt_chips"
const TOOL_DELAYED_CLONE_SALE := &"tool_delayed_clone_sale"
const TOOL_LEFT_COPY_BRAINSTORM := &"tool_left_copy_brainstorm"
const TOOL_UPGRADE_VARIETY_INCOME := &"tool_upgrade_variety_income"
const TOOL_FIVE_STAY_MULT := &"tool_five_stay_mult"
const TOOL_MODIFIED_FACE_LICENSE := &"tool_modified_face_license"
const TOOL_BATTLE_START_FORGE_ITEM := &"tool_battle_start_forge_item"
const TOOL_COMBO_UPGRADE_SHOP_FREE := &"tool_combo_upgrade_shop_free"
const TOOL_FIRST_REROLL_COMBO_UPGRADE := &"tool_first_reroll_combo_upgrade"
const TOOL_COIN_MULT_BOOTSTRAP := &"tool_coin_mult_bootstrap"
const TOOL_HIGH_PIP_TRANSFORM_X := &"tool_high_pip_transform_x"
const TOOL_FIVE_SIX_X2 := &"tool_five_six_x2"
const TOOL_REROLL_23_X := &"tool_reroll_23_x"
const TOOL_BOSS_DISABLE_LEGEND := &"tool_boss_disable_legend"
const TOOL_SHOP_END_ITEM_COPY := &"tool_shop_end_item_copy"

const FIRST_BATCH_IDS := [
	TOOL_BASIC_MULT,
	TOOL_EVEN_MULT,
	TOOL_ODD_MULT,
	TOOL_HIGH_PIP_MULT,
	TOOL_LOW_PIP_MULT,
	TOOL_PAIR_MULT,
	TOOL_THREE_KIND_MULT,
	TOOL_TWO_PAIR_MULT,
	TOOL_STRAIGHT_MULT,
	TOOL_ALIGNED_FACT_MULT,
	TOOL_PAIR_CHIPS,
	TOOL_THREE_KIND_CHIPS,
	TOOL_TWO_PAIR_CHIPS,
	TOOL_STRAIGHT_CHIPS,
	TOOL_ALIGNED_FACT_CHIPS,
	TOOL_FEW_SCORED_MULT,
	TOOL_EMPTY_SLOT_XMULT,
	TOOL_SHORT_STRAIGHT_RULE,
	TOOL_UNSCORED_RETRIGGER,
	TOOL_CREDIT_DEBT,
	TOOL_SELL_VALUE_DAGGER,
	TOOL_REMAINING_REROLL_CHIPS,
	TOOL_ZERO_REROLL_MULT,
	TOOL_STONE_SEED,
	TOOL_SIX_ROUND_XMULT,
	TOOL_SIX_FORGE_GENERATOR,
	TOOL_RANDOM_MULT,
	TOOL_FINAL_ROUND_RETRIGGER,
	TOOL_LOWEST_UNSCORED_MULT,
	TOOL_FREE_SHOP_REROLL,
	TOOL_FIBONACCI_MULT,
	TOOL_STAY_ORNAMENT_XMULT,
	TOOL_HIGH_PIP_CHIPS,
	TOOL_TOOL_COUNT_MULT,
	TOOL_NO_REROLL_INCOME,
	TOOL_LOW_MID_RETRIGGER,
	TOOL_ALL_FACES_HIGH_FOR_TOOLS,
	TOOL_RISKY_MULT_SELF_DESTRUCT,
	TOOL_EVEN_PLUS_FOUR_MULT,
	TOOL_ODD_CHIPS,
	TOOL_SIX_SCHOLAR,
	TOOL_HIGH_INCOME_CHANCE,
	TOOL_COMBO_COUNT_MULT,
	TOOL_NO_HIGH_STREAK_MULT,
	TOOL_SPACE_COMBO_UPGRADE,
	TOOL_GROWING_SELL_VALUE,
	TOOL_ROUNDS_FOR_NO_REROLL,
	TOOL_UNSCORED_LOW_HIGH_XMULT,
	TOOL_STRAIGHT_RUNNER_CHIPS,
	TOOL_DECAY_CHIPS,
]

const SECOND_BATCH_IDS := [
	TOOL_SINGLE_FACE_BLUEPRINT,
	TOOL_SPLASH_SCORING,
	TOOL_LEFTOVER_CHIPS,
	TOOL_SINGLE_SIX_REFORGE,
	TOOL_STAR_COUNTER,
	TOOL_TRAIL_MARKER,
	TOOL_HIGH_REROLL_BOUNTY,
	TOOL_GREEN_METER,
	TOOL_STRAIGHT_SIX_SUPPLY,
	TOOL_TARGET_COMBO_CONTRACT,
	TOOL_UNSTABLE_X3,
	TOOL_REPEAT_COMBO_X3,
	TOOL_SKIP_PACK_MULT,
	TOOL_MAD_GROWTH,
	TOOL_FOUR_FACE_SQUARE,
	TOOL_STRAIGHT_FORGE_SUPPLY,
	TOOL_COMMON_TOOL_SUPPLY,
	TOOL_ORNAMENT_VAMPIRE,
	TOOL_SHORTCUT_STRAIGHT,
	TOOL_COPY_HOLOGRAM,
	TOOL_POOR_FORGE_SUPPLY,
	TOOL_SIX_STAY_KING,
	TOOL_FIVE_FACE_INCOME,
	TOOL_ROCKET_INCOME,
	TOOL_OBELISK_ROTATION,
	TOOL_HIGH_TO_GOLD,
	TOOL_BOSS_RULE_BREAKER,
	TOOL_FIRST_HIGH_X2,
	TOOL_SELL_VALUE_GROWTH,
	TOOL_MAX_SCORE_DECAY,
	TOOL_FACE_COUNT_GAP_MULT,
	TOOL_HIGH_STAY_PARKING,
	TOOL_MAIL_PIP_REBATE,
	TOOL_INTEREST_BOOSTER,
	TOOL_PACK_HALLUCINATION,
	TOOL_FORGE_ITEM_ORACLE,
	TOOL_SCORE_SLOT_PLUS_ONE,
	TOOL_REROLL_PLUS_ONE,
	TOOL_STONE_FACE_CHIPS,
	TOOL_ROUND_GOLD_INCOME,
	TOOL_LUCKY_CAT_INTEGER,
	TOOL_UNCOMMON_TEAM_XMULT,
	TOOL_COIN_CHIPS,
	TOOL_DOUBLE_REWARD_TAG,
	TOOL_SINGLE_REROLL_TRADE,
	TOOL_SHOP_REROLL_MULT,
	TOOL_DECAY_POPCORN,
	TOOL_TWO_PAIR_TROUSERS,
	TOOL_ANCIENT_POINT_CLASS,
	TOOL_REROLL_DECAY_X2,
]

const THIRD_BATCH_IDS := [
	TOOL_SIX_FOUR_BROADCAST,
	TOOL_SELTZER_RETRIGGER,
	TOOL_CASTLE_PIP_CLASS,
	TOOL_HIGH_SMILE_MULT,
	TOOL_CAMPFIRE_SALES,
	TOOL_GOLD_ORNAMENT_INCOME,
	TOOL_BONE_SAFETY,
	TOOL_FINAL_ROUND_ACROBAT,
	TOOL_HIGH_FACE_RETRIGGER,
	TOOL_SELL_VALUE_SWORD,
	TOOL_TROUBADOUR_SLOTS,
	TOOL_MARKED_TEMP_FACE,
	TOOL_FACT_TOLERANCE,
	TOOL_SKIP_THROWBACK,
	TOOL_FIRST_FACE_RETRIGGER,
	TOOL_EVEN_COIN_GEM,
	TOOL_ODD_BLOODSTONE,
	TOOL_HIGH_ARROWHEAD,
	TOOL_LOW_ONYX_AGATE,
	TOOL_BURST_BREAK_GLASS,
	TOOL_DUPLICATE_SHOWMAN,
	TOOL_FOUR_FACT_POT,
	TOOL_RIGHT_COPY_BLUEPRINT,
	TOOL_TWO_PIP_WEEJOKER,
	TOOL_MERRY_REROLLER,
	TOOL_PROBABILITY_DOUBLER,
	TOOL_IDOL_TARGET,
	TOOL_LOW_PLUS_OTHER_X2,
	TOOL_BOSS_TRIGGER_BOUNTY,
	TOOL_FOUR_REROLL_ROAD,
	TOOL_PAIR_X2,
	TOOL_THREE_KIND_X3,
	TOOL_FOUR_KIND_X4,
	TOOL_STRAIGHT_X3,
	TOOL_ALIGNED_FACT_X2,
	TOOL_STUNT_CHIPS,
	TOOL_DELAYED_CLONE_SALE,
	TOOL_LEFT_COPY_BRAINSTORM,
	TOOL_UPGRADE_VARIETY_INCOME,
	TOOL_FIVE_STAY_MULT,
	TOOL_MODIFIED_FACE_LICENSE,
	TOOL_BATTLE_START_FORGE_ITEM,
	TOOL_COMBO_UPGRADE_SHOP_FREE,
	TOOL_FIRST_REROLL_COMBO_UPGRADE,
	TOOL_COIN_MULT_BOOTSTRAP,
	TOOL_HIGH_PIP_TRANSFORM_X,
	TOOL_FIVE_SIX_X2,
	TOOL_REROLL_23_X,
	TOOL_BOSS_DISABLE_LEGEND,
	TOOL_SHOP_END_ITEM_COPY,
]

const ALL_IDS := FIRST_BATCH_IDS + SECOND_BATCH_IDS + THIRD_BATCH_IDS


static func get_all_defs() -> Array[DiceToolDef]:
	return [
		_make_def(TOOL_BASIC_MULT, "基础倍率器", "Joker", 1, &"common", "结算时，+4 倍率。", &"on_score", [&"mult"]),
		_make_def(TOOL_EVEN_MULT, "偶面增幅器", "Greedy Joker", 2, &"common", "每个被结算的偶数面 +3 倍率。偶数面为有效点数 2 / 4 / 6 / 8；石质面饰不参与判断。", &"on_scored_face", [&"mult", &"even"]),
		_make_def(TOOL_ODD_MULT, "奇面增幅器", "Lusty Joker", 3, &"common", "每个被结算的奇数面 +3 倍率。奇数面为有效点数 1 / 3 / 5 / 7；石质面饰不参与判断。", &"on_scored_face", [&"mult", &"odd"]),
		_make_def(TOOL_HIGH_PIP_MULT, "高点增幅器", "Wrathful Joker", 4, &"common", "每个被结算的高点面 +3 倍率。高点面为有效点数 5 / 6 / 7 / 8。", &"on_scored_face", [&"mult", &"high"]),
		_make_def(TOOL_LOW_PIP_MULT, "低点增幅器", "Gluttonous Joker", 5, &"common", "每个被结算的低点面 +3 倍率。低点面为有效点数 1 / 2 / 3 / 4。", &"on_scored_face", [&"mult", &"low"]),
		_make_def(TOOL_PAIR_MULT, "对子倍率器", "Jolly Joker", 6, &"common", "若本回合有效被结算骰面中存在一对结构，+8 倍率。", &"on_score", [&"mult", &"pair"]),
		_make_def(TOOL_THREE_KIND_MULT, "三同倍率器", "Zany Joker", 7, &"common", "若本回合有效被结算骰面中存在三同结构，+12 倍率。", &"on_score", [&"mult", &"three_kind"]),
		_make_def(TOOL_TWO_PAIR_MULT, "两对倍率器", "Mad Joker", 8, &"common", "若本回合有效被结算骰面中存在两对结构，+10 倍率。", &"on_score", [&"mult", &"two_pair"]),
		_make_def(TOOL_STRAIGHT_MULT, "顺子倍率器", "Crazy Joker", 9, &"common", "若本回合满足顺子结构，+12 倍率。", &"on_score", [&"mult", &"straight"]),
		_make_def(TOOL_ALIGNED_FACT_MULT, "整齐倍率器", "Droll Joker", 10, &"common", "若本回合有效被结算骰面满足全奇、全偶、全低或全高之一，+10 倍率。", &"on_score", [&"mult", &"aligned"]),
		_make_def(TOOL_PAIR_CHIPS, "对子战力器", "Sly Joker", 11, &"common", "若本回合有效被结算骰面中存在一对结构，+50 基础战力。", &"on_score", [&"chips", &"pair"]),
		_make_def(TOOL_THREE_KIND_CHIPS, "三同战力器", "Wily Joker", 12, &"common", "若本回合有效被结算骰面中存在三同结构，+100 基础战力。", &"on_score", [&"chips", &"three_kind"]),
		_make_def(TOOL_TWO_PAIR_CHIPS, "两对战力器", "Clever Joker", 13, &"common", "若本回合有效被结算骰面中存在两对结构，+80 基础战力。", &"on_score", [&"chips", &"two_pair"]),
		_make_def(TOOL_STRAIGHT_CHIPS, "顺子战力器", "Devious Joker", 14, &"common", "若本回合满足顺子结构，+100 基础战力。", &"on_score", [&"chips", &"straight"]),
		_make_def(TOOL_ALIGNED_FACT_CHIPS, "整齐战力器", "Crafty Joker", 15, &"common", "若本回合有效被结算骰面满足全奇、全偶、全低或全高之一，+80 基础战力。", &"on_score", [&"chips", &"aligned"]),
		_make_def(TOOL_FEW_SCORED_MULT, "少选倍率器", "Half Joker", 16, &"common", "若本回合结算 3 个或更少骰面，+20 倍率；石质面饰仍计入结算数量。", &"on_score", [&"mult", &"few_scored"]),
		_make_def(TOOL_EMPTY_SLOT_XMULT, "空槽棱镜", "Joker Stencil", 17, &"uncommon", "结算时，终倍率 ×N。N = 空骰具槽数量 + 1；负载骰具不占用槽位。", &"on_score", [&"xmult", &"slot"]),
		_make_def(TOOL_SHORT_STRAIGHT_RULE, "四指顺规", "Four Fingers", 18, &"uncommon", "顺子判定只需要 4 个连续有效点数。", &"rule_modifier", [&"straight"]),
		_make_def(TOOL_UNSCORED_RETRIGGER, "留场复诵器", "Mime", 19, &"uncommon", "所有未结算留场骰面的留场触发效果额外执行 1 次。", &"after_unscored_stay", [&"retrigger", &"stay"]),
		_make_def(TOOL_CREDIT_DEBT, "负债额度卡", "Credit Card", 20, &"common", "金币最低可以降到 -20。", &"economy_rule", [&"coins"]),
		_make_def(TOOL_SELL_VALUE_DAGGER, "祭价短刃", "Ceremonial Dagger", 21, &"uncommon", "选择战斗时，摧毁右侧相邻骰具；本骰具永久获得倍率：被摧毁骰具卖价 ×2。", &"on_battle_start", [&"mult", &"destroy"], [], [&"mult_bonus"]),
		_make_def(TOOL_REMAINING_REROLL_CHIPS, "重投旗帜", "Banner", 22, &"common", "结算时，每个剩余重投次数 +30 基础战力。", &"on_score", [&"chips", &"reroll"]),
		_make_def(TOOL_ZERO_REROLL_MULT, "零投山巅", "Mystic Summit", 23, &"common", "若剩余重投次数为 0，+15 倍率。", &"on_score", [&"mult", &"reroll"]),
		_make_def(TOOL_STONE_SEED, "石化播种器", "Marble Joker", 24, &"uncommon", "选择战斗时，随机选择 1 个现有骰面，将其面饰替换为石质面饰。", &"on_battle_start", [&"ornament", &"stone"]),
		_make_def(TOOL_SIX_ROUND_XMULT, "六回合忠诚器", "Loyalty Card", 25, &"uncommon", "每第 6 次结算回合，终倍率 ×4。", &"on_score", [&"xmult", &"counter"], [], [&"scored_round_counter"]),
		_make_def(TOOL_SIX_FORGE_GENERATOR, "六点铸件球", "8 Ball", 26, &"common", "每个被结算的 6 点面有 1/4 概率生成 1 个随机铸骰件；需要 1 个空道具槽位。", &"on_scored_face", [&"generate", &"six"]),
		_make_def(TOOL_RANDOM_MULT, "乱码倍率器", "Misprint", 27, &"common", "结算时，随机 +0 到 +23 倍率。", &"on_score", [&"mult", &"random"]),
		_make_def(TOOL_FINAL_ROUND_RETRIGGER, "黄昏复触器", "Dusk", 28, &"uncommon", "在本场最后一回合中，所有被结算骰面额外触发 1 次。", &"on_score", [&"retrigger"]),
		_make_def(TOOL_LOWEST_UNSCORED_MULT, "留场低拳", "Raised Fist", 29, &"common", "将未结算留场骰面中的最低有效点数 ×2 加入倍率；没有有效点数则不触发。", &"on_score", [&"mult", &"stay"]),
		_make_def(TOOL_FREE_SHOP_REROLL, "免费刷新器", "Chaos the Clown", 30, &"common", "每个商店获得 1 次免费刷新。", &"on_shop_open", [&"shop"]),
		_make_def(TOOL_FIBONACCI_MULT, "斐波那契增幅器", "Fibonacci", 31, &"uncommon", "每个被结算的 1 / 2 / 3 / 5 / 8 点面 +8 倍率。", &"on_scored_face", [&"mult", &"pip"]),
		_make_def(TOOL_STAY_ORNAMENT_XMULT, "留场钢核", "Steel Joker", 32, &"uncommon", "完整出战骰组中，每 5 个留场面饰骰面，使本骰具终倍率 +1；本骰具基础终倍率为 ×1。", &"on_score", [&"xmult", &"stay"]),
		_make_def(TOOL_HIGH_PIP_CHIPS, "高点战力面具", "Scary Face", 33, &"common", "每个被结算高点面 +30 基础战力。高点面为有效点数 5 / 6 / 7 / 8。", &"on_scored_face", [&"chips", &"high"]),
		_make_def(TOOL_TOOL_COUNT_MULT, "骰具共鸣器", "Abstract Joker", 34, &"common", "结算时，每个已安装骰具 +3 倍率；负载骰具也计入。", &"on_score", [&"mult", &"tool_count"]),
		_make_def(TOOL_NO_REROLL_INCOME, "延迟收益器", "Delayed Gratification", 35, &"common", "回合结束时，若本回合没有使用重投，则每个剩余重投次数获得 2 金币。", &"round_end", [&"coins", &"reroll"]),
		_make_def(TOOL_LOW_MID_RETRIGGER, "低中点破解器", "Hack", 36, &"uncommon", "重新触发每个被结算的 2 / 3 / 4 / 5 点面。", &"on_scored_face", [&"retrigger", &"pip"]),
		_make_def(TOOL_ALL_FACES_HIGH_FOR_TOOLS, "高点拟像器", "Pareidolia", 37, &"uncommon", "所有非石质骰面在骰具条件判断中都视为高点面；实际点数不变。", &"rule_modifier", [&"high"]),
		_make_def(TOOL_RISKY_MULT_SELF_DESTRUCT, "脆香倍率器", "Gros Michel", 38, &"common", "结算时 +15 倍率；战斗结束时有 1/6 概率自毁。", &"on_score_and_battle_end", [&"mult", &"destroy"]),
		_make_def(TOOL_EVEN_PLUS_FOUR_MULT, "偶数鼓手", "Even Steven", 39, &"common", "每个被结算偶数面 +4 倍率。偶数面为有效点数 2 / 4 / 6 / 8。", &"on_scored_face", [&"mult", &"even"]),
		_make_def(TOOL_ODD_CHIPS, "奇数行者", "Odd Todd", 40, &"common", "每个被结算奇数面 +31 基础战力。奇数面为有效点数 1 / 3 / 5 / 7。", &"on_scored_face", [&"chips", &"odd"]),
		_make_def(TOOL_SIX_SCHOLAR, "六点学者", "Scholar", 41, &"common", "每个被结算 6 点面 +20 基础战力，且 +4 倍率。", &"on_scored_face", [&"chips", &"mult", &"six"]),
		_make_def(TOOL_HIGH_INCOME_CHANCE, "高点名片", "Business Card", 42, &"common", "每个被结算高点面有 1/2 概率获得 2 金币；高点面为有效点数 5 / 6 / 7 / 8。", &"on_scored_face", [&"coins", &"high"]),
		_make_def(TOOL_COMBO_COUNT_MULT, "骰型新星", "Supernova", 43, &"common", "将本局当前主骰型已结算次数加入倍率；本次结算先计入次数。", &"on_score", [&"mult", &"combo_count"]),
		_make_def(TOOL_NO_HIGH_STREAK_MULT, "无高通勤车", "Ride the Bus", 44, &"common", "若本回合没有高点面被结算，本骰具连续计数 +1，并提供等同连续计数的倍率；若有高点面则重置。", &"on_score", [&"mult", &"streak"], [], [&"no_high_streak"]),
		_make_def(TOOL_SPACE_COMBO_UPGRADE, "星隙升格器", "Space Joker", 45, &"uncommon", "结算时有 1/4 概率使本回合主骰型等级 +1。", &"on_score", [&"combo_level", &"random"]),
		_make_def(TOOL_GROWING_SELL_VALUE, "增值蛋壳", "Egg", 46, &"common", "每回合结束时，本骰具卖价 +3 金币。", &"round_end", [&"sell_value"], [], [&"sell_value"]),
		_make_def(TOOL_ROUNDS_FOR_NO_REROLL, "窃回合者", "Burglar", 47, &"uncommon", "选择战斗时，本场战斗结算回合数 +3，且本场战斗重投次数上限设为 0。", &"on_battle_start", [&"rounds", &"reroll"]),
		_make_def(TOOL_UNSCORED_LOW_HIGH_XMULT, "留场黑板", "Blackboard", 48, &"uncommon", "若本回合存在至少 1 个有效未结算留场骰面，且这些有效未结算留场骰面全部为低点面或全部为高点面，则终倍率 ×3。", &"on_score", [&"xmult", &"stay"]),
		_make_def(TOOL_STRAIGHT_RUNNER_CHIPS, "顺子跑者", "Runner", 49, &"common", "若本回合满足顺子结构，本骰具永久获得 +15 基础战力；结算时提供其当前累计的基础战力。", &"on_score", [&"chips", &"straight", &"counter"], [], [&"chips_bonus"]),
		_make_def(TOOL_DECAY_CHIPS, "融化战力器", "Ice Cream", 50, &"common", "初始提供 +100 基础战力；每完成 1 次结算回合后，本骰具基础战力 -5，最低降至 0。", &"on_score_and_round_end", [&"chips", &"decay"], [], [&"current_chips_bonus"]),
		_make_def(TOOL_SINGLE_FACE_BLUEPRINT, "单面样本", "DNA", 51, &"rare", "每场战斗第一回合只结算 1 个骰面时，进入待处理复制覆盖状态，选择现有目标骰面后覆盖点数、面饰、印记。", &"on_first_round_single_score", [&"copy"], [], []),
		_make_def(TOOL_SPLASH_SCORING, "溅射计分", "Splash", 52, &"common", "本回合被结算但未参与主骰型结构的骰面，其面饰额外触发 1 次；不重复点数总和。", &"on_score", [&"ornament", &"retrigger"]),
		_make_def(TOOL_LEFTOVER_CHIPS, "余面筹码", "Blue Joker", 53, &"common", "完整出战骰组中，每个本回合未被结算的投出骰面位，+2 基础战力。", &"on_score", [&"chips", &"unscored"]),
		_make_def(TOOL_SINGLE_SIX_REFORGE, "六感重铸", "Sixth Sense", 54, &"uncommon", "每场战斗第一回合只结算 1 个 6 点面时，结算后重置该物理骰面并生成 1 个随机铸骰件；需要空道具槽位。", &"on_first_round_single_score", [&"generate", &"six", &"reset"]),
		_make_def(TOOL_STAR_COUNTER, "星群计数器", "Constellation", 55, &"uncommon", "本局每使用 3 个主骰型升级件，本骰具终倍率 +1；计分时提供整数终倍率。", &"on_score", [&"xmult", &"combo_upgrade"], [], [&"combo_upgrade_used_count"]),
		_make_def(TOOL_TRAIL_MARKER, "行者刻痕", "Hiker", 56, &"uncommon", "每当一个物理骰面首次在本局被结算，本骰具永久获得 +5 基础战力。", &"on_score", [&"chips", &"counter"], [], [&"credited_face_keys"]),
		_make_def(TOOL_HIGH_REROLL_BOUNTY, "高点悬赏", "Faceless Joker", 57, &"common", "若一次重投中选择了 3 个或更多高点面，获得 5 金币。", &"before_reroll", [&"coins", &"high", &"reroll"]),
		_make_def(TOOL_GREEN_METER, "绿骰计数器", "Green Joker", 58, &"common", "每完成 1 次结算，本骰具倍率 +1；每使用 1 次重投，本骰具倍率 -1，最低为 0。", &"on_score_and_reroll", [&"mult", &"counter"], [], [&"green_mult"]),
		_make_def(TOOL_STRAIGHT_SIX_SUPPLY, "顺六补给", "Superposition", 59, &"common", "若本回合主骰型为顺子，且被结算有效骰面中包含 6 点面，生成 1 个随机铸骰件；需要空道具槽位。", &"on_score", [&"generate", &"straight", &"six"]),
		_make_def(TOOL_TARGET_COMBO_CONTRACT, "骰型委托单", "To Do List", 60, &"common", "若本回合主骰型等于当前指定主骰型，获得 4 金币；指定主骰型在回合结束时重新随机。", &"on_score_and_round_end", [&"coins", &"combo"], [], [&"target_combo_id"]),
		_make_def(TOOL_UNSTABLE_X3, "不稳定三倍器", "Cavendish", 61, &"common", "计分时终倍率 ×3；战斗结束时有 1/1000 概率自毁。", &"on_score_and_battle_end", [&"xmult", &"destroy"]),
		_make_def(TOOL_REPEAT_COMBO_X3, "复现三倍器", "Card Sharp", 62, &"uncommon", "若本回合主骰型在本场战斗中此前已经结算过，终倍率 ×3；结算后记录本回合主骰型。", &"on_score", [&"xmult", &"combo"], [], [&"seen_combo_ids_this_battle"]),
		_make_def(TOOL_SKIP_PACK_MULT, "跳包倍率器", "Red Card", 63, &"common", "每跳过 1 个补充包，本骰具永久获得 +3 倍率。", &"on_pack_skipped", [&"mult", &"pack"], [], [&"skipped_pack_count"]),
		_make_def(TOOL_MAD_GROWTH, "狂乱增长器", "Madness", 64, &"uncommon", "每选择 1 次非 Boss 战斗，本骰具狂乱计数 +1，并随机摧毁 1 个其他已安装骰具；每 2 点计数使终倍率 +1。", &"on_battle_start", [&"xmult", &"destroy"], [], [&"madness_charge"]),
		_make_def(TOOL_FOUR_FACE_SQUARE, "四面方阵", "Square Joker", 65, &"common", "若本回合正好结算 4 个骰面，本骰具永久获得 +4 基础战力；计分时提供累计基础战力。", &"on_score", [&"chips", &"counter"], [], [&"square_chips"]),
		_make_def(TOOL_STRAIGHT_FORGE_SUPPLY, "顺子铸件供给", "Séance", 66, &"uncommon", "若本回合主骰型为顺子，生成 1 个随机进阶铸骰件；需要空道具槽位。", &"on_score", [&"generate", &"straight"]),
		_make_def(TOOL_COMMON_TOOL_SUPPLY, "普通骰具补给", "Riff-Raff", 67, &"common", "选择战斗时，生成最多 2 个随机普通骰具道具，进入道具槽位。", &"on_battle_start", [&"generate", &"dice_tool"]),
		_make_def(TOOL_ORNAMENT_VAMPIRE, "面饰吞噬者", "Vampire", 68, &"uncommon", "每个被结算且带有面饰的骰面，会被本骰具吞噬面饰；每吞噬 10 个面饰，本骰具终倍率 +1。", &"on_score", [&"xmult", &"ornament"], [], [&"absorbed_ornament_count"]),
		_make_def(TOOL_SHORTCUT_STRAIGHT, "捷径顺规", "Shortcut", 69, &"uncommon", "顺子判定允许缺 1 个中间点数。", &"rule_modifier", [&"straight"]),
		_make_def(TOOL_COPY_HOLOGRAM, "复写增幅器", "Hologram", 70, &"uncommon", "每当 1 个现有骰面被复制覆盖，本骰具复制计数 +1；每 2 点复制计数使终倍率 +1。", &"on_face_copied", [&"xmult", &"copy"], [], [&"copied_face_count"]),
		_make_def(TOOL_POOR_FORGE_SUPPLY, "低资铸件供给", "Vagabond", 71, &"rare", "若结算后当前金币 ≤4，生成 1 个随机铸骰件；需要空道具槽位。", &"on_score", [&"generate", &"coins"]),
		_make_def(TOOL_SIX_STAY_KING, "六点留王", "Baron", 72, &"rare", "未结算留场的每个 6 点面，使终倍率 ×2。", &"on_score", [&"xmult", &"stay", &"six"]),
		_make_def(TOOL_FIVE_FACE_INCOME, "五点存款", "Cloud 9", 73, &"uncommon", "回合结束时，完整出战骰组中每个 5 点骰面获得 1 金币。", &"round_end", [&"coins", &"pip"]),
		_make_def(TOOL_ROCKET_INCOME, "火箭收益器", "Rocket", 74, &"uncommon", "回合结束时获得 N 金币，初始 N = 1；每击败 1 场 Boss 战斗，N 永久 +2。", &"round_end_and_boss_win", [&"coins"], [], [&"rocket_income"]),
		_make_def(TOOL_OBELISK_ROTATION, "方尖轮换器", "Obelisk", 75, &"rare", "若本回合主骰型不是当前本场战斗中最常用的主骰型，轮换计数 +1；每 5 点计数使终倍率 +1。", &"on_score", [&"xmult", &"combo"], [], [&"combo_play_counts", &"obelisk_streak"]),
		_make_def(TOOL_HIGH_TO_GOLD, "高点镀金器", "Midas Mask", 76, &"uncommon", "所有被结算的高点面，在结算后变为金辉面饰。", &"on_score", [&"ornament", &"high"]),
		_make_def(TOOL_BOSS_RULE_BREAKER, "Boss 破规器", "Luchador", 77, &"uncommon", "出售此骰具时，若当前处于 Boss 战斗，禁用当前 Boss 规则。", &"on_tool_sold", [&"boss"]),
		_make_def(TOOL_FIRST_HIGH_X2, "首高摄影机", "Photograph", 78, &"common", "本回合第一个被结算的高点面，触发终倍率 ×2。", &"on_score", [&"xmult", &"high"]),
		_make_def(TOOL_SELL_VALUE_GROWTH, "礼券增值器", "Gift Card", 79, &"uncommon", "回合结束时，每个已安装骰具和每个道具槽位中的道具卖价 +1 金币。", &"round_end", [&"sell_value"]),
		_make_def(TOOL_MAX_SCORE_DECAY, "龟甲扩容器", "Turtle Bean", 80, &"uncommon", "每回合最大可结算骰面数 +N，初始 N = 5；每回合结束后 N -1，降到 0 时自毁。", &"battle_rule_and_round_end", [&"score_limit", &"decay"], [], [&"bean_bonus"]),
		_make_def(TOOL_FACE_COUNT_GAP_MULT, "缺面倍率器", "Erosion", 81, &"uncommon", "完整出战骰组当前总面数每低于本局起始总面数 1 个，+4 倍率。", &"on_score", [&"mult", &"face_count"]),
		_make_def(TOOL_HIGH_STAY_PARKING, "高点留位费", "Reserved Parking", 82, &"common", "未结算留场的每个高点面，各有 1/2 概率获得 1 金币。", &"on_score", [&"coins", &"stay", &"high"]),
		_make_def(TOOL_MAIL_PIP_REBATE, "指点返利", "Mail-In Rebate", 83, &"common", "每重投 1 个当前指定点数的骰面，获得 5 金币；指定点数在回合结束时重新随机。", &"before_reroll", [&"coins", &"reroll"], [], [&"rebate_pip"]),
		_make_def(TOOL_INTEREST_BOOSTER, "月息放大器", "To the Moon", 84, &"uncommon", "回合结束时，每拥有 5 金币，额外获得 1 金币。", &"round_end", [&"coins"]),
		_make_def(TOOL_PACK_HALLUCINATION, "开包幻觉", "Hallucination", 85, &"common", "打开任意补充包时，有 1/2 概率生成 1 个随机铸骰件；需要空道具槽位。", &"on_pack_opened", [&"generate", &"pack"]),
		_make_def(TOOL_FORGE_ITEM_ORACLE, "铸件占卜器", "Fortune Teller", 86, &"common", "本局每使用 1 个铸骰件，+1 倍率。", &"on_score", [&"mult", &"forge_item"]),
		_make_def(TOOL_SCORE_SLOT_PLUS_ONE, "结算扩位器", "Juggler", 87, &"common", "每回合最大可结算骰面数 +1。", &"battle_rule", [&"score_limit"]),
		_make_def(TOOL_REROLL_PLUS_ONE, "追加重投器", "Drunkard", 88, &"common", "每回合重投次数 +1。", &"battle_rule", [&"reroll"]),
		_make_def(TOOL_STONE_FACE_CHIPS, "石面筹码器", "Stone Joker", 89, &"uncommon", "完整出战骰组中每个石质面饰骰面，+25 基础战力。", &"on_score", [&"chips", &"stone"]),
		_make_def(TOOL_ROUND_GOLD_INCOME, "固定金币器", "Golden Joker", 90, &"common", "回合结束时获得 4 金币。", &"round_end", [&"coins"]),
		_make_def(TOOL_LUCKY_CAT_INTEGER, "幸运猫", "Lucky Cat", 91, &"uncommon", "每当幸运面饰成功触发 1 次，幸运计数 +1；每 2 点幸运计数使终倍率 +1。", &"on_lucky_success", [&"xmult", &"lucky"], [], [&"lucky_success_count"]),
		_make_def(TOOL_UNCOMMON_TEAM_XMULT, "罕见联队", "Baseball Card", 92, &"rare", "每有 2 个已安装的罕见骰具，终倍率 ×2。", &"on_score", [&"xmult", &"rarity"]),
		_make_def(TOOL_COIN_CHIPS, "金币筹码器", "Bull", 93, &"uncommon", "每拥有 1 金币，+2 基础战力。", &"on_score", [&"chips", &"coins"]),
		_make_def(TOOL_DOUBLE_REWARD_TAG, "双奖汽水", "Diet Cola", 94, &"uncommon", "出售此骰具时，获得 1 个双倍奖励标记。", &"on_tool_sold", [&"reward"]),
		_make_def(TOOL_SINGLE_REROLL_TRADE, "单投交易员", "Trading Card", 95, &"uncommon", "每回合第一次重投时，若只选择 1 个骰面重投，则该物理骰面在重投前被重置，并获得 3 金币。", &"before_reroll", [&"coins", &"reset"], [], [&"trading_used_this_round"]),
		_make_def(TOOL_SHOP_REROLL_MULT, "刷新倍率器", "Flash Card", 96, &"uncommon", "商店每刷新 1 次，本骰具永久获得 +2 倍率。", &"on_shop_rerolled", [&"mult", &"shop"], [], [&"shop_reroll_count"]),
		_make_def(TOOL_DECAY_POPCORN, "衰减爆米花", "Popcorn", 97, &"common", "初始 +20 倍率；每回合结束后，本骰具倍率 -4；降到 0 或以下时自毁。", &"on_score_and_round_end", [&"mult", &"decay"], [], [&"popcorn_mult"]),
		_make_def(TOOL_TWO_PAIR_TROUSERS, "两对长裤", "Spare Trousers", 98, &"uncommon", "若本回合有效被结算骰面中存在两对结构，本骰具永久获得 +2 倍率；计分时提供累计倍率。", &"on_score", [&"mult", &"two_pair"], [], [&"trousers_mult"]),
		_make_def(TOOL_ANCIENT_POINT_CLASS, "古老点域器", "Ancient Joker", 99, &"rare", "每回合指定奇数、偶数、低点、高点之一；被结算且符合当前分类的每个有效骰面，终倍率 ×2。", &"on_score_and_round_end", [&"xmult", &"pip_class"], [], [&"ancient_class"]),
		_make_def(TOOL_REROLL_DECAY_X2, "拉面衰减器", "Ramen", 100, &"uncommon", "初始终倍率 ×2；本局每重投 10 个骰面，本骰具终倍率降低 1，最低为 ×1。", &"on_score_and_reroll", [&"xmult", &"reroll"], [], [&"rerolled_face_count_for_ramen"]),
		_make_def(TOOL_SIX_FOUR_BROADCAST, "六四对讲器", "Walkie Talkie", 101, &"common", "每个被结算且有效点数为 6 或 4 的骰面，+10 基础战力，+4 倍率。", &"on_scored_face", [&"chips", &"mult", &"pip"]),
		_make_def(TOOL_SELTZER_RETRIGGER, "气泡重触器", "Seltzer", 102, &"uncommon", "若剩余重触回合数大于 0，当前回合所有被结算骰面额外触发 1 次；结算结束后计数 -1，降到 0 时自毁。", &"on_score_and_round_end", [&"retrigger", &"decay"], [], [&"remaining_retrigger_rounds"]),
		_make_def(TOOL_CASTLE_PIP_CLASS, "城堡点类器", "Castle", 103, &"uncommon", "每回合开始时指定奇数、偶数、低点、高点之一；重投指定类别的有效骰面时永久 +3 基础战力。", &"round_start_and_reroll", [&"chips", &"pip_class"], [], [&"castle_class", &"chips_bonus"]),
		_make_def(TOOL_HIGH_SMILE_MULT, "高点笑脸", "Smiley Face", 104, &"common", "每个被结算高点面 +5 倍率。高点面为有效点数 5 / 6 / 7 / 8。", &"on_scored_face", [&"mult", &"high"]),
		_make_def(TOOL_CAMPFIRE_SALES, "营火出售器", "Campfire", 105, &"rare", "每出售 4 个物品，本骰具终倍率 +1；结算时按累计加成提供整数终倍率；击败 Boss 后重置。", &"on_item_sold_and_score", [&"xmult", &"sell"], [], [&"sold_item_counter", &"xmult_bonus"]),
		_make_def(TOOL_GOLD_ORNAMENT_INCOME, "金辉票根", "Golden Ticket", 106, &"common", "每个被结算且带有金辉面饰的骰面，获得 4 金币。", &"on_scored_face", [&"coins", &"ornament"]),
		_make_def(TOOL_BONE_SAFETY, "保底骨架", "Mr. Bones", 107, &"uncommon", "若本场累计战力未达标但至少达到目标战力四分之一，则避免本次失败并自毁。", &"before_defeat", [&"safety"]),
		_make_def(TOOL_FINAL_ROUND_ACROBAT, "终回合杂技", "Acrobat", 108, &"uncommon", "若当前回合是本场战斗最后一回合，终倍率 ×3。", &"on_score", [&"xmult", &"final_round"]),
		_make_def(TOOL_HIGH_FACE_RETRIGGER, "高点复演", "Sock and Buskin", 109, &"uncommon", "所有被结算高点面额外触发 1 次。", &"on_scored_face", [&"retrigger", &"high"]),
		_make_def(TOOL_SELL_VALUE_SWORD, "卖价剑客", "Swashbuckler", 110, &"common", "结算时，获得等同其他所有已安装骰具卖价总和的倍率。", &"on_score", [&"mult", &"sell_value"]),
		_make_def(TOOL_TROUBADOUR_SLOTS, "吟游扩位器", "Troubadour", 111, &"uncommon", "每回合最大可结算骰面数 +2；每场战斗可结算回合数 -1，最低为 1。", &"battle_rule", [&"score_limit", &"rounds"]),
		_make_def(TOOL_MARKED_TEMP_FACE, "印记临面证", "Certificate", 112, &"uncommon", "回合开始时，向当前投骰池加入 1 个当前回合临时骰面；该骰面有随机点数和随机印记，回合结束后移除。", &"round_start", [&"temporary_face", &"mark"]),
		_make_def(TOOL_FACT_TOLERANCE, "宽容判定器", "Smeared Joker", 113, &"uncommon", "全奇、全偶、全低、全高四个事实判定允许 1 个有效被结算骰面不符合条件。", &"rule_modifier", [&"fact"]),
		_make_def(TOOL_SKIP_THROWBACK, "跳战回响", "Throwback", 114, &"uncommon", "本局每跳过 2 个战斗节点，本骰具终倍率 +1；结算时按累计加成提供整数终倍率。", &"on_score", [&"xmult", &"skip"]),
		_make_def(TOOL_FIRST_FACE_RETRIGGER, "首面重演器", "Hanging Chad", 115, &"common", "当前回合第一个被结算骰面额外触发 2 次。", &"on_scored_face", [&"retrigger"]),
		_make_def(TOOL_EVEN_COIN_GEM, "偶数粗宝石", "Rough Gem", 116, &"uncommon", "每个被结算偶数面获得 1 金币。", &"on_scored_face", [&"coins", &"even"]),
		_make_def(TOOL_ODD_BLOODSTONE, "奇数血石", "Bloodstone", 117, &"uncommon", "每个被结算奇数面有 1/2 概率提供终倍率 ×2；概率可被概率规则修正。", &"on_scored_face", [&"xmult", &"odd", &"chance"]),
		_make_def(TOOL_HIGH_ARROWHEAD, "高点箭簇", "Arrowhead", 118, &"uncommon", "每个被结算高点面 +50 基础战力。", &"on_scored_face", [&"chips", &"high"]),
		_make_def(TOOL_LOW_ONYX_AGATE, "低点玛瑙", "Onyx Agate", 119, &"uncommon", "每个被结算低点面 +7 倍率。", &"on_scored_face", [&"mult", &"low"]),
		_make_def(TOOL_BURST_BREAK_GLASS, "爆裂玻璃", "Glass Joker", 120, &"uncommon", "每有 1 个爆裂面饰实际破碎，本骰具终倍率 +1；结算时按累计加成提供整数终倍率。", &"on_burst_break_and_score", [&"xmult", &"burst"], [], [&"xmult_bonus"]),
		_make_def(TOOL_DUPLICATE_SHOWMAN, "重复艺人", "Showman", 121, &"uncommon", "骰具、铸骰件、主骰型升级件可以重复出现；只影响后续生成规则。", &"generation_rule", [&"duplicate"]),
		_make_def(TOOL_FOUR_FACT_POT, "四类花盆", "Flower Pot", 122, &"uncommon", "若当前回合至少 4 个有效被结算骰面同时存在奇数、偶数、低点、高点四类，终倍率 ×3。", &"on_score", [&"xmult", &"pip_class"]),
		_make_def(TOOL_RIGHT_COPY_BLUEPRINT, "右侧蓝图", "Blueprint", 123, &"rare", "复制右侧第 1 个可复制骰具的能力；复制类骰具不会被复制。", &"copy", [&"copy"]),
		_make_def(TOOL_TWO_PIP_WEEJOKER, "二点小丑", "Wee Joker", 124, &"rare", "每当 1 个被结算的 2 点面触发，本骰具永久 +8 基础战力；结算时提供累计基础战力。", &"on_scored_face", [&"chips", &"counter"], [], [&"chips_bonus"]),
		_make_def(TOOL_MERRY_REROLLER, "快乐重投手", "Merry Andy", 125, &"uncommon", "每回合重投次数 +3；每回合最大可结算骰面数 -1，最低为 1。", &"battle_rule", [&"reroll", &"score_limit"]),
		_make_def(TOOL_PROBABILITY_DOUBLER, "概率六面器", "Oops! All 6s", 126, &"uncommon", "所有明确写在效果里的概率翻倍，最高不超过必定成功。", &"probability_rule", [&"chance"]),
		_make_def(TOOL_IDOL_TARGET, "偶像目标器", "The Idol", 127, &"uncommon", "每回合指定 1 个目标点数和 1 个目标槽位特征；同时满足的被结算骰面终倍率 ×2。", &"round_start_and_score", [&"xmult", &"target"], [], [&"idol_pip", &"idol_feature"]),
		_make_def(TOOL_LOW_PLUS_OTHER_X2, "低点双视器", "Seeing Double", 128, &"uncommon", "若当前回合至少有 1 个低点面被结算，且至少有 1 个非低点面被结算，终倍率 ×2。", &"on_score", [&"xmult", &"low"]),
		_make_def(TOOL_BOSS_TRIGGER_BOUNTY, "Boss 触发赏金", "Matador", 129, &"uncommon", "若当前回合触发了 Boss 规则或 Boss 禁用条件，获得 8 金币；每回合最多 1 次。", &"on_boss_rule", [&"coins", &"boss"]),
		_make_def(TOOL_FOUR_REROLL_ROAD, "四点远行", "Hit the Road", 130, &"rare", "当前回合每重投 2 个 4 点面，本骰具终倍率 +1；回合结束后清空当前回合计数。", &"before_reroll_and_score", [&"xmult", &"reroll"], [], [&"current_round_rerolled_four_pip_count"]),
		_make_def(TOOL_PAIR_X2, "对子双倍器", "The Duo", 131, &"rare", "若当前回合有效被结算骰面中存在一对结构，终倍率 ×2。", &"on_score", [&"xmult", &"pair"]),
		_make_def(TOOL_THREE_KIND_X3, "三同三倍器", "The Trio", 132, &"rare", "若当前回合有效被结算骰面中存在三同结构，终倍率 ×3。", &"on_score", [&"xmult", &"three_kind"]),
		_make_def(TOOL_FOUR_KIND_X4, "四同四倍器", "The Family", 133, &"rare", "若当前回合有效被结算骰面中存在四同结构，终倍率 ×4。", &"on_score", [&"xmult", &"four_kind"]),
		_make_def(TOOL_STRAIGHT_X3, "顺子三倍器", "The Order", 134, &"rare", "若当前回合满足顺子结构，终倍率 ×3。", &"on_score", [&"xmult", &"straight"]),
		_make_def(TOOL_ALIGNED_FACT_X2, "整齐双倍器", "The Tribe", 135, &"rare", "若当前回合有效被结算骰面满足全奇、全偶、全低或全高之一，终倍率 ×2。", &"on_score", [&"xmult", &"fact"]),
		_make_def(TOOL_STUNT_CHIPS, "特技高分器", "Stuntman", 136, &"rare", "+250 基础战力；每回合最大可结算骰面数 -2，最低为 1。", &"on_score_and_rule", [&"chips", &"score_limit"]),
		_make_def(TOOL_DELAYED_CLONE_SALE, "隐形复刻器", "Invisible Joker", 137, &"rare", "安装后经过 2 个结算回合进入可复刻状态；出售时随机复制 1 个其他已安装骰具为骰具道具。", &"round_end_and_sale", [&"copy", &"dice_tool"], [], [&"rounds_held"]),
		_make_def(TOOL_LEFT_COPY_BRAINSTORM, "左侧脑暴", "Brainstorm", 138, &"rare", "复制最左侧可复制骰具的能力；复制类骰具不会被复制。", &"copy", [&"copy"]),
		_make_def(TOOL_UPGRADE_VARIETY_INCOME, "星系收益器", "Satellite", 139, &"uncommon", "回合结束时，本局每使用过 1 种不同的主骰型升级件，获得 1 金币。", &"round_end", [&"coins", &"combo_upgrade"]),
		_make_def(TOOL_FIVE_STAY_MULT, "五点留月", "Shoot the Moon", 140, &"common", "未结算留场的每个 5 点面提供 +13 倍率。", &"on_score", [&"mult", &"stay"]),
		_make_def(TOOL_MODIFIED_FACE_LICENSE, "改造执照", "Driver's License", 141, &"rare", "若当前永久骰组中至少有 16 个改造面，终倍率 ×3；改造面为有面饰或有印记的骰面。", &"on_score", [&"xmult", &"modified_face"]),
		_make_def(TOOL_BATTLE_START_FORGE_ITEM, "开战铸件师", "Cartomancer", 142, &"uncommon", "选择战斗时生成 1 个随机铸骰件，进入道具槽位。", &"on_battle_start", [&"generate", &"forge_item"]),
		_make_def(TOOL_COMBO_UPGRADE_SHOP_FREE, "星象免费器", "Astronomer", 143, &"uncommon", "商店中的所有主骰型升级件和主骰型升级包价格变为 0。", &"shop_price_rule", [&"shop", &"combo_upgrade"]),
		_make_def(TOOL_FIRST_REROLL_COMBO_UPGRADE, "焦痕升级器", "Burnt Joker", 144, &"rare", "每回合第一次重投前，根据重投前选中骰面可组成的最高主骰型，使该主骰型等级 +1。", &"before_reroll", [&"combo_level", &"reroll"], [], [&"burnt_used_this_round"]),
		_make_def(TOOL_COIN_MULT_BOOTSTRAP, "金币引导器", "Bootstraps", 145, &"uncommon", "每拥有 5 金币，+2 倍率。", &"on_score", [&"mult", &"coins"]),
		_make_def(TOOL_HIGH_PIP_TRANSFORM_X, "高点转化王", "Canio", 146, &"legendary", "每当 1 个高点面被重置或改造为非高点，本骰具终倍率 +1；结算时按累计加成提供整数终倍率。", &"on_face_changed_and_score", [&"xmult", &"high"], [], [&"high_transform_counter"]),
		_make_def(TOOL_FIVE_SIX_X2, "五六王庭", "Triboulet", 147, &"legendary", "每个被结算且有效点数为 5 或 6 的骰面，终倍率 ×2。", &"on_scored_face", [&"xmult", &"pip"]),
		_make_def(TOOL_REROLL_23_X, "二十三重投者", "Yorick", 148, &"legendary", "每累计重投 23 个骰面，本骰具终倍率 +1；结算时按累计加成提供整数终倍率。", &"after_reroll_and_score", [&"xmult", &"reroll"], [], [&"rerolled_face_counter", &"xmult_bonus"]),
		_make_def(TOOL_BOSS_DISABLE_LEGEND, "Boss 静默器", "Chicot", 149, &"legendary", "禁用所有 Boss 规则；只影响 Boss 规则读取。", &"boss_rule", [&"boss"]),
		_make_def(TOOL_SHOP_END_ITEM_COPY, "终店复刻器", "Perkeo", 150, &"legendary", "商店阶段结束时，随机复制 1 个玩家持有的铸骰件或主骰型升级件；复制物进入道具槽位。", &"shop_phase_end", [&"copy", &"item"]),
	]


static func get_catalog() -> Dictionary:
	var result := {}
	for def in get_all_defs():
		result[def.tool_id] = def
	return result


static func get_def(tool_id: StringName) -> DiceToolDef:
	var catalog := get_catalog()
	if not catalog.has(tool_id):
		return null
	return (catalog[tool_id] as DiceToolDef).clone()


static func has_tool(tool_id: StringName) -> bool:
	return ALL_IDS.has(tool_id)


static func get_all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in ALL_IDS:
		ids.append(id)
	return ids


static func display_name_for_id(tool_id: StringName) -> String:
	var def := get_def(tool_id)
	return def.display_name if def != null else str(tool_id)


static func sell_value_for_rarity(rarity: StringName) -> int:
	match rarity:
		&"legendary":
			return 60
		&"rare":
			return 32
		&"uncommon":
			return 18
		_:
			return 12


static func get_item_pool_for_rarity(rarity: StringName = &"") -> Array:
	var result := []
	for def in get_all_defs():
		if rarity != &"" and def.rarity != rarity:
			continue
		result.append({
			"id": def.tool_id,
			"name": def.display_name,
			"rarity": def.rarity,
			"sell_value": sell_value_for_rarity(def.rarity),
		})
	return result


static func _make_def(
	tool_id: StringName,
	display_name: String,
	balatro_source_name: String,
	source_index: int,
	rarity: StringName,
	effect_text: String,
	trigger_timing: StringName,
	mechanic_tags: Array = [],
	archetype_tags: Array = [],
	state_fields: Array = [],
	notes: String = ""
) -> DiceToolDef:
	var def := DiceToolDef.new()
	def.tool_id = tool_id
	def.display_name = display_name
	def.balatro_source_name = balatro_source_name
	def.source_index = source_index
	def.rarity = rarity
	def.effect_text = effect_text
	def.trigger_timing = trigger_timing
	def.implementation_status = IMPLEMENTATION_FORMAL
	def.drop_pool_reserved = DROP_POOL_TBD
	def.drop_weight_reserved = DROP_WEIGHT_TBD
	for tag in mechanic_tags:
		def.mechanic_tags.append(StringName(str(tag)))
	for tag in archetype_tags:
		def.archetype_tags.append(StringName(str(tag)))
	for field in state_fields:
		def.state_fields.append(StringName(str(field)))
	def.notes = notes
	return def
