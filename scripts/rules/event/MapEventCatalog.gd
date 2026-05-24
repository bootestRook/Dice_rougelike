extends RefCounted
class_name MapEventCatalog


const TYPE_POSITIVE_REWARD := &"positive_reward"
const TYPE_TRADE := &"trade"
const TYPE_RISK := &"risk"
const TYPE_PENALTY := &"penalty"
const TYPE_MAP := &"map"
const TYPE_BOSS := &"boss"
const TYPE_BUILD := &"build"

const EVENT_TYPE_WEIGHTS := {
	TYPE_POSITIVE_REWARD: 25.0,
	TYPE_TRADE: 25.0,
	TYPE_RISK: 20.0,
	TYPE_PENALTY: 15.0,
	TYPE_MAP: 8.0,
	TYPE_BUILD: 7.0,
}

const EXTRA_EVENT_TYPE_WEIGHTS := {
	TYPE_BOSS: 5.0,
}

const FIRST_PROTECTED_ALLOWED_TYPES := [
	TYPE_POSITIVE_REWARD,
	TYPE_TRADE,
	TYPE_MAP,
	TYPE_BUILD,
]

const FIRST_PROTECTED_BANNED_TAGS := [
	&"high_risk",
	&"strong_penalty",
	&"boss_counter",
	&"sacrifice_relic",
	&"clear_face",
]


static func get_type_weights() -> Dictionary:
	return EVENT_TYPE_WEIGHTS.duplicate(true)


static func get_generator_type_weights() -> Dictionary:
	var result := EVENT_TYPE_WEIGHTS.duplicate(true)
	for key in EXTRA_EVENT_TYPE_WEIGHTS.keys():
		result[key] = EXTRA_EVENT_TYPE_WEIGHTS[key]
	return result


static func get_all_event_defs() -> Array[Dictionary]:
	return _event_defs().duplicate(true)


static func get_event_count() -> int:
	return _event_defs().size()


static func get_event_def(event_id: StringName) -> Dictionary:
	for event_def in _event_defs():
		if StringName(str(event_def.get("id", &""))) == event_id:
			return event_def.duplicate(true)
	return {}


static func get_eligible_event_defs(circle: int, first_protected_segment: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_def in _event_defs():
		var min_circle := int(event_def.get("min_circle", 1))
		var max_circle := int(event_def.get("max_circle", 8))
		if circle < min_circle or circle > max_circle:
			continue
		if first_protected_segment:
			if not bool(event_def.get("first_circle_allowed", false)):
				continue
			if get_available_options(event_def, true).is_empty():
				continue
		result.append(event_def.duplicate(true))
	return result


static func get_available_options(event_def: Dictionary, first_protected_segment: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for option_any in event_def.get("options", []):
		var option := Dictionary(option_any).duplicate(true)
		if first_protected_segment:
			if not bool(option.get("first_protected_allowed", false)):
				continue
			if _has_any_tag(option.get("tags", []), FIRST_PROTECTED_BANNED_TAGS):
				continue
		result.append(option)
	return result


static func event_weight_for_circle(event_def: Dictionary, circle: int) -> float:
	var base_weight := float(event_def.get("weight", 1.0))
	if circle <= 2:
		return base_weight * float(event_def.get("early_weight_multiplier", 1.0))
	if circle <= 5:
		return base_weight * float(event_def.get("mid_weight_multiplier", 1.0))
	return base_weight * float(event_def.get("late_weight_multiplier", 1.0))


static func _has_any_tag(tags: Array, banned_tags: Array) -> bool:
	for tag in tags:
		if banned_tags.has(StringName(str(tag))):
			return true
	return false


static func _event_defs() -> Array[Dictionary]:
	return [
		_event(&"event_roadside_dice_box", "路边骰匣", TYPE_POSITIVE_REWARD, "安全奖励", 1, 8, true, "路边的尘土里躺着一个木制骰匣。锁扣已经断裂，里面传来几枚骰片轻轻碰撞的声音。\n没有人看守，也没有陷阱。至少看起来如此。", "", [
			_option(&"take_pips", "翻找点数片", "随机展示 3 个点数片，从中选择 1 个，立即安装到一个骰面。", &"grant_forge_piece", "随机获得 1 个点数片，随后选择骰面安装。", {"pool": &"pip"}, &"common", [&"positive_reward", &"forge_piece"]),
			_option(&"take_basic_ornament", "挑选面饰片", "随机展示 3 个基础面饰，从中选择 1 个，立即安装到一个骰面。", &"grant_forge_piece", "随机获得 1 个基础面饰片，随后选择骰面安装。", {"pool": &"basic_ornament"}, &"common", [&"positive_reward", &"forge_piece"]),
			_option(&"take_coins", "拿走钱袋", "获得 5 金币。", &"gain_coins", "获得 5 金币。", {"amount": 5}, &"common", [&"positive_reward", &"coins"]),
			_option(&"leave", "离开", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 1.25, 0.85),
		_event(&"event_broken_supply_cart", "破旧补给车", TYPE_POSITIVE_REWARD, "奖励 / 轻风险", 1, 8, true, "一辆补给车侧翻在路边，车轮还在缓慢转动。\n车厢外散落着几枚金币，更深处似乎还有东西，但木板已经开始吱呀作响。", "", [
			_option(&"shallow_search", "搜索浅层", "获得 4 金币。", &"gain_coins", "获得 4 金币。", {"amount": 4}, &"common", [&"positive_reward", &"coins"]),
			_option(&"search_crate", "打开货箱", "获得 1 个随机普通骰面奖励，立即安装。", &"grant_forge_piece", "随机获得 1 个普通骰面奖励，随后选择骰面安装。", {"pool": &"common_face"}, &"common", [&"positive_reward", &"forge_piece"]),
			_option(&"deep_search", "翻到底层", "获得 1 个随机罕见骰面奖励；下一场战斗敌人目标分 +10%。", &"grant_forge_piece_with_next_battle_target", "随机获得 1 个罕见骰面奖励，随后选择骰面安装；下一场战斗目标分 +10%。", {"pool": &"rare_face", "target_multiplier": 1.10}, &"rare", [&"risk", &"forge_piece", &"battle_modifier"], false),
			_option(&"leave", "离开", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 1.2, 0.85),
		_event(&"event_gambler_cup", "赌徒骰盅", TYPE_RISK, "风险赌局", 1, 8, false, "一个戴着宽檐帽的赌徒坐在石桌旁，指尖压着倒扣的骰盅。\n他没有抬头，只把另一只手伸向你，掌心朝上。", "小赌怡情，大赌改命。不赌也行，只是别后悔。", [
			_option(&"small_bet", "小赌一把：3 金币", "支付 3 金币；75% 获得 1 个普通骰面奖励，25% 无事发生。", &"gamble_forge_piece", "支付 3 金币；75% 获得 1 个普通骰面奖励，25% 无事发生。", {"cost": 3, "chance": 0.75, "pool": &"common_face"}, &"uncommon", [&"risk", &"forge_piece", &"coins"], false),
			_option(&"big_bet", "豪赌一局：7 金币", "支付 7 金币；50% 获得 1 个稀有骰面奖励，50% 下一场战斗每回合重投次数 -1。", &"gamble_forge_piece_with_failure_penalty", "支付 7 金币；50% 获得 1 个稀有骰面奖励，50% 下一场战斗每回合重投次数 -1。", {"cost": 7, "chance": 0.50, "pool": &"gambler_rare", "rerolls_delta": -1}, &"rare", [&"risk", &"battle_modifier"], false),
			_option(&"leave", "离开赌桌", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 0.45, 1.25),
		_event(&"event_traveling_carver", "游方雕刻师", TYPE_BUILD, "定向改造", 1, 8, true, "一个背着工具箱的雕刻师蹲在路旁，正在用小刀修整一枚裂开的骰子。\n他看了一眼你的骰子，露出职业性的嫌弃。", "能用，但很粗糙。给点钱，我能让它像个作品。", [
			_option(&"carve_pip", "雕刻点数：3 金币", "支付 3 金币；选择 1 个骰面，将点数改为指定的 1-6。", &"pay_for_forge_piece", "支付 3 金币；获得 1 个随机点数片，随后选择骰面安装。", {"cost": 3, "pool": &"pip"}, &"common", [&"build", &"forge_piece"], false),
			_option(&"polish_ornament", "打磨面饰：4 金币", "支付 4 金币；选择 1 个骰面，安装筹码面饰或倍率面饰。", &"pay_for_forge_piece", "支付 4 金币；获得筹码面饰或倍率面饰，随后选择骰面安装。", {"cost": 4, "pool": &"chip_mult_ornament"}, &"common", [&"build", &"forge_piece"]),
			_option(&"quick_repair", "随手修补", "免费；随机 1 个骰面点数 +1，超过 6 循环到 1。", &"random_pip_step", "随机 1 个骰面的点数 +1，超过 6 循环到 1。", {"amount": 1}, &"common", [&"build"]),
			_option(&"leave", "离开", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 1.1, 0.9),
		_event(&"event_golden_peddler", "金辉小贩", TYPE_TRADE, "经济交易", 2, 8, false, "一名小贩推着镀金的小车，车上挂满会反光的骰片。\n你还没开口，他已经开始数你的金币。", "金币生金币，骰子也懂这个道理。", [
			_option(&"buy_gold_ornament", "购买金辉：5 金币", "支付 5 金币；选择 1 个骰面，安装金辉面饰。", &"pay_for_forge_piece", "支付 5 金币；获得金辉面饰片，随后选择骰面安装。", {"cost": 5, "pool": &"gold_ornament"}, &"uncommon", [&"trade", &"forge_piece"], false),
			_option(&"buy_gold_mark", "购买金印：8 金币", "支付 8 金币；选择 1 个骰面，添加金印。", &"pay_for_forge_piece", "支付 8 金币；获得金印片，随后选择骰面安装。", {"cost": 8, "pool": &"gold_mark"}, &"rare", [&"trade", &"forge_piece"], false),
			_option(&"sell_luck", "出售运气", "获得 10 金币；下一场战斗每回合重投次数 -1。", &"gain_coins_next_battle_rerolls", "获得 10 金币；下一场战斗每回合重投次数 -1。", {"amount": 10, "rerolls_delta": -1}, &"uncommon", [&"trade", &"battle_modifier"], false),
			_option(&"leave", "离开", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		]),
		_event(&"event_dead_roller", "死去的投骰者", TYPE_RISK, "遗物风险奖励", 1, 8, true, "一个投骰者倒在路边，手里还攥着半枚破碎的骰子。\n他的遗物袋没有完全合上，里面似乎还有能用的东西。", "", [
			_option(&"search_pouch", "翻找钱袋", "获得 6 金币。", &"gain_coins", "获得 6 金币。", {"amount": 6}, &"common", [&"positive_reward", &"coins"]),
			_option(&"take_tool", "拿走遗物", "获得 1 个普通骰具遗物；下一场战斗敌人目标分 +15%。", &"grant_dice_tool_with_next_battle_target", "获得 1 个普通骰具遗物；下一场战斗目标分 +15%。", {"rarity": &"common", "target_multiplier": 1.15}, &"uncommon", [&"risk", &"dice_tool", &"battle_modifier"]),
			_option(&"deep_dig", "深挖遗物", "从 3 个罕见骰具遗物中选择 1 个；随后立即触发一场普通战斗。", &"grant_dice_tool_start_battle", "获得 1 个罕见骰具遗物；随后立即触发一场普通战斗。", {"rarity": &"rare"}, &"rare", [&"high_risk", &"dice_tool", &"battle_modifier"], false),
			_option(&"leave", "离开尸体", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 1.0, 1.0),
		_event(&"event_mirror_well", "镜面水井", TYPE_TRADE, "复制 / 改造", 2, 8, false, "一口井的水面光滑得像镜子。你低头看去，倒影里的骰面排列与现实并不一致。\n井底传来细碎的回声，像是在重复你刚刚想到的东西。", "", [
			_option(&"mirror_pip", "照见点数", "选择 1 个来源骰面和 1 个目标骰面；目标复制来源点数。", &"gain_forge_item", "获得 1 个回炉点数道具，用于后续点数改造。", {"item_id": &"forge_pip_up"}, &"common", [&"trade", &"copy"], false),
			_option(&"mirror_ornament", "照见面饰：5 金币", "支付 5 金币；目标复制来源面饰，不复制点数和印记。", &"pay_for_forge_item", "支付 5 金币；获得 1 个面饰铸骰道具。", {"cost": 5, "item_id": &"forge_lucky_ornament"}, &"uncommon", [&"trade", &"copy"], false),
			_option(&"full_reflection", "照见完整倒影：10 金币", "支付 10 金币；目标复制来源点数、面饰、印记；之后来源骰面清空面饰。", &"pay_for_forge_item", "支付 10 金币；获得 1 个骰面复制道具。", {"cost": 10, "item_id": &"forge_face_copy"}, &"epic", [&"trade", &"copy"], false),
			_option(&"leave", "离开水井", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 0.7, 1.15),
		_event(&"event_white_mark_abbey", "白印修道院", TYPE_BOSS, "首领对策", 3, 8, false, "白色石墙围成一座沉默的修道院。门前的修士没有影子，手里握着一枚无色印记。\n他的声音很轻，却像是直接落在骰面上。", "有些规则不能打破，只能被暂时忘记。", [
			_option(&"pray_protection", "祈求庇护：6 金币", "支付 6 金币；选择 1 个骰面，添加白印。", &"pay_for_forge_piece", "支付 6 金币；获得白印片，随后选择骰面安装。", {"cost": 6, "pool": &"white_mark"}, &"rare", [&"boss", &"forge_piece"], false),
			_option(&"listen_prophecy", "倾听预言", "显示本圈 Boss 规则。", &"set_run_flag", "记录本圈首领情报已查看。", {"flag": &"boss_rule_previewed"}, &"common", [&"boss", &"map"], false),
			_option(&"refuse_ritual", "拒绝仪式", "获得 4 金币；本圈 Boss 战目标分 +10%。", &"gain_coins_boss_target_multiplier", "获得 4 金币；本圈首领战目标分 +10%。", {"amount": 4, "boss_multiplier": 1.10}, &"uncommon", [&"boss", &"battle_modifier"], false),
			_option(&"leave", "离开", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 0.45, 1.35),
		_event(&"event_old_map_fragment", "旧地图残片", TYPE_MAP, "地图情报 / 路线操控", 1, 8, true, "你在石缝里发现一张破旧地图。上面的路线正在缓慢变化，仿佛有人刚刚擦掉了某些格子。\n墨迹还未干透。", "", [
			_option(&"preview_path", "查看前路", "显示未来 8 格节点类型。", &"set_run_flag", "记录未来 8 格节点情报已查看。", {"flag": &"map_preview_8"}, &"common", [&"map"]),
			_option(&"mark_landing", "标记落点", "下一次投掷前，显示 1D6 和 2D6 的所有可能落点。", &"set_run_flag", "记录下次地图投掷落点情报。", {"flag": &"landing_preview"}, &"common", [&"map"]),
			_option(&"redraw_one", "重画一格：4 金币", "支付 4 金币；选择未来 6 格中的 1 个非固定节点重随机。", &"pay_for_run_flag", "支付 4 金币；记录一次未来节点重画机会。", {"cost": 4, "flag": &"map_redraw_charge"}, &"uncommon", [&"map"], false),
			_option(&"leave", "收起地图", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 1.0, 0.9),
		_event(&"event_black_dice_taxman", "黑骰税吏", TYPE_PENALTY, "轻惩罚 / 规避", 2, 8, false, "一个穿黑制服的人挡在路中间，胸前挂着一枚六面的徽章。\n他摊开账本，上面已经写好了你的名字。", "每一次运气，都应缴税。", [
			_option(&"pay_tax", "缴税：6 金币", "失去 6 金币。", &"pay_coins", "失去 6 金币。", {"cost": 6}, &"common", [&"penalty", &"coins"], false),
			_option(&"pawn_tool", "抵押遗物", "失去 1 个普通或罕见骰具遗物，获得 8 金币。", &"sell_dice_tool", "失去 1 个骰具遗物，获得 8 金币。", {"amount": 8}, &"uncommon", [&"penalty", &"dice_tool"], false),
			_option(&"refuse_tax", "拒缴", "下一场战斗每回合重投次数 -1；战斗胜利后获得 4 金币。", &"gain_coins_next_battle_rerolls", "获得 4 金币；下一场战斗每回合重投次数 -1。", {"amount": 4, "rerolls_delta": -1}, &"uncommon", [&"penalty", &"battle_modifier"], false),
		], 0.55, 1.15),
		_event(&"event_silent_belltower", "静默钟楼", TYPE_RISK, "高风险奖励", 3, 8, false, "一座没有入口的钟楼立在雾中。钟绳垂到地面，绳尾沾着干涸的金粉。\n你还没碰到它，耳边就已经响起了钟声。", "", [
			_option(&"ring_once", "敲响一次", "获得 1 个稀有骰面奖励；下一场战斗随机禁用 1 个面饰。", &"grant_forge_piece_disable_ornament", "随机获得 1 个稀有骰面奖励；下一场战斗随机禁用 1 个面饰。", {"pool": &"rare_face", "disabled_ornament_count": 1}, &"rare", [&"risk", &"forge_piece", &"battle_modifier"], false),
			_option(&"ring_thrice", "敲响三次", "从 3 个稀有骰具遗物中选择 1 个；下一场战斗可结算回合数 -1。", &"grant_dice_tool_next_battle_hands", "获得 1 个稀有骰具遗物；下一场战斗可结算回合数 -1。", {"rarity": &"rare", "hands_delta": -1}, &"rare", [&"high_risk", &"dice_tool", &"battle_modifier"], false),
			_option(&"do_not_ring", "不敲钟", "获得 3 金币。", &"gain_coins", "获得 3 金币。", {"amount": 3}, &"common", [&"risk", &"coins"], false),
		], 0.35, 1.45),
		_event(&"event_tricolor_dice_gate", "三色骰扉", TYPE_POSITIVE_REWARD, "方向选择", 1, 8, true, "三扇窄扉并排立在路上。红扉发热，蓝扉结霜，金扉后传来金币滚动的声音。\n每扇窄扉都只够伸进一只手。", "", [
			_option(&"red_gate", "推开红扉", "从红印、爆裂面饰、爆裂复合件中随机展示 3 个，选择 1 个。", &"grant_forge_piece", "从红印、爆裂面饰、爆裂复合件中随机获得 1 个。", {"pool": &"red_gate"}, &"uncommon", [&"positive_reward", &"forge_piece"], true, {"pool": &"red_gate_low"}),
			_option(&"blue_gate", "推开蓝扉", "从蓝印、留场面饰、留场复合件中随机展示 3 个，选择 1 个。", &"grant_forge_piece", "从蓝印、留场面饰、留场复合件中随机获得 1 个。", {"pool": &"blue_gate"}, &"uncommon", [&"positive_reward", &"forge_piece"], true, {"pool": &"blue_gate_low"}),
			_option(&"gold_gate", "推开金扉", "从金印、金辉面饰、金币奖励中随机展示 3 个，选择 1 个。", &"grant_forge_piece_or_coins", "获得金印、金辉面饰或金币奖励。", {"pool": &"gold_gate", "coins": 6}, &"uncommon", [&"positive_reward", &"forge_piece", &"coins"], true, {"pool": &"gold_gate_low", "coins": 6}),
			_option(&"leave", "绕过三扉", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 1.0, 0.9),
		_event(&"event_astral_board", "星象棋盘", TYPE_MAP, "地图操控", 2, 8, false, "一张巨大的棋盘浮在空中，棋子都是你刚刚经过的地图格。\n每当你眨眼，几个格子的位置就会交换。", "", [
			_option(&"adjust_stars", "调整星位", "选择未来 6 格中的 2 个非固定节点，交换位置。", &"set_run_flag", "记录一次未来节点交换机会。", {"flag": &"map_swap_charge"}, &"uncommon", [&"map"], false),
			_option(&"delay_danger", "推迟危险", "选择未来 6 格中的 1 个 elite，将其重随机为 battle；本圈下一个 battle 目标分 +10%。", &"set_run_flag", "记录一次精英节点降级机会；下一场普通战目标分 +10%。", {"flag": &"elite_delay_charge", "next_battle_target_multiplier": 1.10}, &"uncommon", [&"map", &"battle_modifier"], false),
			_option(&"focus_chance", "聚焦机遇：5 金币", "支付 5 金币；选择未来 6 格中的 1 个节点，重随机为 event。", &"pay_for_run_flag", "支付 5 金币；记录一次未来节点改为奇遇的机会。", {"cost": 5, "flag": &"map_event_focus_charge"}, &"uncommon", [&"map"], false),
			_option(&"leave", "离开棋盘", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 0.75, 1.25),
		_event(&"event_lost_apprentice", "迷路的学徒", TYPE_BUILD, "主骰型成长", 1, 8, true, "一个年轻学徒抱着厚厚的骰谱站在岔路口，显然已经迷路很久。\n他看见你的骰子，眼睛立刻亮了起来。", "能不能教我一次？我会把我刚学会的也告诉你。", [
			_option(&"teach_loose", "教他基础构型", "散点或一对等级 +1，二选一。", &"combo_upgrade_pool", "散点或一对等级 +1。", {"combos": [&"scatter", &"pair"], "amount": 1}, &"common", [&"build", &"combo"]),
			_option(&"teach_shape", "教他常用构型", "从本局最常结算的 3 个主骰型中选择 1 个，等级 +1。", &"combo_upgrade_most_scored", "本局最常结算的主骰型等级 +1；记录不足时随机。", {"amount": 1}, &"uncommon", [&"build", &"combo"]),
			_option(&"let_try", "让他自行试错", "随机主骰型等级 +2；下一场战斗敌人目标分 +10%。", &"combo_upgrade_random_next_battle_target", "随机主骰型等级 +2；下一场战斗目标分 +10%。", {"amount": 2, "target_multiplier": 1.10}, &"rare", [&"build", &"risk", &"battle_modifier"], false),
			_option(&"leave", "让他继续迷路", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 1.1, 0.8),
		_event(&"event_rgb_altar", "红蓝紫祭坛", TYPE_TRADE, "印记定向", 3, 8, false, "三枚印记悬在祭坛上空。红色脉动，蓝色低鸣，紫色像一只半睁的眼。\n祭坛下方刻着一行字：选择会留下痕迹。", "", [
			_option(&"red_rite", "红色祭礼：8 金币", "支付 8 金币；选择 1 个骰面，添加红印。", &"pay_for_forge_piece", "支付 8 金币；获得红印片，随后选择骰面安装。", {"cost": 8, "pool": &"red_mark"}, &"rare", [&"trade", &"forge_piece"], false),
			_option(&"blue_rite", "蓝色祭礼：8 金币", "支付 8 金币；选择 1 个骰面，添加蓝印。", &"pay_for_forge_piece", "支付 8 金币；获得蓝印片，随后选择骰面安装。", {"cost": 8, "pool": &"blue_mark"}, &"rare", [&"trade", &"forge_piece"], false),
			_option(&"purple_rite", "紫色祭礼：8 金币", "支付 8 金币；选择 1 个骰面，添加紫印。", &"pay_for_forge_piece", "支付 8 金币；获得紫印片，随后选择骰面安装。", {"cost": 8, "pool": &"purple_mark"}, &"rare", [&"trade", &"forge_piece"], false),
			_option(&"offer_all", "献上全部金币", "失去所有金币；随机获得 1 个红印 / 蓝印 / 紫印复合件。", &"pay_all_for_forge_piece", "失去所有金币；随机获得 1 个红印 / 蓝印 / 紫印复合件。", {"min_coins": 10, "pool": &"rgb_composite"}, &"rare", [&"trade", &"forge_piece"], false),
		], 0.4, 1.3),
		_event(&"event_cracked_floor", "裂纹地板", TYPE_PENALTY, "惩罚 / 风险交换", 2, 8, false, "前方的地面布满细小裂纹。裂缝之间有骰面碎片闪光，像是有人故意把奖励埋在危险下面。\n每一步都会让裂缝扩大。", "", [
			_option(&"walk_around", "小心绕过：4 金币", "支付 4 金币，安全通过。", &"pay_coins", "支付 4 金币。", {"cost": 4}, &"common", [&"penalty", &"coins"], false),
			_option(&"force_cross", "强行通过", "随机 1 个普通骰面清空面饰；获得 1 个随机罕见骰面奖励。", &"clear_random_ornament_gain_piece", "随机清空 1 个普通骰面的面饰；随机获得 1 个罕见骰面奖励。", {"pool": &"rare_face"}, &"rare", [&"penalty", &"clear_face", &"forge_piece"], false),
			_option(&"observe", "停下观察", "下一场战斗每回合重投次数 -1；获得 5 金币。", &"gain_coins_next_battle_rerolls", "获得 5 金币；下一场战斗每回合重投次数 -1。", {"amount": 5, "rerolls_delta": -1}, &"uncommon", [&"penalty", &"battle_modifier"], false),
		], 0.45, 1.25),
		_event(&"event_caravan_echo", "商队残影", TYPE_MAP, "商店强化", 2, 8, false, "一支半透明的商队从你面前经过。马车里空无一物，却落下了几张价格标签。\n标签上的数字还在变化。", "", [
			_option(&"coupon", "捡起优惠券", "下一个 shop 中第一个商店骰包 -50%。", &"set_shop_modifier", "下一个商店中第一个骰包 -50%。", {"key": &"first_booster_discount", "value": 0.5}, &"uncommon", [&"map", &"shop"], false),
			_option(&"shelf_blueprint", "捡起货架图纸", "下一个 shop 中遗物货架额外 +1；但该商店刷新费用 +2。", &"set_shop_modifier", "下一个商店遗物货架额外 +1；刷新费用 +2。", {"key": &"extra_relic_shelf", "value": 1, "reroll_cost_delta": 2}, &"uncommon", [&"map", &"shop"], false),
			_option(&"fake_coin", "捡起假币", "获得 8 金币；下一个 shop 中所有价格 +25%。", &"gain_coins_set_shop_modifier", "获得 8 金币；下一个商店所有价格 +25%。", {"amount": 8, "key": &"price_multiplier", "value": 1.25}, &"uncommon", [&"risk", &"shop"], false),
			_option(&"leave", "无视残影", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		]),
		_event(&"event_whispering_statue", "低语石像", TYPE_BUILD, "构筑定向", 1, 8, true, "一座没有面孔的石像立在路边。靠近时，你听见它在重复你最近打出的骰型。\n它并不说话，但你知道它在等待一个问题。", "", [
			_option(&"ask_same", "询问同点", "从一对、三同、四同、五同升级中随机展示 3 个，选择 1 个等级 +1。", &"combo_upgrade_pool", "从一对、三同、四同、五同中随机 1 个等级 +1。", {"combos": [&"pair", &"three_kind", &"four_kind", &"five_kind"], "amount": 1}, &"uncommon", [&"build", &"combo"]),
			_option(&"ask_straight", "询问顺列", "顺子等级 +1，并获得 1 个随机缺失点数片候选。", &"combo_upgrade_and_piece", "顺子等级 +1，并随机获得 1 个当前较少的点数片。", {"combo": &"straight", "amount": 1, "pool": &"missing_pip"}, &"uncommon", [&"build", &"combo", &"forge_piece"]),
			_option(&"ask_scatter", "询问散落", "散点等级 +1，并获得 4 金币。", &"combo_upgrade_gain_coins", "散点等级 +1，并获得 4 金币。", {"combo": &"scatter", "amount": 1, "coins": 4}, &"common", [&"build", &"combo", &"coins"]),
			_option(&"leave", "保持沉默", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 1.05, 0.85),
		_event(&"event_empty_relic_case", "空遗物匣", TYPE_TRADE, "遗物交易", 2, 8, false, "一个空的遗物匣躺在石台上，内部铺着柔软的黑布。\n匣子没有锁，但你感觉它不会白白打开。", "", [
			_option(&"insert_coins", "装入金币：8 金币", "支付 8 金币；获得 1 个普通骰具遗物。", &"pay_for_dice_tool", "支付 8 金币；获得 1 个普通骰具遗物。", {"cost": 8, "rarity": &"common"}, &"uncommon", [&"trade", &"dice_tool"], false),
			_option(&"insert_old_tool", "装入旧物", "出售 1 个已拥有的普通或罕见遗物；从 3 个罕见遗物中选择 1 个。", &"replace_dice_tool", "失去 1 个骰具遗物；获得 1 个罕见骰具遗物。", {"rarity": &"rare"}, &"rare", [&"trade", &"dice_tool"], false),
			_option(&"break_case", "打碎匣子", "获得 5 金币；下一场战斗敌人目标分 +10%。", &"gain_coins_next_battle_target", "获得 5 金币；下一场战斗目标分 +10%。", {"amount": 5, "target_multiplier": 1.10}, &"uncommon", [&"risk", &"battle_modifier"], false),
			_option(&"leave", "离开", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		]),
		_event(&"event_polychrome_rift", "幻彩裂隙", TYPE_RISK, "高风险高收益", 4, 8, false, "空气中裂开一道彩色伤口。裂隙另一边没有道路，只有不断翻面的骰子。\n你越靠近，骰面上的颜色越鲜艳，也越不稳定。", "", [
			_option(&"touch", "伸手触碰", "选择 1 个骰面，随机安装箔光强化或幻彩强化。", &"grant_forge_piece", "随机获得箔光强化或幻彩强化，随后选择骰面安装。", {"pool": &"foil_holo"}, &"rare", [&"risk", &"forge_piece"], false),
			_option(&"enter_rift", "深入裂隙", "选择 1 个骰面，安装多彩强化；同一颗骰子的其他所有骰面清空面饰。", &"grant_forge_piece_with_random_clear", "获得多彩强化；随机清空同一颗骰子的其他面饰。", {"pool": &"poly_ornament"}, &"epic", [&"high_risk", &"clear_face", &"forge_piece"], false),
			_option(&"close_rift", "封闭裂隙", "获得 6 金币。", &"gain_coins", "获得 6 金币。", {"amount": 6}, &"common", [&"risk", &"coins"], false),
			_option(&"leave", "后退", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 0.25, 1.55),
		_event(&"event_broken_crown", "断裂的王冠", TYPE_BOSS, "首领对策 / 代价交换", 3, 8, false, "一顶断裂的王冠被插在路中央。王冠内侧刻着历代首领的名字。\n当你靠近时，其中一个名字被划掉了。", "", [
			_option(&"wear_crown", "戴上王冠", "本圈 Boss 战目标分 -15%；本圈剩余普通/精英战斗目标分 +10%。", &"set_circle_target_modifiers", "本圈首领战目标分 -15%；本圈剩余普通/精英战斗目标分 +10%。", {"boss_multiplier": 0.85, "non_boss_multiplier": 1.10}, &"rare", [&"boss", &"battle_modifier"], false),
			_option(&"break_crown", "折断王冠", "获得 1 个白印；失去 6 金币。", &"pay_for_forge_piece", "支付 6 金币；获得白印片，随后选择骰面安装。", {"cost": 6, "pool": &"white_mark"}, &"rare", [&"boss", &"forge_piece"], false),
			_option(&"sell_fragments", "卖掉碎片", "获得 10 金币。", &"gain_coins", "获得 10 金币。", {"amount": 10}, &"common", [&"boss", &"coins"], false),
			_option(&"leave", "绕开", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 0.35, 1.45),
		_event(&"event_reroll_well", "重投井", TYPE_POSITIVE_REWARD, "战斗资源", 1, 8, true, "一口浅井旁堆满旧骰子。井水中偶尔冒出气泡，每个气泡里都映着一次没有发生的重投。\n井沿刻着一句话：投入越多，犹豫越多。", "", [
			_option(&"throw_two", "投入 2 金币", "下一场战斗每回合重投次数 +1。", &"pay_for_next_battle_rerolls", "支付 2 金币；下一场战斗每回合重投次数 +1。", {"cost": 2, "rerolls_delta": 1}, &"uncommon", [&"positive_reward", &"battle_modifier"]),
			_option(&"throw_six", "投入 6 金币", "接下来 2 场战斗每回合重投次数 +1。", &"pay_for_next_battle_rerolls", "支付 6 金币；接下来 2 场战斗每回合重投次数 +1。", {"cost": 6, "rerolls_delta": 1, "charges": 2}, &"rare", [&"positive_reward", &"battle_modifier"]),
			_option(&"take_water", "取一捧水", "获得 1 个随机普通点数片。", &"grant_forge_piece", "随机获得 1 个普通点数片，随后选择骰面安装。", {"pool": &"pip"}, &"common", [&"positive_reward", &"forge_piece"]),
			_option(&"leave", "离开", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 1.15, 0.75),
		_event(&"event_face_graveyard", "骰面墓园", TYPE_TRADE, "清理 / 回收", 2, 8, false, "无数废弃骰面插在泥土里，像一片小小的墓碑。\n有些墓碑还没完全沉下去，似乎还能换点东西。", "", [
			_option(&"bury_ornament", "埋葬面饰", "选择 1 个拥有面饰的骰面，清空其面饰；获得 5 金币。", &"clear_random_ornament_gain_coins", "随机清空 1 个非保护面饰；获得 5 金币。", {"amount": 5}, &"uncommon", [&"trade", &"clear_face", &"coins"], false),
			_option(&"bury_mark", "埋葬印记", "选择 1 个拥有印记的骰面，清空其印记；获得 7 金币。", &"clear_random_mark_gain_coins", "随机清空 1 个非保护印记；获得 7 金币。", {"amount": 7}, &"rare", [&"trade", &"clear_face", &"coins"], false),
			_option(&"dig_fragment", "挖出残片", "获得 1 个随机复合件；随机 1 个普通骰面点数变为 1。", &"grant_forge_piece_random_pip_to_one", "随机获得 1 个复合件；随机 1 个普通骰面点数变为 1。", {"pool": &"composite"}, &"rare", [&"risk", &"forge_piece"], false),
			_option(&"leave", "离开墓园", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		]),
		_event(&"event_symbol_storm", "符号风暴", TYPE_BUILD, "点数重构", 2, 8, false, "一阵由点数符号组成的风暴卷过道路。奇数、偶数、高点和低点在风中互相撞碎。\n伸手进去，也许能抓住想要的形状。", "", [
			_option(&"chase_odd", "追逐奇数", "最多 3 个随机骰面改为合法奇数点数。", &"randomize_pips", "最多 3 个随机骰面改为 1 / 3 / 5。", {"count": 3, "pool": [1, 3, 5]}, &"uncommon", [&"build"], false),
			_option(&"chase_even", "追逐偶数", "最多 3 个随机骰面改为合法偶数点数。", &"randomize_pips", "最多 3 个随机骰面改为 2 / 4 / 6。", {"count": 3, "pool": [2, 4, 6]}, &"uncommon", [&"build"], false),
			_option(&"chase_high", "追逐高点", "最多 2 个随机骰面改为 4 / 5 / 6；下一场战斗敌人目标分 +10%。", &"randomize_pips_next_battle_target", "最多 2 个随机骰面改为 4 / 5 / 6；下一场战斗目标分 +10%。", {"count": 2, "pool": [4, 5, 6], "target_multiplier": 1.10}, &"rare", [&"build", &"battle_modifier"], false),
			_option(&"chase_low", "追逐低点", "最多 2 个随机骰面改为 1 / 2 / 3；获得 4 金币。", &"randomize_pips_gain_coins", "最多 2 个随机骰面改为 1 / 2 / 3；获得 4 金币。", {"count": 2, "pool": [1, 2, 3], "amount": 4}, &"uncommon", [&"build", &"coins"], false),
		], 0.7, 1.1),
		_event(&"event_cursed_money_bag", "诅咒钱袋", TYPE_RISK, "经济风险", 1, 8, true, "一个鼓鼓的钱袋挂在枯树枝上，袋口自己一张一合，像是在呼吸。\n金币的声音很清脆，但袋子底部渗出黑色的灰。", "", [
			_option(&"take_some", "拿少量", "获得 6 金币。", &"gain_coins", "获得 6 金币。", {"amount": 6}, &"common", [&"positive_reward", &"coins"]),
			_option(&"take_all", "拿全部", "获得 15 金币；下一场战斗随机 1 个骰面不可被选择结算。", &"gain_coins_next_battle_disabled_score_die", "获得 15 金币；下一场战斗随机 1 个骰面不可被选择结算。", {"amount": 15, "disabled_score_die_count": 1}, &"rare", [&"risk", &"strong_penalty"], false),
			_option(&"return_bag", "归还钱袋", "下一次 shop 的刷新费用 -3，最低 1。", &"set_shop_modifier", "下一次商店刷新费用 -3，最低 1。", {"key": &"reroll_cost_delta", "value": -3}, &"common", [&"positive_reward", &"shop"]),
			_option(&"leave", "离开", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 0.9, 0.9),
		_event(&"event_fog_storyteller", "迷雾讲述者", TYPE_BUILD, "方向选择 / 未来事件倾向", 1, 8, true, "雾中坐着一个讲述者。他面前没有书，只有几枚不停滚动的骰子。\n每次骰子停下，他就讲出一段你还没经历过的故事。", "财富、战斗，或命运。你要先听哪一个？", [
			_option(&"wealth_story", "听财富故事", "获得金印或金辉面饰候选，2 选 1。", &"grant_forge_piece", "随机获得金印或金辉面饰。", {"pool": &"wealth_story"}, &"uncommon", [&"build", &"forge_piece"]),
			_option(&"battle_story", "听战斗故事", "从筹码、倍率、爆裂、留场中随机展示 3 个，选择 1 个。", &"grant_forge_piece", "随机获得筹码、倍率、爆裂或留场面饰。", {"pool": &"battle_story"}, &"common", [&"build", &"forge_piece"]),
			_option(&"fate_story", "听命运故事", "下一个 event 节点出现正向奖励事件的权重 +50%。", &"set_next_event_bias", "下一个奇遇节点出现正向奖励事件的权重 +50%。", {"bias": TYPE_POSITIVE_REWARD, "multiplier": 1.5}, &"uncommon", [&"build", &"map"]),
			_option(&"leave", "不听故事", "无事发生。", &"no_effect", "无事发生。", {}, &"common", []),
		], 1.0, 0.85),
	]


static func _event(
	id: StringName,
	name: String,
	event_type: StringName,
	type_display_name: String,
	min_circle: int,
	max_circle: int,
	first_circle_allowed: bool,
	scene_text: String,
	npc_text: String,
	options: Array,
	early_multiplier: float = 1.0,
	late_multiplier: float = 1.0
) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"type": event_type,
		"type_display_name": type_display_name,
		"min_circle": min_circle,
		"max_circle": max_circle,
		"first_circle_allowed": first_circle_allowed,
		"scene_text": scene_text,
		"npc_text": npc_text,
		"options": options,
		"weight": 1.0,
		"early_weight_multiplier": early_multiplier,
		"mid_weight_multiplier": 1.0,
		"late_weight_multiplier": late_multiplier,
	}


static func _option(
	id: StringName,
	label: String,
	description: String,
	effect_id: StringName,
	effect_text: String,
	args: Dictionary = {},
	rarity: StringName = &"common",
	tags: Array = [],
	first_protected_allowed: bool = true,
	first_protected_args: Dictionary = {}
) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"description": description,
		"effect_id": effect_id,
		"effect_text": effect_text,
		"args": args,
		"rarity": rarity,
		"tags": tags,
		"first_protected_allowed": first_protected_allowed,
		"first_protected_args": first_protected_args,
	}
