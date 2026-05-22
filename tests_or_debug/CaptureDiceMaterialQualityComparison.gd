extends SceneTree


const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const GmDiceMaterialPreviewViewport = preload("res://scripts/ui/debug/GmDiceMaterialPreviewViewport.gd")


const CAPTURE_DIR := "res://tests_or_debug/captures/dice_material_quality"
const MANIFEST_PATH := "res://tests_or_debug/captures/dice_material_quality/latest_manifest.json"
const PREVIEW_SOURCE := "res://scripts/ui/debug/GmDiceMaterialPreviewViewport.gd"
const DEFAULT_STAGE_ID := "preview_lighting_rig_final"
const DEFAULT_LIGHTING_ID := "production_preview"
const OUTPUT_SIZE := Vector2i(1680, 720)
const PREVIEW_SIZE := Vector2(512, 384)
const CAPTURE_METHOD := "display_server_window_rect"
const CAPTURE_SETTLE_FRAMES := 120
const CAPTURE_SETTLE_SECONDS := 2.0
const MATERIAL_ROWS := [
	{"id": GmDiceDefinition.MATERIAL_BRONZE, "label": "青铜"},
	{"id": GmDiceDefinition.MATERIAL_GOLD, "label": "黄金"},
	{"id": GmDiceDefinition.MATERIAL_REPRO_GOLD, "label": "星金"},
]


func _init() -> void:
	print("--- CaptureDiceMaterialQualityComparison: start ---")
	var stage_id := _stage_id_from_args()
	var requested_lighting_id := _lighting_id_from_args()
	var capture_options := _capture_options(stage_id)
	var output_res := "%s/%s.png" % [CAPTURE_DIR, stage_id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_EXCLUDE_FROM_CAPTURE, false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_size(OUTPUT_SIZE)
	root.size = OUTPUT_SIZE

	var holder := _build_capture_layout()
	root.add_child(holder)

	var row := holder.find_child("ProductionPreviewRow", true, false) as Control
	var previews := _populate_previews(row, capture_options)
	await _wait_for_capture_settle()

	var output_path := ProjectSettings.globalize_path(output_res)
	var error := _save_window_image(output_path)
	var manifest_error := _save_manifest(stage_id, requested_lighting_id, output_path, previews, capture_options)
	print("capture_source=%s" % PREVIEW_SOURCE)
	print("capture_method=%s" % CAPTURE_METHOD)
	print("saved=%s error=%s manifest_error=%s" % [output_path, error, manifest_error])
	print("--- CaptureDiceMaterialQualityComparison: end ---")
	quit(0 if error == OK and manifest_error == OK else 1)


func _build_capture_layout() -> Control:
	var root_control := Control.new()
	root_control.name = "DiceMaterialQualityProductionPreviewCapture"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.name = "ProductionPreviewBackdrop"
	background.color = Color(0.075, 0.090, 0.115, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(background)

	var margin := MarginContainer.new()
	margin.name = "ProductionPreviewMargin"
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 116)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 92)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "ProductionPreviewRow"
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)
	return root_control


func _populate_previews(row: Control, capture_options: Dictionary) -> Array[Dictionary]:
	var previews: Array[Dictionary] = []
	if row == null:
		return previews
	var show_labels := bool(capture_options.get("show_labels", true))
	var show_pips := bool(capture_options.get("show_pips", true))
	var clean_body := bool(capture_options.get("clean_body_diagnostic", false))
	var lighting_preset := StringName(str(capture_options.get("lighting_preset", "neutral")))
	for material_row in MATERIAL_ROWS:
		var material_id: StringName = material_row["id"]
		var column := VBoxContainer.new()
		column.name = "ProductionPreviewColumn_%s" % str(material_id)
		column.add_theme_constant_override("separation", 14)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(column)

		if show_labels:
			var label := Label.new()
			label.name = "ProductionPreviewLabel_%s" % str(material_id)
			label.text = str(material_row["label"])
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.90, 1.0))
			label.add_theme_font_size_override("font_size", 24)
			column.add_child(label)

		var preview := GmDiceMaterialPreviewViewport.new()
		preview.name = "ProductionPreview_%s" % str(material_id)
		preview.custom_minimum_size = PREVIEW_SIZE
		preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		column.add_child(preview)
		preview.build(material_id, false)
		preview.set_show_pips(show_pips)
		preview.set_clean_body_diagnostic_enabled(clean_body)
		preview.apply_lighting_preset(lighting_preset)
		previews.append({
			"material_id": str(material_id),
			"label": str(material_row["label"]),
			"preview": preview,
		})
	return previews


func _stage_id_from_args() -> String:
	return _arg_value("--material-quality-stage", DEFAULT_STAGE_ID)


func _lighting_id_from_args() -> String:
	return _arg_value("--material-quality-lighting", DEFAULT_LIGHTING_ID)


func _capture_options(stage_id: String) -> Dictionary:
	match stage_id:
		"clean_body_material_diagnostic":
			return {
				"show_labels": false,
				"show_pips": false,
				"clean_body_diagnostic": true,
				"lighting_preset": "body_diagnostic",
			}
		"normals_repaired":
			return {
				"show_labels": false,
				"show_pips": false,
				"clean_body_diagnostic": false,
				"lighting_preset": "normal_diagnostic",
			}
		_:
			return {
				"show_labels": true,
				"show_pips": true,
				"clean_body_diagnostic": false,
				"lighting_preset": "neutral",
			}


func _arg_value(name: String, fallback: String) -> String:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	for index in range(args.size()):
		if str(args[index]) == name and index + 1 < args.size():
			return _sanitize_id(str(args[index + 1]), fallback)
	return fallback


func _wait_for_capture_settle() -> void:
	for _frame in range(CAPTURE_SETTLE_FRAMES):
		DisplayServer.process_events()
		await process_frame
	await create_timer(CAPTURE_SETTLE_SECONDS).timeout
	await process_frame
	await process_frame


func _sanitize_id(value: String, fallback: String) -> String:
	var result := ""
	for index in range(value.length()):
		var code := value.unicode_at(index)
		var is_digit := code >= 48 and code <= 57
		var is_upper := code >= 65 and code <= 90
		var is_lower := code >= 97 and code <= 122
		if is_digit or is_upper or is_lower or value[index] == "_" or value[index] == "-":
			result += value[index]
	return result if not result.is_empty() else fallback


func _save_window_image(output_path: String) -> int:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_EXCLUDE_FROM_CAPTURE, false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.process_events()
	var rect := Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	if rect.size.x <= 0 or rect.size.y <= 0:
		push_error("Cannot capture material quality screenshot: invalid window rect %s" % str(rect))
		return FAILED
	var image := DisplayServer.screen_get_image_rect(rect)
	if image == null or image.is_empty():
		push_error("Cannot capture material quality screenshot from OS window rect: %s" % str(rect))
		return FAILED
	return image.save_png(output_path)


func _save_manifest(stage_id: String, requested_lighting_id: String, output_path: String, previews: Array[Dictionary], capture_options: Dictionary) -> int:
	var manifest := {
		"stage": stage_id,
		"requested_lighting": requested_lighting_id,
		"capture_options": capture_options,
		"capture_source": PREVIEW_SOURCE,
		"capture_method": CAPTURE_METHOD,
		"capture_settle_frames": CAPTURE_SETTLE_FRAMES,
		"capture_settle_seconds": CAPTURE_SETTLE_SECONDS,
		"window_borderless": DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS),
		"window_position": str(DisplayServer.window_get_position()),
		"window_size": str(DisplayServer.window_get_size()),
		"output": output_path,
		"materials": [],
	}
	for row in previews:
		var preview := row.get("preview") as GmDiceMaterialPreviewViewport
		if preview == null:
			continue
		var snapshot := preview.get_snapshot()
		manifest["materials"].append({
			"id": str(row.get("material_id", "")),
			"label": str(row.get("label", "")),
			"material_source_path": str(snapshot.get("material_source_path", "")),
			"material_instance_resource_path": str(snapshot.get("material_resource_path", "")),
			"mesh_resource_path": str(snapshot.get("mesh_resource_path", "")),
			"has_reflection_probe": bool(snapshot.get("has_reflection_probe", false)),
			"has_preview_lighting_rig": bool(snapshot.get("has_preview_lighting_rig", false)),
			"clean_body_diagnostic_enabled": bool(snapshot.get("clean_body_diagnostic_enabled", false)),
			"lighting": snapshot.get("lighting", {}),
			"lighting_rig": snapshot.get("lighting_rig", {}),
		})
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_string(JSON.stringify(manifest, "\t"))
	return OK
