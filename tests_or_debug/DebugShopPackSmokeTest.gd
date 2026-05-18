extends SceneTree
class_name DebugShopPackSmokeTest


const BoosterOfferDef = preload("res://scripts/data_defs/BoosterOfferDef.gd")
const BoosterPackCatalog = preload("res://scripts/rules/shop/BoosterPackCatalog.gd")
const BoosterPackService = preload("res://scripts/rules/shop/BoosterPackService.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceOffer = preload("res://scripts/data_defs/FaceOffer.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const FoundryServiceCatalog = preload("res://scripts/rules/forge/FoundryServiceCatalog.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ShopCatalog = preload("res://scripts/rules/shop/ShopCatalog.gd")
const ShopOfferDef = preload("res://scripts/data_defs/ShopOfferDef.gd")
const ShopService = preload("res://scripts/rules/shop/ShopService.gd")


func _init() -> void:
	print("--- DebugShopPackSmokeTest: start ---")

	var all_passed := true
	all_passed = _check_shop_layout() and all_passed
	all_passed = _check_shop_reroll_scope() and all_passed
	all_passed = _check_random_item_purchase() and all_passed
	all_passed = _check_full_item_slots_block_random_item() and all_passed
	all_passed = _check_pack_catalog() and all_passed
	all_passed = _check_face_pack_open_rules() and all_passed
	all_passed = _check_face_offer_cover_rules() and all_passed
	all_passed = _check_d4_rejects_high_face_offer() and all_passed
	all_passed = _check_pending_target_resolution_flow() and all_passed
	all_passed = _check_forge_pack_immediate_use() and all_passed
	all_passed = _check_combo_pack_pool() and all_passed
	all_passed = _check_mega_pack_selects_distinct_candidates() and all_passed
	all_passed = _check_tool_pack_item_slot_result() and all_passed
	all_passed = _check_mega_tool_pack_slot_requirement() and all_passed
	all_passed = _check_foundry_pack_immediate_use() and all_passed
	all_passed = _check_removed_words_absent() and all_passed

	print("PASS: DebugShopPackSmokeTest" if all_passed else "FAIL: DebugShopPackSmokeTest")
	print("--- DebugShopPackSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_shop_layout() -> bool:
	var run_state := _make_run(20)
	var service := ShopService.new()
	service.rng.seed = 1101
	var state := service.generate_shop(run_state)
	var passed := (
		Array(state.get("random_item_slots", [])).size() == 2
		and Array(state.get("booster_slots", [])).size() == 2
		and state.get("long_term_unlock_slot", null) is ShopOfferDef
		and int(state.get("reroll_cost", 0)) == 5
		and run_state.get_shop_reroll_cost() == 5
	)
	return _check("shop creates 2 random item slots, 2 pack slots, 1 unlock slot, and cost 5", passed)


func _check_shop_reroll_scope() -> bool:
	var run_state := _make_run(20)
	var service := ShopService.new()
	service.rng.seed = 1201
	var state := service.generate_shop(run_state)
	var random_before := _offer_ids(state.get("random_item_slots", []))
	var booster_before := _offer_ids(state.get("booster_slots", []))
	var unlock_before := (state.get("long_term_unlock_slot") as ShopOfferDef).offer_id
	var result := service.reroll_random_shop_items(run_state)
	var after: Dictionary = run_state.current_shop_state
	var passed := (
		bool(result.get("success", false))
		and run_state.get_shop_reroll_cost() == 6
		and int(after.get("reroll_cost", 0)) == 6
		and _offer_ids(after.get("random_item_slots", [])) != random_before
		and _offer_ids(after.get("booster_slots", [])) == booster_before
		and (after.get("long_term_unlock_slot") as ShopOfferDef).offer_id == unlock_before
	)
	return _check("shop reroll changes only random item slots and raises next cost to 6", passed)


func _check_random_item_purchase() -> bool:
	var run_state := _make_run(10)
	var service := ShopService.new()
	var offer := ShopCatalog.make_random_item_offer(
		&"test_forge_offer",
		ShopOfferDef.PAYLOAD_FORGE_ITEM,
		ForgeItemCatalog.FORGE_COIN_DOUBLER,
		ForgeItemCatalog.display_name_for_id(ForgeItemCatalog.FORGE_COIN_DOUBLER),
		4
	)
	var result := service.purchase_offer(run_state, offer)
	var passed := (
		bool(result.get("success", false))
		and run_state.item_slots.size() == 1
		and run_state.item_slots[0].item_type == ItemInstance.TYPE_FORGE_ITEM
		and run_state.coins == 6
	)
	return _check("random item purchase enters item_slots", passed)


func _check_full_item_slots_block_random_item() -> bool:
	var run_state := _make_run(10)
	run_state.item_slot_capacity = 1
	run_state.add_item_to_inventory_or_pending(ForgeItemCatalog.FORGE_COIN_DOUBLER)
	var service := ShopService.new()
	var offer := ShopCatalog.make_random_item_offer(
		&"test_blocked_offer",
		ShopOfferDef.PAYLOAD_FORGE_ITEM,
		ForgeItemCatalog.FORGE_PIP_UP,
		ForgeItemCatalog.display_name_for_id(ForgeItemCatalog.FORGE_PIP_UP),
		4
	)
	var reason := service.get_offer_unavailable_reason(run_state, offer)
	var result := service.purchase_offer(run_state, offer)
	var passed := (
		reason == "道具槽位不足"
		and not bool(result.get("success", false))
		and run_state.item_slots.size() == 1
	)
	return _check("full item slots make random item unavailable", passed)


func _check_pack_catalog() -> bool:
	var expected := [
		BoosterPackCatalog.PACK_FACE_BASIC,
		BoosterPackCatalog.PACK_FACE_LARGE,
		BoosterPackCatalog.PACK_FACE_MEGA,
		BoosterPackCatalog.PACK_FORGE_BASIC,
		BoosterPackCatalog.PACK_FORGE_LARGE,
		BoosterPackCatalog.PACK_FORGE_MEGA,
		BoosterPackCatalog.PACK_COMBO_BASIC,
		BoosterPackCatalog.PACK_COMBO_LARGE,
		BoosterPackCatalog.PACK_COMBO_MEGA,
		BoosterPackCatalog.PACK_TOOL_BASIC,
		BoosterPackCatalog.PACK_TOOL_LARGE,
		BoosterPackCatalog.PACK_TOOL_MEGA,
		BoosterPackCatalog.PACK_FOUNDRY_BASIC,
		BoosterPackCatalog.PACK_FOUNDRY_LARGE,
		BoosterPackCatalog.PACK_FOUNDRY_MEGA,
	]
	var defs := BoosterPackCatalog.get_all_defs()
	var passed := defs.size() == 15
	for pack_id in expected:
		var def := BoosterPackCatalog.get_def(pack_id)
		passed = passed and def != null and def.is_formal()
		passed = passed and def.shop_pool_reserved == &"TBD"
		passed = passed and def.drop_weight_reserved == &"TBD"
	return _check("all 15 formal booster packs are queryable", passed)


func _check_face_pack_open_rules() -> bool:
	var run_state := _make_run(20)
	var before_faces := run_state.get_total_face_count()
	var service := BoosterPackService.new()
	service.rng.seed = 1301
	var result := service.open_pack(run_state, BoosterPackCatalog.PACK_FACE_BASIC)
	var candidates: Array = result.get("candidate_offers", [])
	var passed := bool(result.get("success", false)) and candidates.size() == 3
	for offer in candidates:
		passed = passed and offer is BoosterOfferDef
		passed = passed and (offer as BoosterOfferDef).payload_kind == BoosterOfferDef.PAYLOAD_FACE_OFFER
		passed = passed and not str((offer as BoosterOfferDef).payload_kind).contains("template")
	passed = passed and run_state.get_total_face_count() == before_faces
	var shop_run := _make_run(20)
	var shop_service := ShopService.new()
	var pack_offer: ShopOfferDef = ShopCatalog.make_booster_offer(&"face_pack_purchase", BoosterPackCatalog.PACK_FACE_BASIC)
	var purchase_result := shop_service.purchase_offer(shop_run, pack_offer)
	passed = passed and bool(purchase_result.get("success", false))
	passed = passed and shop_run.item_slots.is_empty()
	passed = passed and not shop_run.pending_booster_resolution.is_empty()
	return _check("face pack opens face offers without adding faces or templates", passed)


func _check_face_offer_cover_rules() -> bool:
	var run_state := _make_run(20)
	var service := BoosterPackService.new()
	var face := run_state.dice[0].faces[0]
	face.pip = 2
	face.ornament_id = FaceState.ORN_CHIP
	face.mark_id = FaceState.MARK_RED
	var pip_offer: FaceOffer = FaceOffer.create(&"pip_only_test", "6 点改造", FaceOffer.COVER_PIP_ONLY, 6)
	var pip_result := service.apply_face_offer_to_target(run_state, pip_offer, 0, 0)
	var pip_passed := (
		bool(pip_result.get("success", false))
		and face.pip == 6
		and face.ornament_id == FaceState.ORN_CHIP
		and face.mark_id == FaceState.MARK_RED
	)
	var slots_offer: FaceOffer = FaceOffer.create(&"slots_test", "面饰与印记", FaceOffer.COVER_ORNAMENT_MARK, 0, FaceState.ORN_LUCKY, FaceState.MARK_BLUE)
	var slots_result := service.apply_face_offer_to_target(run_state, slots_offer, 0, 0)
	var slots_passed := (
		bool(slots_result.get("success", false))
		and face.pip == 6
		and face.ornament_id == FaceState.ORN_LUCKY
		and face.mark_id == FaceState.MARK_BLUE
	)
	return _check("face offers cover only declared FaceState slots", pip_passed and slots_passed)


func _check_d4_rejects_high_face_offer() -> bool:
	var run_state := _make_run(20)
	run_state.dice[0] = _make_die(&"d4_test", 4)
	var service := BoosterPackService.new()
	var offer: FaceOffer = FaceOffer.create(&"pip_6_test", "6 点改造", FaceOffer.COVER_PIP_ONLY, 6)
	var validation := service.can_apply_face_offer_to_target(run_state, offer, 0, 0)
	var passed := (
		not bool(validation.get("success", false))
		and str(validation.get("reason", "")) == "点数不适用于该骰子"
	)
	return _check("D4 rejects pip 5/6/7/8 face offers as targets", passed)


func _check_pending_target_resolution_flow() -> bool:
	var face_run := _make_run(20)
	var face_service := BoosterPackService.new()
	face_service.rng.seed = 1401
	face_service.open_pack(face_run, BoosterPackCatalog.PACK_FACE_BASIC)
	var face_need_target := face_service.select_pending_offer(face_run, 0)
	var face_resolved := face_service.resolve_pending_target(face_run, {"die_index": 0, "face_index": 0})

	var forge_run := _make_run(20)
	var forge_service := BoosterPackService.new()
	var forge_offer: BoosterOfferDef = BoosterOfferDef.create(
		&"forge_pack_face_copy",
		ForgeItemCatalog.display_name_for_id(ForgeItemCatalog.FORGE_FACE_COPY),
		&"forge",
		BoosterOfferDef.PAYLOAD_FORGE_ITEM,
		ForgeItemCatalog.FORGE_FACE_COPY
	)
	forge_run.pending_booster_resolution = _make_pending_pack([forge_offer])
	var forge_need_target := forge_service.select_pending_offer(forge_run, 0)
	var forge_resolved := forge_service.resolve_pending_target(forge_run, {
		"source_face": {"die_index": 0, "face_index": 0},
		"target_faces": [{"die_index": 0, "face_index": 1}],
	})

	var foundry_run := _make_run(20)
	var foundry_service := BoosterPackService.new()
	var foundry_offer: BoosterOfferDef = BoosterOfferDef.create(
		&"foundry_pack_sync",
		FoundryServiceCatalog.get_def(FoundryServiceCatalog.FOUNDRY_SAME_PIP_SYNC).get_display_name(),
		&"foundry",
		BoosterOfferDef.PAYLOAD_FOUNDRY_SERVICE,
		FoundryServiceCatalog.FOUNDRY_SAME_PIP_SYNC
	)
	foundry_run.pending_booster_resolution = _make_pending_pack([foundry_offer])
	var foundry_need_target := foundry_service.select_pending_offer(foundry_run, 0)
	var foundry_resolved := foundry_service.resolve_pending_target(foundry_run, {
		"target_faces": [
			{"die_index": 0, "face_index": 0},
			{"die_index": 1, "face_index": 0},
		],
	})

	var passed := (
		bool(face_need_target.get("success", false))
		and bool(face_need_target.get("needs_target", false))
		and bool(face_resolved.get("success", false))
		and bool(forge_need_target.get("success", false))
		and bool(forge_need_target.get("needs_target", false))
		and bool(forge_resolved.get("success", false))
		and bool(foundry_need_target.get("success", false))
		and bool(foundry_need_target.get("needs_target", false))
		and bool(foundry_resolved.get("success", false))
	)
	return _check("pending target selections resolve through booster services", passed)


func _check_forge_pack_immediate_use() -> bool:
	var run_state := _make_run(5)
	var service := BoosterPackService.new()
	var before_slots := run_state.item_slots.size()
	var offer: BoosterOfferDef = BoosterOfferDef.create(
		&"forge_pack_coin",
		ForgeItemCatalog.display_name_for_id(ForgeItemCatalog.FORGE_COIN_DOUBLER),
		&"forge",
		BoosterOfferDef.PAYLOAD_FORGE_ITEM,
		ForgeItemCatalog.FORGE_COIN_DOUBLER
	)
	var result := service.apply_booster_offer(run_state, offer)
	var passed := (
		bool(result.get("success", false))
		and run_state.item_slots.size() == before_slots
		and run_state.used_forge_item_count == 1
	)
	return _check("forge pack candidates immediately call ForgeItemService without entering item_slots", passed)


func _check_combo_pack_pool() -> bool:
	var service := BoosterPackService.new()
	var pool := service.get_combo_candidate_pool()
	var allowed := [
		&"combo_scatter",
		&"combo_pair",
		&"combo_two_pair",
		&"combo_three_kind",
		&"combo_full_house",
		&"combo_four_kind",
		&"combo_straight",
		&"combo_five_kind",
	]
	var generated := service.generate_candidate_offers(_make_run(20), BoosterPackCatalog.PACK_COMBO_MEGA)
	var passed := pool.size() == 8 and _same_id_set(pool, allowed)
	for offer in generated:
		passed = passed and (offer as BoosterOfferDef).payload_kind == BoosterOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM
		passed = passed and allowed.has((offer as BoosterOfferDef).payload_id)
	return _check("combo packs only generate the 8 main combo upgrade candidates", passed)


func _check_tool_pack_item_slot_result() -> bool:
	var run_state := _make_run(20)
	var service := BoosterPackService.new()
	var tool_data: Dictionary = DiceToolCatalog.get_item_pool_for_rarity()[0]
	var offer: BoosterOfferDef = BoosterOfferDef.create(
		&"tool_pack_item",
		str(tool_data.get("name", "")),
		&"tool",
		BoosterOfferDef.PAYLOAD_DICE_TOOL_ITEM,
		StringName(str(tool_data.get("id", &""))),
		{
			"rarity": StringName(str(tool_data.get("rarity", &"common"))),
			"sell_value": int(tool_data.get("sell_value", 0)),
		}
	)
	var result := service.apply_booster_offer(run_state, offer)
	var passed := (
		bool(result.get("success", false))
		and run_state.item_slots.size() == 1
		and run_state.item_slots[0].item_type == ItemInstance.TYPE_DICE_TOOL
		and run_state.dice_tools.is_empty()
	)
	return _check("tool pack creates dice tool items in item_slots without installing them", passed)


func _check_mega_pack_selects_distinct_candidates() -> bool:
	var run_state := _make_run(20)
	var service := BoosterPackService.new()
	var open_result := service.open_pack(run_state, BoosterPackCatalog.PACK_COMBO_MEGA)
	var first_result := service.select_pending_offer(run_state, 0)
	var duplicate_result := service.select_pending_offer(run_state, 0)
	var second_result := service.select_pending_offer(run_state, 1)
	var close_result := service.close_completed_pack(run_state)
	var passed := (
		bool(open_result.get("success", false))
		and bool(first_result.get("success", false))
		and not bool(duplicate_result.get("success", false))
		and str(duplicate_result.get("message", "")) == "该候选已选择"
		and bool(second_result.get("success", false))
		and bool(close_result.get("success", false))
		and run_state.pending_booster_resolution.is_empty()
	)
	return _check("mega packs select distinct candidates and can close when complete", passed)


func _check_mega_tool_pack_slot_requirement() -> bool:
	var run_state := _make_run(20)
	run_state.item_slot_capacity = 1
	var service := ShopService.new()
	var offer := ShopCatalog.make_booster_offer(&"mega_tool_pack_offer", BoosterPackCatalog.PACK_TOOL_MEGA)
	var reason := service.get_offer_unavailable_reason(run_state, offer)
	var result := service.purchase_offer(run_state, offer)
	var passed := reason == "道具槽位不足" and not bool(result.get("success", false))
	return _check("mega tool pack requires at least 2 empty item slots before purchase", passed)


func _check_foundry_pack_immediate_use() -> bool:
	var run_state := _make_run(20)
	var before_coins := run_state.coins
	var service := BoosterPackService.new()
	var offer: BoosterOfferDef = BoosterOfferDef.create(
		&"foundry_pack_burn",
		"熔毁换金",
		&"foundry",
		BoosterOfferDef.PAYLOAD_FOUNDRY_SERVICE,
		FoundryServiceCatalog.FOUNDRY_BURN_FOR_COINS
	)
	var result := service.apply_booster_offer(run_state, offer)
	var passed := (
		bool(result.get("success", false))
		and run_state.coins == before_coins + 20
		and not run_state.foundry_logs.is_empty()
	)
	return _check("foundry pack candidates immediately call FoundryService", passed)


func _check_removed_words_absent() -> bool:
	var blocked := [
		"Standard " + "Pack",
		"Arcana " + "Pack",
		"Celestial " + "Pack",
		"Buffoon " + "Pack",
		"Spect" + "ral",
		"幻" + "灵",
		"塔" + "罗",
		"同" + "域",
		"花" + "色",
		"面分布" + "模板",
		"双六骰" + "模板",
		"偶数骰" + "模板",
		"奇数骰" + "模板",
		"顺子骰" + "模板",
		"消耗" + "槽",
		"M" + "VP",
		"扩" + "展",
		"后" + "期",
	]
	var paths := [
		"res://scripts/data_defs/ShopOfferDef.gd",
		"res://scripts/data_defs/BoosterPackDef.gd",
		"res://scripts/data_defs/BoosterOfferDef.gd",
		"res://scripts/data_defs/FaceOffer.gd",
		"res://scripts/rules/shop/ShopCatalog.gd",
		"res://scripts/rules/shop/ShopService.gd",
		"res://scripts/rules/shop/BoosterPackCatalog.gd",
		"res://scripts/rules/shop/BoosterPackService.gd",
		"res://scripts/rules/shop/FaceOfferGenerator.gd",
		"res://scripts/ui/shop/ShopScreen.gd",
		"res://scenes/shop/ShopScreen.tscn",
	]
	var passed := true
	for path in paths:
		var text := FileAccess.get_file_as_string(path)
		for word in blocked:
			if text.contains(word):
				passed = false
	for def in BoosterPackCatalog.get_all_defs():
		for word in blocked:
			if def.display_name.contains(word) or str(def.pack_id).contains(word):
				passed = false
	return _check("removed legacy words do not appear in formal shop-pack data or UI text", passed)


func _make_run(coins: int) -> RunState:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.coins = coins
	return run_state


func _make_die(id: StringName, face_count: int) -> DieState:
	var die := DieState.new()
	die.id = id
	die.die_id = id
	die.face_count = face_count
	die.body_id = DieState.BODY_STANDARD
	for pip in DieState.get_legal_pips(face_count):
		die.faces.append(FaceState.new(pip))
		die.face_weights.append(1)
	return die


func _offer_ids(offers: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for offer in offers:
		if offer is ShopOfferDef:
			result.append((offer as ShopOfferDef).offer_id)
	return result


func _same_id_set(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for item in left:
		if not right.has(item):
			return false
	return true


func _make_pending_pack(offers: Array) -> Dictionary:
	var candidate_data := []
	for offer in offers:
		candidate_data.append((offer as BoosterOfferDef).to_dict())
	return {
		"pack_id": &"test_pack",
		"pack_name": "测试补充包",
		"candidate_offers": candidate_data,
		"choose_count": 1,
		"selected_offers": [],
		"selected_offer_indexes": [],
		"pending_target_selection": {},
		"completed": false,
	}


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	return passed
