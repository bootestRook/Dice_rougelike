extends SceneTree
class_name DebugRewardPoolSmokeTest


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const DiceToolRewardChoice = preload("res://scripts/data_defs/DiceToolRewardChoice.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


const LEGACY_IDS := [
	&"rune_six",
	&"rune_straight",
	&"rune_pair",
	&"rune_odd",
	&"rune_even",
	&"upgrade_1",
	&"material_glass",
	&"material_steel",
	&"glass_1",
]

const EXPECTED_NORMAL_IDS := [
	&"pip_1",
	&"pip_2",
	&"pip_3",
	&"pip_4",
	&"pip_5",
	&"pip_6",
	&"ornament_chip",
	&"ornament_mult",
	&"ornament_wild",
	&"ornament_burst",
	&"ornament_stay",
	&"ornament_stone",
	&"ornament_gold",
	&"ornament_lucky",
	&"ornament_foil",
	&"ornament_holo",
	&"ornament_poly",
	&"mark_red",
	&"mark_blue",
	&"mark_purple",
	&"mark_gold",
	&"mark_white",
]

const COMPOSITE_PREFIXES := [
	&"red",
	&"blue",
	&"purple",
	&"gold",
	&"burst",
	&"stay",
]

const INTERNAL_TEXT_TOKENS := [
	"red_",
	"blue_",
	"purple_",
	"gold_",
	"burst_",
	"stay_",
	"mark_",
	"orn_",
	"OP_SET",
	"SET_",
]


func _init() -> void:
	print("--- DebugRewardPoolSmokeTest: start ---")

	var all_passed := true
	var generator := RewardGenerator.new()
	generator.rng.seed = 97531
	all_passed = _check("all forge pieces have archetype tags", _all_catalog_pieces_have_tags(generator)) and all_passed

	var choices := generator.generate_forge_choices(3, 0)
	print("Choices: %s" % [_ids_text(choices)])
	all_passed = _check("choices count is 3", choices.size() == 3) and all_passed
	all_passed = _check("choices are unique", _choices_are_unique(choices)) and all_passed
	all_passed = _check("choices do not include cleanse", not _has_piece(choices, &"cleanse")) and all_passed
	all_passed = _check("choices include direct power", _has_direct_power(generator, choices)) and all_passed
	all_passed = _check("choices contain no legacy ids", not _has_any_piece(choices, LEGACY_IDS)) and all_passed
	all_passed = _check("normal battle choices exclude zero-weight rarities", not _has_rarity(choices, &"epic") and not _has_rarity(choices, &"legendary")) and all_passed

	var pool_sample := generator._build_forge_piece_pool()
	print("Pool sample: %s" % [_ids_text(pool_sample)])
	all_passed = _check("pool sample has no duplicates", _choices_are_unique(pool_sample)) and all_passed
	all_passed = _check("pool sample excludes cleanse", not _has_piece(pool_sample, &"cleanse")) and all_passed
	all_passed = _check("pool sample contains no legacy ids", not _has_any_piece(pool_sample, LEGACY_IDS)) and all_passed
	for expected_id in EXPECTED_NORMAL_IDS:
		all_passed = _check("pool contains %s" % [str(expected_id)], _has_piece(pool_sample, expected_id)) and all_passed
	for expected_id in _expected_composite_ids():
		all_passed = _check("pool contains %s" % [str(expected_id)], _has_piece(pool_sample, expected_id)) and all_passed
	all_passed = _check("composite rewards have visible Chinese text", _composite_rewards_have_visible_text(pool_sample)) and all_passed
	all_passed = _check("reward catalog assigns five-tier rarity gates", _reward_rarity_gates_are_assigned(generator)) and all_passed
	all_passed = _check("encounter reward rarity weights are applied", _encounter_reward_weights_are_applied(generator)) and all_passed
	all_passed = _check("dice tool rewards are limited to elite boss reward and special nodes", _dice_tool_reward_sources_are_applied()) and all_passed

	print("PASS: DebugRewardPoolSmokeTest" if all_passed else "FAIL: DebugRewardPoolSmokeTest")
	print("--- DebugRewardPoolSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _choices_are_unique(choices: Array[ForgePieceDef]) -> bool:
	var ids: Array[StringName] = []
	for choice in choices:
		if choice == null or ids.has(choice.id):
			return false
		ids.append(choice.id)
	return true


func _has_piece(choices: Array[ForgePieceDef], id: StringName) -> bool:
	for choice in choices:
		if choice != null and choice.id == id:
			return true
	return false


func _find_piece(choices: Array[ForgePieceDef], id: StringName) -> ForgePieceDef:
	for choice in choices:
		if choice != null and choice.id == id:
			return choice
	return null


func _has_any_piece(choices: Array[ForgePieceDef], ids: Array) -> bool:
	for id in ids:
		if _has_piece(choices, id):
			return true
	return false


func _has_rarity(choices: Array[ForgePieceDef], rarity: StringName) -> bool:
	for choice in choices:
		if choice != null and choice.get_rarity() == rarity:
			return true
	return false


func _has_direct_power(generator: RewardGenerator, choices: Array[ForgePieceDef]) -> bool:
	for choice in choices:
		if generator._is_direct_power_piece(choice):
			return true
	return false


func _ids_text(choices: Array[ForgePieceDef]) -> String:
	var ids := PackedStringArray()
	for choice in choices:
		ids.append(str(choice.id if choice != null else &"null"))
	return "[" + ", ".join(ids) + "]"


func _expected_composite_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for prefix in COMPOSITE_PREFIXES:
		for pip in range(1, 7):
			ids.append(StringName("%s_%d" % [str(prefix), pip]))
	return ids


func _composite_rewards_have_visible_text(choices: Array[ForgePieceDef]) -> bool:
	for id in _expected_composite_ids():
		var piece := _find_piece(choices, id)
		if piece == null:
			return false
		var text := piece.get_display_text()
		if text == "":
			return false
		for token in INTERNAL_TEXT_TOKENS:
			if text.contains(str(token)):
				return false
	return true


func _all_catalog_pieces_have_tags(generator: RewardGenerator) -> bool:
	var catalog := generator._build_piece_catalog()
	for id in catalog.keys():
		var piece := catalog[id] as ForgePieceDef
		if piece == null or piece.get_archetype_tags().is_empty():
			return false
	return true


func _reward_rarity_gates_are_assigned(generator: RewardGenerator) -> bool:
	var catalog := generator._build_piece_catalog()
	var expected := {
		&"pip_6": &"common",
		&"ornament_wild": &"rare",
		&"ornament_stone": &"uncommon",
		&"ornament_foil": &"rare",
		&"ornament_poly": &"epic",
		&"mark_red": &"rare",
		&"mark_blue": &"rare",
		&"mark_purple": &"rare",
		&"mark_gold": &"uncommon",
		&"mark_white": &"rare",
		&"red_4": &"epic",
		&"red_5": &"epic",
		&"red_6": &"epic",
		&"blue_1": &"rare",
		&"blue_5": &"rare",
		&"blue_6": &"epic",
		&"purple_1": &"rare",
		&"purple_5": &"rare",
		&"purple_6": &"epic",
		&"gold_5": &"uncommon",
		&"gold_6": &"rare",
		&"burst_3": &"uncommon",
		&"burst_4": &"rare",
		&"burst_6": &"rare",
		&"stay_6": &"rare",
		&"cleanse": &"uncommon",
		&"material_glass": &"uncommon",
		&"material_steel": &"uncommon",
		&"glass_1": &"uncommon",
		&"upgrade_1": &"rare",
		&"rune_six": &"uncommon",
		&"rune_straight": &"rare",
		&"rune_pair": &"uncommon",
		&"rune_odd": &"common",
		&"rune_even": &"common",
		&"upgrade_combo_scatter": &"common",
		&"upgrade_combo_pair": &"common",
		&"upgrade_combo_two_pair": &"uncommon",
		&"upgrade_combo_three_kind": &"uncommon",
		&"upgrade_combo_full_house": &"uncommon",
		&"upgrade_combo_four_kind": &"rare",
		&"upgrade_combo_straight": &"rare",
		&"upgrade_combo_five_kind": &"epic",
	}
	for id in expected.keys():
		if not catalog.has(id):
			return false
		var piece := catalog[id] as ForgePieceDef
		if piece == null or piece.get_rarity() != expected[id]:
			return false
	return true


func _encounter_reward_weights_are_applied(generator: RewardGenerator) -> bool:
	if not _weights_match(generator._rarity_weights_for_encounter(&"battle"), {
		&"common": 72.0,
		&"uncommon": 24.0,
		&"rare": 4.0,
		&"epic": 0.0,
		&"legendary": 0.0,
	}):
		return false
	if not _weights_match(generator._rarity_weights_for_encounter(&"elite"), {
		&"common": 20.0,
		&"uncommon": 45.0,
		&"rare": 28.0,
		&"epic": 7.0,
		&"legendary": 0.0,
	}):
		return false
	if not _weights_match(generator._rarity_weights_for_encounter(&"boss"), {
		&"common": 0.0,
		&"uncommon": 20.0,
		&"rare": 45.0,
		&"epic": 25.0,
		&"legendary": 10.0,
	}):
		return false

	var normal_pool := generator.generate_forge_choices_for_encounter(99, &"battle")
	if not _has_rarity(normal_pool, &"common") or not _has_rarity(normal_pool, &"uncommon") or not _has_rarity(normal_pool, &"rare"):
		return false
	if _has_rarity(normal_pool, &"epic") or _has_rarity(normal_pool, &"legendary"):
		return false

	var elite_pool := generator.generate_forge_choices_for_encounter(99, &"elite")
	if not _has_rarity(elite_pool, &"common") or not _has_rarity(elite_pool, &"uncommon") or not _has_rarity(elite_pool, &"rare") or not _has_rarity(elite_pool, &"epic"):
		return false
	if _has_rarity(elite_pool, &"legendary"):
		return false

	var boss_pool := generator.generate_forge_choices_for_encounter(99, &"boss")
	if _has_rarity(boss_pool, &"common"):
		return false
	if not _has_rarity(boss_pool, &"uncommon") or not _has_rarity(boss_pool, &"rare") or not _has_rarity(boss_pool, &"epic"):
		return false
	return true


func _dice_tool_reward_sources_are_applied() -> bool:
	var generator := RewardGenerator.new()
	generator.rng.seed = 4201

	var normal_run := RunState.new()
	normal_run.setup_new_run()
	normal_run.current_encounter_node_type = RunState.ENCOUNTER_BATTLE
	var normal_choices := generator.generate_battle_reward_choices(normal_run, 3)

	var elite_run := RunState.new()
	elite_run.setup_new_run()
	elite_run.current_encounter_node_type = RunState.ENCOUNTER_ELITE
	var elite_choices := generator.generate_battle_reward_choices(elite_run, 3)

	var boss_run := RunState.new()
	boss_run.setup_new_run()
	boss_run.current_encounter_node_type = RunState.ENCOUNTER_BOSS
	var boss_choices := generator.generate_battle_reward_choices(boss_run, 3)

	var event_choices := generator.generate_special_event_choices(3)
	var reward_node_can_roll_tool := false
	var reward_node_can_roll_without_tool := false
	for seed_value in range(1, 200):
		var seeded := RewardGenerator.new()
		seeded.rng.seed = seed_value
		var node_choices := seeded.generate_map_reward_node_choices(3)
		if _has_dice_tool_choice(node_choices):
			reward_node_can_roll_tool = true
		else:
			reward_node_can_roll_without_tool = true
		if reward_node_can_roll_tool and reward_node_can_roll_without_tool:
			break

	return (
		normal_choices.size() == 3
		and not _has_dice_tool_choice(normal_choices)
		and elite_choices.size() == 3
		and _has_dice_tool_choice(elite_choices)
		and boss_choices.size() == 3
		and _has_dice_tool_choice(boss_choices)
		and event_choices.size() == 3
		and _has_dice_tool_choice(event_choices)
		and reward_node_can_roll_tool
		and reward_node_can_roll_without_tool
		and _dice_tool_choices_say_item_then_use(elite_choices + boss_choices + event_choices)
	)


func _has_dice_tool_choice(choices: Array) -> bool:
	for choice in choices:
		if choice is DiceToolRewardChoice:
			return true
	return false


func _dice_tool_choices_say_item_then_use(choices: Array) -> bool:
	for choice in choices:
		if choice is DiceToolRewardChoice:
			var description := (choice as DiceToolRewardChoice).get_description()
			if not description.contains("道具槽") or not description.contains("使用后"):
				return false
	return true


func _weights_match(actual: Dictionary, expected: Dictionary) -> bool:
	for rarity in expected.keys():
		if not is_equal_approx(float(actual.get(rarity, -1.0)), float(expected[rarity])):
			return false
	return true


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
