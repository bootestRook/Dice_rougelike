extends RefCounted
class_name ComboLevelSystem


const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const ComboLevelResult = preload("res://scripts/rules/combo/ComboLevelResult.gd")


static func get_combo_level_result(primary_combo_id: StringName, combo_levels: Dictionary) -> ComboLevelResult:
	var combo_id := ComboUpgradeCatalog.normalize_combo_id(primary_combo_id)
	if not ComboUpgradeCatalog.has_combo(combo_id):
		combo_id = ComboUpgradeCatalog.SCATTER
	var def := ComboUpgradeCatalog.get_def(combo_id)
	var level := int(combo_levels.get(combo_id, 1))
	level = max(level, 1)

	var result := ComboLevelResult.new()
	result.combo_id = combo_id
	result.level = level
	result.chips_bonus = def.get_chips_bonus(level)
	result.mult = def.get_mult(level)
	return result


static func get_base_values(primary_combo_id: StringName, combo_levels: Dictionary, scored_point_sum: int = 0) -> Dictionary:
	var result := get_combo_level_result(primary_combo_id, combo_levels)
	return {
		"combo_id": result.combo_id,
		"level": result.level,
		"chips_bonus": result.chips_bonus,
		"mult": result.mult,
		"chips": max(0, scored_point_sum) + result.chips_bonus,
	}
