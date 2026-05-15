extends SceneTree
class_name DebugLocalizationSmokeTest


const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocNode = preload("res://scripts/i18n/Loc.gd")
const LocService = preload("res://scripts/i18n/LocService.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


const REQUIRED_LOCALES := ["zh_Hans", "en"]
const SOURCE_EXTENSIONS := ["gd", "tscn", "tres", "json"]


func _init() -> void:
	print("--- DebugLocalizationSmokeTest: start ---")

	var all_passed := true
	all_passed = _run_check("required locales", _test_required_locales()) and all_passed
	all_passed = _run_check("core keys", _test_core_keys()) and all_passed
	all_passed = _run_check("data keys", _test_data_keys()) and all_passed
	all_passed = _run_check("localized runtime text", _test_localized_runtime_text()) and all_passed
	all_passed = _run_check("no visible CJK in player text sources", _test_no_visible_chinese_in_player_text_sources()) and all_passed

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
		&"UI.BATTLE.LOG_SECTION_TITLE",
		&"UI.BATTLE.PREVIEW_EMPTY",
		&"UI.BATTLE.PREVIEW",
		&"UI.BATTLE.DEBUG_INFO",
		&"UI.BATTLE.VICTORY",
		&"UI.BATTLE.DEFEAT",
		&"UI.SCORE_SUMMARY.NONE",
		&"UI.SCORE_SUMMARY.COMBO",
		&"UI.SCORE_SUMMARY.TAGS",
		&"UI.SCORE_SUMMARY.CHIPS",
		&"UI.SCORE_SUMMARY.MULT",
		&"UI.SCORE_SUMMARY.XMULT",
		&"UI.SCORE_SUMMARY.FINAL",
		&"UI.REWARD.TITLE",
		&"UI.REWARD.RARITY",
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
		&"COMBO.HIGH_CARD",
		&"COMBO.PAIR",
		&"COMBO.TWO_PAIR",
		&"COMBO.THREE_KIND",
		&"COMBO.FULL_HOUSE",
		&"COMBO.SMALL_STRAIGHT",
		&"COMBO.LARGE_STRAIGHT",
		&"COMBO.FOUR_KIND",
		&"COMBO.FIVE_KIND",
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
	result.combo_id = &"HIGH_CARD"
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

	result.combo_id = &"SMALL_STRAIGHT"
	result.display_combo_ids = [&"SMALL_STRAIGHT", &"PAIR"]
	summary = result.get_summary_text()
	if (
		not summary.contains(LocService.t(&"COMBO.SMALL_STRAIGHT"))
		or not summary.contains(LocService.t(&"COMBO.PAIR"))
	):
		push_error("Display combo summary missed a matched combo: %s" % [summary])
		return false

	var phase_text := LocService.t(LocKeys.battle_phase_key(&"WAITING_ACTION"))
	if phase_text == "WAITING_ACTION" or phase_text == str(LocKeys.battle_phase_key(&"WAITING_ACTION")):
		push_error("Unlocalized battle phase leaked: %s" % [phase_text])
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
			if not _key_translates(piece.get_name_key()):
				push_error("Missing forge piece name key: %s" % [str(piece.get_name_key())])
				return false
			if not _key_translates(piece.get_desc_key()):
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

		if not _test_id_key_group("material", [&"none", &"glass", &"steel", &"blood", &"mirror", &"curse"]):
			return false
		if not _test_id_key_group("imprint", [&"none", &"red", &"blue", &"gold", &"white", &"purple", &"black"]):
			return false
		if not _test_id_key_group("rune", [&"none", &"six", &"low", &"straight", &"pair", &"odd", &"even", &"reroll", &"curse"]):
			return false
		if not _test_data_resource_files():
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


func _test_no_visible_chinese_in_player_text_sources() -> bool:
	var paths: Array[String] = []
	_collect_files("res://", SOURCE_EXTENSIONS, paths)
	for path in paths:
		if _source_path_excluded(path):
			continue
		var text := FileAccess.get_file_as_string(path)
		if _contains_cjk(text):
			push_error("CJK player text found outside localization resources: %s" % [path])
			return false
	return true


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


func _contains_cjk(text: String) -> bool:
	for index in range(text.length()):
		var code := text.unicode_at(index)
		if (code >= 0x3400 and code <= 0x9FFF) or (code >= 0xF900 and code <= 0xFAFF):
			return true
	return false


func _run_check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	return passed
