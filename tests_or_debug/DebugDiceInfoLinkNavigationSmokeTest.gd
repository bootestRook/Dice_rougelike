extends SceneTree
class_name DebugDiceInfoLinkNavigationSmokeTest


const RunState = preload("res://scripts/core/battle/RunState.gd")


func _init() -> void:
	print("--- DebugDiceInfoLinkNavigationSmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.dice[0].faces[0].ornament_id = &"orn_burst"
	run_state.dice[0].faces[0].mark_id = &"red"

	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	battle_screen.setup(null, run_state)
	root.add_child(battle_screen)

	await process_frame
	await process_frame
	await process_frame

	var bench = battle_screen.get("dice_bench_area")
	all_passed = _check("bench exists", bench != null) and all_passed
	if bench != null:
		bench.show_info_for_die(0)
	await process_frame
	await process_frame

	var link_card := _first_link_card(battle_screen)
	all_passed = _check("face card exposes ornament and mark links", link_card != null) and all_passed
	if link_card != null:
		link_card.emit_signal("ornament_link_pressed", &"orn_burst")
	await process_frame
	await process_frame

	var combo_popup = battle_screen.get("combo_info_popup")
	var tabs := _tabs(combo_popup)
	all_passed = _check("ornament link opens central info popup", combo_popup != null and combo_popup.visible) and all_passed
	all_passed = _check("ornament link switches to tab 2", tabs != null and tabs.current_tab == 1) and all_passed
	all_passed = _check("second tab is ornament", tabs != null and tabs.get_tab_title(1) == "面饰") and all_passed
	all_passed = _check("third tab is mark", tabs != null and tabs.get_tab_title(2) == "印记") and all_passed

	if battle_screen.has_method("_hide_combo_info_popup"):
		battle_screen._hide_combo_info_popup()
	if bench != null:
		bench.show_info_for_die(0)
	await process_frame
	await process_frame

	link_card = _first_link_card(battle_screen)
	if link_card != null:
		link_card.emit_signal("mark_link_pressed", &"red")
	await process_frame
	await process_frame

	combo_popup = battle_screen.get("combo_info_popup")
	tabs = _tabs(combo_popup)
	all_passed = _check("mark link opens central info popup", combo_popup != null and combo_popup.visible) and all_passed
	all_passed = _check("mark link switches to tab 3", tabs != null and tabs.current_tab == 2) and all_passed

	battle_screen.queue_free()
	print("PASS: DebugDiceInfoLinkNavigationSmokeTest" if all_passed else "FAIL: DebugDiceInfoLinkNavigationSmokeTest")
	print("--- DebugDiceInfoLinkNavigationSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _first_link_card(root_node: Node) -> Node:
	if root_node.has_signal("ornament_link_pressed") and root_node.has_signal("mark_link_pressed"):
		return root_node
	for child in root_node.get_children():
		var result := _first_link_card(child)
		if result != null:
			return result
	return null


func _tabs(combo_popup) -> TabBar:
	if combo_popup == null:
		return null
	var node = combo_popup.get_node_or_null("%InfoTabs")
	return node as TabBar


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
