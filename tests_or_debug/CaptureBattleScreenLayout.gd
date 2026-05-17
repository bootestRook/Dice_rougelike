extends SceneTree


const OUTPUT_DIR := "res://tests_or_debug/captures"
const RunState = preload("res://scripts/core/battle/RunState.gd")


func _init() -> void:
	var capture_size := _capture_size_from_args()
	var output_path := "res://tests_or_debug/captures/battle_screen_%dx%d.png" % [
		capture_size.x,
		capture_size.y,
	]
	DisplayServer.window_set_size(capture_size)
	root.size = capture_size
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	if _has_arg("ornament"):
		var run_state := RunState.new()
		run_state.setup_new_run()
		run_state.dice[0].faces[0].ornament_id = &"orn_burst"
		run_state.dice[0].faces[0].mark_id = &"red"
		battle_screen.setup(null, run_state)
	root.add_child(battle_screen)

	await process_frame
	await process_frame
	await process_frame

	var selected_count := _selected_count_from_args()
	if selected_count > 0 and battle_screen.get("controller") != null:
		for index in range(selected_count):
			battle_screen.controller.toggle_select(index)
		await process_frame
		await process_frame
	if _has_arg("popup") and battle_screen.get("dice_bench_area") != null:
		battle_screen.dice_bench_area.show_info_for_die(_die_index_from_args())
		await process_frame
		await process_frame
	if _has_arg("float") and battle_screen.get("scoring_area") != null:
		var scoring_area: Control = battle_screen.get("scoring_area")
		if battle_screen.has_method("_build_die_view_data") and scoring_area.has_method("show_resolution_dice"):
			var dice_data: Array = battle_screen._build_die_view_data()
			scoring_area.show_resolution_dice(dice_data.slice(0, mini(5, dice_data.size())), false)
			await process_frame
			await process_frame
		var chip_target := scoring_area.get_global_rect().get_center()
		var mult_target := chip_target + Vector2(90, 0)
		if scoring_area.has_method("get_resolution_dice_global_floating_anchor"):
			chip_target = scoring_area.get_resolution_dice_global_floating_anchor(0)
			mult_target = scoring_area.get_resolution_dice_global_floating_anchor(1)
		scoring_area.show_floating_score_at("+2 Chips", chip_target)
		scoring_area.show_floating_score_at("+4 Mult", mult_target)
		await process_frame
		await process_frame
	if _has_arg("combo") and battle_screen.has_method("_show_combo_info_popup"):
		battle_screen._show_combo_info_popup()
		await process_frame
		await process_frame
	if _has_arg("ornamenttab") and battle_screen.has_method("_show_ornament_info_popup"):
		battle_screen._show_ornament_info_popup(&"orn_burst")
		await process_frame
		await process_frame
	if _has_arg("marktab") and battle_screen.has_method("_show_mark_info_popup"):
		battle_screen._show_mark_info_popup(&"red")
		await process_frame
		await process_frame

	_print_node_rects(battle_screen)
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(output_path))
	print("saved=%s" % [ProjectSettings.globalize_path(output_path)])
	quit(0)


func _capture_size_from_args() -> Vector2i:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if not arg.contains("x"):
			continue
		var parts := arg.split("x")
		if parts.size() != 2:
			continue
		return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i(1920, 1080)


func _has_arg(name: String) -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg == name:
			return true
	return false


func _die_index_from_args() -> int:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("die"):
			continue
		return maxi(0, int(arg.trim_prefix("die")) - 1)
	return 0


func _selected_count_from_args() -> int:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("selected"):
			continue
		var value := arg.trim_prefix("selected")
		if value == "":
			return 1
		return maxi(1, int(value))
	return 0


func _print_node_rects(battle_screen: Node) -> void:
	var names := [
		"ResolutionScaledBattleLayout",
		"LeftBattleSidebar",
		"MainBattleArea",
		"TopInventoryBar",
		"SegmentScoringArea",
		"DiceBenchArea",
		"BenchOverlay",
		"DiceInfoPopup",
		"ComboInfoPopup",
		"WindowPanel",
		"BattleResourcePanel",
		"DiceRow",
	]
	for node_name in names:
		var node := _find_node_by_name(battle_screen, node_name)
		if node is Control:
			var control := node as Control
			print("%s pos=%s size=%s min=%s scale=%s" % [
				node_name,
				control.global_position,
				control.size,
				control.custom_minimum_size,
				control.scale,
			])
		else:
			print("%s missing" % [node_name])


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var result := _find_node_by_name(child, node_name)
		if result != null:
			return result
	return null
