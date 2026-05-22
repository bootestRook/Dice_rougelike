extends SceneTree
class_name DebugGmDiceMaterialInspectorSmokeTest


const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")


func _init() -> void:
	print("--- DebugGmDiceMaterialInspectorSmokeTest: start ---")
	var all_passed := true

	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	all_passed = _check("main scene loads", scene != null) and all_passed
	if scene == null:
		_finish(all_passed)
		return

	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame

	var gm_button := _find_node_by_name(main, "GmFloatingButton") as Button
	var gm_menu := _find_node_by_name(main, "GmFunctionMenu") as Control
	var material_button := _find_node_by_name(main, "GmDiceMaterialInspectorButton") as Button
	all_passed = _check("main menu has right-top GM button", gm_button != null) and all_passed
	all_passed = _check("main menu has GM function menu", gm_menu != null and not gm_menu.visible) and all_passed
	if gm_button != null:
		gm_button.pressed.emit()
		await process_frame
	all_passed = _check("GM button toggles function menu", gm_menu != null and gm_menu.visible) and all_passed
	all_passed = _check("GM menu has material inspector action", material_button != null and material_button.text == "骰子材质检查") and all_passed

	if material_button != null:
		material_button.pressed.emit()
		await process_frame
		await process_frame
		await process_frame

	var inspector := _find_node_by_name(main, "GmDiceMaterialInspectorRoot")
	all_passed = _check("material inspector screen opens", inspector != null) and all_passed
	all_passed = _check("GM floating button is cleared outside main menu", _find_node_by_name(main, "GmFloatingButton") == null) and all_passed

	if inspector != null:
		var snapshot: Dictionary = inspector.call("automation_get_snapshot")
		var material_rows: Array = snapshot.get("materials", [])
		all_passed = _check("inspector lists every GM material option", _has_all_expected_materials(material_rows)) and all_passed
		all_passed = _check("inspector exposes material resource/programmatic metadata", _material_rows_have_metadata(material_rows)) and all_passed
		all_passed = _check("cabinet cards exist for all material rows", _all_cards_exist(material_rows)) and all_passed
		all_passed = _check("visible inspector text has no forbidden internal terms", not _contains_forbidden_visible_text(inspector)) and all_passed

		var open_result: Dictionary = inspector.call("automation_open_material", "gold")
		await process_frame
		await process_frame
		all_passed = _check("automation opens gold material popup", bool(open_result.get("success", false))) and all_passed
		var popup := _find_node_by_name(inspector, "DiceMaterialInspectorPopup") as PanelContainer
		var title := _find_node_by_name(inspector, "InspectorTitleLabel") as Label
		all_passed = _check("popup exists", popup != null) and all_passed
		all_passed = _check("popup title uses Chinese material name", title != null and title.text.contains(GmDiceDefinition.material_name(&"gold"))) and all_passed
		all_passed = _check("popup controls exist", _popup_controls_exist(inspector)) and all_passed
		all_passed = _check("popup visible text has no forbidden internal terms", popup != null and not _contains_forbidden_visible_text(popup)) and all_passed

		if popup != null:
			var before_position := popup.global_position
			var handle := _find_node_by_name(inspector, "InspectorDragHandle") as Control
			if handle != null:
				var press_event := InputEventMouseButton.new()
				press_event.button_index = MOUSE_BUTTON_LEFT
				press_event.pressed = true
				press_event.global_position = before_position + Vector2(24, 18)
				handle.gui_input.emit(press_event)

				var motion_event := InputEventMouseMotion.new()
				motion_event.global_position = before_position + Vector2(190, 92)
				motion_event.relative = Vector2(166, 74)
				handle.gui_input.emit(motion_event)

				var release_event := InputEventMouseButton.new()
				release_event.button_index = MOUSE_BUTTON_LEFT
				release_event.pressed = false
				release_event.global_position = before_position + Vector2(190, 92)
				handle.gui_input.emit(release_event)
				await process_frame
			all_passed = _check("popup can be dragged", popup.global_position.distance_to(before_position) > 20.0) and all_passed

		var close_button := _find_node_by_name(inspector, "InspectorCloseButton") as Button
		if close_button != null:
			close_button.pressed.emit()
			await process_frame
		all_passed = _check("popup closes without leaving cabinet", _find_node_by_name(inspector, "DiceMaterialInspectorPopup") == null and _find_node_by_name(main, "GmDiceMaterialInspectorRoot") != null) and all_passed

		var back_button := _find_node_by_name(inspector, "MaterialInspectorBackButton") as Button
		if back_button != null:
			back_button.pressed.emit()
			await process_frame
			await process_frame
		all_passed = _check("back returns to main menu", _find_node_by_name(main, "GmFloatingButton") is Button) and all_passed

	var flow = main.get("game_flow_controller")
	if flow != null and flow.has_method("start_new_run"):
		flow.call("start_new_run")
		await process_frame
		await process_frame
	all_passed = _check("GM entry does not persist into run view", _find_node_by_name(main, "GmFloatingButton") == null) and all_passed

	main.queue_free()
	_finish(all_passed)


func _has_all_expected_materials(rows: Array) -> bool:
	var seen := {}
	for row in rows:
		if row is Dictionary:
			seen[str((row as Dictionary).get("id", ""))] = true
	for option in GmDiceDefinition.get_material_options():
		if not seen.has(str(option.get("id", ""))):
			return false
	return true


func _material_rows_have_metadata(rows: Array) -> bool:
	if rows.is_empty():
		return false
	var has_resource := false
	var has_programmatic := false
	for row in rows:
		if not (row is Dictionary):
			return false
		var dict := row as Dictionary
		if str(dict.get("name", "")).is_empty():
			return false
		if bool(dict.get("has_resource", false)):
			has_resource = true
		if bool(dict.get("programmatic", false)):
			has_programmatic = true
	return has_resource and has_programmatic


func _all_cards_exist(rows: Array) -> bool:
	for row in rows:
		if not (row is Dictionary):
			return false
		if not bool((row as Dictionary).get("card_exists", false)):
			return false
	return true


func _popup_controls_exist(root_node: Node) -> bool:
	var required_nodes := [
		"InspectorCloseButton",
		"InspectorPreviewViewport",
		"ResetViewButton",
		"AutoRotateCheckButton",
		"ShowPipsCheckButton",
		"KeyLightEnergySlider",
		"KeyLightYawSlider",
		"AmbientLightEnergySlider",
		"FillLightEnergySlider",
		"LightPresetBrightButton",
		"LightPresetNeutralButton",
		"LightPresetDarkButton",
	]
	for node_name in required_nodes:
		if _find_node_by_name(root_node, node_name) == null:
			return false
	return true


func _contains_forbidden_visible_text(root_node: Node) -> bool:
	var forbidden := ["material", "rune", "level", "glass", "steel", "rune_six", "upgrade", "lock", "unlock"]
	if root_node is Label:
		if _contains_any((root_node as Label).text, forbidden):
			return true
	if root_node is Button:
		if _contains_any((root_node as Button).text, forbidden):
			return true
	if root_node is CheckButton:
		if _contains_any((root_node as CheckButton).text, forbidden):
			return true
	for child in root_node.get_children():
		if _contains_forbidden_visible_text(child):
			return true
	return false


func _contains_any(text: String, values: Array) -> bool:
	var lower_text := text.to_lower()
	for value in values:
		if lower_text.contains(str(value)):
			print("Forbidden visible text: %s" % text)
			return true
	return false


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed


func _finish(all_passed: bool) -> void:
	print("PASS: DebugGmDiceMaterialInspectorSmokeTest" if all_passed else "FAIL: DebugGmDiceMaterialInspectorSmokeTest")
	print("--- DebugGmDiceMaterialInspectorSmokeTest: end ---")
	quit(0 if all_passed else 1)
