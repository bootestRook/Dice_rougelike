extends SceneTree
class_name DebugChineseDisplaySmokeTest


const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const RichTextHighlighter = preload("res://scripts/ui/RichTextHighlighter.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


func _init() -> void:
	print("--- DebugChineseDisplaySmokeTest: start ---")

	var all_passed := true
	var generator := RewardGenerator.new()
	generator.rng.seed = 112233
	var choices := generator.generate_forge_choices(3, 0)

	for choice in choices:
		all_passed = _check("reward display_name is not empty", choice.get_display_name() != "") and all_passed
		all_passed = _check("reward description is not empty", choice.get_description() != "") and all_passed
		all_passed = _check("reward tags text is not empty", choice.get_tags_display_text() != "") and all_passed
		all_passed = _check("reward tags text is Chinese-first", not _contains_internal_token(choice.get_tags_display_text())) and all_passed
		all_passed = _check("reward text has no removed visible terms", not _contains_removed_visible_terms(choice.get_display_text())) and all_passed

	var result: ScoreResult = _score_pair_with_tags()
	var summary: String = result.get_summary_text_zh()
	print(summary)
	all_passed = _check("summary contains primary combo label", summary.contains("主骰型")) and all_passed
	all_passed = _check("summary contains contained patterns label", summary.contains("包含结构")) and all_passed
	all_passed = _check("summary contains chips label", summary.contains("基础战力")) and all_passed
	all_passed = _check("summary contains mult label", summary.contains("倍率")) and all_passed
	all_passed = _check("summary contains xmult label", summary.contains("终倍率")) and all_passed
	all_passed = _check("summary contains final label", summary.contains("最终战力")) and all_passed
	all_passed = _check("summary combo is Chinese", summary.contains("一对") and not summary.contains("PAIR")) and all_passed
	all_passed = _check("summary contained patterns are Chinese", summary.contains("包含结构：一对") and not summary.contains("contains_pair")) and all_passed
	all_passed = _check("summary tags are Chinese", summary.contains("包含 6") and summary.contains("高点合计") and not summary.contains("contains_six") and not summary.contains("high_total")) and all_passed
	all_passed = _check("body display", DisplayNames.body_name(&"standard") == "标准骰胚") and all_passed
	all_passed = _check("legacy glass maps to burst ornament display", DisplayNames.ornament_name(&"glass") == "爆裂面饰") and all_passed
	all_passed = _check("legacy steel maps to stay ornament display", DisplayNames.ornament_name(&"steel") == "留场面饰") and all_passed
	all_passed = _check("mult ornament effect uses Chinese multiplier", DisplayNames.ornament_effect_text(&"orn_mult").contains("+4 倍率") and not DisplayNames.ornament_effect_text(&"orn_mult").contains("Mult")) and all_passed
	all_passed = _check("holo ornament effect uses Chinese multiplier", DisplayNames.ornament_effect_text(&"orn_holo").contains("+10 倍率") and not DisplayNames.ornament_effect_text(&"orn_holo").contains("Mult")) and all_passed
	all_passed = _check("holo forge reward description uses Chinese multiplier", str(TranslationServer.translate(&"AUTO.TEXT.E70A3C6E22B1")).contains("+10 倍率") and not str(TranslationServer.translate(&"AUTO.TEXT.E70A3C6E22B1")).contains("Mult")) and all_passed
	all_passed = _check("lucky ornament coin chance uses 6 percent", DisplayNames.ornament_effect_text(&"orn_lucky").contains("6% 获得 +20 金币") and not DisplayNames.ornament_effect_text(&"orn_lucky").contains("1/15")) and all_passed
	all_passed = _check("lucky forge reward description uses 6 percent", str(TranslationServer.translate(&"AUTO.TEXT.E699B4E7996F")).contains("6% 获得 +20 金币") and not str(TranslationServer.translate(&"AUTO.TEXT.E699B4E7996F")).contains("1/15")) and all_passed
	all_passed = _check("lucky forge part description uses 6 percent", str(TranslationServer.translate(&"FORGE_PART.ORNAMENT_LUCKY.DESC")).contains("6% 获得 +20 金币") and not str(TranslationServer.translate(&"FORGE_PART.ORNAMENT_LUCKY.DESC")).contains("1/15")) and all_passed
	all_passed = _check("stay ornament effect is final multiplier x2", DisplayNames.ornament_effect_text(&"orn_stay").contains("终倍率 ×2") and not DisplayNames.ornament_effect_text(&"orn_stay").contains("+2")) and all_passed
	all_passed = _check("stay forge reward description is final multiplier x2", str(TranslationServer.translate(&"AUTO.TEXT.A74D96EFFD75")).contains("终倍率 ×2") and not str(TranslationServer.translate(&"AUTO.TEXT.A74D96EFFD75")).contains("+2")) and all_passed
	all_passed = _check("red mark display", DisplayNames.mark_name(&"red") == "红印") and all_passed
	all_passed = _check("purple mark text uses die face wording", DisplayNames.mark_effect_text(&"purple").contains("每个骰面每场战斗最多生成 1 次") and not DisplayNames.mark_effect_text(&"purple").contains("物理面")) and all_passed
	all_passed = _check("gold mark effect has normalized coin punctuation", DisplayNames.mark_effect_text(&"gold").contains("+1 金币") and not DisplayNames.mark_effect_text(&"gold").contains("+1金币")) and all_passed
	all_passed = _check("score rich text highlights mult keyword and number", _rich_text_contains("+10 倍率", "[color=#00ff00]+10[/color] [color=#a36b00]倍率[/color]")) and all_passed
	all_passed = _check("score rich text highlights xmult keyword and symbol number", _rich_text_contains("终倍率 ×2", "[color=#a36b00]终倍率[/color] [color=#00ff00]×2[/color]")) and all_passed
	all_passed = _check("score rich text highlights chips keyword and number", _rich_text_contains("+50 基础战力", "[color=#00ff00]+50[/color] [color=#a36b00]基础战力[/color]")) and all_passed
	all_passed = _check("score rich text does not highlight multiplier ornament name", RichTextHighlighter.score_text_to_bbcode("倍率面饰：+4 倍率").begins_with("倍率面饰：")) and all_passed

	print("PASS: DebugChineseDisplaySmokeTest" if all_passed else "FAIL: DebugChineseDisplaySmokeTest")
	print("--- DebugChineseDisplaySmokeTest: end ---")
	quit(0 if all_passed else 1)


func _score_pair_with_tags() -> ScoreResult:
	var context := ScoreContext.new()
	context.selected_faces = [_make_roll(0, 0, 6), _make_roll(1, 0, 6)]
	context.all_rolled_faces = context.selected_faces
	context.primary_combo = ComboEvaluator.PAIR
	context.combo_id = ComboEvaluator.PAIR
	context.combo_type = ComboEvaluator.PAIR
	context.display_combo_ids = [ComboEvaluator.PAIR]
	context.contained_patterns = [ComboEvaluator.CONTAINS_PAIR]
	context.tags = [&"contains_six", &"high_total"]
	return ScoreEngine.new().score(context)


func _make_roll(die_index: int, face_index: int, pip: int) -> RolledFace:
	var face := FaceState.new()
	face.pip = pip
	var roll := RolledFace.new()
	roll.set_roll(die_index, face_index, face)
	roll.selected = true
	return roll


func _contains_internal_token(text: String) -> bool:
	for token in ["ornament_", "mark_", "material_", "rune_", "upgrade_", "xmult", "XMult", "chips", "mult", "Mult", "stable", "burst", "reroll"]:
		if text.contains(token):
			return true
	return false


func _contains_removed_visible_terms(text: String) -> bool:
	for term in ["锁定", "解锁", "材质", "符文", "等级", "血量", "扣血"]:
		if text.contains(term):
			return true
	return false


func _rich_text_contains(input_text: String, expected: String) -> bool:
	var actual := RichTextHighlighter.score_text_to_bbcode(input_text)
	if not actual.contains(expected):
		print("RichTextHighlighter expected: %s" % [expected])
		print("RichTextHighlighter actual: %s" % [actual])
	return actual.contains(expected)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
