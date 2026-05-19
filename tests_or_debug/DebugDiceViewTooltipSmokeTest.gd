extends SceneTree
class_name DebugDiceViewTooltipSmokeTest


const DieState = preload("res://scripts/core/dice/DieState.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")


func _init() -> void:
	print("--- DebugDiceViewTooltipSmokeTest: start ---")

	var all_passed := true
	var scene := load("res://scenes/battle/components/DiceView.tscn")
	var view = scene.instantiate()
	root.add_child(view)

	await process_frame
	await process_frame

	var die := DieState.create_normal_d6(&"test_die")
	var data := DieViewData.new()
	data.setup_from_die(die, 0, null, true, false, false)
	view.render(data, null, null, null)
	await process_frame

	all_passed = _check("dice view does not expose native tooltip", view is Control and (view as Control).tooltip_text == "") and all_passed

	view.render(null, null, null, null)
	await process_frame
	all_passed = _check("empty dice view clears native tooltip", view is Control and (view as Control).tooltip_text == "") and all_passed

	view.queue_free()
	print("PASS: DebugDiceViewTooltipSmokeTest" if all_passed else "FAIL: DebugDiceViewTooltipSmokeTest")
	print("--- DebugDiceViewTooltipSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
