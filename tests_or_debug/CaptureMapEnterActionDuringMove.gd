extends SceneTree


const OUTPUT_PATH := "res://tests_or_debug/captures/map_enter_action_during_move_after.png"
const MANIFEST_PATH := "res://tests_or_debug/captures/map_enter_action_during_move_after_manifest.json"
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const MapStageViewScript = preload("res://scripts/ui/map/MapStageView.gd")


func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests_or_debug/captures"))

	var flow := GameFlowController.new()
	root.add_child(flow)
	flow.start_new_run()
	if flow.map_nodes.size() < 2:
		push_error("Map capture requires at least two nodes.")
		quit(1)
		return
	flow.map_nodes[1]["node_type"] = &"event"
	flow.map_nodes[1]["is_cleared"] = false
	flow.map_position_index = 0

	var map_view = MapStageViewScript.new()
	map_view.name = "MapStageViewCapture"
	map_view.size = Vector2(root.size)
	map_view.setup(flow, flow.get_map_state())
	root.add_child(map_view)

	await process_frame
	await process_frame
	await map_view.call("play_raise")

	map_view.set("is_marker_animating", true)
	flow.apply_prepared_map_movement_roll([0], [1], [0])
	await process_frame
	map_view.call("_refresh_interaction_lock_state")
	await process_frame
	await process_frame

	var output_abs := ProjectSettings.globalize_path(OUTPUT_PATH)
	var image := root.get_texture().get_image()
	var error := FAILED
	if image != null and not image.is_empty():
		error = image.save_png(output_abs)
	else:
		push_error("Cannot capture root viewport image.")
	_save_manifest(map_view, output_abs, error)
	print("saved=%s error=%s" % [output_abs, error])
	quit(0 if error == OK else 1)


func _save_manifest(map_view: Node, output_path: String, error: int) -> void:
	var snapshot: Dictionary = map_view.call("automation_get_snapshot") if map_view != null and map_view.has_method("automation_get_snapshot") else {}
	var manifest := {
		"output": output_path,
		"error": error,
		"current_node_type": snapshot.get("current_node_type", ""),
		"pending_event": bool(snapshot.get("pending_event", false)),
		"interaction_locked": bool(snapshot.get("interaction_locked", false)),
		"is_movement_roll_pending": bool(snapshot.get("is_movement_roll_pending", false)),
		"enter_battle_button_visible": bool(snapshot.get("enter_battle_button_visible", true)),
		"enter_battle_button_disabled": bool(snapshot.get("enter_battle_button_disabled", false)),
		"enter_battle_button_label": str(snapshot.get("enter_battle_button_label", "")),
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t"))
