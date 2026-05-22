extends SceneTree


const BASE_DIR := "res://tests_or_debug/visual_acceptance/shader_light"
const TMP_REPORT_DIR := "res://tests_or_debug/tmp_report/visual_acceptance/shader_light"
const CASES_DIR := BASE_DIR + "/cases"
const OUTPUTS_DIR := TMP_REPORT_DIR + "/outputs"
const LATEST_DIR := TMP_REPORT_DIR + "/latest"
const REPORTS_DIR := TMP_REPORT_DIR + "/reports"
const GM_SCENE_PATH := "res://scenes/debug/gm_dice_scene_visual_repro.tscn"
const RESOLUTION := Vector2i(1920, 1080)
const SUPPORTED_TYPES := ["shader_material", "lighting_effect"]
const CASE_ORDER := ["dice_shader_basic", "table_shader_basic", "light_effect_basic"]


func _init() -> void:
	var exit_code := await _run()
	quit(exit_code)


func _run() -> int:
	var args := _get_user_args()
	if not args.has("--shader-light-va"):
		return _fail("Missing --shader-light-va")

	var selection := _parse_selection(args)
	if not selection.get("ok", false):
		return _fail(str(selection.get("error", "Invalid arguments")))

	var run_id := _make_run_id()
	var git_hash := _read_command_text("git", ["rev-parse", "--short", "HEAD"])
	var git_branch := _read_command_text("git", ["rev-parse", "--abbrev-ref", "HEAD"])
	if git_hash.is_empty():
		git_hash = "unknown"
	if git_branch.is_empty():
		git_branch = "unknown"

	if not _ensure_base_dirs():
		return _fail("Cannot prepare shader/light visual acceptance directories")
	if not _clear_latest_dir():
		return _fail("Cannot clear latest directory; visual acceptance aborted")

	var all_cases := _load_cases()
	if all_cases.is_empty():
		return _fail("No valid shader/light visual acceptance cases found")

	var selected_cases := _select_cases(all_cases, selection)
	if selected_cases.is_empty():
		return _fail("No cases matched the requested filter")

	DisplayServer.window_set_size(RESOLUTION)
	root.size = RESOLUTION

	var packed := load(GM_SCENE_PATH) as PackedScene
	if packed == null:
		return _fail("Cannot load GM visual acceptance scene: %s" % GM_SCENE_PATH)
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var camera := scene.get_node_or_null("VA_Camera3D") as Camera3D
	var marker_root := scene.get_node_or_null("VA_CameraMarkers") as Node3D
	var watermark := scene.get_node_or_null("VA_WatermarkLayer/VA_WatermarkLabel") as Label
	if camera == null:
		return _fail("Missing VA_Camera3D in GM visual acceptance scene")
	if marker_root == null:
		return _fail("Missing VA_CameraMarkers in GM visual acceptance scene")
	if watermark == null:
		return _fail("Missing VA_WatermarkLayer/VA_WatermarkLabel in GM visual acceptance scene")

	var manifest := {
		"run_id": run_id,
		"generated_at": _make_timestamp_text(),
		"scene": GM_SCENE_PATH,
		"git": git_hash,
		"branch": git_branch,
		"resolution": {"width": RESOLUTION.x, "height": RESOLUTION.y},
		"status": "valid",
		"cases": [],
		"latest_invalid_pngs": [],
	}
	var registered_latest := {}

	for case_data in selected_cases:
		var capture_result := await _capture_case(case_data, run_id, git_hash, git_branch, camera, marker_root, watermark)
		if not capture_result.get("ok", false):
			return _fail(str(capture_result.get("error", "Capture failed")))
		var entry: Dictionary = capture_result.get("entry", {})
		manifest["cases"].append(entry)
		registered_latest[str(entry.get("latest_png_res", ""))] = true

	var invalid_pngs := _find_unregistered_latest_pngs(registered_latest)
	if not invalid_pngs.is_empty():
		manifest["status"] = "invalid"
		manifest["latest_invalid_pngs"] = invalid_pngs

	root.remove_child(scene)
	scene.free()
	await process_frame
	await process_frame

	if not _write_manifest(run_id, manifest):
		return _fail("Cannot write manifest for run_id %s" % run_id)
	if not _write_report(run_id, manifest):
		return _fail("Cannot write visual report for run_id %s" % run_id)

	if manifest["status"] != "valid":
		print("FAIL: shader/light visual acceptance invalid, unregistered latest png detected")
		return 1

	print("PASS: shader/light visual acceptance run_id=%s cases=%d" % [run_id, selected_cases.size()])
	return 0


func _get_user_args() -> Array:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	return args


func _parse_selection(args: Array) -> Dictionary:
	var selection := {"ok": true, "all": false, "case_id": "", "type": ""}
	for index in range(args.size()):
		var arg := str(args[index])
		match arg:
			"--all":
				selection["all"] = true
			"--case":
				if index + 1 >= args.size():
					return {"ok": false, "error": "--case requires a case id"}
				selection["case_id"] = str(args[index + 1])
			"--type":
				if index + 1 >= args.size():
					return {"ok": false, "error": "--type requires shader_material or lighting_effect"}
				selection["type"] = str(args[index + 1])
	if str(selection["type"]) != "" and not SUPPORTED_TYPES.has(str(selection["type"])):
		return {"ok": false, "error": "Unsupported type: %s" % selection["type"]}
	if not bool(selection["all"]) and str(selection["case_id"]) == "" and str(selection["type"]) == "":
		return {"ok": false, "error": "Expected --all, --case, or --type"}
	return selection


func _ensure_base_dirs() -> bool:
	var ok := true
	for path in [CASES_DIR, BASE_DIR + "/tools", OUTPUTS_DIR, LATEST_DIR, REPORTS_DIR]:
		ok = _ensure_dir(path) and ok
	return ok


func _ensure_dir(res_path: String) -> bool:
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(res_path))
	return error == OK or error == ERR_ALREADY_EXISTS


func _clear_latest_dir() -> bool:
	if not _ensure_dir(LATEST_DIR):
		return false
	var latest_abs := ProjectSettings.globalize_path(LATEST_DIR)
	if not _clear_dir_contents_abs(latest_abs):
		return false
	return _directory_pngs_abs(latest_abs).is_empty()


func _clear_dir_contents_abs(abs_path: String) -> bool:
	var dir := DirAccess.open(abs_path)
	if dir == null:
		return false
	dir.list_dir_begin()
	while true:
		var item := dir.get_next()
		if item == "":
			break
		if item == "." or item == "..":
			continue
		var child_abs := abs_path.path_join(item)
		if dir.current_is_dir():
			if not _clear_dir_contents_abs(child_abs):
				dir.list_dir_end()
				return false
			var remove_dir_error := DirAccess.remove_absolute(child_abs)
			if remove_dir_error != OK:
				dir.list_dir_end()
				return false
		else:
			var remove_file_error := DirAccess.remove_absolute(child_abs)
			if remove_file_error != OK:
				dir.list_dir_end()
				return false
	dir.list_dir_end()
	return true


func _load_cases() -> Array:
	var by_id := {}
	var dir := DirAccess.open(CASES_DIR)
	if dir == null:
		push_error("Cannot open cases directory: %s" % CASES_DIR)
		return []
	var files := dir.get_files()
	files.sort()
	for file_name in files:
		if not str(file_name).ends_with(".json"):
			continue
		var path := CASES_DIR.path_join(str(file_name))
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (parsed is Dictionary):
			push_error("Case JSON is invalid: %s" % path)
			continue
		var case_data: Dictionary = parsed
		var case_id := str(case_data.get("id", ""))
		var case_type := str(case_data.get("type", ""))
		if case_id.is_empty() or not SUPPORTED_TYPES.has(case_type):
			push_error("Case is missing id or has unsupported type: %s" % path)
			continue
		by_id[case_id] = case_data

	var ordered := []
	for case_id in CASE_ORDER:
		if by_id.has(case_id):
			ordered.append(by_id[case_id])
	for case_id in by_id.keys():
		if not CASE_ORDER.has(str(case_id)):
			ordered.append(by_id[case_id])
	return ordered


func _select_cases(all_cases: Array, selection: Dictionary) -> Array:
	var selected := []
	var case_filter := str(selection.get("case_id", ""))
	var type_filter := str(selection.get("type", ""))
	for case_data in all_cases:
		if not (case_data is Dictionary):
			continue
		var row: Dictionary = case_data
		if case_filter != "" and str(row.get("id", "")) != case_filter:
			continue
		if type_filter != "" and str(row.get("type", "")) != type_filter:
			continue
		selected.append(row)
	return selected


func _capture_case(
	case_data: Dictionary,
	run_id: String,
	git_hash: String,
	git_branch: String,
	camera: Camera3D,
	marker_root: Node3D,
	watermark: Label
) -> Dictionary:
	var case_id := str(case_data.get("id", ""))
	var case_type := str(case_data.get("type", ""))
	var marker_name := str(case_data.get("camera_marker", ""))
	var marker := marker_root.get_node_or_null(marker_name) as Marker3D
	if marker == null:
		return {"ok": false, "error": "Missing camera_marker %s for case %s" % [marker_name, case_id]}

	var capture: Dictionary = case_data.get("capture", {}) if case_data.get("capture", {}) is Dictionary else {}
	var capture_id := str(capture.get("id", "main"))
	var wait_time := float(capture.get("time", 0.35))
	var seed_value := int(case_data.get("seed", 1))
	seed(seed_value)

	camera.global_transform = marker.global_transform
	var camera_data: Dictionary = case_data.get("camera", {}) if case_data.get("camera", {}) is Dictionary else {}
	camera.fov = float(camera_data.get("fov", camera.fov))
	if camera_data.has("target"):
		camera.look_at(_vector3_from_value(camera_data.get("target", []), Vector3.ZERO), Vector3.UP)
	camera.current = true

	var watermark_text := _make_watermark_text(run_id, case_type, case_id, capture_id, git_hash, git_branch, seed_value)
	watermark.text = watermark_text
	watermark.visible = true

	await process_frame
	await process_frame
	if wait_time > 0.0:
		await create_timer(wait_time).timeout
	await process_frame

	var image := _capture_root_image()
	if image == null:
		return {"ok": false, "error": "Cannot capture viewport image for case %s" % case_id}

	var file_name := "%s_%s.png" % [case_id, capture_id]
	var output_res := OUTPUTS_DIR.path_join(run_id).path_join(case_type).path_join(case_id).path_join(file_name)
	var latest_res := LATEST_DIR.path_join(case_type).path_join(case_id).path_join(file_name)
	if not _save_image_png(image, output_res):
		return {"ok": false, "error": "Cannot save output screenshot: %s" % output_res}
	if not _save_image_png(image, latest_res):
		return {"ok": false, "error": "Cannot sync latest screenshot: %s" % latest_res}

	var entry := {
		"run_id": run_id,
		"id": case_id,
		"type": case_type,
		"capture": capture_id,
		"camera_marker": marker_name,
		"seed": seed_value,
		"resolution": {"width": RESOLUTION.x, "height": RESOLUTION.y},
		"git": git_hash,
		"branch": git_branch,
		"output_png_res": output_res,
		"latest_png_res": latest_res,
		"watermark": watermark_text,
		"valid": true,
	}
	print("captured case=%s type=%s latest=%s" % [case_id, case_type, latest_res])
	return {"ok": true, "entry": entry}


func _capture_root_image() -> Image:
	var texture := root.get_texture()
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		return null
	return image


func _save_image_png(image: Image, res_path: String) -> bool:
	var dir_res := res_path.get_base_dir()
	if not _ensure_dir(dir_res):
		return false
	var error := image.save_png(ProjectSettings.globalize_path(res_path))
	return error == OK


func _find_unregistered_latest_pngs(registered_latest: Dictionary) -> Array:
	var invalid := []
	for abs_path in _directory_pngs_abs(ProjectSettings.globalize_path(LATEST_DIR)):
		var res_path := _absolute_to_res(abs_path)
		if not registered_latest.has(res_path):
			invalid.append(res_path)
	invalid.sort()
	return invalid


func _directory_pngs_abs(abs_path: String) -> Array:
	var results := []
	_collect_pngs_abs(abs_path, results)
	return results


func _collect_pngs_abs(abs_path: String, results: Array) -> void:
	var dir := DirAccess.open(abs_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var item := dir.get_next()
		if item == "":
			break
		if item == "." or item == "..":
			continue
		var child_abs := abs_path.path_join(item)
		if dir.current_is_dir():
			_collect_pngs_abs(child_abs, results)
		elif str(item).to_lower().ends_with(".png"):
			results.append(child_abs)
	dir.list_dir_end()


func _write_manifest(run_id: String, manifest: Dictionary) -> bool:
	var manifest_res := REPORTS_DIR.path_join("%s_manifest.json" % run_id)
	var file := FileAccess.open(ProjectSettings.globalize_path(manifest_res), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(manifest, "\t"))
	var error := file.get_error()
	file = null
	return error == OK


func _write_report(run_id: String, manifest: Dictionary) -> bool:
	var report_res := REPORTS_DIR.path_join("%s_visual_report.md" % run_id)
	var lines := PackedStringArray()
	lines.append("# Shader / Light Visual Acceptance")
	lines.append("")
	lines.append("- Run ID: `%s`" % run_id)
	lines.append("- Status: `%s`" % manifest.get("status", "invalid"))
	lines.append("- Git: `%s`" % manifest.get("git", "unknown"))
	lines.append("- Branch: `%s`" % manifest.get("branch", "unknown"))
	lines.append("- Resolution: `%dx%d`" % [RESOLUTION.x, RESOLUTION.y])
	lines.append("- Scene: `%s`" % GM_SCENE_PATH)
	lines.append("")
	lines.append("Only images listed in this run manifest are valid acceptance images for this report.")
	lines.append("")
	for entry_value in manifest.get("cases", []):
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		if str(entry.get("run_id", "")) != run_id:
			continue
		var latest_res := str(entry.get("latest_png_res", ""))
		lines.append("## %s" % entry.get("id", "unknown"))
		lines.append("")
		lines.append("- Type: `%s`" % entry.get("type", ""))
		lines.append("- Capture: `%s`" % entry.get("capture", ""))
		lines.append("- Seed: `%s`" % entry.get("seed", ""))
		lines.append("- Latest: `%s`" % latest_res)
		lines.append("")
		lines.append("![%s](../latest/%s/%s/%s_%s.png)" % [
			entry.get("id", "case"),
			entry.get("type", ""),
			entry.get("id", ""),
			entry.get("id", ""),
			entry.get("capture", ""),
		])
		lines.append("")
	var invalid_pngs: Array = manifest.get("latest_invalid_pngs", [])
	if not invalid_pngs.is_empty():
		lines.append("## Invalid Latest PNGs")
		lines.append("")
		for png in invalid_pngs:
			lines.append("- `%s`" % png)
		lines.append("")

	var file := FileAccess.open(ProjectSettings.globalize_path(report_res), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string("\n".join(lines))
	var error := file.get_error()
	file = null
	return error == OK


func _make_watermark_text(
	run_id: String,
	case_type: String,
	case_id: String,
	capture_id: String,
	git_hash: String,
	git_branch: String,
	seed_value: int
) -> String:
	return "\n".join(PackedStringArray([
		"Run ID: %s" % run_id,
		"Type: %s" % case_type,
		"Case: %s" % case_id,
		"Capture: %s" % capture_id,
		"Git: %s" % git_hash,
		"Branch: %s" % git_branch,
		"Seed: %d" % seed_value,
		"Resolution: %dx%d" % [RESOLUTION.x, RESOLUTION.y],
	]))


func _vector3_from_value(value, fallback: Vector3) -> Vector3:
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback


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


func _absolute_to_res(abs_path: String) -> String:
	var project_abs := ProjectSettings.globalize_path("res://").replace("\\", "/")
	var normalized := abs_path.replace("\\", "/")
	if normalized.begins_with(project_abs):
		var relative := normalized.substr(project_abs.length())
		if relative.begins_with("/"):
			relative = relative.substr(1)
		return "res://%s" % relative
	return normalized


func _fail(message: String) -> int:
	print("FAIL: %s" % message)
	push_error(message)
	return 1
