extends SceneTree
class_name DebugCoreSmokeTest


const DieState = preload("res://scripts/core/dice/DieState.gd")


func _init() -> void:
	print("--- DebugCoreSmokeTest: start ---")

	var dice: Array[DieState] = []

	for die_index in range(6):
		dice.append(DieState.create_normal_d6(StringName("debug_d6_%d" % [die_index + 1])))

	for die_index in range(dice.size()):
		print("Die %d faces: %s" % [die_index + 1, _describe_die(dice[die_index])])

	var original := dice[0]
	var cloned := original.clone()
	cloned.faces[0].pip = 6
	cloned.faces[0].material_id = &"debug_glass"
	cloned.faces[0].level = 2

	print("Original after clone mutation: %s" % [_describe_die(original)])
	print("Clone after mutation: %s" % [_describe_die(cloned)])

	var original_unchanged := original.faces[0].pip == 1 and original.faces[0].material_id == &"" and original.faces[0].level == 1
	print("Clone isolation verified: %s" % [str(original_unchanged)])
	print("--- DebugCoreSmokeTest: end ---")

	quit(0 if original_unchanged else 1)


func _describe_die(die: DieState) -> String:
	var face_texts := PackedStringArray()

	for face_index in range(die.faces.size()):
		var face := die.faces[face_index]
		face_texts.append("#%d pip=%d material=%s mark=%s rune=%s level=%d" % [
			face_index,
			face.pip,
			str(face.material_id),
			str(face.mark_id),
			str(face.rune_id),
			face.level,
		])

	return "[" + ", ".join(face_texts) + "]"
