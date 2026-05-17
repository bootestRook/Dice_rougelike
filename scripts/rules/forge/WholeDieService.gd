extends RefCounted
class_name WholeDieService


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const DieBodyCatalog = preload("res://scripts/rules/forge/DieBodyCatalog.gd")
const WholeDieServiceCatalog = preload("res://scripts/rules/forge/WholeDieServiceCatalog.gd")


var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


static func get_legal_pips(face_count: int) -> Array[int]:
	return DieState.get_legal_pips(face_count)


static func clamp_or_reset_pip_for_face_count(pip: int, face_count: int) -> int:
	return DieState.clamp_or_reset_pip_for_face_count(pip, face_count)


func create_plain_face_for_die(die: DieState) -> FaceState:
	var face := FaceState.new()
	var legal_pips := get_legal_pips(die.face_count if die != null else 6)
	if legal_pips.is_empty():
		face.pip = 1
	else:
		face.pip = legal_pips[rng.randi_range(0, legal_pips.size() - 1)]
	face.ornament_id = FaceState.ORN_NONE
	face.mark_id = FaceState.MARK_NONE
	face.material_id = &"none"
	face.rune_id = &"none"
	face.level = 1
	return face


func init_biased_weights(die: DieState, biased_face_index: int) -> void:
	if die == null:
		return
	die.face_weights.clear()
	for _index in range(die.face_count):
		die.face_weights.append(1)
	if biased_face_index < 0 or biased_face_index >= die.face_count:
		biased_face_index = rng.randi_range(0, max(0, die.face_count - 1))
	die.face_weights[biased_face_index] += 1


func can_use_service(run_state: RunState, service_id: StringName, args: Dictionary = {}) -> bool:
	return get_unavailable_reason(run_state, service_id, args) == ""


func get_unavailable_reason(run_state: RunState, service_id: StringName, args: Dictionary = {}) -> String:
	if run_state == null:
		return "缺少本局状态"
	if not WholeDieServiceCatalog.has_service(service_id):
		return "未知整骰服务"
	var entry := _get_die_entry(run_state, args)
	if not bool(entry.get("valid", false)):
		return str(entry.get("error", "请选择目标骰子"))
	var die: DieState = entry["die"]

	match service_id:
		WholeDieServiceCatalog.DIE_CONVERT_D4:
			if die.face_count != 6 and die.face_count != 8:
				return "只能选择 D6 或 D8"
			if _unique_kept_indices(args, die.faces.size(), 4).size() != 4:
				return "需要选择 4 个保留面位"
		WholeDieServiceCatalog.DIE_CONVERT_D6:
			if die.face_count == 6:
				return "目标已经是 D6"
			if die.face_count != 4 and die.face_count != 8:
				return "只能选择 D4 或 D8"
			if die.face_count == 8 and _unique_kept_indices(args, die.faces.size(), 6).size() != 6:
				return "需要选择 6 个保留面位"
		WholeDieServiceCatalog.DIE_CONVERT_D8:
			if die.face_count != 4 and die.face_count != 6:
				return "只能选择 D4 或 D6"
		WholeDieServiceCatalog.DIE_CHANGE_BODY:
			var raw_body_id := StringName(str(args.get("body_id", &"")))
			if raw_body_id == &"" or raw_body_id == &"none":
				return "请选择有效骰胚"
			var new_body_id := DieBodyCatalog.normalize_body_id(raw_body_id)
			if not DieBodyCatalog.has_body(new_body_id):
				return "请选择有效骰胚"
		WholeDieServiceCatalog.DIE_FULL_REFORGE:
			var keep_face_index := int(args.get("keep_face_index", -1))
			if keep_face_index < 0 or keep_face_index >= die.faces.size():
				return "需要选择 1 个保留面位"
	return ""


func apply_service(run_state: RunState, service_id: StringName, args: Dictionary = {}) -> Dictionary:
	match service_id:
		WholeDieServiceCatalog.DIE_CONVERT_D4:
			return convert_die_to_d4(run_state, int(args.get("die_index", -1)), _kept_faces_from_args(args), int(args.get("biased_face_index", -1)))
		WholeDieServiceCatalog.DIE_CONVERT_D6:
			return convert_die_to_d6(run_state, int(args.get("die_index", -1)), _kept_faces_from_args(args), int(args.get("biased_face_index", -1)))
		WholeDieServiceCatalog.DIE_CONVERT_D8:
			return convert_die_to_d8(run_state, int(args.get("die_index", -1)), int(args.get("biased_face_index", -1)))
		WholeDieServiceCatalog.DIE_CHANGE_BODY:
			return change_body(run_state, int(args.get("die_index", -1)), StringName(str(args.get("body_id", &""))), int(args.get("biased_face_index", -1)))
		WholeDieServiceCatalog.DIE_FULL_REFORGE:
			return full_reforge(run_state, int(args.get("die_index", -1)), int(args.get("keep_face_index", -1)), int(args.get("biased_face_index", -1)))
		_:
			return _fail(_make_result(service_id), "未知整骰服务")


func convert_die_to_d4(run_state: RunState, die_index: int, kept_face_indices: Array, biased_face_index: int = -1) -> Dictionary:
	var service_id := WholeDieServiceCatalog.DIE_CONVERT_D4
	var args := {"die_index": die_index, "kept_face_indices": kept_face_indices, "biased_face_index": biased_face_index}
	var result := _validate_result(run_state, service_id, args)
	if not bool(result.get("success", false)):
		return result
	var die: DieState = result["die"]
	var kept := _unique_kept_indices(args, die.faces.size(), 4)
	_keep_faces_in_original_order(die, kept)
	die.face_count = 4
	_clamp_faces_to_face_count(die)
	_refresh_weights_for_body(die, biased_face_index)
	return _finish_die_change(run_state, result, "面数转换结果：%s 已转换为 D4。" % [_die_label(result)])


func convert_die_to_d6(run_state: RunState, die_index: int, kept_face_indices: Array = [], biased_face_index: int = -1) -> Dictionary:
	var service_id := WholeDieServiceCatalog.DIE_CONVERT_D6
	var args := {"die_index": die_index, "kept_face_indices": kept_face_indices, "biased_face_index": biased_face_index}
	var result := _validate_result(run_state, service_id, args)
	if not bool(result.get("success", false)):
		return result
	var die: DieState = result["die"]
	if die.face_count == 4:
		die.face_count = 6
		while die.faces.size() < die.face_count:
			die.faces.append(create_plain_face_for_die(die))
	else:
		var kept := _unique_kept_indices(args, die.faces.size(), 6)
		_keep_faces_in_original_order(die, kept)
		die.face_count = 6
		_clamp_faces_to_face_count(die)
	_refresh_weights_for_body(die, biased_face_index)
	return _finish_die_change(run_state, result, "面数转换结果：%s 已转换为 D6。" % [_die_label(result)])


func convert_die_to_d8(run_state: RunState, die_index: int, biased_face_index: int = -1) -> Dictionary:
	var service_id := WholeDieServiceCatalog.DIE_CONVERT_D8
	var args := {"die_index": die_index, "biased_face_index": biased_face_index}
	var result := _validate_result(run_state, service_id, args)
	if not bool(result.get("success", false)):
		return result
	var die: DieState = result["die"]
	die.face_count = 8
	while die.faces.size() < die.face_count:
		die.faces.append(create_plain_face_for_die(die))
	_clamp_faces_to_face_count(die)
	_refresh_weights_for_body(die, biased_face_index)
	return _finish_die_change(run_state, result, "面数转换结果：%s 已转换为 D8。" % [_die_label(result)])


func change_body(run_state: RunState, die_index: int, new_body_id: StringName, biased_face_index: int = -1) -> Dictionary:
	var service_id := WholeDieServiceCatalog.DIE_CHANGE_BODY
	var normalized_body_id := DieBodyCatalog.normalize_body_id(new_body_id)
	var args := {"die_index": die_index, "body_id": new_body_id, "biased_face_index": biased_face_index}
	var result := _validate_result(run_state, service_id, args)
	if not bool(result.get("success", false)):
		return result
	var die: DieState = result["die"]
	var old_body_id := DieBodyCatalog.normalize_body_id(die.body_id)
	die.body_id = normalized_body_id
	_refresh_weights_for_body(die, biased_face_index)
	result["old_body_id"] = old_body_id
	result["body_id"] = normalized_body_id
	return _finish_die_change(run_state, result, "骰胚更换结果：%s 从%s更换为%s。" % [
		_die_label(result),
		DisplayNames.body_name(old_body_id),
		DisplayNames.body_name(normalized_body_id),
	])


func full_reforge(run_state: RunState, die_index: int, keep_face_index: int, biased_face_index: int = -1) -> Dictionary:
	var service_id := WholeDieServiceCatalog.DIE_FULL_REFORGE
	var args := {"die_index": die_index, "keep_face_index": keep_face_index, "biased_face_index": biased_face_index}
	var result := _validate_result(run_state, service_id, args)
	if not bool(result.get("success", false)):
		return result
	var die: DieState = result["die"]
	var kept_face := die.faces[keep_face_index]
	for face_index in range(die.faces.size()):
		if face_index == keep_face_index:
			continue
		die.faces[face_index] = create_plain_face_for_die(die)
	die.faces[keep_face_index] = kept_face
	_refresh_weights_for_body(die, biased_face_index)
	result["kept_face_index"] = keep_face_index
	return _finish_die_change(run_state, result, "整骰重铸结果：%s 保留第 %d 面，其余面位已重置。" % [_die_label(result), keep_face_index + 1])


func get_confirmation_text(run_state: RunState, service_id: StringName, args: Dictionary = {}) -> String:
	var entry := _get_die_entry(run_state, args)
	if not bool(entry.get("valid", false)):
		return str(entry.get("error", "请选择目标骰子"))
	var die: DieState = entry["die"]
	match service_id:
		WholeDieServiceCatalog.DIE_CONVERT_D4, WholeDieServiceCatalog.DIE_CONVERT_D6:
			var kept := _kept_faces_from_args(args)
			return "确认面数转换？\n将保留面位：%s\n将移除其他面位；保留面点数会按目标面数合法化。" % [_face_index_list_text(kept)]
		WholeDieServiceCatalog.DIE_CONVERT_D8:
			return "确认面数转换？\n将保留当前 %d 个面位，并新增普通面直到 D8。" % [die.faces.size()]
		WholeDieServiceCatalog.DIE_CHANGE_BODY:
			return "确认更换骰胚？\n将保留面数和所有骰面，只替换骰胚。"
		WholeDieServiceCatalog.DIE_FULL_REFORGE:
			var keep_face_index := int(args.get("keep_face_index", -1))
			return "确认整骰重铸？\n将保留第 %d 面。\n其他面位将重置为合法随机点数、无面饰、无印记。" % [keep_face_index + 1]
		_:
			return "确认执行整骰服务？"


func _validate_result(run_state: RunState, service_id: StringName, args: Dictionary) -> Dictionary:
	var result := _make_result(service_id)
	var error := get_unavailable_reason(run_state, service_id, args)
	if error != "":
		return _fail(result, error)
	var entry := _get_die_entry(run_state, args)
	result["success"] = true
	result["die"] = entry["die"]
	result["die_index"] = int(entry.get("die_index", -1))
	result["face_count_before"] = (entry["die"] as DieState).face_count
	result["body_id_before"] = (entry["die"] as DieState).body_id
	result["faces_before"] = _face_snapshots(entry["die"])
	return result


func _finish_die_change(run_state: RunState, result: Dictionary, message: String) -> Dictionary:
	var die: DieState = result.get("die", null)
	if die == null:
		return _fail(result, "目标骰子无效")
	result["success"] = die.has_valid_shape()
	result["face_count_after"] = die.face_count
	result["body_id_after"] = die.body_id
	result["faces_after"] = _face_snapshots(die)
	result["face_weights"] = die.face_weights.duplicate()
	result["message"] = message
	result["events"].append(message)
	if not bool(result["success"]):
		result["message"] = "整骰服务失败：%s" % ["；".join(die.get_shape_errors())]
	if run_state != null and run_state.has_method("record_foundry_log"):
		run_state.record_foundry_log(
			StringName(str(result.get("service_id", &""))),
			str(result.get("service_name", "")),
			str(result.get("message", "")),
			{
				"die_index": int(result.get("die_index", -1)),
				"face_count_after": int(result.get("face_count_after", 0)),
				"body_id_after": StringName(str(result.get("body_id_after", &""))),
			}
		)
	result.erase("die")
	return result


func _refresh_weights_for_body(die: DieState, biased_face_index: int) -> void:
	if die == null:
		return
	if DieBodyCatalog.normalize_body_id(die.body_id) == DieState.BODY_BIASED:
		init_biased_weights(die, biased_face_index)
		return
	die.face_weights.clear()
	for _index in range(die.face_count):
		die.face_weights.append(1)


func _clamp_faces_to_face_count(die: DieState) -> void:
	for face in die.faces:
		if face == null:
			continue
		face.pip = clamp_or_reset_pip_for_face_count(face.pip, die.face_count)
		face.ornament_id = FaceState.normalize_ornament_id(face.ornament_id)
		face.mark_id = FaceState.normalize_mark_id(face.mark_id)


func _keep_faces_in_original_order(die: DieState, kept_indices: Array[int]) -> void:
	var kept_lookup := {}
	for index in kept_indices:
		kept_lookup[index] = true
	var kept_faces: Array[FaceState] = []
	for face_index in range(die.faces.size()):
		if kept_lookup.has(face_index):
			kept_faces.append(die.faces[face_index])
	die.faces = kept_faces


func _unique_kept_indices(args: Dictionary, face_size: int, required_count: int) -> Array[int]:
	var result: Array[int] = []
	for value in _kept_faces_from_args(args):
		var index := int(value)
		if index < 0 or index >= face_size:
			continue
		if not result.has(index):
			result.append(index)
	if result.size() != required_count:
		return []
	return result


func _kept_faces_from_args(args: Dictionary) -> Array:
	if args.has("kept_face_indices") and args["kept_face_indices"] is Array:
		return args["kept_face_indices"]
	if args.has("keep_face_indices") and args["keep_face_indices"] is Array:
		return args["keep_face_indices"]
	if args.has("faces") and args["faces"] is Array:
		return args["faces"]
	return []


func _get_die_entry(run_state: RunState, args: Dictionary) -> Dictionary:
	if run_state == null:
		return {"valid": false, "error": "缺少本局状态"}
	run_state.ensure_starting_dice()
	var die_index := int(args.get("die_index", -1))
	if die_index < 0 or die_index >= run_state.dice.size():
		return {"valid": false, "error": "请选择目标骰子"}
	var die := run_state.dice[die_index]
	if die == null:
		return {"valid": false, "error": "目标骰子无效"}
	if die.faces.size() != die.face_count:
		return {"valid": false, "error": "目标骰子面数异常"}
	return {
		"valid": true,
		"die": die,
		"die_index": die_index,
	}


func _make_result(service_id: StringName) -> Dictionary:
	var def := WholeDieServiceCatalog.get_def(service_id)
	return {
		"success": false,
		"service_id": service_id,
		"service_name": def.display_name if def != null else str(service_id),
		"message": "",
		"events": [],
		"die_index": -1,
	}


func _fail(result: Dictionary, message: String) -> Dictionary:
	result["success"] = false
	result["message"] = message
	result["events"].append(message)
	return result


func _face_snapshots(die: DieState) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	if die == null:
		return snapshots
	for face_index in range(die.faces.size()):
		var face := die.faces[face_index]
		snapshots.append({
			"face_index": face_index,
			"pip": face.pip if face != null else 0,
			"ornament_id": face.ornament_id if face != null else FaceState.ORN_NONE,
			"mark_id": face.mark_id if face != null else FaceState.MARK_NONE,
		})
	return snapshots


func _die_label(result: Dictionary) -> String:
	return "骰子 %d" % [int(result.get("die_index", -1)) + 1]


func _face_index_list_text(indices: Array) -> String:
	var parts := PackedStringArray()
	for value in indices:
		parts.append("第 %d 面" % [int(value) + 1])
	return "、".join(parts) if not parts.is_empty() else "未选择"
