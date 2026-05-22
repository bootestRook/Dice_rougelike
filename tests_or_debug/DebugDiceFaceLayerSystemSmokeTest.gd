extends SceneTree
class_name DebugDiceFaceLayerSystemSmokeTest


const DiceFaceLayer = preload("res://scripts/ui/dice_face_layers/DiceFaceLayer.gd")
const DiceFaceLayerSet = preload("res://scripts/ui/dice_face_layers/DiceFaceLayerSet.gd")
const DiceFaceLayerSystem = preload("res://scripts/ui/dice_face_layers/DiceFaceLayerSystem.gd")
const GmDiceCtrl = preload("res://scripts/ui/debug/gm_dice_port/GmDiceCtrl.gd")
const GmDiceDefinition = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const GmDiceInstance = preload("res://scripts/ui/debug/gm_dice_port/GmDiceInstance.gd")
const GmDiceMaterialResolver = preload("res://scripts/ui/debug/gm_dice_port/GmDiceMaterialResolver.gd")


func _init() -> void:
	print("--- DebugDiceFaceLayerSystemSmokeTest: start ---")
	var all_passed := true
	all_passed = _check_layer_contract() and all_passed
	all_passed = _check_atlas_output_and_soft_edges() and all_passed
	var runtime_passed := await _check_runtime_dice_uses_shader_layers()
	all_passed = runtime_passed and all_passed
	all_passed = _check_base_material_is_not_modified() and all_passed
	print("PASS: DebugDiceFaceLayerSystemSmokeTest" if all_passed else "FAIL: DebugDiceFaceLayerSystemSmokeTest")
	print("--- DebugDiceFaceLayerSystemSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_layer_contract() -> bool:
	var ok := true
	var layer := DiceFaceLayer.make(DiceFaceLayerSystem.make_number_texture("6"), Color.RED, 0.5, DiceFaceLayer.BLEND_ADD, 12)
	layer.uv_offset = Vector2(0.1, -0.2)
	layer.uv_scale = Vector2(0.7, 0.6)
	layer.rotation = 0.25
	var data := layer.to_dictionary()
	ok = _check("layer has texture field", bool(data.get("has_texture", false))) and ok
	ok = _check("layer has color field", data.get("color") is Color) and ok
	ok = _check("layer has opacity field", is_equal_approx(float(data.get("opacity", 0.0)), 0.5)) and ok
	ok = _check("layer has blend mode field", str(data.get("blend_mode", "")) == "add") and ok
	ok = _check("layer has uv offset field", data.get("uv_offset") is Vector2) and ok
	ok = _check("layer has uv scale field", data.get("uv_scale") is Vector2) and ok
	ok = _check("layer has rotation field", is_equal_approx(float(data.get("rotation", 0.0)), 0.25)) and ok
	ok = _check("layer has order field", int(data.get("order", 0)) == 12) and ok

	var layer_set := DiceFaceLayerSet.new()
	layer_set.number_layer = DiceFaceLayer.make(DiceFaceLayerSystem.make_number_texture("1"), Color.WHITE, 1.0, DiceFaceLayer.BLEND_NORMAL, 20)
	layer_set.mark_layer = DiceFaceLayerSystem.make_mark_layer(&"red", 10)
	layer_set.rune_layer = DiceFaceLayer.make(DiceFaceLayerSystem.make_mark_texture(&"purple"), Color(0.82, 0.42, 1.0), 0.75, DiceFaceLayer.BLEND_SCREEN, 30)
	var ordered := layer_set.get_ordered_layers()
	ok = _check("layer set sorts layers by order", ordered.size() == 3 and ordered[0] == layer_set.mark_layer and ordered[1] == layer_set.number_layer and ordered[2] == layer_set.rune_layer) and ok
	ok = _check("layer set exposes independent rune layer", layer_set.to_dictionary().get("rune_layer", {}) is Dictionary and not (layer_set.to_dictionary().get("rune_layer", {}) as Dictionary).is_empty()) and ok

	var system := DiceFaceLayerSystem.new()
	ok = _check("system reserves normal mask interface", system.has_method("get_normal_mask_texture") and system.get_normal_mask_texture() == null) and ok
	ok = _check("system reserves height mask interface", system.has_method("get_height_mask_texture") and system.get_height_mask_texture() == null) and ok
	ok = _check("system reserves roughness mask interface", system.has_method("get_roughness_mask_texture") and system.get_roughness_mask_texture() == null) and ok
	return ok


func _check_atlas_output_and_soft_edges() -> bool:
	var rows := _face_rows(["1", "2", "3", "4", "5", "6"])
	rows[0]["mark_id"] = &"red"
	var system := DiceFaceLayerSystem.from_face_rows(rows)
	var image := system.bake_face_albedo_image()
	var ok := _check("face albedo atlas has D6 material atlas size", image.get_width() == 384 and image.get_height() == 256)
	ok = _check("face albedo atlas has visible layer pixels", _alpha_pixel_count(image, 0.20, 1.0) > 250) and ok
	ok = _check("number and mark edges use soft alpha", _alpha_pixel_count(image, 0.02, 0.92) > 80) and ok

	var before_hash := _cell_alpha_hash(image, DiceFaceLayerSystem.atlas_value_for_face_index(0))
	system.configure_from_face_rows(_face_rows(["6", "2", "3", "4", "5", "6"]))
	var changed_image := system.bake_face_albedo_image()
	var after_hash := _cell_alpha_hash(changed_image, DiceFaceLayerSystem.atlas_value_for_face_index(0))
	ok = _check("changing a number regenerates only layer texture data", before_hash != after_hash) and ok
	return ok


func _check_runtime_dice_uses_shader_layers() -> bool:
	var definition := GmDiceDefinition.create_standard_d6()
	definition.material_id = GmDiceDefinition.MATERIAL_REPRO_BLUE
	var instance := GmDiceInstance.from_definition(definition)
	var dice := GmDiceCtrl.new()
	root.add_child(dice)
	await process_frame
	dice.build_visuals(Color(0.40, 0.78, 1.00), Color(0.12, 0.14, 0.18))
	dice.init_dice(instance)
	await process_frame
	var before := dice.get_debug_snapshot()
	instance.replace_face_pips([6, 5, 4, 3, 2, 1])
	dice.refresh_from_config()
	await process_frame
	var after := dice.get_debug_snapshot()
	var roles: Dictionary = after.get("visual_layer_roles", {})
	var ok := _check("runtime dice exposes face layer system", not (after.get("face_layer_system", {}) as Dictionary).is_empty())
	ok = _check("runtime dice outputs face albedo texture", bool(after.get("face_albedo_texture_exists", false)) and after.get("face_albedo_texture_size") == Vector2i(384, 256)) and ok
	ok = _check("runtime dice feeds face texture into shader", bool(roles.get("face_albedo_texture", false)) and float(after.get("body_material_face_layer_enabled", 0.0)) > 0.5) and ok
	ok = _check("runtime dice does not display floating face Label3D nodes", int(after.get("face_label_count", -1)) == 0 and not bool(after.get("face_label_nodes_visible", true))) and ok
	ok = _check("runtime dice keeps mesh while replacing number texture", str(before.get("body_mesh_resource_path", "")) == str(after.get("body_mesh_resource_path", ""))) and ok
	dice.queue_free()
	return ok


func _check_base_material_is_not_modified() -> bool:
	var base := load("res://assets/materials/dice/bronze_dice.tres") as BaseMaterial3D
	var ok := _check("bronze base material loads", base != null)
	if base == null:
		return ok
	var original_albedo = base.get("albedo_texture")
	var system := DiceFaceLayerSystem.from_face_rows(_face_rows(["1", "2", "3", "4", "5", "6"]))
	var layered := GmDiceMaterialResolver.make_body_material_instance(Color(0.54, 0.35, 0.17), GmDiceDefinition.MATERIAL_BRONZE, system.get_face_albedo_texture(), true)
	ok = _check("bronze layered runtime material uses shader", layered is ShaderMaterial) and ok
	ok = _check("bronze source material albedo texture remains unchanged", base.get("albedo_texture") == original_albedo) and ok
	return ok


func _face_rows(labels: Array) -> Array:
	var rows := []
	for index in range(6):
		rows.append({
			"label": str(labels[index]) if index < labels.size() else str(index + 1),
			"mark_id": &"none",
		})
	return rows


func _alpha_pixel_count(image: Image, min_alpha: float, max_alpha: float) -> int:
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a
			if alpha >= min_alpha and alpha <= max_alpha:
				count += 1
	return count


func _cell_alpha_hash(image: Image, atlas_value: int) -> int:
	var cell_size := 128
	var index := clampi(atlas_value - 1, 0, 5)
	var col := index % 3
	var row := int(index / 3)
	var hash_value := 17
	for y in range(row * cell_size, (row + 1) * cell_size):
		for x in range(col * cell_size, (col + 1) * cell_size):
			hash_value = int((hash_value * 31 + roundi(image.get_pixel(x, y).a * 255.0) + x * 3 + y * 5) % 2147483647)
	return hash_value


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
