extends SceneTree
class_name DebugLongTermUnlockSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const BoosterPackCatalog = preload("res://scripts/rules/shop/BoosterPackCatalog.gd")
const BoosterPackDef = preload("res://scripts/data_defs/BoosterPackDef.gd")
const BoosterPackService = preload("res://scripts/rules/shop/BoosterPackService.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const LongTermUnlockCatalog = preload("res://scripts/rules/long_term/LongTermUnlockCatalog.gd")
const LongTermUnlockDef = preload("res://scripts/data_defs/LongTermUnlockDef.gd")
const LongTermUnlockService = preload("res://scripts/rules/long_term/LongTermUnlockService.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ShopCatalog = preload("res://scripts/rules/shop/ShopCatalog.gd")
const ShopOfferDef = preload("res://scripts/data_defs/ShopOfferDef.gd")
const ShopService = preload("res://scripts/rules/shop/ShopService.gd")


func _init() -> void:
	print("--- DebugLongTermUnlockSmokeTest: start ---")

	var all_passed := true
	all_passed = _check_catalog_defs() and all_passed
	all_passed = _check_duplicate_and_invalid_unlocks() and all_passed
	all_passed = _check_slot_shop_and_discount_params() and all_passed
	all_passed = _check_pack_params() and all_passed
	all_passed = _check_contract_tool_slot() and all_passed
	all_passed = _check_battle_params_and_score_hooks() and all_passed
	all_passed = _check_economy_unlocks() and all_passed
	all_passed = _check_danger_and_boss_params() and all_passed
	all_passed = _check_no_face_or_level_side_effects() and all_passed
	all_passed = _check_removed_words_absent() and all_passed

	print("PASS: DebugLongTermUnlockSmokeTest" if all_passed else "FAIL: DebugLongTermUnlockSmokeTest")
	print("--- DebugLongTermUnlockSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_catalog_defs() -> bool:
	var defs := LongTermUnlockCatalog.get_all_defs()
	var allowed_kinds := [
		LongTermUnlockDef.KIND_GLOBAL_RULE,
		LongTermUnlockDef.KIND_SHOP_PARAM,
		LongTermUnlockDef.KIND_SLOT_PARAM,
		LongTermUnlockDef.KIND_ECONOMY_PARAM,
		LongTermUnlockDef.KIND_BOSS_HOOK,
	]
	var passed: bool = (
		defs.size() == 29
		and defs.size() == LongTermUnlockCatalog.get_all_ids().size()
		and LongTermUnlockCatalog.has_unlock(LongTermUnlockCatalog.UNLOCK_BATTLE_REWARD_EXTRA_CHOICE)
		and LongTermUnlockCatalog.get_shop_pool_ids().size() == 29
		and LongTermUnlockCatalog.get_shop_pool_ids().has(LongTermUnlockCatalog.UNLOCK_COMBO_UPGRADE_SHOP_WEIGHT_X2)
		and LongTermUnlockCatalog.get_shop_pool_ids().has(LongTermUnlockCatalog.UNLOCK_BASIC_FACE_SHOP_ITEMS)
		and LongTermUnlockCatalog.get_shop_pool_ids().has(LongTermUnlockCatalog.UNLOCK_ADVANCED_FACE_DISPLAY)
	)
	for def in defs:
		passed = passed and def != null
		passed = passed and def.is_formal()
		passed = passed and allowed_kinds.has(def.unlock_kind)
		passed = passed and def.shop_pool_reserved == &"TBD"
		passed = passed and def.drop_weight_reserved == &"TBD"
		passed = passed and def.price_coins >= 0
		passed = passed and def.display_name != ""
		passed = passed and def.description != ""
	return _check("long-term unlock catalog matches the 29 retained shop unlocks", passed)


func _check_duplicate_and_invalid_unlocks() -> bool:
	var run_state := _make_run(20)
	var service := LongTermUnlockService.new()
	var first := service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_ITEM_SLOT_PLUS_1)
	var duplicate := service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_ITEM_SLOT_PLUS_1)
	var invalid := service.apply_unlock(run_state, &"missing_unlock")
	var passed: bool = (
		bool(first.get("success", false))
		and not bool(duplicate.get("success", false))
		and str(duplicate.get("message", "")) == "该长期解锁已获得"
		and not bool(invalid.get("success", false))
		and run_state.item_slot_capacity == RunState.DEFAULT_ITEM_SLOT_CAPACITY + 1
	)
	return _check("long-term unlock service blocks duplicates and invalid ids", passed)


func _check_slot_shop_and_discount_params() -> bool:
	var run_state := _make_run(80)
	var service := LongTermUnlockService.new()
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_ITEM_SLOT_PLUS_1)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_TOOL_SLOT_PLUS_1)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_SHOP_REROLL_DISCOUNT_2)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_SHOP_RANDOM_SLOT_PLUS_1)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_SHOP_PACK_SLOT_PLUS_1)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_SHOP_FIRST_REROLL_FREE)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_RANDOM_ITEM_DISCOUNT_25)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_FIRST_PURCHASE_HALF_PRICE)

	var shop_service := ShopService.new()
	shop_service.rng.seed = 12001
	var shop_state := shop_service.generate_shop(run_state)
	var weights := ShopCatalog.get_random_item_kind_weights(run_state)
	var tool_base_price := ShopCatalog.base_price_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, DiceToolCatalog.TOOL_REROLL_PLUS_ONE)
	var tool_offer := ShopCatalog.make_random_item_offer(&"discount_check", ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, DiceToolCatalog.TOOL_REROLL_PLUS_ONE, "折扣检查", tool_base_price, "遗物货架")
	var price_data := shop_service.get_offer_view_data(run_state, tool_offer)
	var passed: bool = (
		run_state.item_slot_capacity == RunState.DEFAULT_ITEM_SLOT_CAPACITY + 1
		and run_state.dice_tool_capacity == RunState.DEFAULT_DICE_TOOL_CAPACITY + 1
		and run_state.shop_reroll_base_cost == 3
		and int(shop_state.get("reroll_cost", -1)) == 0
		and int(shop_state.get("free_rerolls", 0)) >= 1
		and Array(shop_state.get("relic_shelf_slots", [])).size() == 3
		and Array(shop_state.get("booster_slots", [])).size() == 3
		and not shop_state.has("random_item_slots")
		and not shop_state.has("merchant_service_slot")
		and not shop_state.has("advanced_face_display_slots")
		and _weight_for(weights, ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM) == ShopCatalog.RANDOM_ITEM_WEIGHT_DICE_TOOL
		and _weight_for(weights, ShopOfferDef.PAYLOAD_FORGE_ITEM) == 0
		and _weight_for(weights, ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM) == 0
		and _weight_for(weights, ShopOfferDef.PAYLOAD_FACE_SHOP_ITEM) == 0
		and int(price_data.get("price", -1)) == 3
	)
	return _check("slot, shop, weight, and discount unlocks apply immediately", passed)


func _check_pack_params() -> bool:
	var run_state := _make_run(80)
	var service := LongTermUnlockService.new()
	var pack_service := BoosterPackService.new()
	pack_service.rng.seed = 22003

	var before_ids := BoosterPackCatalog.get_pack_ids_for_shop(run_state)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_FACE_PACK_EXTRA_CANDIDATE)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_COMBO_UPGRADE_SHOP_UPGRADE)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_COMBO_UPGRADE_SHOP_WEIGHT_X2)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_BASIC_FACE_SHOP_ITEMS)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_ADVANCED_FACE_DISPLAY)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_COMBO_PACK_PREFERRED_UPGRADE)
	run_state.combo_scored_counts[&"combo_pair"] = 4

	var after_ids := BoosterPackCatalog.get_pack_ids_for_shop(run_state)
	var face_offers := pack_service.generate_candidate_offers(run_state, BoosterPackCatalog.PACK_FACE_BASIC)
	var combo_offers := pack_service.generate_candidate_offers(run_state, BoosterPackCatalog.PACK_COMBO_BASIC)
	var combo_pack_weight := BoosterPackCatalog.shop_weight_for_pack_id(BoosterPackCatalog.PACK_COMBO_BASIC, run_state)
	var face_pack_weight := BoosterPackCatalog.shop_weight_for_pack_id(BoosterPackCatalog.PACK_FACE_BASIC, run_state)
	var combo_has_preferred := false
	for offer in combo_offers:
		if offer != null and offer.payload_id == &"combo_pair":
			combo_has_preferred = true
	var before_has_foundry := _pack_pool_has_kind(before_ids, BoosterPackDef.KIND_FOUNDRY)
	var after_has_foundry := _pack_pool_has_kind(after_ids, BoosterPackDef.KIND_FOUNDRY)
	var before_has_forge := _pack_pool_has_kind(before_ids, BoosterPackDef.KIND_FORGE)
	var after_has_forge := _pack_pool_has_kind(after_ids, BoosterPackDef.KIND_FORGE)
	var passed := (
		not before_has_foundry
		and not after_has_foundry
		and not before_has_forge
		and not after_has_forge
		and face_offers.size() == 4
		and combo_offers.size() == 4
		and combo_pack_weight == 2
		and face_pack_weight == 2
		and combo_has_preferred
		and run_state.combo_pack_extra_candidates == 1
		and bool(run_state.advanced_face_pack_rewards_enabled)
	)
	return _check("pack unlocks keep shop packs to face, combo, relic packs and update weights/candidates", passed)


func _check_contract_tool_slot() -> bool:
	var run_state := _make_run(80)
	run_state.dice_tool_capacity = 0
	var service := LongTermUnlockService.new()
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_CONTRACT_TOOL_SLOT)

	run_state.add_item_to_inventory_or_pending(DiceToolCatalog.TOOL_REROLL_PLUS_ONE, ItemInstance.TYPE_DICE_TOOL)
	var common_installed := run_state.install_dice_tool_item_from_slot(0)
	run_state.add_item_to_inventory_or_pending(DiceToolCatalog.TOOL_FIRST_REROLL_COMBO_UPGRADE, ItemInstance.TYPE_DICE_TOOL)
	var rare_installed := run_state.install_dice_tool_item_from_slot(0)
	var installed_tool = run_state.dice_tools[0] if not run_state.dice_tools.is_empty() else null
	var passed := (
		run_state.contract_tool_slots == 1
		and common_installed
		and not rare_installed
		and installed_tool != null
		and StringName(str(installed_tool.metadata.get("slot_type", &""))) == &"contract"
	)
	return _check("contract tool slot accepts common or uncommon tools and rejects rare tools", passed)


func _check_battle_params_and_score_hooks() -> bool:
	var run_state := _make_run(80)
	var service := LongTermUnlockService.new()
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_SCORING_ROUND_PLUS_1)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_REROLL_PER_ROUND_PLUS_1)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_MAX_SCORED_FACES_PLUS_1)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_OBSERVATORY_COMBO_BONUS)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_FIRST_SCORE_ECHO)
	run_state.combo_scored_counts[&"combo_scatter"] = 5

	var controller := BattleController.new()
	controller.start_battle(null, run_state)
	var config = controller.battle_state.config
	controller.toggle_select(0)
	var trace = controller.request_settle_selected()
	var base_score: int = int(trace.hand_score_final) if trace != null else 0
	controller.commit_pending_resolution()
	var passed: bool = (
		config.hands_per_battle == 5
		and config.rerolls_per_hand == 3
		and config.max_scored_faces_per_round == 6
		and config.max_selected_dice == 6
		and base_score > 0
		and controller.get_total_score() > base_score
		and run_state.observatory_used_this_battle
		and run_state.first_score_echo_used_this_battle
	)
	return _check("battle parameter and score-hook unlocks modify controller-owned scoring", passed)


func _check_economy_unlocks() -> bool:
	var run_state := _make_run(25)
	var service := LongTermUnlockService.new()
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_INTEREST_CAP_8)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_FLAT_GOLD_AFTER_BATTLE)

	var flow := GameFlowController.new()
	flow.run_state = run_state
	flow.on_battle_won()

	var shop_run := _make_run(20)
	var shop_service := ShopService.new()
	var offer := ShopCatalog.make_long_term_unlock_offer(&"slot_unlock_offer", LongTermUnlockCatalog.UNLOCK_ITEM_SLOT_PLUS_1)
	var result := shop_service.purchase_offer(shop_run, offer)
	var duplicate_reason := shop_service.get_offer_unavailable_reason(shop_run, offer)
	var reward_run := _make_run(20)
	service.apply_unlock(reward_run, LongTermUnlockCatalog.UNLOCK_BATTLE_REWARD_EXTRA_CHOICE)
	var reward_flow := GameFlowController.new()
	reward_flow.run_state = reward_run
	reward_flow.on_battle_won()
	var passed: bool = (
		run_state.coins == 34
		and bool(result.get("success", false))
		and shop_run.coins == 8
		and shop_run.item_slots.is_empty()
		and shop_run.has_long_term_unlock(LongTermUnlockCatalog.UNLOCK_ITEM_SLOT_PLUS_1)
		and duplicate_reason == "该长期解锁已获得"
		and not shop_run.shop_logs.is_empty()
		and reward_run.last_reward_choices.size() == 4
	)
	return _check("economy and reward-choice unlocks apply after battle", passed)


func _check_danger_and_boss_params() -> bool:
	var run_state := _make_run(80)
	run_state.current_circle_action_count = 2
	var service := LongTermUnlockService.new()
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_EARLY_BATTLE_DANGER_REDUCE)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_BOSS_DANGER_REDUCE)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_BOSS_RULE_FREE_REROLL)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_BOSS_RULE_CHOICE)
	var battle_danger := run_state.get_danger_bonus_percent_for_node(&"battle")
	var boss_target_with_reduce := run_state.get_target_score(&"boss")
	var boss_target_without_reduce := int(round(float(run_state.get_current_circle_base_score()) * 2.0 * run_state.get_danger_multiplier()))
	var passed := (
		battle_danger == 0
		and boss_target_with_reduce < boss_target_without_reduce
		and run_state.free_boss_rule_reroll_per_loop == 1
		and run_state.boss_rule_choice_count == 2
	)
	return _check("danger and boss-rule unlock parameters are stored and used by target scoring", passed)


func _check_no_face_or_level_side_effects() -> bool:
	var run_state := _make_run(200)
	var before_face_count := run_state.get_total_face_count()
	var before_combo_levels := run_state.combo_levels.duplicate(true)
	var service := LongTermUnlockService.new()
	for unlock_id in LongTermUnlockCatalog.get_all_ids():
		service.apply_unlock(run_state, unlock_id)
	var after_face_count := run_state.get_total_face_count()
	var passed: bool = (
		after_face_count == before_face_count
		and run_state.combo_levels == before_combo_levels
	)
	for die in run_state.dice:
		passed = passed and die.face_count == die.faces.size()
		for face in die.faces:
			passed = passed and face != null
			passed = passed and face.get("pip") != null
			passed = passed and face.get("ornament_id") != null
			passed = passed and face.get("mark_id") != null
	return _check("long-term unlocks do not add face slots or level systems", passed)


func _check_removed_words_absent() -> bool:
	var blocked := [
		"补" + "充包",
		"Vouch" + "er",
		"Tar" + "ot",
		"Plan" + "et",
		"Spect" + "ral",
		"M" + "VP",
	]
	var paths := [
		"res://scripts/data_defs/LongTermUnlockDef.gd",
		"res://scripts/rules/long_term/LongTermUnlockCatalog.gd",
		"res://scripts/rules/long_term/LongTermUnlockService.gd",
		"res://tests_or_debug/DebugLongTermUnlockSmokeTest.gd",
	]
	var passed: bool = true
	for path in paths:
		var text := FileAccess.get_file_as_string(path)
		for word in blocked:
			if text.contains(word):
				passed = false
	for def in LongTermUnlockCatalog.get_all_defs():
		for word in blocked:
			if def.display_name.contains(word) or def.description.contains(word):
				passed = false
	return _check("removed legacy shop words do not appear in long-term unlock module", passed)


func _make_run(coins: int) -> RunState:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.coins = coins
	return run_state


func _weight_for(weights: Array, payload_kind: StringName) -> int:
	for entry in weights:
		if StringName(str(entry.get("payload_kind", &""))) == payload_kind:
			return int(entry.get("weight", 0))
	return 0


func _pack_pool_has_kind(ids: Array, pack_kind: StringName) -> bool:
	for id in ids:
		var def := BoosterPackCatalog.get_def(StringName(str(id)))
		if def != null and def.pack_kind == pack_kind:
			return true
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	return passed
