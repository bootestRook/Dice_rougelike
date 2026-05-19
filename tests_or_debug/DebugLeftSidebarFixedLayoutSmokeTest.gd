extends SceneTree
class_name DebugLeftSidebarFixedLayoutSmokeTest


const RunState = preload("res://scripts/core/battle/RunState.gd")
const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")


func _init() -> void:
	print("--- DebugLeftSidebarFixedLayoutSmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.current_circle_index = 2
	run_state.current_circle_action_count = 5

	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	battle_screen.setup(null, run_state)
	root.add_child(battle_screen)

	await process_frame
	await process_frame
	await process_frame

	var formula_panel := _find_node_by_name(battle_screen, "ScoreFormulaPanel") as Control
	var resource_panel := _find_node_by_name(battle_screen, "BattleResourcePanel") as Control
	var formula_value := _find_node_by_name(battle_screen, "FormulaValue") as Label
	var formula_badges := _find_node_by_name(battle_screen, "FormulaBadges") as Control
	var chips_badge := _find_node_by_name(battle_screen, "FormulaChipsBadge") as Control
	var mult_badge := _find_node_by_name(battle_screen, "FormulaMultBadge") as Control
	var chips_value := _find_node_by_name(battle_screen, "FormulaChipsValue") as Label
	var mult_value := _find_node_by_name(battle_screen, "FormulaMultValue") as Label
	var x_label := _find_node_by_name(battle_screen, "FormulaXLabel") as Label
	var target_value := _find_node_by_name(battle_screen, "TargetValue") as Label
	var reward_label := _find_node_by_name(battle_screen, "RewardLabel") as Label
	var battle_title := _find_node_by_name(battle_screen, "BattleTitle") as Label
	var battle_value := _find_node_by_name(battle_screen, "BattleValue") as Label
	var status_label := _find_node_by_name(battle_screen, "StatusLabel") as Label
	var chips_texture := _find_node_by_name(battle_screen, "FormulaChipsTexture") as TextureRect
	var mult_texture := _find_node_by_name(battle_screen, "FormulaMultTexture") as TextureRect
	var max_battle_value := _find_node_by_name(battle_screen, "MaxBattleValue") as Label
	var left_sidebar = battle_screen.get("left_sidebar")
	all_passed = _check("sidebar nodes exist", formula_panel != null and resource_panel != null and formula_value != null and formula_badges != null and chips_badge != null and mult_badge != null and chips_value != null and mult_value != null and x_label != null and target_value != null and reward_label != null and battle_title != null and battle_value != null and status_label != null and max_battle_value != null and left_sidebar != null) and all_passed

	var base_formula_height := formula_panel.size.y
	var base_resource_y := resource_panel.global_position.y

	chips_value.text = "388,888"
	mult_value.text = "333"
	if left_sidebar.has_method("_fit_formula_badge_font_sizes"):
		left_sidebar._fit_formula_badge_font_sizes()
	await process_frame
	await process_frame
	var base_badges_position := formula_badges.global_position

	all_passed = _check("formula panel height does not grow", formula_panel.size.y <= base_formula_height + 1.0) and all_passed
	all_passed = _check("formula panel uses configured height", _near(formula_panel.size.y, float(battle_screen.style_config.left_score_formula_panel_height), 2.0)) and all_passed
	all_passed = _check("resource panel position stays fixed", _near(resource_panel.global_position.y, base_resource_y, 1.0)) and all_passed
	all_passed = _check("formula value does not request wrapping", formula_value.autowrap_mode == TextServer.AUTOWRAP_OFF) and all_passed
	all_passed = _check("formula legacy value is hidden", not formula_value.visible) and all_passed
	all_passed = _check("formula badges use image textures", chips_texture != null and chips_texture.texture != null and mult_texture != null and mult_texture.texture != null) and all_passed
	all_passed = _check("formula badge row stays inside formula panel", _rect_contains(formula_panel.get_global_rect(), formula_badges.get_global_rect(), 1.0)) and all_passed
	all_passed = _check("formula chips badge stays inside formula panel", _rect_contains(formula_panel.get_global_rect(), chips_badge.get_global_rect(), 1.0)) and all_passed
	all_passed = _check("formula mult badge stays inside formula panel", _rect_contains(formula_panel.get_global_rect(), mult_badge.get_global_rect(), 1.0)) and all_passed
	all_passed = _check("formula separator stays inside formula panel", _rect_contains(formula_panel.get_global_rect(), x_label.get_global_rect(), 1.0)) and all_passed
	all_passed = _check("target score value is visible", target_value.visible and target_value.text != "" and target_value.size.y >= 50.0) and all_passed
	all_passed = _check("target score value stays inside target panel", _rect_contains((_find_node_by_name(battle_screen, "TargetScorePanel") as Control).get_global_rect(), target_value.get_global_rect(), 1.0)) and all_passed
	all_passed = _check("target panel no longer shows circle base score", (not reward_label.visible or reward_label.text == "") and not reward_label.text.contains("基础分")) and all_passed
	all_passed = _check("sidebar former danger slot shows adjusted base score", battle_title.text == "基础分" and battle_title.autowrap_mode == TextServer.AUTOWRAP_OFF and battle_value.text == "825") and all_passed
	all_passed = _check("sidebar former danger slot omits map action count and danger", not battle_value.text.contains("次") and not battle_value.text.contains("%")) and all_passed
	all_passed = _check("stage status shows action count", status_label.text == "行动 5次") and all_passed
	all_passed = _check("stage value follows circle index", max_battle_value.text == "3/8") and all_passed

	if left_sidebar.has_method("render") and battle_screen.has_method("_build_hud_state"):
		var final_score_state: BattleHudState = battle_screen._build_hud_state()
		final_score_state.combo_display_visible = false
		final_score_state.final_score_display_visible = true
		final_score_state.formula_score = 12345
		left_sidebar.render(final_score_state)
		await process_frame
		await process_frame
		all_passed = _check("formula badge row does not move when final score appears", formula_badges.global_position.distance_to(base_badges_position) <= 1.0) and all_passed

		var count_state: BattleHudState = battle_screen._build_hud_state()
		count_state.circle_base_score = 900
		left_sidebar.render(count_state)
		var text_after_render := battle_value.text
		all_passed = _check("base score change starts count animation instead of direct switch", text_after_render != "900") and all_passed
		await create_timer(0.8).timeout
		all_passed = _check("base score count animation reaches target", battle_value.text == "900") and all_passed

	battle_screen.queue_free()
	print("PASS: DebugLeftSidebarFixedLayoutSmokeTest" if all_passed else "FAIL: DebugLeftSidebarFixedLayoutSmokeTest")
	print("--- DebugLeftSidebarFixedLayoutSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var result := _find_node_by_name(child, node_name)
		if result != null:
			return result
	return null


func _near(a: float, b: float, tolerance: float) -> bool:
	return absf(a - b) <= tolerance


func _rect_contains(parent_rect: Rect2, child_rect: Rect2, tolerance: float) -> bool:
	return child_rect.position.x >= parent_rect.position.x - tolerance \
		and child_rect.position.y >= parent_rect.position.y - tolerance \
		and child_rect.end.x <= parent_rect.end.x + tolerance \
		and child_rect.end.y <= parent_rect.end.y + tolerance


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
