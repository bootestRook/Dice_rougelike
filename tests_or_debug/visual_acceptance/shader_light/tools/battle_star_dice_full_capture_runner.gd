extends SceneTree


const LightingRig := preload("res://scripts/ui/debug/star_dice_full/LightingRig.gd")

const SCENE_PATH := "res://scenes/debug/battle_star_dice_full.tscn"
const TMP_REPORT_DIR := "res://tests_or_debug/tmp_report/visual_acceptance/shader_light"
const OUTPUT_DIR := TMP_REPORT_DIR + "/outputs"
const REPORT_DIR := TMP_REPORT_DIR + "/reports"
const CASE_TYPE := "full_scene_repro"
const CASE_ID := "battle_star_dice_full"
const REFERENCE_IMAGE_PATH := "res://reference/场景参考图.png"
const RESOLUTION := Vector2i(1920, 1080)


func _init() -> void:
	var exit_code := await _run()
	quit(exit_code)


func _run() -> int:
	var args := _get_user_args()
	if not args.has("--battle-star-dice-full-capture"):
		return _fail("Missing --battle-star-dice-full-capture")
	var run_id := _make_run_id()
	var git_hash := _read_command_text("git", ["rev-parse", "--short", "HEAD"])
	var git_branch := _read_command_text("git", ["rev-parse", "--abbrev-ref", "HEAD"])
	if git_hash.is_empty():
		git_hash = "unknown"
	if git_branch.is_empty():
		git_branch = "unknown"
	if not _ensure_dir(OUTPUT_DIR.path_join(run_id).path_join(CASE_TYPE).path_join(CASE_ID)):
		return _fail("Cannot prepare output directory")
	if not _ensure_dir(REPORT_DIR):
		return _fail("Cannot prepare report directory")

	DisplayServer.window_set_size(RESOLUTION)
	root.size = RESOLUTION

	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		return _fail("Cannot load scene: %s" % SCENE_PATH)
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var camera := scene.get_node_or_null("VA_Camera3D") as Camera3D
	if camera == null:
		camera = scene.get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return _fail("Missing camera in scene")
	camera.current = true

	var manifest := {
		"run_id": run_id,
		"generated_at": _make_timestamp_text(),
		"scene": SCENE_PATH,
		"git": git_hash,
		"branch": git_branch,
		"resolution": {"width": RESOLUTION.x, "height": RESOLUTION.y},
		"case": CASE_ID,
		"valid": true,
		"captures": [],
	}

	var postprocess_image: Image = null
	var capture_specs := [
		{"id": "no_postprocess", "postprocess": false},
		{"id": "postprocess_on", "postprocess": true},
	]
	for spec in capture_specs:
		var capture_id := str(spec["id"])
		_set_scene_postprocess(scene, bool(spec["postprocess"]))
		await process_frame
		await process_frame
		await create_timer(0.45).timeout
		var image := _capture_root_image()
		if image == null:
			return _fail("Cannot capture %s" % capture_id)
		var output_res := _capture_output_res(run_id, git_hash, capture_id)
		if not _save_image_png(image, output_res):
			return _fail("Cannot save %s" % output_res)
		manifest["captures"].append(_capture_manifest_entry(run_id, git_hash, capture_id, output_res))
		if capture_id == "postprocess_on":
			postprocess_image = image.duplicate()

	if postprocess_image == null:
		return _fail("Missing postprocess image for reference comparison")
	var compare_image := _make_reference_compare_image(postprocess_image)
	if compare_image == null:
		return _fail("Cannot make reference_compare image")
	var compare_res := _capture_output_res(run_id, git_hash, "reference_compare")
	if not _save_image_png(compare_image, compare_res):
		return _fail("Cannot save %s" % compare_res)
	manifest["captures"].append(_capture_manifest_entry(run_id, git_hash, "reference_compare", compare_res))

	root.remove_child(scene)
	scene.free()
	await process_frame
	await process_frame

	if not _write_manifest(run_id, manifest):
		return _fail("Cannot write manifest")
	print("PASS: battle_star_dice_full capture run_id=%s git=%s" % [run_id, git_hash])
	return 0


func _set_scene_postprocess(scene: Node, enabled: bool) -> void:
	var env_node := _find_node(scene, "WorldEnvironment") as WorldEnvironment
	if env_node != null and env_node.environment != null:
		LightingRig.set_postprocess_enabled(env_node.environment, enabled)


func _capture_output_res(run_id: String, git_hash: String, capture_id: String) -> String:
	var file_name := "%s_%s_%s_%s.png" % [CASE_ID, capture_id, run_id, git_hash]
	return OUTPUT_DIR.path_join(run_id).path_join(CASE_TYPE).path_join(CASE_ID).path_join(file_name)


func _capture_manifest_entry(run_id: String, git_hash: String, capture_id: String, output_res: String) -> Dictionary:
	return {
		"run_id": run_id,
		"git": git_hash,
		"id": CASE_ID,
		"type": CASE_TYPE,
		"capture": capture_id,
		"output_png_res": output_res,
		"filename_contains_timestamp_and_git": output_res.get_file().contains(run_id) and output_res.get_file().contains(git_hash),
	}


func _capture_root_image() -> Image:
	var texture := root.get_texture()
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		return null
	return image


func _make_reference_compare_image(current_image: Image) -> Image:
	var reference := Image.load_from_file(ProjectSettings.globalize_path(REFERENCE_IMAGE_PATH))
	if reference == null or reference.is_empty():
		return null
	var left := reference.duplicate()
	var right := current_image.duplicate()
	left.convert(Image.FORMAT_RGBA8)
	right.convert(Image.FORMAT_RGBA8)
	left.resize(RESOLUTION.x / 2, RESOLUTION.y, Image.INTERPOLATE_LANCZOS)
	right.resize(RESOLUTION.x / 2, RESOLUTION.y, Image.INTERPOLATE_LANCZOS)
	var composite := Image.create(RESOLUTION.x, RESOLUTION.y, false, Image.FORMAT_RGBA8)
	composite.fill(Color(0.01, 0.015, 0.04, 1.0))
	composite.blit_rect(left, Rect2i(Vector2i.ZERO, Vector2i(RESOLUTION.x / 2, RESOLUTION.y)), Vector2i.ZERO)
	composite.blit_rect(right, Rect2i(Vector2i.ZERO, Vector2i(RESOLUTION.x / 2, RESOLUTION.y)), Vector2i(RESOLUTION.x / 2, 0))
	return composite


func _save_image_png(image: Image, res_path: String) -> bool:
	if not _ensure_dir(res_path.get_base_dir()):
		return false
	var error := image.save_png(ProjectSettings.globalize_path(res_path))
	return error == OK


func _write_manifest(run_id: String, manifest: Dictionary) -> bool:
	var manifest_res := REPORT_DIR.path_join("%s_%s_manifest.json" % [CASE_ID, run_id])
	var file := FileAccess.open(ProjectSettings.globalize_path(manifest_res), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(manifest, "\t"))
	var error := file.get_error()
	file = null
	return error == OK


func _ensure_dir(res_path: String) -> bool:
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(res_path))
	return error == OK or error == ERR_ALREADY_EXISTS


func _find_node(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_node(child, node_name)
		if found != null:
			return found
	return null


func _get_user_args() -> Array:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	return args


func _make_run_id() -> String:
	var now := Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d" % [
		int(now["year"]),
		int(now["month"]),
		int(now["day"]),
		int(now["hour"]),
		int(now["minute"]),
		int(now["second"]),
	]


func _make_timestamp_text() -> String:
	var now := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		int(now["year"]),
		int(now["month"]),
		int(now["day"]),
		int(now["hour"]),
		int(now["minute"]),
		int(now["second"]),
	]


func _read_command_text(command: String, args: Array) -> String:
	var output := []
	var exit_code := OS.execute(command, args, output, true)
	if exit_code != 0:
		return ""
	return "\n".join(PackedStringArray(output)).strip_edges()


func _fail(message: String) -> int:
	print("FAIL: %s" % message)
	push_error(message)
	return 1
