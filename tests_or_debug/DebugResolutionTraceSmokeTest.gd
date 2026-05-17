extends SceneTree
class_name DebugResolutionTraceSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const ResolutionStep = preload("res://scripts/core/scoring/ResolutionStep.gd")


func _init() -> void:
	print("--- DebugResolutionTraceSmokeTest: start ---")

	var all_passed := true
	all_passed = _check("trace final score matches score engine", test_resolution_trace_final_score_matches_score_engine()) and all_passed
	all_passed = _check("selected dice order is bench order", test_selected_dice_order_is_bench_order()) and all_passed
	all_passed = _check("score is committed once", test_score_is_committed_once()) and all_passed
	all_passed = _check("trace contains combo and pip steps", test_trace_contains_combo_and_pip_steps()) and all_passed
	all_passed = _check("retrigger steps are explicit", test_retrigger_steps_are_explicit()) and all_passed

	print("PASS: DebugResolutionTraceSmokeTest" if all_passed else "FAIL: DebugResolutionTraceSmokeTest")
	print("--- DebugResolutionTraceSmokeTest: end ---")
	quit(0 if all_passed else 1)


func test_resolution_trace_final_score_matches_score_engine() -> bool:
	var engine := ScoreEngine.new()
	var score_result := engine.score(_context_for_rolls([
		_make_roll(0, 0, 4, FaceState.ORN_MULT, FaceState.MARK_RED),
		_make_roll(1, 0, 4),
		_make_roll(2, 0, 2),
	]))
	var trace := ScoreEngine.new().build_resolution_trace(_context_for_rolls([
		_make_roll(0, 0, 4, FaceState.ORN_MULT, FaceState.MARK_RED),
		_make_roll(1, 0, 4),
		_make_roll(2, 0, 2),
	]))
	return trace != null and score_result.final_score == trace.hand_score_final


func test_selected_dice_order_is_bench_order() -> bool:
	var controller := BattleController.new()
	controller.roll_service.rng.seed = 20260517
	controller.start_battle()
	controller.toggle_select(2)
	controller.toggle_select(0)
	var trace = controller.request_settle_selected()
	var passed := trace != null and trace.selected_slot_indices == [0, 2]
	controller.free()
	return passed


func test_score_is_committed_once() -> bool:
	var controller := BattleController.new()
	controller.roll_service.rng.seed = 20260518
	controller.start_battle()
	controller.toggle_select(0)
	var score_before := controller.get_total_score()
	var trace = controller.request_settle_selected()
	if trace == null:
		controller.free()
		return false
	var request_kept_score := controller.get_total_score() == score_before
	controller.commit_pending_resolution()
	var score_after_commit := controller.get_total_score()
	controller.commit_pending_resolution()
	var score_after_second_commit := controller.get_total_score()
	var passed := (
		request_kept_score
		and score_after_commit == score_before + trace.hand_score_final
		and score_after_second_commit == score_after_commit
	)
	controller.free()
	return passed


func test_trace_contains_combo_and_pip_steps() -> bool:
	var trace := ScoreEngine.new().build_resolution_trace(_context_for_rolls([
		_make_roll(0, 0, 1),
		_make_roll(1, 0, 2),
		_make_roll(2, 0, 3),
	]))
	var combo_count := 0
	var pip_count := 0
	for step in trace.steps:
		if step.phase == ResolutionStep.Phase.COMBO_BASE:
			combo_count += 1
		if step.phase == ResolutionStep.Phase.PIP_SCORE:
			pip_count += 1
	return combo_count >= 1 and pip_count == trace.selected_dice.size()


func test_retrigger_steps_are_explicit() -> bool:
	var trace := ScoreEngine.new().build_resolution_trace(_context_for_rolls([
		_make_roll(0, 0, 4, FaceState.ORN_MULT, FaceState.MARK_RED),
		_make_roll(1, 0, 4),
	]))
	for step in trace.steps:
		if step.phase == ResolutionStep.Phase.RETRIGGER and step.retrigger_target_resolution_index >= 0:
			return true
	return false


func _context_for_rolls(rolls: Array) -> ScoreContext:
	var context := ScoreContext.new()
	var typed_rolls: Array[RolledFace] = []
	for roll in rolls:
		if roll is RolledFace:
			typed_rolls.append(roll)
	context.selected_faces = typed_rolls
	context.all_rolled_faces = typed_rolls
	context.rng = FixedRng.new([0.99, 0.99, 0.99, 0.99])
	return context


func _make_roll(
	die_index: int,
	face_index: int,
	pip: int,
	ornament_id: StringName = FaceState.ORN_NONE,
	mark_id: StringName = FaceState.MARK_NONE
) -> RolledFace:
	var face := FaceState.new()
	face.pip = pip
	face.ornament_id = ornament_id
	face.mark_id = mark_id

	var roll := RolledFace.new()
	roll.set_roll(die_index, face_index, face)
	roll.selected = true
	return roll


class FixedRng:
	extends RefCounted

	var values: Array = []

	func _init(new_values: Array) -> void:
		values = new_values.duplicate()

	func randf() -> float:
		if values.is_empty():
			return 0.99
		return values.pop_front()


func _check(label: String, passed: bool) -> bool:
	var status: String = "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
