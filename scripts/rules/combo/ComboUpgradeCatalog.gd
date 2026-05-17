extends RefCounted
class_name ComboUpgradeCatalog


const ComboLevelDef = preload("res://scripts/rules/combo/ComboLevelDef.gd")


const FIVE_KIND := &"five_kind"
const STRAIGHT := &"straight"
const FOUR_KIND := &"four_kind"
const FULL_HOUSE := &"full_house"
const THREE_KIND := &"three_kind"
const TWO_PAIR := &"two_pair"
const PAIR := &"pair"
const SCATTER := &"scatter"

const ITEM_PREFIX := "upgrade_combo_"


static func get_def(primary_combo_id: StringName) -> ComboLevelDef:
	var normalized_id := normalize_combo_id(primary_combo_id)
	for def in get_all_defs():
		if def.combo_id == normalized_id:
			return def
	return _scatter_def()


static func get_def_by_upgrade_id(upgrade_id: StringName) -> ComboLevelDef:
	for def in get_all_defs():
		if def.upgrade_id == upgrade_id:
			return def
	return null


static func has_combo(primary_combo_id: StringName) -> bool:
	var normalized_id := normalize_combo_id(primary_combo_id)
	for def in get_all_defs():
		if def.combo_id == normalized_id:
			return true
	return false


static func get_all_defs() -> Array[ComboLevelDef]:
	var defs: Array[ComboLevelDef] = []
	defs.append(_make_def(&"combo_five_kind", str(TranslationServer.translate(&"AUTO.TEXT.7FDD1CDCF1BE")), FIVE_KIND, 1, 100, 15, 45, 4))
	defs.append(_make_def(&"combo_straight", str(TranslationServer.translate(&"AUTO.TEXT.287EC954DA38")), STRAIGHT, 2, 80, 8, 40, 4))
	defs.append(_make_def(&"combo_four_kind", str(TranslationServer.translate(&"AUTO.TEXT.267A5D4096BE")), FOUR_KIND, 3, 60, 8, 35, 3))
	defs.append(_make_def(&"combo_full_house", str(TranslationServer.translate(&"AUTO.TEXT.66311348D7E0")), FULL_HOUSE, 4, 40, 5, 30, 2))
	defs.append(_make_def(&"combo_three_kind", str(TranslationServer.translate(&"AUTO.TEXT.B1296780A94C")), THREE_KIND, 5, 30, 4, 25, 2))
	defs.append(_make_def(&"combo_two_pair", str(TranslationServer.translate(&"AUTO.TEXT.4391622EE4DF")), TWO_PAIR, 6, 20, 3, 20, 1))
	defs.append(_make_def(&"combo_pair", str(TranslationServer.translate(&"AUTO.TEXT.46216CA5837D")), PAIR, 7, 10, 2, 15, 1))
	defs.append(_make_def(&"combo_scatter", str(TranslationServer.translate(&"AUTO.TEXT.EF4C86E15258")), SCATTER, 8, 5, 1, 10, 1))
	return defs


static func get_combo_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for def in get_all_defs():
		ids.append(def.combo_id)
	return ids


static func get_item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for def in get_all_defs():
		ids.append(item_id_for_combo(def.combo_id))
	return ids


static func default_combo_levels() -> Dictionary:
	var result := {}
	for combo_id in get_combo_ids():
		result[combo_id] = 1
	return result


static func item_id_for_combo(primary_combo_id: StringName) -> StringName:
	var normalized_id := normalize_combo_id(primary_combo_id)
	if not has_combo(normalized_id):
		return &""
	return StringName("%s%s" % [ITEM_PREFIX, str(normalized_id)])


static func combo_id_from_item_id(item_id: StringName) -> StringName:
	var text := str(item_id)
	if text.begins_with(ITEM_PREFIX):
		return normalize_combo_id(StringName(text.trim_prefix(ITEM_PREFIX)))
	if text.begins_with("upgrade_"):
		return normalize_combo_id(StringName(text.trim_prefix("upgrade_")))
	return &""


static func display_name_for_combo(primary_combo_id: StringName) -> String:
	return str(TranslationServer.translate(&"AUTO.TEXT.F5D5B726DC8E")) % [get_def(primary_combo_id).display_name]


static func normalize_combo_id(combo_id: StringName) -> StringName:
	match combo_id:
		&"FIVE_KIND", &"five_kind":
			return FIVE_KIND
		&"STRAIGHT", &"straight":
			return STRAIGHT
		&"FOUR_KIND", &"four_kind":
			return FOUR_KIND
		&"FULL_HOUSE", &"full_house":
			return FULL_HOUSE
		&"THREE_KIND", &"three_kind":
			return THREE_KIND
		&"TWO_PAIR", &"two_pair":
			return TWO_PAIR
		&"PAIR", &"pair":
			return PAIR
		&"SCATTER", &"scatter":
			return SCATTER
		_:
			return combo_id


static func _scatter_def() -> ComboLevelDef:
	return _make_def(&"combo_scatter", str(TranslationServer.translate(&"AUTO.TEXT.EF4C86E15258")), SCATTER, 8, 5, 1, 10, 1)


static func _make_def(
	upgrade_id: StringName,
	display_name: String,
	combo_id: StringName,
	priority: int,
	lv1_chips_bonus: int,
	lv1_mult: int,
	chips_per_level: int,
	mult_per_level: int
) -> ComboLevelDef:
	var def := ComboLevelDef.new()
	def.upgrade_id = upgrade_id
	def.display_name = display_name
	def.combo_id = combo_id
	def.priority = priority
	def.lv1_chips_bonus = lv1_chips_bonus
	def.lv1_mult = lv1_mult
	def.chips_per_level = chips_per_level
	def.mult_per_level = mult_per_level
	return def
