extends SceneTree
class_name DebugBattleSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


func _init() -> void:
	print("--- DebugBattleSmokeTest: start ---")

	var controller := BattleController.new()
	controller.roll_service.rng.seed = 12345
	controller.start_battle()

	var all_passed := true
	all_passed = _check("start_battle creates 6 rolls", controller.get_current_rolls().size() == 6) and all_passed

	var before_reroll := _face_indexes(controller.get_current_rolls())
	controller.toggle_select(0)
	controller.reroll()
	var after_reroll := _face_indexes(controller.get_current_rolls())
	var unselected_kept := _all_unselected_kept(before_reroll, after_reroll)
	var selection_cleared := _selected_count(controller.get_current_rolls()) == 0
	all_passed = _check("unselected dice stay unchanged after selected reroll", unselected_kept) and all_passed
	all_passed = _check("selection clears after reroll", selection_cleared) and all_passed

	for index in range(5):
		controller.toggle_select(index)

	var selected_count := _selected_count(controller.get_current_rolls())
	all_passed = _check("selection reaches max selection", selected_count == 5) and all_passed
	all_passed = _check("score is enabled at max selection", controller.can_score()) and all_passed
	controller.toggle_select(5)
	selected_count = _selected_count(controller.get_current_rolls())
	all_passed = _check("selection can exceed max for rerolling", selected_count == 6) and all_passed
	all_passed = _check("score is disabled above max selection", not controller.can_score()) and all_passed
	all_passed = _check("reroll is enabled above max selection", controller.can_reroll()) and all_passed
	controller.toggle_select(5)

	var score_before := controller.get_total_score()
	controller.score_selected()
	var score_after := controller.get_total_score()
	all_passed = _check("score_selected increases total score", score_after > score_before) and all_passed
	all_passed = _check("purple mark generates once per face per battle", _purple_mark_generates_once_per_face_per_battle()) and all_passed
	all_passed = _check("purple mark no-slot does not consume face generation", _purple_mark_no_slot_does_not_consume_generation()) and all_passed

	while controller.get_phase() == BattleController.BattlePhase.WAITING_ACTION:
		_select_first_count(controller, 5)
		controller.score_selected()

	var finished := controller.get_phase() == BattleController.BattlePhase.VICTORY or controller.get_phase() == BattleController.BattlePhase.DEFEAT
	all_passed = _check("battle reaches victory or defeat within 4 hands", finished) and all_passed

	print("Final phase: %s" % [_phase_name(controller.get_phase())])
	print("Final score: %d / %d" % [controller.get_total_score(), controller.get_target_score()])
	print("--- DebugBattleSmokeTest: end ---")

	var exit_code := 0
	if not all_passed:
		exit_code = 1
	controller.free()
	quit(exit_code)


func _face_indexes(rolls: Array[RolledFace]) -> Array[int]:
	var result: Array[int] = []

	for roll in rolls:
		result.append(roll.face_index)

	return result


func _all_unselected_kept(before: Array[int], after: Array[int]) -> bool:
	for index in range(1, min(before.size(), after.size())):
		if before[index] != after[index]:
			return false

	return true


func _selected_count(rolls: Array[RolledFace]) -> int:
	var count := 0

	for roll in rolls:
		if roll.selected:
			count += 1

	return count


func _select_first_count(controller: BattleController, count: int) -> void:
	var rolls := controller.get_current_rolls()
	for index in range(min(count, rolls.size())):
		if not rolls[index].selected:
			controller.toggle_select(index)


func _purple_mark_generates_once_per_face_per_battle() -> bool:
	var run_state := RunState.new()
	run_state.ensure_starting_dice()
	run_state.item_slots.clear()
	run_state.item_ids.clear()
	run_state.item_slot_capacity = 3

	var controller := BattleController.new()
	controller.start_battle(null, run_state)
	var roll := controller.get_current_rolls()[0] as RolledFace
	roll.face.mark_id = FaceState.MARK_PURPLE
	roll.selected = true
	controller._trigger_purple_marks_before_reroll()
	var first_count := run_state.item_slots.size()
	var triggered_once := bool(controller.battle_state.purple_mark_triggered_this_battle.get(controller._face_instance_id_for_roll(roll), false))
	controller._trigger_purple_marks_before_reroll()
	var second_count := run_state.item_slots.size()
	controller.free()
	return first_count == 1 and second_count == 1 and triggered_once


func _purple_mark_no_slot_does_not_consume_generation() -> bool:
	var run_state := RunState.new()
	run_state.ensure_starting_dice()
	run_state.item_slots.clear()
	run_state.item_ids.clear()
	run_state.item_slot_capacity = 0

	var controller := BattleController.new()
	controller.start_battle(null, run_state)
	var roll := controller.get_current_rolls()[0] as RolledFace
	roll.face.mark_id = FaceState.MARK_PURPLE
	roll.selected = true
	controller._trigger_purple_marks_before_reroll()
	var triggered := bool(controller.battle_state.purple_mark_triggered_this_battle.get(controller._face_instance_id_for_roll(roll), false))
	var item_count := run_state.item_slots.size()
	controller.free()
	return item_count == 0 and not triggered


func _check(label: String, passed: bool) -> bool:
	print("%s: %s" % [label, str(passed)])
	return passed


func _phase_name(phase: int) -> String:
	match phase:
		BattleController.BattlePhase.INIT:
			return "INIT"
		BattleController.BattlePhase.WAITING_ACTION:
			return "WAITING_ACTION"
		BattleController.BattlePhase.SCORING:
			return "SCORING"
		BattleController.BattlePhase.VICTORY:
			return "VICTORY"
		BattleController.BattlePhase.DEFEAT:
			return "DEFEAT"
		_:
			return "UNKNOWN"
