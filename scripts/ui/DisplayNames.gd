extends RefCounted
class_name DisplayNames


const DieState = preload("res://scripts/core/dice/DieState.gd")


static func combo_name(id: StringName) -> String:
	match id:
		&"scatter", &"SCATTER", &"high_card":
			return str(TranslationServer.translate(&"AUTO.TEXT.EF4C86E15258"))
		&"straight", &"STRAIGHT", &"small_straight", &"large_straight":
			return str(TranslationServer.translate(&"AUTO.TEXT.287EC954DA38"))
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
			return str(TranslationServer.translate(&"AUTO.TEXT.0BB2D2BDE559"))
		&"PAIR":
			return str(TranslationServer.translate(&"AUTO.TEXT.46216CA5837D"))
		&"TWO_PAIR":
			return str(TranslationServer.translate(&"AUTO.TEXT.4391622EE4DF"))
		&"THREE_KIND":
			return str(TranslationServer.translate(&"AUTO.TEXT.B1296780A94C"))
		&"SMALL_STRAIGHT":
			return str(TranslationServer.translate(&"AUTO.TEXT.F26608E9DBEA"))
		&"FULL_HOUSE":
			return str(TranslationServer.translate(&"AUTO.TEXT.66311348D7E0"))
		&"FOUR_KIND":
			return str(TranslationServer.translate(&"AUTO.TEXT.267A5D4096BE"))
		&"LARGE_STRAIGHT":
			return str(TranslationServer.translate(&"AUTO.TEXT.8024C1DC23A5"))
		&"FIVE_KIND":
			return str(TranslationServer.translate(&"AUTO.TEXT.7FDD1CDCF1BE"))
		_:
			return str(id)


static func contained_pattern_name(id: StringName) -> String:
	match id:
		&"contains_pair":
			return str(TranslationServer.translate(&"AUTO.TEXT.46216CA5837D"))
		&"contains_two_pair":
			return str(TranslationServer.translate(&"AUTO.TEXT.4391622EE4DF"))
		&"contains_three_kind":
			return str(TranslationServer.translate(&"AUTO.TEXT.B1296780A94C"))
		&"contains_full_house":
			return str(TranslationServer.translate(&"AUTO.TEXT.66311348D7E0"))
		&"contains_four_kind":
			return str(TranslationServer.translate(&"AUTO.TEXT.267A5D4096BE"))
		&"contains_five_kind":
			return str(TranslationServer.translate(&"AUTO.TEXT.7FDD1CDCF1BE"))
		_:
			return str(id)


static func tag_name(id: StringName) -> String:
	match id:
		&"all_odd":
			return str(TranslationServer.translate(&"AUTO.TEXT.DA53AE041865"))
		&"all_even":
			return str(TranslationServer.translate(&"AUTO.TEXT.93EBECF8CECD"))
		&"low_total":
			return str(TranslationServer.translate(&"AUTO.TEXT.E836750721A5"))
		&"high_total":
			return str(TranslationServer.translate(&"AUTO.TEXT.20A87E1FBD1E"))
		&"contains_six":
			return str(TranslationServer.translate(&"AUTO.TEXT.610C37A76491"))
		&"many_sixes":
			return str(TranslationServer.translate(&"AUTO.TEXT.BE2465538832"))
		&"few_scored":
			return str(TranslationServer.translate(&"AUTO.TEXT.A1D476072362"))
		&"rerolled":
			return str(TranslationServer.translate(&"AUTO.TEXT.D4D96AFD037F"))
		&"last_hand":
			return str(TranslationServer.translate(&"AUTO.TEXT.BCC672A44DB4"))
		_:
			return forge_tag_name(id)


static func forge_tag_name(id: StringName) -> String:
	match id:
		&"ornament":
			return str(TranslationServer.translate(&"AUTO.TEXT.6D536C9ECF3E"))
		&"mark":
			return str(TranslationServer.translate(&"AUTO.TEXT.7F31376752FF"))
		&"stay":
			return str(TranslationServer.translate(&"AUTO.TEXT.446EFF18E772"))
		&"reroll":
			return str(TranslationServer.translate(&"AUTO.TEXT.332A22260969"))
		&"xmult":
			return str(TranslationServer.translate(&"AUTO.TEXT.D19E1EFF6391"))
		&"chips":
			return str(TranslationServer.translate(&"AUTO.TEXT.038CDAFC55EF"))
		&"mult":
			return str(TranslationServer.translate(&"AUTO.TEXT.8482E1E532B0"))
		&"burst":
			return str(TranslationServer.translate(&"AUTO.TEXT.E3D30EF5898B"))
		&"wild":
			return str(TranslationServer.translate(&"AUTO.TEXT.B7CD1829C0EC"))
		&"stone":
			return str(TranslationServer.translate(&"AUTO.TEXT.043D46E4F6CD"))
		&"gold":
			return str(TranslationServer.translate(&"AUTO.TEXT.61F608B0D90E"))
		&"lucky":
			return str(TranslationServer.translate(&"AUTO.TEXT.B824742329E0"))
		&"foil":
			return str(TranslationServer.translate(&"AUTO.TEXT.7755578B11E2"))
		&"holo":
			return str(TranslationServer.translate(&"AUTO.TEXT.A9A4A4AB8CAF"))
		&"poly":
			return str(TranslationServer.translate(&"AUTO.TEXT.1943D2CAFB6A"))
		&"stable":
			return str(TranslationServer.translate(&"AUTO.TEXT.4024BD5E2322"))
		&"power":
			return str(TranslationServer.translate(&"AUTO.TEXT.63A0E9B5803D"))
		&"six":
			return str(TranslationServer.translate(&"AUTO.TEXT.A93AED7A90F4"))
		&"low":
			return str(TranslationServer.translate(&"AUTO.TEXT.6197FE1A0676"))
		&"straight":
			return str(TranslationServer.translate(&"AUTO.TEXT.287EC954DA38"))
		&"odd":
			return str(TranslationServer.translate(&"AUTO.TEXT.0CF1D841BD73"))
		&"even":
			return str(TranslationServer.translate(&"AUTO.TEXT.A3685EA6FAFC"))
		&"extra_trigger":
			return str(TranslationServer.translate(&"AUTO.TEXT.22CE35BEF3DF"))
		_:
			return str(id)


static func rarity_name(id: StringName) -> String:
	match id:
		&"", &"common":
			return str(TranslationServer.translate(&"AUTO.TEXT.7CDA072D452B"))
		&"uncommon":
			return str(TranslationServer.translate(&"AUTO.TEXT.8FCB7811D446"))
		&"rare":
			return str(TranslationServer.translate(&"AUTO.TEXT.543CFD5DFDFE"))
		&"epic":
			return str(TranslationServer.translate(&"AUTO.TEXT.A18EBC607F7F"))
		&"legendary":
			return str(TranslationServer.translate(&"AUTO.TEXT.E60ACDC62872"))
		_:
			return str(id)


static func body_name(id: StringName) -> String:
	if id == &"" or id == &"none":
		return str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))
	match DieState.normalize_body_id(id):
		DieState.BODY_STANDARD:
			return str(TranslationServer.translate(&"AUTO.TEXT.42C63776B3C2"))
		DieState.BODY_IRON:
			return str(TranslationServer.translate(&"AUTO.TEXT.FE35ED0F6706"))
		DieState.BODY_GLASS:
			return str(TranslationServer.translate(&"AUTO.TEXT.DB1E908DDAAB"))
		DieState.BODY_BIASED:
			return str(TranslationServer.translate(&"AUTO.TEXT.46CDBD4B9F31"))
		DieState.BODY_HOLLOW:
			return str(TranslationServer.translate(&"AUTO.TEXT.33C12FCEA8E6"))
		DieState.BODY_MIRROR:
			return str(TranslationServer.translate(&"AUTO.TEXT.A542B7CCA535"))
		DieState.BODY_CRACKED:
			return "裂纹骰胚"
		DieState.BODY_MERCHANT:
			return "商人骰胚"
		_:
			return str(id)


static func ornament_name(id: StringName) -> String:
	match _legacy_ornament_id(id):
		&"", &"none", &"orn_none":
			return str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))
		&"orn_chip":
			return str(TranslationServer.translate(&"AUTO.TEXT.117883B0EBE1"))
		&"orn_mult":
			return str(TranslationServer.translate(&"AUTO.TEXT.C500FA399240"))
		&"orn_wild":
			return str(TranslationServer.translate(&"AUTO.TEXT.AC2FB8965804"))
		&"orn_burst":
			return str(TranslationServer.translate(&"AUTO.TEXT.97FB92DB432F"))
		&"orn_stay":
			return str(TranslationServer.translate(&"AUTO.TEXT.5C1FC3B3DE4C"))
		&"orn_stone":
			return str(TranslationServer.translate(&"AUTO.TEXT.7D507BD3C533"))
		&"orn_gold":
			return str(TranslationServer.translate(&"AUTO.TEXT.0C170134B33B"))
		&"orn_lucky":
			return str(TranslationServer.translate(&"AUTO.TEXT.9B44878F713C"))
		&"orn_foil":
			return str(TranslationServer.translate(&"AUTO.TEXT.EF8326246CC6"))
		&"orn_holo":
			return str(TranslationServer.translate(&"AUTO.TEXT.71057C7B06AE"))
		&"orn_poly":
			return str(TranslationServer.translate(&"AUTO.TEXT.C7D719D6CF7B"))
		&"orn_negative":
			return str(TranslationServer.translate(&"AUTO.TEXT.513FE245BC0D"))
		&"curse":
			return str(TranslationServer.translate(&"AUTO.TEXT.85162D1409CC"))
		_:
			return str(id)


static func ornament_effect_text(id: StringName) -> String:
	match _legacy_ornament_id(id):
		&"", &"none", &"orn_none":
			return str(TranslationServer.translate(&"AUTO.TEXT.1706DBBA86F9"))
		&"orn_chip":
			return str(TranslationServer.translate(&"AUTO.TEXT.14DDE613ACF4"))
		&"orn_mult":
			return str(TranslationServer.translate(&"AUTO.TEXT.699368E17299"))
		&"orn_wild":
			return str(TranslationServer.translate(&"AUTO.TEXT.2A707C088E48"))
		&"orn_burst":
			return str(TranslationServer.translate(&"AUTO.TEXT.B6A38FDF50AC"))
		&"orn_stay":
			return str(TranslationServer.translate(&"AUTO.TEXT.1DC0AB17E3A0"))
		&"orn_stone":
			return str(TranslationServer.translate(&"AUTO.TEXT.5598B4374A82"))
		&"orn_gold":
			return str(TranslationServer.translate(&"AUTO.TEXT.50D8E8DFB926"))
		&"orn_lucky":
			return str(TranslationServer.translate(&"AUTO.TEXT.7EA823B27E5C"))
		&"orn_foil":
			return str(TranslationServer.translate(&"AUTO.TEXT.1E604A9DCA44"))
		&"orn_holo":
			return str(TranslationServer.translate(&"AUTO.TEXT.375FB8073275"))
		&"orn_poly":
			return str(TranslationServer.translate(&"AUTO.TEXT.296CDB12F677"))
		&"orn_negative":
			return str(TranslationServer.translate(&"AUTO.TEXT.1BD96BB61B7F"))
		&"curse":
			return str(TranslationServer.translate(&"AUTO.TEXT.42398AEA87B6"))
		_:
			return str(TranslationServer.translate(&"AUTO.TEXT.55F0E3DF4A53"))


static func mark_name(id: StringName) -> String:
	match _legacy_mark_id(id):
		&"", &"none", &"mark_none":
			return str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))
		&"mark_red", &"red":
			return str(TranslationServer.translate(&"AUTO.TEXT.79C2CA946E6B"))
		&"mark_blue", &"blue":
			return str(TranslationServer.translate(&"AUTO.TEXT.DF9F6D1541D3"))
		&"mark_purple", &"purple":
			return str(TranslationServer.translate(&"AUTO.TEXT.8EBB318D3D60"))
		&"black":
			return str(TranslationServer.translate(&"AUTO.TEXT.0FEA7E823183"))
		&"mark_gold", &"gold":
			return str(TranslationServer.translate(&"AUTO.TEXT.C95B7D8DF883"))
		&"mark_white", &"white":
			return str(TranslationServer.translate(&"AUTO.TEXT.2E1D574ED743"))
		_:
			return str(id)


static func mark_effect_text(id: StringName) -> String:
	match _legacy_mark_id(id):
		&"mark_red", &"red":
			return str(TranslationServer.translate(&"AUTO.TEXT.C017F153E6FB"))
		&"mark_blue", &"blue":
			return str(TranslationServer.translate(&"AUTO.TEXT.648BA894F98E"))
		&"mark_purple", &"purple":
			return str(TranslationServer.translate(&"AUTO.TEXT.147E1AD7C52E"))
		&"mark_gold", &"gold":
			return str(TranslationServer.translate(&"AUTO.TEXT.51C417CBC24C"))
		&"mark_white", &"white":
			return str(TranslationServer.translate(&"AUTO.TEXT.CD048469AC0B"))
		&"black":
			return str(TranslationServer.translate(&"AUTO.TEXT.EBBDEA8ACEFD"))
		&"", &"none", &"mark_none":
			return str(TranslationServer.translate(&"AUTO.TEXT.A11B7784CCC8"))
		_:
			return str(TranslationServer.translate(&"AUTO.TEXT.6F29AFF3D8BB"))


static func mark_compact_effect_text(id: StringName) -> String:
	match _legacy_mark_id(id):
		&"mark_blue", &"blue":
			return str(TranslationServer.translate(&"UI.MARK_EFFECT_COMPACT.BLUE"))
		&"mark_purple", &"purple":
			return str(TranslationServer.translate(&"UI.MARK_EFFECT_COMPACT.PURPLE"))
		&"mark_gold", &"gold":
			return str(TranslationServer.translate(&"UI.MARK_EFFECT_COMPACT.GOLD"))
		_:
			return ""


static func face_summary(face) -> String:
	if face == null:
		return str(TranslationServer.translate(&"AUTO.TEXT.9FC761A95140"))

	var lines := PackedStringArray()
	lines.append(str(face.pip))

	var ornament_id := _effective_face_ornament_id(face)
	if not _is_none_id(ornament_id):
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.51AA50FCBAD9")) % [ornament_name(ornament_id)])
	if not _is_none_id(face.mark_id):
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.6711FCB746E3")) % [mark_name(face.mark_id)])

	return "\n".join(lines)


static func face_detail_text(face) -> String:
	if face == null:
		return str(TranslationServer.translate(&"AUTO.TEXT.9FC761A95140"))

	var ornament_id := _effective_face_ornament_id(face)
	var lines := PackedStringArray()
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.3BD4F422F927")) % [face.pip])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.51AA50FCBAD9")) % [ornament_name(ornament_id)])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.64A75BA1FD38")) % [ornament_effect_text(ornament_id)])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.6711FCB746E3")) % [mark_name(face.mark_id)])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.64A75BA1FD38")) % [mark_effect_text(face.mark_id)])
	return "\n".join(lines)


static func die_summary(die) -> String:
	if die == null:
		return str(TranslationServer.translate(&"AUTO.TEXT.DF10F8387066"))

	var lines := PackedStringArray()
	var face_count := int(die.face_count)
	if face_count <= 0:
		face_count = die.faces.size()
	lines.append("面数：D%d" % [face_count])
	lines.append("骰胚：%s" % [body_name(die.body_id)])

	for face_index in range(die.faces.size()):
		var face = die.faces[face_index]
		var parts := PackedStringArray()
		parts.append(str(face.pip))
		var ornament_id := _effective_face_ornament_id(face)
		if not _is_none_id(ornament_id):
			parts.append(str(TranslationServer.translate(&"AUTO.TEXT.51AA50FCBAD9")) % [ornament_name(ornament_id)])
		if not _is_none_id(face.mark_id):
			parts.append(str(TranslationServer.translate(&"AUTO.TEXT.6711FCB746E3")) % [mark_name(face.mark_id)])
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.6F4FAC813D23")) % [face_index + 1, " / ".join(parts)])

	return "\n".join(lines)


static func phase_name(phase) -> String:
	var phase_id := StringName(str(phase))
	match phase_id:
		&"INIT":
			return str(TranslationServer.translate(&"AUTO.TEXT.196E11130931"))
		&"WAITING_ACTION":
			return str(TranslationServer.translate(&"AUTO.TEXT.EE01EF7E6EA2"))
		&"SCORING":
			return str(TranslationServer.translate(&"AUTO.TEXT.0327CD3D96EB"))
		&"VICTORY":
			return str(TranslationServer.translate(&"AUTO.TEXT.BD9FEA62A9DC"))
		&"DEFEAT":
			return str(TranslationServer.translate(&"AUTO.TEXT.D2C21A5E1F56"))
		_:
			return str(phase)


static func join_names(names: Array, separator: String = " / ") -> String:
	var parts := PackedStringArray()
	for name in names:
		var text := str(name)
		if text != "":
			parts.append(text)
	if parts.is_empty():
		return str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))
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
				return str(TranslationServer.translate(&"AUTO.TEXT.9455DA31503B")) % [combo_text, level]
			return str(TranslationServer.translate(&"AUTO.TEXT.EF0721A4BAA9")) % [combo_text]
		&"LOG.CONTAINED_PATTERNS":
			return str(TranslationServer.translate(&"AUTO.TEXT.135E3DF5C753")) % [args.get("patterns", str(TranslationServer.translate(&"AUTO.TEXT.72077749F794")))]
		&"LOG.COMBO_CHIPS_BONUS":
			return str(TranslationServer.translate(&"AUTO.TEXT.DC6B0A9293A8")) % [int(args.get("chips", 0))]
		&"LOG.COMBO_MULT":
			return str(TranslationServer.translate(&"AUTO.TEXT.C5FFC0D889DE")) % [_ceil_numeric_arg(args, "mult", 1.0)]
		&"LOG.PIP_SUM":
			return str(TranslationServer.translate(&"AUTO.TEXT.2392B1DFA2A1")) % [int(args.get("sum", 0))]
		&"LOG.BASE_CHIPS":
			return str(TranslationServer.translate(&"AUTO.TEXT.4175E1B87B17")) % [int(args.get("chips", 0))]
		&"LOG.BASE_MULT":
			return str(TranslationServer.translate(&"AUTO.TEXT.B57562D610C0")) % [_ceil_numeric_arg(args, "mult", 0.0)]
		&"LOG.BASE_XMULT":
			return str(TranslationServer.translate(&"AUTO.TEXT.C39ACC391607")) % [_format_multiplier_arg(args, "xmult", 1.0)]
		&"LOG.FINAL_SCORE":
			return str(TranslationServer.translate(&"AUTO.TEXT.481853976CD4")) % [
				int(args.get("chips", 0)),
				_ceil_numeric_arg(args, "mult", 0.0),
				_format_multiplier_arg(args, "xmult", 1.0),
				int(args.get("score", 0)),
			]
		&"LOG.ORNAMENT_CHIP":
			return str(TranslationServer.translate(&"AUTO.TEXT.01573E10E71B")) % [int(args.get("chips", 0))]
		&"LOG.ORNAMENT_MULT":
			return str(TranslationServer.translate(&"AUTO.TEXT.29C0C578392B")) % [_ceil_numeric_arg(args, "mult", 0.0)]
		&"LOG.ORNAMENT_BURST":
			return str(TranslationServer.translate(&"AUTO.TEXT.35285A7CDA47")) % [_format_multiplier_arg(args, "xmult", 2.0)]
		&"LOG.ORNAMENT_STAY":
			return str(TranslationServer.translate(&"AUTO.TEXT.B144C1DD3DD0")) % [_format_multiplier_arg(args, "xmult", 2.0)]
		&"LOG.ORNAMENT_WILD":
			return str(TranslationServer.translate(&"AUTO.TEXT.CF5532730BC5")) % [
				int(args.get("original", 0)),
				int(args.get("pip", 0)),
			]
		&"LOG.ORNAMENT_STONE":
			return str(TranslationServer.translate(&"AUTO.TEXT.C77871423FEA")) % [int(args.get("chips", 0))]
		&"LOG.ORNAMENT_GOLD":
			return str(TranslationServer.translate(&"AUTO.TEXT.2B928EF5366D")) % [int(args.get("coins", 0))]
		&"LOG.ORNAMENT_LUCKY_MULT":
			return str(TranslationServer.translate(&"AUTO.TEXT.DB56A53169CA")) % [_ceil_numeric_arg(args, "mult", 0.0)]
		&"LOG.ORNAMENT_LUCKY_COINS":
			return str(TranslationServer.translate(&"AUTO.TEXT.F4E270D49C8E")) % [int(args.get("coins", 0))]
		&"LOG.ORNAMENT_LUCKY_MISS":
			return str(TranslationServer.translate(&"AUTO.TEXT.5CD950781956"))
		&"LOG.ORNAMENT_FOIL":
			return str(TranslationServer.translate(&"AUTO.TEXT.222171072F44")) % [int(args.get("chips", 0))]
		&"LOG.ORNAMENT_HOLO":
			return str(TranslationServer.translate(&"AUTO.TEXT.53F7EEE5CB6F")) % [_ceil_numeric_arg(args, "mult", 0.0)]
		&"LOG.ORNAMENT_POLY":
			return str(TranslationServer.translate(&"AUTO.TEXT.FC3405B20424")) % [_format_multiplier_arg(args, "xmult", 2.0)]
		&"LOG.ORNAMENT_BURST_BREAK":
			return str(TranslationServer.translate(&"AUTO.TEXT.5C8EA2E7B281"))
		&"LOG.BODY_IRON":
			var iron_text := "铁质骰胚触发：+%d 基础战力" % [int(args.get("chips", 0))]
			var iron_mult := int(args.get("mult", 0))
			if iron_mult > 0:
				iron_text = "%s / +%d 倍率" % [iron_text, iron_mult]
			return iron_text
		&"LOG.BODY_HOLLOW":
			return "空心骰胚触发：+%d 基础战力 / +%d 倍率" % [int(args.get("chips", 0)), int(args.get("mult", 0))]
		&"LOG.BODY_MIRROR":
			return "镜面骰胚触发：面饰额外触发"
		&"LOG.BODY_CRACKED_ABSORB":
			return "裂纹吸收：取消爆裂破碎"
		&"LOG.BODY_MERCHANT":
			return "商人骰胚触发：金币额外 +%d" % [int(args.get("coins", 0))]
		&"LOG.MARK_RED_RETRIGGER":
			return str(TranslationServer.translate(&"AUTO.TEXT.FB21BA85CACD"))
		&"LOG.MARK_BLUE_GENERATE":
			return str(TranslationServer.translate(&"AUTO.TEXT.E941ADF91E56")) % [str(args.get("item_name", args.get("item", str(TranslationServer.translate(&"AUTO.TEXT.8F10CCA653DA")))))]
		&"LOG.MARK_BLUE_NO_SLOT":
			return str(TranslationServer.translate(&"AUTO.TEXT.6F0EF6ABE0EC"))
		&"LOG.MARK_PURPLE_GENERATE":
			return str(TranslationServer.translate(&"AUTO.TEXT.922669C45622"))
		&"LOG.MARK_PURPLE_NO_SLOT":
			return str(TranslationServer.translate(&"AUTO.TEXT.B14D78BB3065"))
		&"LOG.MARK_GOLD_COINS":
			return str(TranslationServer.translate(&"AUTO.TEXT.8FB1BCFCA352"))
		&"LOG.MARK_WHITE_IMMUNE":
			return str(TranslationServer.translate(&"AUTO.TEXT.CFBB1A03E628"))
		&"LOG.MARK_WHITE_REMOVED":
			return str(TranslationServer.translate(&"AUTO.TEXT.BAD8CA5F8C4F"))
		&"LOG.MARK_RED":
			return str(TranslationServer.translate(&"AUTO.TEXT.BC067D3E77C9")) % [
				int(args.get("die", 0)),
				int(args.get("face", 0)),
				str(args.get("mark", "")),
			]
		&"LOG.MARK_BLUE":
			return str(TranslationServer.translate(&"AUTO.TEXT.D2D13E787E4F")) % [
				int(args.get("die", 0)),
				int(args.get("face", 0)),
				str(args.get("mark", "")),
				_ceil_numeric_arg(args, "mult", 0.0),
			]
		&"LOG.MARK_PURPLE":
			return str(TranslationServer.translate(&"AUTO.TEXT.9C193E41AF49")) % [
				int(args.get("die", 0)),
				int(args.get("face", 0)),
				str(args.get("mark", "")),
				_ceil_numeric_arg(args, "mult", 0.0),
			]
		&"LOG.EXTRA_TRIGGER_PIP":
			return str(TranslationServer.translate(&"AUTO.TEXT.264C241CE51B")) % [
				int(args.get("die", 0)),
				int(args.get("face", 0)),
				int(args.get("chips", 0)),
			]
		&"LOG.MATERIAL_STEEL":
			return log_text(&"LOG.ORNAMENT_STAY", {"die": args.get("die", 0), "face": args.get("face", 0), "ornament": ornament_name(&"orn_stay"), "xmult": args.get("xmult", "2")})
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
			return str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))
		_:
			return str(id)


static func rune_effect_text(_id: StringName) -> String:
	return str(TranslationServer.translate(&"AUTO.TEXT.FB4D12C8E49C"))


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


static func _format_multiplier_arg(args: Dictionary, key: String, default_value: float) -> String:
	return str(_ceil_numeric_arg(args, key, default_value))


static func _ceil_numeric_arg(args: Dictionary, key: String, default_value: float) -> int:
	if args == null:
		return ceili(default_value)
	var value = args.get(key, default_value)
	if value is String or value is StringName:
		var text := str(value).strip_edges()
		if text.is_valid_float():
			return ceili(text.to_float())
		return ceili(default_value)
	return ceili(float(value))


static func _is_none_id(value: StringName) -> bool:
	return value == &"" or value == &"none" or value == &"orn_none" or value == &"mark_none"
