extends SceneTree
class_name DebugBattleDiceInputSmokeTest


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

	var first_die: Control = _find_die_view(battle_screen, 0)
	all_passed = _check("first die view exists", first_die != null) and all_passed
	if first_die != null:
		_send_mouse_button(first_die, MOUSE_BUTTON_LEFT, battle_screen)
		await process_frame
		await process_frame
		all_passed = _check("left click selects die 0", _is_roll_selected(battle_screen, 0)) and all_passed

	var second_die: Control = _find_die_view(battle_screen, 1)
	all_passed = _check("second die view exists", second_die != null) and all_passed
	if second_die != null:
		_send_mouse_button(second_die, MOUSE_BUTTON_RIGHT, battle_screen)
		await process_frame
		await process_frame
		await process_frame
		all_passed = _check("right click does not select die 1", not _is_roll_selected(battle_screen, 1)) and all_passed
		all_passed = _check("right click shows info popup", _is_popup_visible(battle_screen)) and all_passed
		all_passed = _check("single right click keeps popup on screen", _popup_canvas_rect(battle_screen).position.y >= -1.0) and all_passed
		all_passed = _check("popup viewing target is reflected in bench title", _bench_title_contains(battle_screen, "正在查看骰子 2")) and all_passed
		var refreshed_second_die: Control = _find_die_view(battle_screen, 1)
		all_passed = _check("viewed die is marked in dice row", refreshed_second_die != null and _die_state_label(refreshed_second_die) == "查看中") and all_passed

		_send_global_mouse_button(Vector2(100.0, 100.0), MOUSE_BUTTON_LEFT, battle_screen)
		await process_frame
		await process_frame
		all_passed = _check("left click outside popup closes info popup", not _is_popup_visible(battle_screen)) and all_passed

	var sixth_die: Control = _find_die_view(battle_screen, 5)
	all_passed = _check("sixth die view exists", sixth_die != null) and all_passed
	if sixth_die != null:
		_send_mouse_button(sixth_die, MOUSE_BUTTON_RIGHT, battle_screen)
		_send_mouse_button(sixth_die, MOUSE_BUTTON_RIGHT, battle_screen)
		await process_frame
		await process_frame
		await process_frame
		all_passed = _check("double right click keeps one popup visible", _is_popup_visible(battle_screen)) and all_passed
		all_passed = _check("double right click keeps popup on screen", _popup_canvas_rect(battle_screen).position.y >= -1.0) and all_passed
		all_passed = _check("double right click keeps six face cards", _popup_face_card_count(battle_screen) == 6) and all_passed

		_send_mouse_button(sixth_die, MOUSE_BUTTON_RIGHT, battle_screen)
		_send_mouse_button(sixth_die, MOUSE_BUTTON_RIGHT, battle_screen)
		_send_mouse_button(sixth_die, MOUSE_BUTTON_RIGHT, battle_screen)
		await process_frame
		await process_frame
		await process_frame
		all_passed = _check("triple right click keeps one popup visible", _is_popup_visible(battle_screen)) and all_passed
		all_passed = _check("triple right click keeps six face cards", _popup_face_card_count(battle_screen) == 6) and all_passed
		all_passed = _check("triple right click keeps popup height sane", _popup_height(battle_screen) <= 720.0) and all_passed
		all_passed = _check("triple right click keeps popup on screen", _popup_canvas_rect(battle_screen).position.y >= -1.0) and all_passed
		all_passed = _check("triple right click target is reflected in bench title", _bench_title_contains(battle_screen, "正在查看骰子 6")) and all_passed

	battle_screen.queue_free()
	print("PASS: DebugBattleDiceInputSmokeTest" if all_passed else "FAIL: DebugBattleDiceInputSmokeTest")
	print("--- DebugBattleDiceInputSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _send_mouse_button(target: Control, button_index: int, battle_screen: Node) -> void:
	var center := target.get_global_rect().get_center()
	print("sending button=%d target=%s center=%s disabled=%s filter=%s hovered=%s" % [
		button_index,
		target.name,
		center,
		str(target.get("disabled")),
		str(target.mouse_filter),
		str(target.get_global_rect().has_point(center)),
	])

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


func _send_global_mouse_button(position: Vector2, button_index: int, battle_screen: Node) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = button_index
	press.pressed = true
	press.position = position
	press.global_position = position
	battle_screen.get_viewport().push_input(press)

	var release := InputEventMouseButton.new()
	release.button_index = button_index
	release.pressed = false
	release.position = position
	release.global_position = position
	battle_screen.get_viewport().push_input(release)


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


func _is_roll_selected(battle_screen: Node, die_index: int) -> bool:
	var controller = battle_screen.get("controller")
	if controller == null:
		return false
	for rolled_face in controller.get_current_rolls():
		if int(rolled_face.die_index) == die_index:
			return bool(rolled_face.selected)
	return false


func _is_popup_visible(battle_screen: Node) -> bool:
	var dice_bench_area = battle_screen.get("dice_bench_area")
	if dice_bench_area == null:
		return false
	var popup = dice_bench_area.get("popup")
	return popup != null and popup.visible


func _bench_title_contains(battle_screen: Node, text: String) -> bool:
	var dice_bench_area = battle_screen.get("dice_bench_area")
	if dice_bench_area == null:
		return false
	var title_label = dice_bench_area.get_node_or_null("%TitleLabel")
	return title_label != null and str(title_label.text).contains(text)


func _popup_face_card_count(battle_screen: Node) -> int:
	var popup = _popup_node(battle_screen)
	if popup == null:
		return -1
	var face_grid = popup.get_node_or_null("%FaceGrid")
	return face_grid.get_child_count() if face_grid != null else -1


func _popup_height(battle_screen: Node) -> float:
	var popup = _popup_node(battle_screen)
	return popup.size.y if popup != null else 0.0


func _popup_canvas_rect(battle_screen: Node) -> Rect2:
	var popup = _popup_node(battle_screen)
	if popup == null:
		return Rect2()
	return _control_canvas_rect(popup)


func _control_canvas_rect(control: Control) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	var points := [
		transform * Vector2.ZERO,
		transform * Vector2(control.size.x, 0.0),
		transform * Vector2(0.0, control.size.y),
		transform * control.size,
	]
	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]
	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)


func _popup_node(battle_screen: Node):
	var dice_bench_area = battle_screen.get("dice_bench_area")
	if dice_bench_area == null:
		return null
	return dice_bench_area.get("popup")


func _die_state_label(die_view: Control) -> String:
	var label = die_view.get_node_or_null("%StateLabel")
	return str(label.text) if label != null else ""


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
