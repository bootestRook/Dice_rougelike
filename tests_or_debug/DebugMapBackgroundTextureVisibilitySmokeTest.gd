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
	all_passed = _check("map board texture node shows parchment map", _texture_node_visible_with_path(map_view, "MapBoardTexture", "res://assets/ui/map/map.png")) and all_passed
	all_passed = _check("map board texture covers the scoring and prep stage", _texture_node_covers_root(map_view, "MapBoardTexture")) and all_passed
	all_passed = _check("movement dice panel texture node stays wired but hidden", _texture_node_hidden(map_view, "MoveDicePanelTexture")) and all_passed
	all_passed = _check("map path floor tiles stay visible", _texture_node_visible(map_view, "PathFloorTexture")) and all_passed
	all_passed = _check("map route nodes stay visible", _texture_node_visible(map_view, "NodeTexture")) and all_passed
	all_passed = _check("movement controls stay mounted", _find_node_by_name(map_view, "RollMovementButton") != null) and all_passed

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
