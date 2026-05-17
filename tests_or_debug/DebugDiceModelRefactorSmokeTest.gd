extends SceneTree
class_name DebugDiceModelRefactorSmokeTest


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")


func _init() -> void:
	print("--- DebugDiceModelRefactorSmokeTest: start ---")

	var all_passed := true

	all_passed = _check("valid face counts are D4/D6/D8", DieState.VALID_FACE_COUNTS == [4, 6, 8]) and all_passed
	for pip in range(1, 9):
		all_passed = _check("pip_%d maps to %d" % [pip, pip], DieState.pip_id_to_value(StringName("pip_%d" % [pip])) == pip) and all_passed
	all_passed = _check("low domain pips are 1..4", DieState.LOW_DOMAIN_PIPS == [1, 2, 3, 4]) and all_passed
	all_passed = _check("high domain pips are 5..8", DieState.HIGH_DOMAIN_PIPS == [5, 6, 7, 8]) and all_passed

	var face := FaceState.new()
	all_passed = _check("FaceState default pip", face.pip == 1) and all_passed
	all_passed = _check("FaceState default ornament", face.ornament_id == &"orn_none") and all_passed
	all_passed = _check("FaceState default mark", face.mark_id == &"mark_none") and all_passed
	var custom_face := FaceState.new(8, &"orn_chip", &"red")
	all_passed = _check("FaceState constructor accepts legal pip and slots", custom_face.pip == 8 and custom_face.ornament_id == &"orn_chip" and custom_face.mark_id == &"mark_red") and all_passed

	var die := DieState.create_normal_d6(&"smoke_d6")
	all_passed = _check("create_normal_d6 die_id", die.die_id == &"smoke_d6") and all_passed
	all_passed = _check("create_normal_d6 face_count", die.face_count == 6) and all_passed
	all_passed = _check("create_normal_d6 body", DieState.normalize_body_id(die.body_id) == DieState.BODY_STANDARD) and all_passed
	all_passed = _check("create_normal_d6 faces", die.faces.size() == 6) and all_passed
	all_passed = _check("create_normal_d6 weights size", die.face_weights.size() == 6) and all_passed
	all_passed = _check("create_normal_d6 weights are 1", _all_weights_are_one(die)) and all_passed
	all_passed = _check("create_normal_d6 has valid shape", die.has_valid_shape()) and all_passed

	die.set_face_pip(0, 8)
	all_passed = _check("set_face_pip writes faces[index].pip", die.faces[0].pip == 8) and all_passed
	die.set_face_pip(0, 1)

	die.body_id = DieState.BODY_IRON
	die.face_count = 6
	die.face_weights[0] = 3
	die.faces[0].ornament_id = &"orn_chip"
	die.faces[0].mark_id = &"mark_red"
	var cloned := die.clone()
	cloned.body_id = DieState.BODY_GLASS
	cloned.face_count = 8
	cloned.face_weights[0] = 9
	cloned.faces[0].pip = 6
	cloned.faces[0].ornament_id = &"orn_burst"
	cloned.faces[0].mark_id = &"mark_blue"
	all_passed = _check("clone copies die fields", cloned.id == die.id and cloned.face_weights.size() == die.face_weights.size() and cloned.faces.size() == die.faces.size()) and all_passed
	all_passed = _check("clone mutation does not affect original", DieState.normalize_body_id(die.body_id) == DieState.BODY_IRON and die.face_count == 6 and die.face_weights[0] == 3 and die.faces[0].pip == 1 and die.faces[0].ornament_id == &"orn_chip" and die.faces[0].mark_id == &"mark_red") and all_passed

	var invalid_shape := die.clone()
	invalid_shape.face_count = 8
	all_passed = _check("faces size must match face_count", not invalid_shape.has_valid_shape()) and all_passed
	invalid_shape = die.clone()
	invalid_shape.face_weights.remove_at(0)
	all_passed = _check("weights size must match face_count when weights are used", not invalid_shape.has_valid_shape()) and all_passed

	var legacy := FaceState.new()
	legacy.material_id = &"glass"
	all_passed = _check("legacy glass maps to burst", legacy.get_effective_ornament_id() == &"orn_burst") and all_passed
	legacy.material_id = &"steel"
	all_passed = _check("legacy steel maps to stay", legacy.get_effective_ornament_id() == &"orn_stay") and all_passed
	all_passed = _check("orn_negative is rejected for face slot", not FaceState.is_valid_face_ornament_id(&"orn_negative")) and all_passed

	print("PASS: DebugDiceModelRefactorSmokeTest" if all_passed else "FAIL: DebugDiceModelRefactorSmokeTest")
	print("--- DebugDiceModelRefactorSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _all_weights_are_one(die: DieState) -> bool:
	for weight in die.face_weights:
		if weight != 1:
			return false
	return true


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
