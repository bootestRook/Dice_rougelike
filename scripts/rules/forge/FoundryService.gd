extends RefCounted
class_name FoundryService


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const FoundryServiceCatalog = preload("res://scripts/rules/forge/FoundryServiceCatalog.gd")
const FoundryServiceDef = preload("res://scripts/data_defs/FoundryServiceDef.gd")


const MAIN_COMBO_IDS := [
	&"combo_scatter",
	&"combo_pair",
	&"combo_two_pair",
	&"combo_three_kind",
	&"combo_full_house",
	&"combo_four_kind",
	&"combo_straight",
	&"combo_five_kind",
]


var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


static func get_legal_pips(face_count: int) -> Array[int]:
	var result: Array[int] = []
	match face_count:
		4:
			result.append_array([1, 2, 3, 4])
		6:
			result.append_array([1, 2, 3, 4, 5, 6])
		8:
			result.append_array([1, 2, 3, 4, 5, 6, 7, 8])
		_:
			push_error("Unsupported face_count: %s" % [face_count])
	return result


static func get_high_pips(face_count: int) -> Array[int]:
	var result: Array[int] = []
	for pip in get_legal_pips(face_count):
		if [5, 6, 7, 8].has(pip):
			result.append(pip)
	return result


static func get_ordinary_ornament_pool() -> Array[StringName]:
	return FoundryServiceCatalog.get_ordinary_ornament_pool()


static func get_rare_ornament_pool() -> Array[StringName]:
	return FoundryServiceCatalog.get_rare_ornament_pool()


func can_use_service(run_state: RunState, service_id: StringName, args: Dictionary = {}) -> bool:
	return get_unavailable_reason(run_state, service_id, args) == ""


func can_apply_to_die(run_state: RunState, service_id: StringName, die_index: int) -> bool:
	return can_use_service(run_state, service_id, {"die_index": die_index})


func get_service_card_unavailable_reason(run_state: RunState, service_id: StringName) -> String:
	var def := FoundryServiceCatalog.get_def(service_id)
	if run_state == null:
		return "缺少本局状态"
	if def == null:
		return "未知铸骰坊服务"
	if def.requires_item_slot:
		run_state.ensure_item_slots_from_legacy()
		if run_state.get_free_item_slot_count() <= 0:
			return "道具槽位不足"
	match service_id:
		FoundryServiceCatalog.FOUNDRY_NEGATIVE_TOOL_SLOT, FoundryServiceCatalog.FOUNDRY_BURN_FOR_COINS, FoundryServiceCatalog.FOUNDRY_TOOL_CLONE_PURGE:
			return get_unavailable_reason(run_state, service_id)
	return ""


func can_copy_face_to_target(run_state: RunState, source_face_ref: Dictionary, target_face_ref: Dictionary) -> bool:
	var source_entry := _get_face_entry(run_state, source_face_ref)
	if not bool(source_entry.get("valid", false)):
		return false
	var target_entry := _get_face_entry(run_state, target_face_ref)
	if not bool(target_entry.get("valid", false)):
		return false
	var source_face: FaceState = source_entry["face"]
	var target_die: DieState = target_entry["die"]
	return get_legal_pips(target_die.face_count).has(source_face.pip)


func get_unavailable_reason(run_state: RunState, service_id: StringName, args: Dictionary = {}) -> String:
	var def := FoundryServiceCatalog.get_def(service_id)
	if run_state == null:
		return "缺少本局状态"
	if def == null:
		return "未知铸骰坊服务"

	if def.requires_item_slot:
		run_state.ensure_item_slots_from_legacy()
		if run_state.get_free_item_slot_count() <= 0:
			return "道具槽位不足"

	match service_id:
		FoundryServiceCatalog.FOUNDRY_HIGH_PIP_REFORGE:
			var high_die_entry := _get_die_entry(run_state, _target_die_ref(args))
			if not bool(high_die_entry.get("valid", false)):
				return str(high_die_entry.get("error", "请选择目标骰子"))
			var high_die: DieState = high_die_entry["die"]
			if get_high_pips(high_die.face_count).is_empty():
				return "目标骰子没有合法高点"
		FoundryServiceCatalog.FOUNDRY_SIX_PIP_REFORGE:
			var six_die_entry := _get_die_entry(run_state, _target_die_ref(args))
			if not bool(six_die_entry.get("valid", false)):
				return str(six_die_entry.get("error", "请选择目标骰子"))
			var six_die: DieState = six_die_entry["die"]
			if not get_legal_pips(six_die.face_count).has(6):
				return "目标骰子的合法点数不包含 6"
		FoundryServiceCatalog.FOUNDRY_RANDOM_PIP_REFORGE, FoundryServiceCatalog.FOUNDRY_POLY_GAMBLE:
			var die_entry := _get_die_entry(run_state, _target_die_ref(args))
			if not bool(die_entry.get("valid", false)):
				return str(die_entry.get("error", "请选择目标骰子"))
		FoundryServiceCatalog.FOUNDRY_GOLD_MARK, FoundryServiceCatalog.FOUNDRY_RED_MARK, FoundryServiceCatalog.FOUNDRY_BLUE_MARK, FoundryServiceCatalog.FOUNDRY_PURPLE_MARK, FoundryServiceCatalog.FOUNDRY_RARE_ORNAMENT:
			var face_entry := _get_face_entry(run_state, _target_face_ref(args))
			if not bool(face_entry.get("valid", false)):
				return str(face_entry.get("error", "请选择目标骰面"))
		FoundryServiceCatalog.FOUNDRY_SAME_PIP_SYNC:
			var sync_error := _validate_same_pip_sync(run_state, _target_faces(args))
			if sync_error != "":
				return sync_error
		FoundryServiceCatalog.FOUNDRY_NEGATIVE_TOOL_SLOT:
			if _non_negative_tool_indexes(run_state).is_empty():
				return "没有可转为负载的已安装骰具"
		FoundryServiceCatalog.FOUNDRY_BURN_FOR_COINS:
			if _all_face_entries(run_state).size() < 5:
				return "当前出战骰面不足 5 个"
		FoundryServiceCatalog.FOUNDRY_TOOL_CLONE_PURGE:
			var clone_error := _validate_tool_clone_purge(run_state)
			if clone_error != "":
				return clone_error
		FoundryServiceCatalog.FOUNDRY_FACE_DOUBLE_COPY:
			var copy_error := _validate_face_double_copy(run_state, _source_face_ref(args), _target_faces(args))
			if copy_error != "":
				return copy_error

	return ""


func apply_service(run_state: RunState, service_id: StringName, args: Dictionary = {}) -> Dictionary:
	match service_id:
		FoundryServiceCatalog.FOUNDRY_HIGH_PIP_REFORGE, FoundryServiceCatalog.FOUNDRY_SIX_PIP_REFORGE, FoundryServiceCatalog.FOUNDRY_RANDOM_PIP_REFORGE:
			var pending := create_reforge_resolution(run_state, service_id, _target_die_ref(args))
			if not bool(pending.get("success", false)):
				return pending
			return commit_reforge_candidate(run_state, pending, int(args.get("candidate_index", 0)))
		FoundryServiceCatalog.FOUNDRY_GOLD_MARK:
			return apply_mark(run_state, service_id, _target_face_ref(args), FaceState.MARK_GOLD)
		FoundryServiceCatalog.FOUNDRY_RED_MARK:
			return apply_mark(run_state, service_id, _target_face_ref(args), FaceState.MARK_RED)
		FoundryServiceCatalog.FOUNDRY_BLUE_MARK:
			return apply_mark(run_state, service_id, _target_face_ref(args), FaceState.MARK_BLUE)
		FoundryServiceCatalog.FOUNDRY_PURPLE_MARK:
			return apply_mark(run_state, service_id, _target_face_ref(args), FaceState.MARK_PURPLE)
		FoundryServiceCatalog.FOUNDRY_RARE_ORNAMENT:
			return apply_rare_ornament(run_state, _target_face_ref(args))
		FoundryServiceCatalog.FOUNDRY_RARE_TOOL_PACK:
			return apply_tool_pack(run_state, service_id, &"rare")
		FoundryServiceCatalog.FOUNDRY_LEGENDARY_TOOL_PACK:
			return apply_tool_pack(run_state, service_id, &"legendary")
		FoundryServiceCatalog.FOUNDRY_SAME_PIP_SYNC:
			return apply_same_pip_sync(run_state, _target_faces(args))
		FoundryServiceCatalog.FOUNDRY_NEGATIVE_TOOL_SLOT:
			return apply_negative_tool_slot(run_state)
		FoundryServiceCatalog.FOUNDRY_BURN_FOR_COINS:
			return apply_burn_for_coins(run_state)
		FoundryServiceCatalog.FOUNDRY_TOOL_CLONE_PURGE:
			return apply_tool_clone_purge(run_state)
		FoundryServiceCatalog.FOUNDRY_POLY_GAMBLE:
			return apply_poly_gamble(run_state, _target_die_ref(args))
		FoundryServiceCatalog.FOUNDRY_FACE_DOUBLE_COPY:
			return apply_face_double_copy(run_state, _source_face_ref(args), _target_faces(args))
		FoundryServiceCatalog.FOUNDRY_ALL_COMBO_UPGRADE:
			return apply_all_combo_upgrade(run_state)
		_:
			return _fail(_make_result(service_id), "未知铸骰坊服务")


func create_reforge_resolution(run_state: RunState, service_id: StringName, target_die_ref: Dictionary) -> Dictionary:
	var result := _make_result(service_id)
	var validation_error := get_unavailable_reason(run_state, service_id, target_die_ref)
	if validation_error != "":
		return _fail(result, validation_error)

	var die_entry := _get_die_entry(run_state, target_die_ref)
	var die: DieState = die_entry["die"]
	var sacrifice_face_index := rng.randi_range(0, die.faces.size() - 1)
	var candidates: Array[FaceState] = []
	var pip_pool: Array[int] = []
	var candidate_count := 0

	match service_id:
		FoundryServiceCatalog.FOUNDRY_HIGH_PIP_REFORGE:
			pip_pool = get_high_pips(die.face_count)
			candidate_count = 3
		FoundryServiceCatalog.FOUNDRY_SIX_PIP_REFORGE:
			pip_pool.append(6)
			candidate_count = 2
		FoundryServiceCatalog.FOUNDRY_RANDOM_PIP_REFORGE:
			pip_pool = get_legal_pips(die.face_count)
			candidate_count = 4
		_:
			return _fail(result, "该服务不会生成候选骰面")

	for _index in range(candidate_count):
		candidates.append(_make_candidate_face(pip_pool))

	result["success"] = true
	result["pending_foundry_resolution"] = true
	result["target_die_index"] = int(die_entry.get("die_index", -1))
	result["sacrifice_face_index"] = sacrifice_face_index
	result["sacrifice_face"] = die.faces[sacrifice_face_index].clone()
	result["candidates"] = candidates
	result["message"] = "候选骰面已生成，请选择 1 个候选面。"
	_add_event(result, result["message"])
	return result


func commit_reforge_candidate(run_state: RunState, pending_resolution: Dictionary, candidate_index: int) -> Dictionary:
	var service_id := StringName(str(pending_resolution.get("service_id", &"")))
	var result := _make_result(service_id)
	if run_state == null:
		return _fail(result, "缺少本局状态")
	if not bool(pending_resolution.get("pending_foundry_resolution", false)):
		return _fail(result, "缺少待处理的铸骰坊候选")

	var die_index := int(pending_resolution.get("target_die_index", -1))
	var face_index := int(pending_resolution.get("sacrifice_face_index", -1))
	var candidates: Array = pending_resolution.get("candidates", [])
	if candidate_index < 0 or candidate_index >= candidates.size():
		return _fail(result, "候选骰面不存在")
	var candidate := candidates[candidate_index] as FaceState
	if candidate == null:
		return _fail(result, "候选骰面无效")

	var entry := _get_face_entry(run_state, {"die_index": die_index, "face_index": face_index})
	if not bool(entry.get("valid", false)):
		return _fail(result, str(entry.get("error", "目标骰面无效")))
	var face: FaceState = entry["face"]
	face.pip = candidate.pip
	face.ornament_id = candidate.ornament_id
	face.mark_id = FaceState.MARK_NONE
	face.material_id = &"none"
	_add_changed_face(result, entry)

	var def := FoundryServiceCatalog.get_def(service_id)
	var service_name := def.get_display_name() if def != null else str(service_id)
	var message := "[铸骰坊] %s：骰子 %s 的第 %d 面被回炉，获得 %d / %s / %s。" % [
		service_name,
		_die_label(entry),
		face_index + 1,
		face.pip,
		DisplayNames.ornament_name(face.ornament_id),
		DisplayNames.mark_name(face.mark_id),
	]
	result["success"] = true
	result["message"] = message
	_record_log(run_state, result, message, {
		"die_index": die_index,
		"face_index": face_index,
		"pip": face.pip,
		"ornament_id": face.ornament_id,
		"mark_id": face.mark_id,
	})
	return result


func apply_mark(run_state: RunState, service_id: StringName, target_face_ref: Dictionary, mark_id: StringName) -> Dictionary:
	var result := _make_result(service_id)
	var validation_error := get_unavailable_reason(run_state, service_id, target_face_ref)
	if validation_error != "":
		return _fail(result, validation_error)

	var entry := _get_face_entry(run_state, target_face_ref)
	var face: FaceState = entry["face"]
	var old_mark := face.mark_id
	face.mark_id = FaceState.normalize_mark_id(mark_id)
	_add_changed_face(result, entry)

	var def := FoundryServiceCatalog.get_def(service_id)
	var service_name := def.get_display_name() if def != null else str(service_id)
	var message := "[铸骰坊] %s：骰子 %s 的第 %d 面印记变为 %s。" % [
		service_name,
		_die_label(entry),
		int(entry.get("face_index", -1)) + 1,
		DisplayNames.mark_name(face.mark_id),
	]
	result["success"] = true
	result["message"] = message
	result["replaced_mark_id"] = old_mark
	_record_log(run_state, result, message, {
		"die_index": int(entry.get("die_index", -1)),
		"face_index": int(entry.get("face_index", -1)),
		"old_mark_id": old_mark,
		"mark_id": face.mark_id,
	})
	return result


func apply_rare_ornament(run_state: RunState, target_face_ref: Dictionary) -> Dictionary:
	var service_id := FoundryServiceCatalog.FOUNDRY_RARE_ORNAMENT
	var result := _make_result(service_id)
	var validation_error := get_unavailable_reason(run_state, service_id, target_face_ref)
	if validation_error != "":
		return _fail(result, validation_error)

	var entry := _get_face_entry(run_state, target_face_ref)
	var face: FaceState = entry["face"]
	var ornament_id: StringName = _draw_id(get_rare_ornament_pool())
	face.ornament_id = ornament_id
	face.material_id = &"none"
	_add_changed_face(result, entry)

	var message := "[铸骰坊] 稀饰灌注：骰子 %s 的第 %d 面获得 %s。" % [
		_die_label(entry),
		int(entry.get("face_index", -1)) + 1,
		DisplayNames.ornament_name(ornament_id),
	]
	result["success"] = true
	result["message"] = message
	result["ornament_id"] = ornament_id
	_record_log(run_state, result, message, {
		"die_index": int(entry.get("die_index", -1)),
		"face_index": int(entry.get("face_index", -1)),
		"ornament_id": ornament_id,
	})
	return result


func apply_tool_pack(run_state: RunState, service_id: StringName, rarity: StringName) -> Dictionary:
	var result := _make_result(service_id)
	var validation_error := get_unavailable_reason(run_state, service_id)
	if validation_error != "":
		return _fail(result, validation_error)

	var pool := FoundryServiceCatalog.get_legendary_dice_tool_item_pool() if rarity == &"legendary" else FoundryServiceCatalog.get_rare_dice_tool_item_pool()
	if pool.is_empty():
		return _fail(result, "骰具道具池为空")

	var before_coins := run_state.coins
	var tool_data: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var item: ItemInstance = ItemInstance.create_dice_tool(
		StringName(str(tool_data.get("id", &""))),
		str(tool_data.get("name", "")),
		int(tool_data.get("sell_value", 0))
	)
	item.metadata["rarity"] = StringName(str(tool_data.get("rarity", rarity)))
	if not run_state.add_item_instance_to_slots(item):
		return _fail(result, "道具槽位不足")

	if service_id == FoundryServiceCatalog.FOUNDRY_RARE_TOOL_PACK:
		run_state.coins = 0

	result["success"] = true
	result["generated_items"].append(item.item_id)
	result["coins_delta"] = run_state.coins - before_coins
	var def := FoundryServiceCatalog.get_def(service_id)
	var service_name := def.get_display_name() if def != null else str(service_id)
	var message := "[铸骰坊] %s：生成骰具道具 %s。金币变化 %+d。" % [
		service_name,
		item.display_name,
		int(result["coins_delta"]),
	]
	result["message"] = message
	_record_log(run_state, result, message, {
		"generated_item_id": item.item_id,
		"rarity": rarity,
		"coins_delta": int(result["coins_delta"]),
	})
	return result


func apply_same_pip_sync(run_state: RunState, target_face_refs: Array) -> Dictionary:
	var service_id := FoundryServiceCatalog.FOUNDRY_SAME_PIP_SYNC
	var result := _make_result(service_id)
	var validation_error := _validate_same_pip_sync(run_state, target_face_refs)
	if validation_error != "":
		return _fail(result, validation_error)

	var entries := _face_entries_for_refs(run_state, target_face_refs)
	var common_pips := get_legal_pips((entries[0]["die"] as DieState).face_count)
	for entry in entries:
		common_pips = _intersect_ints(common_pips, get_legal_pips((entry["die"] as DieState).face_count))
	var pip := common_pips[rng.randi_range(0, common_pips.size() - 1)]

	for entry in entries:
		var face: FaceState = entry["face"]
		face.pip = pip
		face.ornament_id = FaceState.ORN_NONE
		face.mark_id = FaceState.MARK_NONE
		face.material_id = &"none"
		_add_changed_face(result, entry)

	var message := "[铸骰坊] 同点同调：%d 个骰面被同步为 %d 点，面饰和印记已清空。" % [entries.size(), pip]
	result["success"] = true
	result["message"] = message
	result["pip"] = pip
	_record_log(run_state, result, message, {
		"count": entries.size(),
		"pip": pip,
	})
	return result


func apply_negative_tool_slot(run_state: RunState) -> Dictionary:
	var service_id := FoundryServiceCatalog.FOUNDRY_NEGATIVE_TOOL_SLOT
	var result := _make_result(service_id)
	var validation_error := get_unavailable_reason(run_state, service_id)
	if validation_error != "":
		return _fail(result, validation_error)

	var indexes := _non_negative_tool_indexes(run_state)
	var chosen_index: int = indexes[rng.randi_range(0, indexes.size() - 1)]
	var tools := _get_installed_tools(run_state)
	var tool: DiceToolState = tools[chosen_index]
	var before_coins := run_state.coins
	tool.is_negative = true
	run_state.coins = 0

	var message := "[铸骰坊] 负载扩槽：骰具 %s 被设为负载骰具。金币变化 %+d。" % [
		_tool_label(tool),
		run_state.coins - before_coins,
	]
	result["success"] = true
	result["message"] = message
	result["coins_delta"] = run_state.coins - before_coins
	result["changed_tool_index"] = chosen_index
	_record_log(run_state, result, message, {
		"tool_index": chosen_index,
		"tool_id": tool.tool_id,
		"coins_delta": int(result["coins_delta"]),
	})
	return result


func apply_burn_for_coins(run_state: RunState) -> Dictionary:
	var service_id := FoundryServiceCatalog.FOUNDRY_BURN_FOR_COINS
	var result := _make_result(service_id)
	var validation_error := get_unavailable_reason(run_state, service_id)
	if validation_error != "":
		return _fail(result, validation_error)

	var pool := _all_face_entries(run_state)
	var chosen: Array[Dictionary] = []
	while chosen.size() < 5 and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		chosen.append(pool[index])
		pool.remove_at(index)

	for entry in chosen:
		var die: DieState = entry["die"]
		var face: FaceState = entry["face"]
		var legal := get_legal_pips(die.face_count)
		face.pip = legal[rng.randi_range(0, legal.size() - 1)]
		face.ornament_id = FaceState.ORN_NONE
		face.mark_id = FaceState.MARK_NONE
		face.material_id = &"none"
		_add_changed_face(result, entry)

	run_state.coins += 20
	result["success"] = true
	result["coins_delta"] = 20
	var message := "[铸骰坊] 熔毁换金：5 个骰面被重置，获得 20 金币。"
	result["message"] = message
	_record_log(run_state, result, message, {
		"count": chosen.size(),
		"coins_delta": 20,
	})
	return result


func apply_tool_clone_purge(run_state: RunState) -> Dictionary:
	var service_id := FoundryServiceCatalog.FOUNDRY_TOOL_CLONE_PURGE
	var result := _make_result(service_id)
	var validation_error := get_unavailable_reason(run_state, service_id)
	if validation_error != "":
		return _fail(result, validation_error)

	var tools := _get_installed_tools(run_state)
	var source_index := rng.randi_range(0, tools.size() - 1)
	var source: DiceToolState = tools[source_index]
	var clone := _clone_tool_for_foundry(source)
	var destroyed_ids: Array[StringName] = []
	for index in range(tools.size()):
		if index == source_index:
			continue
		var destroyed_tool: DiceToolState = tools[index]
		if destroyed_tool != null:
			destroyed_ids.append(destroyed_tool.tool_id)

	_set_installed_tools(run_state, [source, clone])
	result["success"] = true
	result["cloned_tool_id"] = clone.tool_id
	result["destroyed_tools"] = destroyed_ids
	var message := "[铸骰坊] 骰具孤本复刻：复制 %s，并摧毁 %d 个其他骰具。" % [
		_tool_label(source),
		destroyed_ids.size(),
	]
	result["message"] = message
	_record_log(run_state, result, message, {
		"source_tool_id": source.tool_id,
		"cloned_tool_id": clone.tool_id,
		"destroyed_tools": destroyed_ids,
	})
	return result


func apply_poly_gamble(run_state: RunState, target_die_ref: Dictionary) -> Dictionary:
	var service_id := FoundryServiceCatalog.FOUNDRY_POLY_GAMBLE
	var result := _make_result(service_id)
	var validation_error := get_unavailable_reason(run_state, service_id, target_die_ref)
	if validation_error != "":
		return _fail(result, validation_error)

	var die_entry := _get_die_entry(run_state, target_die_ref)
	var die: DieState = die_entry["die"]
	var winner_index := rng.randi_range(0, die.faces.size() - 1)
	for face_index in range(die.faces.size()):
		var face := die.faces[face_index]
		face.ornament_id = FaceState.ORN_POLY if face_index == winner_index else FaceState.ORN_NONE
		face.material_id = &"none"
		_add_changed_face(result, {
			"die": die,
			"face": face,
			"die_index": int(die_entry.get("die_index", -1)),
			"face_index": face_index,
		})

	var message := "[铸骰坊] 多彩孤注：骰子 %s 的第 %d 面获得多彩，其余面饰已清空。" % [
		_die_label(die_entry),
		winner_index + 1,
	]
	result["success"] = true
	result["message"] = message
	result["winner_face_index"] = winner_index
	_record_log(run_state, result, message, {
		"die_index": int(die_entry.get("die_index", -1)),
		"winner_face_index": winner_index,
		"ornament_id": FaceState.ORN_POLY,
	})
	return result


func apply_face_double_copy(run_state: RunState, source_face_ref: Dictionary, target_face_refs: Array) -> Dictionary:
	var service_id := FoundryServiceCatalog.FOUNDRY_FACE_DOUBLE_COPY
	var result := _make_result(service_id)
	var validation_error := _validate_face_double_copy(run_state, source_face_ref, target_face_refs)
	if validation_error != "":
		return _fail(result, validation_error)

	var source_entry := _get_face_entry(run_state, source_face_ref)
	var source_face: FaceState = source_entry["face"]
	var target_entries := _face_entries_for_refs(run_state, target_face_refs)
	for entry in target_entries:
		var target_face: FaceState = entry["face"]
		target_face.pip = source_face.pip
		target_face.ornament_id = source_face.ornament_id
		target_face.mark_id = source_face.mark_id
		target_face.material_id = &"none"
		_add_changed_face(result, entry)

	var message := "[铸骰坊] 骰面双写：来源第 %d 面复制到 2 个目标骰面。" % [int(source_entry.get("face_index", -1)) + 1]
	result["success"] = true
	result["message"] = message
	_record_log(run_state, result, message, {
		"source_die_index": int(source_entry.get("die_index", -1)),
		"source_face_index": int(source_entry.get("face_index", -1)),
		"target_faces": result["changed_faces"],
	})
	return result


func apply_all_combo_upgrade(run_state: RunState) -> Dictionary:
	var service_id := FoundryServiceCatalog.FOUNDRY_ALL_COMBO_UPGRADE
	var result := _make_result(service_id)
	var validation_error := get_unavailable_reason(run_state, service_id)
	if validation_error != "":
		return _fail(result, validation_error)

	if run_state.has_method("ensure_combo_levels"):
		run_state.ensure_combo_levels()

	for combo_id in MAIN_COMBO_IDS:
		var current_level: int = max(1, int(run_state.combo_levels.get(combo_id, 1)))
		run_state.combo_levels[combo_id] = current_level + 1
		result["upgraded_combos"].append({
			"combo_id": combo_id,
			"from": current_level,
			"to": current_level + 1,
		})

	var message := "[铸骰坊] 全主骰型升阶：8 个主骰型等级 +1。"
	result["success"] = true
	result["message"] = message
	_record_log(run_state, result, message, {
		"upgraded_combos": result["upgraded_combos"],
	})
	return result


func get_mark_replacement_warning(face: FaceState) -> String:
	if face == null:
		return ""
	if _is_none_id(face.mark_id):
		return ""
	return "将替换现有印记。"


func _validate_same_pip_sync(run_state: RunState, target_face_refs: Array) -> String:
	if run_state == null:
		return "缺少本局状态"
	if target_face_refs.size() < 2 or target_face_refs.size() > 5:
		return "需要选择 2 到 5 个目标骰面"
	var entries := _face_entries_for_refs(run_state, target_face_refs)
	if entries.size() != target_face_refs.size():
		return "目标骰面无效"
	if _has_duplicate_face_refs(entries):
		return "目标骰面不能重复"
	var common_pips := get_legal_pips((entries[0]["die"] as DieState).face_count)
	for entry in entries:
		common_pips = _intersect_ints(common_pips, get_legal_pips((entry["die"] as DieState).face_count))
	if common_pips.is_empty():
		return "目标骰子没有共同合法点数"
	return ""


func _validate_tool_clone_purge(run_state: RunState) -> String:
	if run_state == null:
		return "缺少本局状态"
	var tools := _get_installed_tools(run_state)
	if tools.is_empty():
		return "没有已安装骰具"
	var capacity: int = max(0, run_state.dice_tool_capacity)
	var has_non_negative_source := false
	for tool_item in tools:
		var tool := tool_item as DiceToolState
		if tool != null and not tool.is_negative:
			has_non_negative_source = true
			break
	var required_capacity := 2 if has_non_negative_source else 1
	if required_capacity > capacity:
		return "骰具槽容量不足"
	return ""


func _validate_face_double_copy(run_state: RunState, source_face_ref: Dictionary, target_face_refs: Array) -> String:
	if run_state == null:
		return "缺少本局状态"
	if target_face_refs.size() != 2:
		return "需要选择 2 个目标骰面"
	var source_entry := _get_face_entry(run_state, source_face_ref)
	if not bool(source_entry.get("valid", false)):
		return str(source_entry.get("error", "来源骰面无效"))
	var target_entries := _face_entries_for_refs(run_state, target_face_refs)
	if target_entries.size() != 2:
		return "目标骰面无效"
	if _has_duplicate_face_refs(target_entries):
		return "两个目标骰面必须彼此不同"
	var source_key := _entry_key(source_entry)
	var source_face: FaceState = source_entry["face"]
	for entry in target_entries:
		if _entry_key(entry) == source_key:
			return "来源骰面不能作为目标"
		var target_die: DieState = entry["die"]
		if not get_legal_pips(target_die.face_count).has(source_face.pip):
			return "来源点数对目标骰子不合法"
	return ""


func _make_candidate_face(pip_pool: Array[int]) -> FaceState:
	var pip := pip_pool[rng.randi_range(0, pip_pool.size() - 1)]
	var ornament_id := _draw_id(get_ordinary_ornament_pool())
	return FaceState.new(pip, ornament_id, FaceState.MARK_NONE)


func _draw_id(pool: Array) -> StringName:
	if pool.is_empty():
		return &""
	return StringName(str(pool[rng.randi_range(0, pool.size() - 1)]))


func _get_die_entry(run_state: RunState, die_ref: Dictionary) -> Dictionary:
	if run_state == null:
		return {"valid": false, "error": "缺少本局状态"}
	run_state.ensure_starting_dice()
	var die_index := int(die_ref.get("die_index", -1))
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


func _get_face_entry(run_state: RunState, face_ref: Dictionary) -> Dictionary:
	var die_entry := _get_die_entry(run_state, face_ref)
	if not bool(die_entry.get("valid", false)):
		return die_entry
	var die: DieState = die_entry["die"]
	var face_index := int(face_ref.get("face_index", -1))
	if face_index < 0 or face_index >= die.faces.size():
		return {"valid": false, "error": "请选择目标骰面"}
	var face := die.faces[face_index]
	if face == null:
		return {"valid": false, "error": "目标骰面无效"}
	return {
		"valid": true,
		"die": die,
		"face": face,
		"die_index": int(die_entry.get("die_index", -1)),
		"face_index": face_index,
	}


func _face_entries_for_refs(run_state: RunState, face_refs: Array) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for face_ref in face_refs:
		if not (face_ref is Dictionary):
			continue
		var entry := _get_face_entry(run_state, face_ref)
		if bool(entry.get("valid", false)):
			entries.append(entry)
	return entries


func _all_face_entries(run_state: RunState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if run_state == null:
		return result
	run_state.ensure_starting_dice()
	for die_index in range(run_state.dice.size()):
		var die := run_state.dice[die_index]
		if die == null:
			continue
		for face_index in range(die.faces.size()):
			if die.faces[face_index] == null:
				continue
			result.append({
				"die": die,
				"face": die.faces[face_index],
				"die_index": die_index,
				"face_index": face_index,
			})
	return result


func _target_die_ref(args: Dictionary) -> Dictionary:
	if args.has("target_die") and args["target_die"] is Dictionary:
		return args["target_die"]
	return args


func _target_face_ref(args: Dictionary) -> Dictionary:
	if args.has("target_face") and args["target_face"] is Dictionary:
		return args["target_face"]
	if args.has("face") and args["face"] is Dictionary:
		return args["face"]
	return args


func _source_face_ref(args: Dictionary) -> Dictionary:
	if args.has("source_face") and args["source_face"] is Dictionary:
		return args["source_face"]
	return {}


func _target_faces(args: Dictionary) -> Array:
	if args.has("target_faces") and args["target_faces"] is Array:
		return args["target_faces"]
	if args.has("faces") and args["faces"] is Array:
		return args["faces"]
	return []


func _get_installed_tools(run_state: RunState) -> Array:
	if run_state == null:
		return []
	if run_state.dice_tools.is_empty() and not run_state.installed_tools.is_empty():
		run_state.dice_tools = run_state.installed_tools
	elif run_state.installed_tools.is_empty() and not run_state.dice_tools.is_empty():
		run_state.installed_tools = run_state.dice_tools
	return run_state.dice_tools


func _set_installed_tools(run_state: RunState, tools: Array) -> void:
	run_state.dice_tools.clear()
	for tool in tools:
		if tool is DiceToolState:
			run_state.dice_tools.append(tool)
	run_state.installed_tools = run_state.dice_tools


func _non_negative_tool_indexes(run_state: RunState) -> Array[int]:
	var result: Array[int] = []
	var tools := _get_installed_tools(run_state)
	for index in range(tools.size()):
		var tool: DiceToolState = tools[index]
		if tool != null and not tool.is_negative:
			result.append(index)
	return result


func _clone_tool_for_foundry(source: DiceToolState) -> DiceToolState:
	var clone: DiceToolState = DiceToolState.create(source.tool_id, source.display_name, source.sell_value, source.rarity)
	clone.permanent_flags = source.permanent_flags.duplicate(true)
	clone.metadata = source.metadata.duplicate(true)
	clone.is_negative = false
	clone.combat_counters.clear()
	return clone


func _intersect_ints(left: Array[int], right: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for value in left:
		if right.has(value) and not result.has(value):
			result.append(value)
	return result


func _has_duplicate_face_refs(entries: Array[Dictionary]) -> bool:
	var seen := {}
	for entry in entries:
		var key := _entry_key(entry)
		if seen.has(key):
			return true
		seen[key] = true
	return false


func _entry_key(entry: Dictionary) -> String:
	return "%d:%d" % [int(entry.get("die_index", -1)), int(entry.get("face_index", -1))]


func _add_changed_face(result: Dictionary, entry: Dictionary) -> void:
	result["changed_faces"].append({
		"die_index": int(entry.get("die_index", -1)),
		"face_index": int(entry.get("face_index", -1)),
	})


func _make_result(service_id: StringName) -> Dictionary:
	var def := FoundryServiceCatalog.get_def(service_id)
	return {
		"success": false,
		"service_id": service_id,
		"service_name": def.get_display_name() if def != null else str(service_id),
		"message": "",
		"events": [],
		"changed_faces": [],
		"generated_items": [],
		"destroyed_tools": [],
		"upgraded_combos": [],
		"coins_delta": 0,
	}


func _fail(result: Dictionary, message: String) -> Dictionary:
	result["success"] = false
	result["message"] = message
	_add_event(result, message)
	return result


func _record_log(run_state: RunState, result: Dictionary, message: String, details: Dictionary = {}) -> void:
	_add_event(result, message)
	if run_state == null:
		return
	if run_state.has_method("record_foundry_log"):
		run_state.record_foundry_log(
			StringName(str(result.get("service_id", &""))),
			str(result.get("service_name", "")),
			message,
			details
		)


func _add_event(result: Dictionary, message: String) -> void:
	if message == "":
		return
	result["events"].append(message)


func _die_label(entry: Dictionary) -> String:
	var die: DieState = entry.get("die", null)
	if die != null and die.id != &"":
		return str(die.id)
	return "D%d-%d" % [int(entry.get("die_index", -1)) + 1, int(entry.get("die_index", -1)) + 1]


func _tool_label(tool: DiceToolState) -> String:
	if tool == null:
		return "未知骰具"
	if tool.display_name != "":
		return tool.display_name
	return str(tool.tool_id)


func _is_none_id(value: StringName) -> bool:
	return value == &"" or value == &"none" or value == FaceState.ORN_NONE or value == FaceState.MARK_NONE
