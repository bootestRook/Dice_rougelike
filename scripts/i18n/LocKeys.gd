extends RefCounted
class_name LocKeys


static func combo_key(combo_id: StringName) -> StringName:
	match combo_id:
		&"scatter", &"HIGH_CARD", &"high_card":
			return &"COMBO.SCATTER"
		&"PAIR", &"pair":
			return &"COMBO.PAIR"
		&"TWO_PAIR", &"two_pair":
			return &"COMBO.TWO_PAIR"
		&"THREE_KIND", &"three_kind":
			return &"COMBO.THREE_KIND"
		&"FULL_HOUSE", &"full_house":
			return &"COMBO.FULL_HOUSE"
		&"straight", &"SMALL_STRAIGHT", &"LARGE_STRAIGHT", &"small_straight", &"large_straight":
			return &"COMBO.STRAIGHT"
		&"FOUR_KIND", &"four_kind":
			return &"COMBO.FOUR_KIND"
		&"FIVE_KIND", &"five_kind":
			return &"COMBO.FIVE_KIND"
		_:
			return &"COMBO.SCATTER"


static func rarity_key(rarity_id: StringName) -> StringName:
	match rarity_id:
		&"common", &"":
			return &"RARITY.COMMON"
		&"uncommon":
			return &"RARITY.UNCOMMON"
		&"rare":
			return &"RARITY.RARE"
		&"epic":
			return &"RARITY.EPIC"
		&"legendary":
			return &"RARITY.LEGENDARY"
		_:
			return StringName("RARITY.%s" % str(rarity_id).to_upper())


static func tag_key(tag_id: StringName) -> StringName:
	match tag_id:
		&"all_odd":
			return &"TAG.ALL_ODD"
		&"all_even":
			return &"TAG.ALL_EVEN"
		&"low_total":
			return &"TAG.LOW_TOTAL"
		&"high_total":
			return &"TAG.HIGH_TOTAL"
		&"contains_six":
			return &"TAG.CONTAINS_SIX"
		&"many_sixes":
			return &"TAG.MANY_SIXES"
		&"few_scored":
			return &"TAG.FEW_SCORED"
		&"rerolled":
			return &"TAG.REROLLED"
		&"last_hand":
			return &"TAG.LAST_HAND"
		_:
			return StringName("TAG.%s" % _stable_id(tag_id))


static func contained_pattern_key(pattern_id: StringName) -> StringName:
	match pattern_id:
		&"contains_pair":
			return &"CONTAINED_PATTERN.CONTAINS_PAIR"
		&"contains_two_pair":
			return &"CONTAINED_PATTERN.CONTAINS_TWO_PAIR"
		&"contains_three_kind":
			return &"CONTAINED_PATTERN.CONTAINS_THREE_KIND"
		&"contains_full_house":
			return &"CONTAINED_PATTERN.CONTAINS_FULL_HOUSE"
		&"contains_four_kind":
			return &"CONTAINED_PATTERN.CONTAINS_FOUR_KIND"
		&"contains_five_kind":
			return &"CONTAINED_PATTERN.CONTAINS_FIVE_KIND"
		_:
			return StringName("CONTAINED_PATTERN.%s" % _stable_id(pattern_id))


static func battle_phase_key(phase_id: StringName) -> StringName:
	match phase_id:
		&"INIT":
			return &"PHASE.INIT"
		&"WAITING_ACTION":
			return &"PHASE.WAITING_ACTION"
		&"SCORING":
			return &"PHASE.SCORING"
		&"VICTORY":
			return &"PHASE.VICTORY"
		&"DEFEAT":
			return &"PHASE.DEFEAT"
		_:
			return &"PHASE.UNKNOWN"


static func material_name_key(material_id: StringName) -> StringName:
	return _typed_name_key(&"MATERIAL", material_id)


static func material_desc_key(material_id: StringName) -> StringName:
	return _typed_desc_key(&"MATERIAL", material_id)


static func imprint_name_key(imprint_id: StringName) -> StringName:
	return _typed_name_key(&"IMPRINT", _normalize_imprint_id(imprint_id))


static func imprint_desc_key(imprint_id: StringName) -> StringName:
	return _typed_desc_key(&"IMPRINT", _normalize_imprint_id(imprint_id))


static func rune_name_key(rune_id: StringName) -> StringName:
	return _typed_name_key(&"RUNE", rune_id)


static func rune_desc_key(rune_id: StringName) -> StringName:
	return _typed_desc_key(&"RUNE", rune_id)


static func forge_part_name_key(part_id: StringName) -> StringName:
	return _typed_name_key(&"FORGE_PART", part_id)


static func forge_part_desc_key(part_id: StringName) -> StringName:
	return _typed_desc_key(&"FORGE_PART", part_id)


static func die_name_key(die_id: StringName) -> StringName:
	return _typed_name_key(&"DIE", die_id)


static func die_desc_key(die_id: StringName) -> StringName:
	return _typed_desc_key(&"DIE", die_id)


static func relic_name_key(relic_id: StringName) -> StringName:
	return _typed_name_key(&"RELIC", relic_id)


static func relic_desc_key(relic_id: StringName) -> StringName:
	return _typed_desc_key(&"RELIC", relic_id)


static func encounter_name_key(encounter_id: StringName) -> StringName:
	return _typed_name_key(&"ENCOUNTER", encounter_id)


static func _typed_name_key(prefix: StringName, id: StringName) -> StringName:
	return StringName("%s.%s.NAME" % [str(prefix), _stable_id(id)])


static func _typed_desc_key(prefix: StringName, id: StringName) -> StringName:
	return StringName("%s.%s.DESC" % [str(prefix), _stable_id(id)])


static func _stable_id(id: StringName) -> String:
	if id == &"":
		return "NONE"
	return str(id).to_upper()


static func _normalize_imprint_id(id: StringName) -> StringName:
	match id:
		&"mark_none":
			return &"none"
		&"mark_red":
			return &"red"
		&"mark_blue":
			return &"blue"
		&"mark_purple":
			return &"purple"
		&"mark_gold":
			return &"gold"
		&"mark_white":
			return &"white"
		_:
			return id
