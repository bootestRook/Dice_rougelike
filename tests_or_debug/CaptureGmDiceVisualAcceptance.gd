extends SceneTree


const OUTPUT_PATH := "res://tests_or_debug/captures/gm_dice_visual_acceptance.png"


func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1680, 960))
	root.size = Vector2i(1680, 960)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests_or_debug/captures"))

	var scene := load("res://scenes/debug/GmPhysicsDiceTestScreen.tscn")
	var screen = scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	await process_frame
	if screen.has_method("automation_clear"):
		screen.call("automation_clear")
	if screen.has_method("automation_set_dice_count"):
		screen.call("automation_set_dice_count", 6)
	await process_frame
	await process_frame
	await process_frame
	if screen.has_method("automation_get_snapshot"):
		var snapshot: Dictionary = screen.call("automation_get_snapshot")
		for row in snapshot.get("dice", []):
			if row is Dictionary:
				print("dice=%s material=%s body=%s mesh=%s" % [
					str((row as Dictionary).get("index", "")),
					str((row as Dictionary).get("material_id", "")),
					str((row as Dictionary).get("body_material_resource_path", "")),
					str((row as Dictionary).get("body_mesh_resource_path", "")),
				])

	var output := ProjectSettings.globalize_path(OUTPUT_PATH)
	var error := _save_viewport_image(root as Viewport, output)
	var dice_viewport = screen.get("dice_viewport")
	if error != OK and dice_viewport != null and dice_viewport.get("sub_viewport") is SubViewport:
		error = _save_viewport_image(dice_viewport.get("sub_viewport") as SubViewport, output)
	print("saved=%s error=%s" % [output, error])
	quit(0 if error == OK else 1)


func _save_viewport_image(viewport: Viewport, output_path: String) -> int:
	if viewport == null:
		return FAILED
	var texture := viewport.get_texture()
	if texture == null:
		return FAILED
	var image := texture.get_image()
	if image == null or image.is_empty():
		return FAILED
	return image.save_png(output_path)
