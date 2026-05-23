extends RefCounted
class_name DiceToolService


const BattleConfig = preload("res://scripts/core/battle/BattleConfig.gd")
const BattleLogEntry = preload("res://scripts/log/BattleLogEntry.gd")
const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const LongTermUnlockService = preload("res://scripts/rules/long_term/LongTermUnlockService.gd")
const ResolutionStep = preload("res://scripts/core/scoring/ResolutionStep.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


var rng := RandomNumberGenerator.new()
var reward_generator := RewardGenerator.new()


func _init() -> void:
	rng.randomize()


func apply_rule_modifiers(context: ScoreContext) -> void:
	if context == null:
		return
	context.straight_required_count = 5
	context.straight_allow_one_gap = false
	context.all_faces_high_for_tools = false
	context.fact_tolerance_for_tools = false
	for tool in _installed_tools(context):
		match tool.tool_id:
			DiceToolCatalog.TOOL_SHORT_STRAIGHT_RULE:
				context.straight_required_count = 4
			DiceToolCatalog.TOOL_SHORTCUT_STRAIGHT:
				context.straight_allow_one_gap = true
			DiceToolCatalog.TOOL_ALL_FACES_HIGH_FOR_TOOLS:
				context.all_faces_high_for_tools = true
			DiceToolCatalog.TOOL_FACT_TOLERANCE:
				context.fact_tolerance_for_tools = true


func apply_score_tools(context: ScoreContext, result: ScoreResult, trace = null, effect_resolver = null) -> void:
	if context == null or result == null:
		return

	var tools := _installed_tools(context)
	if tools.is_empty():
		return

	var selected := context.selected_faces
	var effective_pips := effective_pips_for_rolls(selected, context)
	var has_pair := has_pair_structure(effective_pips)
	var has_three := has_three_kind_structure(effective_pips)
	var has_four := has_four_kind_structure(effective_pips)
	var has_two_pair := has_two_pair_structure(effective_pips)
	var has_straight := has_straight_structure(effective_pips, {
		"straight_required_count": context.straight_required_count,
		"straight_allow_one_gap": context.straight_allow_one_gap,
	})
	var aligned := has_aligned_fact(effective_pips, context.fact_tolerance_for_tools)
	var remaining_rerolls := _remaining_rerolls(context)
	var high_count := _count_selected_high_for_tools(context)
	var low_count := _count_selected_low(context)
	var odd_count := _count_selected_odd(context)
	var even_count := _count_selected_even(context)
	var six_count := _count_selected_pip(context, 6)
	var tool_count := tools.size()

	for index in range(tools.size()):
		var tool: DiceToolState = tools[index]
		if tool == null:
			continue
		match tool.tool_id:
			DiceToolCatalog.TOOL_BASIC_MULT:
				_add_mult(result, trace, tool, 4, "+4 倍率。")
			DiceToolCatalog.TOOL_EVEN_MULT:
				_add_mult_if_count(result, trace, tool, even_count, even_count * 3, "%d 个偶数面触发，+%d 倍率。" % [even_count, even_count * 3])
			DiceToolCatalog.TOOL_ODD_MULT:
				_add_mult_if_count(result, trace, tool, odd_count, odd_count * 3, "%d 个奇数面触发，+%d 倍率。" % [odd_count, odd_count * 3])
			DiceToolCatalog.TOOL_HIGH_PIP_MULT:
				_add_mult_if_count(result, trace, tool, high_count, high_count * 3, "%d 个高点面触发，+%d 倍率。" % [high_count, high_count * 3])
			DiceToolCatalog.TOOL_LOW_PIP_MULT:
				_add_mult_if_count(result, trace, tool, low_count, low_count * 3, "%d 个低点面触发，+%d 倍率。" % [low_count, low_count * 3])
			DiceToolCatalog.TOOL_PAIR_MULT:
				if has_pair:
					_add_mult(result, trace, tool, 8, "存在一对结构，+8 倍率。")
			DiceToolCatalog.TOOL_THREE_KIND_MULT:
				if has_three:
					_add_mult(result, trace, tool, 12, "存在三同结构，+12 倍率。")
			DiceToolCatalog.TOOL_TWO_PAIR_MULT:
				if has_two_pair:
					_add_mult(result, trace, tool, 10, "存在两对结构，+10 倍率。")
			DiceToolCatalog.TOOL_STRAIGHT_MULT:
				if has_straight:
					_add_mult(result, trace, tool, 12, "满足顺子结构，+12 倍率。")
			DiceToolCatalog.TOOL_ALIGNED_FACT_MULT:
				if aligned:
					_add_mult(result, trace, tool, 10, "满足全奇、全偶、全低或全高事实，+10 倍率。")
			DiceToolCatalog.TOOL_PAIR_CHIPS:
				if has_pair:
					_add_chips(result, trace, tool, 50, "存在一对结构，+50 基础战力。")
			DiceToolCatalog.TOOL_THREE_KIND_CHIPS:
				if has_three:
					_add_chips(result, trace, tool, 100, "存在三同结构，+100 基础战力。")
			DiceToolCatalog.TOOL_TWO_PAIR_CHIPS:
				if has_two_pair:
					_add_chips(result, trace, tool, 80, "存在两对结构，+80 基础战力。")
			DiceToolCatalog.TOOL_STRAIGHT_CHIPS:
				if has_straight:
					_add_chips(result, trace, tool, 100, "满足顺子结构，+100 基础战力。")
			DiceToolCatalog.TOOL_ALIGNED_FACT_CHIPS:
				if aligned:
					_add_chips(result, trace, tool, 80, "满足全奇、全偶、全低或全高事实，+80 基础战力。")
			DiceToolCatalog.TOOL_FEW_SCORED_MULT:
				if selected.size() <= 3:
					_add_mult(result, trace, tool, 20, "本回合结算 %d 个骰面，+20 倍率。" % [selected.size()])
			DiceToolCatalog.TOOL_EMPTY_SLOT_XMULT:
				var empty_slots := _empty_regular_tool_slots(context)
				var factor: int = max(1, empty_slots + 1)
				_multiply_xmult(result, trace, tool, factor, "空骰具槽 %d 个，终倍率 ×%d。" % [empty_slots, factor])
			DiceToolCatalog.TOOL_SHORT_STRAIGHT_RULE:
				_log_tool(result, tool, "顺子判定使用 4 个连续有效点数。")
			DiceToolCatalog.TOOL_UNSCORED_RETRIGGER:
				_apply_unscored_retrigger(context, result, trace, effect_resolver, tool)
			DiceToolCatalog.TOOL_SELL_VALUE_DAGGER:
				var bonus := _permanent_counter(tool, &"mult_bonus", 0)
				if bonus > 0:
					_add_mult(result, trace, tool, bonus, "永久累计倍率 +%d，本回合提供 +%d 倍率。" % [bonus, bonus])
			DiceToolCatalog.TOOL_REMAINING_REROLL_CHIPS:
				var chips := remaining_rerolls * 30
				if chips > 0:
					_add_chips(result, trace, tool, chips, "剩余重投次数 %d，+%d 基础战力。" % [remaining_rerolls, chips])
			DiceToolCatalog.TOOL_ZERO_REROLL_MULT:
				if remaining_rerolls == 0:
					_add_mult(result, trace, tool, 15, "剩余重投次数为 0，+15 倍率。")
			DiceToolCatalog.TOOL_SIX_ROUND_XMULT:
				_apply_six_round_xmult(context, result, trace, tool, index)
			DiceToolCatalog.TOOL_SIX_FORGE_GENERATOR:
				_apply_six_forge_generator(context, result, trace, tool)
			DiceToolCatalog.TOOL_RANDOM_MULT:
				var bonus := _randi_range(context, 0, 23)
				_add_mult(result, trace, tool, bonus, "随机结果 +%d 倍率。" % [bonus], true)
			DiceToolCatalog.TOOL_FINAL_ROUND_RETRIGGER:
				_apply_final_round_retrigger(context, result, trace, effect_resolver, tool)
			DiceToolCatalog.TOOL_LOWEST_UNSCORED_MULT:
				_apply_lowest_unscored_mult(context, result, trace, tool)
			DiceToolCatalog.TOOL_FIBONACCI_MULT:
				var count := _count_selected_pips_in(context, [1, 2, 3, 5, 8])
				_add_mult_if_count(result, trace, tool, count, count * 8, "%d 个斐波那契点数面触发，+%d 倍率。" % [count, count * 8])
			DiceToolCatalog.TOOL_STAY_ORNAMENT_XMULT:
				var stay_count := _count_faces_with_ornament(context, FaceState.ORN_STAY)
				var stay_factor := 1 + int(floor(float(stay_count) / 5.0))
				_multiply_xmult(result, trace, tool, stay_factor, "完整出战骰组中有 %d 个留场面饰骰面，终倍率 ×%d。" % [stay_count, stay_factor])
			DiceToolCatalog.TOOL_HIGH_PIP_CHIPS:
				_add_chips_if_count(result, trace, tool, high_count, high_count * 30, "%d 个高点面触发，+%d 基础战力。" % [high_count, high_count * 30])
			DiceToolCatalog.TOOL_TOOL_COUNT_MULT:
				_add_mult(result, trace, tool, tool_count * 3, "已安装骰具 %d 个，+%d 倍率。" % [tool_count, tool_count * 3])
			DiceToolCatalog.TOOL_LOW_MID_RETRIGGER:
				_apply_low_mid_retrigger(context, result, trace, effect_resolver, tool)
			DiceToolCatalog.TOOL_ALL_FACES_HIGH_FOR_TOOLS:
				_log_tool(result, tool, "非石质骰面在骰具条件判断中视为高点面，实际点数不变。")
			DiceToolCatalog.TOOL_RISKY_MULT_SELF_DESTRUCT:
				_add_mult(result, trace, tool, 15, "+15 倍率；战斗结束时检查自毁。")
			DiceToolCatalog.TOOL_EVEN_PLUS_FOUR_MULT:
				_add_mult_if_count(result, trace, tool, even_count, even_count * 4, "%d 个偶数面触发，+%d 倍率。" % [even_count, even_count * 4])
			DiceToolCatalog.TOOL_ODD_CHIPS:
				_add_chips_if_count(result, trace, tool, odd_count, odd_count * 31, "%d 个奇数面触发，+%d 基础战力。" % [odd_count, odd_count * 31])
			DiceToolCatalog.TOOL_SIX_SCHOLAR:
				if six_count > 0:
					_add_chips_mult(result, trace, tool, six_count * 20, six_count * 4, "%d 个 6 点面触发，+%d 基础战力，+%d 倍率。" % [six_count, six_count * 20, six_count * 4])
			DiceToolCatalog.TOOL_HIGH_INCOME_CHANCE:
				_apply_high_income_chance(context, result, trace, tool)
			DiceToolCatalog.TOOL_COMBO_COUNT_MULT:
				_apply_combo_count_mult(context, result, trace, tool)
			DiceToolCatalog.TOOL_NO_HIGH_STREAK_MULT:
				_apply_no_high_streak(context, result, trace, tool, index, high_count)
			DiceToolCatalog.TOOL_SPACE_COMBO_UPGRADE:
				_apply_space_combo_upgrade(context, result, tool)
			DiceToolCatalog.TOOL_STRAIGHT_RUNNER_CHIPS:
				_apply_straight_runner(context, result, trace, tool, index, has_straight)
			DiceToolCatalog.TOOL_UNSCORED_LOW_HIGH_XMULT:
				_apply_unscored_low_high_xmult(context, result, trace, tool)
			DiceToolCatalog.TOOL_DECAY_CHIPS:
				var current_chips := _permanent_counter(tool, &"current_chips_bonus", 100)
				_add_chips(result, trace, tool, current_chips, "当前基础战力加成 +%d；回合结束后衰减 5。" % [current_chips], true)
			DiceToolCatalog.TOOL_SINGLE_FACE_BLUEPRINT:
				_apply_single_face_blueprint_pending(context, result, tool)
			DiceToolCatalog.TOOL_SPLASH_SCORING:
				_apply_splash_scoring(context, result, trace, effect_resolver, tool)
			DiceToolCatalog.TOOL_LEFTOVER_CHIPS:
				_apply_leftover_chips(context, result, trace, tool)
			DiceToolCatalog.TOOL_SINGLE_SIX_REFORGE:
				_apply_single_six_reforge(context, result, tool)
			DiceToolCatalog.TOOL_STAR_COUNTER:
				var star_count := _permanent_counter(tool, &"combo_upgrade_used_count", 0)
				_multiply_xmult(result, trace, tool, 1 + int(floor(float(star_count) / 3.0)), "本局使用主骰型升级件 %d 个，终倍率 ×%d。" % [star_count, 1 + int(floor(float(star_count) / 3.0))])
			DiceToolCatalog.TOOL_TRAIL_MARKER:
				_apply_trail_marker(context, result, trace, tool, index)
			DiceToolCatalog.TOOL_GREEN_METER:
				var green_mult := _permanent_counter(tool, &"green_mult", 0)
				if green_mult > 0:
					_add_mult(result, trace, tool, green_mult, "当前绿骰计数提供 +%d 倍率。" % [green_mult])
			DiceToolCatalog.TOOL_STRAIGHT_SIX_SUPPLY:
				_apply_straight_six_supply(context, result, tool)
			DiceToolCatalog.TOOL_TARGET_COMBO_CONTRACT:
				_apply_target_combo_contract(context, result, tool)
			DiceToolCatalog.TOOL_UNSTABLE_X3:
				_multiply_xmult(result, trace, tool, 3, "计分时终倍率 ×3。")
			DiceToolCatalog.TOOL_REPEAT_COMBO_X3:
				_apply_repeat_combo_x3(context, result, trace, tool, index)
			DiceToolCatalog.TOOL_SKIP_PACK_MULT:
				var skipped_count := _permanent_counter(tool, &"skipped_pack_count", 0)
				if skipped_count > 0:
					_add_mult(result, trace, tool, skipped_count * 3, "已跳过骰包 %d 个，+%d 倍率。" % [skipped_count, skipped_count * 3])
			DiceToolCatalog.TOOL_MAD_GROWTH:
				var madness_charge := _permanent_counter(tool, &"madness_charge", 0)
				_multiply_xmult(result, trace, tool, 1 + int(floor(float(madness_charge) / 2.0)), "狂乱计数 %d，终倍率 ×%d。" % [madness_charge, 1 + int(floor(float(madness_charge) / 2.0))])
			DiceToolCatalog.TOOL_FOUR_FACE_SQUARE:
				_apply_four_face_square(context, result, trace, tool, index)
			DiceToolCatalog.TOOL_STRAIGHT_FORGE_SUPPLY:
				_apply_straight_forge_supply(context, result, tool)
			DiceToolCatalog.TOOL_ORNAMENT_VAMPIRE:
				_apply_ornament_vampire(context, result, trace, tool, index)
			DiceToolCatalog.TOOL_SHORTCUT_STRAIGHT:
				_log_tool(result, tool, "顺子判定允许缺 1 个中间点数。")
			DiceToolCatalog.TOOL_COPY_HOLOGRAM:
				var copied_count := _permanent_counter(tool, &"copied_face_count", 0)
				_multiply_xmult(result, trace, tool, 1 + int(floor(float(copied_count) / 2.0)), "复制覆盖计数 %d，终倍率 ×%d。" % [copied_count, 1 + int(floor(float(copied_count) / 2.0))])
			DiceToolCatalog.TOOL_POOR_FORGE_SUPPLY:
				_apply_poor_forge_supply(context, result, tool)
			DiceToolCatalog.TOOL_SIX_STAY_KING:
				_apply_six_stay_king(context, result, trace, tool)
			DiceToolCatalog.TOOL_OBELISK_ROTATION:
				_apply_obelisk_rotation(context, result, trace, tool, index)
			DiceToolCatalog.TOOL_HIGH_TO_GOLD:
				_apply_high_to_gold(context, result, tool)
			DiceToolCatalog.TOOL_FIRST_HIGH_X2:
				_apply_first_high_x2(context, result, trace, tool)
			DiceToolCatalog.TOOL_FACE_COUNT_GAP_MULT:
				_apply_face_count_gap_mult(context, result, trace, tool)
			DiceToolCatalog.TOOL_HIGH_STAY_PARKING:
				_apply_high_stay_parking(context, result, tool)
			DiceToolCatalog.TOOL_FORGE_ITEM_ORACLE:
				if context.run_state != null and context.run_state.used_forge_item_count > 0:
					_add_mult(result, trace, tool, context.run_state.used_forge_item_count, "本局已使用铸骰件 %d 个，+%d 倍率。" % [context.run_state.used_forge_item_count, context.run_state.used_forge_item_count])
			DiceToolCatalog.TOOL_STONE_FACE_CHIPS:
				var stone_faces := _count_faces_with_ornament(context, FaceState.ORN_STONE)
				if stone_faces > 0:
					_add_chips(result, trace, tool, stone_faces * 25, "完整出战骰组有 %d 个石质面饰骰面，+%d 基础战力。" % [stone_faces, stone_faces * 25])
			DiceToolCatalog.TOOL_LUCKY_CAT_INTEGER:
				var lucky_count := _permanent_counter(tool, &"lucky_success_count", 0)
				_multiply_xmult(result, trace, tool, 1 + int(floor(float(lucky_count) / 2.0)), "幸运计数 %d，终倍率 ×%d。" % [lucky_count, 1 + int(floor(float(lucky_count) / 2.0))])
			DiceToolCatalog.TOOL_UNCOMMON_TEAM_XMULT:
				_apply_uncommon_team_xmult(context, result, trace, tool)
			DiceToolCatalog.TOOL_COIN_CHIPS:
				if context.run_state != null and context.run_state.coins > 0:
					_add_chips(result, trace, tool, context.run_state.coins * 2, "当前金币 %d，+%d 基础战力。" % [context.run_state.coins, context.run_state.coins * 2])
			DiceToolCatalog.TOOL_SHOP_REROLL_MULT:
				var shop_rerolls := _permanent_counter(tool, &"shop_reroll_count", 0)
				if shop_rerolls > 0:
					_add_mult(result, trace, tool, shop_rerolls * 2, "骰商铺刷新计数 %d，+%d 倍率。" % [shop_rerolls, shop_rerolls * 2])
			DiceToolCatalog.TOOL_DECAY_POPCORN:
				var popcorn_mult := _permanent_counter(tool, &"popcorn_mult", 20)
				if popcorn_mult > 0:
					_add_mult(result, trace, tool, popcorn_mult, "当前爆米花倍率 +%d。" % [popcorn_mult])
			DiceToolCatalog.TOOL_TWO_PAIR_TROUSERS:
				_apply_two_pair_trousers(context, result, trace, tool, index, has_two_pair)
			DiceToolCatalog.TOOL_ANCIENT_POINT_CLASS:
				_apply_ancient_point_class(context, result, trace, tool)
			DiceToolCatalog.TOOL_REROLL_DECAY_X2:
				var ramen_count := _permanent_counter(tool, &"rerolled_face_count_for_ramen", 0)
				var ramen_factor: int = max(1, 2 - int(floor(float(ramen_count) / 10.0)))
				_multiply_xmult(result, trace, tool, ramen_factor, "本局已重投骰面 %d 个，终倍率 ×%d。" % [ramen_count, ramen_factor])
			DiceToolCatalog.TOOL_SELTZER_RETRIGGER:
				_apply_seltzer_retrigger(context, result, trace, effect_resolver, tool)
			DiceToolCatalog.TOOL_CASTLE_PIP_CLASS:
				var castle_chips := _permanent_counter(tool, &"chips_bonus", 0)
				if castle_chips > 0:
					_add_chips(result, trace, tool, castle_chips, "累计城堡基础战力 +%d。" % [castle_chips])
			DiceToolCatalog.TOOL_CAMPFIRE_SALES:
				_apply_counter_xmult(context, result, trace, tool, &"xmult_bonus", "出售计数形成的终倍率加成")
			DiceToolCatalog.TOOL_FINAL_ROUND_ACROBAT:
				if _is_final_round(context):
					_multiply_xmult(result, trace, tool, 3, "当前回合是最后一回合，终倍率 ×3。")
			DiceToolCatalog.TOOL_HIGH_FACE_RETRIGGER:
				_apply_high_face_retrigger(context, result, trace, effect_resolver, tool)
			DiceToolCatalog.TOOL_SELL_VALUE_SWORD:
				_apply_sell_value_sword(context, result, trace, tool)
			DiceToolCatalog.TOOL_FACT_TOLERANCE:
				_log_tool(result, tool, "全奇、全偶、全低、全高事实允许 1 个有效骰面不符合。")
			DiceToolCatalog.TOOL_IDOL_TARGET:
				_apply_idol_target(context, result, trace, tool)
			DiceToolCatalog.TOOL_LOW_PLUS_OTHER_X2:
				_apply_low_plus_other_x2(context, result, trace, tool)
			DiceToolCatalog.TOOL_BOSS_TRIGGER_BOUNTY:
				_apply_boss_trigger_bounty(context, result, tool)
			DiceToolCatalog.TOOL_SKIP_THROWBACK:
				if context.run_state != null:
					var skip_bonus := int(floor(float(context.run_state.skipped_battle_node_count) / 2.0))
					_multiply_xmult(result, trace, tool, 1 + skip_bonus, "本局跳过战斗节点 %d 个，终倍率 ×%d。" % [context.run_state.skipped_battle_node_count, 1 + skip_bonus])
			DiceToolCatalog.TOOL_FIRST_FACE_RETRIGGER:
				_apply_first_face_retrigger(context, result, trace, effect_resolver, tool)
			DiceToolCatalog.TOOL_BURST_BREAK_GLASS:
				_apply_counter_xmult(context, result, trace, tool, &"xmult_bonus", "爆裂破碎累计")
			DiceToolCatalog.TOOL_FOUR_FACT_POT:
				_apply_four_fact_pot(context, result, trace, tool)
			DiceToolCatalog.TOOL_FOUR_REROLL_ROAD:
				var road_count := context.battle_state.current_round_rerolled_four_pip_count if context.battle_state != null else 0
				var road_bonus := int(floor(float(road_count) / 2.0))
				if road_bonus > 0:
					_multiply_xmult(result, trace, tool, 1 + road_bonus, "本回合已重投 %d 个 4 点面，终倍率 ×%d。" % [road_count, 1 + road_bonus])
			DiceToolCatalog.TOOL_RIGHT_COPY_BLUEPRINT:
				_apply_copy_tool_score(context, result, trace, effect_resolver, tool, index, &"right")
			DiceToolCatalog.TOOL_TWO_PIP_WEEJOKER:
				var wee_chips := _permanent_counter(tool, &"chips_bonus", 0)
				if wee_chips > 0:
					_add_chips(result, trace, tool, wee_chips, "累计 2 点基础战力 +%d。" % [wee_chips])
			DiceToolCatalog.TOOL_PAIR_X2:
				if has_pair:
					_multiply_xmult(result, trace, tool, 2, "存在一对结构，终倍率 ×2。")
			DiceToolCatalog.TOOL_THREE_KIND_X3:
				if has_three:
					_multiply_xmult(result, trace, tool, 3, "存在三同结构，终倍率 ×3。")
			DiceToolCatalog.TOOL_FOUR_KIND_X4:
				if has_four:
					_multiply_xmult(result, trace, tool, 4, "存在四同结构，终倍率 ×4。")
			DiceToolCatalog.TOOL_STRAIGHT_X3:
				if has_straight:
					_multiply_xmult(result, trace, tool, 3, "满足顺子结构，终倍率 ×3。")
			DiceToolCatalog.TOOL_ALIGNED_FACT_X2:
				if aligned:
					_multiply_xmult(result, trace, tool, 2, "满足全奇、全偶、全低或全高事实，终倍率 ×2。")
			DiceToolCatalog.TOOL_STUNT_CHIPS:
				_add_chips(result, trace, tool, 250, "+250 基础战力。")
			DiceToolCatalog.TOOL_LEFT_COPY_BRAINSTORM:
				_apply_copy_tool_score(context, result, trace, effect_resolver, tool, index, &"left")
			DiceToolCatalog.TOOL_FIVE_STAY_MULT:
				_apply_five_stay_mult(context, result, trace, tool)
			DiceToolCatalog.TOOL_MODIFIED_FACE_LICENSE:
				_apply_modified_face_license(context, result, trace, tool)
			DiceToolCatalog.TOOL_COIN_MULT_BOOTSTRAP:
				if context.run_state != null:
					var coin_mult := int(floor(float(context.run_state.coins) / 5.0)) * 2
					if coin_mult > 0:
						_add_mult(result, trace, tool, coin_mult, "当前金币 %d，每 5 金币 +2 倍率，共 +%d 倍率。" % [context.run_state.coins, coin_mult])
			DiceToolCatalog.TOOL_HIGH_PIP_TRANSFORM_X:
				_apply_counter_xmult(context, result, trace, tool, &"high_transform_counter", "高点转化累计")
			DiceToolCatalog.TOOL_REROLL_23_X:
				_apply_counter_xmult(context, result, trace, tool, &"xmult_bonus", "二十三重投累计")
			_:
				pass


func apply_round_end_effects(context: ScoreContext, result: ScoreResult) -> void:
	if context == null or result == null or context.run_state == null:
		return
	var tools := _installed_tools(context)
	if tools.is_empty():
		return

	var remaining_rerolls := _remaining_rerolls(context)
	for index in range(tools.size()):
		var tool: DiceToolState = tools[index]
		if tool == null:
			continue
		match tool.tool_id:
			DiceToolCatalog.TOOL_NO_REROLL_INCOME:
				if _rerolls_used(context) == 0:
					var coins := remaining_rerolls * 2
					if coins > 0:
						_add_coins(context, result, coins)
						_log_tool(result, tool, "本回合没有使用重投，剩余重投次数 %d，+%d 金币。" % [remaining_rerolls, coins])
			DiceToolCatalog.TOOL_GROWING_SELL_VALUE:
				tool.sell_value += 3
				_log_tool(result, tool, "回合结束，卖价 +3，当前卖价 %d 金币。" % [tool.sell_value])
			DiceToolCatalog.TOOL_DECAY_CHIPS:
				var current := _permanent_counter(tool, &"current_chips_bonus", 100)
				var next_value: int = max(0, current - 5)
				tool.permanent_counters["current_chips_bonus"] = next_value
				_log_tool(result, tool, "回合结束，基础战力加成从 %d 降至 %d。" % [current, next_value])
			DiceToolCatalog.TOOL_GREEN_METER:
				var green_next := _permanent_counter(tool, &"green_mult", 0) + 1
				tool.permanent_counters["green_mult"] = green_next
				_log_tool(result, tool, "完成 1 次结算，绿骰计数 +1，当前 +%d 倍率。" % [green_next])
			DiceToolCatalog.TOOL_TARGET_COMBO_CONTRACT:
				var target_combo := _random_combo_id(context.run_state)
				tool.permanent_counters["target_combo_id"] = target_combo
				_log_tool(result, tool, "回合结束，新的委托主骰型为「%s」。" % [DisplayNames.combo_name(target_combo)])
			DiceToolCatalog.TOOL_FIVE_FACE_INCOME:
				var five_count := _count_permanent_pip_faces(context.run_state, 5)
				if five_count > 0:
					_add_coins(context, result, five_count)
					_log_tool(result, tool, "完整出战骰组有 %d 个 5 点骰面，+%d 金币。" % [five_count, five_count])
			DiceToolCatalog.TOOL_ROCKET_INCOME:
				var rocket_income := _permanent_counter(tool, &"rocket_income", 1)
				_add_coins(context, result, rocket_income)
				_log_tool(result, tool, "回合结束，获得 %d 金币。" % [rocket_income])
			DiceToolCatalog.TOOL_SELL_VALUE_GROWTH:
				_apply_sell_value_growth(context, result, tool)
			DiceToolCatalog.TOOL_MAX_SCORE_DECAY:
				var bean_bonus := _permanent_counter(tool, &"bean_bonus", 5)
				var bean_next: int = max(0, bean_bonus - 1)
				tool.permanent_counters["bean_bonus"] = bean_next
				if context.battle_state != null:
					context.battle_state.config.max_scored_faces_per_round = max(1, context.battle_state.config.max_scored_faces_per_round - 1)
					context.battle_state.config.max_selected_dice = context.battle_state.config.max_scored_faces_per_round
				_log_tool(result, tool, "回合结束，最大可结算骰面数加成从 %d 降至 %d。" % [bean_bonus, bean_next])
				if bean_next <= 0:
					_destroy_tool(context.run_state, tool, result, "加成降到 0，自毁。")
			DiceToolCatalog.TOOL_MAIL_PIP_REBATE:
				var rebate_pip := _random_legal_pip(context.run_state)
				tool.permanent_counters["rebate_pip"] = rebate_pip
				_log_tool(result, tool, "回合结束，新的指定点数为 %d。" % [rebate_pip])
			DiceToolCatalog.TOOL_INTEREST_BOOSTER:
				var interest := int(floor(float(context.run_state.coins) / 5.0))
				if interest > 0:
					_add_coins(context, result, interest)
					_log_tool(result, tool, "当前金币 %d，每 5 金币额外获得 1 金币，+%d 金币。" % [context.run_state.coins, interest])
			DiceToolCatalog.TOOL_ROUND_GOLD_INCOME:
				_add_coins(context, result, 4)
				_log_tool(result, tool, "回合结束，+4 金币。")
			DiceToolCatalog.TOOL_DECAY_POPCORN:
				var popcorn_current := _permanent_counter(tool, &"popcorn_mult", 20)
				var popcorn_next := popcorn_current - 4
				tool.permanent_counters["popcorn_mult"] = popcorn_next
				_log_tool(result, tool, "回合结束，爆米花倍率从 %d 降至 %d。" % [popcorn_current, max(0, popcorn_next)])
				if popcorn_next <= 0:
					_destroy_tool(context.run_state, tool, result, "倍率降到 0，自毁。")
			DiceToolCatalog.TOOL_ANCIENT_POINT_CLASS:
				var ancient_class := _random_ancient_class(context.run_state)
				tool.permanent_counters["ancient_class"] = ancient_class
				_log_tool(result, tool, "回合结束，新的指定分类为「%s」。" % [_ancient_class_name(ancient_class)])
			DiceToolCatalog.TOOL_SELTZER_RETRIGGER:
				var remaining := _permanent_counter(tool, &"remaining_retrigger_rounds", 10)
				if remaining > 0:
					var next_remaining: int = max(0, remaining - 1)
					tool.permanent_counters["remaining_retrigger_rounds"] = next_remaining
					_log_tool(result, tool, "回合结束，剩余重触回合数从 %d 降至 %d。" % [remaining, next_remaining])
					if next_remaining <= 0:
						_destroy_tool(context.run_state, tool, result, "剩余重触回合数降为 0，自毁。")
			DiceToolCatalog.TOOL_CAMPFIRE_SALES:
				if _battle_was_boss_victory(context.run_state):
					tool.permanent_counters["sold_item_counter"] = 0
					tool.permanent_counters["xmult_bonus"] = 0
					_log_tool(result, tool, "击败 Boss 后，出售计数和终倍率加成已清空。")
			DiceToolCatalog.TOOL_FOUR_REROLL_ROAD:
				if context.battle_state != null:
					context.battle_state.current_round_rerolled_four_pip_count = 0
					_log_tool(result, tool, "回合结束，当前回合 4 点重投计数清空。")
			DiceToolCatalog.TOOL_DELAYED_CLONE_SALE:
				var held_rounds := _permanent_counter(tool, &"rounds_held", 0) + 1
				tool.permanent_counters["rounds_held"] = held_rounds
				_log_tool(result, tool, "已持有并完成 %d 个结算回合。" % [held_rounds])
			DiceToolCatalog.TOOL_UPGRADE_VARIETY_INCOME:
				var variety := context.run_state.used_combo_upgrade_item_ids.size()
				if variety > 0:
					_add_coins(context, result, variety)
					_log_tool(result, tool, "本局使用过 %d 种主骰型升级件，+%d 金币。" % [variety, variety])
			_:
				pass
	if context.battle_state != null:
		context.battle_state.temporary_faces.clear()
		context.battle_state.boss_rule_triggered_this_round = false
	if context.hand_state != null:
		var kept_rolls: Array[RolledFace] = []
		for roll in context.hand_state.rolled_faces:
			if roll != null and roll.is_temporary:
				continue
			kept_rolls.append(roll)
		context.hand_state.rolled_faces = kept_rolls


func apply_battle_start_effects(run_state, config: BattleConfig = null) -> Array[String]:
	var logs: Array[String] = []
	if run_state == null:
		return logs
	var tools := _tools_for_run(run_state)
	for tool in tools:
		if tool != null:
			tool.combat_counters.clear()

	var index := 0
	while index < tools.size():
		var tool: DiceToolState = tools[index]
		if tool == null:
			index += 1
			continue
		match tool.tool_id:
			DiceToolCatalog.TOOL_SELL_VALUE_DAGGER:
				if index + 1 < tools.size():
					var destroyed: DiceToolState = tools[index + 1]
					if destroyed != null:
						var gain: int = max(0, destroyed.sell_value) * 2
						tool.permanent_counters["mult_bonus"] = _permanent_counter(tool, &"mult_bonus", 0) + gain
						logs.append("[骰具] %s：摧毁右侧相邻骰具 %s，永久倍率 +%d。" % [_tool_name(tool), _tool_name(destroyed), gain])
					tools.remove_at(index + 1)
					run_state.installed_tools = tools
			DiceToolCatalog.TOOL_STONE_SEED:
				if _apply_stone_seed(run_state):
					logs.append("[骰具] %s：随机 1 个现有骰面替换为石质面饰。" % [_tool_name(tool)])
			DiceToolCatalog.TOOL_ROUNDS_FOR_NO_REROLL:
				if config != null:
					config.hands_per_battle += 3
					config.rerolls_per_hand = 0
					logs.append("[骰具] %s：本场结算回合数 +3，重投次数上限设为 0。" % [_tool_name(tool)])
			DiceToolCatalog.TOOL_TARGET_COMBO_CONTRACT:
				if not tool.permanent_counters.has(&"target_combo_id"):
					var target_combo := _random_combo_id_for_run(run_state)
					tool.permanent_counters["target_combo_id"] = target_combo
					logs.append("[骰具] %s：当前委托主骰型为「%s」。" % [_tool_name(tool), DisplayNames.combo_name(target_combo)])
			DiceToolCatalog.TOOL_MAD_GROWTH:
				if config == null or not config.is_boss_battle:
					var madness_next := _permanent_counter(tool, &"madness_charge", 0) + 1
					tool.permanent_counters["madness_charge"] = madness_next
					var destroyed_name := _destroy_random_other_tool(run_state, tool)
					if destroyed_name != "":
						logs.append("[骰具] %s：狂乱计数 +1 至 %d，随机摧毁 %s。" % [_tool_name(tool), madness_next, destroyed_name])
					else:
						logs.append("[骰具] %s：狂乱计数 +1 至 %d，没有其他骰具可摧毁。" % [_tool_name(tool), madness_next])
			DiceToolCatalog.TOOL_COMMON_TOOL_SUPPLY:
				var generated := _generate_common_tool_items(run_state, 2)
				if generated.is_empty():
					logs.append("[骰具] %s：道具槽位不足。" % [_tool_name(tool)])
				else:
					logs.append("[骰具] %s：生成普通骰具道具：%s。" % [_tool_name(tool), DisplayNames.join_names(generated)])
			DiceToolCatalog.TOOL_MAX_SCORE_DECAY:
				if not tool.permanent_counters.has(&"bean_bonus"):
					tool.permanent_counters["bean_bonus"] = 5
				if config != null:
					var bean_bonus := _permanent_counter(tool, &"bean_bonus", 5)
					config.max_scored_faces_per_round += bean_bonus
					config.max_selected_dice = config.max_scored_faces_per_round
					logs.append("[骰具] %s：每回合最大可结算骰面数 +%d。" % [_tool_name(tool), bean_bonus])
			DiceToolCatalog.TOOL_MAIL_PIP_REBATE:
				if not tool.permanent_counters.has(&"rebate_pip"):
					var rebate_pip := _random_legal_pip_for_run(run_state)
					tool.permanent_counters["rebate_pip"] = rebate_pip
					logs.append("[骰具] %s：当前指定点数为 %d。" % [_tool_name(tool), rebate_pip])
			DiceToolCatalog.TOOL_ANCIENT_POINT_CLASS:
				if not tool.permanent_counters.has(&"ancient_class"):
					var ancient_class := _random_ancient_class_for_run(run_state)
					tool.permanent_counters["ancient_class"] = ancient_class
					logs.append("[骰具] %s：当前指定分类为「%s」。" % [_tool_name(tool), _ancient_class_name(ancient_class)])
			DiceToolCatalog.TOOL_SCORE_SLOT_PLUS_ONE:
				if config != null:
					config.max_scored_faces_per_round += 1
					config.max_selected_dice = config.max_scored_faces_per_round
					logs.append("[骰具] %s：每回合最大可结算骰面数 +1。" % [_tool_name(tool)])
			DiceToolCatalog.TOOL_REROLL_PLUS_ONE:
				if config != null:
					config.rerolls_per_hand += 1
					logs.append("[骰具] %s：每回合重投次数 +1。" % [_tool_name(tool)])
			DiceToolCatalog.TOOL_SELTZER_RETRIGGER:
				if not tool.permanent_counters.has(&"remaining_retrigger_rounds"):
					tool.permanent_counters["remaining_retrigger_rounds"] = 10
					logs.append("[骰具] %s：剩余重触回合数初始化为 10。" % [_tool_name(tool)])
			DiceToolCatalog.TOOL_TROUBADOUR_SLOTS:
				if config != null:
					config.max_scored_faces_per_round = max(1, config.max_scored_faces_per_round + 2)
					config.max_selected_dice = config.max_scored_faces_per_round
					config.hands_per_battle = max(1, config.hands_per_battle - 1)
					logs.append("[骰具] %s：最大可结算骰面数 +2，可结算回合数 -1。" % [_tool_name(tool)])
			DiceToolCatalog.TOOL_MERRY_REROLLER:
				if config != null:
					config.rerolls_per_hand += 3
					config.max_scored_faces_per_round = max(1, config.max_scored_faces_per_round - 1)
					config.max_selected_dice = config.max_scored_faces_per_round
					logs.append("[骰具] %s：每回合重投次数 +3，最大可结算骰面数 -1。" % [_tool_name(tool)])
			DiceToolCatalog.TOOL_STUNT_CHIPS:
				if config != null:
					config.max_scored_faces_per_round = max(1, config.max_scored_faces_per_round - 2)
					config.max_selected_dice = config.max_scored_faces_per_round
					logs.append("[骰具] %s：最大可结算骰面数 -2。" % [_tool_name(tool)])
			DiceToolCatalog.TOOL_BATTLE_START_FORGE_ITEM:
				var item_id := reward_generator.roll_random_formal_forge_item()
				if run_state.get_free_item_slot_count() <= 0 or item_id == &"":
					logs.append("[骰具] %s：道具槽位不足。" % [_tool_name(tool)])
				elif run_state.add_item_to_inventory_or_pending(item_id):
					logs.append("[骰具] %s：生成 %s。" % [_tool_name(tool), ForgeItemCatalog.display_name_for_id(item_id)])
			DiceToolCatalog.TOOL_BOSS_DISABLE_LEGEND:
				if config != null and config.is_boss_battle:
					logs.append("[骰具] %s：本场 Boss 规则已禁用。" % [_tool_name(tool)])
			_:
				pass
		index += 1
	return logs


func apply_battle_end_effects(run_state, result: ScoreResult = null) -> Array[String]:
	var logs: Array[String] = []
	if run_state == null:
		return logs
	var tools := _tools_for_run(run_state)
	var index := tools.size() - 1
	while index >= 0:
		var tool: DiceToolState = tools[index]
		if tool != null and tool.tool_id == DiceToolCatalog.TOOL_RISKY_MULT_SELF_DESTRUCT:
			if _randf(null) < (1.0 / 6.0):
				logs.append("[骰具] %s：战斗结束检查失败，自毁。" % [_tool_name(tool)])
				if result != null:
					_log_tool(result, tool, "战斗结束检查失败，自毁。")
				tools.remove_at(index)
			else:
				logs.append("[骰具] %s：战斗结束检查通过，未自毁。" % [_tool_name(tool)])
				if result != null:
					_log_tool(result, tool, "战斗结束检查通过，未自毁。")
		elif tool != null and tool.tool_id == DiceToolCatalog.TOOL_UNSTABLE_X3:
			if _randf(null) < (1.0 / 1000.0):
				logs.append("[骰具] %s：不稳定三倍器自毁。" % [_tool_name(tool)])
				if result != null:
					_log_tool(result, tool, "不稳定三倍器自毁。")
				tools.remove_at(index)
			elif result != null:
				_log_tool(result, tool, "战斗结束检查通过，未自毁。")
		elif tool != null and tool.tool_id == DiceToolCatalog.TOOL_ROCKET_INCOME:
			if result != null and result.final_score >= 0 and _battle_was_boss_victory(run_state):
				var rocket_next := _permanent_counter(tool, &"rocket_income", 1) + 2
				tool.permanent_counters["rocket_income"] = rocket_next
				logs.append("[骰具] %s：击败 Boss 战斗，回合结束收益提高到 %d。" % [_tool_name(tool), rocket_next])
				_log_tool(result, tool, "击败 Boss 战斗，回合结束收益提高到 %d。" % [rocket_next])
		elif tool != null and tool.tool_id == DiceToolCatalog.TOOL_CAMPFIRE_SALES:
			if _battle_was_boss_victory(run_state):
				tool.permanent_counters["sold_item_counter"] = 0
				tool.permanent_counters["xmult_bonus"] = 0
				logs.append("[骰具] %s：击败 Boss 后，出售计数和终倍率加成已清空。" % [_tool_name(tool)])
				if result != null:
					_log_tool(result, tool, "击败 Boss 后，出售计数和终倍率加成已清空。")
		index -= 1
	run_state.installed_tools = tools
	return logs


func apply_shop_open_effects(run_state, shop_state) -> void:
	if run_state == null or shop_state == null:
		return
	for tool in _tools_for_run(run_state):
		if tool != null and tool.tool_id == DiceToolCatalog.TOOL_FREE_SHOP_REROLL:
			if shop_state is Dictionary:
				shop_state["free_rerolls"] = int(shop_state.get("free_rerolls", 0)) + 1
			elif shop_state is Object:
				shop_state.set("free_rerolls", int(shop_state.get("free_rerolls")) + 1)


func apply_round_start_effects(run_state, battle_state = null, hand_state = null) -> Array[String]:
	var logs: Array[String] = []
	if battle_state != null:
		battle_state.boss_rule_triggered_this_round = false
		battle_state.current_round_rerolled_face_count = 0
		battle_state.current_round_rerolled_four_pip_count = 0
		battle_state.temporary_faces.clear()
	for tool in _tools_for_run(run_state):
		if tool == null:
			continue
		tool.runtime_counters["boss_bounty_paid_this_round"] = false
		match tool.tool_id:
			DiceToolCatalog.TOOL_SINGLE_REROLL_TRADE:
				tool.combat_counters["trading_used_this_round"] = false
			DiceToolCatalog.TOOL_FIRST_REROLL_COMBO_UPGRADE:
				tool.combat_counters["burnt_used_this_round"] = false
			DiceToolCatalog.TOOL_CASTLE_PIP_CLASS:
				var castle_class := _random_ancient_class_for_run(run_state)
				tool.combat_counters["castle_class"] = castle_class
				logs.append("[骰具] %s：本回合指定点数类别为「%s」。" % [_tool_name(tool), _ancient_class_name(castle_class)])
			DiceToolCatalog.TOOL_IDOL_TARGET:
				var target := _random_idol_target(run_state)
				tool.combat_counters["idol_pip"] = int(target.get("pip", 0))
				tool.combat_counters["idol_feature"] = StringName(str(target.get("feature", &"")))
				if int(target.get("pip", 0)) > 0 and StringName(str(target.get("feature", &""))) != &"":
					logs.append("[骰具] %s：本回合目标为 %d 点和「%s」。" % [_tool_name(tool), int(target.get("pip", 0)), _slot_feature_name(StringName(str(target.get("feature", &""))))])
				else:
					logs.append("[骰具] %s：当前永久骰组没有可指定的非空槽位特征，本回合不触发。" % [_tool_name(tool)])
			DiceToolCatalog.TOOL_MARKED_TEMP_FACE:
				if hand_state != null:
					var temp_roll := _make_marked_temp_face(hand_state.rolled_faces.size())
					hand_state.rolled_faces.append(temp_roll)
					if battle_state != null:
						battle_state.temporary_faces.append(temp_roll)
					logs.append("[骰具] %s：加入 1 个当前回合临时骰面，点数 %d，印记「%s」。" % [_tool_name(tool), temp_roll.face.pip, _slot_feature_name(temp_roll.face.mark_id)])
			_:
				pass
	return logs


func apply_reroll_before_effects(run_state, selected_rolls: Array, hand_state = null, battle_state = null) -> Array[String]:
	var logs: Array[String] = []
	if run_state == null or selected_rolls.is_empty():
		return logs
	var high_count := _count_high_rolls_for_reroll(run_state, selected_rolls)
	for tool in _tools_for_run(run_state):
		if tool == null:
			continue
		match tool.tool_id:
			DiceToolCatalog.TOOL_HIGH_REROLL_BOUNTY:
				if high_count >= 3:
					run_state.add_coins(5, tool.tool_id)
					logs.append("[骰具] %s：本次重投选择 %d 个高点面，+5 金币。" % [_tool_name(tool), high_count])
			DiceToolCatalog.TOOL_MAIL_PIP_REBATE:
				var target_pip := _permanent_counter(tool, &"rebate_pip", 0)
				if target_pip <= 0:
					target_pip = _random_legal_pip_for_run(run_state)
					tool.permanent_counters["rebate_pip"] = target_pip
				var match_count := 0
				for roll in selected_rolls:
					if roll != null and roll.face != null and roll.face.pip == target_pip:
						match_count += 1
				if match_count > 0:
					var gain := match_count * 5
					run_state.add_coins(gain, tool.tool_id)
					logs.append("[骰具] %s：重投 %d 个指定点数 %d 的骰面，+%d 金币。" % [_tool_name(tool), match_count, target_pip, gain])
			DiceToolCatalog.TOOL_SINGLE_REROLL_TRADE:
				if bool(tool.combat_counters.get("trading_used_this_round", false)):
					continue
				tool.combat_counters["trading_used_this_round"] = true
				if selected_rolls.size() == 1:
					var roll: RolledFace = selected_rolls[0]
					if _reset_physical_face_for_roll(run_state, roll):
						run_state.add_coins(3, tool.tool_id)
						logs.append("[骰具] %s：第一次重投只选择 1 个骰面，重置该物理骰面并 +3 金币。" % [_tool_name(tool)])
				else:
					logs.append("[骰具] %s：第一次重投选择多个骰面，本回合机会已消耗。" % [_tool_name(tool)])
			DiceToolCatalog.TOOL_CASTLE_PIP_CLASS:
				var castle_class := StringName(str(tool.combat_counters.get("castle_class", &"")))
				if castle_class == &"":
					castle_class = _random_ancient_class_for_run(run_state)
					tool.combat_counters["castle_class"] = castle_class
				var class_count := _count_reroll_pip_class(selected_rolls, castle_class)
				if class_count > 0:
					var next_chips := _permanent_counter(tool, &"chips_bonus", 0) + class_count * 3
					tool.permanent_counters["chips_bonus"] = next_chips
					logs.append("[骰具] %s：重投 %d 个「%s」骰面，累计基础战力 +%d 至 %d。" % [_tool_name(tool), class_count, _ancient_class_name(castle_class), class_count * 3, next_chips])
			DiceToolCatalog.TOOL_FOUR_REROLL_ROAD:
				var four_count := _count_reroll_pip(selected_rolls, 4)
				if four_count > 0 and battle_state != null:
					battle_state.current_round_rerolled_four_pip_count += four_count
					logs.append("[骰具] %s：本次重投 %d 个 4 点面，本回合累计 %d 个。" % [_tool_name(tool), four_count, battle_state.current_round_rerolled_four_pip_count])
			DiceToolCatalog.TOOL_FIRST_REROLL_COMBO_UPGRADE:
				if bool(tool.combat_counters.get("burnt_used_this_round", false)):
					continue
				tool.combat_counters["burnt_used_this_round"] = true
				var combo_id := _highest_combo_for_rolls(run_state, selected_rolls)
				if ComboUpgradeCatalog.has_combo(combo_id) and run_state.increase_combo_level(combo_id, 1):
					logs.append("[骰具] %s：第一次重投前，升级主骰型「%s」+1。" % [_tool_name(tool), DisplayNames.combo_name(combo_id)])
			_:
				pass
	return logs


func apply_reroll_after_effects(run_state, selected_rolls_or_count, battle_state = null) -> Array[String]:
	var logs: Array[String] = []
	var rerolled_face_count: int = selected_rolls_or_count.size() if selected_rolls_or_count is Array else int(selected_rolls_or_count)
	if run_state == null or rerolled_face_count <= 0:
		return logs
	if battle_state != null:
		battle_state.current_round_rerolled_face_count += rerolled_face_count
	for tool in _tools_for_run(run_state):
		if tool == null:
			continue
		match tool.tool_id:
			DiceToolCatalog.TOOL_GREEN_METER:
				var green_next: int = max(0, _permanent_counter(tool, &"green_mult", 0) - 1)
				tool.permanent_counters["green_mult"] = green_next
				logs.append("[骰具] %s：使用 1 次重投，绿骰计数降至 %d。" % [_tool_name(tool), green_next])
			DiceToolCatalog.TOOL_REROLL_DECAY_X2:
				var ramen_next: int = _permanent_counter(tool, &"rerolled_face_count_for_ramen", 0) + rerolled_face_count
				tool.permanent_counters["rerolled_face_count_for_ramen"] = ramen_next
				logs.append("[骰具] %s：本局重投骰面计数增加到 %d。" % [_tool_name(tool), ramen_next])
			DiceToolCatalog.TOOL_REROLL_23_X:
				var reroll_counter: int = _permanent_counter(tool, &"rerolled_face_counter", 0) + rerolled_face_count
				var xbonus: int = _permanent_counter(tool, &"xmult_bonus", 0)
				while reroll_counter >= 23:
					reroll_counter -= 23
					xbonus += 1
				tool.permanent_counters["rerolled_face_counter"] = reroll_counter
				tool.permanent_counters["xmult_bonus"] = xbonus
				logs.append("[骰具] %s：累计重投计数剩余 %d，终倍率加成 %d。" % [_tool_name(tool), reroll_counter, xbonus])
			_:
				pass
	return logs


func on_booster_pack_skipped(run_state, pack_id: StringName = &"") -> Array[String]:
	var logs: Array[String] = []
	for tool in _tools_for_run(run_state):
		if tool != null and tool.tool_id == DiceToolCatalog.TOOL_SKIP_PACK_MULT:
			var next_value := _permanent_counter(tool, &"skipped_pack_count", 0) + 1
			tool.permanent_counters["skipped_pack_count"] = next_value
			logs.append("[骰具] %s：跳过骰包，跳包计数 +1 至 %d。" % [_tool_name(tool), next_value])
	return logs


func on_booster_pack_opened(run_state, pack_id: StringName = &"") -> Array[String]:
	var logs: Array[String] = []
	for tool in _tools_for_run(run_state):
		if tool == null or tool.tool_id != DiceToolCatalog.TOOL_PACK_HALLUCINATION:
			continue
		if _randf(null) >= 0.5:
			logs.append("[骰具] %s：开包幻觉判定未成功。" % [_tool_name(tool)])
			continue
		if run_state.get_free_item_slot_count() <= 0:
			logs.append("[骰具] %s：道具槽位不足。" % [_tool_name(tool)])
			continue
		var item_id := reward_generator.roll_random_formal_forge_item()
		if run_state.add_item_to_inventory_or_pending(item_id):
			logs.append("[骰具] %s：打开骰包，生成 %s。" % [_tool_name(tool), ForgeItemCatalog.display_name_for_id(item_id)])
	return logs


func on_shop_rerolled(run_state) -> Array[String]:
	var logs: Array[String] = []
	for tool in _tools_for_run(run_state):
		if tool != null and tool.tool_id == DiceToolCatalog.TOOL_SHOP_REROLL_MULT:
			var next_value := _permanent_counter(tool, &"shop_reroll_count", 0) + 1
			tool.permanent_counters["shop_reroll_count"] = next_value
			logs.append("[骰具] %s：骰商铺刷新计数 +1 至 %d。" % [_tool_name(tool), next_value])
	return logs


func on_combo_upgrade_item_used(run_state, combo_id: StringName = &"") -> Array[String]:
	var logs: Array[String] = []
	for tool in _tools_for_run(run_state):
		if tool != null and tool.tool_id == DiceToolCatalog.TOOL_STAR_COUNTER:
			var next_value := _permanent_counter(tool, &"combo_upgrade_used_count", 0) + 1
			tool.permanent_counters["combo_upgrade_used_count"] = next_value
			logs.append("[骰具] %s：主骰型升级件计数 +1 至 %d。" % [_tool_name(tool), next_value])
	return logs


func on_forge_item_used(run_state, item_id: StringName = &"") -> Array[String]:
	if run_state == null:
		return []
	run_state.used_forge_item_count += 1
	return ["[骰具] 铸件占卜器：本局铸骰件使用计数为 %d。" % [run_state.used_forge_item_count]]


func on_face_copied(run_state, source_face_ref: Dictionary = {}, target_face_ref: Dictionary = {}) -> Array[String]:
	var logs: Array[String] = []
	for tool in _tools_for_run(run_state):
		if tool != null and tool.tool_id == DiceToolCatalog.TOOL_COPY_HOLOGRAM:
			var next_value := _permanent_counter(tool, &"copied_face_count", 0) + 1
			tool.permanent_counters["copied_face_count"] = next_value
			logs.append("[骰具] %s：复制覆盖计数 +1 至 %d。" % [_tool_name(tool), next_value])
	return logs


func on_lucky_ornament_success(run_state, face_ref = null, success_type: StringName = &"") -> Array[String]:
	var logs: Array[String] = []
	for tool in _tools_for_run(run_state):
		if tool != null and tool.tool_id == DiceToolCatalog.TOOL_LUCKY_CAT_INTEGER:
			var next_value := _permanent_counter(tool, &"lucky_success_count", 0) + 1
			tool.permanent_counters["lucky_success_count"] = next_value
			logs.append("[骰具] %s：幸运计数 +1 至 %d。" % [_tool_name(tool), next_value])
	return logs


func on_tool_sold(run_state, sold_tool: DiceToolState, battle_state = null) -> Array[String]:
	var logs: Array[String] = []
	if run_state == null or sold_tool == null:
		return logs
	logs.append_array(_record_item_sale_for_campfire(run_state))
	match sold_tool.tool_id:
		DiceToolCatalog.TOOL_DOUBLE_REWARD_TAG:
			run_state.pending_double_reward_tags += 1
			logs.append("[骰具] %s：获得 1 个双倍奖励标记。" % [_tool_name(sold_tool)])
		DiceToolCatalog.TOOL_BOSS_RULE_BREAKER:
			if battle_state != null and battle_state.config != null and battle_state.config.is_boss_battle:
				battle_state.boss_rule_disabled = true
				logs.append("[骰具] %s：当前 Boss 规则已禁用。" % [_tool_name(sold_tool)])
		DiceToolCatalog.TOOL_DELAYED_CLONE_SALE:
			var held_rounds := _permanent_counter(sold_tool, &"rounds_held", 0)
			if held_rounds >= 2:
				var generated := _copy_random_installed_tool_to_item_slot(run_state, sold_tool)
				if generated != "":
					logs.append("[骰具] %s：出售时复制 1 个其他已安装骰具为道具：%s。" % [_tool_name(sold_tool), generated])
				else:
					logs.append("[骰具] %s：出售时未能生成复制骰具道具。" % [_tool_name(sold_tool)])
		_:
			pass
	return logs


func on_item_sold(run_state, sold_item_state = null) -> Array[String]:
	if run_state == null:
		return []
	return _record_item_sale_for_campfire(run_state)


func on_boss_defeated(run_state) -> Array[String]:
	var logs: Array[String] = []
	for tool in _tools_for_run(run_state):
		if tool == null or tool.tool_id != DiceToolCatalog.TOOL_CAMPFIRE_SALES:
			continue
		tool.permanent_counters["sold_item_counter"] = 0
		tool.permanent_counters["xmult_bonus"] = 0
		logs.append("[骰具] %s：击败 Boss 后，出售计数和终倍率加成已清空。" % [_tool_name(tool)])
	return logs


func on_boss_rule_triggered(run_state, battle_state = null, boss_rule_id: StringName = &"") -> Array[String]:
	var logs: Array[String] = []
	if battle_state != null:
		battle_state.boss_rule_triggered_this_round = true
	for tool in _tools_for_run(run_state):
		if tool == null or tool.tool_id != DiceToolCatalog.TOOL_BOSS_TRIGGER_BOUNTY:
			continue
		if bool(tool.runtime_counters.get("boss_bounty_paid_this_round", false)):
			continue
		tool.runtime_counters["boss_bounty_paid_this_round"] = true
		if run_state != null:
			run_state.add_coins(8, tool.tool_id)
		logs.append("[骰具] %s：Boss 规则触发，+8 金币。" % [_tool_name(tool)])
	return logs


func should_disable_boss_rules(run_state, battle_state = null) -> bool:
	if battle_state != null and bool(battle_state.boss_rule_disabled):
		return true
	if LongTermUnlockService.should_disable_boss_rules(run_state, battle_state):
		return true
	return _has_tool(run_state, DiceToolCatalog.TOOL_BOSS_DISABLE_LEGEND)


func on_shop_price_query(run_state, shop_item, current_price: int = 0) -> int:
	if not _has_tool(run_state, DiceToolCatalog.TOOL_COMBO_UPGRADE_SHOP_FREE):
		return current_price
	var item_id := _item_id_from_any(shop_item)
	var item_type := _item_type_from_any(shop_item)
	if item_type == ItemInstance.TYPE_COMBO_UPGRADE or ComboUpgradeCatalog.combo_id_from_item_id(item_id) != &"":
		return 0
	return current_price


func on_shop_phase_end(run_state) -> Array[String]:
	var logs: Array[String] = []
	for tool in _tools_for_run(run_state):
		if tool == null or tool.tool_id != DiceToolCatalog.TOOL_SHOP_END_ITEM_COPY:
			continue
		var copied_name := _copy_random_held_forge_or_upgrade_item(run_state)
		if copied_name != "":
			logs.append("[骰具] %s：骰商铺阶段结束，复制道具：%s。" % [_tool_name(tool), copied_name])
		else:
			logs.append("[骰具] %s：骰商铺阶段结束，没有可复制道具或道具槽位不足。" % [_tool_name(tool)])
	return logs


func on_battle_skipped(run_state) -> Array[String]:
	if run_state == null:
		return []
	run_state.skipped_battle_node_count += 1
	return ["[骰具] 跳战回响：本局跳过战斗节点计数为 %d。" % [run_state.skipped_battle_node_count]]


func allow_duplicate_generated_options(run_state) -> bool:
	return _has_tool(run_state, DiceToolCatalog.TOOL_DUPLICATE_SHOWMAN)


func on_burst_ornament_broken(run_state, roll: RolledFace = null) -> Array[String]:
	var logs: Array[String] = []
	for tool in _tools_for_run(run_state):
		if tool == null or tool.tool_id != DiceToolCatalog.TOOL_BURST_BREAK_GLASS:
			continue
		var next_bonus := _permanent_counter(tool, &"xmult_bonus", 0) + 1
		tool.permanent_counters["xmult_bonus"] = next_bonus
		logs.append("[骰具] %s：爆裂面饰实际破碎，终倍率加成 +1 至 %d。" % [_tool_name(tool), next_bonus])
	return logs


func on_face_changed(run_state, before_face: FaceState, after_face: FaceState, reason: StringName = &"") -> Array[String]:
	var logs: Array[String] = []
	if before_face == null or after_face == null:
		return logs
	if not is_high_pip(before_face.pip) or is_high_pip(after_face.pip):
		return logs
	for tool in _tools_for_run(run_state):
		if tool == null or tool.tool_id != DiceToolCatalog.TOOL_HIGH_PIP_TRANSFORM_X:
			continue
		var next_count := _permanent_counter(tool, &"high_transform_counter", 0) + 1
		tool.permanent_counters["high_transform_counter"] = next_count
		logs.append("[骰具] %s：高点面变为非高点，终倍率加成 +1 至 %d。" % [_tool_name(tool), next_count])
	return logs


func try_apply_bone_safety(run_state, battle_state, result: ScoreResult = null) -> bool:
	if run_state == null or battle_state == null:
		return false
	var target: int = max(1, int(battle_state.config.target_score))
	if battle_state.total_score < int(ceil(float(target) / 4.0)):
		return false
	for tool in _tools_for_run(run_state):
		if tool == null or tool.tool_id != DiceToolCatalog.TOOL_BONE_SAFETY:
			continue
		if result != null:
			_log_tool(result, tool, "保底骨架避免失败。")
		_destroy_tool(run_state, tool, result, "触发后自毁。")
		return true
	return false


func apply_pending_face_copy(run_state, target_ref: Dictionary) -> Dictionary:
	if run_state == null or run_state.pending_dice_tool_face_copy.is_empty():
		return {"success": false, "message": "没有待处理的骰面复制覆盖。"}
	var request: Dictionary = run_state.pending_dice_tool_face_copy.duplicate(true)
	var source_ref := {
		"die_index": int(request.get("source_die_index", -1)),
		"face_index": int(request.get("source_face_index", -1)),
	}
	var result := copy_existing_face(run_state, source_ref, target_ref)
	if bool(result.get("success", false)):
		run_state.pending_dice_tool_face_copy.clear()
	return result


func copy_existing_face(run_state, source_ref: Dictionary, target_ref: Dictionary) -> Dictionary:
	var source := _face_entry_from_ref(run_state, source_ref)
	var target := _face_entry_from_ref(run_state, target_ref)
	if not bool(source.get("valid", false)):
		return {"success": false, "message": "来源骰面无效。"}
	if not bool(target.get("valid", false)):
		return {"success": false, "message": "目标骰面无效。"}
	if int(source.get("die_index", -1)) == int(target.get("die_index", -2)) and int(source.get("face_index", -1)) == int(target.get("face_index", -2)):
		return {"success": false, "message": "来源骰面不能等于目标骰面。"}
	var source_face: FaceState = source["face"]
	var target_die: DieState = target["die"]
	var target_face: FaceState = target["face"]
	if not DieState.get_legal_pips(target_die.face_count).has(source_face.pip):
		return {"success": false, "message": "来源点数不适合目标骰子面数。"}
	var before_face := target_face.clone()
	target_face.pip = source_face.pip
	target_face.ornament_id = source_face.get_effective_ornament_id()
	target_face.mark_id = source_face.mark_id
	target_face.material_id = &"none"
	on_face_changed(run_state, before_face, target_face, &"face_copy")
	on_face_copied(run_state, source_ref, target_ref)
	return {"success": true, "message": "骰面已复制覆盖。"}


func apply_face_trigger_tools(context: ScoreContext, result: ScoreResult, trace, roll: RolledFace, trigger_index: int = 0) -> void:
	if context == null or result == null or roll == null or roll.face == null:
		return
	var tools := _installed_tools(context)
	if tools.is_empty():
		return
	var pip = get_effective_pip(roll, context)
	var ornament_id := _effective_ornament_for_roll(roll, context)
	for index in range(tools.size()):
		var tool: DiceToolState = tools[index]
		if tool == null:
			continue
		match tool.tool_id:
			DiceToolCatalog.TOOL_SIX_FOUR_BROADCAST:
				if pip != null and [4, 6].has(int(pip)):
					_add_chips_mult(result, trace, tool, 10, 4, "有效点数 %d 的骰面触发，+10 基础战力，+4 倍率。" % [int(pip)])
			DiceToolCatalog.TOOL_HIGH_SMILE_MULT:
				if pip != null and _is_high_for_tools(roll, int(pip), context):
					_add_mult(result, trace, tool, 5, "高点面触发，+5 倍率。")
			DiceToolCatalog.TOOL_GOLD_ORNAMENT_INCOME:
				if ornament_id == FaceState.ORN_GOLD:
					_add_coins(context, result, 4)
					_log_tool(result, tool, "金辉面饰骰面触发，+4 金币。")
			DiceToolCatalog.TOOL_EVEN_COIN_GEM:
				if pip != null and is_even_pip(int(pip)):
					_add_coins(context, result, 1)
					_log_tool(result, tool, "偶数面触发，+1 金币。")
			DiceToolCatalog.TOOL_ODD_BLOODSTONE:
				if pip != null and is_odd_pip(int(pip)):
					if probability_succeeds(context, 1, 2):
						_multiply_xmult(result, trace, tool, 2, "奇数面判定成功，终倍率 ×2。")
					else:
						_log_tool(result, tool, "奇数面判定未成功。")
			DiceToolCatalog.TOOL_HIGH_ARROWHEAD:
				if pip != null and _is_high_for_tools(roll, int(pip), context):
					_add_chips(result, trace, tool, 50, "高点面触发，+50 基础战力。")
			DiceToolCatalog.TOOL_LOW_ONYX_AGATE:
				if pip != null and is_low_pip(int(pip)):
					_add_mult(result, trace, tool, 7, "低点面触发，+7 倍率。")
			DiceToolCatalog.TOOL_TWO_PIP_WEEJOKER:
				if pip != null and int(pip) == 2:
					var next_chips := _permanent_counter(tool, &"chips_bonus", 0) + 8
					_set_tool_counter(context, index, &"permanent", &"chips_bonus", next_chips)
					_log_tool(result, tool, "2 点面触发，累计基础战力 +8 至 %d。" % [next_chips])
			DiceToolCatalog.TOOL_FIVE_SIX_X2:
				if pip != null and [5, 6].has(int(pip)):
					_multiply_xmult(result, trace, tool, 2, "%d 点面触发，终倍率 ×2。" % [int(pip)])
			_:
				pass


func apply_probability_modifiers(run_state, numerator: int, denominator: int) -> Vector2i:
	var safe_denominator: int = max(1, denominator)
	var safe_numerator: int = max(0, numerator)
	if _has_tool(run_state, DiceToolCatalog.TOOL_PROBABILITY_DOUBLER):
		safe_numerator *= 2
	safe_numerator = min(safe_numerator, safe_denominator)
	if safe_numerator >= safe_denominator:
		return Vector2i(1, 1)
	return Vector2i(safe_numerator, safe_denominator)


func probability_succeeds(context: ScoreContext, numerator: int, denominator: int) -> bool:
	var modified := apply_probability_modifiers(context.run_state if context != null else null, numerator, denominator)
	if modified.x >= modified.y:
		return true
	return _randf(context) < float(modified.x) / float(modified.y)


static func get_effective_pip(roll: RolledFace, context: ScoreContext = null) -> Variant:
	return ComboEvaluator.get_effective_pip_for_point_logic(roll, context)


static func is_low_pip(pip: int) -> bool:
	return [1, 2, 3, 4].has(pip)


static func is_high_pip(pip: int) -> bool:
	return [5, 6, 7, 8].has(pip)


static func is_even_pip(pip: int) -> bool:
	return pip % 2 == 0


static func is_odd_pip(pip: int) -> bool:
	return pip % 2 == 1


static func effective_pips_for_rolls(rolls: Array, context: ScoreContext = null) -> Array[int]:
	var pips: Array[int] = []
	for roll in rolls:
		var pip = get_effective_pip(roll, context)
		if pip != null:
			pips.append(int(pip))
	return pips


static func count_pips(pips: Array[int]) -> Dictionary:
	var counts := {}
	for pip in pips:
		counts[pip] = int(counts.get(pip, 0)) + 1
	return counts


static func has_pair_structure(effective_pips: Array[int]) -> bool:
	return _max_count_by_pip(effective_pips) >= 2


static func has_three_kind_structure(effective_pips: Array[int]) -> bool:
	return _max_count_by_pip(effective_pips) >= 3


static func has_four_kind_structure(effective_pips: Array[int]) -> bool:
	return _max_count_by_pip(effective_pips) >= 4


static func has_two_pair_structure(effective_pips: Array[int]) -> bool:
	return _count_pips_with_at_least_n(effective_pips, 2) >= 2


static func has_straight_structure(effective_pips: Array[int], modifiers: Dictionary = {}) -> bool:
	var required := int(modifiers.get("straight_required_count", 5))
	required = clampi(required, 4, 5)
	var allow_one_gap := bool(modifiers.get("straight_allow_one_gap", false))
	var unique: Array[int] = []
	for pip in effective_pips:
		if not unique.has(pip):
			unique.append(pip)
	unique.sort()
	if unique.size() < required:
		return false
	return not ComboEvaluator._straight_pip_subset(unique, required, allow_one_gap).is_empty()


static func has_aligned_fact(effective_pips: Array[int], allow_one_miss: bool = false) -> bool:
	if effective_pips.is_empty():
		return false
	var tolerance := 1 if allow_one_miss else 0
	return (
		_all_pips_match(effective_pips, [1, 3, 5, 7], tolerance)
		or _all_pips_match(effective_pips, [2, 4, 6, 8], tolerance)
		or _all_pips_match(effective_pips, [1, 2, 3, 4], tolerance)
		or _all_pips_match(effective_pips, [5, 6, 7, 8], tolerance)
	)


static func _max_count_by_pip(effective_pips: Array[int]) -> int:
	var best := 0
	for count in count_pips(effective_pips).values():
		best = max(best, int(count))
	return best


static func _count_pips_with_at_least_n(effective_pips: Array[int], threshold: int) -> int:
	var count := 0
	for value in count_pips(effective_pips).values():
		if int(value) >= threshold:
			count += 1
	return count


static func _all_pips_match(effective_pips: Array[int], allowed: Array, tolerance: int = 0) -> bool:
	if effective_pips.is_empty():
		return false
	var miss_count := 0
	for pip in effective_pips:
		if not allowed.has(pip):
			miss_count += 1
			if miss_count > tolerance:
				return false
	return true


func _apply_six_round_xmult(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState, tool_index: int) -> void:
	var current := _combat_counter(tool, &"scored_round_counter", 0)
	var next_value := current + 1
	if next_value >= 6:
		next_value = 0
		_multiply_xmult(result, trace, tool, 4, "第 6 次结算回合触发，终倍率 ×4，计数重置为 0。")
	else:
		_log_tool(result, tool, "结算回合计数 %d / 6，未触发终倍率。" % [next_value])
	_set_tool_counter(context, tool_index, &"combat", &"scored_round_counter", next_value)


func _apply_six_forge_generator(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var six_rolls := _selected_rolls_with_pip(context, 6)
	if six_rolls.is_empty():
		return
	var free_slots := _free_item_slots(context)
	var success_count := 0
	var fail_count := 0
	var no_slot_count := 0
	var generated_names: Array[String] = []
	for _roll in six_rolls:
		if _randf(context) >= 0.25:
			fail_count += 1
			continue
		if free_slots <= 0:
			no_slot_count += 1
			continue
		var item_id := reward_generator.roll_random_formal_forge_item()
		if item_id == &"":
			fail_count += 1
			continue
		if _add_item(context, item_id):
			free_slots -= 1
			success_count += 1
			generated_names.append(ForgeItemCatalog.display_name_for_id(item_id))
	if success_count > 0:
		_log_tool(result, tool, "%d 个 6 点面尝试生成铸骰件，成功 %d 次，生成：%s。" % [six_rolls.size(), success_count, DisplayNames.join_names(generated_names)])
	if fail_count > 0:
		_log_tool(result, tool, "%d 个 6 点面生成判定未成功。" % [fail_count])
	if no_slot_count > 0:
		_log_tool(result, tool, "%d 次生成未发生：道具槽位不足。" % [no_slot_count])


func _apply_unscored_retrigger(context: ScoreContext, result: ScoreResult, trace, effect_resolver, tool: DiceToolState) -> void:
	if effect_resolver == null:
		return
	var triggered := 0
	var before := _score_snapshot(result)
	for roll in context.unscored_faces:
		if roll == null:
			continue
		if effect_resolver._apply_single_unselected_stay_trigger(roll, context, result, trace, true):
			triggered += 1
	if triggered > 0:
		_log_tool(result, tool, "%d 个未结算留场骰面的留场触发效果额外执行 1 次。" % [triggered])
		_append_tool_step(trace, result, before, tool, "留场复触", "额外执行 %d 次留场触发。" % [triggered])


func _apply_final_round_retrigger(context: ScoreContext, result: ScoreResult, trace, effect_resolver, tool: DiceToolState) -> void:
	if effect_resolver == null or not _is_final_round(context):
		return
	var before := _score_snapshot(result)
	for roll in context.selected_faces:
		effect_resolver._apply_single_face_trigger(roll, result, 1, context, trace)
	_log_tool(result, tool, "最后一回合中，%d 个被结算骰面额外触发 1 次。" % [context.selected_faces.size()])
	_append_tool_step(trace, result, before, tool, "最后一回合复触", "被结算骰面额外触发。")


func _apply_low_mid_retrigger(context: ScoreContext, result: ScoreResult, trace, effect_resolver, tool: DiceToolState) -> void:
	if effect_resolver == null:
		return
	var before := _score_snapshot(result)
	var triggered := 0
	for roll in context.selected_faces:
		var pip = get_effective_pip(roll, context)
		if pip == null:
			continue
		if [2, 3, 4, 5].has(int(pip)):
			effect_resolver._apply_single_face_trigger(roll, result, 1, context, trace)
			triggered += 1
	if triggered > 0:
		_log_tool(result, tool, "%d 个 2 / 3 / 4 / 5 点面重新触发。" % [triggered])
		_append_tool_step(trace, result, before, tool, "低中点复触", "重新触发 %d 个骰面。" % [triggered])


func _apply_lowest_unscored_mult(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var pips := effective_pips_for_rolls(context.unscored_faces, context)
	if pips.is_empty():
		return
	pips.sort()
	var lowest := pips[0]
	_add_mult(result, trace, tool, lowest * 2, "未结算留场骰面最低有效点数为 %d，+%d 倍率。" % [lowest, lowest * 2])


func _apply_high_income_chance(context: ScoreContext, result: ScoreResult, _trace, tool: DiceToolState) -> void:
	var attempts := 0
	var success := 0
	for roll in context.selected_faces:
		var pip = get_effective_pip(roll, context)
		if pip == null or not _is_high_for_tools(roll, int(pip), context):
			continue
		attempts += 1
		if _randf(context) < 0.5:
			success += 1
			_add_coins(context, result, 2)
	if attempts > 0:
		_log_tool(result, tool, "%d 个高点面触发金币判定，成功 %d 次，失败 %d 次，+%d 金币。" % [attempts, success, attempts - success, success * 2])


func _apply_combo_count_mult(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var combo_id := ComboUpgradeCatalog.normalize_combo_id(context.primary_combo)
	if combo_id == &"":
		return
	var count := 1
	if context.run_state != null:
		count = int(context.run_state.combo_scored_counts.get(combo_id, 0)) + 1
		if not context.is_preview:
			if context.defer_runtime_mutations:
				context.score_events.append({"type": &"combo_scored_count", "combo_id": combo_id, "count": count})
			else:
				context.run_state.combo_scored_counts[combo_id] = count
	_add_mult(result, trace, tool, count, "本局当前主骰型已结算次数为 %d，+%d 倍率。" % [count, count])


func _apply_no_high_streak(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState, tool_index: int, high_count: int) -> void:
	if high_count > 0:
		_set_tool_counter(context, tool_index, &"permanent", &"no_high_streak", 0)
		_log_tool(result, tool, "本回合有高点面被结算，连续计数重置为 0。")
		return
	var next_value := _permanent_counter(tool, &"no_high_streak", 0) + 1
	_set_tool_counter(context, tool_index, &"permanent", &"no_high_streak", next_value)
	_add_mult(result, trace, tool, next_value, "本回合没有高点面被结算，连续计数 +1，当前 +%d 倍率。" % [next_value])


func _apply_space_combo_upgrade(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	var combo_id := ComboUpgradeCatalog.normalize_combo_id(context.primary_combo)
	if not ComboUpgradeCatalog.has_combo(combo_id):
		_log_tool(result, tool, "当前主骰型不能升格，未触发。")
		return
	if _randf(context) >= 0.25:
		_log_tool(result, tool, "主骰型升格判定未成功。")
		return
	if context.run_state != null and not context.is_preview:
		if context.defer_runtime_mutations:
			context.score_events.append({"type": &"combo_upgrade", "combo_id": combo_id, "amount": 1})
		else:
			context.run_state.increase_combo_level(combo_id, 1)
	_log_tool(result, tool, "判定成功，主骰型「%s」等级 +1。" % [DisplayNames.combo_name(combo_id)])


func _apply_straight_runner(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState, tool_index: int, has_straight: bool) -> void:
	var current := _permanent_counter(tool, &"chips_bonus", 0)
	var next_value := current
	if has_straight:
		next_value += 15
		_set_tool_counter(context, tool_index, &"permanent", &"chips_bonus", next_value)
		_add_chips(result, trace, tool, next_value, "满足顺子结构，累计基础战力 +15，当前提供 +%d 基础战力。" % [next_value])
	elif next_value > 0:
		_add_chips(result, trace, tool, next_value, "当前累计提供 +%d 基础战力。" % [next_value])


func _apply_unscored_low_high_xmult(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var valid_rolls: Array[RolledFace] = []
	var pips: Array[int] = []
	for roll in context.unscored_faces:
		var pip = get_effective_pip(roll, context)
		if pip == null:
			continue
		valid_rolls.append(roll)
		pips.append(int(pip))
	if pips.is_empty():
		return
	var all_low := true
	var all_high := true
	for index in range(valid_rolls.size()):
		var pip := pips[index]
		var roll := valid_rolls[index]
		all_low = all_low and is_low_pip(pip)
		all_high = all_high and _is_high_for_tools(roll, pip, context)
	if all_low or all_high:
		_multiply_xmult(result, trace, tool, 3, "有效未结算留场骰面全部为%s，终倍率 ×3。" % ["低点面" if all_low else "高点面"])


func _apply_single_face_blueprint_pending(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	if not _is_first_battle_round(context) or context.selected_faces.size() != 1:
		return
	var roll: RolledFace = context.selected_faces[0]
	if roll == null or roll.face == null:
		return
	var request := {
		"tool_id": tool.tool_id,
		"source_die_index": roll.die_index,
		"source_face_index": roll.face_index,
		"pip": roll.face.pip,
		"ornament_id": roll.face.get_effective_ornament_id(),
		"mark_id": roll.face.mark_id,
	}
	_queue_or_apply_run_event(context, {
		"type": &"pending_face_copy",
		"request": request,
	})
	_log_tool(result, tool, "第一回合只结算 1 个骰面，进入待处理复制覆盖状态。")


func _apply_splash_scoring(context: ScoreContext, result: ScoreResult, trace, effect_resolver, tool: DiceToolState) -> void:
	if effect_resolver == null:
		return
	var before := _score_snapshot(result)
	var triggered := 0
	for roll in context.selected_faces:
		if _structure_keys(context).has(_face_key(roll)):
			continue
		if _effective_ornament_for_roll(roll, context) == FaceState.ORN_NONE:
			continue
		effect_resolver._apply_ornament_only_retrigger(roll, context, result, trace)
		triggered += 1
	if triggered > 0:
		_log_tool(result, tool, "%d 个未参与主骰型结构的骰面，其面饰额外触发 1 次。" % [triggered])
		_append_tool_step(trace, result, before, tool, _tool_name(tool), "溅射触发 %d 次面饰。" % [triggered])


func _apply_leftover_chips(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var count := context.unscored_faces.size()
	if count > 0:
		_add_chips(result, trace, tool, count * 2, "当前投出结果中有 %d 个未被结算的骰面位，+%d 基础战力。" % [count, count * 2])


func _apply_single_six_reforge(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	if not _is_first_battle_round(context) or context.selected_faces.size() != 1:
		return
	var roll: RolledFace = context.selected_faces[0]
	var pip = get_effective_pip(roll, context)
	if pip == null or int(pip) != 6:
		return
	if _free_item_slots(context) <= 0:
		_log_tool(result, tool, "触发条件满足，但道具槽位不足；物理骰面未重置。")
		return
	var item_id := reward_generator.roll_random_formal_forge_item()
	if item_id == &"":
		_log_tool(result, tool, "未能生成铸骰件。")
		return
	var new_pip := _random_legal_pip_for_roll(context, roll)
	_queue_or_apply_run_event(context, {
		"type": &"reset_face",
		"die_index": roll.die_index,
		"face_index": roll.face_index,
		"pip": new_pip,
	})
	if _add_item(context, item_id):
		_log_tool(result, tool, "第一回合单独结算 6 点面，重置该物理骰面并生成：%s。" % [ForgeItemCatalog.display_name_for_id(item_id)])


func _apply_trail_marker(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState, tool_index: int) -> void:
	var credited := _dictionary_counter(tool, &"credited_face_keys")
	var added := 0
	for roll in context.selected_faces:
		var key := _face_key(roll)
		if key == "" or bool(credited.get(key, false)):
			continue
		credited[key] = true
		added += 1
	if added > 0:
		_set_tool_counter_value(context, tool_index, &"permanent", &"credited_face_keys", credited)
	var chips := credited.size() * 5
	if chips > 0:
		_add_chips(result, trace, tool, chips, "本局首次被结算的物理骰面累计 %d 个，提供 +%d 基础战力。" % [credited.size(), chips])


func _apply_straight_six_supply(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	if ComboUpgradeCatalog.normalize_combo_id(context.primary_combo) != ComboUpgradeCatalog.STRAIGHT:
		return
	if _count_selected_pip(context, 6) <= 0:
		return
	_generate_forge_item_for_score(context, result, tool, false, "主骰型为顺子且包含 6 点面")


func _apply_target_combo_contract(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	if context.run_state == null:
		return
	var target_combo := StringName(str(tool.permanent_counters.get("target_combo_id", &"")))
	if target_combo == &"":
		target_combo = _random_combo_id(context.run_state)
		tool.permanent_counters["target_combo_id"] = target_combo
	if ComboUpgradeCatalog.normalize_combo_id(context.primary_combo) == ComboUpgradeCatalog.normalize_combo_id(target_combo):
		_add_coins(context, result, 4)
		_log_tool(result, tool, "本回合主骰型命中委托「%s」，+4 金币。" % [DisplayNames.combo_name(target_combo)])


func _apply_repeat_combo_x3(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState, tool_index: int) -> void:
	var combo_id := ComboUpgradeCatalog.normalize_combo_id(context.primary_combo)
	var seen := _dictionary_counter(tool, &"seen_combo_ids_this_battle", true)
	if bool(seen.get(combo_id, false)):
		_multiply_xmult(result, trace, tool, 3, "本场战斗此前已结算过「%s」，终倍率 ×3。" % [DisplayNames.combo_name(combo_id)])
	else:
		_log_tool(result, tool, "首次记录本场战斗主骰型「%s」。" % [DisplayNames.combo_name(combo_id)])
	seen[combo_id] = true
	_set_tool_counter_value(context, tool_index, &"combat", &"seen_combo_ids_this_battle", seen)


func _apply_four_face_square(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState, tool_index: int) -> void:
	var current := _permanent_counter(tool, &"square_chips", 0)
	var next_value := current
	if context.selected_faces.size() == 4:
		next_value += 4
		_set_tool_counter(context, tool_index, &"permanent", &"square_chips", next_value)
	if next_value > 0:
		_add_chips(result, trace, tool, next_value, "当前累计提供 +%d 基础战力%s。" % [next_value, "，本回合正好结算 4 个骰面" if next_value != current else ""])


func _apply_straight_forge_supply(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	if ComboUpgradeCatalog.normalize_combo_id(context.primary_combo) == ComboUpgradeCatalog.STRAIGHT:
		_generate_forge_item_for_score(context, result, tool, true, "主骰型为顺子")


func _apply_ornament_vampire(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState, tool_index: int) -> void:
	var absorbed_now := 0
	for roll in context.selected_faces:
		var ornament_id := _effective_ornament_for_roll(roll, context)
		if ornament_id == FaceState.ORN_NONE:
			continue
		absorbed_now += 1
		_queue_or_apply_run_event(context, {
			"type": &"set_face_ornament",
			"die_index": roll.die_index,
			"face_index": roll.face_index,
			"ornament_id": FaceState.ORN_NONE,
		})
	var total := _permanent_counter(tool, &"absorbed_ornament_count", 0) + absorbed_now
	if absorbed_now > 0:
		_set_tool_counter(context, tool_index, &"permanent", &"absorbed_ornament_count", total)
	var factor := 1 + int(floor(float(total) / 10.0))
	_multiply_xmult(result, trace, tool, factor, "累计吞噬面饰 %d 个，终倍率 ×%d；本回合吞噬 %d 个。" % [total, factor, absorbed_now])


func _apply_poor_forge_supply(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	if context.run_state == null:
		return
	if context.run_state.coins + context.coins_delta <= 4:
		_generate_forge_item_for_score(context, result, tool, false, "结算后当前金币不高于 4")


func _apply_six_stay_king(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var count := 0
	for roll in context.unscored_faces:
		if _unscored_raw_pip_is_valid(roll, 6):
			count += 1
	if count <= 0:
		return
	var factor := 1
	for _i in range(count):
		factor *= 2
	_multiply_xmult(result, trace, tool, factor, "%d 个未结算留场 6 点面触发，终倍率 ×%d。" % [count, factor])


func _apply_obelisk_rotation(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState, tool_index: int) -> void:
	var combo_id := ComboUpgradeCatalog.normalize_combo_id(context.primary_combo)
	var counts := _dictionary_counter(tool, &"combo_play_counts", true)
	var top_count := 0
	for value in counts.values():
		top_count = max(top_count, int(value))
	var is_top := false
	if top_count > 0:
		for key in counts.keys():
			if int(counts[key]) == top_count and ComboUpgradeCatalog.normalize_combo_id(StringName(str(key))) == combo_id:
				is_top = true
				break
	var streak := _combat_counter(tool, &"obelisk_streak", _permanent_counter(tool, &"obelisk_streak", 0))
	streak = 0 if is_top else streak + 1
	counts[combo_id] = int(counts.get(combo_id, 0)) + 1
	_set_tool_counter_value(context, tool_index, &"combat", &"combo_play_counts", counts)
	_set_tool_counter(context, tool_index, &"combat", &"obelisk_streak", streak)
	var factor := 1 + int(floor(float(streak) / 5.0))
	_multiply_xmult(result, trace, tool, factor, "轮换计数 %d，终倍率 ×%d。" % [streak, factor])


func _apply_high_to_gold(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	var count := 0
	for roll in context.selected_faces:
		var pip = get_effective_pip(roll, context)
		if pip == null or not _is_high_for_tools(roll, int(pip), context):
			continue
		count += 1
		_queue_or_apply_run_event(context, {
			"type": &"set_face_ornament",
			"die_index": roll.die_index,
			"face_index": roll.face_index,
			"ornament_id": FaceState.ORN_GOLD,
		})
	if count > 0:
		_log_tool(result, tool, "%d 个被结算高点面在结算后变为金辉面饰。" % [count])


func _apply_first_high_x2(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	for roll in context.selected_faces:
		var pip = get_effective_pip(roll, context)
		if pip != null and _is_high_for_tools(roll, int(pip), context):
			_multiply_xmult(result, trace, tool, 2, "第一个被结算高点面触发，终倍率 ×2。")
			return


func _apply_face_count_gap_mult(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	if context.run_state == null:
		return
	var start_count := context.run_state.starting_total_face_count
	if start_count <= 0:
		start_count = context.run_state.get_total_face_count()
		context.run_state.starting_total_face_count = start_count
	var current_count := context.run_state.get_total_face_count()
	var gap: int = max(0, start_count - current_count)
	if gap > 0:
		_add_mult(result, trace, tool, gap * 4, "当前总面数比本局起始少 %d 个，+%d 倍率。" % [gap, gap * 4])


func _apply_high_stay_parking(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	var attempts := 0
	var success := 0
	for roll in context.unscored_faces:
		if not _unscored_raw_high_is_valid(roll):
			continue
		attempts += 1
		if _randf(context) < 0.5:
			success += 1
	if attempts > 0:
		if success > 0:
			_add_coins(context, result, success)
		_log_tool(result, tool, "%d 个未结算留场高点面判定，成功 %d 次，+%d 金币。" % [attempts, success, success])


func _apply_uncommon_team_xmult(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var count := 0
	for installed in _installed_tools(context):
		if installed != null and installed.rarity == &"uncommon":
			count += 1
	var pairs := int(floor(float(count) / 2.0))
	if pairs <= 0:
		return
	var factor := 1
	for _i in range(pairs):
		factor *= 2
	_multiply_xmult(result, trace, tool, factor, "%d 个罕见骰具形成 %d 组，终倍率 ×%d。" % [count, pairs, factor])


func _apply_two_pair_trousers(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState, tool_index: int, has_two_pair: bool) -> void:
	var current := _permanent_counter(tool, &"trousers_mult", 0)
	var next_value := current
	if has_two_pair:
		next_value += 2
		_set_tool_counter(context, tool_index, &"permanent", &"trousers_mult", next_value)
	if next_value > 0:
		_add_mult(result, trace, tool, next_value, "当前累计提供 +%d 倍率%s。" % [next_value, "，本回合存在两对结构" if next_value != current else ""])


func _apply_ancient_point_class(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var class_id := StringName(str(tool.permanent_counters.get("ancient_class", &"")))
	if class_id == &"":
		class_id = _random_ancient_class(context.run_state)
		tool.permanent_counters["ancient_class"] = class_id
	var count := 0
	for roll in context.selected_faces:
		var pip = get_effective_pip(roll, context)
		if pip != null and _pip_matches_ancient_class(int(pip), class_id):
			count += 1
	if count <= 0:
		_log_tool(result, tool, "当前指定分类为「%s」，没有符合条件的有效骰面。" % [_ancient_class_name(class_id)])
		return
	var factor := 1
	for _i in range(count):
		factor *= 2
	_multiply_xmult(result, trace, tool, factor, "当前指定分类「%s」，%d 个有效骰面触发，终倍率 ×%d。" % [_ancient_class_name(class_id), count, factor])


func _apply_seltzer_retrigger(context: ScoreContext, result: ScoreResult, trace, effect_resolver, tool: DiceToolState) -> void:
	if effect_resolver == null:
		return
	var remaining := _permanent_counter(tool, &"remaining_retrigger_rounds", 10)
	if remaining <= 0:
		return
	var before := _score_snapshot(result)
	var triggered := 0
	for roll in context.selected_faces:
		effect_resolver._apply_single_face_trigger(roll, result, 1, context, trace)
		triggered += 1
	if triggered > 0:
		_log_tool(result, tool, "剩余重触回合数 %d，本回合 %d 个被结算骰面额外触发 1 次。" % [remaining, triggered])
		_append_tool_step(trace, result, before, tool, _tool_name(tool), "额外触发 %d 个被结算骰面。" % [triggered])


func _apply_counter_xmult(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState, key: StringName, label: String) -> void:
	var bonus := _permanent_counter(tool, key, 0)
	if bonus <= 0:
		_log_tool(result, tool, "%s为 0，未提供终倍率。" % [label])
		return
	_multiply_xmult(result, trace, tool, 1 + bonus, "%s为 %d，终倍率 ×%d。" % [label, bonus, 1 + bonus])


func _apply_high_face_retrigger(context: ScoreContext, result: ScoreResult, trace, effect_resolver, tool: DiceToolState) -> void:
	if effect_resolver == null:
		return
	var before := _score_snapshot(result)
	var triggered := 0
	for roll in context.selected_faces:
		var pip = get_effective_pip(roll, context)
		if pip == null or not _is_high_for_tools(roll, int(pip), context):
			continue
		effect_resolver._apply_single_face_trigger(roll, result, 1, context, trace)
		triggered += 1
	if triggered > 0:
		_log_tool(result, tool, "%d 个高点面额外触发 1 次。" % [triggered])
		_append_tool_step(trace, result, before, tool, _tool_name(tool), "高点面额外触发 %d 次。" % [triggered])


func _apply_sell_value_sword(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	if context.run_state == null:
		return
	var total := 0
	for installed in _tools_for_run(context.run_state):
		if installed != null and installed != tool:
			total += max(0, installed.sell_value)
	if total > 0:
		_add_mult(result, trace, tool, total, "其他已安装骰具卖价总和为 %d，+%d 倍率。" % [total, total])


func _apply_first_face_retrigger(context: ScoreContext, result: ScoreResult, trace, effect_resolver, tool: DiceToolState) -> void:
	if effect_resolver == null or context.selected_faces.is_empty():
		return
	var before := _score_snapshot(result)
	var first_roll: RolledFace = context.selected_faces[0]
	effect_resolver._apply_single_face_trigger(first_roll, result, 1, context, trace)
	effect_resolver._apply_single_face_trigger(first_roll, result, 2, context, trace)
	_log_tool(result, tool, "第一个被结算骰面额外触发 2 次。")
	_append_tool_step(trace, result, before, tool, _tool_name(tool), "首个被结算骰面额外触发。")


func _apply_four_fact_pot(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var pips := effective_pips_for_rolls(context.selected_faces, context)
	if pips.size() < 4:
		return
	var has_odd := false
	var has_even := false
	var has_low := false
	var has_high := false
	for pip in pips:
		has_odd = has_odd or is_odd_pip(pip)
		has_even = has_even or is_even_pip(pip)
		has_low = has_low or is_low_pip(pip)
		has_high = has_high or is_high_pip(pip)
	if has_odd and has_even and has_low and has_high:
		_multiply_xmult(result, trace, tool, 3, "至少 4 个有效骰面同时覆盖奇数、偶数、低点、高点，终倍率 ×3。")


func _apply_copy_tool_score(context: ScoreContext, result: ScoreResult, trace, effect_resolver, source_tool: DiceToolState, source_index: int, direction: StringName) -> void:
	var target := _resolve_copy_target(context.run_state, source_index, direction)
	if target == null:
		_log_tool(result, source_tool, "没有可复制的骰具。")
		return
	match target.tool_id:
		DiceToolCatalog.TOOL_BASIC_MULT:
			_add_mult(result, trace, source_tool, 4, "复制「%s」能力，+4 倍率。" % [_tool_name(target)])
		DiceToolCatalog.TOOL_STUNT_CHIPS:
			_add_chips(result, trace, source_tool, 250, "复制「%s」能力，+250 基础战力。" % [_tool_name(target)])
		DiceToolCatalog.TOOL_FINAL_ROUND_ACROBAT:
			if _is_final_round(context):
				_multiply_xmult(result, trace, source_tool, 3, "复制「%s」能力，最后一回合终倍率 ×3。" % [_tool_name(target)])
		DiceToolCatalog.TOOL_PAIR_X2:
			if has_pair_structure(effective_pips_for_rolls(context.selected_faces, context)):
				_multiply_xmult(result, trace, source_tool, 2, "复制「%s」能力，一对结构终倍率 ×2。" % [_tool_name(target)])
		DiceToolCatalog.TOOL_THREE_KIND_X3:
			if has_three_kind_structure(effective_pips_for_rolls(context.selected_faces, context)):
				_multiply_xmult(result, trace, source_tool, 3, "复制「%s」能力，三同结构终倍率 ×3。" % [_tool_name(target)])
		DiceToolCatalog.TOOL_FOUR_KIND_X4:
			if has_four_kind_structure(effective_pips_for_rolls(context.selected_faces, context)):
				_multiply_xmult(result, trace, source_tool, 4, "复制「%s」能力，四同结构终倍率 ×4。" % [_tool_name(target)])
		DiceToolCatalog.TOOL_STRAIGHT_X3:
			var straight := has_straight_structure(effective_pips_for_rolls(context.selected_faces, context), {
				"straight_required_count": context.straight_required_count,
				"straight_allow_one_gap": context.straight_allow_one_gap,
			})
			if straight:
				_multiply_xmult(result, trace, source_tool, 3, "复制「%s」能力，顺子结构终倍率 ×3。" % [_tool_name(target)])
		_:
			_log_tool(result, source_tool, "复制目标「%s」当前没有可复制的结算输出。" % [_tool_name(target)])


func _apply_five_stay_mult(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var count := 0
	for roll in context.unscored_faces:
		if _unscored_raw_pip_is_valid(roll, 5):
			count += 1
	if count > 0:
		_add_mult(result, trace, tool, count * 13, "%d 个未结算留场 5 点面，+%d 倍率。" % [count, count * 13])


func _apply_modified_face_license(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var count := _count_modified_permanent_faces(context.run_state)
	if count >= 16:
		_multiply_xmult(result, trace, tool, 3, "当前永久骰组有 %d 个改造面，终倍率 ×3。" % [count])
	else:
		_log_tool(result, tool, "当前永久骰组有 %d 个改造面，未达到 16 个。" % [count])


func _apply_idol_target(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var target_pip := int(tool.combat_counters.get("idol_pip", 0))
	var feature := StringName(str(tool.combat_counters.get("idol_feature", &"")))
	if target_pip <= 0 or feature == &"":
		return
	var count := 0
	for roll in context.selected_faces:
		var pip = get_effective_pip(roll, context)
		if pip == null or int(pip) != target_pip:
			continue
		if _roll_has_slot_feature(roll, feature, context):
			count += 1
	if count <= 0:
		return
	var factor := 1
	for _i in range(count):
		factor *= 2
	_multiply_xmult(result, trace, tool, factor, "目标 %d 点和「%s」命中 %d 个骰面，终倍率 ×%d。" % [target_pip, _slot_feature_name(feature), count, factor])


func _apply_low_plus_other_x2(context: ScoreContext, result: ScoreResult, trace, tool: DiceToolState) -> void:
	var has_low := false
	var has_other := false
	for pip in effective_pips_for_rolls(context.selected_faces, context):
		if is_low_pip(pip):
			has_low = true
		else:
			has_other = true
	if has_low and has_other:
		_multiply_xmult(result, trace, tool, 2, "当前回合同时有低点面和非低点面被结算，终倍率 ×2。")


func _apply_boss_trigger_bounty(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	if context.battle_state == null or not context.battle_state.boss_rule_triggered_this_round:
		return
	if bool(tool.runtime_counters.get("boss_bounty_paid_this_round", false)):
		return
	tool.runtime_counters["boss_bounty_paid_this_round"] = true
	_add_coins(context, result, 8)
	_log_tool(result, tool, "本回合触发 Boss 规则或禁用条件，+8 金币。")


func _apply_stone_seed(run_state) -> bool:
	var entries: Array[Dictionary] = []
	for die_index in range(run_state.dice.size()):
		var die = run_state.dice[die_index]
		if die == null:
			continue
		for face_index in range(die.faces.size()):
			if die.faces[face_index] != null:
				entries.append({"die_index": die_index, "face_index": face_index, "face": die.faces[face_index]})
	if entries.is_empty():
		return false
	var entry := entries[rng.randi_range(0, entries.size() - 1)]
	var face: FaceState = entry["face"]
	face.ornament_id = FaceState.ORN_STONE
	face.material_id = &"none"
	return true


func _add_chips(result: ScoreResult, trace, tool: DiceToolState, amount: int, detail: String, log_even_zero: bool = false) -> void:
	if amount == 0 and not log_even_zero:
		return
	var before := _score_snapshot(result)
	result.chips += amount
	_log_tool(result, tool, detail)
	_append_tool_step(trace, result, before, tool, _tool_name(tool), detail)


func _add_mult(result: ScoreResult, trace, tool: DiceToolState, amount: int, detail: String, log_even_zero: bool = false) -> void:
	if amount == 0 and not log_even_zero:
		return
	var before := _score_snapshot(result)
	result.mult += amount
	_log_tool(result, tool, detail)
	_append_tool_step(trace, result, before, tool, _tool_name(tool), detail)


func _add_chips_mult(result: ScoreResult, trace, tool: DiceToolState, chips: int, mult: int, detail: String) -> void:
	var before := _score_snapshot(result)
	result.chips += chips
	result.mult += mult
	_log_tool(result, tool, detail)
	_append_tool_step(trace, result, before, tool, _tool_name(tool), detail)


func _multiply_xmult(result: ScoreResult, trace, tool: DiceToolState, factor: int, detail: String) -> void:
	var safe_factor: int = max(1, factor)
	var before := _score_snapshot(result)
	result.xmult *= float(safe_factor)
	_log_tool(result, tool, detail)
	_append_tool_step(trace, result, before, tool, _tool_name(tool), detail)


func _add_mult_if_count(result: ScoreResult, trace, tool: DiceToolState, count: int, amount: int, detail: String) -> void:
	if count > 0:
		_add_mult(result, trace, tool, amount, detail)


func _add_chips_if_count(result: ScoreResult, trace, tool: DiceToolState, count: int, amount: int, detail: String) -> void:
	if count > 0:
		_add_chips(result, trace, tool, amount, detail)


func _add_coins(context: ScoreContext, result: ScoreResult, amount: int) -> void:
	if amount == 0:
		return
	context.coins_delta += amount
	result.coins_delta += amount
	if not context.is_preview and not context.defer_runtime_mutations and context.run_state != null:
		context.run_state.add_coins(amount, &"dice_tool")
	elif not context.is_preview and context.defer_runtime_mutations:
		context.score_events.append({"type": &"coins", "amount": amount})


func _add_item(context: ScoreContext, item_id: StringName) -> bool:
	if item_id == &"" or context == null:
		return false
	if context.is_preview:
		return true
	if context.defer_runtime_mutations:
		context.score_events.append({"type": &"item", "item_id": item_id})
		return true
	if context.run_state != null:
		return context.run_state.add_item_to_inventory_or_pending(item_id)
	return false


func _set_tool_counter(context: ScoreContext, tool_index: int, scope: StringName, key: StringName, value: int) -> void:
	if context == null or context.is_preview:
		return
	var tools := _installed_tools(context)
	if tool_index < 0 or tool_index >= tools.size():
		return
	var tool: DiceToolState = tools[tool_index]
	if tool == null:
		return
	if context.defer_runtime_mutations:
		context.score_events.append({
			"type": &"dice_tool_counter",
			"tool_index": tool_index,
			"scope": scope,
			"key": key,
			"value": value,
		})
	elif scope == &"combat":
		tool.combat_counters[key] = value
	else:
		tool.permanent_counters[key] = value


func _set_tool_counter_value(context: ScoreContext, tool_index: int, scope: StringName, key: StringName, value) -> void:
	if context == null or context.is_preview:
		return
	var tools := _installed_tools(context)
	if tool_index < 0 or tool_index >= tools.size():
		return
	var tool: DiceToolState = tools[tool_index]
	if tool == null:
		return
	var stored_value = value
	if value is Dictionary or value is Array:
		stored_value = value.duplicate(true)
	if context.defer_runtime_mutations:
		context.score_events.append({
			"type": &"dice_tool_counter_value",
			"tool_index": tool_index,
			"scope": scope,
			"key": key,
			"value": stored_value,
		})
	elif scope == &"combat":
		tool.combat_counters[key] = stored_value
	else:
		tool.permanent_counters[key] = stored_value


func _queue_or_apply_run_event(context: ScoreContext, event: Dictionary) -> void:
	if context == null or context.is_preview:
		return
	if context.defer_runtime_mutations:
		context.score_events.append(event)
		return
	_apply_run_event(context.run_state, event)


func _apply_run_event(run_state, event: Dictionary) -> void:
	if run_state == null:
		return
	var event_type := StringName(str(event.get("type", &"")))
	match event_type:
		&"pending_face_copy":
			run_state.pending_dice_tool_face_copy = event.get("request", {}).duplicate(true)
		&"reset_face":
			var reset_entry := _face_entry_from_ref(run_state, event)
			if bool(reset_entry.get("valid", false)):
				var reset_face: FaceState = reset_entry["face"]
				var before_reset := reset_face.clone()
				reset_face.pip = int(event.get("pip", reset_face.pip))
				reset_face.ornament_id = FaceState.ORN_NONE
				reset_face.mark_id = FaceState.MARK_NONE
				reset_face.material_id = &"none"
				on_face_changed(run_state, before_reset, reset_face, &"reset_face")
		&"set_face_ornament":
			var ornament_entry := _face_entry_from_ref(run_state, event)
			if bool(ornament_entry.get("valid", false)):
				var ornament_face: FaceState = ornament_entry["face"]
				var before_ornament := ornament_face.clone()
				ornament_face.ornament_id = FaceState.normalize_ornament_id(StringName(str(event.get("ornament_id", FaceState.ORN_NONE))))
				ornament_face.material_id = &"none"
				on_face_changed(run_state, before_ornament, ornament_face, &"set_face_ornament")
		_:
			pass


func _log_tool(result: ScoreResult, tool: DiceToolState, detail: String) -> void:
	if result == null:
		return
	result.add_log(BattleLogEntry.new(&"LOG.DICE_TOOL", {
		"text": "[骰具] %s：%s" % [_tool_name(tool), detail],
		"tool_id": tool.tool_id if tool != null else &"",
	}, &"dice_tool"))


func _append_tool_step(trace, result: ScoreResult, before: Dictionary, tool: DiceToolState, title: String, detail: String) -> void:
	if trace == null or result == null:
		return
	var step := ResolutionStep.new()
	step.phase = ResolutionStep.Phase.ITEM
	step.source_type = &"dice_tool"
	step.source_id = tool.tool_id if tool != null else &""
	step.source_display_name = _tool_name(tool)
	step.title = title
	step.detail = detail
	step.floating_text = _score_delta_text(before, result)
	step.set_before(int(before.get("chips", 0)), int(before.get("mult", 1)), float(before.get("xmult", 1.0)))
	step.set_after(result.chips, result.mult, result.xmult)
	step.log_line = "[骰具] %s：%s" % [_tool_name(tool), detail]
	trace.append_step(step)


func _score_delta_text(before: Dictionary, result: ScoreResult) -> String:
	var parts := PackedStringArray()
	var chips_delta: int = result.chips - int(before.get("chips", 0))
	var mult_delta: int = result.mult - int(before.get("mult", 1))
	var xmult_before := float(before.get("xmult", 1.0))
	var xmult_factor := 1.0 if is_zero_approx(xmult_before) else result.xmult / xmult_before
	if chips_delta != 0:
		parts.append("+%d 基础战力" % [chips_delta])
	if mult_delta != 0:
		parts.append("+%d 倍率" % [mult_delta])
	if not is_equal_approx(xmult_factor, 1.0):
		parts.append("终倍率 ×%d" % [int(ceil(xmult_factor))])
	return " / ".join(parts) if not parts.is_empty() else "触发"


func _installed_tools(context: ScoreContext) -> Array:
	if context == null or context.run_state == null:
		return []
	return _tools_for_run(context.run_state)


func _tools_for_run(run_state) -> Array:
	if run_state == null:
		return []
	if run_state.dice_tools.is_empty() and not run_state.installed_tools.is_empty():
		run_state.dice_tools = run_state.installed_tools
	elif run_state.installed_tools.is_empty() and not run_state.dice_tools.is_empty():
		run_state.installed_tools = run_state.dice_tools
	return run_state.dice_tools


func _tool_name(tool: DiceToolState) -> String:
	if tool == null:
		return "未知骰具"
	if tool.display_name != "":
		return tool.display_name
	return DiceToolCatalog.display_name_for_id(tool.tool_id)


func _score_snapshot(result: ScoreResult) -> Dictionary:
	return {"chips": result.chips, "mult": result.mult, "xmult": result.xmult}


func _permanent_counter(tool: DiceToolState, key: StringName, default_value: int = 0) -> int:
	if tool == null:
		return default_value
	return int(tool.permanent_counters.get(key, default_value))


func _combat_counter(tool: DiceToolState, key: StringName, default_value: int = 0) -> int:
	if tool == null:
		return default_value
	return int(tool.combat_counters.get(key, default_value))


func _dictionary_counter(tool: DiceToolState, key: StringName, combat: bool = false) -> Dictionary:
	if tool == null:
		return {}
	var source := tool.combat_counters if combat else tool.permanent_counters
	var value = source.get(key, {})
	if value is Dictionary:
		return value.duplicate(true)
	return {}


func _structure_keys(context: ScoreContext) -> Dictionary:
	if context == null:
		return {}
	return context.primary_structure_face_keys


func _face_key(roll: RolledFace) -> String:
	if roll == null:
		return ""
	if roll.face_instance_id != "":
		return roll.face_instance_id
	return RolledFace.make_face_instance_id(roll.die_id, roll.die_index, roll.face_index)


func _effective_ornament_for_roll(roll: RolledFace, context: ScoreContext = null) -> StringName:
	return ComboEvaluator._effective_ornament_id_for_roll(roll, context)


func _is_first_battle_round(context: ScoreContext) -> bool:
	if context == null:
		return false
	if context.hand_state != null:
		return context.hand_state.hand_index == 0
	if context.battle_state != null:
		return context.battle_state.hands_played == 0
	return false


func _random_combo_id(run_state = null) -> StringName:
	return _random_combo_id_for_run(run_state)


func _random_combo_id_for_run(run_state = null) -> StringName:
	var ids := ComboUpgradeCatalog.get_combo_ids()
	var combos: Array[StringName] = []
	for upgrade_id in ids:
		var def := ComboUpgradeCatalog.get_def_by_upgrade_id(upgrade_id)
		if def != null:
			combos.append(def.combo_id)
	if combos.is_empty():
		return ComboUpgradeCatalog.SCATTER
	var index := rng.randi_range(0, combos.size() - 1)
	return combos[index]


func _random_ancient_class(run_state = null) -> StringName:
	return _random_ancient_class_for_run(run_state)


func _random_ancient_class_for_run(run_state = null) -> StringName:
	var classes := [&"odd", &"even", &"low", &"high"]
	return classes[rng.randi_range(0, classes.size() - 1)]


func _ancient_class_name(class_id: StringName) -> String:
	match class_id:
		&"odd":
			return "奇数"
		&"even":
			return "偶数"
		&"low":
			return "低点"
		&"high":
			return "高点"
		_:
			return "未知"


func _pip_matches_ancient_class(pip: int, class_id: StringName) -> bool:
	match class_id:
		&"odd":
			return is_odd_pip(pip)
		&"even":
			return is_even_pip(pip)
		&"low":
			return is_low_pip(pip)
		&"high":
			return is_high_pip(pip)
		_:
			return false


func _random_legal_pip(run_state = null) -> int:
	return _random_legal_pip_for_run(run_state)


func _random_legal_pip_for_run(run_state = null) -> int:
	var values: Array[int] = []
	if run_state != null:
		for die in run_state.dice:
			if die == null:
				continue
			for pip in DieState.get_legal_pips(die.face_count):
				if not values.has(pip):
					values.append(pip)
	if values.is_empty():
		values.append_array([1, 2, 3, 4, 5, 6])
	values.sort()
	return values[rng.randi_range(0, values.size() - 1)]


func _random_legal_pip_for_roll(context: ScoreContext, roll: RolledFace) -> int:
	var face_count := 6
	var die: DieState = _source_die_for_roll(context, roll)
	if die != null:
		face_count = die.face_count
	var pips := DieState.get_legal_pips(face_count)
	return pips[_randi_range(context, 0, pips.size() - 1)]


func _source_die_for_roll(context: ScoreContext, roll: RolledFace):
	if roll == null:
		return null
	if context != null and roll.die_index >= 0 and roll.die_index < context.source_dice.size():
		return context.source_dice[roll.die_index]
	if context != null and context.run_state != null and roll.die_index >= 0 and roll.die_index < context.run_state.dice.size():
		return context.run_state.dice[roll.die_index]
	return roll.die


func _face_entry_from_ref(run_state, ref: Dictionary) -> Dictionary:
	if run_state == null:
		return {"valid": false}
	var die_index := int(ref.get("die_index", -1))
	var face_index := int(ref.get("face_index", -1))
	if die_index < 0 or die_index >= run_state.dice.size():
		return {"valid": false}
	var die: DieState = run_state.dice[die_index]
	if die == null or face_index < 0 or face_index >= die.faces.size():
		return {"valid": false}
	var face: FaceState = die.faces[face_index]
	if face == null:
		return {"valid": false}
	return {"valid": true, "die": die, "face": face, "die_index": die_index, "face_index": face_index}


func _reset_physical_face_for_roll(run_state, roll: RolledFace) -> bool:
	var entry := _face_entry_from_ref(run_state, {"die_index": roll.die_index if roll != null else -1, "face_index": roll.face_index if roll != null else -1})
	if not bool(entry.get("valid", false)):
		return false
	var die: DieState = entry["die"]
	var face: FaceState = entry["face"]
	var pips := DieState.get_legal_pips(die.face_count)
	var before_face := face.clone()
	face.pip = pips[rng.randi_range(0, pips.size() - 1)]
	face.ornament_id = FaceState.ORN_NONE
	face.mark_id = FaceState.MARK_NONE
	face.material_id = &"none"
	on_face_changed(run_state, before_face, face, &"reset_face")
	return true


func _unscored_raw_pip_is_valid(roll: RolledFace, target_pip: int) -> bool:
	if roll == null or roll.face == null:
		return false
	if _effective_ornament_for_roll(roll, null) == FaceState.ORN_STONE:
		return false
	return roll.face.pip == target_pip


func _unscored_raw_high_is_valid(roll: RolledFace) -> bool:
	if roll == null or roll.face == null:
		return false
	if _effective_ornament_for_roll(roll, null) == FaceState.ORN_STONE:
		return false
	return is_high_pip(roll.face.pip)


func _count_high_rolls_for_reroll(run_state, rolls: Array) -> int:
	var count := 0
	var all_high := _has_tool(run_state, DiceToolCatalog.TOOL_ALL_FACES_HIGH_FOR_TOOLS)
	for roll in rolls:
		if roll == null or roll.face == null:
			continue
		if _effective_ornament_for_roll(roll, null) == FaceState.ORN_STONE:
			continue
		if all_high or is_high_pip(roll.face.pip):
			count += 1
	return count


func _has_tool(run_state, tool_id: StringName) -> bool:
	for tool in _tools_for_run(run_state):
		if tool != null and tool.tool_id == tool_id:
			return true
	return false


func _generate_forge_item_for_score(context: ScoreContext, result: ScoreResult, tool: DiceToolState, _advanced: bool, reason: String) -> void:
	if _free_item_slots(context) <= 0:
		_log_tool(result, tool, "%s，但道具槽位不足。" % [reason])
		return
	var item_id := reward_generator.roll_random_formal_forge_item()
	if item_id == &"":
		_log_tool(result, tool, "%s，但没有可生成的铸骰件。" % [reason])
		return
	if _add_item(context, item_id):
		_log_tool(result, tool, "%s，生成 %s。" % [reason, ForgeItemCatalog.display_name_for_id(item_id)])


func _generate_common_tool_items(run_state, count: int) -> Array[String]:
	var names: Array[String] = []
	if run_state == null:
		return names
	var pool := DiceToolCatalog.get_item_pool_for_rarity(&"common")
	var free_slots: int = run_state.get_free_item_slot_count()
	var generated_count: int = min(count, free_slots)
	for _i in range(generated_count):
		if pool.is_empty():
			break
		var tool_data: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		var item: ItemInstance = ItemInstance.create_dice_tool(
			StringName(str(tool_data.get("id", &""))),
			str(tool_data.get("name", "")),
			int(tool_data.get("sell_value", 0))
		)
		item.metadata["rarity"] = StringName(str(tool_data.get("rarity", &"common")))
		if run_state.add_item_instance_to_slots(item):
			names.append(item.display_name)
	return names


func _destroy_random_other_tool(run_state, source_tool: DiceToolState) -> String:
	var candidates: Array[DiceToolState] = []
	for tool in _tools_for_run(run_state):
		if tool != null and tool != source_tool:
			candidates.append(tool)
	if candidates.is_empty():
		return ""
	var target: DiceToolState = candidates[rng.randi_range(0, candidates.size() - 1)]
	var name := _tool_name(target)
	_destroy_tool(run_state, target, null, "")
	return name


func _destroy_tool(run_state, target_tool: DiceToolState, result: ScoreResult = null, reason: String = "") -> bool:
	if run_state == null or target_tool == null:
		return false
	var tools := _tools_for_run(run_state)
	var index := tools.find(target_tool)
	if index < 0:
		return false
	if result != null and reason != "":
		_log_tool(result, target_tool, reason)
	tools.remove_at(index)
	run_state.installed_tools = tools
	return true


func _record_item_sale_for_campfire(run_state) -> Array[String]:
	var logs: Array[String] = []
	for tool in _tools_for_run(run_state):
		if tool == null or tool.tool_id != DiceToolCatalog.TOOL_CAMPFIRE_SALES:
			continue
		var sold_counter := _permanent_counter(tool, &"sold_item_counter", 0) + 1
		var xbonus := _permanent_counter(tool, &"xmult_bonus", 0)
		while sold_counter >= 4:
			sold_counter -= 4
			xbonus += 1
		tool.permanent_counters["sold_item_counter"] = sold_counter
		tool.permanent_counters["xmult_bonus"] = xbonus
		logs.append("[骰具] %s：出售物品计数剩余 %d，终倍率加成 %d。" % [_tool_name(tool), sold_counter, xbonus])
	return logs


func _copy_random_installed_tool_to_item_slot(run_state, excluded_tool: DiceToolState) -> String:
	if run_state == null or run_state.get_free_item_slot_count() <= 0:
		return ""
	var candidates: Array[DiceToolState] = []
	for tool in _tools_for_run(run_state):
		if tool != null and tool != excluded_tool:
			candidates.append(tool)
	if candidates.is_empty():
		return ""
	var source: DiceToolState = candidates[rng.randi_range(0, candidates.size() - 1)]
	var item: ItemInstance = ItemInstance.create_dice_tool(source.tool_id, _tool_name(source), max(0, source.sell_value))
	item.metadata["rarity"] = source.rarity
	if run_state.add_item_instance_to_slots(item):
		return item.display_name
	return ""


func _copy_random_held_forge_or_upgrade_item(run_state) -> String:
	if run_state == null or run_state.get_free_item_slot_count() <= 0:
		return ""
	var candidates: Array[ItemInstance] = []
	run_state.ensure_item_slots_from_legacy()
	for item in run_state.item_slots:
		if item == null:
			continue
		if item.item_type == ItemInstance.TYPE_FORGE_ITEM or item.item_type == ItemInstance.TYPE_COMBO_UPGRADE:
			candidates.append(item)
	if candidates.is_empty():
		return ""
	var source: ItemInstance = candidates[rng.randi_range(0, candidates.size() - 1)]
	var copied: ItemInstance = source.clone_as_new()
	if run_state.add_item_instance_to_slots(copied):
		return copied.display_name
	return ""


func _resolve_copy_target(run_state, source_index: int, direction: StringName) -> DiceToolState:
	var tools := _tools_for_run(run_state)
	if tools.is_empty():
		return null
	if direction == &"right":
		for index in range(source_index + 1, tools.size()):
			var right_tool: DiceToolState = tools[index]
			if right_tool != null and not _is_copy_tool(right_tool):
				return right_tool
		return null
	for index in range(tools.size()):
		if index == source_index:
			continue
		var left_tool: DiceToolState = tools[index]
		if left_tool != null and not _is_copy_tool(left_tool):
			return left_tool
	return null


func _is_copy_tool(tool: DiceToolState) -> bool:
	return tool != null and (
		tool.tool_id == DiceToolCatalog.TOOL_RIGHT_COPY_BLUEPRINT
		or tool.tool_id == DiceToolCatalog.TOOL_LEFT_COPY_BRAINSTORM
	)


func _make_marked_temp_face(next_index: int) -> RolledFace:
	var marks := [FaceState.MARK_RED, FaceState.MARK_BLUE, FaceState.MARK_PURPLE, FaceState.MARK_GOLD]
	var face := FaceState.new(rng.randi_range(1, 6), FaceState.ORN_NONE, marks[rng.randi_range(0, marks.size() - 1)])
	var roll := RolledFace.new()
	roll.set_roll(1000 + max(0, next_index), 0, face, null)
	roll.is_temporary = true
	return roll


func _random_idol_target(run_state) -> Dictionary:
	var pips: Array[int] = []
	var features: Array[StringName] = []
	if run_state != null:
		for die in run_state.dice:
			if die == null:
				continue
			for face in die.faces:
				if face == null:
					continue
				if not pips.has(face.pip):
					pips.append(face.pip)
				var ornament_id: StringName = face.get_effective_ornament_id()
				if ornament_id != FaceState.ORN_NONE and not features.has(ornament_id):
					features.append(ornament_id)
				var mark_id := FaceState.normalize_mark_id(face.mark_id)
				if mark_id != FaceState.MARK_NONE and not features.has(mark_id):
					features.append(mark_id)
	if pips.is_empty():
		pips.append_array([1, 2, 3, 4, 5, 6])
	if features.is_empty():
		return {"pip": pips[rng.randi_range(0, pips.size() - 1)], "feature": &""}
	return {
		"pip": pips[rng.randi_range(0, pips.size() - 1)],
		"feature": features[rng.randi_range(0, features.size() - 1)],
	}


func _slot_feature_name(feature_id: StringName) -> String:
	if str(feature_id).begins_with("orn_"):
		return DisplayNames.ornament_name(feature_id)
	if str(feature_id).begins_with("mark_"):
		return DisplayNames.mark_name(feature_id)
	return str(feature_id)


func _roll_has_slot_feature(roll: RolledFace, feature_id: StringName, context: ScoreContext = null) -> bool:
	if roll == null or roll.face == null:
		return false
	if str(feature_id).begins_with("orn_"):
		return _effective_ornament_for_roll(roll, context) == feature_id
	if str(feature_id).begins_with("mark_"):
		return FaceState.normalize_mark_id(roll.face.mark_id) == feature_id
	return false


func _count_reroll_pip_class(rolls: Array, class_id: StringName) -> int:
	var count := 0
	for roll in rolls:
		var pip = _effective_pip_for_reroll(roll)
		if pip != null and _pip_matches_ancient_class(int(pip), class_id):
			count += 1
	return count


func _count_reroll_pip(rolls: Array, target_pip: int) -> int:
	var count := 0
	for roll in rolls:
		var pip = _effective_pip_for_reroll(roll)
		if pip != null and int(pip) == target_pip:
			count += 1
	return count


func _effective_pip_for_reroll(roll) -> Variant:
	if roll == null or roll.face == null:
		return null
	if _effective_ornament_for_roll(roll, null) == FaceState.ORN_STONE:
		return null
	return roll.face.pip


func _highest_combo_for_rolls(run_state, selected_rolls: Array) -> StringName:
	var context := ScoreContext.new()
	var typed_rolls: Array[RolledFace] = []
	for roll in selected_rolls:
		if roll is RolledFace:
			typed_rolls.append(roll)
	context.selected_faces = typed_rolls
	context.scored_faces = typed_rolls
	context.all_rolled_faces = typed_rolls
	context.run_state = run_state
	context.source_dice = run_state.dice if run_state != null else []
	apply_rule_modifiers(context)
	var evaluator := ComboEvaluator.new()
	var resolution := evaluator.resolve(typed_rolls, typed_rolls, false, false, context)
	return ComboUpgradeCatalog.normalize_combo_id(StringName(str(resolution.get("primary_combo_id", ComboUpgradeCatalog.SCATTER))))


func _count_modified_permanent_faces(run_state) -> int:
	if run_state == null:
		return 0
	var count := 0
	for die in run_state.dice:
		if die == null:
			continue
		for face in die.faces:
			if face == null:
				continue
			if face.get_effective_ornament_id() != FaceState.ORN_NONE or FaceState.normalize_mark_id(face.mark_id) != FaceState.MARK_NONE:
				count += 1
	return count


func _item_id_from_any(value) -> StringName:
	if value == null:
		return &""
	if value is StringName:
		return value
	if value is String:
		return StringName(value)
	if value is ItemInstance:
		return value.item_id
	if value is Dictionary:
		return StringName(str(value.get("item_id", value.get("id", &""))))
	if value is Object:
		for property in value.get_property_list():
			var name := str(property.get("name", ""))
			if name == "item_id" or name == "id":
				return StringName(str(value.get(name)))
	return &""


func _item_type_from_any(value) -> StringName:
	if value == null:
		return &""
	if value is ItemInstance:
		return value.item_type
	if value is Dictionary:
		return StringName(str(value.get("item_type", value.get("type", &""))))
	if value is Object:
		for property in value.get_property_list():
			var name := str(property.get("name", ""))
			if name == "item_type" or name == "type":
				return StringName(str(value.get(name)))
	return &""


func _battle_was_boss_victory(run_state) -> bool:
	if run_state == null or run_state.current_battle == null:
		return false
	return run_state.current_battle.config.is_boss_battle and run_state.current_battle.victory


func _count_permanent_pip_faces(run_state, target_pip: int) -> int:
	if run_state == null:
		return 0
	var count := 0
	for die in run_state.dice:
		if die == null:
			continue
		for face in die.faces:
			if face != null and face.pip == target_pip:
				count += 1
	return count


func _apply_sell_value_growth(context: ScoreContext, result: ScoreResult, tool: DiceToolState) -> void:
	if context.run_state == null:
		return
	for installed in _tools_for_run(context.run_state):
		if installed != null:
			installed.sell_value += 1
	for item in context.run_state.item_slots:
		if item != null:
			item.sell_value += 1
	_log_tool(result, tool, "回合结束，所有已安装骰具与道具槽位中的道具卖价 +1。")


func _remaining_rerolls(context: ScoreContext) -> int:
	if context == null or context.battle_state == null:
		return 0
	return max(0, int(context.battle_state.config.rerolls_per_hand) - _rerolls_used(context))


func _rerolls_used(context: ScoreContext) -> int:
	if context == null:
		return 0
	if context.hand_state != null:
		return context.hand_state.rerolls_used
	return context.rerolls_used


func _is_final_round(context: ScoreContext) -> bool:
	if context == null:
		return false
	if context.is_last_hand:
		return true
	if context.battle_state == null or context.hand_state == null:
		return false
	return context.hand_state.hand_index >= max(0, context.battle_state.config.hands_per_battle - 1)


func _empty_regular_tool_slots(context: ScoreContext) -> int:
	if context == null or context.run_state == null:
		return 0
	if context.run_state.has_method("get_empty_regular_dice_tool_slot_count"):
		return context.run_state.get_empty_regular_dice_tool_slot_count()
	return 0


func _free_item_slots(context: ScoreContext) -> int:
	if context == null or context.run_state == null:
		return 0
	return context.run_state.get_free_item_slot_count()


func _count_selected_even(context: ScoreContext) -> int:
	var count := 0
	for pip in effective_pips_for_rolls(context.selected_faces, context):
		if is_even_pip(pip):
			count += 1
	return count


func _count_selected_odd(context: ScoreContext) -> int:
	var count := 0
	for pip in effective_pips_for_rolls(context.selected_faces, context):
		if is_odd_pip(pip):
			count += 1
	return count


func _count_selected_low(context: ScoreContext) -> int:
	var count := 0
	for pip in effective_pips_for_rolls(context.selected_faces, context):
		if is_low_pip(pip):
			count += 1
	return count


func _count_selected_high_for_tools(context: ScoreContext) -> int:
	var count := 0
	for roll in context.selected_faces:
		var pip = get_effective_pip(roll, context)
		if pip != null and _is_high_for_tools(roll, int(pip), context):
			count += 1
	return count


func _count_selected_pip(context: ScoreContext, target_pip: int) -> int:
	return _selected_rolls_with_pip(context, target_pip).size()


func _selected_rolls_with_pip(context: ScoreContext, target_pip: int) -> Array[RolledFace]:
	var result: Array[RolledFace] = []
	for roll in context.selected_faces:
		var pip = get_effective_pip(roll, context)
		if pip != null and int(pip) == target_pip:
			result.append(roll)
	return result


func _count_selected_pips_in(context: ScoreContext, values: Array) -> int:
	var count := 0
	for pip in effective_pips_for_rolls(context.selected_faces, context):
		if values.has(pip):
			count += 1
	return count


func _is_high_for_tools(roll: RolledFace, pip: int, context: ScoreContext) -> bool:
	if context != null and context.all_faces_high_for_tools:
		return get_effective_pip(roll, context) != null
	return is_high_pip(pip)


func _count_faces_with_ornament(context: ScoreContext, ornament_id: StringName) -> int:
	var dice := []
	if context != null and not context.source_dice.is_empty():
		dice = context.source_dice
	elif context != null and context.run_state != null:
		dice = context.run_state.dice
	elif context != null and context.battle_state != null:
		dice = context.battle_state.dice
	var count := 0
	for die in dice:
		if die == null:
			continue
		for face in die.faces:
			if face != null and face.get_effective_ornament_id() == ornament_id:
				count += 1
	return count


func _randf(context: ScoreContext) -> float:
	if context != null and context.rng != null and context.rng.has_method("randf"):
		return float(context.rng.randf())
	return rng.randf()


func _randi_range(context: ScoreContext, from_value: int, to_value: int) -> int:
	if context != null and context.rng != null and context.rng.has_method("randi_range"):
		return int(context.rng.randi_range(from_value, to_value))
	var roll := _randf(context)
	return clampi(from_value + int(floor(roll * float(to_value - from_value + 1))), from_value, to_value)
