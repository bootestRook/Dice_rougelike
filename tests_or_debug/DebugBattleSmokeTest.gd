extends SceneTree
class_name DebugBattleSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")


func _init() -> void:
	print("--- DebugBattleSmokeTest: start ---")

	var controller := BattleController.new()
	controller.roll_service.rng.seed = 12345
	controller.start_battle()

	var all_passed := true
	all_passed = _check("start_battle creates 6 rolls", controller.get_current_rolls().size() == 6) and all_passed

	var before_reroll := _face_indexes(controller.get_current_rolls())
	controller.toggle_lock(0)
	var locked_before := before_reroll[0]
	controller.reroll()
	var after_reroll := _face_indexes(controller.get_current_rolls())
	var locked_kept := after_reroll[0] == locked_before and controller.get_current_rolls()[0].locked
	var unlocked_changed := _any_unlocked_changed(before_reroll, after_reroll)
	all_passed = _check("locked die stays unchanged after reroll", locked_kept) and all_passed
	all_passed = _check("at least one unlocked die changes after reroll", unlocked_changed) and all_passed

	for index in range(6):
		controller.toggle_select(index)

	var selected_count := _selected_count(controller.get_current_rolls())
	all_passed = _check("selection does not exceed 5", selected_count == 5) and all_passed

	var score_before := controller.get_total_score()
	controller.score_selected()
	var score_after := controller.get_total_score()
	all_passed = _check("score_selected increases total score", score_after > score_before) and all_passed

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


func _any_unlocked_changed(before: Array[int], after: Array[int]) -> bool:
	for index in range(1, min(before.size(), after.size())):
		if before[index] != after[index]:
			return true

	return false


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
