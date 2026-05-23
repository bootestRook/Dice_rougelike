extends SceneTree
class_name DebugGmDiceHoverOrientationSmokeTest


const GmDiceCtrlScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceCtrl.gd")


func _init() -> void:
	print("--- DebugGmDiceHoverOrientationSmokeTest: start ---")
	var all_passed := true
	var dice := GmDiceCtrlScript.new() as GmDiceCtrl
	for face_index in range(6):
		var basis: Basis = dice.call("_hover_presentation_basis", face_index)
		var top_normal := (basis * _face_normal_local(face_index)).normalized()
		var number_up := _project_horizontal(basis * _texture_number_up_local(face_index))
		all_passed = _check(
			"face %d returns to top in hover pose" % face_index,
			top_normal.dot(Vector3.UP) >= 0.995
		) and all_passed
		all_passed = _check(
			"face %d keeps top number upright after hover return" % face_index,
			number_up.dot(Vector3.FORWARD) >= 0.995
		) and all_passed
	dice.free()
	print("PASS: DebugGmDiceHoverOrientationSmokeTest" if all_passed else "FAIL: DebugGmDiceHoverOrientationSmokeTest")
	print("--- DebugGmDiceHoverOrientationSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _face_normal_local(face_index: int) -> Vector3:
	match clampi(face_index, 0, 5):
		0:
			return Vector3.UP
		1:
			return Vector3.DOWN
		2:
			return Vector3.FORWARD
		3:
			return Vector3.BACK
		4:
			return Vector3.RIGHT
		5:
			return Vector3.LEFT
	return Vector3.UP


func _texture_number_up_local(face_index: int) -> Vector3:
	match clampi(face_index, 0, 5):
		0, 1:
			return Vector3.BACK
		_:
			return Vector3.UP


func _project_horizontal(vector: Vector3) -> Vector3:
	var projected := vector - Vector3.UP * vector.dot(Vector3.UP)
	if projected.length_squared() <= 0.0001:
		return Vector3.ZERO
	return projected.normalized()


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
