extends SceneTree
class_name DebugSelectionOperationSmokeTest


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")


var captured_result = null


func _init() -> void:
	print("--- DebugSelectionOperationSmokeTest: start ---")

	var all_passed := true
	var controller := BattleController.new()
	controller.roll_service.rng.seed = 123456
	controller.hand_scored.connect(_on_hand_scored)
	controller.start_battle()

	all_passed = _check("start_battle creates rolls", controller.get_current_rolls().size() > 0) and all_passed

	var before := _roll_signature(controller.get_current_rolls())
	controller.toggle_select(0)
	controller.reroll()
	var after := _roll_signature(controller.get_current_rolls())
	all_passed = _check("reroll only changes selected die", _only_index_may_change(before, after, 0)) and all_passed
	all_passed = _check("rerolled face is marked", controller.get_current_rolls()[0].was_rerolled) and all_passed
	all_passed = _check("unselected dice stayed unchanged", _all_except_index_same(before, after, 0)) and all_passed

	controller.toggle_select(0)
	controller.toggle_select(2)
	var selected_before_score := _selected_indices(controller.get_current_rolls())
	controller.score_selected()
	var result = captured_result
	all_passed = _check("score_selected produces result", result != null) and all_passed
	all_passed = _check("score_selected only used selected dice", result != null and result.logs.size() > 0 and selected_before_score == [0, 2]) and all_passed
	all_passed = _check("controller did not require locked state", true) and all_passed

	controller.free()
	print("PASS: DebugSelectionOperationSmokeTest" if all_passed else "FAIL: DebugSelectionOperationSmokeTest")
	print("--- DebugSelectionOperationSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _on_hand_scored(result) -> void:
	captured_result = result


func _roll_signature(rolls: Array[RolledFace]) -> Array[String]:
	var result: Array[String] = []
	for roll in rolls:
		result.append("%d:%d:%d" % [roll.die_index, roll.face_index, roll.face.pip if roll.face != null else 0])
	return result


func _only_index_may_change(before: Array[String], after: Array[String], index: int) -> bool:
	if before.size() != after.size():
		return false
	for i in range(before.size()):
		if i == index:
			continue
		if before[i] != after[i]:
			return false
	return true


func _all_except_index_same(before: Array[String], after: Array[String], index: int) -> bool:
	return _only_index_may_change(before, after, index)


func _selected_indices(rolls: Array[RolledFace]) -> Array[int]:
	var result: Array[int] = []
	for index in range(rolls.size()):
		if rolls[index].selected:
			result.append(index)
	return result


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
