extends SceneTree
class_name DebugDiceVisualLibrarySmokeTest


func _init() -> void:
	print("--- DebugDiceVisualLibrarySmokeTest: start ---")

	var all_passed := true
	var library = load("res://scenes/battle/resources/DiceVisualLibrary.tres")

	all_passed = _check("visual library loads", library != null) and all_passed
	if library != null:
		var first_standard = library.get_custom_body_texture(&"standard", 0)
		var sixth_standard = library.get_custom_body_texture(&"standard", 5)
		var unknown_first = library.get_custom_body_texture(&"unknown_body", 0)
		var unknown_sixth = library.get_custom_body_texture(&"unknown_body", 5)

		all_passed = _check("standard body texture exists", first_standard != null) and all_passed
		all_passed = _check("same body id ignores die index", first_standard == sixth_standard) and all_passed
		all_passed = _check("unknown body fallback ignores die index", unknown_first == unknown_sixth) and all_passed

	print("PASS: DebugDiceVisualLibrarySmokeTest" if all_passed else "FAIL: DebugDiceVisualLibrarySmokeTest")
	print("--- DebugDiceVisualLibrarySmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
