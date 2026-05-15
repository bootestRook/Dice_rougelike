extends SceneTree
class_name DebugScorePreviewSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


var captured_result: ScoreResult = null


func _init() -> void:
	print("--- DebugScorePreviewSmokeTest: start ---")

	var all_passed := true
	var controller := BattleController.new()
	controller.roll_service.rng.seed = 424242
	controller.hand_scored.connect(_on_hand_scored)
	controller.start_battle()
	controller.toggle_select(0)

	var preview := controller.preview_selected_score()
	all_passed = _check("preview is not null after selecting a die", preview != null) and all_passed

	var total_before := controller.get_total_score()
	var hand_before := controller.get_current_hand_number()
	var rerolls_before := controller.get_rerolls_left()
	var phase_before := controller.get_phase()
	var selected_before := _selected_count(controller)

	var preview_again := controller.preview_selected_score()
	all_passed = _check("second preview is not null", preview_again != null) and all_passed
	all_passed = _check("preview final is stable", preview.final_score == preview_again.final_score) and all_passed
	all_passed = _check("preview does not change total_score", controller.get_total_score() == total_before) and all_passed
	all_passed = _check("preview does not change hand", controller.get_current_hand_number() == hand_before) and all_passed
	all_passed = _check("preview does not change rerolls", controller.get_rerolls_left() == rerolls_before) and all_passed
	all_passed = _check("preview does not change phase", controller.get_phase() == phase_before) and all_passed
	all_passed = _check("preview does not change selection", _selected_count(controller) == selected_before) and all_passed

	controller.score_selected()
	all_passed = _check("score_selected emitted result", captured_result != null) and all_passed
	if captured_result != null and preview != null:
		all_passed = _check("actual final matches preview final", captured_result.final_score == preview.final_score) and all_passed
	all_passed = _check("score_selected increases total score", controller.get_total_score() > total_before) and all_passed

	if all_passed:
		print("PASS: DebugScorePreviewSmokeTest")
	else:
		print("FAIL: DebugScorePreviewSmokeTest")

	controller.free()
	print("--- DebugScorePreviewSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _on_hand_scored(result: ScoreResult) -> void:
	captured_result = result


func _selected_count(controller: BattleController) -> int:
	var count := 0
	for roll in controller.get_current_rolls():
		if roll.selected:
			count += 1
	return count


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
