extends SceneTree


const ENTRY_SCENE_PATH := "res://scenes/main/Main.tscn"
const OUTPUT_PATH := "res://tests_or_debug/captures/gm_dice_visual_acceptance.png"
const STABLE_OUTPUT_PATH := "res://tests_or_debug/captures/gm_throw_scene/after_actual_gm_throw_scene.png"
const DICE_VIEWPORT_OUTPUT_PATH := "res://tests_or_debug/captures/gm_throw_scene/after_actual_gm_dice_viewport.png"
const BEFORE_TEXTURE_FIX_DICE_VIEWPORT_OUTPUT_PATH := "res://tests_or_debug/captures/gm_throw_scene/before_texture_fix_gm_dice_viewport.png"
const MANIFEST_PATH := "res://tests_or_debug/captures/gm_throw_scene/latest_manifest.json"
const CAPTURE_DICE_COUNT := 6
const PHYSICAL_SETTLE_MAX_FRAMES := 900


func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1680, 960))
	root.size = Vector2i(1680, 960)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests_or_debug/captures"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests_or_debug/captures/gm_throw_scene"))

	var scene := load(ENTRY_SCENE_PATH)
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame
	if main.has_method("_on_gm_physics_dice_test_pressed"):
		main.call("_on_gm_physics_dice_test_pressed")
	await process_frame
	await process_frame
	await process_frame
	var screen := _find_automation_screen(main)
	if screen == null:
		push_error("Cannot find GM physics dice screen after entering from Main.tscn")
		quit(1)
		return
	await process_frame
	await process_frame
	await process_frame
	if screen.has_method("automation_clear"):
		screen.call("automation_clear")
	if screen.has_method("automation_set_dice_count"):
		screen.call("automation_set_dice_count", CAPTURE_DICE_COUNT)
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
	if OS.get_environment("DICE_GM_CAPTURE_HIDE_FACE_TEXTURES") == "1":
		_set_face_texture_layers_visible(screen, false)
	if not await _run_physical_settle_capture(screen):
		push_error("GM visual acceptance capture did not reach physical settled state")
		quit(1)
		return

	var output := ProjectSettings.globalize_path(OUTPUT_PATH)
	var stable_output := ProjectSettings.globalize_path(STABLE_OUTPUT_PATH)
	var dice_viewport_output := ProjectSettings.globalize_path(
		BEFORE_TEXTURE_FIX_DICE_VIEWPORT_OUTPUT_PATH if OS.get_environment("DICE_GM_CAPTURE_HIDE_FACE_TEXTURES") == "1" else DICE_VIEWPORT_OUTPUT_PATH
	)
	var error := _save_viewport_image(root as Viewport, output)
	if error == OK:
		error = _save_viewport_image(root as Viewport, stable_output)
	var dice_viewport = screen.get("dice_viewport")
	var dice_viewport_error := FAILED
	if dice_viewport != null and dice_viewport.get("sub_viewport") is SubViewport:
		dice_viewport_error = _save_viewport_image(dice_viewport.get("sub_viewport") as SubViewport, dice_viewport_output)
	if error != OK and dice_viewport_error == OK:
		error = dice_viewport_error
	if error == OK and screen.has_method("automation_get_snapshot"):
		_save_manifest(screen.call("automation_get_snapshot"), stable_output, dice_viewport_output)
	print("saved=%s error=%s" % [output, error])
	quit(0 if error == OK else 1)


func _find_automation_screen(node: Node) -> Node:
	if node != null and node.has_method("automation_get_snapshot") and node.has_method("automation_set_dice_count"):
		return node
	for child in node.get_children():
		var found := _find_automation_screen(child)
		if found != null:
			return found
	return null


func _run_physical_settle_capture(screen: Node) -> bool:
	if screen == null or not screen.has_method("automation_drop_random") or not screen.has_method("automation_get_snapshot"):
		return false
	screen.call("automation_drop_random", CAPTURE_DICE_COUNT)
	for _frame in range(PHYSICAL_SETTLE_MAX_FRAMES):
		await physics_frame
		var snapshot: Dictionary = screen.call("automation_get_snapshot")
		if int(snapshot.get("pending_ready_returns", 0)) > 0 and _all_dice_have_settled(snapshot):
			return true
	return false


func _all_dice_have_settled(snapshot: Dictionary) -> bool:
	var rows: Array = snapshot.get("dice", [])
	if rows.size() < CAPTURE_DICE_COUNT:
		return false
	for row in rows:
		if not (row is Dictionary):
			return false
		var data := row as Dictionary
		if int(data.get("last_settled_face_value", 0)) < 1:
			return false
		var position: Vector3 = data.get("last_settled_position", Vector3.ZERO)
		if position.y < -0.20 or position.y > 1.20:
			return false
	return true


func _save_manifest(snapshot: Dictionary, output_path: String, dice_viewport_output_path: String) -> void:
	var manifest := {
		"entry_scene": ENTRY_SCENE_PATH,
		"capture_scene": "res://scenes/debug/GmPhysicsDiceTestScreen.tscn",
		"capture_phase": "physical_settle_after_drop",
		"capture_wait_max_frames": PHYSICAL_SETTLE_MAX_FRAMES,
		"output": output_path,
		"dice_viewport_output": dice_viewport_output_path,
		"camera_fov": snapshot.get("camera_fov", 0.0),
		"camera_pitch": snapshot.get("camera_pitch", 0.0),
		"camera_position": str(snapshot.get("camera_position", Vector3.ZERO)),
		"camera_look_at": str(snapshot.get("camera_look_at", Vector3.ZERO)),
		"dice_count": snapshot.get("dice_count", 0),
		"settled": _all_dice_have_settled(snapshot),
		"settled_positions": _dice_settled_positions(snapshot),
		"body_mesh_paths": _dice_body_mesh_paths(snapshot),
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t"))


func _dice_body_mesh_paths(snapshot: Dictionary) -> Array:
	var paths := []
	for row in snapshot.get("dice", []):
		if row is Dictionary:
			paths.append(str((row as Dictionary).get("body_mesh_resource_path", "")))
	return paths


func _dice_settled_positions(snapshot: Dictionary) -> Array:
	var positions := []
	for row in snapshot.get("dice", []):
		if row is Dictionary:
			positions.append(str((row as Dictionary).get("last_settled_position", Vector3.ZERO)))
	return positions


func _set_face_texture_layers_visible(node: Node, visible: bool) -> void:
	if node.name == "FaceTextureLayer" and node is Node3D:
		(node as Node3D).visible = visible
	for child in node.get_children():
		_set_face_texture_layers_visible(child, visible)


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
