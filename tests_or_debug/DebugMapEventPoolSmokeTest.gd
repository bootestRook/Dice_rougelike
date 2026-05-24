extends SceneTree
class_name DebugMapEventPoolSmokeTest


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const MapEventCatalog = preload("res://scripts/rules/event/MapEventCatalog.gd")
const MapEventGenerator = preload("res://scripts/rules/event/MapEventGenerator.gd")
const MapEventChoice = preload("res://scripts/data_defs/MapEventChoice.gd")


func _init() -> void:
	print("--- DebugMapEventPoolSmokeTest: start ---")

	var all_passed := true
	all_passed = _check("map event catalog contains 26 first-version events", MapEventCatalog.get_event_count() == 26) and all_passed
	all_passed = _check("map event type weights match design", _type_weights_match()) and all_passed
	all_passed = _check("boss counter events have generator weight", _boss_counter_events_have_generator_weight()) and all_passed
	all_passed = _check("all requested event ids exist", _all_requested_event_ids_exist()) and all_passed
	all_passed = _check("first protected segment only rolls safe event choices", _first_protected_segment_is_safe()) and all_passed
	all_passed = _check("generated map nodes merge reward and penalty into event", _map_nodes_are_merged()) and all_passed
	all_passed = _check("event choices expose Chinese text and executable ids", _event_choices_are_presentable()) and all_passed
	all_passed = _check("tricolor dice gate avoids ambiguous 门 glyph", _tricolor_gate_avoids_ambiguous_door_glyph()) and all_passed
	all_passed = _check("all event defs expose scene text and leave options where designed", _event_dialogue_defs_are_complete()) and all_passed

	print("PASS: DebugMapEventPoolSmokeTest" if all_passed else "FAIL: DebugMapEventPoolSmokeTest")
	print("--- DebugMapEventPoolSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _type_weights_match() -> bool:
	var weights := MapEventCatalog.get_type_weights()
	return is_equal_approx(float(weights.get(&"positive_reward", -1.0)), 25.0) \
		and is_equal_approx(float(weights.get(&"trade", -1.0)), 25.0) \
		and is_equal_approx(float(weights.get(&"risk", -1.0)), 20.0) \
		and is_equal_approx(float(weights.get(&"penalty", -1.0)), 15.0) \
		and is_equal_approx(float(weights.get(&"map", -1.0)), 8.0) \
		and is_equal_approx(float(weights.get(&"build", -1.0)), 7.0)


func _boss_counter_events_have_generator_weight() -> bool:
	var weights := MapEventCatalog.get_generator_type_weights()
	return float(weights.get(&"boss", 0.0)) > 0.0


func _all_requested_event_ids_exist() -> bool:
	var expected := [
		&"event_roadside_dice_box",
		&"event_broken_supply_cart",
		&"event_gambler_cup",
		&"event_traveling_carver",
		&"event_golden_peddler",
		&"event_dead_roller",
		&"event_mirror_well",
		&"event_white_mark_abbey",
		&"event_old_map_fragment",
		&"event_black_dice_taxman",
		&"event_silent_belltower",
		&"event_tricolor_dice_gate",
		&"event_astral_board",
		&"event_lost_apprentice",
		&"event_rgb_altar",
		&"event_cracked_floor",
		&"event_caravan_echo",
		&"event_whispering_statue",
		&"event_empty_relic_case",
		&"event_polychrome_rift",
		&"event_broken_crown",
		&"event_reroll_well",
		&"event_face_graveyard",
		&"event_symbol_storm",
		&"event_cursed_money_bag",
		&"event_fog_storyteller",
	]
	for event_id in expected:
		if MapEventCatalog.get_event_def(event_id).is_empty():
			return false
	return true


func _first_protected_segment_is_safe() -> bool:
	var flow := GameFlowController.new()
	flow.start_new_run()
	var generator := MapEventGenerator.new()
	var safe_types := {
		&"positive_reward": true,
		&"trade": true,
		&"risk": true,
		&"map": true,
		&"build": true,
	}
	var banned_tags := {
		&"high_risk": true,
		&"strong_penalty": true,
		&"boss_counter": true,
		&"sacrifice_relic": true,
		&"clear_face": true,
	}
	for seed_value in range(1, 80):
		generator.rng.seed = seed_value
		var choices := generator.generate_event_choices(flow.get_run_state(), 6, 3)
		if choices.is_empty():
			flow.free()
			return false
		for choice_any in choices:
			var choice := choice_any as MapEventChoice
			if choice == null:
				flow.free()
				return false
			if not safe_types.has(choice.event_type):
				flow.free()
				return false
			for tag in choice.tags:
				if banned_tags.has(tag):
					flow.free()
					return false
	flow.free()
	return true


func _map_nodes_are_merged() -> bool:
	var flow := GameFlowController.new()
	flow.start_new_run()
	var nodes: Array = flow.get_map_state().get("nodes", [])
	var counts := {}
	for node in nodes:
		var type_id := StringName(str(node.get("node_type", "")))
		counts[type_id] = int(counts.get(type_id, 0)) + 1
	flow.free()
	return nodes.size() == 32 \
		and int(counts.get(&"start", 0)) == 1 \
		and int(counts.get(&"boss", 0)) == 1 \
		and int(counts.get(&"battle", 0)) == 10 \
		and int(counts.get(&"elite", 0)) == 2 \
		and int(counts.get(&"shop", 0)) == 3 \
		and int(counts.get(&"forge", 0)) == 2 \
		and int(counts.get(&"event", 0)) == 11 \
		and int(counts.get(&"rest", 0)) == 2 \
		and int(counts.get(&"reward", 0)) == 0 \
		and int(counts.get(&"penalty", 0)) == 0


func _event_choices_are_presentable() -> bool:
	var flow := GameFlowController.new()
	flow.start_new_run()
	var generator := MapEventGenerator.new()
	generator.rng.seed = 20260524
	var choices := generator.generate_event_choices(flow.get_run_state(), 16, 3)
	flow.free()
	if choices.is_empty():
		return false
	for choice_any in choices:
		var choice := choice_any as MapEventChoice
		if choice == null:
			return false
		if choice.id == &"" or choice.effect_id == &"":
			return false
		if choice.get_display_name() == "" or choice.get_description() == "" or choice.get_effect_text() == "":
			return false
		if choice.get_display_name().contains("reward") or choice.get_display_name().contains("penalty"):
			return false
	return true


func _tricolor_gate_avoids_ambiguous_door_glyph() -> bool:
	var event_def := MapEventCatalog.get_event_def(&"event_tricolor_dice_gate")
	if event_def.is_empty():
		return false
	if str(event_def.get("name", "")).contains("门"):
		return false
	if str(event_def.get("scene_text", "")).contains("门"):
		return false
	var expected := {
		&"red_gate": "三色骰扉：推开红扉",
		&"blue_gate": "三色骰扉：推开蓝扉",
		&"gold_gate": "三色骰扉：推开金扉",
	}
	for option in event_def.get("options", []):
		var choice := MapEventChoice.from_data(event_def, option) as MapEventChoice
		if choice == null:
			return false
		if choice.get_display_name().contains("门") or choice.get_button_text().contains("门"):
			return false
		if not expected.has(choice.option_id):
			continue
		var display_name := choice.get_display_name()
		if display_name != expected[choice.option_id]:
			return false
		if display_name.contains("巾"):
			return false
	return true


func _event_dialogue_defs_are_complete() -> bool:
	for event_def in MapEventCatalog.get_all_event_defs():
		if str(event_def.get("name", "")) == "":
			return false
		if str(event_def.get("type_display_name", "")) == "":
			return false
		if str(event_def.get("scene_text", "")) == "":
			return false
		var options: Array = event_def.get("options", [])
		if options.is_empty():
			return false
		for option in options:
			if str(option.get("label", "")) == "":
				return false
			if str(option.get("effect_text", "")) == "":
				return false
			if StringName(str(option.get("effect_id", &""))) == &"":
				return false
	return true


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
