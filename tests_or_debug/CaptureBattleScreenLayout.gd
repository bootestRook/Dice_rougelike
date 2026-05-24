extends SceneTree


const OUTPUT_DIR := "res://tests_or_debug/captures"
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


func _init() -> void:
	var capture_size := _capture_size_from_args()
	var suffix := ""
	if _has_arg("hover"):
		suffix = "_hover"
	elif _has_arg("coinreward"):
		suffix = "_coin_reward"
	elif _has_arg("rewardchoices"):
		suffix = "_reward_choices"
	var output_path := "res://tests_or_debug/captures/battle_screen_%dx%d%s.png" % [
		capture_size.x,
		capture_size.y,
		suffix,
	]
	if _has_arg("iteminfo"):
		output_path = "res://tests_or_debug/captures/battle_screen_%dx%d_item_info.png" % [
			capture_size.x,
			capture_size.y,
		]
	if _has_arg("relicinfo"):
		output_path = "res://tests_or_debug/captures/battle_screen_%dx%d_relic_info.png" % [
			capture_size.x,
			capture_size.y,
		]
	DisplayServer.window_set_size(capture_size)
	root.size = capture_size
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	if _has_arg("ornament") or _has_arg("relic") or _has_arg("iteminfo") or _has_arg("relicinfo"):
		var run_state := RunState.new()
		run_state.setup_new_run()
		if _has_arg("ornament"):
			run_state.dice[0].faces[0].ornament_id = &"orn_burst"
			run_state.dice[0].faces[0].mark_id = &"red"
		if _has_arg("iteminfo"):
			run_state.add_item_to_inventory_or_pending(&"upgrade_combo_pair")
		if _has_arg("relic") or _has_arg("relicinfo"):
			var item: ItemInstance = ItemInstance.create_dice_tool(
				DiceToolCatalog.TOOL_BASIC_MULT,
				DiceToolCatalog.display_name_for_id(DiceToolCatalog.TOOL_BASIC_MULT),
				DiceToolCatalog.sell_value_for_rarity(&"common")
			)
			item.metadata["rarity"] = &"common"
			run_state.install_dice_tool_item_instance(item)
		battle_screen.setup(null, run_state, _has_arg("iteminfo") or _has_arg("relicinfo"))
	root.add_child(battle_screen)

	await process_frame
	await process_frame
	await process_frame
	if _has_arg("hover"):
		await _wait_for_initial_3d_roll(battle_screen)
		if battle_screen.has_method("_refresh_hud"):
			battle_screen.call("_refresh_hud")
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
		scoring_area.show_floating_score_at(str(TranslationServer.translate(&"UI.SCORE_FLOAT.MULT_GAIN")) % [4], mult_target)
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
	if _has_arg("iteminfo"):
		await _show_inventory_hover_info(battle_screen, "ItemSlots")
	if _has_arg("relicinfo"):
		await _show_inventory_hover_info(battle_screen, "RelicSlots")
	if _has_arg("hover") and battle_screen.get("dice_bench_area") != null:
		var stage = battle_screen.get("dice_bench_area")
		var battle_mgr = stage.get("battle_mgr") if stage != null else null
		if battle_mgr != null and battle_mgr.using_dices.size() > 0 and battle_mgr.using_dices[0] != null:
			var avatar = battle_mgr.using_dices[0].avatar
			if avatar != null:
				stage.call("_on_dice_viewport_dice_hovered", avatar)
		for _index in range(24):
			await process_frame
	if _has_arg("coinreward") and battle_screen.has_method("show_battle_coin_reward"):
		battle_screen.show_battle_coin_reward(_sample_coin_reward_summary())
		await process_frame
		await process_frame
	if _has_arg("rewardchoices") and battle_screen.has_method("show_reward_choices"):
		var reward_run := RunState.new()
		reward_run.setup_new_run()
		var generator := RewardGenerator.new()
		battle_screen.show_reward_choices(generator.generate_battle_reward_choices(reward_run, 3))
		await process_frame
		await process_frame

	_print_node_rects(battle_screen)
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(output_path))
	print("saved=%s" % [ProjectSettings.globalize_path(output_path)])
	if _has_arg("hover"):
		var manifest_path := "res://tests_or_debug/captures/battle_screen_%dx%d_hover_manifest.json" % [
			capture_size.x,
			capture_size.y,
		]
		var manifest := {
			"scenario": "battle screen dice hover face info",
			"screenshot": ProjectSettings.globalize_path(output_path),
			"fields": ["骰胚", "点数", "面饰", "印记"],
		}
		var file := FileAccess.open(ProjectSettings.globalize_path(manifest_path), FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(manifest, "\t"))
			file.close()
		print("manifest=%s" % [ProjectSettings.globalize_path(manifest_path)])
	if _has_arg("coinreward") or _has_arg("rewardchoices"):
		var manifest_path := output_path.replace(".png", "_manifest.json")
		var manifest := {
			"scenario": "battle reward flow coin screen" if _has_arg("coinreward") else "battle reward flow choices screen",
			"screenshot": ProjectSettings.globalize_path(output_path),
			"fields": ["金币奖励", "通关奖励", "继续"] if _has_arg("coinreward") else ["常规奖励", "挑选"],
		}
		var file := FileAccess.open(ProjectSettings.globalize_path(manifest_path), FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(manifest, "\t"))
			file.close()
		print("manifest=%s" % [ProjectSettings.globalize_path(manifest_path)])
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


func _wait_for_initial_3d_roll(battle_screen: Node) -> void:
	var controller = battle_screen.get("controller")
	for _index in range(720):
		if controller == null:
			return
		if controller.has_method("is_waiting_for_initial_roll_results") and not controller.is_waiting_for_initial_roll_results():
			return
		await physics_frame


func _show_inventory_hover_info(battle_screen: Node, slots_name: String) -> void:
	var slots := _find_node_by_name(battle_screen, slots_name) as HBoxContainer
	if slots == null or slots.get_child_count() <= 0:
		return
	var slot := slots.get_child(0) as Control
	if slot == null:
		return
	slot.mouse_entered.emit()
	for _index in range(24):
		await process_frame


func _sample_coin_reward_summary() -> Dictionary:
	return {
		"title": "金币奖励",
		"rows": [
			{"label": "通关奖励", "amount": 16, "kind": &"battle_clear"},
			{"label": "剩余轮次(7)", "amount": 0, "kind": &"unused_reroll"},
			{"label": "骰子技能", "amount": 0, "kind": &"dice_skill"},
		],
		"total": 16,
		"coins_before": 20,
		"coins_after": 36,
	}
