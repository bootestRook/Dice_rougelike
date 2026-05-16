extends SceneTree
class_name DebugChineseDisplaySmokeTest


const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
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
	all_passed = _check("red mark display", DisplayNames.mark_name(&"red") == "红印") and all_passed

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
	for token in ["ornament_", "mark_", "material_", "rune_", "upgrade_", "xmult", "chips", "mult", "stable", "burst", "reroll"]:
		if text.contains(token):
			return true
	return false


func _contains_removed_visible_terms(text: String) -> bool:
	for term in ["锁定", "解锁", "材质", "符文", "等级", "血量", "扣血"]:
		if text.contains(term):
			return true
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
