extends SceneTree
class_name DebugRewardPoolSmokeTest


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")


func _init() -> void:
	print("--- DebugRewardPoolSmokeTest: start ---")

	var all_passed := true
	var generator := RewardGenerator.new()
	generator.rng.seed = 97531
	all_passed = _check("all forge pieces have archetype tags", _all_catalog_pieces_have_tags(generator)) and all_passed

	var early_choices := generator.generate_forge_choices(3, 0)
	print("Early choices: %s" % [_ids_text(early_choices)])
	all_passed = _check("early choices count is 3", early_choices.size() == 3) and all_passed
	all_passed = _check("early choices are unique", _choices_are_unique(early_choices)) and all_passed
	all_passed = _check("early choices do not include cleanse", not _has_piece(early_choices, &"cleanse")) and all_passed
	all_passed = _check("early choices do not include rune_pair", not _has_piece(early_choices, &"rune_pair")) and all_passed
	all_passed = _check("early choices do not include rune_straight", not _has_piece(early_choices, &"rune_straight")) and all_passed
	all_passed = _check("early choices include direct power", _has_direct_power(generator, early_choices)) and all_passed

	var mid_choices := generator.generate_forge_choices(3, 2)
	print("Battle 3 choices: %s" % [_ids_text(mid_choices)])
	all_passed = _check("battle 3 choices count is 3", mid_choices.size() == 3) and all_passed
	all_passed = _check("battle 3 choices are unique", _choices_are_unique(mid_choices)) and all_passed
	all_passed = _check("battle 3 choices include direct power", _has_direct_power(generator, mid_choices)) and all_passed

	var mid_pool_sample := generator.generate_forge_choices(99, 2)
	all_passed = _check("mid pool sample has no duplicates", _choices_are_unique(mid_pool_sample)) and all_passed
	all_passed = _check("mid pool sample excludes cleanse", not _has_piece(mid_pool_sample, &"cleanse")) and all_passed
	all_passed = _check("mid pool can include rune_pair", _has_piece(mid_pool_sample, &"rune_pair")) and all_passed
	all_passed = _check("mid pool can include rune_straight", _has_piece(mid_pool_sample, &"rune_straight")) and all_passed

	if all_passed:
		print("PASS: DebugRewardPoolSmokeTest")
	else:
		print("FAIL: DebugRewardPoolSmokeTest")

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
