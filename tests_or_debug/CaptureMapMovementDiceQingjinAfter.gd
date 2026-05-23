extends SceneTree


const OUTPUT_PATH := "res://tests_or_debug/captures/map_movement_dice_qingjin_after.png"
const MANIFEST_PATH := "res://tests_or_debug/captures/map_movement_dice_qingjin_after_manifest.json"


func _init() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_EXCLUDE_FROM_CAPTURE, false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests_or_debug/captures"))

	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	if scene == null:
		push_error("无法加载主场景。")
		quit(1)
		return
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	if main.has_method("_on_start_battle_pressed"):
		main.call("_on_start_battle_pressed")
	await create_timer(1.10).timeout
	await process_frame
	await process_frame

	var map_stage := _find_node_by_name(main, "MapStageView")
	var movement_view = map_stage.get("movement_dice_physics_view") if map_stage != null else null
	if movement_view == null:
		push_error("无法找到地图前进骰视图。")
		quit(1)
		return
	var selected_indices: Array[int] = [0, 1]
	movement_view.set_display_state([4, 2], selected_indices, false, [3, 1])
	await _wait_for_capture_settle()

	var output := ProjectSettings.globalize_path(OUTPUT_PATH)
	var error := _save_window_image(output)
	_save_manifest(map_stage, output, error)
	print("saved=%s error=%s" % [output, error])
	quit(0 if error == OK else 1)


func _wait_for_capture_settle() -> void:
	for _frame in range(80):
		DisplayServer.process_events()
		await process_frame
	await create_timer(0.45).timeout
	await process_frame


func _find_node_by_name(node: Node, node_name: String) -> Node:
	if node == null:
		return null
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _save_window_image(output_path: String) -> int:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_EXCLUDE_FROM_CAPTURE, false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.process_events()
	var rect := Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	if rect.size.x <= 0 or rect.size.y <= 0:
		push_error("截图窗口尺寸无效：%s" % [str(rect)])
		return FAILED
	var image := DisplayServer.screen_get_image_rect(rect)
	if image == null or image.is_empty():
		push_error("无法截取窗口图像：%s" % [str(rect)])
		return FAILED
	return image.save_png(output_path)


func _save_manifest(map_stage: Node, output_path: String, error: int) -> void:
	var snapshot: Dictionary = map_stage.call("automation_get_snapshot") if map_stage != null and map_stage.has_method("automation_get_snapshot") else {}
	var movement_snapshot: Dictionary = snapshot.get("movement_physics_dice", {})
	var gm_snapshot: Dictionary = movement_snapshot.get("gm_snapshot", {})
	var manifest := {
		"output": output_path,
		"error": error,
		"display_values": movement_snapshot.get("display_values", []),
		"display_face_indices": movement_snapshot.get("display_face_indices", []),
		"selected_indices": movement_snapshot.get("selected_indices", []),
		"dice": gm_snapshot.get("dice", []),
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t"))
