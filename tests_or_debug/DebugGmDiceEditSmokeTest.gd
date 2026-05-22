extends SceneTree
class_name DebugGmDiceEditSmokeTest


const GmDiceDefinitionScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")


func _init() -> void:
	print("--- DebugGmDiceEditSmokeTest: start ---")
	var all_passed := true
	var crystal_definition := GmDiceDefinitionScript.create_crystal_d6()
	all_passed = _check("gm crystal d6 definition exists", crystal_definition.display_name == "水晶六面骰" and crystal_definition.material_id == GmDiceDefinitionScript.MATERIAL_CRYSTAL) and all_passed

	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	var scene := load("res://scenes/debug/GmPhysicsDiceTestScreen.tscn")
	var screen = scene.instantiate()
	root.add_child(screen)

	await process_frame
	await process_frame
	await process_frame
	screen.call("automation_clear")
	screen.call("automation_set_dice_count", 3)
	await process_frame
	await process_frame

	all_passed = _check("gm edit button exists", _find_node_by_name(screen, "DiceEditButton") is Button) and all_passed
	all_passed = _check("gm edit panel exists", _find_node_by_name(screen, "DiceEditPanel") is PanelContainer) and all_passed
	all_passed = _check("gm material selector exists", _find_node_by_name(screen, "DiceMaterialOption") is OptionButton) and all_passed
	all_passed = _check("gm selected replace button exists", _find_node_by_name(screen, "ApplySelectedDiceEditButton") is Button) and all_passed
	all_passed = _check("gm all replace button exists", _find_node_by_name(screen, "ApplyAllDiceEditButton") is Button) and all_passed
	all_passed = _check("gm crystal preset button is removed", _find_node_by_name(screen, "CrystalDicePresetButton") == null) and all_passed
	for face_index in range(1, 7):
		all_passed = _check("gm face %d pip selector exists" % face_index, _find_node_by_name(screen, "EditFace%dOption" % face_index) is OptionButton) and all_passed

	var edit_button := _find_node_by_name(screen, "DiceEditButton") as Button
	var edit_panel := _find_node_by_name(screen, "DiceEditPanel") as Control
	if edit_button != null and edit_panel != null:
		all_passed = _check("gm edit panel starts hidden", not edit_panel.visible) and all_passed
		screen.call("automation_toggle_dice_edit_panel")
		await process_frame
		all_passed = _check("gm edit button toggles panel", edit_panel.visible) and all_passed
		var before_position := edit_panel.global_position
		var hud_node = screen.get("hud")
		if hud_node != null:
			var press_event := InputEventMouseButton.new()
			press_event.button_index = MOUSE_BUTTON_LEFT
			press_event.pressed = true
			hud_node.call("_on_dice_edit_drag_handle_gui_input", press_event)
			var motion_event := InputEventMouseMotion.new()
			motion_event.relative = Vector2(180.0, 90.0)
			hud_node.call("_on_dice_edit_drag_handle_gui_input", motion_event)
			var release_event := InputEventMouseButton.new()
			release_event.button_index = MOUSE_BUTTON_LEFT
			release_event.pressed = false
			hud_node.call("_on_dice_edit_drag_handle_gui_input", release_event)
		await process_frame
		all_passed = _check("gm edit panel can be dragged", edit_panel.global_position.distance_to(before_position) > 20.0) and all_passed

	var initial_snapshot: Dictionary = screen.call("automation_get_snapshot")
	all_passed = _check("gm snapshot exposes visual repro blue material option", _material_options_have_id(initial_snapshot, "repro_blue")) and all_passed
	all_passed = _check("gm snapshot exposes visual repro purple material option", _material_options_have_id(initial_snapshot, "repro_purple")) and all_passed
	all_passed = _check("gm snapshot exposes visual repro cyan material option", _material_options_have_id(initial_snapshot, "repro_cyan")) and all_passed
	all_passed = _check("gm snapshot exposes visual repro gold material option", _material_options_have_id(initial_snapshot, "repro_gold")) and all_passed
	all_passed = _check("gm snapshot exposes visual repro silverwhite material option", _material_options_have_id(initial_snapshot, "repro_silverwhite")) and all_passed
	all_passed = _check("gm snapshot exposes bronze material option", _material_options_have(initial_snapshot, "bronze", "青铜骰胚")) and all_passed
	all_passed = _check("gm snapshot exposes gold material option", _material_options_have(initial_snapshot, "gold", "黄金骰胚")) and all_passed
	all_passed = _check("gm snapshot exposes crystal material option", _material_options_have(initial_snapshot, "crystal", "水晶骰胚")) and all_passed
	var bridge_contract: Dictionary = initial_snapshot.get("bridge_contract", {})
	all_passed = _check("gm bridge exposes selected replace action", (bridge_contract.get("actions", []) as Array).has("replace_selected_dice")) and all_passed
	all_passed = _check("gm bridge exposes all replace action", (bridge_contract.get("actions", []) as Array).has("replace_all_dice")) and all_passed

	screen.call("automation_clear")
	screen.call("automation_set_dice_count", 3)
	screen.call("automation_select_dice", [1])
	var selected_result: Dictionary = screen.call("automation_replace_selected_dice", "crystal", [6, 6, 5, 5, 4, 4])
	var selected_snapshot: Dictionary = screen.call("automation_get_snapshot")
	all_passed = _check("gm selected replace succeeds", bool(selected_result.get("success", false)) and selected_result.get("changed_indices", []) == [1]) and all_passed
	all_passed = _check("gm selected replace only changes selected die", _dice_material_id(selected_snapshot, 1) == "crystal" and _dice_material_id(selected_snapshot, 0) != "crystal") and all_passed
	all_passed = _check("gm selected replace writes Chinese crystal name", _dice_material_name(selected_snapshot, 1) == "水晶骰胚") and all_passed
	all_passed = _check("gm selected replace uses crystal pipeline material", _dice_body_material_path(selected_snapshot, 1) == "res://assets/materials/dice/crystal_dice.tres") and all_passed
	all_passed = _check("gm selected replace uses rounded dice mesh", _dice_body_mesh_path(selected_snapshot, 1) == "res://assets/models/dice/rounded_d6_mesh.tres") and all_passed
	all_passed = _check("gm selected replace writes all face pips", _dice_face_pips(selected_snapshot, 1) == [6, 6, 5, 5, 4, 4]) and all_passed
	all_passed = _check("gm selected replace refreshes current top pip", _dice_face_value(selected_snapshot, 1) == 6) and all_passed

	var all_result: Dictionary = screen.call("automation_replace_all_dice", "gold", [1, 1, 2, 2, 3, 3])
	var all_snapshot: Dictionary = screen.call("automation_get_snapshot")
	all_passed = _check("gm all replace succeeds", bool(all_result.get("success", false)) and all_result.get("changed_indices", []) == [0, 1, 2]) and all_passed
	all_passed = _check("gm all replace changes every die material", _all_dice_material(all_snapshot, "gold")) and all_passed
	all_passed = _check("gm all replace writes Chinese gold name", _all_dice_material_name(all_snapshot, "黄金骰胚")) and all_passed
	all_passed = _check("gm all replace uses gold pipeline material", _all_dice_body_material_path(all_snapshot, "res://assets/materials/dice/gold_dice.tres")) and all_passed
	all_passed = _check("gm all replace uses rounded dice mesh", _all_dice_body_mesh_path(all_snapshot, "res://assets/models/dice/rounded_d6_mesh.tres")) and all_passed
	all_passed = _check("gm all replace writes every die face pips", _all_dice_face_pips(all_snapshot, [1, 1, 2, 2, 3, 3])) and all_passed

	screen.queue_free()
	print("PASS: DebugGmDiceEditSmokeTest" if all_passed else "FAIL: DebugGmDiceEditSmokeTest")
	print("--- DebugGmDiceEditSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _selected_material_id(root_node: Node) -> String:
	var option := _find_node_by_name(root_node, "DiceMaterialOption") as OptionButton
	if option == null:
		return ""
	return str(option.get_item_metadata(option.selected))


func _selected_edit_pips(root_node: Node) -> Array:
	var pips: Array = []
	for face_index in range(1, 7):
		var option := _find_node_by_name(root_node, "EditFace%dOption" % face_index) as OptionButton
		pips.append(option.get_selected_id() if option != null else 0)
	return pips


func _material_options_have(snapshot: Dictionary, material_id: String, display_name: String) -> bool:
	var options: Array = snapshot.get("editable_materials", [])
	for option in options:
		if option is Dictionary and str(option.get("id", "")) == material_id and str(option.get("name", "")) == display_name:
			return true
	return false


func _material_options_have_id(snapshot: Dictionary, material_id: String) -> bool:
	var options: Array = snapshot.get("editable_materials", [])
	for option in options:
		if option is Dictionary and str(option.get("id", "")) == material_id:
			return true
	return false


func _dice_material_id(snapshot: Dictionary, index: int) -> String:
	var row := _dice_row(snapshot, index)
	return str(row.get("material_id", ""))


func _dice_material_name(snapshot: Dictionary, index: int) -> String:
	var row := _dice_row(snapshot, index)
	return str(row.get("material_name", ""))


func _dice_body_material_path(snapshot: Dictionary, index: int) -> String:
	var row := _dice_row(snapshot, index)
	var source_path := str(row.get("body_material_source_path", ""))
	return source_path if not source_path.is_empty() else str(row.get("body_material_resource_path", ""))


func _dice_body_mesh_path(snapshot: Dictionary, index: int) -> String:
	var row := _dice_row(snapshot, index)
	return str(row.get("body_mesh_resource_path", ""))


func _dice_face_pips(snapshot: Dictionary, index: int) -> Array:
	var row := _dice_row(snapshot, index)
	return row.get("face_pips", [])


func _dice_face_value(snapshot: Dictionary, index: int) -> int:
	var row := _dice_row(snapshot, index)
	return int(row.get("face_value", 0))


func _all_dice_material(snapshot: Dictionary, material_id: String) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary) or str((row as Dictionary).get("material_id", "")) != material_id:
			return false
	return true


func _all_dice_material_name(snapshot: Dictionary, material_name: String) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary) or str((row as Dictionary).get("material_name", "")) != material_name:
			return false
	return true


func _all_dice_body_material_path(snapshot: Dictionary, material_path: String) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var dict := row as Dictionary
		var source_path := str(dict.get("body_material_source_path", ""))
		var resolved_path := source_path if not source_path.is_empty() else str(dict.get("body_material_resource_path", ""))
		if resolved_path != material_path:
			return false
	return true


func _all_dice_body_mesh_path(snapshot: Dictionary, mesh_path: String) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary) or str((row as Dictionary).get("body_mesh_resource_path", "")) != mesh_path:
			return false
	return true


func _all_dice_face_pips(snapshot: Dictionary, expected: Array) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary) or (row as Dictionary).get("face_pips", []) != expected:
			return false
	return true


func _dice_row(snapshot: Dictionary, index: int) -> Dictionary:
	var dice_rows: Array = snapshot.get("dice", [])
	if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
		return {}
	return dice_rows[index] as Dictionary


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
