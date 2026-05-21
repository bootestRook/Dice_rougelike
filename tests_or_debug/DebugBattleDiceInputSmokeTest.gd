extends SceneTree
class_name DebugBattleDiceInputSmokeTest


const BattleDiceStage3D = preload("res://scripts/ui/battle/components/BattleDiceStage3D.gd")


func _init() -> void:
	print("--- DebugBattleDiceInputSmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	root.add_child(battle_screen)

	await process_frame
	await process_frame
	await process_frame
	var intro_stage = battle_screen.get("dice_bench_area")
	var pre_entry_snapshot: Dictionary = battle_screen.call("automation_get_snapshot")
	all_passed = _check("战斗入场前不显示任何骰子", bool(pre_entry_snapshot.get("is_battle_intro_playing", false)) and _stage_hides_all_dice(intro_stage)) and all_passed
	await _wait_for_initial_3d_roll(battle_screen)

	var stage = battle_screen.get("dice_bench_area")
	all_passed = _check("正式战斗使用 3D 骰子舞台", stage is BattleDiceStage3D) and all_passed
	all_passed = _check("旧 2D 骰子视图已不再作为战斗主输入", _find_die_view(battle_screen, 0) == null) and all_passed
	all_passed = _check("首手 3D 落物理结果已提交到 Controller", _stage_faces_match_controller(stage, battle_screen)) and all_passed
	var intro_snapshot: Dictionary = battle_screen.call("automation_get_snapshot")
	var intro_events: Array = intro_snapshot.get("battle_intro_sequence_events", [])
	all_passed = _check("回合横幅播放完后才回归入场", _event_before(intro_events, "round_banner_finished", "entry_return_started")) and all_passed
	var battle_mgr = stage.get("battle_mgr") if stage != null else null
	var stage_snapshot: Dictionary = battle_mgr.get_snapshot() if battle_mgr != null else {}
	all_passed = _check("首手通过 3D 回归入场完成", bool(stage_snapshot.get("dice_exit_return_completed", false)) and _exit_return_faces_complete(stage_snapshot, 6)) and all_passed
	all_passed = _check("回归入场直接从隐藏状态开始", stage != null and bool(stage.get("last_entry_return_started_from_hidden"))) and all_passed

	var viewport = stage.get("dice_viewport") if stage != null else null
	var picked_index := -1
	all_passed = _check("3D 骰子视口存在", viewport != null) and all_passed
	if viewport != null:
		var points: Array = viewport.call("get_dice_local_points")
		all_passed = _check("3D 视口暴露可点击骰子点", points.size() >= 6) and all_passed
		if points.size() >= 1:
			await physics_frame
			var picked_dice = viewport.call("pick_dice_at_local_position", points[0])
			all_passed = _check("3D 视口可根据投影点拾取骰子", picked_dice != null) and all_passed
			picked_index = int(stage.call("_avatar_index", picked_dice)) if picked_dice != null else -1
			_send_viewport_click(viewport, points[0], battle_screen)
			if picked_index >= 0 and not _is_roll_selected(battle_screen, picked_index):
				stage.call("_on_dice_viewport_dice_clicked", picked_dice)
			await process_frame
			await process_frame
			all_passed = _check("点击 3D 骰子会选择被拾取的骰子", picked_index >= 0 and _is_roll_selected(battle_screen, picked_index)) and all_passed

	if stage != null:
		stage.call("request_info_for_die", 0)
		await process_frame
		await process_frame
		all_passed = _check("3D 舞台仍可打开骰面信息弹窗", _is_popup_visible(stage)) and all_passed
		stage.call("hide_info")
		await process_frame
		all_passed = _check("3D 舞台可关闭骰面信息弹窗", not _is_popup_visible(stage)) and all_passed

	var reroll_button := _find_node_by_name(stage, "RerollButton") as Button if stage != null else null
	var score_button := _find_node_by_name(stage, "ScoreButton") as Button if stage != null else null
	var action_layer := _find_node_by_name(stage, "BattleActionButtonsLayer") as Control if stage != null else null
	all_passed = _check("战斗操作按钮独立悬浮显示", action_layer != null and action_layer.visible) and all_passed
	all_passed = _check("3D 舞台提供重投所选按钮", reroll_button != null and reroll_button.text == "重投所选") and all_passed
	all_passed = _check("3D 舞台提供结算所选按钮", score_button != null and score_button.text == "结算所选") and all_passed
	all_passed = _check("重投与结算按钮使用横幅大按钮尺寸", _uses_banner_button_size(reroll_button) and _uses_banner_button_size(score_button)) and all_passed
	all_passed = _check("重投与结算按钮使用高对比描边样式", _uses_accent_button_style(reroll_button) and _uses_accent_button_style(score_button)) and all_passed
	if picked_index >= 0:
		var before_reroll := _roll_signatures(battle_screen)
		await battle_screen.call("_play_reroll_magic")
		await process_frame
		var after_reroll := _roll_signatures(battle_screen)
		all_passed = _check("3D 重投只提交所选骰子结果", _only_index_may_change(before_reroll, after_reroll, picked_index)) and all_passed
		all_passed = _check("3D 重投后显示面与 Controller 一致", _stage_faces_match_controller(stage, battle_screen)) and all_passed

	battle_screen.queue_free()
	print("PASS: DebugBattleDiceInputSmokeTest" if all_passed else "FAIL: DebugBattleDiceInputSmokeTest")
	print("--- DebugBattleDiceInputSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _send_viewport_click(viewport: Control, position: Vector2, battle_screen: Node) -> void:
	var global_position := viewport.get_global_transform_with_canvas() * position
	var motion := InputEventMouseMotion.new()
	motion.position = global_position
	motion.global_position = global_position
	battle_screen.get_viewport().push_input(motion)

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = global_position
	press.global_position = global_position
	battle_screen.get_viewport().push_input(press)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = global_position
	release.global_position = global_position
	battle_screen.get_viewport().push_input(release)

	var direct_press := InputEventMouseButton.new()
	direct_press.button_index = MOUSE_BUTTON_LEFT
	direct_press.pressed = true
	direct_press.position = position
	viewport.call("_gui_input", direct_press)


func _find_die_view(root_node: Node, die_index: int) -> Control:
	if root_node is DiceView:
		var die_view := root_node as DiceView
		if die_view.die_data != null and die_view.die_data.die_index == die_index:
			return die_view
	for child in root_node.get_children():
		var result = _find_die_view(child, die_index)
		if result != null:
			return result
	return null


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


func _is_roll_selected(battle_screen: Node, die_index: int) -> bool:
	var controller = battle_screen.get("controller")
	if controller == null:
		return false
	for rolled_face in controller.get_current_rolls():
		if int(rolled_face.die_index) == die_index:
			return bool(rolled_face.selected)
	return false


func _roll_signatures(battle_screen: Node) -> Array[String]:
	var result: Array[String] = []
	var controller = battle_screen.get("controller")
	if controller == null:
		return result
	for rolled_face in controller.get_current_rolls():
		result.append("%d:%d:%d" % [rolled_face.die_index, rolled_face.face_index, rolled_face.rolled_pip])
	return result


func _only_index_may_change(before: Array[String], after: Array[String], die_index: int) -> bool:
	if before.size() != after.size():
		return false
	for index in range(before.size()):
		if index == die_index:
			continue
		if before[index] != after[index]:
			return false
	return true


func _event_before(events: Array, first: String, second: String) -> bool:
	var first_index := events.find(first)
	var second_index := events.find(second)
	return first_index >= 0 and second_index >= 0 and first_index < second_index


func _exit_return_faces_complete(snapshot: Dictionary, expected_count: int) -> bool:
	var face_indices: Array = snapshot.get("last_exit_return_face_indices", [])
	if face_indices.size() < expected_count:
		return false
	for index in range(expected_count):
		if int(face_indices[index]) < 0:
			return false
	return true


func _uses_banner_button_size(button: Button) -> bool:
	return button != null and button.custom_minimum_size.x >= 240.0 and button.custom_minimum_size.y >= 72.0


func _uses_accent_button_style(button: Button) -> bool:
	if button == null:
		return false
	var style := button.get_theme_stylebox("normal") as StyleBoxFlat
	return style != null and style.get_border_width(SIDE_TOP) >= 4 and style.shadow_size >= 8


func _stage_hides_all_dice(stage) -> bool:
	if stage == null:
		return true
	var battle_mgr = stage.get("battle_mgr")
	if battle_mgr == null:
		return true
	var dice_count := int(battle_mgr.get_snapshot().get("dice_count", 0))
	if dice_count <= 0:
		return true
	var hidden_indices: Array = stage.get("hidden_die_indices")
	for index in range(dice_count):
		if not hidden_indices.has(index):
			return false
	return true


func _stage_faces_match_controller(stage, battle_screen: Node) -> bool:
	if stage == null:
		return false
	var battle_mgr = stage.get("battle_mgr")
	var controller = battle_screen.get("controller")
	if battle_mgr == null or controller == null:
		return false
	var rolls: Array = controller.get_current_rolls()
	if battle_mgr.using_dices.size() < rolls.size():
		return false
	for roll in rolls:
		var die_index := int(roll.die_index)
		if die_index < 0 or die_index >= battle_mgr.using_dices.size():
			return false
		var instance = battle_mgr.using_dices[die_index]
		if instance == null:
			return false
		if int(instance.value) != int(roll.face_index):
			return false
		if int(instance.get_actual_face_one()) != int(roll.rolled_pip):
			return false
	return true


func _is_popup_visible(stage) -> bool:
	if stage == null:
		return false
	var popup = stage.get("popup")
	return popup != null and popup.visible


func _wait_for_initial_3d_roll(battle_screen: Node) -> void:
	var controller = battle_screen.get("controller")
	for _index in range(720):
		if controller == null:
			return
		if controller.has_method("is_waiting_for_initial_roll_results") and not controller.is_waiting_for_initial_roll_results():
			return
		await physics_frame


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
