extends SceneTree
class_name DebugFoundryServicesSmokeTest


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const FoundryService = preload("res://scripts/rules/forge/FoundryService.gd")
const FoundryServiceCatalog = preload("res://scripts/rules/forge/FoundryServiceCatalog.gd")
const FoundryServiceMigration = preload("res://scripts/rules/forge/FoundryServiceMigration.gd")


func _init() -> void:
	print("--- DebugFoundryServicesSmokeTest: start ---")

	var all_passed := true
	all_passed = _check_catalog_no_legacy() and all_passed
	all_passed = _check_reward_generator_foundry_choices() and all_passed
	all_passed = _check_no_face_add_or_delete() and all_passed
	all_passed = _check_d4_high_and_six_unavailable() and all_passed
	all_passed = _check_d6_six_reforge_candidates() and all_passed
	all_passed = _check_same_pip_sync_clears_slots() and all_passed
	all_passed = _check_negative_tool_slot() and all_passed
	all_passed = _check_burn_for_coins() and all_passed
	all_passed = _check_face_double_copy_legality() and all_passed
	all_passed = _check_all_combo_upgrade_only_main_combos() and all_passed
	all_passed = _check_item_slot_shortage() and all_passed
	all_passed = _check_tool_clone_purge_copy_rules() and all_passed

	print("PASS: DebugFoundryServicesSmokeTest" if all_passed else "FAIL: DebugFoundryServicesSmokeTest")
	print("--- DebugFoundryServicesSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_catalog_no_legacy() -> bool:
	var defs := FoundryServiceCatalog.get_all_defs()
	var ids: Array[StringName] = []
	var removed_segment := "do" + "main"
	var passed := defs.size() == 17
	for def in defs:
		if def == null:
			passed = false
			continue
		ids.append(def.service_id)
		passed = passed and def.implementation_status == &"formal"
		passed = passed and def.drop_pool == &"TBD"
		passed = passed and is_equal_approx(def.drop_weight, -1.0)
		passed = passed and not str(def.service_id).begins_with("sp_")
		passed = passed and not str(def.service_id).contains(removed_segment)
	passed = passed and ids.size() == _unique_ids(ids).size()
	passed = passed and not ids.has(&"sp_sigil")
	passed = passed and not ids.has(StringName("foundry_%s_randomize" % [removed_segment]))
	passed = passed and FoundryServiceMigration.migrate_legacy_service_id(&"sp_sigil") == &""
	return _check("formal foundry catalog excludes removed legacy services", passed)


func _check_reward_generator_foundry_choices() -> bool:
	var generator := RewardGenerator.new()
	generator.rng.seed = 808
	var choices := generator.generate_foundry_service_choices(4)
	var ids: Array[StringName] = []
	var passed := choices.size() == 4
	for choice in choices:
		passed = passed and choice != null
		passed = passed and choice.is_formal()
		passed = passed and FoundryServiceCatalog.has_service(choice.service_id)
		ids.append(choice.service_id)
	passed = passed and ids.size() == _unique_ids(ids).size()
	return _check("reward generator can draw unique formal foundry service choices", passed)


func _check_no_face_add_or_delete() -> bool:
	var services := [
		FoundryServiceCatalog.FOUNDRY_HIGH_PIP_REFORGE,
		FoundryServiceCatalog.FOUNDRY_SIX_PIP_REFORGE,
		FoundryServiceCatalog.FOUNDRY_RANDOM_PIP_REFORGE,
		FoundryServiceCatalog.FOUNDRY_GOLD_MARK,
		FoundryServiceCatalog.FOUNDRY_RARE_ORNAMENT,
		FoundryServiceCatalog.FOUNDRY_RARE_TOOL_PACK,
		FoundryServiceCatalog.FOUNDRY_SAME_PIP_SYNC,
		FoundryServiceCatalog.FOUNDRY_NEGATIVE_TOOL_SLOT,
		FoundryServiceCatalog.FOUNDRY_BURN_FOR_COINS,
		FoundryServiceCatalog.FOUNDRY_TOOL_CLONE_PURGE,
		FoundryServiceCatalog.FOUNDRY_RED_MARK,
		FoundryServiceCatalog.FOUNDRY_POLY_GAMBLE,
		FoundryServiceCatalog.FOUNDRY_BLUE_MARK,
		FoundryServiceCatalog.FOUNDRY_PURPLE_MARK,
		FoundryServiceCatalog.FOUNDRY_FACE_DOUBLE_COPY,
		FoundryServiceCatalog.FOUNDRY_LEGENDARY_TOOL_PACK,
		FoundryServiceCatalog.FOUNDRY_ALL_COMBO_UPGRADE,
	]
	var passed := true
	for service_id in services:
		var run_state := _make_foundry_run()
		var service := FoundryService.new()
		service.rng.seed = 101
		_apply_representative_service(service, run_state, service_id)
		passed = passed and _all_dice_face_counts_match(run_state)
	return _check("foundry services never add or delete faces", passed)


func _check_d4_high_and_six_unavailable() -> bool:
	var run_state := _make_foundry_run()
	run_state.dice[0] = _make_die(&"d4", 4)
	var service := FoundryService.new()
	var passed := (
		not service.can_apply_to_die(run_state, FoundryServiceCatalog.FOUNDRY_HIGH_PIP_REFORGE, 0)
		and not service.can_apply_to_die(run_state, FoundryServiceCatalog.FOUNDRY_SIX_PIP_REFORGE, 0)
	)
	return _check("D4 cannot use high-pip or six-pip reforge", passed)


func _check_d6_six_reforge_candidates() -> bool:
	var run_state := _make_foundry_run()
	var service := FoundryService.new()
	service.rng.seed = 202
	var pending := service.create_reforge_resolution(run_state, FoundryServiceCatalog.FOUNDRY_SIX_PIP_REFORGE, _die_target(0))
	var candidates: Array = pending.get("candidates", [])
	var passed := bool(pending.get("success", false)) and candidates.size() == 2
	for candidate in candidates:
		var face := candidate as FaceState
		passed = passed and face != null
		passed = passed and face.pip == 6
		passed = passed and face.mark_id == FaceState.MARK_NONE
		passed = passed and FoundryService.get_ordinary_ornament_pool().has(face.ornament_id)
	return _check("D6 six-pip reforge creates two legal six candidates", passed)


func _check_same_pip_sync_clears_slots() -> bool:
	var run_state := _make_foundry_run()
	for target in [_face_target(0, 0), _face_target(1, 1), _face_target(2, 2)]:
		var face := run_state.dice[int(target["die_index"])].faces[int(target["face_index"])]
		face.ornament_id = FaceState.ORN_POLY
		face.mark_id = FaceState.MARK_GOLD
	var service := FoundryService.new()
	service.rng.seed = 303
	var targets := [_face_target(0, 0), _face_target(1, 1), _face_target(2, 2)]
	var result := service.apply_same_pip_sync(run_state, targets)
	var pip := run_state.dice[0].faces[0].pip
	var passed := bool(result.get("success", false))
	for target in targets:
		var face := run_state.dice[int(target["die_index"])].faces[int(target["face_index"])]
		passed = passed and face.pip == pip
		passed = passed and face.ornament_id == FaceState.ORN_NONE
		passed = passed and face.mark_id == FaceState.MARK_NONE
	return _check("same-pip sync equalizes pips and clears ornament/mark", passed)


func _check_negative_tool_slot() -> bool:
	var run_state := _make_foundry_run()
	run_state.coins = 17
	run_state.dice_tools.append(DiceToolState.create(&"tool_a", "A", 10))
	run_state.dice_tools.append(DiceToolState.create(&"tool_b", "B", 10))
	run_state.installed_tools = run_state.dice_tools
	var before_dice := _dice_signature(run_state)
	var service := FoundryService.new()
	service.rng.seed = 404
	var result := service.apply_negative_tool_slot(run_state)
	var negative_count := 0
	for tool in run_state.dice_tools:
		if tool.is_negative:
			negative_count += 1
	var passed := (
		bool(result.get("success", false))
		and negative_count == 1
		and run_state.coins == 0
		and _dice_signature(run_state) == before_dice
	)
	return _check("negative tool slot marks one tool, zeros coins, and leaves dice unchanged", passed)


func _check_burn_for_coins() -> bool:
	var run_state := _make_foundry_run()
	run_state.coins = 5
	for die in run_state.dice:
		for face in die.faces:
			face.ornament_id = FaceState.ORN_CHIP
			face.mark_id = FaceState.MARK_RED
	var service := FoundryService.new()
	service.rng.seed = 505
	var result := service.apply_burn_for_coins(run_state)
	var changed: Array = result.get("changed_faces", [])
	var passed := (
		bool(result.get("success", false))
		and changed.size() == 5
		and _changed_faces_are_distinct(changed)
		and run_state.coins == 25
		and _all_dice_face_counts_match(run_state)
	)
	for ref in changed:
		var face := run_state.dice[int(ref["die_index"])].faces[int(ref["face_index"])]
		passed = passed and face.ornament_id == FaceState.ORN_NONE
		passed = passed and face.mark_id == FaceState.MARK_NONE
	return _check("burn for coins resets exactly five distinct faces and grants 20 coins", passed)


func _check_face_double_copy_legality() -> bool:
	var run_state := _make_foundry_run()
	run_state.dice[0] = _make_die(&"d8_source", 8)
	run_state.dice[1] = _make_die(&"d4_target", 4)
	run_state.dice[2] = _make_die(&"d6_target", 6)
	run_state.dice[3] = _make_die(&"d8_target", 8)
	run_state.dice[0].faces[7].pip = 8
	var service := FoundryService.new()
	var source := _face_target(0, 7)
	var passed := (
		not service.can_copy_face_to_target(run_state, source, _face_target(1, 0))
		and not service.can_copy_face_to_target(run_state, source, _face_target(2, 0))
		and service.can_copy_face_to_target(run_state, source, _face_target(3, 0))
	)
	run_state.dice[0].faces[7].ornament_id = FaceState.ORN_HOLO
	run_state.dice[0].faces[7].mark_id = FaceState.MARK_BLUE
	var result := service.apply_face_double_copy(run_state, source, [_face_target(3, 0), _face_target(3, 1)])
	passed = passed and bool(result.get("success", false))
	passed = passed and run_state.dice[3].faces[0].pip == 8
	passed = passed and run_state.dice[3].faces[0].ornament_id == FaceState.ORN_HOLO
	passed = passed and run_state.dice[3].faces[0].mark_id == FaceState.MARK_BLUE
	return _check("face double copy rejects illegal D4/D6 targets for pip 8", passed)


func _check_all_combo_upgrade_only_main_combos() -> bool:
	var run_state := _make_foundry_run()
	run_state.combo_levels = {
		&"combo_scatter": 1,
		&"combo_pair": 2,
		&"all_odd": 9,
		&"contains_six": 7,
	}
	var service := FoundryService.new()
	var result := service.apply_all_combo_upgrade(run_state)
	var passed := bool(result.get("success", false))
	for combo_id in FoundryService.MAIN_COMBO_IDS:
		passed = passed and run_state.combo_levels.has(combo_id)
		var expected := 3 if combo_id == &"combo_pair" else 2
		passed = passed and int(run_state.combo_levels[combo_id]) == expected
	for forbidden in [&"all_odd", &"all_even", &"all_low", &"all_high", &"low_total", &"high_total", &"contains_six", &"many_sixes", &"few_scored", &"rerolled", &"first_roll", &"last_hand", &"unscored_stay"]:
		passed = passed and not run_state.combo_levels.has(forbidden)
	return _check("all combo upgrade only changes the eight main combo levels", passed)


func _check_item_slot_shortage() -> bool:
	var run_state := _make_foundry_run()
	run_state.item_slot_capacity = 1
	run_state.add_item_to_inventory_or_pending(&"filled")
	var service := FoundryService.new()
	var passed := (
		not service.can_use_service(run_state, FoundryServiceCatalog.FOUNDRY_RARE_TOOL_PACK)
		and not service.can_use_service(run_state, FoundryServiceCatalog.FOUNDRY_LEGENDARY_TOOL_PACK)
		and service.get_unavailable_reason(run_state, FoundryServiceCatalog.FOUNDRY_RARE_TOOL_PACK) == "道具槽位不足"
	)
	return _check("tool pack services are unavailable when item slots are full", passed)


func _check_tool_clone_purge_copy_rules() -> bool:
	var run_state := _make_foundry_run()
	var source: DiceToolState = DiceToolState.create(&"tool_source", "Source", 30, &"rare")
	source.is_negative = true
	source.permanent_flags = {"kept": true}
	source.combat_counters = {"cooldown": 5}
	var other: DiceToolState = DiceToolState.create(&"tool_other", "Other", 5, &"common")
	run_state.dice_tools.append(source)
	run_state.dice_tools.append(other)
	run_state.installed_tools = run_state.dice_tools
	var service := FoundryService.new()
	service.rng.seed = _first_clone_source_seed()
	var result := service.apply_tool_clone_purge(run_state)
	var clone: DiceToolState = run_state.dice_tools[1]
	var passed: bool = (
		bool(result.get("success", false))
		and run_state.dice_tools.size() == 2
		and run_state.dice_tools[0] == source
		and clone.tool_id == source.tool_id
		and clone.rarity == source.rarity
		and bool(clone.permanent_flags.get("kept", false))
		and clone.combat_counters.is_empty()
		and not clone.is_negative
	)
	return _check("tool clone purge copies permanent data only and makes clone non-negative", passed)


func _apply_representative_service(service: FoundryService, run_state: RunState, service_id: StringName) -> void:
	match service_id:
		FoundryServiceCatalog.FOUNDRY_HIGH_PIP_REFORGE, FoundryServiceCatalog.FOUNDRY_SIX_PIP_REFORGE, FoundryServiceCatalog.FOUNDRY_RANDOM_PIP_REFORGE, FoundryServiceCatalog.FOUNDRY_POLY_GAMBLE:
			service.apply_service(run_state, service_id, {"die_index": 0})
		FoundryServiceCatalog.FOUNDRY_GOLD_MARK, FoundryServiceCatalog.FOUNDRY_RARE_ORNAMENT, FoundryServiceCatalog.FOUNDRY_RED_MARK, FoundryServiceCatalog.FOUNDRY_BLUE_MARK, FoundryServiceCatalog.FOUNDRY_PURPLE_MARK:
			service.apply_service(run_state, service_id, _face_target(0, 0))
		FoundryServiceCatalog.FOUNDRY_RARE_TOOL_PACK, FoundryServiceCatalog.FOUNDRY_LEGENDARY_TOOL_PACK, FoundryServiceCatalog.FOUNDRY_BURN_FOR_COINS, FoundryServiceCatalog.FOUNDRY_ALL_COMBO_UPGRADE:
			service.apply_service(run_state, service_id)
		FoundryServiceCatalog.FOUNDRY_SAME_PIP_SYNC:
			service.apply_service(run_state, service_id, {"target_faces": [_face_target(0, 0), _face_target(1, 0)]})
		FoundryServiceCatalog.FOUNDRY_NEGATIVE_TOOL_SLOT:
			run_state.dice_tools.append(DiceToolState.create(&"tool_a", "A", 10))
			run_state.installed_tools = run_state.dice_tools
			service.apply_service(run_state, service_id)
		FoundryServiceCatalog.FOUNDRY_TOOL_CLONE_PURGE:
			run_state.dice_tools.append(DiceToolState.create(&"tool_a", "A", 10))
			run_state.installed_tools = run_state.dice_tools
			service.apply_service(run_state, service_id)
		FoundryServiceCatalog.FOUNDRY_FACE_DOUBLE_COPY:
			service.apply_service(run_state, service_id, {
				"source_face": _face_target(0, 0),
				"target_faces": [_face_target(1, 0), _face_target(2, 0)],
			})


func _make_foundry_run() -> RunState:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.dice.clear()
	run_state.dice.append(_make_die(&"d6_1", 6))
	run_state.dice.append(_make_die(&"d6_2", 6))
	run_state.dice.append(_make_die(&"d6_3", 6))
	run_state.dice.append(_make_die(&"d6_4", 6))
	run_state.dice.append(_make_die(&"d6_5", 6))
	run_state.dice.append(_make_die(&"d6_6", 6))
	return run_state


func _make_die(id: StringName, face_count: int) -> DieState:
	var die := DieState.new()
	die.id = id
	die.face_count = face_count
	die.body_id = &"standard"
	for pip in range(1, face_count + 1):
		die.faces.append(FaceState.new(pip))
		die.face_weights.append(1)
	return die


func _die_target(die_index: int) -> Dictionary:
	return {"die_index": die_index}


func _face_target(die_index: int, face_index: int) -> Dictionary:
	return {"die_index": die_index, "face_index": face_index}


func _all_dice_face_counts_match(run_state: RunState) -> bool:
	for die in run_state.dice:
		if die == null or die.faces.size() != die.face_count:
			return false
	return true


func _dice_signature(run_state: RunState) -> String:
	var parts := PackedStringArray()
	for die in run_state.dice:
		for face in die.faces:
			parts.append("%d/%s/%s" % [face.pip, str(face.ornament_id), str(face.mark_id)])
	return "|".join(parts)


func _changed_faces_are_distinct(changed: Array) -> bool:
	var seen := {}
	for ref in changed:
		var key := "%d:%d" % [int(ref["die_index"]), int(ref["face_index"])]
		if seen.has(key):
			return false
		seen[key] = true
	return true


func _unique_ids(ids: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for id in ids:
		if not result.has(id):
			result.append(id)
	return result


func _first_clone_source_seed() -> int:
	for seed_value in range(1, 1000):
		var test_rng := RandomNumberGenerator.new()
		test_rng.seed = seed_value
		if test_rng.randi_range(0, 1) == 0:
			return seed_value
	return 1


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
