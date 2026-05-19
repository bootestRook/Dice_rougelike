extends SceneTree
class_name DebugRewardKeywordLinkSmokeTest


const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


func _init() -> void:
	print("--- DebugRewardKeywordLinkSmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var run_state := RunState.new()
	run_state.setup_new_run()

	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	battle_screen.setup(null, run_state, true)
	root.add_child(battle_screen)
	await process_frame
	await process_frame
	await process_frame

	var mark_piece := _make_piece(
		&"debug_mark_link",
		DisplayNames.mark_name(&"red"),
		ForgeOperationDef.OP_SET_MARK,
		&"mark_red"
	)
	battle_screen.show_reward_choices([mark_piece])
	await process_frame
	await process_frame

	var mark_label := _first_rich_label_with_url(battle_screen, "mark:mark_red")
	all_passed = _check("reward text exposes mark info link", mark_label != null) and all_passed
	if mark_label != null:
		mark_label.emit_signal("meta_clicked", "mark:mark_red")
	await process_frame
	await process_frame

	var combo_popup = battle_screen.get("combo_info_popup")
	all_passed = _check("mark link opens battle info popup", combo_popup != null and combo_popup.visible) and all_passed
	all_passed = _check("mark link selects mark tab", combo_popup != null and int(combo_popup.get("current_tab")) == 2) and all_passed
	all_passed = _check("mark link selects red mark row", combo_popup != null and StringName(str(combo_popup.get("selected_mark_id"))) == &"mark_red") and all_passed

	if combo_popup != null:
		combo_popup.visible = false

	var ornament_piece := _make_piece(
		&"debug_ornament_link",
		DisplayNames.ornament_name(&"orn_stay"),
		ForgeOperationDef.OP_SET_ORNAMENT,
		&"orn_stay"
	)
	battle_screen.show_reward_choices([ornament_piece])
	await process_frame
	await process_frame

	var ornament_label := _first_rich_label_with_url(battle_screen, "ornament:orn_stay")
	all_passed = _check("reward text exposes ornament info link", ornament_label != null) and all_passed
	if ornament_label != null:
		ornament_label.emit_signal("meta_clicked", "ornament:orn_stay")
	await process_frame
	await process_frame

	combo_popup = battle_screen.get("combo_info_popup")
	all_passed = _check("ornament link opens battle info popup", combo_popup != null and combo_popup.visible) and all_passed
	all_passed = _check("ornament link selects ornament tab", combo_popup != null and int(combo_popup.get("current_tab")) == 1) and all_passed
	all_passed = _check("ornament link selects stay ornament row", combo_popup != null and StringName(str(combo_popup.get("selected_ornament_id"))) == &"orn_stay") and all_passed

	battle_screen.queue_free()
	print("PASS: DebugRewardKeywordLinkSmokeTest" if all_passed else "FAIL: DebugRewardKeywordLinkSmokeTest")
	print("--- DebugRewardKeywordLinkSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _make_piece(id: StringName, keyword: String, op: StringName, value_id: StringName) -> ForgePieceDef:
	var operation := ForgeOperationDef.new()
	operation.op = op
	operation.value_id = value_id

	var piece := ForgePieceDef.new()
	piece.id = id
	piece.display_name = "Debug"
	piece.description = "Install %s." % [keyword]
	piece.operations = [operation]
	return piece


func _first_rich_label_with_url(root_node: Node, url_text: String) -> RichTextLabel:
	if root_node is CanvasItem and not (root_node as CanvasItem).visible:
		return null
	if root_node is RichTextLabel and (root_node as RichTextLabel).text.contains("[url=%s]" % [url_text]):
		return root_node as RichTextLabel
	for child in root_node.get_children():
		var result := _first_rich_label_with_url(child, url_text)
		if result != null:
			return result
	return null


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
