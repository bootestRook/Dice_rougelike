extends SceneTree


const OUTPUT_PATH := "res://tests_or_debug/captures/map_first_circle_shop_protection_after.png"
const MANIFEST_PATH := "res://tests_or_debug/captures/map_first_circle_shop_protection_after_manifest.json"
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
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

	var flow: GameFlowController = main.get("game_flow_controller") as GameFlowController
	var image := root.get_texture().get_image()
	var output := ProjectSettings.globalize_path(OUTPUT_PATH)
	var error := image.save_png(output)
	_save_manifest(flow, output, error)
	print("saved=%s error=%s" % [output, error])
	quit(0 if error == OK else 1)


func _save_manifest(flow: GameFlowController, output_path: String, error: int) -> void:
	var nodes: Array = flow.get_map_state().get("nodes", []) if flow != null else []
	var shop_indices: Array[int] = []
	var node_types: Array[String] = []
	for node in nodes:
		var index := int(node.get("index", 0))
		var node_type := StringName(str(node.get("node_type", "")))
		node_types.append(str(node_type))
		if node_type == &"shop":
			shop_indices.append(index)
	var manifest := {
		"output": output_path,
		"error": error,
		"shop_indices": shop_indices,
		"first_shop_index": shop_indices[0] if not shop_indices.is_empty() else -1,
		"node_types": node_types,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t"))
