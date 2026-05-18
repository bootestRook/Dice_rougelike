extends RefCounted
class_name BoosterPackService


const BoosterOfferDef = preload("res://scripts/data_defs/BoosterOfferDef.gd")
const BoosterPackDef = preload("res://scripts/data_defs/BoosterPackDef.gd")
const BoosterPackCatalog = preload("res://scripts/rules/shop/BoosterPackCatalog.gd")
const ComboLevelService = preload("res://scripts/rules/combo/ComboLevelService.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const DiceToolService = preload("res://scripts/rules/dice_tools/DiceToolService.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const FaceOffer = preload("res://scripts/data_defs/FaceOffer.gd")
const FaceOfferGenerator = preload("res://scripts/rules/shop/FaceOfferGenerator.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const ForgeItemService = preload("res://scripts/rules/forge/ForgeItemService.gd")
const FoundryService = preload("res://scripts/rules/forge/FoundryService.gd")
const FoundryServiceCatalog = preload("res://scripts/rules/forge/FoundryServiceCatalog.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")


const ALLOWED_COMBO_IDS := [
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
var combo_level_service := ComboLevelService.new()
var dice_tool_service := DiceToolService.new()
var face_offer_generator := FaceOfferGenerator.new()
var forge_item_service := ForgeItemService.new()
var foundry_service := FoundryService.new()


func _init() -> void:
	rng.randomize()


func open_pack(run_state, pack_id: StringName) -> Dictionary:
	var pack_def := BoosterPackCatalog.get_def(pack_id)
	if pack_def == null:
		return {"success": false, "message": "补充包不存在"}

	var candidates := generate_candidate_offers(run_state, pack_def)
	var candidate_data := _offers_to_data(candidates)
	var pending := {
		"pack_id": pack_def.pack_id,
		"pack_name": pack_def.display_name,
		"candidate_offers": candidate_data,
		"choose_count": pack_def.choose_count,
		"selected_offers": [],
		"selected_offer_indexes": [],
		"pending_target_selection": {},
		"completed": false,
	}
	if run_state != null:
		run_state.pending_booster_resolution = pending

	var message := "[补充包] 打开 %s。" % [pack_def.display_name]
	_record_log(run_state, message, {"kind": &"pack_open", "pack_id": pack_def.pack_id})
	for tool_log in dice_tool_service.on_booster_pack_opened(run_state, pack_def.pack_id):
		_record_log(run_state, tool_log, {"kind": &"dice_tool", "pack_id": pack_def.pack_id})

	return {
		"success": true,
		"message": message,
		"pack_def": pack_def,
		"candidate_offers": candidates,
		"choose_count": pack_def.choose_count,
		"pending_booster_resolution": pending.duplicate(true),
	}


func generate_candidate_offers(run_state, pack_def_or_id) -> Array[BoosterOfferDef]:
	var pack_def := _pack_def_from_any(pack_def_or_id)
	var result: Array[BoosterOfferDef] = []
	if pack_def == null:
		return result

	match pack_def.pack_kind:
		BoosterPackDef.KIND_FACE:
			face_offer_generator.rng.seed = rng.randi()
			return face_offer_generator.generate_face_offers(run_state, pack_def.candidate_count)
		BoosterPackDef.KIND_FORGE:
			return _generate_forge_offers(run_state, pack_def)
		BoosterPackDef.KIND_COMBO:
			return _generate_combo_offers(pack_def)
		BoosterPackDef.KIND_TOOL:
			return _generate_tool_offers(run_state, pack_def)
		BoosterPackDef.KIND_FOUNDRY:
			return _generate_foundry_offers(run_state, pack_def)
		_:
			return result


func get_combo_candidate_pool() -> Array[StringName]:
	var result: Array[StringName] = []
	for combo_id in ALLOWED_COMBO_IDS:
		result.append(combo_id)
	return result


func select_pending_offer(run_state, offer_index: int, args: Dictionary = {}) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var pending: Dictionary = run_state.pending_booster_resolution
	if pending.is_empty():
		return {"success": false, "message": "没有待处理的补充包"}

	var candidate_data: Array = pending.get("candidate_offers", [])
	if offer_index < 0 or offer_index >= candidate_data.size():
		return {"success": false, "message": "候选不存在"}
	var selected: Array = pending.get("selected_offers", [])
	var selected_indexes: Array = pending.get("selected_offer_indexes", [])
	var choose_count := int(pending.get("choose_count", 1))
	if selected.size() >= choose_count:
		return {"success": false, "message": "已达到选择数量"}
	if selected_indexes.has(offer_index):
		return {"success": false, "message": "该候选已选择"}

	var offer: BoosterOfferDef = BoosterOfferDef.from_dict(candidate_data[offer_index])
	if not offer.is_selectable:
		return {"success": false, "message": offer.disabled_reason}

	if _requires_target_selection(offer) and not _has_required_target(offer, args):
		pending["pending_target_selection"] = {
			"offer_index": offer_index,
			"offer": offer.to_dict(),
		}
		run_state.pending_booster_resolution = pending
		return {
			"success": true,
			"needs_target": true,
			"message": "请选择目标骰面",
			"offer": offer,
		}

	var result := apply_booster_offer(run_state, offer, args)
	if bool(result.get("success", false)):
		selected.append(offer.to_dict())
		selected_indexes.append(offer_index)
		pending["selected_offers"] = selected
		pending["selected_offer_indexes"] = selected_indexes
		pending["pending_target_selection"] = {}
		if selected.size() >= choose_count:
			pending["completed"] = true
		run_state.pending_booster_resolution = pending
	return result


func resolve_pending_target(run_state, args: Dictionary) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var pending: Dictionary = run_state.pending_booster_resolution
	var target_state: Dictionary = pending.get("pending_target_selection", {})
	if target_state.is_empty():
		return {"success": false, "message": "没有等待目标选择的候选"}
	var offer: BoosterOfferDef = BoosterOfferDef.from_dict(target_state.get("offer", {}))
	return select_pending_offer(run_state, int(target_state.get("offer_index", -1)), args)


func skip_pending_pack(run_state) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var pending: Dictionary = run_state.pending_booster_resolution
	if pending.is_empty():
		return {"success": false, "message": "没有待处理的补充包"}
	var pack_id := StringName(str(pending.get("pack_id", &"")))
	for tool_log in dice_tool_service.on_booster_pack_skipped(run_state, pack_id):
		_record_log(run_state, tool_log, {"kind": &"dice_tool", "pack_id": pack_id})
	run_state.pending_booster_resolution.clear()
	return {"success": true, "message": "[补充包] 已跳过。"}


func close_completed_pack(run_state) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var pending: Dictionary = run_state.pending_booster_resolution
	if pending.is_empty():
		return {"success": false, "message": "没有待处理的补充包"}
	if not bool(pending.get("completed", false)):
		return {"success": false, "message": "补充包尚未完成选择"}
	run_state.pending_booster_resolution.clear()
	return {"success": true, "message": "[补充包] 已完成。"}


func apply_booster_offer(run_state, offer_any, args: Dictionary = {}) -> Dictionary:
	var offer := _offer_from_any(offer_any)
	if offer == null:
		return {"success": false, "message": "候选无效"}
	if not offer.is_selectable:
		return {"success": false, "message": offer.disabled_reason}

	match offer.payload_kind:
		BoosterOfferDef.PAYLOAD_FACE_OFFER:
			var face_offer: FaceOffer = FaceOffer.from_dict(offer.payload_data)
			var target := _target_face_ref(args)
			return face_offer_generator.apply_to_target(
				run_state,
				face_offer,
				int(target.get("die_index", -1)),
				int(target.get("face_index", -1))
			)
		BoosterOfferDef.PAYLOAD_FORGE_ITEM:
			return _apply_forge_offer(run_state, offer, args)
		BoosterOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
			return _apply_combo_offer(run_state, offer)
		BoosterOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			return _apply_tool_offer(run_state, offer)
		BoosterOfferDef.PAYLOAD_FOUNDRY_SERVICE:
			return _apply_foundry_offer(run_state, offer, args)
		_:
			return {"success": false, "message": "候选类型无效"}


func can_apply_face_offer_to_target(run_state, face_offer: FaceOffer, die_index: int, face_index: int) -> Dictionary:
	return face_offer_generator.can_apply_to_target(run_state, face_offer, die_index, face_index)


func apply_face_offer_to_target(run_state, face_offer: FaceOffer, die_index: int, face_index: int) -> Dictionary:
	return face_offer_generator.apply_to_target(run_state, face_offer, die_index, face_index)


func _generate_forge_offers(run_state, pack_def: BoosterPackDef) -> Array[BoosterOfferDef]:
	var ids := _draw_unique_ids(ForgeItemCatalog.get_forge_item_pack_pool_ids(), pack_def.candidate_count)
	var result: Array[BoosterOfferDef] = []
	for index in range(ids.size()):
		var id := ids[index]
		var def := ForgeItemCatalog.get_def(id)
		var name := def.get_display_name() if def != null else str(id)
		var offer: BoosterOfferDef = BoosterOfferDef.create(
			StringName("%s_forge_%d" % [str(pack_def.pack_id), index]),
			name,
			pack_def.pack_kind,
			BoosterOfferDef.PAYLOAD_FORGE_ITEM,
			id
		)
		if def != null and def.requires_item_slot and _free_item_slots(run_state) <= 0:
			offer.mark_disabled("道具槽位不足")
		result.append(offer)
	return result


func _generate_combo_offers(pack_def: BoosterPackDef) -> Array[BoosterOfferDef]:
	var ids := _draw_unique_ids(get_combo_candidate_pool(), pack_def.candidate_count)
	var result: Array[BoosterOfferDef] = []
	for index in range(ids.size()):
		var combo_id := ids[index]
		var def := ComboUpgradeCatalog.get_def(combo_id)
		var combo_name := def.display_name if def != null else DisplayNames.combo_name(combo_id)
		result.append(BoosterOfferDef.create(
			StringName("%s_combo_%d" % [str(pack_def.pack_id), index]),
			"主骰型升级：%s" % [combo_name],
			pack_def.pack_kind,
			BoosterOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM,
			combo_id
		))
	return result


func _generate_tool_offers(run_state, pack_def: BoosterPackDef) -> Array[BoosterOfferDef]:
	var items := _draw_unique_tool_items(DiceToolCatalog.get_item_pool_for_rarity(), pack_def.candidate_count)
	var result: Array[BoosterOfferDef] = []
	for index in range(items.size()):
		var data: Dictionary = items[index]
		var id := StringName(str(data.get("id", &"")))
		var offer: BoosterOfferDef = BoosterOfferDef.create(
			StringName("%s_tool_%d" % [str(pack_def.pack_id), index]),
			str(data.get("name", id)),
			pack_def.pack_kind,
			BoosterOfferDef.PAYLOAD_DICE_TOOL_ITEM,
			id,
			{
				"rarity": StringName(str(data.get("rarity", &"common"))),
				"sell_value": int(data.get("sell_value", 0)),
			}
		)
		if _free_item_slots(run_state) <= 0:
			offer.mark_disabled("道具槽位不足")
		result.append(offer)
	return result


func _generate_foundry_offers(run_state, pack_def: BoosterPackDef) -> Array[BoosterOfferDef]:
	var ids := _draw_unique_ids(FoundryServiceCatalog.get_all_ids(), pack_def.candidate_count)
	var result: Array[BoosterOfferDef] = []
	for index in range(ids.size()):
		var id := ids[index]
		var def := FoundryServiceCatalog.get_def(id)
		var name := def.get_display_name() if def != null else str(id)
		var offer: BoosterOfferDef = BoosterOfferDef.create(
			StringName("%s_foundry_%d" % [str(pack_def.pack_id), index]),
			name,
			pack_def.pack_kind,
			BoosterOfferDef.PAYLOAD_FOUNDRY_SERVICE,
			id
		)
		if def != null and def.requires_item_slot and _free_item_slots(run_state) <= 0:
			offer.mark_disabled("道具槽位不足")
		result.append(offer)
	return result


func _apply_forge_offer(run_state, offer: BoosterOfferDef, args: Dictionary) -> Dictionary:
	var result := forge_item_service.use_from_pack(
		run_state,
		offer.payload_id,
		_target_faces(args),
		_source_face_ref(args)
	)
	if bool(result.get("success", false)):
		var message := "[补充包] 选择 铸骰件：%s，立即处理。" % [offer.display_name]
		_record_log(run_state, message, {"kind": &"forge_item", "item_id": offer.payload_id})
		result["message"] = message
	return result


func _apply_combo_offer(run_state, offer: BoosterOfferDef) -> Dictionary:
	var result := combo_level_service.use_from_pack(run_state, offer.payload_id)
	if bool(result.get("success", false)):
		for tool_log in dice_tool_service.on_combo_upgrade_item_used(run_state, StringName(str(result.get("combo_id", &"")))):
			_record_log(run_state, tool_log, {"kind": &"dice_tool", "combo_id": result.get("combo_id", &"")})
	return result


func _apply_tool_offer(run_state, offer: BoosterOfferDef) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	if run_state.get_free_item_slot_count() <= 0:
		return {"success": false, "message": "道具槽位不足"}
	var item: ItemInstance = ItemInstance.create_dice_tool(
		offer.payload_id,
		offer.display_name,
		int(offer.payload_data.get("sell_value", 0))
	)
	item.metadata["rarity"] = StringName(str(offer.payload_data.get("rarity", &"common")))
	if not run_state.add_item_instance_to_slots(item):
		return {"success": false, "message": "道具槽位不足"}
	var message := "[补充包] 选择 骰具：%s，生成骰具道具进入道具槽位。" % [offer.display_name]
	_record_log(run_state, message, {"kind": &"dice_tool_item", "tool_id": offer.payload_id})
	return {
		"success": true,
		"message": message,
		"generated_items": [offer.payload_id],
	}


func _apply_foundry_offer(run_state, offer: BoosterOfferDef, args: Dictionary) -> Dictionary:
	var result := foundry_service.apply_service(run_state, offer.payload_id, args)
	if bool(result.get("success", false)):
		var message := "[补充包] 选择 工坊服务：%s，立即处理。" % [offer.display_name]
		_record_log(run_state, message, {"kind": &"foundry_service", "service_id": offer.payload_id})
		result["message"] = message
	return result


func _pack_def_from_any(value) -> BoosterPackDef:
	if value is BoosterPackDef:
		return (value as BoosterPackDef).clone()
	return BoosterPackCatalog.get_def(StringName(str(value)))


func _offer_from_any(value) -> BoosterOfferDef:
	if value is BoosterOfferDef:
		return (value as BoosterOfferDef).clone()
	if value is Dictionary:
		return BoosterOfferDef.from_dict(value)
	return null


func _offers_to_data(offers: Array[BoosterOfferDef]) -> Array:
	var result: Array = []
	for offer in offers:
		if offer != null:
			result.append(offer.to_dict())
	return result


func _draw_unique_ids(source: Array, count: int) -> Array[StringName]:
	var pool: Array[StringName] = []
	for item in source:
		pool.append(StringName(str(item)))
	var result: Array[StringName] = []
	while result.size() < count and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result


func _draw_unique_tool_items(source: Array, count: int) -> Array:
	var pool := source.duplicate(true)
	var result: Array = []
	while result.size() < count and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		result.append(Dictionary(pool[index]).duplicate(true))
		pool.remove_at(index)
	return result


func _free_item_slots(run_state) -> int:
	if run_state == null:
		return 0
	return run_state.get_free_item_slot_count()


func _target_face_ref(args: Dictionary) -> Dictionary:
	if args.has("target_face") and args["target_face"] is Dictionary:
		return args["target_face"]
	if args.has("face") and args["face"] is Dictionary:
		return args["face"]
	return args


func _has_target_face(args: Dictionary) -> bool:
	var target := _target_face_ref(args)
	return target.has("die_index") and target.has("face_index")


func _target_faces(args: Dictionary) -> Array:
	if args.has("target_faces") and args["target_faces"] is Array:
		return args["target_faces"]
	if args.has("faces") and args["faces"] is Array:
		return args["faces"]
	if _has_target_face(args):
		return [_target_face_ref(args)]
	return []


func _source_face_ref(args: Dictionary) -> Dictionary:
	if args.has("source_face") and args["source_face"] is Dictionary:
		return args["source_face"]
	return {}


func _requires_target_selection(offer: BoosterOfferDef) -> bool:
	if offer == null:
		return false
	match offer.payload_kind:
		BoosterOfferDef.PAYLOAD_FACE_OFFER:
			return true
		BoosterOfferDef.PAYLOAD_FORGE_ITEM:
			var forge_def := ForgeItemCatalog.get_def(offer.payload_id)
			return forge_def != null and forge_def.target_type != ForgeItemCatalog.TARGET_NONE
		BoosterOfferDef.PAYLOAD_FOUNDRY_SERVICE:
			var foundry_def := FoundryServiceCatalog.get_def(offer.payload_id)
			return foundry_def != null and foundry_def.target_rule != FoundryServiceCatalog.TARGET_NONE
		_:
			return false


func _has_required_target(offer: BoosterOfferDef, args: Dictionary) -> bool:
	if offer == null:
		return false
	match offer.payload_kind:
		BoosterOfferDef.PAYLOAD_FACE_OFFER:
			return _has_target_face(args)
		BoosterOfferDef.PAYLOAD_FORGE_ITEM:
			var forge_def := ForgeItemCatalog.get_def(offer.payload_id)
			if forge_def == null:
				return false
			match forge_def.target_type:
				ForgeItemCatalog.TARGET_NONE:
					return true
				ForgeItemCatalog.TARGET_FACES:
					return not _target_faces(args).is_empty()
				ForgeItemCatalog.TARGET_FACE_PAIR:
					return _target_faces(args).size() >= 1 and not _source_face_ref(args).is_empty()
				_:
					return false
		BoosterOfferDef.PAYLOAD_FOUNDRY_SERVICE:
			var foundry_def := FoundryServiceCatalog.get_def(offer.payload_id)
			if foundry_def == null:
				return false
			match foundry_def.target_rule:
				FoundryServiceCatalog.TARGET_NONE:
					return true
				FoundryServiceCatalog.TARGET_DIE:
					return args.has("die_index") or (args.has("target_die") and args["target_die"] is Dictionary)
				FoundryServiceCatalog.TARGET_FACE:
					return _has_target_face(args)
				FoundryServiceCatalog.TARGET_MULTI_FACES:
					return _target_faces(args).size() >= 2
				FoundryServiceCatalog.TARGET_FACE_DOUBLE_COPY:
					return not _source_face_ref(args).is_empty() and _target_faces(args).size() == 2
				_:
					return false
		_:
			return true


func _record_log(run_state, message: String, details: Dictionary = {}) -> void:
	if message == "":
		return
	if run_state != null and run_state.has_method("record_shop_log"):
		run_state.record_shop_log(message, details)
