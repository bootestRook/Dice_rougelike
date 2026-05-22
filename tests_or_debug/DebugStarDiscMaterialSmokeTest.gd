extends SceneTree
class_name DebugStarDiscMaterialSmokeTest


const TEXTURE_DIR := "res://assets/textures/stage/star_disc"
const MATERIAL_PATH := "res://assets/materials/stage/star_disc_base.tres"
const DISC_SCENE_PATH := "res://assets/models/stage/star_astrology_disc.tscn"
const TEXTURE_NAMES := ["albedo", "normal", "orm", "emission", "height"]
const PREVIEW_PATHS := [
	"res://assets/scenes/preview/preview_shots/star_disc_albedo_preview.png",
	"res://assets/scenes/preview/preview_shots/star_disc_normal_preview.png",
	"res://assets/scenes/preview/preview_shots/star_disc_lit_preview.png",
]


func _init() -> void:
	print("--- DebugStarDiscMaterialSmokeTest: start ---")
	var all_passed := true
	for texture_name in TEXTURE_NAMES:
		all_passed = _check_texture(texture_name) and all_passed
		all_passed = _check_import_settings(texture_name) and all_passed
	all_passed = _check_albedo_content() and all_passed
	all_passed = _check_normal_content() and all_passed
	all_passed = _check_material() and all_passed
	all_passed = _check_disc_scene() and all_passed
	for path in PREVIEW_PATHS:
		all_passed = _check("preview image exists: %s" % path, FileAccess.file_exists(path)) and all_passed
	print("PASS: DebugStarDiscMaterialSmokeTest" if all_passed else "FAIL: DebugStarDiscMaterialSmokeTest")
	print("--- DebugStarDiscMaterialSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_texture(texture_name: String) -> bool:
	var path := "%s/star_disc_%s.png" % [TEXTURE_DIR, texture_name]
	var ok := true
	ok = _check("%s texture exists" % texture_name, FileAccess.file_exists(path)) and ok
	ok = _check("%s texture loads" % texture_name, load(path) is Texture2D) and ok
	var image := _load_png(path)
	ok = _check("%s texture image is readable" % texture_name, image != null and not image.is_empty()) and ok
	if image != null and not image.is_empty():
		ok = _check("%s texture has expected resolution" % texture_name, image.get_width() == 768 and image.get_height() == 768) and ok
	return ok


func _check_import_settings(texture_name: String) -> bool:
	var import_path := "%s/star_disc_%s.png.import" % [TEXTURE_DIR, texture_name]
	var values := _read_import_values(import_path)
	var ok := _check("%s import exists" % texture_name, not values.is_empty())
	ok = _check("%s mipmaps enabled" % texture_name, values.get("mipmaps/generate", "") == "true") and ok
	if texture_name == "normal":
		ok = _check("stage disc normal imports as normal map", values.get("compress/normal_map", "") == "1") and ok
		ok = _check("stage disc normal Y orientation is stable", values.get("process/normal_map_invert_y", "") == "false") and ok
	else:
		ok = _check("%s is not imported as normal map" % texture_name, values.get("compress/normal_map", "") == "0") and ok
	if ["orm", "height"].has(texture_name):
		ok = _check("%s data texture avoids HDR sRGB" % texture_name, values.get("process/hdr_as_srgb", "") == "false") and ok
	return ok


func _check_albedo_content() -> bool:
	var image := _load_png("%s/star_disc_albedo.png" % TEXTURE_DIR)
	var ok := _check("disc albedo image available", image != null and not image.is_empty())
	if image == null or image.is_empty():
		return ok
	var gold_pixels := 0
	var blue_pixels := 0
	var lit_pixels := 0
	var count := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var color := image.get_pixel(x, y)
			if color.a <= 0.05:
				continue
			count += 1
			if color.r > 0.46 and color.g > 0.25 and color.b < 0.28:
				gold_pixels += 1
			if color.b > 0.24 and color.g > 0.09 and color.r < 0.26:
				blue_pixels += 1
			if color.r + color.g + color.b > 0.22:
				lit_pixels += 1
	ok = _check("disc albedo contains gold astrology detail", float(gold_pixels) / float(maxi(1, count)) >= 0.006) and ok
	ok = _check("disc albedo contains blue glow/detail", float(blue_pixels) / float(maxi(1, count)) >= 0.015) and ok
	ok = _check("disc albedo is not blank/dark-only", float(lit_pixels) / float(maxi(1, count)) >= 0.070) and ok
	return ok


func _check_normal_content() -> bool:
	var image := _load_png("%s/star_disc_normal.png" % TEXTURE_DIR)
	var ok := _check("disc normal image available", image != null and not image.is_empty())
	if image == null or image.is_empty():
		return ok
	var deviation := 0.0
	var z_total := 0.0
	var count := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var uv := Vector2(float(x) / float(image.get_width() - 1), float(y) / float(image.get_height() - 1))
			if (uv * 2.0 - Vector2.ONE).length() > 0.98:
				continue
			var color := image.get_pixel(x, y)
			deviation += absf(color.r - 0.5) + absf(color.g - 0.5)
			z_total += color.b
			count += 1
	ok = _check("disc normal map has visible surface relief", deviation / float(maxi(1, count)) >= 0.006) and ok
	ok = _check("disc normal map keeps upward normals", z_total / float(maxi(1, count)) >= 0.94) and ok
	return ok


func _check_material() -> bool:
	var material := load(MATERIAL_PATH)
	var ok := _check("stage disc material loads", material is BaseMaterial3D)
	if material is BaseMaterial3D:
		ok = _check("stage disc albedo texture assigned", material.get("albedo_texture") != null) and ok
		ok = _check("stage disc ORM texture assigned", material.get("orm_texture") != null) and ok
		ok = _check("stage disc normal enabled", bool(material.get("normal_enabled"))) and ok
		ok = _check("stage disc normal texture assigned", material.get("normal_texture") != null) and ok
		ok = _check("stage disc emission enabled", bool(material.get("emission_enabled"))) and ok
		ok = _check("stage disc emission texture assigned", material.get("emission_texture") != null) and ok
		ok = _check("stage disc height map enabled", bool(material.get("heightmap_enabled"))) and ok
		ok = _check("stage disc height texture assigned", material.get("heightmap_texture") != null) and ok
	return ok


func _check_disc_scene() -> bool:
	var scene := load(DISC_SCENE_PATH) as PackedScene
	var ok := _check("stage disc scene loads", scene != null)
	if scene == null:
		return ok
	var root_node := scene.instantiate()
	var top := _find_node_by_name(root_node, "LitAstrologyDiscTop") as MeshInstance3D
	var side := _find_node_by_name(root_node, "LitAstrologyDiscSide") as MeshInstance3D
	ok = _check("stage disc uses one textured top mesh", top != null and top.mesh != null and top.mesh.get_surface_count() == 1) and ok
	ok = _check("stage disc has side mesh", side != null and side.mesh != null) and ok
	ok = _check("stage disc top uses generated material", top != null and top.material_override != null and top.material_override.resource_path == MATERIAL_PATH) and ok
	ok = _check("old separate gold ring nodes removed", _find_node_by_name(root_node, "GoldRing") == null) and ok
	ok = _check("old separate constellation line nodes removed", _find_node_by_name(root_node, "ConstellationLine") == null) and ok
	if top != null and top.mesh != null:
		var aabb := top.mesh.get_aabb()
		ok = _check("stage disc top is round-sized, not board-sized", aabb.size.x >= 10.0 and aabb.size.x <= 10.8 and aabb.size.z >= 10.0 and aabb.size.z <= 10.8) and ok
	root_node.queue_free()
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


func _load_png(path: String) -> Image:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return null
	if not image.is_empty() and image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
