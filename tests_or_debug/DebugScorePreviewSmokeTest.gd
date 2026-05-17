extends SceneTree
class_name DebugScorePreviewSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
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

	var foil_run := RunState.new()
	foil_run.setup_new_run()
	_set_all_faces_ornament(foil_run, 0, &"orn_foil")
	var foil_controller := BattleController.new()
	foil_controller.roll_service.rng.seed = 98765
	foil_controller.start_battle(null, foil_run)
	foil_controller.toggle_select(0)
	var foil_preview := foil_controller.preview_selected_score()
	var foil_preview_expected_chips := 0
	if foil_preview != null:
		foil_preview_expected_chips = foil_preview.scored_point_sum + foil_preview.combo_chips_bonus
	var foil_preview_ok: bool = (
		foil_preview != null
		and foil_preview.chips == foil_preview_expected_chips
		and not _logs_contain(foil_preview, "ornament_foil")
	)
	all_passed = _check("foil preview skips selected ornament settlement effect", foil_preview_ok) and all_passed
	var foil_trace = foil_controller.request_settle_selected()
	var foil_settlement_ok: bool = (
		foil_trace != null
		and foil_trace.score_result != null
		and foil_trace.score_result.chips == foil_preview_expected_chips + 50
		and _logs_contain(foil_trace.score_result, "ornament_foil")
	)
	all_passed = _check("foil settlement still applies selected ornament effect", foil_settlement_ok) and all_passed
	foil_controller.free()

	var poly_run := RunState.new()
	poly_run.setup_new_run()
	_set_all_faces_ornament(poly_run, 0, &"orn_poly")
	var poly_controller := BattleController.new()
	poly_controller.roll_service.rng.seed = 97531
	poly_controller.start_battle(null, poly_run)
	poly_controller.toggle_select(0)
	var poly_preview := poly_controller.preview_selected_score()
	var poly_preview_ok: bool = (
		poly_preview != null
		and is_equal_approx(poly_preview.xmult, 1.0)
		and not _logs_contain(poly_preview, "ornament_poly")
	)
	all_passed = _check("poly preview keeps xmult at 1", poly_preview_ok) and all_passed
	var poly_trace = poly_controller.request_settle_selected()
	var poly_settlement_ok: bool = (
		poly_trace != null
		and is_equal_approx(poly_trace.xmult_final, 2.0)
		and _logs_contain(poly_trace.score_result, "ornament_poly")
	)
	all_passed = _check("poly settlement applies xmult effect", poly_settlement_ok) and all_passed
	poly_controller.free()

	var red_run := RunState.new()
	red_run.setup_new_run()
	_set_all_faces_mark(red_run, 0, &"mark_red")
	var red_controller := BattleController.new()
	red_controller.roll_service.rng.seed = 75319
	red_controller.start_battle(null, red_run)
	red_controller.toggle_select(0)
	var red_preview := red_controller.preview_selected_score()
	var red_preview_expected_chips := 0
	if red_preview != null:
		red_preview_expected_chips = red_preview.scored_point_sum + red_preview.combo_chips_bonus
	var red_preview_ok: bool = (
		red_preview != null
		and red_preview.chips == red_preview_expected_chips
		and not _logs_contain(red_preview, "mark_red")
		and not _logs_contain(red_preview, "extra_pip")
	)
	all_passed = _check("red mark preview skips retrigger", red_preview_ok) and all_passed
	var red_trace = red_controller.request_settle_selected()
	var red_settlement_ok: bool = (
		red_trace != null
		and red_trace.score_result != null
		and red_trace.score_result.chips > red_preview_expected_chips
		and _logs_contain(red_trace.score_result, "mark_red")
		and _logs_contain(red_trace.score_result, "extra_pip")
	)
	all_passed = _check("red mark settlement applies retrigger", red_settlement_ok) and all_passed
	red_controller.free()

	var stay_run := RunState.new()
	stay_run.setup_new_run()
	_set_all_faces_ornament(stay_run, 1, &"orn_stay")
	var stay_controller := BattleController.new()
	stay_controller.roll_service.rng.seed = 86420
	stay_controller.start_battle(null, stay_run)
	stay_controller.toggle_select(0)
	var stay_preview := stay_controller.preview_selected_score()
	var stay_preview_ok: bool = (
		stay_preview != null
		and is_equal_approx(stay_preview.xmult, 1.0)
		and not _logs_contain(stay_preview, "ornament_stay")
	)
	all_passed = _check("stay preview skips unselected settlement effect", stay_preview_ok) and all_passed
	var stay_trace = stay_controller.request_settle_selected()
	var stay_settlement_ok: bool = (
		stay_trace != null
		and is_equal_approx(stay_trace.xmult_final, 2.0)
		and _logs_contain(stay_trace.score_result, "ornament_stay")
	)
	all_passed = _check("stay settlement applies unselected effect", stay_settlement_ok) and all_passed
	stay_controller.free()

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


func _set_all_faces_ornament(run_state: RunState, die_index: int, ornament_id: StringName) -> void:
	if run_state == null or die_index < 0 or die_index >= run_state.dice.size():
		return
	var die = run_state.dice[die_index]
	if die == null:
		return
	for face in die.faces:
		if face != null:
			face.ornament_id = ornament_id


func _set_all_faces_mark(run_state: RunState, die_index: int, mark_id: StringName) -> void:
	if run_state == null or die_index < 0 or die_index >= run_state.dice.size():
		return
	var die = run_state.dice[die_index]
	if die == null:
		return
	for face in die.faces:
		if face != null:
			face.mark_id = mark_id


func _logs_contain(result: ScoreResult, needle: String) -> bool:
	if result == null:
		return false
	for entry in result.logs:
		if str(entry.key).find(needle) >= 0 or str(entry.category).find(needle) >= 0:
			return true
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
