extends SceneTree
class_name DebugGmProjectedUiBoardSmokeTest


func _init() -> void:
	print("--- DebugGmProjectedUiBoardSmokeTest: start ---")
	var all_passed := true

	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	var scene := load("res://scenes/debug/GmPhysicsDiceTestScreen.tscn")
	all_passed = _check("gm scene loads", scene != null) and all_passed
	if scene == null:
		print("FAIL: DebugGmProjectedUiBoardSmokeTest")
		quit(1)
		return

	var screen = scene.instantiate()
	root.add_child(screen)

	await process_frame
	await process_frame
	await process_frame

	var snapshot: Dictionary = screen.call("automation_get_snapshot")
	var board_snapshot: Dictionary = snapshot.get("projected_ui_board", {})
	all_passed = _check("projected ui board is ready", bool(snapshot.get("projected_ui_board_ready", false))) and all_passed
	all_passed = _check("projected ui board is visible by default", bool(snapshot.get("projected_ui_board_visible", false))) and all_passed
	all_passed = _check("projected ui board starts in floating mode", not bool(snapshot.get("projected_ui_board_flat", true))) and all_passed
	all_passed = _check("projected ui board exposes three separate components", int(board_snapshot.get("panel_count", 0)) == 3) and all_passed
	all_passed = _check("projected left info component is ready", bool(board_snapshot.get("left_info_ready", false))) and all_passed
	all_passed = _check("projected relic bar component is ready", bool(board_snapshot.get("relic_bar_ready", false))) and all_passed
	all_passed = _check("projected item bar component is ready", bool(board_snapshot.get("item_bar_ready", false))) and all_passed
	all_passed = _check("projected ui board uses real control trees", int(board_snapshot.get("control_count", 0)) >= 34) and all_passed
	all_passed = _check("projected ui board contains real checkbox control", bool(board_snapshot.get("real_checkbox_exists", false))) and all_passed
	all_passed = _check("left info viewport node exists", _find_node_by_name(screen, "ProjectedLeftInfoPanel3DViewport") != null) and all_passed
	all_passed = _check("relic bar viewport node exists", _find_node_by_name(screen, "ProjectedRelicBarPanel3DViewport") != null) and all_passed
	all_passed = _check("item bar viewport node exists", _find_node_by_name(screen, "ProjectedItemBarPanel3DViewport") != null) and all_passed
	all_passed = _check("left info mesh node exists", _find_node_by_name(screen, "ProjectedLeftInfoPanel3DPlane") != null) and all_passed
	all_passed = _check("relic bar mesh node exists", _find_node_by_name(screen, "ProjectedRelicBarPanel3DPlane") != null) and all_passed
	all_passed = _check("item bar mesh node exists", _find_node_by_name(screen, "ProjectedItemBarPanel3DPlane") != null) and all_passed
	all_passed = _check("left info edge thickness exists", _find_node_by_name(screen, "ProjectedLeftInfoPanel3DFrontRail") != null and _find_node_by_name(screen, "ProjectedLeftInfoPanel3DBackPlate") != null) and all_passed
	all_passed = _check("relic bar edge thickness exists", _find_node_by_name(screen, "ProjectedRelicBarPanel3DFrontRail") != null and _find_node_by_name(screen, "ProjectedRelicBarPanel3DBackPlate") != null) and all_passed
	all_passed = _check("item bar edge thickness exists", _find_node_by_name(screen, "ProjectedItemBarPanel3DFrontRail") != null and _find_node_by_name(screen, "ProjectedItemBarPanel3DBackPlate") != null) and all_passed

	var visible_check := _find_node_by_name(screen, "ProjectedUiBoardVisibleCheck") as CheckBox
	var flat_check := _find_node_by_name(screen, "ProjectedUiBoardFlatCheck") as CheckBox
	all_passed = _check("hud visible checkbox exists", visible_check != null and visible_check.button_pressed) and all_passed
	all_passed = _check("hud flat checkbox exists", flat_check != null and not flat_check.button_pressed) and all_passed

	if visible_check != null:
		visible_check.set_pressed_no_signal(false)
		visible_check.toggled.emit(false)
		await process_frame
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("hud checkbox hides projected board", not bool(snapshot.get("projected_ui_board_visible", true))) and all_passed

		visible_check.set_pressed_no_signal(true)
		visible_check.toggled.emit(true)
		await process_frame
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("hud checkbox shows projected board", bool(snapshot.get("projected_ui_board_visible", false))) and all_passed

	if flat_check != null:
		flat_check.set_pressed_no_signal(true)
		flat_check.toggled.emit(true)
		await process_frame
		snapshot = screen.call("automation_get_snapshot")
		board_snapshot = snapshot.get("projected_ui_board", {})
		all_passed = _check("hud checkbox lays projected components into scene", bool(snapshot.get("projected_ui_board_flat", false)) and _all_panels_laid_on_table(board_snapshot)) and all_passed
		all_passed = _check("flat projected components keep visible thickness", _all_panels_have_thickness(board_snapshot)) and all_passed
		all_passed = _check("flat projected components use tabletop yaw rotation", _flat_panels_have_yaw(board_snapshot)) and all_passed

		flat_check.set_pressed_no_signal(false)
		flat_check.toggled.emit(false)
		await process_frame
		snapshot = screen.call("automation_get_snapshot")
		board_snapshot = snapshot.get("projected_ui_board", {})
		all_passed = _check("hud checkbox returns projected components to floating mode", not bool(snapshot.get("projected_ui_board_flat", true)) and _all_panels_float_above_table(board_snapshot)) and all_passed

	root.remove_child(screen)
	screen.free()
	print("PASS: DebugGmProjectedUiBoardSmokeTest" if all_passed else "FAIL: DebugGmProjectedUiBoardSmokeTest")
	print("--- DebugGmProjectedUiBoardSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _all_panels_laid_on_table(board_snapshot: Dictionary) -> bool:
	var panels: Dictionary = board_snapshot.get("panels", {})
	for id in ["left_info", "relic_bar", "item_bar"]:
		var panel: Dictionary = panels.get(id, {})
		var position: Vector3 = panel.get("world_position", Vector3.ZERO)
		var rotation: Vector3 = panel.get("world_rotation_degrees", Vector3.ZERO)
		if position.y < 0.20 or position.y > 0.45:
			return false
		if absf(rotation.x) > 0.01:
			return false
	return true


func _all_panels_float_above_table(board_snapshot: Dictionary) -> bool:
	var panels: Dictionary = board_snapshot.get("panels", {})
	for id in ["left_info", "relic_bar", "item_bar"]:
		var panel: Dictionary = panels.get(id, {})
		var position: Vector3 = panel.get("world_position", Vector3.ZERO)
		var rotation: Vector3 = panel.get("world_rotation_degrees", Vector3.ZERO)
		if position.y < 1.0:
			return false
		if absf(rotation.x) < 45.0:
			return false
	return true


func _all_panels_have_thickness(board_snapshot: Dictionary) -> bool:
	var panels: Dictionary = board_snapshot.get("panels", {})
	for id in ["left_info", "relic_bar", "item_bar"]:
		var panel: Dictionary = panels.get(id, {})
		if float(panel.get("board_thickness", 0.0)) < 0.25:
			return false
		if float(panel.get("edge_height", 0.0)) < 0.10:
			return false
	return true


func _flat_panels_have_yaw(board_snapshot: Dictionary) -> bool:
	var panels: Dictionary = board_snapshot.get("panels", {})
	var yaw_values: Array[float] = []
	for id in ["left_info", "relic_bar", "item_bar"]:
		var panel: Dictionary = panels.get(id, {})
		var rotation: Vector3 = panel.get("world_rotation_degrees", Vector3.ZERO)
		yaw_values.append(rotation.y)
	var has_left_tilt := false
	var has_right_tilt := false
	for yaw in yaw_values:
		has_left_tilt = has_left_tilt or yaw < -4.0
		has_right_tilt = has_right_tilt or yaw > 4.0
	return has_left_tilt and has_right_tilt
