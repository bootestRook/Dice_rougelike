extends RefCounted
class_name DisplayNames


static func combo_name(id: StringName) -> String:
	match id:
		&"scatter", &"SCATTER", &"high_card":
			return "散点"
		&"straight", &"STRAIGHT", &"small_straight", &"large_straight":
			return "顺子"
		&"pair":
			return combo_name(&"PAIR")
		&"two_pair":
			return combo_name(&"TWO_PAIR")
		&"three_kind":
			return combo_name(&"THREE_KIND")
		&"full_house":
			return combo_name(&"FULL_HOUSE")
		&"four_kind":
			return combo_name(&"FOUR_KIND")
		&"five_kind":
			return combo_name(&"FIVE_KIND")
		&"HIGH_CARD":
			return "高点"
		&"PAIR":
			return "一对"
		&"TWO_PAIR":
			return "两对"
		&"THREE_KIND":
			return "三同"
		&"SMALL_STRAIGHT":
			return "小顺"
		&"FULL_HOUSE":
			return "葫芦"
		&"FOUR_KIND":
			return "四同"
		&"LARGE_STRAIGHT":
			return "大顺"
		&"FIVE_KIND":
			return "五同"
		_:
			return str(id)


static func contained_pattern_name(id: StringName) -> String:
	match id:
		&"contains_pair":
			return "一对"
		&"contains_two_pair":
			return "两对"
		&"contains_three_kind":
			return "三同"
		&"contains_full_house":
			return "葫芦"
		&"contains_four_kind":
			return "四同"
		&"contains_five_kind":
			return "五同"
		_:
			return str(id)


static func tag_name(id: StringName) -> String:
	match id:
		&"all_odd":
			return "全奇"
		&"all_even":
			return "全偶"
		&"low_total":
			return "低点合计"
		&"high_total":
			return "高点合计"
		&"contains_six":
			return "包含 6"
		&"many_sixes":
			return "多个 6"
		&"few_scored":
			return "少量结算"
		&"rerolled":
			return "使用过重投"
		&"last_hand":
			return "最后一手"
		_:
			return forge_tag_name(id)


static func forge_tag_name(id: StringName) -> String:
	match id:
		&"ornament":
			return "面饰"
		&"mark":
			return "印记"
		&"stay":
			return "留场"
		&"reroll":
			return "重投"
		&"xmult":
			return "终倍率"
		&"chips":
			return "基础战力"
		&"mult":
			return "倍率"
		&"burst":
			return "爆发"
		&"wild":
			return "万能"
		&"stone":
			return "石质"
		&"gold":
			return "金币"
		&"lucky":
			return "幸运"
		&"foil":
			return "箔光"
		&"holo":
			return "幻彩"
		&"poly":
			return "多彩"
		&"stable":
			return "稳定"
		&"power":
			return "战力"
		&"six":
			return "六点"
		&"low":
			return "低点"
		&"straight":
			return "顺子"
		&"odd":
			return "奇数"
		&"even":
			return "偶数"
		&"extra_trigger":
			return "额外触发"
		_:
			return str(id)


static func rarity_name(id: StringName) -> String:
	match id:
		&"", &"common":
			return "普通"
		&"uncommon":
			return "罕见"
		&"rare":
			return "稀有"
		&"epic":
			return "史诗"
		&"legendary":
			return "传说"
		_:
			return str(id)


static func body_name(id: StringName) -> String:
	match id:
		&"", &"none":
			return "无"
		&"standard":
			return "标准骰胚"
		&"iron":
			return "铁质骰胚"
		&"glass":
			return "玻璃骰胚"
		&"biased":
			return "偏心骰胚"
		&"hollow":
			return "空心骰胚"
		&"mirror":
			return "镜面骰胚"
		_:
			return str(id)


static func ornament_name(id: StringName) -> String:
	match _legacy_ornament_id(id):
		&"", &"none", &"orn_none":
			return "无"
		&"orn_chip":
			return "筹码面饰"
		&"orn_mult":
			return "倍率面饰"
		&"orn_wild":
			return "万能面饰"
		&"orn_burst":
			return "爆裂面饰"
		&"orn_stay":
			return "留场面饰"
		&"orn_stone":
			return "石质面饰"
		&"orn_gold":
			return "金辉面饰"
		&"orn_lucky":
			return "幸运面饰"
		&"orn_foil":
			return "箔光强化"
		&"orn_holo":
			return "幻彩强化"
		&"orn_poly":
			return "多彩强化"
		&"orn_negative":
			return "负片强化"
		&"curse":
			return "诅咒面饰"
		_:
			return str(id)


static func ornament_effect_text(id: StringName) -> String:
	match _legacy_ornament_id(id):
		&"", &"none", &"orn_none":
			return "无面饰效果。"
		&"orn_chip":
			return "被结算时，+30 基础战力。"
		&"orn_mult":
			return "被结算时，+4 Mult。"
		&"orn_wild":
			return "结算前可临时选择点数参与点数判断，点数总和仍按原始点数。"
		&"orn_burst":
			return "被结算时，终倍率 ×2；结算后有 25% 概率破碎为无面饰。"
		&"orn_stay":
			return "投出但未结算时，终倍率 ×1.5。"
		&"orn_stone":
			return "被结算时，+50 基础战力；不参与点数判断与点数总和。"
		&"orn_gold":
			return "投出但未结算且本手成功结算后，+3 金币。"
		&"orn_lucky":
			return "被结算时，分别判定 20% 获得 +20 Mult、1/15 获得 +20 金币。"
		&"orn_foil":
			return "被结算时，+50 基础战力。"
		&"orn_holo":
			return "被结算时，+10 Mult。"
		&"orn_poly":
			return "被结算时，终倍率 ×1.5。"
		&"orn_negative":
			return "物品负片强化，不属于骰面面饰。"
		&"curse":
			return "负面面饰，可被净化。"
		_:
			return "未知面饰效果。"


static func mark_name(id: StringName) -> String:
	match _legacy_mark_id(id):
		&"", &"none", &"mark_none":
			return "无"
		&"mark_red", &"red":
			return "红印"
		&"mark_blue", &"blue":
			return "蓝印"
		&"mark_purple", &"purple":
			return "紫印"
		&"black":
			return "黑印"
		&"mark_gold", &"gold":
			return "金印"
		&"mark_white", &"white":
			return "白印"
		_:
			return str(id)


static func mark_effect_text(id: StringName) -> String:
	match _legacy_mark_id(id):
		&"mark_red", &"red":
			return "被结算时，该面额外触发一次。"
		&"mark_blue", &"blue":
			return "投出但未结算时，触发留场收益。"
		&"mark_purple", &"purple":
			return "该骰子本手被重投后出现时，触发额外收益。"
		&"mark_gold", &"gold":
			return "触发时提供资源。当前版本暂未启用经济系统。"
		&"mark_white", &"white":
			return "该骰面不受 Boss 禁用或负面规则影响；一场 Boss 战结束后移除。"
		&"black":
			return "负面印记。当前版本仅用于测试或净化。"
		&"", &"none", &"mark_none":
			return "无印记效果。"
		_:
			return "未知印记效果。"


static func face_summary(face) -> String:
	if face == null:
		return "无骰面"

	var lines := PackedStringArray()
	lines.append(str(face.pip))

	var ornament_id := _effective_face_ornament_id(face)
	if not _is_none_id(ornament_id):
		lines.append("面饰：%s" % [ornament_name(ornament_id)])
	if not _is_none_id(face.mark_id):
		lines.append("印记：%s" % [mark_name(face.mark_id)])

	return "\n".join(lines)


static func face_detail_text(face) -> String:
	if face == null:
		return "无骰面"

	var ornament_id := _effective_face_ornament_id(face)
	var lines := PackedStringArray()
	lines.append("点数：%d" % [face.pip])
	lines.append("面饰：%s" % [ornament_name(ornament_id)])
	lines.append("效果：%s" % [ornament_effect_text(ornament_id)])
	lines.append("印记：%s" % [mark_name(face.mark_id)])
	lines.append("效果：%s" % [mark_effect_text(face.mark_id)])
	return "\n".join(lines)


static func die_summary(die) -> String:
	if die == null:
		return "无骰子"

	var lines := PackedStringArray()
	var face_count := int(die.face_count)
	if face_count <= 0:
		face_count = die.faces.size()
	lines.append("骰胚：%s" % [body_name(die.body_id)])
	lines.append("面数：D%d" % [face_count])

	for face_index in range(die.faces.size()):
		var face = die.faces[face_index]
		var parts := PackedStringArray()
		parts.append(str(face.pip))
		var ornament_id := _effective_face_ornament_id(face)
		if not _is_none_id(ornament_id):
			parts.append("面饰：%s" % [ornament_name(ornament_id)])
		if not _is_none_id(face.mark_id):
			parts.append("印记：%s" % [mark_name(face.mark_id)])
		lines.append("面 %d：%s" % [face_index + 1, " / ".join(parts)])

	return "\n".join(lines)


static func phase_name(phase) -> String:
	var phase_id := StringName(str(phase))
	match phase_id:
		&"INIT":
			return "初始化"
		&"WAITING_ACTION":
			return "等待行动"
		&"SCORING":
			return "结算中"
		&"VICTORY":
			return "战斗胜利"
		&"DEFEAT":
			return "战斗失败"
		_:
			return str(phase)


static func join_names(names: Array, separator: String = " / ") -> String:
	var parts := PackedStringArray()
	for name in names:
		var text := str(name)
		if text != "":
			parts.append(text)
	if parts.is_empty():
		return "无"
	return separator.join(parts)


static func display_from_key_or_id(value: StringName) -> String:
	var text := str(value)
	if text.begins_with("COMBO."):
		return combo_name(StringName(text.trim_prefix("COMBO.")))
	if text.begins_with("CONTAINED_PATTERN."):
		return contained_pattern_name(_id_from_key_suffix(text.trim_prefix("CONTAINED_PATTERN.")))
	if text.begins_with("TAG."):
		return tag_name(_id_from_key_suffix(text.trim_prefix("TAG.")))
	if text.begins_with("ORNAMENT.") and text.ends_with(".NAME"):
		return ornament_name(_id_from_key_suffix(text.trim_prefix("ORNAMENT.").trim_suffix(".NAME")))
	if text.begins_with("IMPRINT.") and text.ends_with(".NAME"):
		return mark_name(_id_from_key_suffix(text.trim_prefix("IMPRINT.").trim_suffix(".NAME")))
	if text.begins_with("RARITY."):
		return rarity_name(_id_from_key_suffix(text.trim_prefix("RARITY.")))
	if text.begins_with("MATERIAL.") and text.ends_with(".NAME"):
		return ornament_name(_id_from_key_suffix(text.trim_prefix("MATERIAL.").trim_suffix(".NAME")))
	if text.begins_with("RUNE.") and text.ends_with(".NAME"):
		return str(_id_from_key_suffix(text.trim_prefix("RUNE.").trim_suffix(".NAME")))
	return text


static func log_text(key: StringName, args: Dictionary = {}) -> String:
	match key:
		&"LOG.COMBO":
			var combo_text := str(args.get("combo", ""))
			var level := int(args.get("level", 0))
			if level > 0:
				return "主骰型：%s Lv%d" % [combo_text, level]
			return "主骰型：%s" % [combo_text]
		&"LOG.CONTAINED_PATTERNS":
			return "包含结构：%s" % [args.get("patterns", "无")]
		&"LOG.COMBO_CHIPS_BONUS":
			return "骰型基础战力：+%d" % [int(args.get("chips", 0))]
		&"LOG.COMBO_MULT":
			return "骰型倍率：x%d" % [int(args.get("mult", 1))]
		&"LOG.PIP_SUM":
			return "点数总和：%d" % [int(args.get("sum", 0))]
		&"LOG.BASE_CHIPS":
			return "基础战力：%d" % [int(args.get("chips", 0))]
		&"LOG.BASE_MULT":
			return "倍率：%d" % [int(args.get("mult", 0))]
		&"LOG.BASE_XMULT":
			return "终倍率：%s" % [str(args.get("xmult", "1.00"))]
		&"LOG.FINAL_SCORE":
			return "最终：%d × %d × %s = %d" % [
				int(args.get("chips", 0)),
				int(args.get("mult", 0)),
				str(args.get("xmult", "1.00")),
				int(args.get("score", 0)),
			]
		&"LOG.ORNAMENT_CHIP":
			return "筹码面饰：+%d 基础战力" % [int(args.get("chips", 0))]
		&"LOG.ORNAMENT_MULT":
			return "倍率面饰：+%d Mult" % [int(args.get("mult", 0))]
		&"LOG.ORNAMENT_BURST":
			return "爆裂面饰：X%s 终倍率" % [str(args.get("xmult", "2"))]
		&"LOG.ORNAMENT_STAY":
			return "留场面饰：X%s 终倍率" % [str(args.get("xmult", "1.5"))]
		&"LOG.ORNAMENT_WILD":
			return "万能面饰：原始 %d，本手视作 %d" % [
				int(args.get("original", 0)),
				int(args.get("pip", 0)),
			]
		&"LOG.ORNAMENT_STONE":
			return "石质面饰：+%d 基础战力；不参与点数判断" % [int(args.get("chips", 0))]
		&"LOG.ORNAMENT_GOLD":
			return "金辉面饰：+%d 金币" % [int(args.get("coins", 0))]
		&"LOG.ORNAMENT_LUCKY_MULT":
			return "幸运面饰：触发 +%d Mult" % [int(args.get("mult", 0))]
		&"LOG.ORNAMENT_LUCKY_COINS":
			return "幸运面饰：触发 +%d 金币" % [int(args.get("coins", 0))]
		&"LOG.ORNAMENT_LUCKY_MISS":
			return "幸运面饰：未触发"
		&"LOG.ORNAMENT_FOIL":
			return "箔光强化：+%d 基础战力" % [int(args.get("chips", 0))]
		&"LOG.ORNAMENT_HOLO":
			return "幻彩强化：+%d Mult" % [int(args.get("mult", 0))]
		&"LOG.ORNAMENT_POLY":
			return "多彩强化：X%s 终倍率" % [str(args.get("xmult", "1.5"))]
		&"LOG.ORNAMENT_BURST_BREAK":
			return "爆裂面饰破碎：面饰变为无面饰"
		&"LOG.MARK_RED_RETRIGGER":
			return "红印：额外触发"
		&"LOG.MARK_BLUE_GENERATE":
			return "蓝印：生成【%s】" % [str(args.get("item_name", args.get("item", "骰型升级件")))]
		&"LOG.MARK_BLUE_NO_SLOT":
			return "蓝印：道具槽位不足"
		&"LOG.MARK_PURPLE_GENERATE":
			return "紫印：生成【随机铸骰件】"
		&"LOG.MARK_PURPLE_NO_SLOT":
			return "紫印：道具槽位不足"
		&"LOG.MARK_GOLD_COINS":
			return "金印：+1 金币"
		&"LOG.MARK_WHITE_IMMUNE":
			return "白印：免疫"
		&"LOG.MARK_WHITE_REMOVED":
			return "白印：Boss 战后移除"
		&"LOG.MARK_RED":
			return "骰子 %d / 面 %d：%s，额外触发一次。" % [
				int(args.get("die", 0)),
				int(args.get("face", 0)),
				str(args.get("mark", "")),
			]
		&"LOG.MARK_BLUE":
			return "骰子 %d / 面 %d：%s留场触发，+%d 倍率。" % [
				int(args.get("die", 0)),
				int(args.get("face", 0)),
				str(args.get("mark", "")),
				int(args.get("mult", 0)),
			]
		&"LOG.MARK_PURPLE":
			return "骰子 %d / 面 %d：%s重投后结算，+%d 倍率。" % [
				int(args.get("die", 0)),
				int(args.get("face", 0)),
				str(args.get("mark", "")),
				int(args.get("mult", 0)),
			]
		&"LOG.EXTRA_TRIGGER_PIP":
			return "骰子 %d / 面 %d：额外触发点数，+%d 基础战力。" % [
				int(args.get("die", 0)),
				int(args.get("face", 0)),
				int(args.get("chips", 0)),
			]
		&"LOG.MATERIAL_STEEL":
			return log_text(&"LOG.ORNAMENT_STAY", {"die": args.get("die", 0), "face": args.get("face", 0), "ornament": ornament_name(&"orn_stay"), "xmult": args.get("xmult", "1.5")})
		&"LOG.MATERIAL_GLASS":
			return log_text(&"LOG.ORNAMENT_BURST", {"die": args.get("die", 0), "face": args.get("face", 0), "ornament": ornament_name(&"orn_burst"), "xmult": args.get("xmult", "2")})
		&"LOG.IMPRINT_BLUE":
			return log_text(&"LOG.MARK_BLUE", {"die": args.get("die", 0), "face": args.get("face", 0), "mark": mark_name(&"blue"), "mult": args.get("mult", 0)})
		&"LOG.IMPRINT_RED":
			return log_text(&"LOG.MARK_RED", {"die": args.get("die", 0), "face": args.get("face", 0), "mark": mark_name(&"red")})
		_:
			return str(key)


static func material_name(id: StringName) -> String:
	return ornament_name(id)


static func material_effect_text(id: StringName) -> String:
	return ornament_effect_text(id)


static func rune_name(id: StringName) -> String:
	match id:
		&"", &"none":
			return "无"
		_:
			return str(id)


static func rune_effect_text(_id: StringName) -> String:
	return "当前版本不启用该效果。"


static func _effective_face_ornament_id(face) -> StringName:
	if face == null:
		return &"none"
	if face.has_method("get_effective_ornament_id"):
		return face.get_effective_ornament_id()
	var ornament_value = face.get("ornament_id")
	if ornament_value is StringName and not _is_none_id(ornament_value):
		return ornament_value
	var material_value = face.get("material_id")
	if material_value is StringName:
		return _legacy_ornament_id(material_value)
	return &"none"


static func _legacy_ornament_id(id: StringName) -> StringName:
	match id:
		&"", &"none", &"orn_none":
			return &"orn_none"
		&"chip", &"orn_chip":
			return &"orn_chip"
		&"mult", &"orn_mult":
			return &"orn_mult"
		&"wild", &"orn_wild":
			return &"orn_wild"
		&"glass":
			return &"orn_burst"
		&"burst", &"orn_burst":
			return &"orn_burst"
		&"steel":
			return &"orn_stay"
		&"stay", &"orn_stay":
			return &"orn_stay"
		&"stone", &"orn_stone":
			return &"orn_stone"
		&"gold", &"orn_gold":
			return &"orn_gold"
		&"lucky", &"orn_lucky":
			return &"orn_lucky"
		&"foil", &"orn_foil":
			return &"orn_foil"
		&"holo", &"orn_holo":
			return &"orn_holo"
		&"poly", &"orn_poly":
			return &"orn_poly"
		&"negative", &"orn_negative":
			return &"orn_negative"
		_:
			return id


static func _id_from_key_suffix(suffix: String) -> StringName:
	return StringName(suffix.to_lower())


static func _legacy_mark_id(id: StringName) -> StringName:
	match id:
		&"", &"none", &"mark_none":
			return &"mark_none"
		&"red", &"mark_red":
			return &"mark_red"
		&"blue", &"mark_blue":
			return &"mark_blue"
		&"purple", &"mark_purple":
			return &"mark_purple"
		&"mark_black":
			return &"black"
		&"gold", &"mark_gold":
			return &"mark_gold"
		&"white", &"mark_white":
			return &"mark_white"
		_:
			return id


static func _is_none_id(value: StringName) -> bool:
	return value == &"" or value == &"none" or value == &"orn_none" or value == &"mark_none"
