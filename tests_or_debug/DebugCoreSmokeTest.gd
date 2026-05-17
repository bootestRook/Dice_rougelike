extends SceneTree
class_name DebugCoreSmokeTest


const DieState = preload("res://scripts/core/dice/DieState.gd")


func _init() -> void:
	print("--- DebugCoreSmokeTest: start ---")

	var dice: Array[DieState] = []
	for die_index in range(6):
		dice.append(DieState.create_normal_d6(StringName("debug_d6_%d" % [die_index + 1])))

	var all_passed := true
	all_passed = _check("creates 6 dice", dice.size() == 6) and all_passed
	all_passed = _check("normal d6 has face_count 6", dice[0].face_count == 6) and all_passed
	all_passed = _check("normal d6 has standard body", DieState.normalize_body_id(dice[0].body_id) == DieState.BODY_STANDARD) and all_passed
	all_passed = _check("normal d6 has 6 weights", dice[0].face_weights.size() == 6) and all_passed

	var original := dice[0]
	var cloned := original.clone()
	cloned.body_id = &"iron"
	cloned.face_count = 8
	cloned.face_weights[0] = 9
	cloned.faces[0].pip = 6
	cloned.faces[0].ornament_id = &"orn_burst"
	cloned.faces[0].mark_id = &"red"

	all_passed = _check("clone mutation does not change original pip", original.faces[0].pip == 1) and all_passed
	all_passed = _check("clone mutation does not change original ornament", original.faces[0].ornament_id == &"orn_none") and all_passed
	all_passed = _check("clone mutation does not change original mark", original.faces[0].mark_id == &"mark_none") and all_passed
	all_passed = _check("clone mutation does not change original die fields", DieState.normalize_body_id(original.body_id) == DieState.BODY_STANDARD and original.face_count == 6 and original.face_weights[0] == 1) and all_passed

	print("Original: %s" % [_describe_die(original)])
	print("Clone: %s" % [_describe_die(cloned)])
	print("PASS: DebugCoreSmokeTest" if all_passed else "FAIL: DebugCoreSmokeTest")
	print("--- DebugCoreSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _describe_die(die: DieState) -> String:
	var face_texts := PackedStringArray()

	for face_index in range(die.faces.size()):
		var face := die.faces[face_index]
		face_texts.append("#%d pip=%d ornament=%s mark=%s" % [
			face_index,
			face.pip,
			str(face.ornament_id),
			str(face.mark_id),
		])

	return "body=%s face_count=%d weights=%s faces=[%s]" % [
		str(die.body_id),
		die.face_count,
		str(die.face_weights),
		", ".join(face_texts),
	]


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
