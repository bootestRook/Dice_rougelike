extends SceneTree
class_name DebugLongTermUnlockSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const BattleState = preload("res://scripts/core/battle/BattleState.gd")
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
	all_passed = _check_slot_and_shop_params() and all_passed
	all_passed = _check_battle_params() and all_passed
	all_passed = _check_economy_and_shop_purchase() and all_passed
	all_passed = _check_boss_hook() and all_passed
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
	var passed: bool = defs.size() == LongTermUnlockCatalog.get_all_ids().size()
	for def in defs:
		passed = passed and def != null
		passed = passed and def.is_formal()
		passed = passed and allowed_kinds.has(def.unlock_kind)
		passed = passed and def.shop_pool_reserved == &"TBD"
		passed = passed and def.drop_weight_reserved == &"TBD"
		passed = passed and def.price_coins >= 0
		passed = passed and def.display_name != ""
		passed = passed and def.description != ""
	return _check("long-term unlock catalog has formal parameter-only defs", passed)


func _check_duplicate_and_invalid_unlocks() -> bool:
	var run_state := _make_run(20)
	var service := LongTermUnlockService.new()
	var first := service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_ITEM_SLOT_PLUS_ONE)
	var duplicate := service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_ITEM_SLOT_PLUS_ONE)
	var invalid := service.apply_unlock(run_state, &"missing_unlock")
	var passed: bool = (
		bool(first.get("success", false))
		and not bool(duplicate.get("success", false))
		and str(duplicate.get("message", "")) == "该长期解锁已获得"
		and not bool(invalid.get("success", false))
		and run_state.item_slot_capacity == RunState.DEFAULT_ITEM_SLOT_CAPACITY + 1
	)
	return _check("long-term unlock service blocks duplicates and invalid ids", passed)


func _check_slot_and_shop_params() -> bool:
	var run_state := _make_run(50)
	var service := LongTermUnlockService.new()
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_ITEM_SLOT_PLUS_ONE)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_DICE_TOOL_SLOT_PLUS_ONE)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_SHOP_REROLL_DISCOUNT)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_SHOP_RANDOM_ITEM_SLOT_PLUS_ONE)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_SHOP_BOOSTER_SLOT_PLUS_ONE)

	var shop_service := ShopService.new()
	shop_service.rng.seed = 12001
	var shop_state := shop_service.generate_shop(run_state)
	var passed: bool = (
		run_state.item_slot_capacity == RunState.DEFAULT_ITEM_SLOT_CAPACITY + 1
		and run_state.dice_tool_capacity == RunState.DEFAULT_DICE_TOOL_CAPACITY + 1
		and run_state.shop_reroll_base_cost == 4
		and run_state.get_shop_reroll_cost() == 4
		and Array(shop_state.get("random_item_slots", [])).size() == 3
		and Array(shop_state.get("booster_slots", [])).size() == 3
	)
	return _check("slot and shop parameter unlocks apply without changing default rules", passed)


func _check_battle_params() -> bool:
	var run_state := _make_run(50)
	var service := LongTermUnlockService.new()
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_BATTLE_HAND_PLUS_ONE)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_BATTLE_REROLL_PLUS_ONE)
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_SCORE_SLOT_PLUS_ONE)

	var controller := BattleController.new()
	controller.start_battle(null, run_state)
	var config = controller.battle_state.config
	var passed: bool = (
		config.hands_per_battle == 5
		and config.rerolls_per_hand == 3
		and config.max_scored_faces_per_round == 6
		and config.max_selected_dice == 6
	)
	return _check("battle parameter unlocks modify future battle config only", passed)


func _check_economy_and_shop_purchase() -> bool:
	var run_state := _make_run(20)
	var shop_service := ShopService.new()
	var offer := ShopCatalog.make_long_term_unlock_offer(&"coin_unlock_offer", LongTermUnlockCatalog.UNLOCK_COIN_RESERVE)
	var result := shop_service.purchase_offer(run_state, offer)
	var duplicate_reason := shop_service.get_offer_unavailable_reason(run_state, offer)
	var passed: bool = (
		bool(result.get("success", false))
		and run_state.coins == 23
		and run_state.item_slots.is_empty()
		and run_state.has_long_term_unlock(LongTermUnlockCatalog.UNLOCK_COIN_RESERVE)
		and duplicate_reason == "该长期解锁已获得"
		and not run_state.shop_logs.is_empty()
	)
	return _check("shop purchase applies economy unlock immediately without item slots", passed)


func _check_boss_hook() -> bool:
	var run_state := _make_run(20)
	var service := LongTermUnlockService.new()
	service.apply_unlock(run_state, LongTermUnlockCatalog.UNLOCK_BOSS_RULE_GRACE)
	var battle_state := BattleState.new()
	battle_state.config.is_boss_battle = true
	var first := LongTermUnlockService.should_disable_boss_rules(run_state, battle_state)
	var second := LongTermUnlockService.should_disable_boss_rules(run_state, battle_state)
	var passed: bool = (
		first
		and not second
		and battle_state.boss_rule_disabled
		and battle_state.long_term_boss_rule_grace_used
	)
	return _check("boss hook disables the first boss rule read once per battle", passed)


func _check_no_face_or_level_side_effects() -> bool:
	var run_state := _make_run(50)
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
		"Vouch" + "er",
		"Tar" + "ot",
		"Plan" + "et",
		"Spect" + "ral",
		"幻" + "灵",
		"同" + "域",
		"消耗" + "槽",
		"M" + "VP",
		"扩" + "展",
		"后" + "期",
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
			if def.display_name.contains(word) or def.description.contains(word) or str(def.unlock_id).contains(word):
				passed = false
	return _check("removed legacy words do not appear in long-term unlock module", passed)


func _make_run(coins: int) -> RunState:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.coins = coins
	return run_state


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	return passed
