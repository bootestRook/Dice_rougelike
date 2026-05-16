extends SceneTree
class_name DebugFaceDisplaySmokeTest


const DieState = preload("res://scripts/core/dice/DieState.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")


func _init() -> void:
	print("--- DebugFaceDisplaySmokeTest: start ---")

	var all_passed := true
	var face := FaceState.new()
	face.pip = 6
	face.ornament_id = &"orn_burst"
	face.mark_id = &"red"
	face.rune_id = &"six"
	face.level = 2

	var summary := DisplayNames.face_summary(face)
	print(summary)
	all_passed = _check("summary contains pip", summary.contains("6")) and all_passed
	all_passed = _check("summary contains ornament", summary.contains("爆裂面饰")) and all_passed
	all_passed = _check("summary contains mark", summary.contains("红印")) and all_passed
	all_passed = _check("summary hides removed slots", not _contains_removed_terms(summary)) and all_passed

	var detail := DisplayNames.face_detail_text(face)
	print(detail)
	all_passed = _check("detail contains ornament effect", detail.contains("被结算时，终倍率 ×2")) and all_passed
	all_passed = _check("detail contains red mark effect", detail.contains("被结算时，该面额外触发一次。")) and all_passed
	all_passed = _check("detail hides removed slots", not _contains_removed_terms(detail)) and all_passed
	all_passed = _check("summary hides internal ids", not _contains_internal_id(summary)) and all_passed
	all_passed = _check("detail hides internal ids", not _contains_internal_id(detail)) and all_passed

	var legacy_face := FaceState.new()
	legacy_face.pip = 3
	legacy_face.material_id = &"glass"
	var legacy_summary := DisplayNames.face_summary(legacy_face)
	all_passed = _check("legacy material displays as ornament", legacy_summary.contains("爆裂面饰") and not legacy_summary.contains("玻璃")) and all_passed

	var die := DieState.create_normal_d6(&"display_d6")
	die.faces[2].ornament_id = &"orn_burst"
	die.faces[5].mark_id = &"red"
	var die_summary := DisplayNames.die_summary(die)
	print(die_summary)
	all_passed = _check("die summary contains body and face count", die_summary.contains("骰胚：标准骰胚") and die_summary.contains("面数：D6")) and all_passed
	all_passed = _check("die summary contains face ornament and mark", die_summary.contains("面 3：3 / 面饰：爆裂面饰") and die_summary.contains("面 6：6 / 印记：红印")) and all_passed
	all_passed = _check("die summary hides removed slots", not _contains_removed_terms(die_summary)) and all_passed

	print("PASS: DebugFaceDisplaySmokeTest" if all_passed else "FAIL: DebugFaceDisplaySmokeTest")
	print("--- DebugFaceDisplaySmokeTest: end ---")
	quit(0 if all_passed else 1)


func _contains_internal_id(text: String) -> bool:
	for id in ["glass", "steel", "material_id", "mark_id", "rune_id", "rune_six"]:
		if text.contains(id):
			return true
	return false


func _contains_removed_terms(text: String) -> bool:
	for term in ["材质", "符文", "等级", "material", "rune", "level", "glass", "steel"]:
		if text.contains(term):
			return true
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
