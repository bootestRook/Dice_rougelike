extends SceneTree
class_name DebugShopPackSmokeTest


const BoosterOfferDef = preload("res://scripts/data_defs/BoosterOfferDef.gd")
const BoosterPackCatalog = preload("res://scripts/rules/shop/BoosterPackCatalog.gd")
const BoosterPackService = preload("res://scripts/rules/shop/BoosterPackService.gd")
const BattleScreen = preload("res://scripts/ui/battle/BattleScreen.gd")
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
	all_passed = _check_shop_offer_descriptions_show_effects() and all_passed
	all_passed = _check_shop_reroll_scope() and all_passed
	all_passed = _check_first_circle_first_shop_protection() and all_passed
	all_passed = _check_random_item_purchase() and all_passed
	all_passed = _check_relic_shelf_purchase_marks_sold_out() and all_passed
	all_passed = _check_booster_purchase_marks_sold_out() and all_passed
	all_passed = _check_purchased_relic_shows_in_top_relic_bar_model() and all_passed
	all_passed = _check_full_relic_bar_blocks_relic_purchase() and all_passed
	all_passed = _check_relic_shelf_price_and_rarity_rules() and all_passed
	all_passed = _check_relic_acquisition_table_rules() and all_passed
	all_passed = _check_relic_sale_rules() and all_passed
	all_passed = _check_pack_catalog() and all_passed
	all_passed = _check_face_pack_open_rules() and all_passed
	all_passed = _check_face_offer_cover_rules() and all_passed
	all_passed = _check_d4_rejects_high_face_offer() and all_passed
	all_passed = _check_pending_target_resolution_flow() and all_passed
	all_passed = _check_forge_pack_immediate_use() and all_passed
	all_passed = _check_combo_pack_pool() and all_passed
	all_passed = _check_mega_pack_selects_distinct_candidates() and all_passed
	all_passed = _check_tool_pack_item_slot_result() and all_passed
	all_passed = _check_mega_relic_pack_slot_requirement() and all_passed
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
		Array(state.get("relic_shelf_slots", [])).size() == 2
		and Array(state.get("booster_slots", [])).size() == 2
		and state.get("long_term_unlock_slot", null) is ShopOfferDef
		and not state.has("merchant_service_slot")
		and not state.has("random_item_slots")
		and not state.has("advanced_face_display_slots")
		and int(state.get("reroll_cost", 0)) == 5
		and run_state.get_shop_reroll_cost() == 5
		and _offers_have_payload_kind(state.get("relic_shelf_slots", []), ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM)
	)
	return _check("shop creates 1 unlock slot, 2 pack slots, 2 relic shelf slots, and cost 5", passed)


func _check_shop_offer_descriptions_show_effects() -> bool:
	var run_state := _make_run(20)
	var service := ShopService.new()
	service.rng.seed = 1111
	var state := service.generate_shop(run_state)
	var relic_offer: ShopOfferDef = Array(state.get("relic_shelf_slots", []))[0]
	var pack_offer: ShopOfferDef = Array(state.get("booster_slots", []))[0]
	var relic_view := service.get_offer_view_data(run_state, relic_offer)
	var pack_view := service.get_offer_view_data(run_state, pack_offer)
	var relic_def := DiceToolCatalog.get_def(relic_offer.payload_id)
	var pack_def := BoosterPackCatalog.get_def(pack_offer.payload_id)
	var relic_description := str(relic_view.get("description", ""))
	var pack_description := str(pack_view.get("description", ""))
	var passed := (
		relic_def != null
		and relic_description.contains("效果：")
		and relic_description.contains(relic_def.effect_text)
		and str(relic_view.get("type", "")).begins_with("骰具遗物")
		and pack_def != null
		and pack_description.contains("打开后出现 %d 个候选" % [pack_def.candidate_count])
		and pack_description.contains("选择 %d 个" % [pack_def.choose_count])
		and (pack_description.contains("点数片") or pack_description.contains("主骰型升级") or pack_description.contains("骰具遗物"))
	)
	return _check("shop cards show concrete relic effects and pack contents", passed)


func _check_shop_reroll_scope() -> bool:
	var run_state := _make_run(20)
	var service := ShopService.new()
	service.rng.seed = 1201
	var state := service.generate_shop(run_state)
	var relic_before := _offer_ids(state.get("relic_shelf_slots", []))
	var booster_before := _offer_ids(state.get("booster_slots", []))
	var unlock_before := (state.get("long_term_unlock_slot") as ShopOfferDef).offer_id
	var result := service.reroll_random_shop_items(run_state)
	var after: Dictionary = run_state.current_shop_state
	var passed := (
		bool(result.get("success", false))
		and run_state.get_shop_reroll_cost() == 6
		and int(after.get("reroll_cost", 0)) == 6
		and run_state.current_circle_action_count == 0
		and _offer_ids(after.get("relic_shelf_slots", [])) != relic_before
		and _offer_ids(after.get("booster_slots", [])) == booster_before
		and (after.get("long_term_unlock_slot") as ShopOfferDef).offer_id == unlock_before
		and _offers_have_payload_kind(after.get("relic_shelf_slots", []), ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM)
	)
	return _check("shop reroll changes only relic shelf slots and raises next cost to 6", passed)


func _check_first_circle_first_shop_protection() -> bool:
	var run_state := _make_run(40)
	run_state.first_reroll_free = true
	run_state.shop_reroll_base_cost = 1
	var service := ShopService.new()
	service.rng.seed = 1215
	var state := service.generate_shop(run_state, {"first_circle_first_shop": true})
	var relic_slots: Array = state.get("relic_shelf_slots", [])
	var booster_slots: Array = state.get("booster_slots", [])
	var initial_free_rerolls := int(state.get("free_rerolls", -1))
	var initial_reroll_cost := int(state.get("reroll_cost", -1))
	var has_common_relic := false
	for offer in relic_slots:
		var relic_offer := offer as ShopOfferDef
		if relic_offer != null and ShopCatalog.rarity_for_payload(relic_offer.payload_kind, relic_offer.payload_id) == &"common":
			has_common_relic = true
	var has_basic_pack := false
	var booster_ids: Array[StringName] = []
	var packs_allowed := true
	for offer in booster_slots:
		var pack_offer := offer as ShopOfferDef
		if pack_offer == null:
			packs_allowed = false
			continue
		booster_ids.append(pack_offer.payload_id)
		has_basic_pack = has_basic_pack or BoosterPackCatalog.is_basic_pack(pack_offer.payload_id)
		packs_allowed = packs_allowed and not BoosterPackCatalog.is_mega_pack(pack_offer.payload_id)
		packs_allowed = packs_allowed and BoosterPackCatalog.FIRST_CIRCLE_FIRST_SHOP_IDS.has(pack_offer.payload_id)
	var reroll_result := service.reroll_random_shop_items(run_state)
	var rerolled_state: Dictionary = run_state.current_shop_state
	var passed := (
		bool(state.get("first_circle_first_shop_protection", false))
		and initial_free_rerolls == 0
		and initial_reroll_cost == 5
		and has_common_relic
		and has_basic_pack
		and packs_allowed
		and BoosterPackCatalog.shop_weight_for_pack_id(BoosterPackCatalog.PACK_FACE_BASIC, run_state, {"first_circle_first_shop": true}) > BoosterPackCatalog.shop_weight_for_pack_id(BoosterPackCatalog.PACK_FACE_LARGE, run_state, {"first_circle_first_shop": true})
		and bool(reroll_result.get("success", false))
		and run_state.coins == 35
		and int(rerolled_state.get("reroll_cost", -1)) == 6
	)
	return _check("first circle first shop forbids mega packs, includes a common relic and a basic pack, and keeps reroll cost normal", passed)


func _check_random_item_purchase() -> bool:
	var run_state := _make_run(10)
	var service := ShopService.new()
	var tool_data: Dictionary = DiceToolCatalog.get_item_pool_for_rarity()[0]
	var tool_id := StringName(str(tool_data.get("id", &"")))
	var price := ShopCatalog.base_price_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
	var offer := ShopCatalog.make_random_item_offer(
		&"test_relic_offer",
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM,
		tool_id,
		str(tool_data.get("name", tool_id)),
		price
	)
	var result := service.purchase_offer(run_state, offer)
	var passed := (
		bool(result.get("success", false))
		and run_state.item_slots.is_empty()
		and run_state.dice_tools.size() == 1
		and run_state.dice_tools[0].tool_id == tool_id
		and run_state.dice_tools[0].sell_value == ShopCatalog.sell_price_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
		and run_state.coins == 10 - price
	)
	return _check("relic shelf purchase installs dice tool relic directly into relic bar", passed)


func _check_relic_shelf_purchase_marks_sold_out() -> bool:
	var run_state := _make_run(30)
	var service := ShopService.new()
	service.rng.seed = 1251
	service.generate_shop(run_state)
	var result := service.purchase_offer_by_slot(run_state, &"relic_shelf_slots", 0)
	var slots: Array = run_state.current_shop_state.get("relic_shelf_slots", [])
	var passed := (
		bool(result.get("success", false))
		and slots.size() >= 1
		and slots[0] == null
		and run_state.dice_tools.size() == 1
	)
	return _check("buying a relic shelf slot marks that shelf slot sold out", passed)


func _check_booster_purchase_marks_sold_out() -> bool:
	var run_state := _make_run(30)
	var service := ShopService.new()
	service.rng.seed = 1252
	service.generate_shop(run_state)
	var result := service.purchase_offer_by_slot(run_state, &"booster_slots", 0)
	var slots: Array = run_state.current_shop_state.get("booster_slots", [])
	var passed := (
		bool(result.get("success", false))
		and slots.size() >= 1
		and slots[0] == null
		and not run_state.pending_booster_resolution.is_empty()
	)
	return _check("buying a booster pack slot marks that pack slot sold out", passed)


func _check_purchased_relic_shows_in_top_relic_bar_model() -> bool:
	var run_state := _make_run(30)
	var service := ShopService.new()
	service.rng.seed = 1253
	service.generate_shop(run_state)
	var purchase_result := service.purchase_offer_by_slot(run_state, &"relic_shelf_slots", 0)
	var screen := BattleScreen.new()
	screen.run_state = run_state
	var slots: Array = screen.call("_build_relic_slots")
	var hud_state = screen.call("_build_hud_state")
	var passed := (
		bool(purchase_result.get("success", false))
		and run_state.dice_tools.size() == 1
		and slots.size() == 1
		and slots[0] is SlotViewData
		and (slots[0] as SlotViewData).id == run_state.dice_tools[0].tool_id
		and int(hud_state.relic_capacity) == run_state.dice_tool_capacity + run_state.contract_tool_slots
	)
	screen.queue_free()
	return _check("purchased relics feed the top relic bar HUD model", passed)


func _check_full_relic_bar_blocks_relic_purchase() -> bool:
	var run_state := _make_run(10)
	run_state.dice_tool_capacity = 1
	var service := ShopService.new()
	var tool_data: Dictionary = DiceToolCatalog.get_item_pool_for_rarity()[0]
	var tool_id := StringName(str(tool_data.get("id", &"")))
	var installed: ItemInstance = ItemInstance.create_dice_tool(tool_id, str(tool_data.get("name", tool_id)), 3)
	installed.metadata["rarity"] = StringName(str(tool_data.get("rarity", &"common")))
	run_state.install_dice_tool_item_instance(installed)
	var offer := ShopCatalog.make_random_item_offer(
		&"test_blocked_offer",
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM,
		tool_id,
		str(tool_data.get("name", tool_id)),
		ShopCatalog.base_price_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
	)
	var reason := service.get_offer_unavailable_reason(run_state, offer)
	var result := service.purchase_offer(run_state, offer)
	var passed := (
		reason == "遗物栏已满，请先出售一个遗物。"
		and not bool(result.get("success", false))
		and run_state.dice_tools.size() == 1
	)
	return _check("full relic bar makes relic shelf purchase unavailable", passed)


func _check_relic_shelf_price_and_rarity_rules() -> bool:
	var price_table_passed := (
		ShopCatalog.relic_shop_price_for_rarity(&"common") == 6
		and ShopCatalog.relic_shop_price_for_rarity(&"uncommon") == 9
		and ShopCatalog.relic_shop_price_for_rarity(&"rare") == 13
		and ShopCatalog.relic_shop_price_for_rarity(&"epic") == 18
		and ShopCatalog.sell_price_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, DiceToolCatalog.TOOL_BASIC_MULT) == 3
	)
	var run_state := _make_run(200)
	run_state.current_circle_index = 7
	var service := ShopService.new()
	service.rng.seed = 1261
	var offers := service.generate_relic_shelf_offers(80, run_state)
	var generated_passed := not offers.is_empty()
	for offer in offers:
		var relic_offer := offer as ShopOfferDef
		if relic_offer == null:
			generated_passed = false
			continue
		var rarity := ShopCatalog.rarity_for_payload(relic_offer.payload_kind, relic_offer.payload_id)
		generated_passed = generated_passed and rarity != &"legendary" and rarity != &"epic"
		generated_passed = generated_passed and relic_offer.price_coins == ShopCatalog.base_price_for_payload(relic_offer.payload_kind, relic_offer.payload_id)
	return _check("relic shelf uses rarity price table and excludes epic/legendary relics", price_table_passed and generated_passed)


func _check_relic_acquisition_table_rules() -> bool:
	var early_run := _make_run(100)
	early_run.current_circle_index = 0
	var mid_run := _make_run(100)
	mid_run.current_circle_index = 2
	var late_run := _make_run(100)
	late_run.current_circle_index = 5

	var early_pool := ShopCatalog.get_normal_shop_relic_pool(&"", early_run)
	var mid_uncommon_pool := ShopCatalog.get_normal_shop_relic_pool(&"uncommon", mid_run)
	var late_rare_pool := ShopCatalog.get_normal_shop_relic_pool(&"rare", late_run)
	var epic_pool := ShopCatalog.get_normal_shop_relic_pool(&"epic", late_run)
	var special_ids := [
		DiceToolCatalog.TOOL_UNSTABLE_X3,
		DiceToolCatalog.TOOL_COMMON_TOOL_SUPPLY,
		DiceToolCatalog.TOOL_RIGHT_COPY_BLUEPRINT,
		DiceToolCatalog.TOOL_LEFT_COPY_BRAINSTORM,
	]
	var passed := true
	passed = passed and _pool_has_id(early_pool, DiceToolCatalog.TOOL_BASIC_MULT)
	passed = passed and not _pool_has_id(early_pool, DiceToolCatalog.TOOL_REROLL_PLUS_ONE)
	passed = passed and _pool_has_id(mid_uncommon_pool, DiceToolCatalog.TOOL_REROLL_PLUS_ONE)
	passed = passed and _pool_has_id(late_rare_pool, DiceToolCatalog.TOOL_SCORE_SLOT_PLUS_ONE)
	passed = passed and epic_pool.is_empty()
	for id in special_ids:
		passed = passed and not _pool_has_id(ShopCatalog.get_normal_shop_relic_pool(&"", late_run), id)

	var basic_pack_pool := DiceToolCatalog.get_weighted_pack_item_pool(BoosterPackCatalog.PACK_RELIC_BASIC)
	var large_pack_pool := DiceToolCatalog.get_weighted_pack_item_pool(BoosterPackCatalog.PACK_RELIC_LARGE)
	var mega_pack_pool := DiceToolCatalog.get_weighted_pack_item_pool(BoosterPackCatalog.PACK_RELIC_MEGA)
	passed = passed and _pool_has_id(basic_pack_pool, DiceToolCatalog.TOOL_BASIC_MULT)
	passed = passed and _pool_has_id(basic_pack_pool, DiceToolCatalog.TOOL_REROLL_PLUS_ONE)
	passed = passed and not _pool_has_id(basic_pack_pool, DiceToolCatalog.TOOL_SCORE_SLOT_PLUS_ONE)
	passed = passed and _pool_has_id(large_pack_pool, DiceToolCatalog.TOOL_SCORE_SLOT_PLUS_ONE)
	passed = passed and _pool_has_id(mega_pack_pool, DiceToolCatalog.TOOL_UNSTABLE_X3)
	passed = passed and not _pool_has_id(mega_pack_pool, DiceToolCatalog.TOOL_RIGHT_COPY_BLUEPRINT)
	return _check("dice tool shop and pack pools follow acquisition table", passed)


func _check_relic_sale_rules() -> bool:
	var run_state := _make_run(0)
	var service := ShopService.new()
	var tool_id := DiceToolCatalog.TOOL_REROLL_PLUS_ONE
	var item: ItemInstance = ItemInstance.create_dice_tool(
		tool_id,
		DiceToolCatalog.display_name_for_id(tool_id),
		ShopCatalog.sell_price_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
	)
	item.metadata["rarity"] = ShopCatalog.rarity_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
	run_state.install_dice_tool_item_instance(item)
	var result := service.sell_relic_by_index(run_state, 0)
	var expected_sell_price := ShopCatalog.sell_price_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
	var passed := (
		bool(result.get("success", false))
		and run_state.coins == expected_sell_price
		and run_state.dice_tools.is_empty()
		and run_state.get_free_dice_tool_slot_count() == run_state.dice_tool_capacity + run_state.contract_tool_slots
	)
	return _check("selling a relic grants floor(base price * 0.5) and frees a relic slot", passed)


func _check_pack_catalog() -> bool:
	var expected := [
		{"id": BoosterPackCatalog.PACK_FACE_BASIC, "name": "骰面改造包", "kind": BoosterPackDef.KIND_FACE, "price": 4, "candidates": 3, "choose": 1},
		{"id": BoosterPackCatalog.PACK_FACE_LARGE, "name": "大型骰面改造包", "kind": BoosterPackDef.KIND_FACE, "price": 6, "candidates": 5, "choose": 1},
		{"id": BoosterPackCatalog.PACK_FACE_MEGA, "name": "豪华骰面改造包", "kind": BoosterPackDef.KIND_FACE, "price": 8, "candidates": 5, "choose": 2},
		{"id": BoosterPackCatalog.PACK_COMBO_BASIC, "name": "主骰型包", "kind": BoosterPackDef.KIND_COMBO, "price": 4, "candidates": 3, "choose": 1},
		{"id": BoosterPackCatalog.PACK_COMBO_LARGE, "name": "大型主骰型包", "kind": BoosterPackDef.KIND_COMBO, "price": 6, "candidates": 5, "choose": 1},
		{"id": BoosterPackCatalog.PACK_COMBO_MEGA, "name": "豪华主骰型包", "kind": BoosterPackDef.KIND_COMBO, "price": 8, "candidates": 5, "choose": 2},
		{"id": BoosterPackCatalog.PACK_RELIC_BASIC, "name": "骰具包", "kind": BoosterPackDef.KIND_RELIC, "price": 4, "candidates": 2, "choose": 1},
		{"id": BoosterPackCatalog.PACK_RELIC_LARGE, "name": "大型骰具包", "kind": BoosterPackDef.KIND_RELIC, "price": 6, "candidates": 4, "choose": 1},
		{"id": BoosterPackCatalog.PACK_RELIC_MEGA, "name": "豪华骰具包", "kind": BoosterPackDef.KIND_RELIC, "price": 8, "candidates": 4, "choose": 2},
	]
	var defs := BoosterPackCatalog.get_all_defs()
	var passed := defs.size() == 9
	for spec in expected:
		var pack_id := StringName(str(spec.get("id", &"")))
		var def := BoosterPackCatalog.get_def(pack_id)
		passed = passed and def != null and def.is_formal()
		passed = passed and def.display_name == str(spec.get("name", ""))
		passed = passed and def.pack_kind == StringName(str(spec.get("kind", &"")))
		passed = passed and def.price_coins == int(spec.get("price", -1))
		passed = passed and def.candidate_count == int(spec.get("candidates", -1))
		passed = passed and def.choose_count == int(spec.get("choose", -1))
		passed = passed and def.shop_pool_reserved == &"TBD"
		passed = passed and def.drop_weight_reserved == &"TBD"
	var shop_ids := BoosterPackCatalog.get_pack_ids_for_shop(_make_run(20))
	passed = passed and shop_ids.size() == 9
	for pack_id in shop_ids:
		var def := BoosterPackCatalog.get_def(pack_id)
		passed = passed and def != null
		passed = passed and [BoosterPackDef.KIND_FACE, BoosterPackDef.KIND_COMBO, BoosterPackDef.KIND_RELIC].has(def.pack_kind)
	return _check("all 9 formal shop booster packs are face, combo, or relic packs", passed)


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
	service.rng.seed = 1831
	var generated := service.generate_candidate_offers(run_state, BoosterPackCatalog.PACK_RELIC_MEGA)
	var tool_data: Dictionary = DiceToolCatalog.get_item_pool_for_rarity()[0]
	var offer: BoosterOfferDef = BoosterOfferDef.create(
		&"relic_pack_item",
		str(tool_data.get("name", "")),
		&"relic",
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
		and run_state.item_slots.is_empty()
		and run_state.dice_tools.size() == 1
		and run_state.dice_tools[0].tool_id == StringName(str(tool_data.get("id", &"")))
	)
	for candidate in generated:
		var relic_offer := candidate as BoosterOfferDef
		if relic_offer == null:
			passed = false
			continue
		passed = passed and StringName(str(relic_offer.payload_data.get("rarity", &"common"))) != &"legendary"
	return _check("relic pack installs selected dice tool relic into relic slots and excludes legendary relics", passed)


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


func _check_mega_relic_pack_slot_requirement() -> bool:
	var run_state := _make_run(20)
	run_state.dice_tool_capacity = 1
	var service := ShopService.new()
	var offer := ShopCatalog.make_booster_offer(&"mega_relic_pack_offer", BoosterPackCatalog.PACK_RELIC_MEGA)
	var reason := service.get_offer_unavailable_reason(run_state, offer)
	var result := service.purchase_offer(run_state, offer)
	var passed := reason == "遗物槽位不足" and not bool(result.get("success", false))
	return _check("mega relic pack requires at least 2 empty relic slots before purchase", passed)


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


func _offers_have_payload_kind(offers: Array, payload_kind: StringName) -> bool:
	if offers.is_empty():
		return false
	for offer in offers:
		if not offer is ShopOfferDef:
			return false
		if (offer as ShopOfferDef).payload_kind != payload_kind:
			return false
	return true


func _same_id_set(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for item in left:
		if not right.has(item):
			return false
	return true


func _pool_has_id(pool: Array, id: StringName) -> bool:
	for data in pool:
		if data is Dictionary and StringName(str(data.get("id", &""))) == id:
			return true
	return false


func _make_pending_pack(offers: Array) -> Dictionary:
	var candidate_data := []
	for offer in offers:
		candidate_data.append((offer as BoosterOfferDef).to_dict())
	return {
		"pack_id": &"test_pack",
		"pack_name": "测试骰包",
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
