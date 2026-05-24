extends SceneTree
class_name CaptureEliteVictoryFlowState


const RunState = preload("res://scripts/core/battle/RunState.gd")

const OUTPUT_DIR := "res://tests_or_debug/captures/elite_victory_flow"
const BEFORE_PATH := OUTPUT_DIR + "/elite_victory_flow_before.png"
const AFTER_PATH := OUTPUT_DIR + "/elite_victory_flow_after.png"
const MANIFEST_PATH := OUTPUT_DIR + "/manifest.json"


func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_EXCLUDE_FROM_CAPTURE, false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	root.add_child(battle_screen)

	await process_frame
	await process_frame
	await process_frame
	await _wait_for_initial_3d_roll(battle_screen)

	var sidebar = battle_screen.get("left_sidebar")
	if sidebar != null and sidebar.has_method("play_battle_victory_target_feedback"):
		await sidebar.play_battle_victory_target_feedback()
	await process_frame
	await _save_root_png(BEFORE_PATH)

	var elite_run := RunState.new()
	elite_run.setup_new_run()
	elite_run.set_current_encounter_node_type(RunState.ENCOUNTER_ELITE)
	battle_screen.call("start_battle_with_run_state", null, elite_run)
	await _wait_for_initial_3d_roll(battle_screen)
	await process_frame
	await process_frame
	await _save_root_png(AFTER_PATH)
	_save_manifest()

	print("before=%s" % [ProjectSettings.globalize_path(BEFORE_PATH)])
	print("after=%s" % [ProjectSettings.globalize_path(AFTER_PATH)])
	await _cleanup_nodes_before_quit([battle_screen])
	quit(0)


func _wait_for_initial_3d_roll(battle_screen: Node) -> void:
	var controller = battle_screen.get("controller")
	for _index in range(720):
		if controller == null:
			return
		if controller.has_method("is_waiting_for_initial_roll_results") and not controller.is_waiting_for_initial_roll_results():
			return
		await physics_frame


func _save_root_png(path: String) -> void:
	await process_frame
	var rect := Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	var image := DisplayServer.screen_get_image_rect(rect)
	var global_path := ProjectSettings.globalize_path(path)
	var error := image.save_png(global_path)
	print("save_png=%s error=%d size=%s" % [global_path, error, str(image.get_size())])
	image = null


func _save_manifest() -> void:
	var manifest := {
		"scenario": "elite victory target overlay restoration before external 3D hand entry",
		"before": ProjectSettings.globalize_path(BEFORE_PATH),
		"after": ProjectSettings.globalize_path(AFTER_PATH),
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t"))


func _cleanup_nodes_before_quit(nodes: Array) -> void:
	await _flush_runtime_feedback(nodes)
	for node in nodes:
		if node != null and is_instance_valid(node):
			node.queue_free()
	for _index in range(24):
		await process_frame
		await physics_frame


func _flush_runtime_feedback(nodes: Array) -> void:
	for node in nodes:
		if node == null or not is_instance_valid(node):
			continue
		var sidebar = node.get("left_sidebar")
		if sidebar != null and sidebar.has_method("automation_flush_runtime_feedback"):
			await sidebar.automation_flush_runtime_feedback()
