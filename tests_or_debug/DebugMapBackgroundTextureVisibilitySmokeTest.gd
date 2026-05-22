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
	all_passed = _check("2D map board texture stays wired but hidden in 3D tabletop mode", _texture_node_hidden_with_path(map_view, "MapBoardTexture", "res://assets/ui/map/map.png")) and all_passed
	all_passed = _check("2D map board texture keeps fallback coverage", _texture_node_covers_root(map_view, "MapBoardTexture")) and all_passed
	all_passed = _check("map tabletop background is its own red-frame-sized layer", _tabletop_background_is_separate_red_frame_layer(map_view)) and all_passed
	all_passed = _check("map dice viewport stays fixed-size over generated tabletop background", _gm_viewport_overlays_generated_tabletop_background(map_view)) and all_passed
	all_passed = _check("3D dice viewport is mounted at content size", _physics_map_stage_is_sized(map_view)) and all_passed
	all_passed = _check("map action badge, movement dice and roll button share center line", _map_primary_controls_share_center_line(map_view)) and all_passed
	all_passed = _check("3D tabletop uses map config for board and nodes", _physics_map_tabletop_is_enabled(map_view)) and all_passed
	all_passed = _check("movement dice panel texture node stays wired but hidden", _texture_node_hidden(map_view, "MoveDicePanelTexture")) and all_passed
	all_passed = _check("2D map path layer is hidden in 3D tabletop mode", _control_hidden(map_view, "PathFloorLayer")) and all_passed
	all_passed = _check("2D map route node layer is hidden in 3D tabletop mode", _control_hidden(map_view, "MapNodeLayer")) and all_passed
	all_passed = _check("movement controls stay mounted", _find_node_by_name(map_view, "RollMovementButton") != null) and all_passed
	all_passed = _check("map POV tuner stays hidden in 3D tabletop mode", _pov_tuner_is_hidden(map_view)) and all_passed
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


func _texture_node_hidden_with_path(root_node: Node, node_name: String, expected_path: String) -> bool:
	var node := _find_node_by_name(root_node, node_name) as TextureRect
	return node != null and node.texture != null and not node.visible and node.texture.resource_path == expected_path


func _control_hidden(root_node: Node, node_name: String) -> bool:
	var node := _find_node_by_name(root_node, node_name) as Control
	return node != null and not node.visible


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


func _physics_map_tabletop_is_enabled(map_view: Node) -> bool:
	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var physics_snapshot: Dictionary = snapshot.get("movement_physics_dice", {})
	var tabletop_snapshot: Dictionary = physics_snapshot.get("tabletop_3d", {})
	return bool(physics_snapshot.get("has_board_texture", false)) \
		and bool(snapshot.get("tabletop_background_visible", false)) \
		and bool(physics_snapshot.get("fixed_camera", false)) \
		and bool(physics_snapshot.get("map_visuals_enabled", false)) \
		and bool(physics_snapshot.get("has_3d_tabletop", false)) \
		and int(physics_snapshot.get("visible_node_count", -1)) == 32 \
		and not bool(tabletop_snapshot.get("board_visible", true)) \
		and not bool(tabletop_snapshot.get("overlay_visible", true)) \
		and bool(tabletop_snapshot.get("player_marker_visible", false)) \
		and int(tabletop_snapshot.get("node_count", 0)) == 32 \
		and not bool(physics_snapshot.get("gm_throw_mat_visible", true)) \
		and str(physics_snapshot.get("gm_throw_surface_texture_path", "")) == "" \
		and bool(physics_snapshot.get("external_tabletop_background_enabled", false)) \
		and not bool(physics_snapshot.get("tabletop_backing_visible", true)) \
		and str(physics_snapshot.get("tabletop_backing_texture_path", "")) == "res://assets/ui/map/map_tabletop_neon_comic.png" \
		and str(tabletop_snapshot.get("overlay_texture_path", "")) == ""


func _tabletop_background_is_separate_red_frame_layer(map_view: Node) -> bool:
	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var rect := snapshot.get("tabletop_background_rect", Rect2()) as Rect2
	var content_rect := snapshot.get("map_content_rect", Rect2()) as Rect2
	return bool(snapshot.get("tabletop_background_visible", false)) \
		and str(snapshot.get("tabletop_background_texture_path", "")) == "res://assets/ui/map/map_tabletop_neon_comic.png" \
		and _rect_close(rect, Rect2(Vector2(436.0, 188.0), Vector2(1488.0, 897.0)), 2.0) \
		and _rect_close(content_rect, Rect2(Vector2(460.0, 256.0), Vector2(1440.0, 810.0)), 2.0)


func _gm_viewport_overlays_generated_tabletop_background(map_view: Node) -> bool:
	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var physics_snapshot: Dictionary = snapshot.get("movement_physics_dice", {})
	var gm_texture_path := str(physics_snapshot.get("gm_throw_surface_texture_path", ""))
	return gm_texture_path == "" \
		and not bool(physics_snapshot.get("gm_throw_mat_visible", true)) \
		and bool(physics_snapshot.get("external_tabletop_background_enabled", false)) \
		and not bool(physics_snapshot.get("tabletop_backing_visible", true)) \
		and str(physics_snapshot.get("tabletop_backing_texture_path", "")) == "res://assets/ui/map/map_tabletop_neon_comic.png" \
		and _content_view_keeps_fixed_size(physics_snapshot)


func _content_view_keeps_fixed_size(physics_snapshot: Dictionary) -> bool:
	var control_size := physics_snapshot.get("control_size", Vector2.ZERO) as Vector2
	return control_size.distance_to(Vector2(1440.0, 810.0)) <= 2.0


func _rect_close(actual: Rect2, expected: Rect2, tolerance: float) -> bool:
	return actual.position.distance_to(expected.position) <= tolerance \
		and actual.size.distance_to(expected.size) <= tolerance


func _physics_map_stage_is_sized(map_view: Node) -> bool:
	var node := _find_node_by_name(map_view, "MapStagePerspective3DView") as Control
	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var physics_snapshot: Dictionary = snapshot.get("movement_physics_dice", {})
	var control_size := physics_snapshot.get("control_size", Vector2.ZERO) as Vector2
	return node != null and bool(physics_snapshot.get("has_physics_viewport", false)) and control_size.x >= 900.0 and control_size.y >= 500.0


func _map_primary_controls_share_center_line(map_view: Node) -> bool:
	var snapshot: Dictionary = map_view.call("automation_get_snapshot")
	var content_rect := snapshot.get("map_content_rect", Rect2()) as Rect2
	var expected_center_x := content_rect.get_center().x
	var badge := _find_node_by_name(map_view, "CircleActionBadge") as Control
	var roll_button := _find_node_by_name(map_view, "RollMovementButton") as Control
	var first_die := _find_node_by_name(map_view, "MovementDice_1") as Control
	var second_die := _find_node_by_name(map_view, "MovementDice_2") as Control
	if badge == null or roll_button == null or first_die == null or second_die == null:
		return false
	var dice_center_x := (first_die.get_global_rect().get_center().x + second_die.get_global_rect().get_center().x) * 0.5
	return absf(badge.get_global_rect().get_center().x - expected_center_x) <= 2.0 \
		and absf(roll_button.get_global_rect().get_center().x - expected_center_x) <= 2.0 \
		and absf(dice_center_x - expected_center_x) <= 4.0


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
