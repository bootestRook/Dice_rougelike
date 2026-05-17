extends SceneTree


var battle_screen: Node = null
var step: int = 0
var wait_frames: int = 0
var preview_final_score: int = 0
var initial_total_score: int = 0
var saw_preview_combo: bool = false
var saw_final_score: bool = false
var saw_synced_transfer: bool = false
var last_formula_score: int = -1
var last_total_score: int = -1


func _init() -> void:
	print("--- DebugLeftSidebarComboDisplaySmokeTest: start ---")


func _process(_delta: float) -> bool:
	if step == 0:
		var scene: PackedScene = load("res://scenes/battle/BattleScreen.tscn")
		print("scene_loaded=%s" % [str(scene != null)])
		battle_screen = scene.instantiate()
		root.add_child(battle_screen)
		print("scene_added")
		step = 1
		wait_frames = 0
		return false

	if step == 1:
		wait_frames += 1
		var controller = battle_screen.get("controller")
		if controller == null and wait_frames < 30:
			return false
		print("controller_null=%s wait_frames=%d" % [str(controller == null), wait_frames])
		if controller != null:
			for index in range(5):
				controller.toggle_select(index)
			print("selected_five")
		step = 2
		wait_frames = 0
		return false

	if step == 2:
		wait_frames += 1
		if wait_frames < 3:
			return false
		saw_preview_combo = _print_combo_state()
		var controller = battle_screen.get("controller")
		initial_total_score = controller.get_total_score() if controller != null else 0
		print("can_score_before_press=%s" % [str(controller.can_score() if controller != null else false)])
		print("wild_request_count=%d" % [controller.get_selected_wild_face_requests().size() if controller != null else 0])
		var trace = controller.request_settle_selected({}) if controller != null else null
		print("trace_null=%s" % [str(trace == null)])
		if trace != null:
			preview_final_score = int(trace.hand_score_final)
			battle_screen.set("active_resolution_trace", trace)
			battle_screen.set("is_resolution_playing", true)
			battle_screen.set("battle_ui_state", 5)
			battle_screen.set("resolution_start_score", initial_total_score)
			battle_screen.set("resolution_display_score", initial_total_score)
			if battle_screen.has_method("_prime_resolution_display_from_trace"):
				battle_screen._prime_resolution_display_from_trace(trace)
		if battle_screen.has_method("skip_resolution_animation"):
			battle_screen.skip_resolution_animation()
		if trace != null:
			battle_screen.play_final_score_fly(trace)
			print("final_score_fly_called")
		step = 3
		wait_frames = 0
		return false

	if step == 3:
		wait_frames += 1
		_track_final_score_transfer()
		if _is_transfer_finished() or wait_frames > 1200:
			var passed := saw_preview_combo and saw_final_score and saw_synced_transfer and _is_transfer_finished()
			print("saw_preview_combo=%s" % [str(saw_preview_combo)])
			print("saw_final_score=%s" % [str(saw_final_score)])
			print("saw_synced_transfer=%s" % [str(saw_synced_transfer)])
			print("transfer_finished=%s" % [str(_is_transfer_finished())])
			print("preview_final_score=%d initial_total_score=%d" % [preview_final_score, initial_total_score])
			print("is_resolution_playing=%s state=%s active_trace_null=%s" % [
				str(battle_screen.get("is_resolution_playing")),
				str(battle_screen.get("battle_ui_state")),
				str(battle_screen.get("active_resolution_trace") == null),
			])
			var combo_value := _find_node_by_name(battle_screen, "ComboValue") as Label
			var current_score_value := _find_node_by_name(battle_screen, "CurrentScoreValue") as Label
			print("last_combo_text='%s' last_current='%s'" % [
				combo_value.text if combo_value != null else "<missing>",
				current_score_value.text if current_score_value != null else "<missing>",
			])
			print("PASS: DebugLeftSidebarComboDisplaySmokeTest" if passed else "FAIL: DebugLeftSidebarComboDisplaySmokeTest")
			print("--- end ---")
			quit(0 if passed else 1)
			return true

	return false


func _print_combo_state() -> bool:
	var combo_value := _find_node_by_name(battle_screen, "ComboValue") as Label
	var combo_level := _find_node_by_name(battle_screen, "ComboLevelLabel") as Label
	var combo_header := _find_node_by_name(battle_screen, "ComboHeader") as Control
	var preview = battle_screen.get("current_preview_result")

	print("preview_null=%s" % [str(preview == null)])
	if preview != null:
		preview_final_score = int(preview.final_score)
		print("preview_combo=%s final=%s" % [str(preview.primary_combo), str(preview.final_score)])
	if combo_header != null:
		print("combo_header size=%s min=%s" % [str(combo_header.size), str(combo_header.custom_minimum_size)])
	if combo_value != null:
		print("combo_value text='%s' visible=%s size=%s min=%s clip=%s flags=%s" % [
			combo_value.text,
			str(combo_value.visible),
			str(combo_value.size),
			str(combo_value.custom_minimum_size),
			str(combo_value.clip_text),
			str(combo_value.size_flags_horizontal),
		])
	if combo_level != null:
		print("combo_level text='%s' visible=%s size=%s min=%s clip=%s flags=%s" % [
			combo_level.text,
			str(combo_level.visible),
			str(combo_level.size),
			str(combo_level.custom_minimum_size),
			str(combo_level.clip_text),
			str(combo_level.size_flags_horizontal),
		])
	return (
		preview != null
		and combo_value != null
		and combo_level != null
		and combo_value.text.strip_edges() != ""
		and combo_level.visible
		and combo_level.text.find("等级") >= 0
		and combo_value.size.x > 30.0
	)


func _track_final_score_transfer() -> void:
	var combo_value := _find_node_by_name(battle_screen, "ComboValue") as Label
	var current_score_value := _find_node_by_name(battle_screen, "CurrentScoreValue") as Label
	if combo_value == null or current_score_value == null:
		return

	var formula_score := _number_from_text(combo_value.text)
	var total_score := _number_from_text(current_score_value.text)
	if formula_score > 0:
		saw_final_score = true
	if last_formula_score >= 0 and last_total_score >= 0 and formula_score >= 0 and total_score >= 0:
		var formula_delta := last_formula_score - formula_score
		var total_delta := total_score - last_total_score
		if formula_delta > 0 and formula_delta == total_delta:
			saw_synced_transfer = true
	last_formula_score = formula_score
	last_total_score = total_score


func _is_transfer_finished() -> bool:
	var combo_value := _find_node_by_name(battle_screen, "ComboValue") as Label
	var current_score_value := _find_node_by_name(battle_screen, "CurrentScoreValue") as Label
	if combo_value == null or current_score_value == null:
		return false
	return (
		saw_final_score
		and combo_value.text == ""
		and _number_from_text(current_score_value.text) == initial_total_score + preview_final_score
	)


func _number_from_text(text: String) -> int:
	var normalized := text.strip_edges().replace(",", "")
	if normalized == "" or not normalized.is_valid_int():
		return -1
	return int(normalized)


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var result := _find_node_by_name(child, node_name)
		if result != null:
			return result
	return null
