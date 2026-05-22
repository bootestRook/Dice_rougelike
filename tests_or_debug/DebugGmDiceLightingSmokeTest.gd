extends SceneTree
class_name DebugGmDiceLightingSmokeTest


const EXPECTED_LIGHTS := [
	"WarmFrontDiffuseLight",
	"CoolBackDiffuseLight",
	"GreenSideDiffuseLight",
	"VioletLowDiffuseLight",
]
const EXPECTED_METAL_REFLECTION_LIGHTS := [
	"WarmMetalReflectionLight",
	"CoolMetalReflectionLight",
]
const EXPECTED_VISUAL_LIGHT_ROLES := {
	"soft_key_top": "SoftTopKeyLight",
	"cool_table_bounce": "CoolTableBounceLight",
	"warm_gold_edge_kicker": "WarmGoldEdgeKickerLight",
	"local_glint_highlight": "LocalGlintHighlightLight",
	"reflection_reference": "ReflectionReferenceLight",
}
const READY_ROW_SAMPLE := Vector3(0.0, 7.5, 0.08)


func _init() -> void:
	print("--- DebugGmDiceLightingSmokeTest: start ---")
	var all_passed := true

	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	var scene := load("res://scenes/debug/GmPhysicsDiceTestScreen.tscn")
	var screen = scene.instantiate()
	root.add_child(screen)

	await process_frame
	await process_frame
	await process_frame

	for light_name in EXPECTED_LIGHTS:
		var light := _find_node_by_name(screen, light_name) as OmniLight3D
		all_passed = _check("%s exists" % light_name, light != null) and all_passed
		all_passed = _check("%s is soft diffuse light" % light_name, light != null and not light.shadow_enabled and light.light_specular <= 0.15 and light.omni_attenuation <= 0.85) and all_passed
		all_passed = _check("%s has visible range and controlled energy" % light_name, light != null and light.omni_range >= 12.0 and light.light_energy >= 0.80 and light.light_energy <= 1.45) and all_passed
		all_passed = _check("%s reaches ready dice row" % light_name, light != null and light.position.y >= 4.5 and light.position.distance_to(READY_ROW_SAMPLE) <= light.omni_range) and all_passed

	for light_name in EXPECTED_METAL_REFLECTION_LIGHTS:
		var light := _find_node_by_name(screen, light_name) as OmniLight3D
		all_passed = _check("%s exists" % light_name, light != null) and all_passed
		all_passed = _check("%s has controlled metal specular" % light_name, light != null and not light.shadow_enabled and light.light_specular >= 0.30 and light.light_specular <= 0.50) and all_passed
		all_passed = _check("%s reaches ready dice row" % light_name, light != null and light.omni_range >= 10.0 and light.position.distance_to(READY_ROW_SAMPLE) <= light.omni_range) and all_passed

	for role in EXPECTED_VISUAL_LIGHT_ROLES.keys():
		var light_name := str(EXPECTED_VISUAL_LIGHT_ROLES[role])
		var light := _find_node_by_name(screen, light_name) as OmniLight3D
		all_passed = _check("%s role light exists" % light_name, light != null) and all_passed
		all_passed = _check("%s role metadata is stable" % light_name, light != null and str(light.get_meta("visual_light_role", "")) == role) and all_passed
		all_passed = _check("%s role light has bounded energy" % light_name, light != null and light.light_energy >= 0.20 and light.light_energy <= 1.00) and all_passed
		all_passed = _check("%s role light has bounded range" % light_name, light != null and light.omni_range >= 5.0 and light.omni_range <= 16.5) and all_passed
		all_passed = _check("%s role light has bounded specular" % light_name, light != null and light.light_specular >= 0.05 and light.light_specular <= 0.70) and all_passed

	var world_environment := _find_node_by_name(screen, "WorldEnvironment") as WorldEnvironment
	all_passed = _check("ambient light leaves room for glowing dice edges", world_environment != null and world_environment.environment != null and world_environment.environment.ambient_light_energy <= 0.42) and all_passed
	all_passed = _check("ambient light keeps deep blue scene readable", world_environment != null and world_environment.environment != null and world_environment.environment.ambient_light_energy >= 0.30) and all_passed
	all_passed = _check("world background is deep blue rather than black", world_environment != null and world_environment.environment != null and _is_readable_deep_blue(world_environment.environment.background_color)) and all_passed
	all_passed = _check("visual repro glow is enabled", world_environment != null and _object_bool(world_environment.environment, "glow_enabled")) and all_passed
	all_passed = _check("visual repro ssao is enabled", world_environment != null and _object_bool(world_environment.environment, "ssao_enabled")) and all_passed
	var key_light := _find_node_by_name(screen, "KeyLight") as DirectionalLight3D
	all_passed = _check("key light is open but does not wash out dice materials", key_light != null and key_light.light_energy >= 1.20 and key_light.light_energy <= 1.60) and all_passed
	var scene_backdrop := _find_node_by_name(screen, "GmSceneBackdrop") as ColorRect
	all_passed = _check("screen backdrop is deep blue rather than black", scene_backdrop != null and _is_readable_deep_blue(scene_backdrop.color)) and all_passed

	var visual_mat := _find_node_by_name(screen, "FixedThrowMat") as Node3D
	all_passed = _check("visual repro throw mat exists", visual_mat != null) and all_passed
	var disc_top := _find_node_by_name(visual_mat, "LitAstrologyDiscTop") as MeshInstance3D if visual_mat != null else null
	all_passed = _check("visual repro throw mat has normal textured disc top", disc_top != null and disc_top.mesh != null) and all_passed
	all_passed = _check("visual repro throw mat has disc side", visual_mat != null and _find_node_by_name(visual_mat, "LitAstrologyDiscSide") is MeshInstance3D) and all_passed
	all_passed = _check("visual repro disc top uses albedo texture", disc_top != null and _material_has_property(disc_top.material_override, "albedo_texture")) and all_passed
	all_passed = _check("visual repro disc top uses normal map", disc_top != null and disc_top.material_override != null and bool(disc_top.material_override.get("normal_enabled")) and _material_has_property(disc_top.material_override, "normal_texture")) and all_passed
	all_passed = _check("visual repro disc top uses ORM texture", disc_top != null and _material_has_property(disc_top.material_override, "orm_texture")) and all_passed
	all_passed = _check("visual repro disc top uses emission texture", disc_top != null and _material_has_property(disc_top.material_override, "emission_texture")) and all_passed
	all_passed = _check("visual repro no longer uses separate gold ring geometry", visual_mat != null and _find_node_by_name(visual_mat, "GoldRing") == null) and all_passed
	all_passed = _check("visual repro no longer uses separate constellation geometry", visual_mat != null and _find_node_by_name(visual_mat, "ConstellationLine") == null) and all_passed

	var snapshot: Dictionary = screen.call("automation_get_snapshot")
	var light_rows: Array = snapshot.get("multi_diffuse_lights", [])
	var metal_rows: Array = snapshot.get("metal_reflection_lights", [])
	var role_rows: Array = snapshot.get("visual_light_roles", [])
	var rendering_features: Dictionary = snapshot.get("rendering_features", {})
	all_passed = _check("snapshot exposes four multi diffuse lights", light_rows.size() == EXPECTED_LIGHTS.size()) and all_passed
	all_passed = _check("snapshot exposes metal reflection lights", metal_rows.size() == EXPECTED_METAL_REFLECTION_LIGHTS.size()) and all_passed
	all_passed = _check("snapshot exposes visual light roles", _snapshot_has_roles(role_rows, EXPECTED_VISUAL_LIGHT_ROLES.keys())) and all_passed
	all_passed = _check("snapshot exposes rendering features", rendering_features.has("glow_enabled") and rendering_features.has("reflection_probe")) and all_passed
	all_passed = _check("snapshot records reflection probe availability", bool(rendering_features.get("reflection_probe", false))) and all_passed
	all_passed = _check("snapshot records transparent marker fallback", bool(rendering_features.get("transparent_marker_layers", false))) and all_passed
	all_passed = _check("diffuse light colors are varied", _unique_light_colors(light_rows) >= 4) and all_passed
	all_passed = _check("bridge contract exposes multi diffuse lights", ((snapshot.get("bridge_contract", {}) as Dictionary).get("snapshot_keys", []) as Array).has("multi_diffuse_lights")) and all_passed
	all_passed = _check("bridge contract exposes metal reflection lights", ((snapshot.get("bridge_contract", {}) as Dictionary).get("snapshot_keys", []) as Array).has("metal_reflection_lights")) and all_passed
	all_passed = _check("bridge contract exposes visual light roles", ((snapshot.get("bridge_contract", {}) as Dictionary).get("snapshot_keys", []) as Array).has("visual_light_roles")) and all_passed
	all_passed = _check("bridge contract exposes rendering features", ((snapshot.get("bridge_contract", {}) as Dictionary).get("snapshot_keys", []) as Array).has("rendering_features")) and all_passed

	screen.queue_free()
	print("PASS: DebugGmDiceLightingSmokeTest" if all_passed else "FAIL: DebugGmDiceLightingSmokeTest")
	print("--- DebugGmDiceLightingSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _unique_light_colors(light_rows: Array) -> int:
	var keys := {}
	for row in light_rows:
		if not (row is Dictionary):
			continue
		var color: Color = (row as Dictionary).get("color", Color.BLACK)
		var key := "%d/%d/%d" % [roundi(color.r * 100.0), roundi(color.g * 100.0), roundi(color.b * 100.0)]
		keys[key] = true
	return keys.size()


func _snapshot_has_roles(role_rows: Array, expected_roles: Array) -> bool:
	var present := {}
	for row in role_rows:
		if not (row is Dictionary):
			continue
		present[str((row as Dictionary).get("role", ""))] = true
	for role in expected_roles:
		if not present.has(str(role)):
			return false
	return true


func _object_bool(object: Object, property_name: String) -> bool:
	if object == null:
		return false
	for item in object.get_property_list():
		if str(item.get("name", "")) == property_name:
			return bool(object.get(property_name))
	return false


func _is_readable_deep_blue(color: Color) -> bool:
	return color.b >= 0.11 and color.b > color.r and color.b > color.g and color.get_luminance() >= 0.035


func _material_has_property(material: Material, property_name: String) -> bool:
	if material == null:
		return false
	for item in material.get_property_list():
		if str(item.get("name", "")) == property_name:
			return material.get(property_name) != null
	return false


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
