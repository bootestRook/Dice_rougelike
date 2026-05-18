extends RefCounted
class_name ComboLevelService


const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")


func use_from_pack(run_state, combo_id: StringName) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var normalized_id := ComboUpgradeCatalog.normalize_combo_id(combo_id)
	if normalized_id == &"" or not ComboUpgradeCatalog.has_combo(normalized_id):
		return {"success": false, "message": "主骰型升级候选无效"}

	var before_level := 1
	if run_state.has_method("get_combo_level"):
		before_level = run_state.get_combo_level(normalized_id)
	if not run_state.increase_combo_level(normalized_id, 1):
		return {"success": false, "message": "主骰型升级失败"}

	var after_level := before_level + 1
	var message := "[补充包] 选择 主骰型升级：%s，%s等级 +1。" % [
		DisplayNames.combo_name(normalized_id),
		DisplayNames.combo_name(normalized_id),
	]
	if run_state.has_method("record_shop_log"):
		run_state.record_shop_log(message, {
			"kind": &"combo_upgrade",
			"combo_id": normalized_id,
			"from": before_level,
			"to": after_level,
		})
	return {
		"success": true,
		"message": message,
		"combo_id": normalized_id,
		"from": before_level,
		"to": after_level,
	}
