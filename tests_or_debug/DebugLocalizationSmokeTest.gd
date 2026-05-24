extends SceneTree


const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocNode = preload("res://scripts/i18n/Loc.gd")
const LocService = preload("res://scripts/i18n/LocService.gd")
const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


const REQUIRED_LOCALES := ["zh_Hans", "en"]
const SOURCE_EXTENSIONS := ["gd", "tscn", "tres", "json"]
const TEXT_INTEGRITY_EXTENSIONS := ["gd", "tscn", "tres", "json", "po", "pot"]


func _init() -> void:
	print("--- DebugLocalizationSmokeTest: start ---")

	var all_passed := true
	all_passed = _run_check("required locales", _test_required_locales()) and all_passed
	all_passed = _run_check("core keys", _test_core_keys()) and all_passed
	all_passed = _run_check("data keys", _test_data_keys()) and all_passed
	all_passed = _run_check("localized runtime text", _test_localized_runtime_text()) and all_passed
	all_passed = _run_check("UTF-8 and mojibake integrity", _test_text_integrity()) and all_passed
	all_passed = _run_check("no mojibake in source text", _test_no_mojibake_in_source_text()) and all_passed

	if all_passed:
		print("PASS: DebugLocalizationSmokeTest")
	else:
		print("FAIL: DebugLocalizationSmokeTest")

	print("--- DebugLocalizationSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _test_required_locales() -> bool:
	var loc_node := LocNode.new()
	get_root().add_child(loc_node)
	for locale in REQUIRED_LOCALES:
		loc_node.set_locale(locale)
		if loc_node.get_locale() == "" or LocService.get_locale() == "":
			push_error("Locale did not activate: %s" % [locale])
			loc_node.queue_free()
			return false
	loc_node.queue_free()
	return true


func _test_core_keys() -> bool:
	var keys := [
		&"UI.MAIN.TITLE",
		&"UI.MAIN.DESCRIPTION",
		&"UI.MAIN.VERSION_TITLE",
		&"UI.MAIN.VERSION_BODY",
		&"UI.MAIN.START",
		&"UI.MAIN.RULES_TITLE",
		&"UI.MAIN.RULES_BODY",
		&"UI.BATTLE.TITLE",
		&"UI.BATTLE.SCORE",
		&"UI.BATTLE.HAND",
		&"UI.BATTLE.REROLL",
		&"UI.BATTLE.REROLL_LEFT",
		&"UI.BATTLE.LOCK",
		&"UI.BATTLE.UNLOCK",
		&"UI.BATTLE.SELECT",
		&"UI.BATTLE.SELECTED",
		&"UI.BATTLE.LOG_LAST_TITLE",
		&"UI.BATTLE.LOG_ACTUAL_SCORE",
		&"UI.BATTLE.LOG_SECTION_TITLE",
		&"UI.BATTLE.PREVIEW_EMPTY",
		&"UI.BATTLE.PREVIEW_TOO_MANY",
		&"UI.BATTLE.PREVIEW",
		&"UI.BATTLE.DEBUG_INFO",
		&"UI.BATTLE.VICTORY",
		&"UI.BATTLE.DEFEAT",
		&"UI.SCORE_SUMMARY.NONE",
		&"UI.SCORE_SUMMARY.COMBO",
		&"UI.SCORE_SUMMARY.PRIMARY_COMBO",
		&"UI.SCORE_SUMMARY.CONTAINED_PATTERNS",
		&"UI.SCORE_SUMMARY.TAGS",
		&"UI.SCORE_SUMMARY.CHIPS",
		&"UI.SCORE_SUMMARY.MULT",
		&"UI.SCORE_SUMMARY.XMULT",
		&"UI.SCORE_SUMMARY.FINAL",
		&"UI.RUN.SUMMARY_TOP_EFFECT",
		&"UI.RUN.SUMMARY_TOP_EFFECT_NONE",
		&"UI.RUN.SUMMARY_SETTLEMENT_TITLE",
		&"UI.RUN.SUMMARY_SETTLEMENT_NONE",
		&"UI.RUN.SUMMARY_SETTLEMENT_ITEM",
		&"UI.RUN.SUMMARY_SETTLEMENT_LOG_ITEM",
		&"UI.REWARD.TITLE",
		&"UI.REWARD.RARITY",
		&"UI.REWARD.ARCHETYPE_TAGS",
		&"UI.REWARD.ARCHETYPE_TAG_NONE",
		&"UI.REWARD.EFFECT",
		&"UI.REWARD.SELECT",
		&"UI.INSTALL.TITLE",
		&"UI.INSTALL.DIE",
		&"UI.INSTALL.FACE",
		&"UI.INSTALL.VALUE",
		&"UI.INSTALL.MATERIAL",
		&"UI.INSTALL.IMPRINT",
		&"UI.INSTALL.RUNE",
		&"UI.INSTALL.LEVEL",
		&"UI.INSTALL.CONFIRM",
		&"UI.INSTALL.CANCEL",
		&"LOG.COMBO",
		&"LOG.CONTAINED_PATTERNS",
		&"LOG.PIP_SUM",
		&"LOG.BASE_CHIPS",
		&"LOG.BASE_MULT",
		&"LOG.CHIPS_GAIN",
		&"LOG.MULT_GAIN",
		&"LOG.XMULT_GAIN",
		&"LOG.RETRIGGER",
		&"LOG.MATERIAL_TRIGGER",
		&"LOG.IMPRINT_TRIGGER",
		&"LOG.RUNE_TRIGGER",
		&"LOG.RELIC_TRIGGER",
		&"LOG.FORGE_PART_TRIGGER",
		&"LOG.FINAL_SCORE",
		&"COMBO.SCATTER",
		&"COMBO.PAIR",
		&"COMBO.TWO_PAIR",
		&"COMBO.THREE_KIND",
		&"COMBO.FULL_HOUSE",
		&"COMBO.STRAIGHT",
		&"COMBO.FOUR_KIND",
		&"COMBO.FIVE_KIND",
		&"CONTAINED_PATTERN.CONTAINS_PAIR",
		&"CONTAINED_PATTERN.CONTAINS_TWO_PAIR",
		&"CONTAINED_PATTERN.CONTAINS_THREE_KIND",
		&"CONTAINED_PATTERN.CONTAINS_FULL_HOUSE",
		&"CONTAINED_PATTERN.CONTAINS_FOUR_KIND",
		&"CONTAINED_PATTERN.CONTAINS_FIVE_KIND",
		&"RARITY.COMMON",
		&"RARITY.UNCOMMON",
		&"RARITY.RARE",
		&"RARITY.LEGENDARY",
		&"TAG.ALL_ODD",
		&"TAG.ALL_EVEN",
		&"TAG.LOW_TOTAL",
		&"TAG.HIGH_TOTAL",
		&"TAG.CONTAINS_SIX",
		&"TAG.MANY_SIXES",
		&"TAG.FEW_SCORED",
		&"TAG.REROLLED",
		&"TAG.LAST_HAND",
		&"TAG.SIX_BUILD",
		&"TAG.HIGH_PIP",
		&"TAG.LOW_PIP",
		&"TAG.ODD_BUILD",
		&"TAG.EVEN_BUILD",
		&"TAG.SINGLE_FACE",
		&"TAG.RETRIGGER",
		&"TAG.UNSELECTED",
		&"TAG.MULT_BUILD",
		&"TAG.XMULT_BUILD",
		&"TAG.STRAIGHT_BUILD",
		&"TAG.CHIPS_BUILD",
		&"TAG.PAIR_BUILD",
		&"TAG.LEVEL_BUILD",
		&"TAG.CLEANSE",
		&"EFFECT.LEVEL.NAME",
		&"PHASE.INIT",
		&"PHASE.WAITING_ACTION",
		&"PHASE.SCORING",
		&"PHASE.VICTORY",
		&"PHASE.DEFEAT",
		&"PHASE.UNKNOWN",
	]

	for locale in REQUIRED_LOCALES:
		LocService.set_locale(locale)
		for key in keys:
			if not _key_translates(key):
				push_error("Missing localization key: %s in %s" % [str(key), locale])
				return false
	return true


func _test_localized_runtime_text() -> bool:
	LocService.set_locale("zh_Hans")

	var result := ScoreResult.new()
	result.primary_combo = &"scatter"
	result.combo_id = &"scatter"
	result.tags = [&"all_odd", &"low_total", &"few_scored"]
	result.chips = 3
	result.mult = 1
	result.xmult = 1.0
	result.final_score = 3

	var summary := result.get_summary_text()
	for leaked_text in ["all_odd", "low_total", "few_scored", "Chips", "Mult", "XMult"]:
		if summary.contains(leaked_text):
			push_error("Unlocalized score summary text leaked: %s in %s" % [leaked_text, summary])
			return false

	result.primary_combo = &"straight"
	result.combo_id = &"straight"
	result.display_combo_ids = [&"straight"]
	result.contained_patterns = []
	summary = result.get_summary_text()
	for leaked_legacy_id in ["SMALL_STRAIGHT", "LARGE_STRAIGHT", "HIGH_CARD", "contains_pair"]:
		if summary.contains(leaked_legacy_id):
			push_error("Score summary leaked legacy combo or contained pattern id: %s in %s" % [leaked_legacy_id, summary])
			return false
	if summary.contains("straight") or summary.contains("scatter"):
		push_error("Score summary leaked raw combo id: %s" % [summary])
		return false

	var early_phase_text := LocService.t(LocKeys.battle_phase_key(&"WAITING_ACTION"))
	if early_phase_text == "WAITING_ACTION" or early_phase_text == str(LocKeys.battle_phase_key(&"WAITING_ACTION")):
		push_error("Unlocalized battle phase leaked: %s" % [early_phase_text])
		return false

	return true


func _test_data_keys() -> bool:
	var reward_generator := RewardGenerator.new()
	var pieces := reward_generator.generate_forge_choices(99)
	for locale in REQUIRED_LOCALES:
		LocService.set_locale(locale)
		for piece in pieces:
			if piece == null:
				push_error("Reward pool contains null piece.")
				return false
			if not _piece_text_resolves(piece.get_display_name(), piece.get_name_key(), piece.id):
				push_error("Forge piece display name did not resolve: %s" % [str(piece.id)])
				return false
			if piece.display_name == "" and not _key_translates(piece.get_name_key()):
				push_error("Missing forge piece name key: %s" % [str(piece.get_name_key())])
				return false
			if not _piece_text_resolves(piece.get_description(), piece.get_desc_key(), piece.id):
				push_error("Forge piece description did not resolve: %s" % [str(piece.id)])
				return false
			if piece.description == "" and not _key_translates(piece.get_desc_key()):
				push_error("Missing forge piece desc key: %s" % [str(piece.get_desc_key())])
				return false
			if not _key_translates(piece.get_rarity_key()):
				push_error("Missing forge piece rarity key: %s" % [str(piece.get_rarity_key())])
				return false
			for operation in piece.get_operations():
				if operation == null:
					push_error("Forge piece has null operation: %s" % [str(piece.id)])
					return false
				if not _key_translates(operation.get_text_key()):
					push_error("Missing forge operation key: %s" % [str(operation.get_text_key())])
					return false
				var operation_text := operation.get_display_text()
				if operation_text == str(operation.get_text_key()):
					push_error("Forge operation did not localize: %s" % [str(operation.get_text_key())])
					return false
			if not _piece_tags_resolve(piece):
				return false

		if not _test_id_key_group("material", [&"none", &"glass", &"steel", &"blood", &"mirror", &"curse"]):
			return false
		if not _test_id_key_group("imprint", [&"none", &"red", &"blue", &"gold", &"white", &"purple", &"black"]):
			return false
		if not _test_id_key_group("rune", [&"none", &"six", &"low", &"straight", &"pair", &"odd", &"even", &"reroll", &"curse"]):
			return false
		if not _test_data_resource_files():
			return false

	return true


func _piece_text_resolves(text: String, key: StringName, id: StringName) -> bool:
	var trimmed := text.strip_edges()
	return trimmed != "" and trimmed != str(key) and trimmed != str(id)


func _piece_tags_resolve(piece) -> bool:
	var tags_text: String = piece.get_tags_display_text()
	if tags_text.strip_edges() == "":
		push_error("Forge piece tags are empty: %s" % [str(piece.id)])
		return false

	for tag in piece.get_archetype_tags():
		var raw_tag := str(tag)
		if raw_tag != "" and tags_text.contains(raw_tag):
			push_error("Forge piece archetype tag leaked raw id %s on %s: %s" % [raw_tag, str(piece.id), tags_text])
			return false
	return true


func _test_id_key_group(group: String, ids: Array[StringName]) -> bool:
	for id in ids:
		var name_key: StringName
		var desc_key: StringName
		match group:
			"material":
				name_key = LocKeys.material_name_key(id)
				desc_key = LocKeys.material_desc_key(id)
			"imprint":
				name_key = LocKeys.imprint_name_key(id)
				desc_key = LocKeys.imprint_desc_key(id)
			"rune":
				name_key = LocKeys.rune_name_key(id)
				desc_key = LocKeys.rune_desc_key(id)
			_:
				return false
		if not _key_translates(name_key):
			push_error("Missing %s name key: %s" % [group, str(name_key)])
			return false
		if not _key_translates(desc_key):
			push_error("Missing %s desc key: %s" % [group, str(desc_key)])
			return false
	return true


func _test_data_resource_files() -> bool:
	var paths: Array[String] = []
	_collect_files("res://data", ["tres", "res"], paths)
	for path in paths:
		var resource := load(path)
		if resource == null:
			push_error("Could not load data resource: %s" % [path])
			return false
		for property_name in ["name_key", "desc_key", "rarity_key", "effect_key"]:
			if not _resource_has_property(resource, property_name):
				continue
			var key = resource.get(property_name)
			if key is StringName and key != &"" and not _key_translates(key):
				push_error("Missing data resource key %s on %s: %s" % [property_name, path, str(key)])
				return false
	return true


func _test_no_mojibake_in_source_text() -> bool:
	var paths: Array[String] = []
	_collect_files("res://", SOURCE_EXTENSIONS, paths)
	var failing_paths: PackedStringArray = []
	for path in paths:
		if _source_path_excluded(path):
			continue
		var text := FileAccess.get_file_as_string(path)
		var pattern := _first_mojibake_pattern(text)
		if pattern != "":
			failing_paths.append("%s (%s)" % [path, pattern])

	if failing_paths.is_empty():
		return true

	for path in failing_paths:
		push_error("Possible mojibake source text found: %s" % [path])
	return false


func _test_text_integrity() -> bool:
	var paths: Array[String] = []
	_collect_files("res://", TEXT_INTEGRITY_EXTENSIONS, paths)
	var invalid_paths: PackedStringArray = []
	var mojibake_paths: PackedStringArray = []

	for path in paths:
		if path.begins_with("res://.git/") or path.begins_with("res://.godot/"):
			continue
		var text := FileAccess.get_file_as_string(path)
		if FileAccess.get_open_error() != OK:
			invalid_paths.append(path)
			continue
		var pattern := _first_mojibake_pattern(text)
		if pattern != "":
			mojibake_paths.append("%s (%s)" % [path, pattern])

	for path in invalid_paths:
		push_error("Could not read text file as UTF-8: %s" % [path])
	for path in mojibake_paths:
		push_error("Possible mojibake text found: %s" % [path])
	return invalid_paths.is_empty() and mojibake_paths.is_empty()


func _first_mojibake_pattern(text: String) -> String:
	for pattern in _mojibake_patterns():
		if text.contains(pattern):
			return pattern
	return ""


func _mojibake_patterns() -> Array[String]:
	return [
		String.chr(0x951B),
		String.chr(0x8133),
		String.chr(0x9416),
		String.chr(0x9369),
		String.chr(0x7EDB),
		String.chr(0x95B2),
		String.chr(0x9483),
		String.chr(0x7EF1),
		String.chr(0x9427),
		String.chr(0x59B2),
		String.chr(0x74D2),
		String.chr(0x6960) + String.chr(0x677F),
		String.chr(0x95C8) + String.chr(0x3224) + String.chr(0x30B0),
		String.chr(0x9357) + String.chr(0x62CC),
		String.chr(0xFFFD),
	]


func _key_translates(key: StringName) -> bool:
	if key == &"":
		return true
	var text := LocService.t(key)
	return text != str(key)


func _resource_has_property(resource: Resource, property_name: String) -> bool:
	for property_info in resource.get_property_list():
		if str(property_info.get("name", "")) == property_name:
			return true
	return false


func _collect_files(root_path: String, extensions: Array, output: Array[String]) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var path := root_path.path_join(file_name)
		if dir.current_is_dir():
			if not _directory_excluded(path):
				_collect_files(path, extensions, output)
		else:
			var extension := path.get_extension()
			if extensions.has(extension):
				output.append(path)

		file_name = dir.get_next()


func _directory_excluded(path: String) -> bool:
	return path == "res://.git" or path == "res://.godot" or path == "res://reference"


func _source_path_excluded(path: String) -> bool:
	if path.begins_with("res://i18n/"):
		return true
	if path.get_file().begins_with("Debug"):
		return true
	return false


func _run_check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	return passed
