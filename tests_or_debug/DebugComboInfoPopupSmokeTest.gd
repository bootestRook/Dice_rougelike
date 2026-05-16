extends SceneTree
class_name DebugComboInfoPopupSmokeTest


func _init() -> void:
	print("--- DebugComboInfoPopupSmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	root.add_child(battle_screen)

	await process_frame
	await process_frame
	await process_frame

	var info_button := _find_node_by_name(battle_screen, "InfoButton") as Control
	all_passed = _check("查看骰型按钮存在", info_button != null) and all_passed
	if info_button != null:
		_send_mouse_button(info_button, MOUSE_BUTTON_LEFT, battle_screen)
		await process_frame
		await process_frame

	var popup := battle_screen.get("combo_info_popup") as Control
	all_passed = _check("点击查看骰型会打开中央骰型窗口", popup != null and popup.visible) and all_passed
	all_passed = _check("骰型窗口没有打开骰子面信息框", not _is_dice_info_popup_visible(battle_screen)) and all_passed

	var rows_container = popup.get_node_or_null("%RowsContainer") if popup != null else null
	all_passed = _check("骰型窗口显示全部基础骰型行", rows_container != null and rows_container.get_child_count() >= 8) and all_passed

	var return_button := popup.get_node_or_null("%ReturnButton") as Control if popup != null else null
	all_passed = _check("返回按钮存在", return_button != null) and all_passed
	if return_button != null:
		_send_mouse_button(return_button, MOUSE_BUTTON_LEFT, battle_screen)
		await process_frame
		await process_frame

	all_passed = _check("点击返回会关闭骰型窗口", popup != null and not popup.visible) and all_passed

	battle_screen.queue_free()
	print("PASS: DebugComboInfoPopupSmokeTest" if all_passed else "FAIL: DebugComboInfoPopupSmokeTest")
	print("--- DebugComboInfoPopupSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _send_mouse_button(target: Control, button_index: int, battle_screen: Node) -> void:
	var center := target.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	battle_screen.get_viewport().push_input(motion)

	var press := InputEventMouseButton.new()
	press.button_index = button_index
	press.pressed = true
	press.position = center
	press.global_position = center
	battle_screen.get_viewport().push_input(press)

	var release := InputEventMouseButton.new()
	release.button_index = button_index
	release.pressed = false
	release.position = center
	release.global_position = center
	battle_screen.get_viewport().push_input(release)


func _is_dice_info_popup_visible(battle_screen: Node) -> bool:
	var dice_bench_area = battle_screen.get("dice_bench_area")
	if dice_bench_area == null:
		return false
	var popup = dice_bench_area.get("popup")
	return popup != null and popup.visible


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
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
