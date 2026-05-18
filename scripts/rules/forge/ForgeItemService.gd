extends RefCounted
class_name ForgeItemService


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ComboUpgradeItem = preload("res://scripts/rules/combo/ComboUpgradeItem.gd")
const DiceToolService = preload("res://scripts/rules/dice_tools/DiceToolService.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const ForgeItemDef = preload("res://scripts/data_defs/ForgeItemDef.gd")


var rng := RandomNumberGenerator.new()
var dice_tool_service := DiceToolService.new()


func _init() -> void:
	rng.randomize()


static func legal_pips(face_count: int) -> Array[int]:
	var result: Array[int] = []
	match face_count:
		4:
			result.append_array([1, 2, 3, 4])
		6:
			result.append_array([1, 2, 3, 4, 5, 6])
		8:
			result.append_array([1, 2, 3, 4, 5, 6, 7, 8])
		_:
			push_error("Unsupported face_count")
	return result


static func legal_even_pips(face_count: int) -> Array[int]:
	var result: Array[int] = []
	for pip in legal_pips(face_count):
		if pip % 2 == 0:
			result.append(pip)
	return result


static func legal_odd_pips(face_count: int) -> Array[int]:
	var result: Array[int] = []
	for pip in legal_pips(face_count):
		if pip % 2 == 1:
			result.append(pip)
	return result


static func legal_low_pips(face_count: int) -> Array[int]:
	var result: Array[int] = []
	for pip in legal_pips(face_count):
		if pip >= 1 and pip <= 4:
			result.append(pip)
	return result


static func legal_high_pips(face_count: int) -> Array[int]:
	var result: Array[int] = []
	for pip in legal_pips(face_count):
		if pip >= 5 and pip <= 8:
			result.append(pip)
	return result


func can_use_forge_item(
	run_state: RunState,
	forge_item_id: StringName,
	target_faces: Array = [],
	source_face_ref: Dictionary = {},
	consume_slot_index: int = -1
) -> bool:
	return _validate_use(run_state, ForgeItemCatalog.get_def(forge_item_id), target_faces, source_face_ref, consume_slot_index) == ""


func use_forge_item_from_slot(
	run_state: RunState,
	slot_index: int,
	target_faces: Array = [],
	source_face_ref: Dictionary = {}
) -> Dictionary:
	var result := _make_result(null)
	if run_state == null:
		return _fail(result, str(TranslationServer.translate(&"AUTO.TEXT.35B3CF548106")))
	run_state.ensure_item_slots_from_legacy()
	if slot_index < 0 or slot_index >= run_state.item_slots.size():
		return _fail(result, str(TranslationServer.translate(&"AUTO.TEXT.2E7CDAF52B60")))

	var item := run_state.item_slots[slot_index]
	if item == null:
		return _fail(result, str(TranslationServer.translate(&"AUTO.TEXT.FEC9D42BBA9A")))
	if item.item_type != ItemInstance.TYPE_FORGE_ITEM and not ForgeItemCatalog.has_forge_item(item.item_id):
		return _fail(result, str(TranslationServer.translate(&"AUTO.TEXT.81B67C366AA7")))

	return apply_forge_item(run_state, item.item_id, target_faces, source_face_ref, slot_index)


func apply_forge_item(
	run_state: RunState,
	forge_item_id: StringName,
	target_faces: Array = [],
	source_face_ref: Dictionary = {},
	consume_slot_index: int = -1
) -> Dictionary:
	var def := ForgeItemCatalog.get_def(forge_item_id)
	var result := _make_result(def)
	var validation_error := _validate_use(run_state, def, target_faces, source_face_ref, consume_slot_index)
	if validation_error != "":
		return _fail(result, validation_error)

	if consume_slot_index >= 0:
		var consumed := run_state.consume_item_slot(consume_slot_index)
		if consumed != null:
			result["consumed_item_id"] = consumed.item_id

	match def.effect_type:
		ForgeItemCatalog.EFFECT_ECHO_COPY:
			_apply_echo_copy(run_state, result)
		ForgeItemCatalog.EFFECT_SET_ORNAMENT:
			_apply_set_ornament(run_state, def, target_faces, result)
		ForgeItemCatalog.EFFECT_COMBO_UPGRADE_PACK:
			_generate_combo_upgrade_pack(run_state, def.generated_count, result)
		ForgeItemCatalog.EFFECT_FORGE_ITEM_PACK:
			_generate_forge_item_pack(run_state, def.generated_count, result)
		ForgeItemCatalog.EFFECT_COIN_DOUBLER:
			_apply_coin_doubler(run_state, result)
		ForgeItemCatalog.EFFECT_RARE_ORNAMENT_ROLL:
			_apply_rare_ornament_roll(run_state, target_faces, result)
		ForgeItemCatalog.EFFECT_PIP_UP:
			_apply_pip_up(run_state, target_faces, result)
		ForgeItemCatalog.EFFECT_FACE_COPY:
			_apply_face_copy(run_state, target_faces, source_face_ref, result)
		ForgeItemCatalog.EFFECT_TOOL_VALUE_CASH:
			_apply_tool_value_cash(run_state, result)
		ForgeItemCatalog.EFFECT_PIP_REROLL:
			_apply_pip_reroll(run_state, def, target_faces, result)
		ForgeItemCatalog.EFFECT_DICE_TOOL_PACK:
			_generate_dice_tool_pack(run_state, result)
		_:
			return _fail(result, str(TranslationServer.translate(&"AUTO.TEXT.6FF4419F3811")))

	result["success"] = true
	dice_tool_service.on_forge_item_used(run_state, def.id)
	if def.effect_type == ForgeItemCatalog.EFFECT_FACE_COPY:
		var target_ref := target_faces[0] if not target_faces.is_empty() and target_faces[0] is Dictionary else {}
		var source_ref := source_face_ref
		if source_ref.is_empty() and target_faces.size() >= 2 and target_faces[1] is Dictionary:
			source_ref = target_faces[1]
		dice_tool_service.on_face_copied(run_state, source_ref, target_ref)
	if def.id != ForgeItemCatalog.FORGE_ECHO_COPY:
		run_state.record_copyable_used_item_id(def.id)
	return result


func install_pending_rare_ornament(run_state: RunState, ornament_id: StringName, target_face_ref: Dictionary) -> Dictionary:
	var result := _make_result(null)
	if not ForgeItemCatalog.RARE_ORNAMENT_IDS.has(ornament_id):
		return _fail(result, str(TranslationServer.translate(&"AUTO.TEXT.F1063CABA3B2")))
	var entry := _get_face_entry(run_state, target_face_ref)
	if not bool(entry.get("valid", false)):
		return _fail(result, str(entry.get("error", str(TranslationServer.translate(&"AUTO.TEXT.E62E8CF325CA")))))
	var face: FaceState = entry["face"]
	face.ornament_id = ornament_id
	face.material_id = &"none"
	_add_changed_face(result, entry)
	result["success"] = true
	result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.83FF300A53CA"))
	return result


func _validate_use(
	run_state: RunState,
	def: ForgeItemDef,
	target_faces: Array,
	source_face_ref: Dictionary,
	consume_slot_index: int
) -> String:
	if run_state == null:
		return str(TranslationServer.translate(&"AUTO.TEXT.35B3CF548106"))
	if def == null:
		return str(TranslationServer.translate(&"AUTO.TEXT.CE1DC71354AE"))

	if consume_slot_index >= 0:
		run_state.ensure_item_slots_from_legacy()
		if consume_slot_index >= run_state.item_slots.size():
			return str(TranslationServer.translate(&"AUTO.TEXT.2E7CDAF52B60"))
		var item := run_state.item_slots[consume_slot_index]
		if item == null or item.item_id != def.id:
			return str(TranslationServer.translate(&"AUTO.TEXT.F613362A4600"))

	if def.effect_type == ForgeItemCatalog.EFFECT_ECHO_COPY:
		if run_state.last_copyable_used_item_id == &"":
			return str(TranslationServer.translate(&"AUTO.TEXT.9F80FDEBB97D"))
		if not _is_copyable_item_id(run_state.last_copyable_used_item_id):
			return str(TranslationServer.translate(&"AUTO.TEXT.9F80FDEBB97D"))

	if def.target_type == ForgeItemCatalog.TARGET_FACES:
		var target_count := target_faces.size()
		if def.effect_type == ForgeItemCatalog.EFFECT_RARE_ORNAMENT_ROLL:
			if target_count > 1:
				return str(TranslationServer.translate(&"AUTO.TEXT.307E616BDC9B"))
		elif target_count <= 0:
			return str(TranslationServer.translate(&"AUTO.TEXT.AF48D0AA5B9B"))
		if def.max_targets > 0 and target_count > def.max_targets:
			return str(TranslationServer.translate(&"AUTO.TEXT.15D753221CB6"))

		for target_ref in target_faces:
			if not (target_ref is Dictionary):
				return str(TranslationServer.translate(&"AUTO.TEXT.E62E8CF325CA"))
			var entry := _get_face_entry(run_state, target_ref)
			if not bool(entry.get("valid", false)):
				return str(entry.get("error", str(TranslationServer.translate(&"AUTO.TEXT.E62E8CF325CA"))))
			if def.effect_type == ForgeItemCatalog.EFFECT_PIP_REROLL:
				var die: DieState = entry["die"]
				var pool := _pip_pool_for_type(StringName(str(def.payload.get("pip_pool_type", &""))), die.face_count)
				if pool.is_empty():
					return str(TranslationServer.translate(&"AUTO.TEXT.E69B498FE866"))

	if def.target_type == ForgeItemCatalog.TARGET_FACE_PAIR:
		if target_faces.is_empty():
			return str(TranslationServer.translate(&"AUTO.TEXT.171261F90755"))
		var target_entry := _get_face_entry(run_state, target_faces[0])
		if not bool(target_entry.get("valid", false)):
			return str(target_entry.get("error", str(TranslationServer.translate(&"AUTO.TEXT.E62E8CF325CA"))))
		var source_ref := source_face_ref
		if source_ref.is_empty() and target_faces.size() >= 2 and target_faces[1] is Dictionary:
			source_ref = target_faces[1]
		var source_entry := _get_face_entry(run_state, source_ref)
		if not bool(source_entry.get("valid", false)):
			return str(source_entry.get("error", str(TranslationServer.translate(&"AUTO.TEXT.E3CFB63E196B"))))

	return ""


func _apply_echo_copy(run_state: RunState, result: Dictionary) -> void:
	var copied_id := run_state.last_copyable_used_item_id
	var item := _make_item_instance_for_id(copied_id)
	if item == null:
		_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.9F80FDEBB97D")))
		result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.9F80FDEBB97D"))
		return
	_add_generated_item_instances(run_state, [item], result)
	if str(result.get("message", "")) == "":
		result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.3BD484CFE7C3")) % [item.display_name]


func _apply_set_ornament(run_state: RunState, def: ForgeItemDef, target_faces: Array, result: Dictionary) -> void:
	var ornament_id := FaceState.normalize_ornament_id(StringName(str(def.payload.get("ornament_id", &""))))
	for target_ref in target_faces:
		var entry := _get_face_entry(run_state, target_ref)
		var face: FaceState = entry["face"]
		face.ornament_id = ornament_id
		face.material_id = &"none"
		_add_changed_face(result, entry)
	_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.CBEC11FC8C00")) % [def.display_name])


func _generate_combo_upgrade_pack(run_state: RunState, count: int, result: Dictionary) -> void:
	var ids := _draw_unique_ids(ForgeItemCatalog.get_combo_upgrade_pool_ids(), count)
	var items: Array[ItemInstance] = []
	for id in ids:
		items.append(ItemInstance.create_combo_upgrade(id))
	_add_generated_item_instances(run_state, items, result)


func _generate_forge_item_pack(run_state: RunState, count: int, result: Dictionary) -> void:
	var ids := _draw_unique_ids(ForgeItemCatalog.get_forge_item_pack_pool_ids(), count)
	var items: Array[ItemInstance] = []
	for id in ids:
		var def := ForgeItemCatalog.get_def(id)
		items.append(ItemInstance.create_forge_item(id, def.get_display_name() if def != null else str(id)))
	_add_generated_item_instances(run_state, items, result)


func _apply_coin_doubler(run_state: RunState, result: Dictionary) -> void:
	var gain: int = min(run_state.coins, 20)
	run_state.add_coins(gain, ForgeItemCatalog.FORGE_COIN_DOUBLER)
	result["coins_delta"] = gain
	result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.5C86EE80873C")) % [gain]
	_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.CB8B35CDF2B4")) % [gain])


func _apply_rare_ornament_roll(run_state: RunState, target_faces: Array, result: Dictionary) -> void:
	if rng.randf() >= 0.25:
		result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.ABACD40075E4"))
		_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.01758EA52EE6")))
		return

	var ornament_id: StringName = ForgeItemCatalog.RARE_ORNAMENT_IDS[rng.randi_range(0, ForgeItemCatalog.RARE_ORNAMENT_IDS.size() - 1)]
	result["pending_ornament_id"] = ornament_id
	if target_faces.is_empty():
		result["needs_target"] = true
		result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.92F40F9E756F"))
		_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.7DA5E56079A8")))
		return

	var entry := _get_face_entry(run_state, target_faces[0])
	var face: FaceState = entry["face"]
	face.ornament_id = ornament_id
	face.material_id = &"none"
	_add_changed_face(result, entry)
	result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.7DA5E56079A8"))
	_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.7DA5E56079A8")))


func _apply_pip_up(run_state: RunState, target_faces: Array, result: Dictionary) -> void:
	for target_ref in target_faces:
		var entry := _get_face_entry(run_state, target_ref)
		var die: DieState = entry["die"]
		var face: FaceState = entry["face"]
		var current_pip: int = clampi(face.pip, 1, die.face_count)
		face.pip = 1 if current_pip >= die.face_count else current_pip + 1
		_add_changed_face(result, entry)
	_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.B4946317A55E")))


func _apply_face_copy(run_state: RunState, target_faces: Array, source_face_ref: Dictionary, result: Dictionary) -> void:
	var target_entry := _get_face_entry(run_state, target_faces[0])
	var source_ref := source_face_ref
	if source_ref.is_empty() and target_faces.size() >= 2 and target_faces[1] is Dictionary:
		source_ref = target_faces[1]
	var source_entry := _get_face_entry(run_state, source_ref)
	var target_face: FaceState = target_entry["face"]
	var source_face: FaceState = source_entry["face"]
	target_face.pip = source_face.pip
	target_face.ornament_id = source_face.ornament_id
	target_face.mark_id = source_face.mark_id
	target_face.material_id = &"none"
	_add_changed_face(result, target_entry)
	_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.37850C43AF0C")))


func _apply_tool_value_cash(run_state: RunState, result: Dictionary) -> void:
	var total_value := 0
	for tool in run_state.dice_tools:
		if tool != null:
			total_value += max(0, tool.sell_value)
	var gain: int = min(total_value, 50)
	run_state.add_coins(gain, ForgeItemCatalog.FORGE_TOOL_VALUE_CASH)
	result["coins_delta"] = gain
	result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.5C86EE80873C")) % [gain]
	_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.7861067B035F")) % [gain])


func _apply_pip_reroll(run_state: RunState, def: ForgeItemDef, target_faces: Array, result: Dictionary) -> void:
	var pool_type := StringName(str(def.payload.get("pip_pool_type", &"")))
	for target_ref in target_faces:
		var entry := _get_face_entry(run_state, target_ref)
		var die: DieState = entry["die"]
		var face: FaceState = entry["face"]
		var pool := _pip_pool_for_type(pool_type, die.face_count)
		face.pip = pool[rng.randi_range(0, pool.size() - 1)]
		_add_changed_face(result, entry)
	_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.8D2CEEC7C5CF")))


func _generate_dice_tool_pack(run_state: RunState, result: Dictionary) -> void:
	var pool := ForgeItemCatalog.get_dice_tool_item_pool()
	if pool.is_empty():
		result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.F2B83B1B98D0"))
		return
	var tool_data: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var item = ItemInstance.create_dice_tool(
		StringName(str(tool_data.get("id", &""))),
		str(tool_data.get("name", "")),
		int(tool_data.get("sell_value", 0))
	)
	item.metadata["rarity"] = StringName(str(tool_data.get("rarity", &"common")))
	_add_generated_item_instances(run_state, [item], result)


func _add_generated_item_instances(run_state: RunState, items: Array, result: Dictionary) -> void:
	var free_slots := run_state.get_free_item_slot_count()
	if free_slots <= 0:
		result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.E2E7B1D1350D"))
		_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.E2E7B1D1350D")))
		return

	var generated_count: int = min(items.size(), free_slots)
	for index in range(generated_count):
		var item := items[index] as ItemInstance
		if item == null:
			continue
		if run_state.add_item_instance_to_slots(item):
			result["generated_items"].append(item.item_id)
			_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.BDFC04DADDCB")) % [item.display_name])

	if generated_count < items.size():
		result["message"] = str(TranslationServer.translate(&"AUTO.TEXT.F073F3814359")) % [generated_count]
		_add_event(result, str(TranslationServer.translate(&"AUTO.TEXT.E2E7B1D1350D")))


func _draw_unique_ids(pool: Array, count: int) -> Array[StringName]:
	var source: Array[StringName] = []
	for id in pool:
		source.append(StringName(str(id)))
	var result: Array[StringName] = []
	while result.size() < count and not source.is_empty():
		var index := rng.randi_range(0, source.size() - 1)
		result.append(source[index])
		source.remove_at(index)
	return result


func _make_item_instance_for_id(item_id: StringName) -> ItemInstance:
	var combo_item := ComboUpgradeItem.from_item_id(item_id)
	if combo_item != null:
		return ItemInstance.create_combo_upgrade(item_id)
	var forge_def := ForgeItemCatalog.get_def(item_id)
	if forge_def != null:
		return ItemInstance.create_forge_item(item_id, forge_def.get_display_name())
	for tool_data in ForgeItemCatalog.get_dice_tool_item_pool():
		if StringName(str(tool_data.get("id", &""))) == item_id:
			var item := ItemInstance.create_dice_tool(
				item_id,
				str(tool_data.get("name", item_id)),
				int(tool_data.get("sell_value", 0))
			)
			item.metadata["rarity"] = StringName(str(tool_data.get("rarity", &"common")))
			return item
	return null


func _get_face_entry(run_state: RunState, face_ref: Dictionary) -> Dictionary:
	if run_state == null:
		return {"valid": false, "error": str(TranslationServer.translate(&"AUTO.TEXT.35B3CF548106"))}
	run_state.ensure_starting_dice()
	if face_ref.is_empty():
		return {"valid": false, "error": str(TranslationServer.translate(&"AUTO.TEXT.C62DCC78F2C8"))}
	var die_index := int(face_ref.get("die_index", -1))
	var face_index := int(face_ref.get("face_index", -1))
	if die_index < 0 or die_index >= run_state.dice.size():
		return {"valid": false, "error": str(TranslationServer.translate(&"AUTO.TEXT.7045BFF36A73"))}
	var die := run_state.dice[die_index]
	if die == null or face_index < 0 or face_index >= die.faces.size():
		return {"valid": false, "error": str(TranslationServer.translate(&"AUTO.TEXT.6097C95B410C"))}
	var face := die.faces[face_index]
	if face == null:
		return {"valid": false, "error": str(TranslationServer.translate(&"AUTO.TEXT.FCF3607DB577"))}
	return {
		"valid": true,
		"die": die,
		"face": face,
		"die_index": die_index,
		"face_index": face_index,
	}


func _pip_pool_for_type(pool_type: StringName, face_count: int) -> Array[int]:
	match pool_type:
		&"even":
			return legal_even_pips(face_count)
		&"odd":
			return legal_odd_pips(face_count)
		&"low":
			return legal_low_pips(face_count)
		&"high":
			return legal_high_pips(face_count)
		_:
			return []


func _add_changed_face(result: Dictionary, entry: Dictionary) -> void:
	result["changed_faces"].append({
		"die_index": int(entry.get("die_index", -1)),
		"face_index": int(entry.get("face_index", -1)),
	})


func _make_result(def: ForgeItemDef) -> Dictionary:
	return {
		"success": false,
		"forge_item_id": def.id if def != null else &"",
		"message": "",
		"events": [],
		"generated_items": [],
		"changed_faces": [],
		"coins_delta": 0,
		"consumed_item_id": &"",
		"needs_target": false,
		"pending_ornament_id": &"",
	}


func _fail(result: Dictionary, message: String) -> Dictionary:
	result["success"] = false
	result["message"] = message
	_add_event(result, message)
	return result


func _add_event(result: Dictionary, message: String) -> void:
	if message == "":
		return
	result["events"].append(message)


func _is_copyable_item_id(item_id: StringName) -> bool:
	if item_id == &"" or item_id == ForgeItemCatalog.FORGE_ECHO_COPY:
		return false
	if ComboUpgradeItem.from_item_id(item_id) != null:
		return true
	return ForgeItemCatalog.has_forge_item(item_id)
