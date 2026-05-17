extends SceneTree
class_name DebugInstallRulesSmokeTest


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const ForgeService = preload("res://scripts/rules/forge/ForgeService.gd")


func _init() -> void:
	print("--- DebugInstallRulesSmokeTest: start ---")

	var all_passed := true
	var service := ForgeService.new()

	var pip_face := _make_base_face()
	service.apply_piece(_make_piece(&"test_pip_6", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 6)]), _die_with_face(pip_face), 0)
	all_passed = _check("set_pip replaces only pip", pip_face.pip == 6 and pip_face.ornament_id == &"orn_chip" and pip_face.mark_id == &"mark_red") and all_passed

	var ornament_face := _make_base_face()
	service.apply_piece(_make_piece(&"test_stay", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"stay")]), _die_with_face(ornament_face), 0)
	all_passed = _check("set_ornament replaces only ornament", ornament_face.ornament_id == &"orn_stay" and ornament_face.pip == 1 and ornament_face.mark_id == &"mark_red") and all_passed

	var legacy_material_face := _make_base_face()
	service.apply_piece(_make_piece(&"test_legacy_glass", [_make_id_op(ForgeOperationDef.OP_SET_MATERIAL, &"glass")]), _die_with_face(legacy_material_face), 0)
	all_passed = _check("set_material maps to ornament", legacy_material_face.ornament_id == &"orn_burst" and legacy_material_face.material_id == &"none") and all_passed

	var mark_face := _make_base_face()
	service.apply_piece(_make_piece(&"test_blue", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"blue")]), _die_with_face(mark_face), 0)
	all_passed = _check("set_mark replaces only mark", mark_face.mark_id == &"mark_blue" and mark_face.pip == 1 and mark_face.ornament_id == &"orn_chip") and all_passed

	var disabled_face := _make_base_face()
	disabled_face.rune_id = &"six"
	disabled_face.level = 2
	service.apply_piece(_make_piece(&"test_odd", [_make_id_op(ForgeOperationDef.OP_SET_RUNE, &"odd")]), _die_with_face(disabled_face), 0)
	service.apply_piece(_make_piece(&"test_upgrade", [_make_int_op(ForgeOperationDef.OP_UPGRADE, 1)]), _die_with_face(disabled_face), 0)
	all_passed = _check("set_rune and upgrade are disabled", disabled_face.rune_id == &"six" and disabled_face.level == 2 and disabled_face.ornament_id == &"orn_chip") and all_passed

	var cleanse_face := _make_base_face()
	cleanse_face.ornament_id = &"curse"
	cleanse_face.mark_id = &"black"
	cleanse_face.pip = 5
	service.apply_piece(_make_piece(&"test_cleanse", [_make_op(ForgeOperationDef.OP_CLEANSE)]), _die_with_face(cleanse_face), 0)
	all_passed = _check("cleanse clears negative ornament and mark only", cleanse_face.pip == 5 and cleanse_face.ornament_id == &"orn_none" and cleanse_face.mark_id == &"mark_none") and all_passed

	var reset_face := _make_base_face()
	reset_face.pip = 4
	service.apply_piece(_make_piece(&"test_reset", [_make_op(ForgeOperationDef.OP_RESET_FACE)]), _die_with_face(reset_face), 0)
	all_passed = _check("reset_face keeps pip and clears new slots", reset_face.pip == 4 and reset_face.ornament_id == &"orn_none" and reset_face.mark_id == &"mark_none") and all_passed

	var compound_face := _make_base_face()
	compound_face.mark_id = &"none"
	service.apply_piece(
		_make_piece(&"test_red_6", [
			_make_int_op(ForgeOperationDef.OP_SET_PIP, 6),
			_make_id_op(ForgeOperationDef.OP_SET_MARK, &"red"),
		]),
		_die_with_face(compound_face),
		0
	)
	all_passed = _check("compound red_6 changes only declared slots", compound_face.pip == 6 and compound_face.mark_id == &"mark_red" and compound_face.ornament_id == &"orn_chip") and all_passed

	var preview_source := _make_base_face()
	var preview := service.preview_face_after_apply(_make_piece(&"preview_pip_6", [_make_int_op(ForgeOperationDef.OP_SET_PIP, 6)]), preview_source)
	all_passed = _check("preview does not mutate original", preview_source.pip == 1 and preview_source.ornament_id == &"orn_chip" and preview_source.mark_id == &"mark_red") and all_passed
	all_passed = _check("preview shows modified result", preview.pip == 6 and preview.ornament_id == &"orn_chip" and preview.mark_id == &"mark_red") and all_passed

	var warning_face := _make_base_face()
	var ornament_warning := service.get_install_warning_text(_make_piece(&"warn_burst", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"burst")]), warning_face)
	all_passed = _check("ornament replacement warning is Chinese", ornament_warning.contains("将替换面饰：筹码面饰 → 爆裂面饰")) and all_passed
	all_passed = _check("ornament replacement warning hides ids", not _contains_internal_id(ornament_warning)) and all_passed

	var mark_warning := service.get_install_warning_text(_make_piece(&"warn_blue", [_make_id_op(ForgeOperationDef.OP_SET_MARK, &"blue")]), warning_face)
	all_passed = _check("mark replacement warning is Chinese", mark_warning.contains("将替换印记：红印 → 蓝印")) and all_passed
	all_passed = _check("mark replacement warning hides ids", not _contains_internal_id(mark_warning)) and all_passed

	var preview_text := service.get_install_preview_text(_make_piece(&"preview_burst", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"burst")]), warning_face)
	all_passed = _check("preview text uses new visible slots", preview_text.contains("安装前") and preview_text.contains("点数") and preview_text.contains("面饰") and preview_text.contains("印记")) and all_passed
	all_passed = _check("preview text hides removed slots", not _contains_removed_terms(preview_text)) and all_passed
	var negative_face := _make_base_face()
	var negative_piece := _make_piece(&"bad_negative", [_make_id_op(ForgeOperationDef.OP_SET_ORNAMENT, &"orn_negative")])
	all_passed = _check("orn_negative cannot apply to face", not service.can_apply_piece(negative_piece, _die_with_face(negative_face), 0)) and all_passed
	service.apply_piece(negative_piece, _die_with_face(negative_face), 0)
	all_passed = _check("orn_negative does not enter face ornament slot", negative_face.ornament_id == &"orn_chip") and all_passed

	print("PASS: DebugInstallRulesSmokeTest" if all_passed else "FAIL: DebugInstallRulesSmokeTest")
	print("--- DebugInstallRulesSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _make_base_face() -> FaceState:
	var face := FaceState.new()
	face.pip = 1
	face.ornament_id = &"orn_chip"
	face.mark_id = &"mark_red"
	face.rune_id = &"six"
	face.level = 2
	return face


func _die_with_face(face: FaceState) -> DieState:
	var die := DieState.new()
	die.faces.append(face)
	die.face_weights.append(1)
	return die


func _make_piece(id: StringName, operations: Array) -> ForgePieceDef:
	var piece := ForgePieceDef.new()
	piece.id = id
	for operation in operations:
		if operation is ForgeOperationDef:
			piece.operations.append(operation)
	return piece


func _make_op(op: StringName) -> ForgeOperationDef:
	var operation := ForgeOperationDef.new()
	operation.op = op
	return operation


func _make_int_op(op: StringName, value_int: int) -> ForgeOperationDef:
	var operation := _make_op(op)
	operation.value_int = value_int
	return operation


func _make_id_op(op: StringName, value_id: StringName) -> ForgeOperationDef:
	var operation := _make_op(op)
	operation.value_id = value_id
	return operation


func _contains_internal_id(text: String) -> bool:
	for id in ["glass", "steel", "chip", "burst", "stay", "red", "blue", "material_id", "mark_id", "rune_id"]:
		if text.contains(id):
			return true
	return false


func _contains_removed_terms(text: String) -> bool:
	for term in ["材质", "符文", "等级", "material", "rune", "level", "glass", "steel"]:
		if text.contains(term):
			return true
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
