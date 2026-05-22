extends SceneTree
class_name DebugDiceMaterialPipelineSmokeTest


const MATERIAL_IDS := ["bronze", "gold", "crystal"]
const MATERIAL_PATHS := {
	"bronze": "res://assets/materials/dice/bronze_dice.tres",
	"gold": "res://assets/materials/dice/gold_dice.tres",
	"crystal": "res://assets/materials/dice/crystal_dice.tres",
}
const TEXTURE_DIRS := {
	"bronze": "res://assets/textures/dice/bronze",
	"gold": "res://assets/textures/dice/gold",
	"crystal": "res://assets/textures/dice/crystal",
}
const SCENE_PATHS := {
	"common": "res://assets/scenes/preview/dice_material_preview.tscn",
	"bronze": "res://assets/scenes/preview/bronze_dice_preview.tscn",
	"gold": "res://assets/scenes/preview/gold_dice_preview.tscn",
	"crystal": "res://assets/scenes/preview/crystal_dice_preview.tscn",
}
const CELL_SIZE := 128
const MAX_BAKED_PIP_CONTRAST := 0.035
const MAX_BRONZE_GREENISH_RATIO := 0.085
const MAX_BRONZE_FACE_GREENISH_RATIO := 0.12
const MIN_GOLD_METALLIC_MEAN := 0.95
const MAX_GOLD_METALLIC_MEAN := 0.98
const MAX_GOLD_METALLIC_MAX_RATIO := 0.08
const MIN_GOLD_ROUGHNESS_MEAN := 0.23
const MAX_GOLD_ROUGHNESS_MEAN := 0.30
const MIN_GOLD_LOW_ROUGHNESS_RATIO := 0.18
const MAX_GOLD_LOW_ROUGHNESS_RATIO := 0.34
const MIN_BRONZE_METALLIC_MEAN := 0.90
const MAX_BRONZE_METALLIC_MEAN := 0.93
const MIN_BRONZE_ROUGHNESS_MEAN := 0.39
const MAX_BRONZE_ROUGHNESS_MEAN := 0.44
const MAX_BRONZE_LOW_ROUGHNESS_RATIO := 0.02
const MIN_DARK_PREVIEW_LUMA := {
	"bronze": 0.074,
	"gold": 0.105,
	"crystal": 0.052,
}
const PIP_SAMPLE_POSITIONS := {
	1: [Vector2(0.50, 0.50)],
	2: [Vector2(0.30, 0.30), Vector2(0.70, 0.70)],
	3: [Vector2(0.30, 0.30), Vector2(0.50, 0.50), Vector2(0.70, 0.70)],
	4: [Vector2(0.30, 0.30), Vector2(0.70, 0.30), Vector2(0.30, 0.70), Vector2(0.70, 0.70)],
	5: [Vector2(0.30, 0.30), Vector2(0.70, 0.30), Vector2(0.50, 0.50), Vector2(0.30, 0.70), Vector2(0.70, 0.70)],
	6: [Vector2(0.30, 0.24), Vector2(0.70, 0.24), Vector2(0.30, 0.50), Vector2(0.70, 0.50), Vector2(0.30, 0.76), Vector2(0.70, 0.76)],
}


func _init() -> void:
	print("--- DebugDiceMaterialPipelineSmokeTest: start ---")
	var all_passed := true
	all_passed = _check("standard d6 mesh loads", load("res://assets/models/dice/standard_d6_mesh.tres") is Mesh) and all_passed
	all_passed = _check("standard d6 model scene loads", load("res://assets/models/dice/standard_d6_preview.tscn") is PackedScene) and all_passed
	all_passed = _check("crystal shader loads", load("res://assets/shaders/dice/crystal_dice.gdshader") is Shader) and all_passed

	for material_id in MATERIAL_IDS:
		all_passed = _check_texture_set(material_id) and all_passed
		all_passed = _check_import_settings(material_id) and all_passed
		all_passed = _check_no_baked_pip_marks(material_id) and all_passed
		all_passed = _check_material_visual_quality(material_id) and all_passed
		all_passed = _check_material(material_id) and all_passed
		all_passed = _check_preview_scene(material_id, SCENE_PATHS[material_id]) and all_passed
		all_passed = _check_screenshots(material_id) and all_passed
	all_passed = _check_preview_scene("common", SCENE_PATHS["common"]) and all_passed

	print("PASS: DebugDiceMaterialPipelineSmokeTest" if all_passed else "FAIL: DebugDiceMaterialPipelineSmokeTest")
	print("--- DebugDiceMaterialPipelineSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_texture_set(material_id: String) -> bool:
	var ok := true
	var texture_names := ["albedo", "normal", "orm", "emission", "height"]
	if material_id == "crystal":
		texture_names.append("flow_mask")
	for texture_name in texture_names:
		var path := "%s/%s_dice_%s.png" % [TEXTURE_DIRS[material_id], material_id, texture_name]
		ok = _check("%s texture exists: %s" % [material_id, texture_name], FileAccess.file_exists(path)) and ok
		ok = _check("%s texture loads: %s" % [material_id, texture_name], load(path) is Texture2D) and ok
	return ok


func _check_import_settings(material_id: String) -> bool:
	var ok := true
	var texture_names := ["albedo", "normal", "orm", "emission", "height"]
	if material_id == "crystal":
		texture_names.append("flow_mask")
	for texture_name in texture_names:
		var import_path := "%s/%s_dice_%s.png.import" % [TEXTURE_DIRS[material_id], material_id, texture_name]
		var values := _read_import_values(import_path)
		ok = _check("%s %s import exists" % [material_id, texture_name], not values.is_empty()) and ok
		ok = _check("%s %s import mipmaps enabled" % [material_id, texture_name], values.get("mipmaps/generate", "") == "true") and ok
		if texture_name == "normal":
			ok = _check("%s normal imports as normal map" % material_id, values.get("compress/normal_map", "") == "1") and ok
			ok = _check("%s normal keeps expected Y orientation" % material_id, values.get("process/normal_map_invert_y", "") == "false") and ok
		else:
			ok = _check("%s %s is not imported as normal map" % [material_id, texture_name], values.get("compress/normal_map", "") == "0") and ok
		if ["orm", "height", "flow_mask"].has(texture_name):
			ok = _check("%s %s data texture avoids HDR sRGB" % [material_id, texture_name], values.get("process/hdr_as_srgb", "") == "false") and ok
	return ok


func _read_import_values(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var keys := [
		"compress/normal_map",
		"mipmaps/generate",
		"roughness/mode",
		"process/normal_map_invert_y",
		"process/hdr_as_srgb",
	]
	var values := {}
	for raw_line in text.split("\n"):
		var line := str(raw_line).strip_edges()
		for key in keys:
			var prefix := "%s=" % key
			if line.begins_with(prefix):
				values[key] = line.substr(prefix.length())
	return values


func _check_no_baked_pip_marks(material_id: String) -> bool:
	var ok := true
	for texture_name in ["albedo", "height"]:
		var path := "%s/%s_dice_%s.png" % [TEXTURE_DIRS[material_id], material_id, texture_name]
		var image := _load_texture_image(path)
		ok = _check("%s %s has no baked dice pips" % [material_id, texture_name], image != null and not image.is_empty() and _max_pip_local_contrast(image) <= MAX_BAKED_PIP_CONTRAST) and ok
	return ok


func _check_material_visual_quality(material_id: String) -> bool:
	var ok := true
	var orm := _load_texture_image("%s/%s_dice_orm.png" % [TEXTURE_DIRS[material_id], material_id])
	ok = _check("%s ORM image available for visual checks" % material_id, orm != null and not orm.is_empty()) and ok
	if orm != null and not orm.is_empty():
		ok = _check_orm_visual_quality(material_id, orm) and ok
	var albedo := _load_texture_image("%s/%s_dice_albedo.png" % [TEXTURE_DIRS[material_id], material_id])
	if material_id == "bronze":
		ok = _check_bronze_patina(albedo) and ok
	ok = _check_dark_preview_luminance(material_id) and ok
	return ok


func _check_orm_visual_quality(material_id: String, image: Image) -> bool:
	var ok := true
	var roughness := _channel_stats(image, 1)
	var metallic := _channel_stats(image, 2)
	if material_id == "gold":
		ok = _check("gold metallic average stays bounded", float(metallic["mean"]) >= MIN_GOLD_METALLIC_MEAN and float(metallic["mean"]) <= MAX_GOLD_METALLIC_MEAN) and ok
		ok = _check("gold metallic is not full-frame maximum", float(metallic["max_ratio"]) <= MAX_GOLD_METALLIC_MAX_RATIO) and ok
		ok = _check("gold roughness average supports clear gold highlights", float(roughness["mean"]) >= MIN_GOLD_ROUGHNESS_MEAN and float(roughness["mean"]) <= MAX_GOLD_ROUGHNESS_MEAN) and ok
		ok = _check("gold keeps crisp low-roughness edge highlights", float(roughness["low_ratio"]) >= MIN_GOLD_LOW_ROUGHNESS_RATIO and float(roughness["low_ratio"]) <= MAX_GOLD_LOW_ROUGHNESS_RATIO) and ok
	elif material_id == "bronze":
		ok = _check("bronze metallic average supports old heavy metal", float(metallic["mean"]) >= MIN_BRONZE_METALLIC_MEAN and float(metallic["mean"]) <= MAX_BRONZE_METALLIC_MEAN) and ok
		ok = _check("bronze roughness average supports aged metal", float(roughness["mean"]) >= MIN_BRONZE_ROUGHNESS_MEAN and float(roughness["mean"]) <= MAX_BRONZE_ROUGHNESS_MEAN) and ok
		ok = _check("bronze keeps sharp polished areas limited", float(roughness["low_ratio"]) <= MAX_BRONZE_LOW_ROUGHNESS_RATIO) and ok
	return ok


func _channel_stats(image: Image, channel: int) -> Dictionary:
	var total := 0.0
	var count := 0
	var max_count := 0
	var low_count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var value := _channel_value(color, channel)
			total += value
			count += 1
			if value >= 0.98:
				max_count += 1
			if value <= 0.20:
				low_count += 1
	return {
		"mean": total / float(maxi(1, count)),
		"max_ratio": float(max_count) / float(maxi(1, count)),
		"low_ratio": float(low_count) / float(maxi(1, count)),
	}


func _channel_value(color: Color, channel: int) -> float:
	match channel:
		0:
			return color.r
		1:
			return color.g
		2:
			return color.b
	return color.a


func _check_bronze_patina(image: Image) -> bool:
	var ok := _check("bronze albedo image available for patina check", image != null and not image.is_empty())
	if image == null or image.is_empty():
		return ok
	var total_ratio := _greenish_ratio(image, Rect2i(0, 0, image.get_width(), image.get_height()))
	ok = _check("bronze patina global coverage is localized", total_ratio <= MAX_BRONZE_GREENISH_RATIO) and ok
	var max_face_ratio := 0.0
	for face_value in range(1, 7):
		var col := (face_value - 1) % 3
		var row := int((face_value - 1) / 3)
		var rect := Rect2i(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		max_face_ratio = maxf(max_face_ratio, _greenish_ratio(image, rect))
	ok = _check("bronze patina does not fill a primary face", max_face_ratio <= MAX_BRONZE_FACE_GREENISH_RATIO) and ok
	return ok


func _greenish_ratio(image: Image, rect: Rect2i) -> float:
	var greenish := 0
	var count := 0
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var color := image.get_pixel(x, y)
			if color.g > color.r * 1.08 and color.g > color.b * 1.25:
				greenish += 1
			count += 1
	return float(greenish) / float(maxi(1, count))


func _check_dark_preview_luminance(material_id: String) -> bool:
	var path := "res://assets/scenes/preview/preview_shots/%s_dice_dark.png" % material_id
	var image := _load_texture_image(path)
	var ok := _check("%s dark preview image available" % material_id, image != null and not image.is_empty())
	if image == null or image.is_empty():
		return ok
	var luminance := _average_luminance_rect(image, Rect2i(420, 130, 600, 460))
	return _check("%s dark preview remains readable" % material_id, luminance >= float(MIN_DARK_PREVIEW_LUMA.get(material_id, 0.05))) and ok


func _average_luminance_rect(image: Image, rect: Rect2i) -> float:
	var total := 0.0
	var count := 0
	var min_x := maxi(0, rect.position.x)
	var max_x := mini(image.get_width() - 1, rect.position.x + rect.size.x - 1)
	var min_y := maxi(0, rect.position.y)
	var max_y := mini(image.get_height() - 1, rect.position.y + rect.size.y - 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var color := image.get_pixel(x, y)
			total += color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			count += 1
	return total / float(maxi(1, count))


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


func _max_pip_local_contrast(image: Image) -> float:
	var max_contrast := 0.0
	for face_value in range(1, 7):
		var positions: Array = PIP_SAMPLE_POSITIONS[face_value]
		var col := (face_value - 1) % 3
		var row := int((face_value - 1) / 3)
		for uv in positions:
			var sample_uv := uv as Vector2
			var center := Vector2(col * CELL_SIZE + sample_uv.x * float(CELL_SIZE - 1), row * CELL_SIZE + sample_uv.y * float(CELL_SIZE - 1))
			var local_contrast := absf(_average_luminance_disc(image, center, 5.0) - _average_luminance_disc(image, center, 14.0))
			max_contrast = maxf(max_contrast, local_contrast)
	return max_contrast


func _average_luminance_disc(image: Image, center: Vector2, radius: float) -> float:
	var radius_squared := radius * radius
	var min_x := maxi(0, int(floor(center.x - radius)))
	var max_x := mini(image.get_width() - 1, int(ceil(center.x + radius)))
	var min_y := maxi(0, int(floor(center.y - radius)))
	var max_y := mini(image.get_height() - 1, int(ceil(center.y + radius)))
	var total := 0.0
	var count := 0
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var offset := Vector2(float(x), float(y)) - center
			if offset.length_squared() <= radius_squared:
				var color := image.get_pixel(x, y)
				total += color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
				count += 1
	return total / float(maxi(1, count))


func _check_material(material_id: String) -> bool:
	var material := load(MATERIAL_PATHS[material_id])
	var ok := _check("%s material loads" % material_id, material != null)
	if material_id == "crystal":
		ok = _check("crystal material is ShaderMaterial", material is ShaderMaterial) and ok
		if material is ShaderMaterial:
			var shader_material := material as ShaderMaterial
			ok = _check("crystal has shader", shader_material.shader != null) and ok
			for parameter in ["alpha_base", "emission_power", "fresnel_power", "flow_speed", "glow_color", "tint_color"]:
				ok = _check("crystal parameter exists: %s" % parameter, shader_material.get_shader_parameter(parameter) != null) and ok
			ok = _check("crystal emission keeps scene lights visible", float(shader_material.get_shader_parameter("emission_power")) <= 1.40) and ok
	else:
		ok = _check("%s material is BaseMaterial3D" % material_id, material is BaseMaterial3D) and ok
		if material is BaseMaterial3D:
			ok = _check("%s albedo texture assigned" % material_id, _has_assigned_property(material, ["albedo_texture"])) and ok
			ok = _check("%s ORM texture assigned" % material_id, _has_assigned_property(material, ["orm_texture"])) and ok
			ok = _check("%s normal enabled" % material_id, bool(material.get("normal_enabled"))) and ok
			ok = _check("%s normal texture assigned" % material_id, _has_assigned_property(material, ["normal_texture"])) and ok
			ok = _check("%s emission enabled" % material_id, bool(material.get("emission_enabled"))) and ok
			ok = _check("%s emission texture assigned" % material_id, _has_assigned_property(material, ["emission_texture"])) and ok
			ok = _check("%s emission keeps scene lights visible" % material_id, float(material.get("emission_energy_multiplier")) <= 0.20) and ok
	return ok


func _check_preview_scene(label: String, path: String) -> bool:
	var scene := load(path) as PackedScene
	var ok := _check("%s preview scene loads" % label, scene != null)
	if scene == null:
		return ok
	var root_node := scene.instantiate()
	ok = _check("%s has WorldEnvironment" % label, _find_node_by_type(root_node, "WorldEnvironment") != null) and ok
	ok = _check("%s has DirectionalLight3D" % label, _find_node_by_type(root_node, "DirectionalLight3D") != null) and ok
	ok = _check("%s has AuxPointLight" % label, root_node.find_child("AuxPointLight", true, false) != null) and ok
	ok = _check("%s has PreviewCamera" % label, root_node.find_child("PreviewCamera", true, false) != null) and ok
	ok = _check("%s has dice mesh" % label, _find_dice_mesh(root_node) != null) and ok
	root_node.queue_free()
	return ok


func _check_screenshots(material_id: String) -> bool:
	var ok := true
	for light_mode in ["bright", "neutral", "dark"]:
		var path := "res://assets/scenes/preview/preview_shots/%s_dice_%s.png" % [material_id, light_mode]
		ok = _check("%s screenshot exists: %s" % [material_id, light_mode], FileAccess.file_exists(path)) and ok
	return ok


func _has_assigned_property(object: Object, names: Array) -> bool:
	for name in names:
		var value = object.get(name)
		if value != null:
			return true
	return false


func _find_node_by_type(root_node: Node, type_name: String) -> Node:
	if root_node.is_class(type_name):
		return root_node
	for child in root_node.get_children():
		var found := _find_node_by_type(child, type_name)
		if found != null:
			return found
	return null


func _find_dice_mesh(root_node: Node) -> Node:
	var direct := root_node.find_child("DiceMesh", true, false)
	if direct != null:
		return direct
	for dice_name in ["BronzeDiceMesh", "GoldDiceMesh", "CrystalDiceMesh"]:
		var named := root_node.find_child(dice_name, true, false)
		if named != null:
			return named
	return null


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
