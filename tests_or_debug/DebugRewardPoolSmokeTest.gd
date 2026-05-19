extends SceneTree
class_name DebugRewardPoolSmokeTest


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")


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

	var pool_sample := generator.generate_forge_choices(99, 2)
	print("Pool sample: %s" % [_ids_text(pool_sample)])
	all_passed = _check("pool sample has no duplicates", _choices_are_unique(pool_sample)) and all_passed
	all_passed = _check("pool sample excludes cleanse", not _has_piece(pool_sample, &"cleanse")) and all_passed
	all_passed = _check("pool sample contains no legacy ids", not _has_any_piece(pool_sample, LEGACY_IDS)) and all_passed
	for expected_id in EXPECTED_NORMAL_IDS:
		all_passed = _check("pool contains %s" % [str(expected_id)], _has_piece(pool_sample, expected_id)) and all_passed
	for expected_id in _expected_composite_ids():
		all_passed = _check("pool contains %s" % [str(expected_id)], _has_piece(pool_sample, expected_id)) and all_passed
	all_passed = _check("composite rewards have visible Chinese text", _composite_rewards_have_visible_text(pool_sample)) and all_passed

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


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
