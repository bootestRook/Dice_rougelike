extends SceneTree
class_name DebugGmDiceMaterialInspectorSmokeTest


const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const PREVIEW_BODY_MESH_PATH := "res://assets/models/dice/preview_rounded_d6_body_mesh.tres"


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
		all_passed = _check("cabinet previews use preview-only repaired mesh", _all_card_previews_use_preview_mesh(material_rows)) and all_passed
		all_passed = _check("cabinet previews are independent instances", _preview_instance_ids_are_unique(material_rows)) and all_passed
		all_passed = _check("inspector uses neutral gray background", _is_neutral_gray_color(snapshot.get("background_color", Color.BLACK))) and all_passed
		all_passed = _check("visible inspector text has no forbidden internal terms", not _contains_forbidden_visible_text(inspector)) and all_passed

		var cabinet_before_popup := snapshot
		var gold_card_before := _material_row_by_id(material_rows, "gold")
		var open_result: Dictionary = inspector.call("automation_open_material", "gold")
		await process_frame
		await process_frame
		all_passed = _check("automation opens gold material popup", bool(open_result.get("success", false))) and all_passed
		var popup_snapshot: Dictionary = inspector.call("automation_get_snapshot")
		var popup := _find_node_by_name(inspector, "DiceMaterialInspectorPopup") as PanelContainer
		var title := _find_node_by_name(inspector, "InspectorTitleLabel") as Label
		all_passed = _check("popup exists", popup != null) and all_passed
		all_passed = _check("popup title uses Chinese material name", title != null and title.text.contains(GmDiceDefinition.material_name(&"gold"))) and all_passed
		all_passed = _check("popup controls exist", _popup_controls_exist(inspector)) and all_passed
		all_passed = _check("popup modal blocks cabinet input", bool(popup_snapshot.get("popup", {}).get("has_modal_backdrop", false)) and bool(popup_snapshot.get("popup", {}).get("popup_layer_blocking", false))) and all_passed
		all_passed = _check("popup backdrop is neutral gray", _is_neutral_gray_color(popup_snapshot.get("popup", {}).get("modal_backdrop_color", Color.BLACK))) and all_passed
		all_passed = _check("popup preview is independent from cabinet preview", _popup_preview_is_independent(popup_snapshot, gold_card_before)) and all_passed
		all_passed = _check("popup preview uses preview-only repaired mesh", str(popup_snapshot.get("popup", {}).get("preview", {}).get("mesh_resource_path", "")) == PREVIEW_BODY_MESH_PATH) and all_passed
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
			all_passed = _check("popup dice drag does not move cabinet previews", await _popup_dice_drag_is_isolated(inspector, cabinet_before_popup)) and all_passed

		var close_button := _find_node_by_name(inspector, "InspectorCloseButton") as Button
		if close_button != null:
			close_button.pressed.emit()
			await process_frame
		all_passed = _check("popup closes without leaving cabinet", _find_node_by_name(inspector, "DiceMaterialInspectorPopup") == null and _find_node_by_name(main, "GmDiceMaterialInspectorRoot") != null) and all_passed
		var after_close_snapshot: Dictionary = inspector.call("automation_get_snapshot")
		all_passed = _check("popup layer releases cabinet input after close", not bool(after_close_snapshot.get("popup_layer_blocking", true))) and all_passed

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


func _all_card_previews_use_preview_mesh(rows: Array) -> bool:
	for row in rows:
		if not (row is Dictionary):
			return false
		var preview := (row as Dictionary).get("preview", {}) as Dictionary
		if str(preview.get("mesh_resource_path", "")) != PREVIEW_BODY_MESH_PATH:
			return false
	return true


func _preview_instance_ids_are_unique(rows: Array) -> bool:
	var seen := {}
	for row in rows:
		if not (row is Dictionary):
			return false
		var preview := (row as Dictionary).get("preview", {}) as Dictionary
		var id := int(preview.get("dice_root_instance_id", 0))
		if id == 0 or seen.has(id):
			return false
		seen[id] = true
	return true


func _popup_preview_is_independent(snapshot: Dictionary, card_row: Dictionary) -> bool:
	var popup_preview := snapshot.get("popup", {}).get("preview", {}) as Dictionary
	var card_preview := card_row.get("preview", {}) as Dictionary
	if popup_preview.is_empty() or card_preview.is_empty():
		return false
	return int(popup_preview.get("preview_instance_id", 0)) != int(card_preview.get("preview_instance_id", 0)) \
		and int(popup_preview.get("dice_root_instance_id", 0)) != int(card_preview.get("dice_root_instance_id", 0)) \
		and int(popup_preview.get("dice_mesh_instance_id", 0)) != int(card_preview.get("dice_mesh_instance_id", 0))


func _material_row_by_id(rows: Array, material_id: String) -> Dictionary:
	for row in rows:
		if row is Dictionary and str((row as Dictionary).get("id", "")) == material_id:
			return row as Dictionary
	return {}


func _is_neutral_gray_color(value) -> bool:
	if not (value is Color):
		return false
	var color := value as Color
	var channel_delta := maxf(absf(color.r - color.g), absf(color.g - color.b))
	return channel_delta <= 0.035 and color.r >= 0.10 and color.r <= 0.26


func _popup_dice_drag_is_isolated(inspector: Node, before_snapshot: Dictionary) -> bool:
	var before_row := _material_row_by_id(before_snapshot.get("materials", []), "gold")
	var before_preview := before_row.get("preview", {}) as Dictionary
	var before_card_rotation := before_preview.get("rotation", Vector3.ZERO) as Vector3
	var preview := _find_node_by_name(inspector, "InspectorPreviewViewport") as Control
	if preview == null:
		return false

	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	press_event.global_position = preview.global_position + Vector2(80, 80)
	preview.call("_gui_input", press_event)

	var motion_event := InputEventMouseMotion.new()
	motion_event.global_position = preview.global_position + Vector2(170, 110)
	motion_event.relative = Vector2(90, 30)
	preview.call("_gui_input", motion_event)

	var release_event := InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	release_event.global_position = preview.global_position + Vector2(170, 110)
	preview.call("_gui_input", release_event)
	await process_frame

	var after_snapshot: Dictionary = inspector.call("automation_get_snapshot")
	var popup_rotation := after_snapshot.get("popup", {}).get("preview", {}).get("rotation", Vector3.ZERO) as Vector3
	var after_row := _material_row_by_id(after_snapshot.get("materials", []), "gold")
	var after_card_preview := after_row.get("preview", {}) as Dictionary
	var after_card_rotation := after_card_preview.get("rotation", Vector3.ZERO) as Vector3
	return not _rotation_close(popup_rotation, before_card_rotation) and _rotation_close(after_card_rotation, before_card_rotation)


func _rotation_close(a: Vector3, b: Vector3) -> bool:
	return a.distance_to(b) <= 0.0001


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
