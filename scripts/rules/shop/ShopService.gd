extends RefCounted
class_name ShopService


const BoosterPackCatalog = preload("res://scripts/rules/shop/BoosterPackCatalog.gd")
const BoosterPackDef = preload("res://scripts/data_defs/BoosterPackDef.gd")
const BoosterPackService = preload("res://scripts/rules/shop/BoosterPackService.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const DiceToolService = preload("res://scripts/rules/dice_tools/DiceToolService.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const LongTermUnlockService = preload("res://scripts/rules/long_term/LongTermUnlockService.gd")
const ShopCatalog = preload("res://scripts/rules/shop/ShopCatalog.gd")
const ShopOfferDef = preload("res://scripts/data_defs/ShopOfferDef.gd")


var rng := RandomNumberGenerator.new()
var booster_pack_service := BoosterPackService.new()
var dice_tool_service := DiceToolService.new()
var long_term_unlock_service := LongTermUnlockService.new()
var offer_serial: int = 0


func _init() -> void:
	rng.randomize()


func generate_shop(run_state) -> Dictionary:
	if run_state == null:
		return {}
	run_state.shop_reroll_count_this_shop = 0
	var random_item_slot_count := _random_item_slot_count(run_state)
	var booster_slot_count := _booster_slot_count(run_state)
	var state := {
		"random_item_slots": generate_random_item_offers(random_item_slot_count),
		"booster_slots": generate_booster_pack_offers(booster_slot_count),
		"long_term_unlock_slot": generate_long_term_unlock_offer(run_state),
		"free_rerolls": 0,
		"reroll_cost": run_state.get_shop_reroll_cost(),
	}
	dice_tool_service.apply_shop_open_effects(run_state, state)
	_update_reroll_cost(state, run_state)
	run_state.current_shop_state = state
	return state


func generate_random_item_offers(count: int) -> Array[ShopOfferDef]:
	var result: Array[ShopOfferDef] = []
	for _index in range(max(0, count)):
		var payload_kind := _draw_random_item_payload_kind()
		var payload_id := _draw_payload_id(payload_kind)
		if payload_id == &"":
			continue
		var display_name := ShopCatalog.display_name_for_payload(payload_kind, payload_id)
		var offer := ShopCatalog.make_random_item_offer(
			_next_offer_id(&"shop_random_item"),
			payload_kind,
			payload_id,
			display_name,
			ShopCatalog.base_price_for_payload(payload_kind, payload_id),
			"随机商品槽"
		)
		result.append(offer)
	return result


func generate_booster_pack_offers(count: int) -> Array[ShopOfferDef]:
	var ids := BoosterPackCatalog.get_pack_ids_for_shop()
	var result: Array[ShopOfferDef] = []
	while result.size() < count and not ids.is_empty():
		var index := rng.randi_range(0, ids.size() - 1)
		var pack_id := StringName(str(ids[index]))
		ids.remove_at(index)
		result.append(ShopCatalog.make_booster_offer(_next_offer_id(&"shop_booster"), pack_id))
	return result


func generate_long_term_unlock_offer(run_state = null) -> ShopOfferDef:
	var unlock_id := LongTermUnlockService.draw_shop_unlock_id(run_state, rng)
	return ShopCatalog.make_long_term_unlock_offer(_next_offer_id(&"shop_unlock"), unlock_id)


func reroll_random_shop_items(run_state) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	if run_state.current_shop_state.is_empty():
		generate_shop(run_state)

	var state: Dictionary = run_state.current_shop_state
	var cost := _reroll_cost_for_state(run_state, state)
	if run_state.coins < cost:
		return {"success": false, "message": "金币不足"}

	if int(state.get("free_rerolls", 0)) > 0:
		state["free_rerolls"] = int(state.get("free_rerolls", 0)) - 1
	else:
		run_state.coins -= cost

	run_state.shop_reroll_count_this_shop += 1
	state["random_item_slots"] = generate_random_item_offers(_random_item_slot_count(run_state))
	_update_reroll_cost(state, run_state)
	run_state.current_shop_state = state

	var message := "[商店] 刷新随机商品槽，花费 %d 金币。" % [cost]
	_record_log(run_state, message, {"kind": &"shop_reroll", "cost": cost})
	for tool_log in dice_tool_service.on_shop_rerolled(run_state):
		_record_log(run_state, tool_log, {"kind": &"dice_tool", "source": &"shop_reroll"})

	return {
		"success": true,
		"message": message,
		"cost": cost,
		"shop_state": state,
	}


func purchase_offer(run_state, offer_any) -> Dictionary:
	var offer := _offer_from_any(offer_any)
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	if offer == null:
		return {"success": false, "message": "商品无效"}

	var unavailable_reason := get_offer_unavailable_reason(run_state, offer)
	if unavailable_reason != "":
		return {"success": false, "message": unavailable_reason}

	var price := _current_price_for_offer(run_state, offer)
	run_state.coins -= price

	match offer.offer_kind:
		ShopOfferDef.KIND_RANDOM_ITEM:
			return _purchase_random_item(run_state, offer, price)
		ShopOfferDef.KIND_BOOSTER_PACK:
			return _purchase_booster_pack(run_state, offer, price)
		ShopOfferDef.KIND_LONG_TERM_UNLOCK:
			return _purchase_long_term_unlock(run_state, offer, price)
		_:
			run_state.coins += price
			return {"success": false, "message": "商品类型无效"}


func purchase_offer_by_slot(run_state, slot_group: StringName, index: int = 0) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var state: Dictionary = run_state.current_shop_state
	if state.is_empty():
		return {"success": false, "message": "商店尚未生成"}
	match slot_group:
		&"random_item_slots":
			var offers: Array = state.get("random_item_slots", [])
			if index < 0 or index >= offers.size():
				return {"success": false, "message": "商品槽不存在"}
			return purchase_offer(run_state, offers[index])
		&"booster_slots":
			var offers: Array = state.get("booster_slots", [])
			if index < 0 or index >= offers.size():
				return {"success": false, "message": "补充包槽不存在"}
			return purchase_offer(run_state, offers[index])
		&"long_term_unlock_slot":
			return purchase_offer(run_state, state.get("long_term_unlock_slot", null))
		_:
			return {"success": false, "message": "商店槽位类型无效"}


func get_offer_unavailable_reason(run_state, offer_any) -> String:
	var offer := _offer_from_any(offer_any)
	if run_state == null:
		return "缺少本局状态"
	if offer == null:
		return "商品无效"

	var price := _current_price_for_offer(run_state, offer)
	if run_state.coins < price:
		return "金币不足"

	if offer.offer_kind == ShopOfferDef.KIND_RANDOM_ITEM and run_state.get_free_item_slot_count() <= 0:
		return "道具槽位不足"

	if offer.offer_kind == ShopOfferDef.KIND_BOOSTER_PACK:
		var required_slots := BoosterPackCatalog.required_item_slots_before_purchase(offer.payload_id)
		if required_slots > 0 and run_state.get_free_item_slot_count() < required_slots:
			return "道具槽位不足"

	if offer.offer_kind == ShopOfferDef.KIND_LONG_TERM_UNLOCK:
		var unlock_reason := LongTermUnlockService.get_unlock_unavailable_reason(run_state, offer.payload_id)
		if unlock_reason != "":
			return unlock_reason

	return ""


func get_offer_view_data(run_state, offer_any) -> Dictionary:
	var offer := _offer_from_any(offer_any)
	if offer == null:
		return {}
	return {
		"offer_id": offer.offer_id,
		"name": offer.display_name,
		"price": _current_price_for_offer(run_state, offer),
		"type": _offer_type_text(offer),
		"description": _offer_description(offer),
		"unavailable_reason": get_offer_unavailable_reason(run_state, offer),
	}


func _purchase_random_item(run_state, offer: ShopOfferDef, price: int) -> Dictionary:
	var item_type := _item_type_for_offer(offer)
	if not run_state.add_item_to_inventory_or_pending(offer.payload_id, item_type):
		run_state.coins += price
		return {"success": false, "message": "道具槽位不足"}

	var type_text := _payload_type_text(offer.payload_kind)
	var message := "[商店] 购买 %s：%s，花费 %d 金币，进入道具槽位。" % [
		type_text,
		offer.display_name,
		price,
	]
	_record_log(run_state, message, {
		"kind": &"random_item",
		"payload_id": offer.payload_id,
		"payload_kind": offer.payload_kind,
		"cost": price,
	})
	return {
		"success": true,
		"message": message,
		"offer": offer,
		"cost": price,
	}


func _purchase_booster_pack(run_state, offer: ShopOfferDef, price: int) -> Dictionary:
	var open_result := booster_pack_service.open_pack(run_state, offer.payload_id)
	if not bool(open_result.get("success", false)):
		run_state.coins += price
		return open_result
	open_result["cost"] = price
	open_result["offer"] = offer
	return open_result


func _purchase_long_term_unlock(run_state, offer: ShopOfferDef, price: int) -> Dictionary:
	var result := long_term_unlock_service.apply_unlock(run_state, offer.payload_id)
	if not bool(result.get("success", false)):
		run_state.coins += price
		return result
	result["cost"] = price
	result["offer"] = offer
	return result


func _draw_random_item_payload_kind() -> StringName:
	var weights := ShopCatalog.get_random_item_kind_weights()
	var total := 0
	for entry in weights:
		total += max(0, int(entry.get("weight", 0)))
	if total <= 0:
		return ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM
	var roll := rng.randi_range(1, total)
	var cursor := 0
	for entry in weights:
		cursor += max(0, int(entry.get("weight", 0)))
		if roll <= cursor:
			return StringName(str(entry.get("payload_kind", ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM)))
	return ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM


func _draw_payload_id(payload_kind: StringName) -> StringName:
	var pool := ShopCatalog.get_payload_pool(payload_kind)
	if pool.is_empty():
		return &""
	var choice = pool[rng.randi_range(0, pool.size() - 1)]
	if choice is Dictionary:
		return StringName(str(choice.get("id", &"")))
	return StringName(str(choice))


func _current_price_for_offer(run_state, offer: ShopOfferDef) -> int:
	if offer == null:
		return 0
	var price: int = max(0, offer.price_coins)
	return max(0, dice_tool_service.on_shop_price_query(run_state, _price_query_item_for_offer(offer), price))


func _price_query_item_for_offer(offer: ShopOfferDef) -> Dictionary:
	if offer.payload_kind == ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
		return {"item_id": offer.payload_id, "item_type": ItemInstance.TYPE_COMBO_UPGRADE}
	if offer.payload_kind == ShopOfferDef.PAYLOAD_BOOSTER_PACK:
		var pack_def := BoosterPackCatalog.get_def(offer.payload_id)
		if pack_def != null and pack_def.pack_kind == BoosterPackDef.KIND_COMBO:
			return {"item_id": ComboUpgradeCatalog.item_id_for_combo(&"combo_scatter"), "item_type": ItemInstance.TYPE_COMBO_UPGRADE}
	return {"item_id": offer.payload_id, "item_type": _item_type_for_offer(offer)}


func _item_type_for_offer(offer: ShopOfferDef) -> StringName:
	match offer.payload_kind:
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			return ItemInstance.TYPE_DICE_TOOL
		ShopOfferDef.PAYLOAD_FORGE_ITEM:
			return ItemInstance.TYPE_FORGE_ITEM
		ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
			return ItemInstance.TYPE_COMBO_UPGRADE
		_:
			return ItemInstance.TYPE_GENERIC


func _payload_type_text(payload_kind: StringName) -> String:
	match payload_kind:
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			return "骰具道具"
		ShopOfferDef.PAYLOAD_FORGE_ITEM:
			return "铸骰件"
		ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
			return "主骰型升级件"
		ShopOfferDef.PAYLOAD_BOOSTER_PACK:
			return "补充包"
		ShopOfferDef.PAYLOAD_LONG_TERM_UNLOCK:
			return "长期解锁"
		_:
			return "商品"


func _offer_type_text(offer: ShopOfferDef) -> String:
	match offer.offer_kind:
		ShopOfferDef.KIND_RANDOM_ITEM:
			return _payload_type_text(offer.payload_kind)
		ShopOfferDef.KIND_BOOSTER_PACK:
			return "补充包"
		ShopOfferDef.KIND_LONG_TERM_UNLOCK:
			return "长期解锁"
		_:
			return "商品"


func _offer_description(offer: ShopOfferDef) -> String:
	match offer.offer_kind:
		ShopOfferDef.KIND_RANDOM_ITEM:
			return "购买后进入道具槽位。"
		ShopOfferDef.KIND_BOOSTER_PACK:
			return "购买后立即打开。"
		ShopOfferDef.KIND_LONG_TERM_UNLOCK:
			return LongTermUnlockService.view_data_for_unlock(offer.payload_id).get("description", "购买后立即生效。")
		_:
			return ""


func _reroll_cost_for_state(run_state, state: Dictionary) -> int:
	if int(state.get("free_rerolls", 0)) > 0:
		return 0
	return run_state.get_shop_reroll_cost()


func _update_reroll_cost(state: Dictionary, run_state) -> void:
	state["reroll_cost"] = _reroll_cost_for_state(run_state, state)


func _random_item_slot_count(run_state) -> int:
	if run_state != null and run_state.has_method("get_shop_random_item_slot_count"):
		return run_state.get_shop_random_item_slot_count()
	return 2


func _booster_slot_count(run_state) -> int:
	if run_state != null and run_state.has_method("get_shop_booster_slot_count"):
		return run_state.get_shop_booster_slot_count()
	return 2


func _offer_from_any(value) -> ShopOfferDef:
	if value is ShopOfferDef:
		return (value as ShopOfferDef).clone()
	if value is Dictionary:
		return ShopOfferDef.from_dict(value)
	return null


func _next_offer_id(prefix: StringName) -> StringName:
	offer_serial += 1
	return StringName("%s_%d" % [str(prefix), offer_serial])


func _record_log(run_state, message: String, details: Dictionary = {}) -> void:
	if message == "":
		return
	if run_state != null and run_state.has_method("record_shop_log"):
		run_state.record_shop_log(message, details)
