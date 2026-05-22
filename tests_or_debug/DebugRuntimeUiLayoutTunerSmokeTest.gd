extends SceneTree
class_name DebugRuntimeUiLayoutTunerSmokeTest


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const MapStageViewScript = preload("res://scripts/ui/map/MapStageView.gd")


func _init() -> void:
	print("--- DebugRuntimeUiLayoutTunerSmokeTest: start ---")
	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var flow := GameFlowController.new()
	root.add_child(flow)
	flow.start_new_run()

	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	battle_screen.setup(flow, flow.get_run_state(), true)
	root.add_child(battle_screen)

	await process_frame
	await process_frame

	var map_view = MapStageViewScript.new()
	map_view.setup(flow, flow.get_map_state())
	battle_screen.attach_map_stage_view(map_view)
	var map_host := battle_screen.get_map_stage_overlay_host() as Control
	if map_host != null:
		map_host.visible = true
	map_view.visible = true
	map_view.modulate.a = 1.0
	await process_frame
	await process_frame

	var snapshot: Dictionary = battle_screen.automation_get_snapshot()
	var tuner := _find_node_by_name(battle_screen, "RuntimeUiLayoutTuner")
	all_passed = _check("runtime UI layout tuner is mounted", bool(snapshot.get("has_runtime_ui_layout_tuner", false)) and tuner != null) and all_passed
	all_passed = _check("runtime UI layout tuner is hidden by default", not bool((snapshot.get("runtime_ui_layout_tuner", {}) as Dictionary).get("visible", true))) and all_passed

	tuner.call("open_tuner")
	await process_frame
	var open_snapshot: Dictionary = tuner.call("automation_get_snapshot")
	all_passed = _check("runtime UI layout tuner opens on demand", bool(open_snapshot.get("visible", false)) and int(open_snapshot.get("candidate_count", 0)) > 0) and all_passed
	all_passed = _check("runtime UI layout tuner buttons show Chinese labels", _tuner_buttons_have_chinese_labels(tuner)) and all_passed
	all_passed = _check("runtime UI layout tuner exposes editor-like modes", _tuner_has_editor_mode_controls(tuner)) and all_passed
	all_passed = _check("runtime UI layout tuner can select tabletop background directly", bool(tuner.call("automation_select_tabletop_background")) and str((tuner.call("automation_get_snapshot") as Dictionary).get("selected_name", "")) == "MapStageTabletopBackgroundTexture") and all_passed

	all_passed = _check("runtime UI layout tuner selects visible control by name", bool(tuner.call("automation_select_control_by_name", "FormalBattleDiceStage3D"))) and all_passed
	var selected := _find_node_by_name(battle_screen, "FormalBattleDiceStage3D") as Control
	var original_rect := selected.get_global_rect() if selected != null else Rect2()
	var tuned_rect := Rect2(original_rect.position + Vector2(12.0, 9.0), original_rect.size + Vector2(80.0, 60.0))
	all_passed = _check("runtime UI layout tuner applies screen rect", bool(tuner.call("automation_set_selected_global_rect", tuned_rect, 333, true))) and all_passed
	await process_frame
	all_passed = _check("runtime UI layout tuner moves real selected control live", _tuner_preview_rect_close(tuner, tuned_rect, 1.0) and _control_rect_close(selected, tuned_rect, 1.0) and selected.z_index == 333) and all_passed
	all_passed = _check("runtime UI layout tuner W drag moves selected control", await _drag_mode_changes_layout(tuner, selected, &"move", Vector2(24.0, 18.0))) and all_passed
	all_passed = _check("runtime UI layout tuner R drag scales selected control", await _drag_mode_changes_layout(tuner, selected, &"scale", Vector2(36.0, 28.0))) and all_passed
	all_passed = _check("runtime UI layout tuner applies rotation live", bool(tuner.call("automation_set_selected_rotation_degrees", 7.5)) and absf(_tuner_preview_rotation(tuner) - 7.5) < 0.01 and absf(selected.rotation_degrees - 7.5) < 0.01) and all_passed
	all_passed = _check("runtime UI layout tuner E drag rotates selected control", await _drag_mode_changes_layout(tuner, selected, &"rotate", Vector2(40.0, 35.0))) and all_passed

	var saved_path := str(tuner.call("automation_save_snapshot", "user://runtime_ui_layout_tuner_smoke.json"))
	all_passed = _check("runtime UI layout tuner saves JSON file", saved_path != "" and FileAccess.file_exists("user://runtime_ui_layout_tuner_smoke.json")) and all_passed
	all_passed = _check("runtime UI layout tuner JSON includes edited and visible snapshots", _saved_json_has_layout_payload("user://runtime_ui_layout_tuner_smoke.json")) and all_passed

	battle_screen.queue_free()
	flow.queue_free()
	await process_frame
	print("PASS: DebugRuntimeUiLayoutTunerSmokeTest" if all_passed else "FAIL: DebugRuntimeUiLayoutTunerSmokeTest")
	print("--- DebugRuntimeUiLayoutTunerSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _saved_json_has_layout_payload(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return false
	var data = json.data
	if not data is Dictionary:
		return false
	var payload := data as Dictionary
	var edited := payload.get("edited", []) as Array
	var visible_snapshot := payload.get("visible_snapshot", []) as Array
	return str(payload.get("format", "")) == "dice_roguelike_runtime_ui_layout_tuning" \
		and not edited.is_empty() \
		and not visible_snapshot.is_empty()


func _control_rect_close(control: Control, expected: Rect2, tolerance: float) -> bool:
	if control == null:
		return false
	var actual := control.get_global_rect()
	return actual.position.distance_to(expected.position) <= tolerance \
		and actual.size.distance_to(expected.size) <= tolerance


func _tuner_preview_rect_close(tuner: Node, expected: Rect2, tolerance: float) -> bool:
	var snapshot: Dictionary = tuner.call("automation_get_snapshot")
	var actual := _dict_to_rect(snapshot.get("selected_preview_rect", {}))
	return actual.position.distance_to(expected.position) <= tolerance \
		and actual.size.distance_to(expected.size) <= tolerance


func _tuner_preview_rotation(tuner: Node) -> float:
	var snapshot: Dictionary = tuner.call("automation_get_snapshot")
	return float(snapshot.get("selected_preview_rotation_degrees", 0.0))


func _dict_to_rect(payload) -> Rect2:
	if not payload is Dictionary:
		return Rect2()
	var data := payload as Dictionary
	return Rect2(
		Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0))),
		Vector2(float(data.get("w", 0.0)), float(data.get("h", 0.0)))
	)


func _tuner_buttons_have_chinese_labels(tuner: Node) -> bool:
	var expected := {
		"RuntimeUiPickButton": "点选控件",
		"RuntimeUiMapBackgroundButton": "选地面背景",
		"RuntimeUiSaveButton": "保存 JSON",
		"RuntimeUiResetButton": "重置选中",
	}
	for button_name in expected.keys():
		var button := _find_node_by_name(tuner, button_name) as Control
		if button == null:
			return false
		var visible_label := _find_node_by_name(button, "VisibleButtonLabel") as Label
		if visible_label == null or visible_label.text != str(expected[button_name]):
			return false
	return _find_node_by_name(tuner, "RuntimeUiField_rot") != null


func _tuner_has_editor_mode_controls(tuner: Node) -> bool:
	var label := _find_node_by_name(tuner, "RuntimeUiEditModeLabel") as Label
	var move_button := _find_node_by_name(tuner, "RuntimeUiMoveModeButton") as Control
	var scale_button := _find_node_by_name(tuner, "RuntimeUiScaleModeButton") as Control
	var rotate_button := _find_node_by_name(tuner, "RuntimeUiRotateModeButton") as Control
	return label != null \
		and _tool_button_label(move_button) == "W 移动" \
		and _tool_button_label(scale_button) == "R 缩放" \
		and _tool_button_label(rotate_button) == "E 旋转"


func _tool_button_label(button: Control) -> String:
	if button == null:
		return ""
	var visible_label := _find_node_by_name(button, "VisibleButtonLabel") as Label
	return visible_label.text if visible_label != null else ""


func _drag_mode_changes_layout(tuner: Node, control: Control, mode: StringName, delta: Vector2) -> bool:
	if tuner == null or control == null:
		return false
	var before_rect := _dict_to_rect((tuner.call("automation_get_snapshot") as Dictionary).get("selected_preview_rect", {}))
	var before_rotation := _tuner_preview_rotation(tuner)
	if not bool(tuner.call("automation_set_edit_mode", mode)):
		return false
	if not bool(tuner.call("automation_drag_selected", delta)):
		return false
	await process_frame
	var after_snapshot: Dictionary = tuner.call("automation_get_snapshot")
	var after_rect := _dict_to_rect(after_snapshot.get("selected_preview_rect", {}))
	match mode:
		&"move":
			var real_after_rect := control.get_global_rect()
			if real_after_rect.position.distance_to(after_rect.position) > 1.0 or real_after_rect.size.distance_to(after_rect.size) > 1.0:
				return false
			return after_rect.position.distance_to(before_rect.position + delta) <= 1.0
		&"scale":
			var real_after_rect := control.get_global_rect()
			if real_after_rect.position.distance_to(after_rect.position) > 1.0 or real_after_rect.size.distance_to(after_rect.size) > 1.0:
				return false
			return after_rect.size.distance_to(before_rect.size + delta) <= 1.0
		&"rotate":
			return absf(float(after_snapshot.get("selected_preview_rotation_degrees", 0.0)) - before_rotation) > 0.01
	return false


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var result := _find_node_by_name(child, node_name)
		if result != null:
			return result
	return null


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
