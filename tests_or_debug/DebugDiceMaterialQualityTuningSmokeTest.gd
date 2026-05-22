extends SceneTree
class_name DebugDiceMaterialQualityTuningSmokeTest


const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const GmDiceMaterialResolver = preload("res://scripts/ui/debug/gm_dice_port/GmDiceMaterialResolver.gd")
const GmDiceMaterialPreviewViewport = preload("res://scripts/ui/debug/GmDiceMaterialPreviewViewport.gd")
const PreviewLightingRig = preload("res://scripts/ui/debug/PreviewLightingRig.gd")


const COLOR_EPS := 0.006
const LIGHT_RATIO_EPS := 0.025
const BRONZE_COLOR := Color(0.545098, 0.352941, 0.168627, 1.0)
const GOLD_COLOR := Color(0.850980, 0.713725, 0.227451, 1.0)
const STAR_GOLD_COLOR := Color(0.909804, 0.847059, 0.686275, 1.0)
const DIGIT_COLOR := Color(0.960784, 0.949020, 0.909804, 1.0)
const KEY_LIGHT_COLOR := Color(1.0, 0.952, 0.870, 1.0)
const FILL_LIGHT_COLOR := Color(0.650, 0.790, 1.0, 1.0)
const RIM_LIGHT_COLOR := Color(1.0, 0.982, 0.940, 1.0)
const CAPTURE_RUNNER_PATH := "res://tests_or_debug/CaptureDiceMaterialQualityComparison.gd"
const PREVIEW_MESH_PATH := "res://assets/models/dice/preview_rounded_d6_body_mesh.tres"


func _init() -> void:
	print("--- DebugDiceMaterialQualityTuningSmokeTest: start ---")
	var all_passed := true
	all_passed = _check_pipeline_material_targets() and all_passed
	all_passed = _check_star_gold_material_targets() and all_passed
	all_passed = _check_capture_runner_uses_production_preview() and all_passed
	var preview_passed := await _check_preview_lighting_and_digits()
	all_passed = preview_passed and all_passed
	print("PASS: DebugDiceMaterialQualityTuningSmokeTest" if all_passed else "FAIL: DebugDiceMaterialQualityTuningSmokeTest")
	print("--- DebugDiceMaterialQualityTuningSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_pipeline_material_targets() -> bool:
	var ok := true
	var bronze := load("res://assets/materials/dice/bronze_dice.tres") as BaseMaterial3D
	var gold := load("res://assets/materials/dice/gold_dice.tres") as BaseMaterial3D
	ok = _check("bronze material loads", bronze != null) and ok
	ok = _check("gold material loads", gold != null) and ok
	if bronze != null:
		ok = _check_color("bronze albedo is brown-orange old metal", bronze.albedo_color, BRONZE_COLOR) and ok
	if gold != null:
		ok = _check_color("gold albedo is distinct yellow gold", gold.albedo_color, GOLD_COLOR) and ok

	var bronze_stats := _orm_stats("res://assets/textures/dice/bronze/bronze_dice_orm.png")
	var gold_stats := _orm_stats("res://assets/textures/dice/gold/gold_dice_orm.png")
	ok = _check("bronze ORM stats available", not bronze_stats.is_empty()) and ok
	ok = _check("gold ORM stats available", not gold_stats.is_empty()) and ok
	if not bronze_stats.is_empty():
		ok = _check("bronze metallic follows 0.92 target", _in_range(float(bronze_stats["metal_mean"]), 0.90, 0.93)) and ok
		ok = _check("bronze body/panel roughness stays old and heavy", _in_range(float(bronze_stats["rough_mean"]), 0.39, 0.44)) and ok
		ok = _check("bronze edge roughness does not become jewelry-polished", float(bronze_stats["rough_low_ratio"]) <= 0.02) and ok
	if not gold_stats.is_empty():
		ok = _check("gold metallic follows 0.97 target", _in_range(float(gold_stats["metal_mean"]), 0.95, 0.98)) and ok
		ok = _check("gold roughness supports bright gold highlights", _in_range(float(gold_stats["rough_mean"]), 0.23, 0.30)) and ok
		ok = _check("gold edge roughness creates crisp highlights", _in_range(float(gold_stats["rough_low_ratio"]), 0.18, 0.34)) and ok
	if not bronze_stats.is_empty() and not gold_stats.is_empty():
		ok = _check("bronze is rougher than gold", float(bronze_stats["rough_mean"]) > float(gold_stats["rough_mean"]) + 0.10) and ok
		ok = _check("gold is more metallic than bronze", float(gold_stats["metal_mean"]) > float(bronze_stats["metal_mean"]) + 0.03) and ok
	return ok


func _check_star_gold_material_targets() -> bool:
	var ok := true
	var repro_gold := load("res://assets/materials/dice/repro_gold_dice.tres") as ShaderMaterial
	var battle_gold := load("res://assets/materials/dice/battle_star/battle_star_dice_gold.tres") as ShaderMaterial
	ok = _check("star gold repro material loads", repro_gold != null) and ok
	ok = _check("battle star gold material loads", battle_gold != null) and ok
	if repro_gold != null:
		ok = _check_color("star gold repro base color is champagne gold", repro_gold.get_shader_parameter("base_color") as Color, STAR_GOLD_COLOR) and ok
		ok = _check_color("star gold repro digit emission is warm ivory", repro_gold.get_shader_parameter("emission_color") as Color, DIGIT_COLOR) and ok
		ok = _check("star gold repro metallic is 0.96", is_equal_approx(float(repro_gold.get_shader_parameter("metallic")), 0.96)) and ok
		ok = _check("star gold repro roughness body is 0.18", is_equal_approx(float(repro_gold.get_shader_parameter("roughness")), 0.18)) and ok
	if battle_gold != null:
		ok = _check_color("battle star gold base color is champagne gold", battle_gold.get_shader_parameter("base_albedo") as Color, STAR_GOLD_COLOR) and ok
		ok = _check_color("battle star gold digit color is warm ivory", battle_gold.get_shader_parameter("emission_color") as Color, DIGIT_COLOR) and ok
		ok = _check("battle star gold metallic is 0.96", is_equal_approx(float(battle_gold.get_shader_parameter("metallic_value")), 0.96)) and ok
		ok = _check("battle star gold roughness body is 0.18", is_equal_approx(float(battle_gold.get_shader_parameter("roughness_value")), 0.18)) and ok
		ok = _check("battle star gold digit emission energy is 0.5", is_equal_approx(float(battle_gold.get_shader_parameter("emission_energy")), 0.50)) and ok
	return ok


func _check_capture_runner_uses_production_preview() -> bool:
	var text := FileAccess.get_file_as_string(CAPTURE_RUNNER_PATH)
	var ok := _check("material quality capture runner exists", not text.is_empty())
	if text.is_empty():
		return ok
	ok = _check("material quality capture runner uses production preview viewport", text.contains("GmDiceMaterialPreviewViewport")) and ok
	ok = _check("material quality capture runner records production source", text.contains("capture_source") and text.contains("GmDiceMaterialPreviewViewport.gd")) and ok
	ok = _check("material quality capture runner can output clean body diagnostic", text.contains("clean_body_material_diagnostic") and text.contains("set_clean_body_diagnostic_enabled")) and ok
	ok = _check("material quality capture runner can output normals diagnostic", text.contains("normals_repaired") and text.contains("normal_diagnostic")) and ok
	ok = _check("material quality capture runner uses OS window screenshot", text.contains("screen_get_image_rect") and text.contains("window_get_position") and text.contains("window_get_size")) and ok
	ok = _check("material quality capture runner captures a borderless window rect", text.contains("WINDOW_FLAG_BORDERLESS") and text.contains("window_borderless")) and ok
	ok = _check("material quality capture runner waits for rendered window to settle", text.contains("CAPTURE_SETTLE_FRAMES") and text.contains("CAPTURE_SETTLE_SECONDS")) and ok
	ok = _check("material quality capture runner does not use viewport readback", not text.contains("root.get_texture") and not text.contains("get_texture().get_image")) and ok
	ok = _check("material quality capture runner avoids bespoke 3D dice mesh construction", not text.contains("MeshInstance3D.new()") and not text.contains("Label3D.new()") and not text.contains("load_preview_mesh")) and ok
	return ok


func _check_preview_lighting_and_digits() -> bool:
	var ok := true
	for material_id in [GmDiceDefinition.MATERIAL_BRONZE, GmDiceDefinition.MATERIAL_GOLD, GmDiceDefinition.MATERIAL_REPRO_GOLD]:
		ok = _check_color("%s face digit color stays warm ivory" % str(material_id), GmDiceMaterialResolver.face_label_color(material_id), DIGIT_COLOR) and ok

	var preview := GmDiceMaterialPreviewViewport.new()
	root.add_child(preview)
	preview.build(GmDiceDefinition.MATERIAL_REPRO_GOLD, true)
	await process_frame
	await process_frame

	var snapshot: Dictionary = preview.get_snapshot()
	var lighting: Dictionary = snapshot.get("lighting", {})
	ok = _check("preview uses dedicated PreviewLightingRig", bool(snapshot.get("has_preview_lighting_rig", false))) and ok
	ok = _check("preview adds reflection probe", bool(snapshot.get("has_reflection_probe", false))) and ok
	ok = _check("preview key light is product spot", _find_node(preview, "KeyLight_Spot") is SpotLight3D) and ok
	ok = _check("preview fill light is weak omni", _find_node(preview, "FillLight_Omni") is OmniLight3D) and ok
	ok = _check("preview rim light is back spot", _find_node(preview, "RimLight_Spot") is SpotLight3D) and ok
	ok = _check("preview key light uses warm color", _light_color_matches(preview, "KeyLight_Spot", KEY_LIGHT_COLOR)) and ok
	ok = _check("preview fill light uses cool blue color", _light_color_matches(preview, "FillLight_Omni", FILL_LIGHT_COLOR)) and ok
	ok = _check("preview rim light uses warm ivory color", _light_color_matches(preview, "RimLight_Spot", RIM_LIGHT_COLOR)) and ok
	ok = _check("preview fill/key ratio is weak", _ratio_matches(lighting, "fill_energy", "key_energy", 0.21)) and ok
	ok = _check("preview rim/key ratio creates edge highlight", _ratio_matches(lighting, "rim_energy", "key_energy", 0.28)) and ok
	ok = _check("preview background is deep blue-gray, not pure black", _background_is_deep_blue_gray(preview)) and ok
	ok = _check("preview mesh uses preview-only repaired body", str(snapshot.get("mesh_resource_path", "")) == PREVIEW_MESH_PATH) and ok
	preview.queue_free()
	return ok


func _orm_stats(path: String) -> Dictionary:
	var image := _load_texture_image(path)
	if image == null or image.is_empty():
		return {}
	var rough_total := 0.0
	var metal_total := 0.0
	var rough_low_count := 0
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			rough_total += color.g
			metal_total += color.b
			if color.g <= 0.20:
				rough_low_count += 1
			count += 1
	return {
		"rough_mean": rough_total / float(maxi(1, count)),
		"metal_mean": metal_total / float(maxi(1, count)),
		"rough_low_ratio": float(rough_low_count) / float(maxi(1, count)),
	}


func _load_texture_image(path: String) -> Image:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return null
	if not image.is_empty() and image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image


func _light_color_matches(preview: Node, node_name: String, expected: Color) -> bool:
	var node := _find_node(preview, node_name)
	if node == null:
		return false
	var color = node.get("light_color")
	return color is Color and _color_close(color as Color, expected)


func _ratio_matches(lighting: Dictionary, numerator_key: String, denominator_key: String, expected_ratio: float) -> bool:
	var denominator := float(lighting.get(denominator_key, 0.0))
	if denominator <= 0.0001:
		return false
	var ratio := float(lighting.get(numerator_key, 0.0)) / denominator
	return absf(ratio - expected_ratio) <= LIGHT_RATIO_EPS


func _background_is_deep_blue_gray(preview: Node) -> bool:
	var env_node := _find_node(preview, "WorldEnvironment") as WorldEnvironment
	if env_node == null or env_node.environment == null:
		return false
	var color := env_node.environment.background_color
	return color.r > 0.04 and color.r < 0.16 and color.b > color.r and color.b < 0.20


func _find_node(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_node(child, node_name)
		if found != null:
			return found
	return null


func _check_color(label: String, actual: Color, expected: Color) -> bool:
	return _check(label, _color_close(actual, expected))


func _color_close(actual: Color, expected: Color) -> bool:
	return absf(actual.r - expected.r) <= COLOR_EPS \
		and absf(actual.g - expected.g) <= COLOR_EPS \
		and absf(actual.b - expected.b) <= COLOR_EPS \
		and absf(actual.a - expected.a) <= COLOR_EPS


func _in_range(value: float, minimum: float, maximum: float) -> bool:
	return value >= minimum and value <= maximum


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
