extends RefCounted
class_name ShopService


const BoosterPackCatalog = preload("res://scripts/rules/shop/BoosterPackCatalog.gd")
const BoosterPackDef = preload("res://scripts/data_defs/BoosterPackDef.gd")
const BoosterPackService = preload("res://scripts/rules/shop/BoosterPackService.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
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


func generate_shop(run_state, options: Dictionary = {}) -> Dictionary:
	if run_state == null:
		return {}
	run_state.shop_reroll_count_this_shop = 0
	run_state.shop_non_unlock_purchase_count_this_shop = 0
	var generation_options := options.duplicate(true)
	var first_circle_first_shop := bool(generation_options.get("first_circle_first_shop", false))
	var relic_shelf_slot_count := _relic_shelf_slot_count(run_state)
	var booster_slot_count := _booster_slot_count(run_state)
	var state := {
		"relic_shelf_slots": generate_relic_shelf_offers(relic_shelf_slot_count, run_state, generation_options),
		"booster_slots": generate_booster_pack_offers(booster_slot_count, run_state, generation_options),
		"long_term_unlock_slot": generate_long_term_unlock_offer(run_state),
		"free_rerolls": 0 if first_circle_first_shop else (1 if bool(run_state.first_reroll_free) else 0),
		"first_circle_first_shop_protection": first_circle_first_shop,
		"reroll_cost": run_state.get_shop_reroll_cost(),
	}
	dice_tool_service.apply_shop_open_effects(run_state, state)
	_update_reroll_cost(state, run_state)
	run_state.current_shop_state = state
	return state


func generate_relic_shelf_offers(count: int, run_state = null, options: Dictionary = {}) -> Array[ShopOfferDef]:
	var result: Array[ShopOfferDef] = []
	var used_ids: Array[StringName] = []
	if bool(options.get("first_circle_first_shop", false)) and count > 0:
		var common_payload_id := _draw_relic_shelf_payload_id_for_rarity(&"common", used_ids, run_state)
		if common_payload_id != &"":
			used_ids.append(common_payload_id)
			result.append(_make_relic_shelf_offer(common_payload_id))
	for _index in range(max(0, count)):
		if result.size() >= count:
			break
		var payload_kind := ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM
		var payload_id := _draw_relic_shelf_payload_id(run_state, used_ids)
		if payload_id == &"":
			continue
		used_ids.append(payload_id)
		result.append(_make_relic_shelf_offer(payload_id))
	return result


func generate_booster_pack_offers(count: int, run_state = null, options: Dictionary = {}) -> Array[ShopOfferDef]:
	var ids := BoosterPackCatalog.get_pack_ids_for_shop(run_state, options)
	var result: Array[ShopOfferDef] = []
	while result.size() < count and not ids.is_empty():
		var index := _draw_weighted_pack_index(ids, run_state, options)
		var pack_id := StringName(str(ids[index]))
		ids.remove_at(index)
		result.append(ShopCatalog.make_booster_offer(_next_offer_id(&"shop_booster"), pack_id))
	if bool(options.get("first_circle_first_shop", false)) and count > 0 and not _booster_offers_include_basic_pack(result):
		var replacement_pack_id := _draw_first_circle_basic_pack_id(result)
		if replacement_pack_id != &"":
			if result.is_empty():
				result.append(ShopCatalog.make_booster_offer(_next_offer_id(&"shop_booster"), replacement_pack_id))
			else:
				result[0] = ShopCatalog.make_booster_offer(_next_offer_id(&"shop_booster"), replacement_pack_id)
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
	state["relic_shelf_slots"] = generate_relic_shelf_offers(_relic_shelf_slot_count(run_state), run_state, _shop_generation_options_from_state(state))
	_update_reroll_cost(state, run_state)
	run_state.current_shop_state = state

	var message := "[骰商铺] 刷新遗物货架，花费 %d 金币。" % [cost]
	_record_log(run_state, message, {"kind": &"shop_reroll", "cost": cost})
	for tool_log in dice_tool_service.on_shop_rerolled(run_state):
		_record_log(run_state, tool_log, {"kind": &"dice_tool", "source": &"shop_reroll"})

	return {
		"success": true,
		"message": message,
		"cost": cost,
		"shop_state": state,
	}


func end_shop_phase(run_state) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	for tool_log in dice_tool_service.on_shop_phase_end(run_state):
		_record_log(run_state, tool_log, {"kind": &"dice_tool", "source": &"shop_phase_end"})
	run_state.current_shop_state.clear()
	run_state.pending_booster_resolution.clear()
	return {"success": true, "message": "离开骰商铺"}


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

	var result := {}
	match offer.offer_kind:
		ShopOfferDef.KIND_RANDOM_ITEM:
			result = _purchase_random_item(run_state, offer, price)
		ShopOfferDef.KIND_BOOSTER_PACK:
			result = _purchase_booster_pack(run_state, offer, price)
		ShopOfferDef.KIND_LONG_TERM_UNLOCK:
			result = _purchase_long_term_unlock(run_state, offer, price)
		_:
			run_state.coins += price
			return {"success": false, "message": "商品类型无效"}
	if bool(result.get("success", false)) and offer.offer_kind != ShopOfferDef.KIND_LONG_TERM_UNLOCK:
		run_state.shop_non_unlock_purchase_count_this_shop += 1
	return result


func purchase_offer_by_slot(run_state, slot_group: StringName, index: int = 0) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var state: Dictionary = run_state.current_shop_state
	if state.is_empty():
		return {"success": false, "message": "骰商铺尚未生成"}
	match slot_group:
		&"relic_shelf_slots":
			var offers: Array = state.get("relic_shelf_slots", [])
			if index < 0 or index >= offers.size():
				return {"success": false, "message": "遗物货架槽不存在"}
			var result := purchase_offer(run_state, offers[index])
			if bool(result.get("success", false)):
				offers[index] = null
				state["relic_shelf_slots"] = offers
				run_state.current_shop_state = state
				result["shop_state"] = state
			return result
		&"booster_slots":
			var offers: Array = state.get("booster_slots", [])
			if index < 0 or index >= offers.size():
				return {"success": false, "message": "骰包槽不存在"}
			var result := purchase_offer(run_state, offers[index])
			if bool(result.get("success", false)):
				offers[index] = null
				state["booster_slots"] = offers
				run_state.current_shop_state = state
				result["shop_state"] = state
			return result
		&"long_term_unlock_slot":
			var result := purchase_offer(run_state, state.get("long_term_unlock_slot", null))
			if bool(result.get("success", false)):
				state["long_term_unlock_slot"] = null
				run_state.current_shop_state = state
				_sync_current_shop_after_long_term_unlock(run_state)
				result["shop_state"] = run_state.current_shop_state
			return result
		_:
			return {"success": false, "message": "骰商铺槽位类型无效"}


func sell_relic_by_index(run_state, index: int) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	if index < 0 or index >= run_state.dice_tools.size():
		return {"success": false, "message": "遗物槽位不存在"}
	var removed_tool = run_state.remove_dice_tool_at_index(index)
	if removed_tool == null:
		return {"success": false, "message": "遗物槽位不存在"}
	var tool_id := StringName(str(removed_tool.tool_id))
	var sell_price := ShopCatalog.sell_price_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
	run_state.add_coins(sell_price, &"shop_relic_sale")
	var message := "[骰商铺] 出售 骰具遗物：%s，获得 %d 金币。" % [
		removed_tool.display_name if removed_tool.display_name != "" else ShopCatalog.display_name_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id),
		sell_price,
	]
	_record_log(run_state, message, {"kind": &"relic_sale", "tool_id": tool_id, "coins": sell_price})
	for tool_log in dice_tool_service.on_tool_sold(run_state, removed_tool):
		_record_log(run_state, tool_log, {"kind": &"dice_tool", "source": &"tool_sold"})
	return {
		"success": true,
		"message": message,
		"coins": sell_price,
		"tool_id": tool_id,
		"shop_state": run_state.current_shop_state,
	}


func get_offer_unavailable_reason(run_state, offer_any) -> String:
	var offer := _offer_from_any(offer_any)
	if run_state == null:
		return "缺少本局状态"
	if offer == null:
		return "商品无效"

	if offer.offer_kind == ShopOfferDef.KIND_LONG_TERM_UNLOCK:
		var unlock_reason := LongTermUnlockService.get_unlock_unavailable_reason(run_state, offer.payload_id)
		if unlock_reason != "":
			return unlock_reason

	var price := _current_price_for_offer(run_state, offer)
	if run_state.coins < price:
		return "金币不足"

	if offer.offer_kind == ShopOfferDef.KIND_RANDOM_ITEM and offer.payload_kind == ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
		if run_state.get_free_dice_tool_slot_count() <= 0:
			return "遗物栏已满，请先出售一个遗物。"
	elif offer.offer_kind == ShopOfferDef.KIND_RANDOM_ITEM and offer.payload_kind != ShopOfferDef.PAYLOAD_FACE_SHOP_ITEM and run_state.get_free_item_slot_count() <= 0:
		return "道具槽位不足"

	if offer.offer_kind == ShopOfferDef.KIND_BOOSTER_PACK:
		var required_relic_slots := BoosterPackCatalog.required_relic_slots_before_purchase(offer.payload_id)
		if required_relic_slots > 0 and run_state.get_free_dice_tool_slot_count() < required_relic_slots:
			return "遗物槽位不足"
		var required_slots := BoosterPackCatalog.required_item_slots_before_purchase(offer.payload_id)
		if required_slots > 0 and run_state.get_free_item_slot_count() < required_slots:
			return "道具槽位不足"

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
	if offer.payload_kind == ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
		return _purchase_relic_shelf_item(run_state, offer, price)

	var item_type := _item_type_for_offer(offer)
	if not run_state.add_item_to_inventory_or_pending(offer.payload_id, item_type):
		run_state.coins += price
		return {"success": false, "message": "道具槽位不足"}

	var type_text := _payload_type_text(offer.payload_kind)
	var message := "[骰商铺] 购买 %s：%s，花费 %d 金币，进入道具槽位。" % [
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


func _purchase_relic_shelf_item(run_state, offer: ShopOfferDef, price: int) -> Dictionary:
	var item: ItemInstance = ItemInstance.create_dice_tool(
		offer.payload_id,
		offer.display_name,
		ShopCatalog.sell_price_for_payload(offer.payload_kind, offer.payload_id)
	)
	item.metadata["rarity"] = ShopCatalog.rarity_for_payload(offer.payload_kind, offer.payload_id)
	if not run_state.install_dice_tool_item_instance(item):
		run_state.coins += price
		return {"success": false, "message": "遗物栏已满，请先出售一个遗物。"}

	var message := "[骰商铺] 购买 骰具遗物：%s，花费 %d 金币，进入遗物栏并立即生效。" % [
		offer.display_name,
		price,
	]
	_record_log(run_state, message, {
		"kind": &"relic_shelf_purchase",
		"tool_id": offer.payload_id,
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


func _draw_relic_shelf_payload_id(run_state = null, excluded_ids: Array[StringName] = []) -> StringName:
	var rarity := _draw_relic_shelf_rarity(run_state)
	var payload_id := _draw_relic_shelf_payload_id_for_rarity(rarity, excluded_ids, run_state)
	if payload_id != &"":
		return payload_id
	var pool := _relic_shelf_pool_for_any_normal_rarity(excluded_ids, run_state)
	return _draw_relic_payload_id_from_pool(pool)


func _draw_relic_shelf_payload_id_for_rarity(rarity: StringName, excluded_ids: Array[StringName], run_state = null) -> StringName:
	var pool := _relic_shelf_pool_for_rarity(rarity, excluded_ids, run_state)
	return _draw_relic_payload_id_from_pool(pool)


func _draw_relic_payload_id_from_pool(pool: Array) -> StringName:
	if pool.is_empty():
		return &""
	var choice: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	return StringName(str(choice.get("id", &"")))


func _make_relic_shelf_offer(payload_id: StringName) -> ShopOfferDef:
	var payload_kind := ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM
	var display_name := ShopCatalog.display_name_for_payload(payload_kind, payload_id)
	return ShopCatalog.make_random_item_offer(
		_next_offer_id(&"shop_relic"),
		payload_kind,
		payload_id,
		display_name,
		ShopCatalog.base_price_for_payload(payload_kind, payload_id),
		"遗物货架"
	)


func _draw_relic_shelf_rarity(run_state = null) -> StringName:
	var circle_number := 1
	if run_state != null and run_state.has_method("get_circle_number"):
		circle_number = int(run_state.get_circle_number())
	var weights := ShopCatalog.relic_rarity_weights_for_circle(circle_number)
	var total_weight := 0
	for data in weights:
		total_weight += max(0, int(data.get("weight", 0)))
	if total_weight <= 0:
		return &"common"
	var roll := rng.randi_range(1, total_weight)
	var cursor := 0
	for data in weights:
		cursor += max(0, int(data.get("weight", 0)))
		if roll <= cursor:
			return StringName(str(data.get("rarity", &"common")))
	return &"common"


func _relic_shelf_pool_for_rarity(rarity: StringName, excluded_ids: Array[StringName], run_state = null) -> Array:
	var result := []
	for data in ShopCatalog.get_normal_shop_relic_pool(rarity, run_state):
		var id := StringName(str(data.get("id", &"")))
		if id == &"" or excluded_ids.has(id):
			continue
		result.append(data)
	return result


func _relic_shelf_pool_for_any_normal_rarity(excluded_ids: Array[StringName], run_state = null) -> Array:
	var result := []
	for data in ShopCatalog.get_normal_shop_relic_pool(&"", run_state):
		var id := StringName(str(data.get("id", &"")))
		if id == &"" or excluded_ids.has(id):
			continue
		result.append(data)
	return result


func _draw_payload_id(payload_kind: StringName, run_state = null) -> StringName:
	var pool := ShopCatalog.get_payload_pool(payload_kind, run_state)
	if pool.is_empty():
		return &""
	var choice = pool[rng.randi_range(0, pool.size() - 1)]
	if choice is Dictionary:
		return StringName(str(choice.get("id", &"")))
	return StringName(str(choice))


func _draw_weighted_pack_index(ids: Array[StringName], run_state = null, options: Dictionary = {}) -> int:
	if ids.is_empty():
		return -1
	var total_weight := 0
	for pack_id in ids:
		total_weight += max(0, BoosterPackCatalog.shop_weight_for_pack_id(pack_id, run_state, options))
	if total_weight <= 0:
		return rng.randi_range(0, ids.size() - 1)
	var roll := rng.randi_range(1, total_weight)
	var cursor := 0
	for index in range(ids.size()):
		cursor += max(0, BoosterPackCatalog.shop_weight_for_pack_id(ids[index], run_state, options))
		if roll <= cursor:
			return index
	return ids.size() - 1


func _current_price_for_offer(run_state, offer: ShopOfferDef) -> int:
	if offer == null:
		return 0
	var price: int = max(0, offer.price_coins)
	if run_state != null:
		price = _price_after_long_term_discounts(run_state, offer, price)
	return max(0, dice_tool_service.on_shop_price_query(run_state, _price_query_item_for_offer(offer), price))


func _price_after_long_term_discounts(run_state, offer: ShopOfferDef, base_price: int) -> int:
	var price: int = max(0, base_price)
	var discount := 0.0
	if offer.offer_kind == ShopOfferDef.KIND_RANDOM_ITEM:
		discount += max(0.0, float(run_state.shop_random_item_discount))
	if offer.payload_kind == ShopOfferDef.PAYLOAD_FORGE_ITEM:
		discount += max(0.0, float(run_state.forge_item_discount))
	if offer.payload_kind == ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
		discount += max(0.0, float(run_state.combo_upgrade_discount))
	if discount > 0.0:
		price = _apply_percent_discount(price, min(discount, 0.95))
	if offer.offer_kind != ShopOfferDef.KIND_LONG_TERM_UNLOCK and int(run_state.shop_non_unlock_purchase_count_this_shop) <= 0:
		price = _apply_percent_discount(price, max(0.0, float(run_state.first_non_unlock_purchase_discount)))
	return price


func _apply_percent_discount(price: int, discount: float) -> int:
	if price <= 0 or discount <= 0.0:
		return max(0, price)
	return max(0, int(floor(float(price) * max(0.0, 1.0 - discount))))


func _price_query_item_for_offer(offer: ShopOfferDef) -> Dictionary:
	if offer.payload_kind == ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
		return {"item_id": offer.payload_id, "item_type": ItemInstance.TYPE_COMBO_UPGRADE}
	if offer.payload_kind == ShopOfferDef.PAYLOAD_BOOSTER_PACK:
		var pack_def := BoosterPackCatalog.get_def(offer.payload_id)
		if pack_def != null and pack_def.pack_kind == BoosterPackDef.KIND_COMBO:
			return {"item_id": ComboUpgradeCatalog.item_id_for_combo(&"combo_scatter"), "item_type": ItemInstance.TYPE_COMBO_UPGRADE}
	if offer.payload_kind == ShopOfferDef.PAYLOAD_FACE_SHOP_ITEM:
		return {"item_id": offer.payload_id, "item_type": ItemInstance.TYPE_GENERIC}
	return {"item_id": offer.payload_id, "item_type": _item_type_for_offer(offer)}


func _item_type_for_offer(offer: ShopOfferDef) -> StringName:
	match offer.payload_kind:
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			return ItemInstance.TYPE_DICE_TOOL
		ShopOfferDef.PAYLOAD_FORGE_ITEM:
			return ItemInstance.TYPE_FORGE_ITEM
		ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
			return ItemInstance.TYPE_COMBO_UPGRADE
		ShopOfferDef.PAYLOAD_FACE_SHOP_ITEM:
			return ItemInstance.TYPE_GENERIC
		_:
			return ItemInstance.TYPE_GENERIC


func _payload_type_text(payload_kind: StringName) -> String:
	match payload_kind:
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			return "骰具遗物"
		ShopOfferDef.PAYLOAD_FORGE_ITEM:
			return "铸骰件"
		ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
			return "主骰型升级件"
		ShopOfferDef.PAYLOAD_FACE_SHOP_ITEM:
			return "骰面改造商品"
		ShopOfferDef.PAYLOAD_BOOSTER_PACK:
			return "骰包"
		ShopOfferDef.PAYLOAD_LONG_TERM_UNLOCK:
			return "长期解锁"
		_:
			return "商品"


func _offer_type_text(offer: ShopOfferDef) -> String:
	match offer.offer_kind:
		ShopOfferDef.KIND_RANDOM_ITEM:
			if offer.payload_kind == ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
				return "骰具遗物 · %s" % [_rarity_text(ShopCatalog.rarity_for_payload(offer.payload_kind, offer.payload_id))]
			return _payload_type_text(offer.payload_kind)
		ShopOfferDef.KIND_BOOSTER_PACK:
			return "骰包"
		ShopOfferDef.KIND_LONG_TERM_UNLOCK:
			return "长期解锁"
		_:
			return "商品"


func _offer_description(offer: ShopOfferDef) -> String:
	match offer.offer_kind:
		ShopOfferDef.KIND_RANDOM_ITEM:
			if offer.payload_kind == ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
				return _relic_offer_description(offer)
			return "购买后进入道具槽位。"
		ShopOfferDef.KIND_BOOSTER_PACK:
			return _booster_offer_description(offer)
		ShopOfferDef.KIND_LONG_TERM_UNLOCK:
			return LongTermUnlockService.view_data_for_unlock(offer.payload_id).get("description", "购买后立即生效。")
		_:
			return ""


func _relic_offer_description(offer: ShopOfferDef) -> String:
	var def := DiceToolCatalog.get_def(offer.payload_id)
	var effect_text := def.effect_text if def != null else "效果待确认。"
	return "效果：%s\n购买后进入遗物栏并立即生效。" % [effect_text]


func _booster_offer_description(offer: ShopOfferDef) -> String:
	var pack_def := BoosterPackCatalog.get_def(offer.payload_id)
	if pack_def == null:
		return "购买后立即打开。"
	var content_text := ""
	var apply_text := ""
	match pack_def.pack_kind:
		BoosterPackDef.KIND_FACE:
			content_text = "点数片 / 面饰片 / 印记片 / 复合件"
			apply_text = "选择后立即安装到骰面。"
		BoosterPackDef.KIND_COMBO:
			content_text = "主骰型升级"
			apply_text = "选择后立即升级对应主骰型。"
		BoosterPackDef.KIND_RELIC:
			content_text = "骰具遗物"
			apply_text = "选择后进入遗物栏并立即生效。"
		_:
			content_text = "候选奖励"
			apply_text = "选择后立即处理。"
	return "打开后出现 %d 个候选，选择 %d 个。\n内容：%s。\n%s" % [
		pack_def.candidate_count,
		pack_def.choose_count,
		content_text,
		apply_text,
	]


func _rarity_text(rarity: StringName) -> String:
	match rarity:
		&"legendary":
			return "传说"
		&"epic":
			return "史诗"
		&"rare":
			return "稀有"
		&"uncommon":
			return "罕见"
		_:
			return "普通"


func _reroll_cost_for_state(run_state, state: Dictionary) -> int:
	if bool(state.get("first_circle_first_shop_protection", false)):
		return max(1, 5 + int(run_state.shop_reroll_count_this_shop))
	if int(state.get("free_rerolls", 0)) > 0:
		return 0
	return run_state.get_shop_reroll_cost()


func _update_reroll_cost(state: Dictionary, run_state) -> void:
	state["reroll_cost"] = _reroll_cost_for_state(run_state, state)


func _random_item_slot_count(run_state) -> int:
	if run_state != null and run_state.has_method("get_shop_random_item_slot_count"):
		return run_state.get_shop_random_item_slot_count()
	return 2


func _relic_shelf_slot_count(run_state) -> int:
	if run_state != null and run_state.has_method("get_shop_relic_shelf_slot_count"):
		return run_state.get_shop_relic_shelf_slot_count()
	return _random_item_slot_count(run_state)


func _booster_slot_count(run_state) -> int:
	if run_state != null and run_state.has_method("get_shop_booster_slot_count"):
		return run_state.get_shop_booster_slot_count()
	return 2


func _sync_current_shop_after_long_term_unlock(run_state) -> void:
	if run_state == null or run_state.current_shop_state.is_empty():
		return
	var state: Dictionary = run_state.current_shop_state
	var generation_options := _shop_generation_options_from_state(state)
	var relic_slots: Array = state.get("relic_shelf_slots", [])
	var expected_relic := _relic_shelf_slot_count(run_state)
	if relic_slots.size() < expected_relic:
		relic_slots.append_array(generate_relic_shelf_offers(expected_relic - relic_slots.size(), run_state, generation_options))
	state["relic_shelf_slots"] = relic_slots

	var booster_slots: Array = state.get("booster_slots", [])
	var expected_boosters := _booster_slot_count(run_state)
	if booster_slots.size() < expected_boosters:
		booster_slots.append_array(generate_booster_pack_offers(expected_boosters - booster_slots.size(), run_state, generation_options))
	state["booster_slots"] = booster_slots

	_update_reroll_cost(state, run_state)
	run_state.current_shop_state = state


func _shop_generation_options_from_state(state: Dictionary) -> Dictionary:
	return {
		"first_circle_first_shop": bool(state.get("first_circle_first_shop_protection", false)),
	}


func _booster_offers_include_basic_pack(offers: Array[ShopOfferDef]) -> bool:
	for offer in offers:
		if offer != null and BoosterPackCatalog.is_basic_pack(offer.payload_id):
			return true
	return false


func _draw_first_circle_basic_pack_id(existing_offers: Array[ShopOfferDef]) -> StringName:
	var existing_ids: Array[StringName] = []
	for offer in existing_offers:
		if offer != null:
			existing_ids.append(offer.payload_id)
	var candidates := BoosterPackCatalog.get_basic_pack_ids()
	for index in range(candidates.size() - 1, -1, -1):
		if existing_ids.has(candidates[index]):
			candidates.remove_at(index)
	if candidates.is_empty():
		candidates = BoosterPackCatalog.get_basic_pack_ids()
	if candidates.is_empty():
		return &""
	return StringName(str(candidates[rng.randi_range(0, candidates.size() - 1)]))


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
