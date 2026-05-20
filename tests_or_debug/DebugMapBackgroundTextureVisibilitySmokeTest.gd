extends SceneTree
class_name DebugMapBackgroundTextureVisibilitySmokeTest


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const MapStageViewScript = preload("res://scripts/ui/map/MapStageView.gd")


func _init() -> void:
	print("--- DebugMapBackgroundTextureVisibilitySmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)

	var flow := GameFlowController.new()
	root.add_child(flow)
	flow.start_new_run()

	var map_view = MapStageViewScript.new()
	map_view.setup(flow, flow.get_map_state())
	root.add_child(map_view)

	await process_frame
	await process_frame

	all_passed = _check("map backdrop texture node stays wired but hidden", _texture_node_hidden(map_view, "MapBackdropTexture")) and all_passed
	all_passed = _check("2D map board texture shows parchment map", _texture_node_visible_with_path(map_view, "MapBoardTexture", "res://assets/ui/map/map.png")) and all_passed
	all_passed = _check("2D map board texture covers the scoring and prep stage", _texture_node_covers_root(map_view, "MapBoardTexture")) and all_passed
	all_passed = _check("3D dice viewport is mounted and sized", _physics_map_stage_is_sized(map_view)) and all_passed
	all_passed = _check("3D dice viewport hides map board and route nodes", _physics_map_visuals_are_disabled(map_view)) and all_passed
	all_passed = _check("movement dice panel texture node stays wired but hidden", _texture_node_hidden(map_view, "MoveDicePanelTexture")) and all_passed
	all_passed = _check("2D map path floor tiles stay visible", _texture_node_visible(map_view, "PathFloorTexture")) and all_passed
	all_passed = _check("2D map route nodes stay visible", _texture_node_visible(map_view, "NodeTexture")) and all_passed
	all_passed = _check("movement controls stay mounted", _find_node_by_name(map_view, "RollMovementButton") != null) and all_passed
	all_passed = _check("map POV tuner stays hidden in 2D map mode", _pov_tuner_is_hidden(map_view)) and all_passed
	all_passed = _check("map POV tuner still updates dice camera parameters", _pov_tuning_updates_camera(map_view)) and all_passed

	map_view.queue_free()
	flow.queue_free()
	print("PASS: DebugMapBackgroundTextureVisibilitySmokeTest" if all_passed else "FAIL: DebugMapBackgroundTextureVisibilitySmokeTest")
	print("--- DebugMapBackgroundTextureVisibilitySmokeTest: end ---")
	quit(0 if all_passed else 1)


func _texture_node_hidden(root_node: Node, node_name: String) -> bool:
	var node := _find_node_by_name(root_node, node_name) as TextureRect
	return node != null and node.texture != null and not node.visible


func _texture_node_visible(root_node: Node, node_name: String) -> bool:
	var node := _find_node_by_name(root_node, node_name) as TextureRect
	return node != null and node.texture != null and node.visible


func _texture_node_visible_with_path(root_node: Node, node_name: String, expected_path: String) -> bool:
	var node := _find_node_by_name(root_node, node_name) as TextureRect
	return node != null and node.texture != null and node.visible and node.texture.resource_path == expected_path


func _texture_node_covers_root(root_node: Control, node_name: String) -> bool:
	var node := _find_node_by_name(root_node, node_name) as Control
	if node == null:
		return false
	var root_rect := root_node.get_global_rect()
	var texture_rect := node.get_global_rect()
	return texture_rect.position.x <= root_rect.position.x \
		and texture_rect.position.y <= root_rect.position.y \
		and texture_rect.end.x >= root_rect.end.x \
		and texture_rect.end.y >= root_rect.end.y


func _physics_map_visuals_are_disabled(map_view: Node) -> bool:
	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var physics_snapshot: Dictionary = snapshot.get("movement_physics_dice", {})
	return bool(physics_snapshot.get("has_board_texture", false)) \
		and bool(physics_snapshot.get("fixed_camera", false)) \
		and not bool(physics_snapshot.get("map_visuals_enabled", true)) \
		and not bool(physics_snapshot.get("board_visible", true)) \
		and int(physics_snapshot.get("visible_node_count", -1)) == 0


func _physics_map_stage_is_sized(map_view: Node) -> bool:
	var node := _find_node_by_name(map_view, "MapStagePerspective3DView") as Control
	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var physics_snapshot: Dictionary = snapshot.get("movement_physics_dice", {})
	var control_size := physics_snapshot.get("control_size", Vector2.ZERO) as Vector2
	return node != null and bool(physics_snapshot.get("has_physics_viewport", false)) and control_size.x >= 900.0 and control_size.y >= 500.0


func _pov_tuner_is_hidden(map_view: Node) -> bool:
	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var physics_snapshot: Dictionary = snapshot.get("movement_physics_dice", {})
	return bool(physics_snapshot.get("has_pov_tuner", false)) \
		and _find_node_by_name(map_view, "MapPovTunerPanel") != null \
		and _find_node_by_name(map_view, "CopyMapPovButton") != null \
		and _find_node_by_name(map_view, "ResetMapPovButton") != null \
		and not bool(physics_snapshot.get("pov_tuner_visible", true)) \
		and str(physics_snapshot.get("pov_tuner_text", "")) != ""


func _pov_tuning_updates_camera(map_view: Node) -> bool:
	var physics_view := _find_node_by_name(map_view, "MapStagePerspective3DView")
	if physics_view == null or not physics_view.has_method("automation_set_camera_pov"):
		return false
	var expected_position := Vector3(0.0, 8.2, 7.2)
	var expected_target := Vector3(0.0, 0.12, -0.35)
	var expected_offset := Vector2(32.0, -48.0)
	physics_view.call("automation_set_camera_pov", 38.0, expected_position, expected_target, expected_offset)
	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var physics_snapshot: Dictionary = snapshot.get("movement_physics_dice", {})
	var actual_position := physics_snapshot.get("camera_position", Vector3.ZERO) as Vector3
	var actual_target := physics_snapshot.get("camera_target", Vector3.ZERO) as Vector3
	var actual_offset := physics_snapshot.get("view_offset", Vector2.ZERO) as Vector2
	return absf(float(physics_snapshot.get("camera_fov", 0.0)) - 38.0) < 0.01 \
		and actual_position.distance_to(expected_position) < 0.01 \
		and actual_target.distance_to(expected_target) < 0.01 \
		and actual_offset.distance_to(expected_offset) < 0.01


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var result := _find_node_by_name(child, node_name)
		if result != null:
			return result
	return null


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
