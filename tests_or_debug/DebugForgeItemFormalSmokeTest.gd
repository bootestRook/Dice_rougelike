extends SceneTree
class_name DebugForgeItemFormalSmokeTest


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ComboUpgradeItem = preload("res://scripts/rules/combo/ComboUpgradeItem.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const ForgeItemService = preload("res://scripts/rules/forge/ForgeItemService.gd")


func _init() -> void:
	print("--- DebugForgeItemFormalSmokeTest: start ---")

	var all_passed := true
	all_passed = _check_catalog() and all_passed
	all_passed = _check_legal_pips() and all_passed
	all_passed = _check_slot_install_rules() and all_passed
	all_passed = _check_generation_rules() and all_passed
	all_passed = _check_copy_and_economy_rules() and all_passed
	all_passed = _check_rare_and_tool_rules() and all_passed

	print("PASS: DebugForgeItemFormalSmokeTest" if all_passed else "FAIL: DebugForgeItemFormalSmokeTest")
	print("--- DebugForgeItemFormalSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_catalog() -> bool:
	var passed := true
	var defs := ForgeItemCatalog.get_all_defs()
	var ids: Array[StringName] = []
	var display_names := {}
	for def in defs:
		if def == null:
			passed = false
			continue
		ids.append(def.id)
		display_names[def.id] = def.display_name
		passed = passed and def.is_formal()
		passed = passed and def.drop_pool_id == &"reserved"
		passed = passed and is_equal_approx(def.drop_weight, -1.0)
	passed = passed and defs.size() == 21
	passed = passed and ids.size() == _unique_ids(ids).size()
	for id in ForgeItemCatalog.OFFICIAL_IDS:
		passed = passed and ids.has(id)
	passed = passed and display_names.get(ForgeItemCatalog.FORGE_ECHO_COPY, "") == "回响铸模"
	passed = passed and display_names.get(ForgeItemCatalog.FORGE_HIGH_REROLL, "") == "高点重铸片"
	passed = passed and _catalog_rarity_tiers_are_assigned()
	return _check("formal catalog has 21 forge items, reserved drops, and rarity tiers", passed)


func _catalog_rarity_tiers_are_assigned() -> bool:
	var expected := {
		ForgeItemCatalog.FORGE_CHIP_ORNAMENT: &"common",
		ForgeItemCatalog.FORGE_MULT_ORNAMENT: &"common",
		ForgeItemCatalog.FORGE_PIP_UP: &"common",
		ForgeItemCatalog.FORGE_EVEN_REROLL: &"common",
		ForgeItemCatalog.FORGE_ODD_REROLL: &"common",
		ForgeItemCatalog.FORGE_LOW_REROLL: &"common",
		ForgeItemCatalog.FORGE_HIGH_REROLL: &"uncommon",
		ForgeItemCatalog.FORGE_LUCKY_ORNAMENT: &"uncommon",
		ForgeItemCatalog.FORGE_STAY_ORNAMENT: &"uncommon",
		ForgeItemCatalog.FORGE_BURST_ORNAMENT: &"uncommon",
		ForgeItemCatalog.FORGE_GOLD_ORNAMENT: &"uncommon",
		ForgeItemCatalog.FORGE_STONE_ORNAMENT: &"uncommon",
		ForgeItemCatalog.FORGE_COIN_DOUBLER: &"uncommon",
		ForgeItemCatalog.FORGE_TOOL_VALUE_CASH: &"rare",
		ForgeItemCatalog.FORGE_WILD_ORNAMENT: &"rare",
		ForgeItemCatalog.FORGE_COMBO_UPGRADE_PACK: &"rare",
		ForgeItemCatalog.FORGE_RARE_ORNAMENT_ROLL: &"rare",
		ForgeItemCatalog.FORGE_ITEM_PACK: &"rare",
		ForgeItemCatalog.FORGE_TOOL_PACK: &"rare",
		ForgeItemCatalog.FORGE_FACE_COPY: &"epic",
		ForgeItemCatalog.FORGE_ECHO_COPY: &"epic",
	}
	for id in expected.keys():
		var def := ForgeItemCatalog.get_def(id)
		if def == null or def.rarity != expected[id]:
			return false
	return true


func _check_legal_pips() -> bool:
	var passed := (
		ForgeItemService.legal_pips(4) == [1, 2, 3, 4]
		and ForgeItemService.legal_even_pips(6) == [2, 4, 6]
		and ForgeItemService.legal_odd_pips(8) == [1, 3, 5, 7]
		and ForgeItemService.legal_low_pips(4) == [1, 2, 3, 4]
		and ForgeItemService.legal_high_pips(4).is_empty()
		and ForgeItemService.legal_high_pips(6) == [5, 6]
		and ForgeItemService.legal_high_pips(8) == [5, 6, 7, 8]
	)
	return _check("D4/D6/D8 legal pip pools are correct", passed)


func _check_slot_install_rules() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	var service := ForgeItemService.new()

	var face := run_state.dice[0].faces[0]
	face.pip = 4
	face.ornament_id = FaceState.ORN_CHIP
	face.mark_id = FaceState.MARK_RED
	var ornament_result := service.apply_forge_item(run_state, ForgeItemCatalog.FORGE_LUCKY_ORNAMENT, [_target(0, 0)])
	var ornament_passed := (
		bool(ornament_result.get("success", false))
		and face.pip == 4
		and face.ornament_id == FaceState.ORN_LUCKY
		and face.mark_id == FaceState.MARK_RED
	)

	var pip_face := run_state.dice[0].faces[5]
	pip_face.pip = 6
	pip_face.ornament_id = FaceState.ORN_MULT
	pip_face.mark_id = FaceState.MARK_BLUE
	var pip_result := service.apply_forge_item(run_state, ForgeItemCatalog.FORGE_PIP_UP, [_target(0, 5)])
	var pip_passed := (
		bool(pip_result.get("success", false))
		and pip_face.pip == 1
		and pip_face.ornament_id == FaceState.ORN_MULT
		and pip_face.mark_id == FaceState.MARK_BLUE
	)

	var source_face := run_state.dice[1].faces[1]
	source_face.pip = 3
	source_face.ornament_id = FaceState.ORN_STAY
	source_face.mark_id = FaceState.MARK_GOLD
	var target_face := run_state.dice[1].faces[0]
	target_face.pip = 6
	target_face.ornament_id = FaceState.ORN_BURST
	target_face.mark_id = FaceState.MARK_RED
	var copy_result := service.apply_forge_item(run_state, ForgeItemCatalog.FORGE_FACE_COPY, [_target(1, 0)], _target(1, 1))
	var copy_passed := (
		bool(copy_result.get("success", false))
		and target_face.pip == 3
		and target_face.ornament_id == FaceState.ORN_STAY
		and target_face.mark_id == FaceState.MARK_GOLD
	)

	run_state.dice[2] = _make_die(&"d4_test", 4)
	run_state.dice[2].faces[0].pip = 2
	var high_result := service.apply_forge_item(run_state, ForgeItemCatalog.FORGE_HIGH_REROLL, [_target(2, 0)])
	var high_passed := (
		not bool(high_result.get("success", false))
		and run_state.dice[2].faces[0].pip == 2
		and run_state.dice[2].face_count == 4
		and run_state.dice[2].faces.size() == 4
	)

	return _check("ornament, pip, face copy and D4 high-reroll boundaries are correct", ornament_passed and pip_passed and copy_passed and high_passed)


func _check_generation_rules() -> bool:
	var service := ForgeItemService.new()
	service.rng.seed = 12345

	var item_pack_run := RunState.new()
	item_pack_run.setup_new_run()
	item_pack_run.add_item_to_inventory_or_pending(ForgeItemCatalog.FORGE_ITEM_PACK)
	var item_pack_result := service.use_forge_item_from_slot(item_pack_run, 0)
	var item_pack_passed := (
		bool(item_pack_result.get("success", false))
		and item_pack_run.item_slots.size() == 2
		and Array(item_pack_result.get("generated_items", [])).size() == 2
	)
	for item in item_pack_run.item_slots:
		item_pack_passed = item_pack_passed and item.item_type == ItemInstance.TYPE_FORGE_ITEM
		item_pack_passed = item_pack_passed and item.item_id != ForgeItemCatalog.FORGE_ITEM_PACK
		item_pack_passed = item_pack_passed and item.item_id != ForgeItemCatalog.FORGE_ECHO_COPY

	var limited_run := RunState.new()
	limited_run.setup_new_run()
	limited_run.item_slot_capacity = 1
	limited_run.add_item_to_inventory_or_pending(ForgeItemCatalog.FORGE_ITEM_PACK)
	var limited_result := service.use_forge_item_from_slot(limited_run, 0)
	var limited_passed := (
		bool(limited_result.get("success", false))
		and limited_run.item_slots.size() == 1
		and Array(limited_result.get("generated_items", [])).size() == 1
	)

	var combo_pack_run := RunState.new()
	combo_pack_run.setup_new_run()
	combo_pack_run.add_item_to_inventory_or_pending(ForgeItemCatalog.FORGE_COMBO_UPGRADE_PACK)
	var combo_result := service.use_forge_item_from_slot(combo_pack_run, 0)
	var combo_passed := (
		bool(combo_result.get("success", false))
		and combo_pack_run.item_slots.size() == 2
	)
	for item in combo_pack_run.item_slots:
		combo_passed = combo_passed and item.item_type == ItemInstance.TYPE_COMBO_UPGRADE
		combo_passed = combo_passed and ComboUpgradeItem.from_item_id(item.item_id) != null

	return _check("generated forge items and combo upgrades enter item_slots with slot limits", item_pack_passed and limited_passed and combo_passed)


func _check_copy_and_economy_rules() -> bool:
	var service := ForgeItemService.new()

	var echo_run := RunState.new()
	echo_run.setup_new_run()
	echo_run.last_copyable_used_item_id = &"upgrade_combo_pair"
	echo_run.add_item_to_inventory_or_pending(ForgeItemCatalog.FORGE_ECHO_COPY)
	var echo_result := service.use_forge_item_from_slot(echo_run, 0)
	var echo_passed := (
		bool(echo_result.get("success", false))
		and echo_run.item_slots.size() == 1
		and echo_run.item_slots[0].item_id == &"upgrade_combo_pair"
		and echo_run.get_combo_level(&"pair") == 1
		and echo_run.last_copyable_used_item_id == &"upgrade_combo_pair"
	)

	var upgrade_run := RunState.new()
	upgrade_run.setup_new_run()
	upgrade_run.add_item_to_inventory_or_pending(&"upgrade_combo_full_house")
	var upgrade_passed := (
		upgrade_run.use_item(&"upgrade_combo_full_house")
		and upgrade_run.get_combo_level(&"full_house") == 2
		and upgrade_run.item_slots.is_empty()
		and upgrade_run.last_copyable_used_item_id == &"upgrade_combo_full_house"
	)

	var coin_run := RunState.new()
	coin_run.setup_new_run()
	coin_run.coins = 15
	var coin_result := service.apply_forge_item(coin_run, ForgeItemCatalog.FORGE_COIN_DOUBLER)
	var coin_passed := (
		bool(coin_result.get("success", false))
		and int(coin_result.get("coins_delta", 0)) == 15
		and coin_run.coins == 30
	)

	var tool_cash_run := RunState.new()
	tool_cash_run.setup_new_run()
	tool_cash_run.dice_tools.append(DiceToolState.create(&"tool_a", "A", 30))
	tool_cash_run.dice_tools.append(DiceToolState.create(&"tool_b", "B", 40))
	var cash_result := service.apply_forge_item(tool_cash_run, ForgeItemCatalog.FORGE_TOOL_VALUE_CASH)
	var cash_passed := (
		bool(cash_result.get("success", false))
		and int(cash_result.get("coins_delta", 0)) == 50
		and tool_cash_run.coins == 50
		and tool_cash_run.dice_tools.size() == 2
	)

	return _check("echo, combo item use, coin doubler and tool valuation work", echo_passed and upgrade_passed and coin_passed and cash_passed)


func _check_rare_and_tool_rules() -> bool:
	var service := ForgeItemService.new()
	service.rng.seed = _first_rare_success_seed()

	var rare_run := RunState.new()
	rare_run.setup_new_run()
	rare_run.dice[0].faces[0].ornament_id = FaceState.ORN_CHIP
	var rare_result := service.apply_forge_item(rare_run, ForgeItemCatalog.FORGE_RARE_ORNAMENT_ROLL, [_target(0, 0)])
	var rare_ornament: StringName = rare_run.dice[0].faces[0].ornament_id
	var rare_passed := (
		bool(rare_result.get("success", false))
		and ForgeItemCatalog.RARE_ORNAMENT_IDS.has(rare_ornament)
		and rare_run.dice[0].faces[0].pip == 1
		and rare_run.dice[0].faces[0].mark_id == FaceState.MARK_NONE
	)

	var tool_run := RunState.new()
	tool_run.setup_new_run()
	tool_run.add_item_to_inventory_or_pending(ForgeItemCatalog.FORGE_TOOL_PACK)
	var tool_result := service.use_forge_item_from_slot(tool_run, 0)
	var generated_is_tool := tool_run.item_slots.size() == 1 and tool_run.item_slots[0].item_type == ItemInstance.TYPE_DICE_TOOL
	var installed := tool_run.install_dice_tool_item_from_slot(0)
	var tool_passed := (
		bool(tool_result.get("success", false))
		and generated_is_tool
		and installed
		and tool_run.item_slots.is_empty()
		and tool_run.dice_tools.size() == 1
	)

	return _check("rare ornament roll and dice tool pack follow item slot rules", rare_passed and tool_passed)


func _first_rare_success_seed() -> int:
	for seed_value in range(1, 1000):
		var test_rng := RandomNumberGenerator.new()
		test_rng.seed = seed_value
		if test_rng.randf() < 0.25:
			return seed_value
	return 1


func _make_die(id: StringName, face_count: int) -> DieState:
	var die := DieState.new()
	die.id = id
	die.face_count = face_count
	die.body_id = &"standard"
	for pip in range(1, face_count + 1):
		die.faces.append(FaceState.new(pip))
		die.face_weights.append(1)
	return die


func _target(die_index: int, face_index: int) -> Dictionary:
	return {
		"die_index": die_index,
		"face_index": face_index,
	}


func _unique_ids(ids: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for id in ids:
		if not result.has(id):
			result.append(id)
	return result


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
