extends Node3D
class_name MapStageTabletop3D


const DEFAULT_TABLE_SIZE := Vector2(16.8, 11.0)
const BOARD_Y := 0.002
const OVERLAY_Y := 0.012
const NODE_Y := 0.18
const MARKER_Y := 0.32


var art_config: Resource = null
var map_nodes: Array = []
var current_map_index := 0
var board_mesh: MeshInstance3D = null
var overlay_mesh: MeshInstance3D = null
var route_node_root: Node3D = null
var player_marker_sprite: Sprite3D = null
var node_visuals: Array[Node3D] = []
var board_mesh_enabled: bool = true


func _ready() -> void:
	_ensure_built()


func set_art_config(new_art_config: Resource) -> void:
	art_config = new_art_config
	_ensure_built()
	_refresh_board()
	_refresh_overlay()
	_refresh_nodes()


func set_map_state(nodes: Array, current_index: int) -> void:
	map_nodes = nodes.duplicate(true)
	current_map_index = current_index
	_ensure_built()
	_refresh_nodes()


func set_tabletop_enabled(enabled: bool) -> void:
	visible = enabled
	if board_mesh != null:
		board_mesh.visible = enabled and board_mesh_enabled and _tabletop_board_texture() != null
	if overlay_mesh != null:
		overlay_mesh.visible = enabled and _tabletop_overlay_texture() != null
	if route_node_root != null:
		route_node_root.visible = enabled
	if player_marker_sprite != null:
		player_marker_sprite.visible = enabled and not map_nodes.is_empty()


func set_board_mesh_enabled(enabled: bool) -> void:
	board_mesh_enabled = enabled
	if board_mesh != null:
		board_mesh.visible = visible and board_mesh_enabled and _tabletop_board_texture() != null


func animate_marker_to_index(index: int, duration: float) -> void:
	current_map_index = index
	if player_marker_sprite == null:
		return
	var target_position := _route_world_position(index, maxi(1, map_nodes.size())) + Vector3(0.0, MARKER_Y, 0.0)
	if not player_marker_sprite.visible:
		player_marker_sprite.position = target_position
		return
	var tween := create_tween()
	tween.tween_property(player_marker_sprite, "position", target_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func automation_get_snapshot() -> Dictionary:
	return {
		"root_exists": true,
		"visible": visible,
		"board_visible": board_mesh != null and board_mesh.visible,
		"board_mesh_enabled": board_mesh_enabled,
		"overlay_visible": overlay_mesh != null and overlay_mesh.visible,
		"node_count": map_nodes.size(),
		"visible_node_count": _visible_node_count(),
		"player_marker_visible": player_marker_sprite != null and player_marker_sprite.visible,
		"board_texture_path": _texture_path(_tabletop_board_texture()),
		"overlay_texture_path": _texture_path(_tabletop_overlay_texture()),
		"table_size": _table_size(),
	}


func _ensure_built() -> void:
	if board_mesh != null:
		return

	name = "MapStageTabletop3D"

	board_mesh = MeshInstance3D.new()
	board_mesh.name = "MapTabletopBoard3D"
	var board_plane := PlaneMesh.new()
	board_plane.size = _table_size()
	board_mesh.mesh = board_plane
	board_mesh.position = Vector3(0.0, BOARD_Y, 0.0)
	add_child(board_mesh)

	overlay_mesh = MeshInstance3D.new()
	overlay_mesh.name = "MapTabletopOverlay3D"
	var overlay_plane := PlaneMesh.new()
	overlay_plane.size = _table_size()
	overlay_mesh.mesh = overlay_plane
	overlay_mesh.position = Vector3(0.0, OVERLAY_Y, 0.0)
	add_child(overlay_mesh)

	route_node_root = Node3D.new()
	route_node_root.name = "MapRouteNodeRoot3D"
	add_child(route_node_root)

	player_marker_sprite = Sprite3D.new()
	player_marker_sprite.name = "PlayerMarker3D"
	player_marker_sprite.pixel_size = 0.0045
	player_marker_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(player_marker_sprite)

	_refresh_board()
	_refresh_overlay()


func _refresh_board() -> void:
	if board_mesh == null:
		return
	var plane := board_mesh.mesh as PlaneMesh
	if plane != null:
		plane.size = _table_size()
	board_mesh.material_override = _make_board_material(_tabletop_board_texture(), _tabletop_board_tint(), false)
	board_mesh.visible = visible and board_mesh_enabled and _tabletop_board_texture() != null


func _refresh_overlay() -> void:
	if overlay_mesh == null:
		return
	var plane := overlay_mesh.mesh as PlaneMesh
	if plane != null:
		plane.size = _table_size()
	overlay_mesh.material_override = _make_board_material(_tabletop_overlay_texture(), _tabletop_overlay_tint(), true)
	overlay_mesh.visible = visible and _tabletop_overlay_texture() != null


func _refresh_nodes() -> void:
	if route_node_root == null:
		return
	_ensure_node_visuals(map_nodes.size())
	for index in range(node_visuals.size()):
		var node_visual := node_visuals[index]
		var active := index < map_nodes.size()
		node_visual.visible = visible and active
		if not active:
			continue
		var node_data := map_nodes[index] as Dictionary
		var node_type := StringName(str(node_data.get("node_type", "event")))
		var is_current := int(node_data.get("index", index)) == current_map_index
		var is_cleared := bool(node_data.get("is_cleared", false))
		node_visual.position = _route_world_position(index, map_nodes.size()) + Vector3(0.0, NODE_Y, 0.0)
		node_visual.scale = Vector3.ONE * (1.15 if is_current else 1.0)

		var sprite := node_visual.get_node("NodeSprite") as Sprite3D
		sprite.texture = _node_texture_for_type(node_type)
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.72 if is_cleared else 1.0)

		var label := node_visual.get_node("NodeLabel") as Label3D
		label.text = _node_short_name(node_type)
		label.modulate = Color(1.0, 0.86, 0.31, 0.72 if is_cleared else 1.0)

	if player_marker_sprite != null:
		player_marker_sprite.texture = _player_marker_texture()
		player_marker_sprite.visible = visible and not map_nodes.is_empty()
		player_marker_sprite.position = _route_world_position(current_map_index, maxi(1, map_nodes.size())) + Vector3(0.0, MARKER_Y, 0.0)


func _ensure_node_visuals(count: int) -> void:
	while node_visuals.size() < count:
		var index := node_visuals.size()
		var root := Node3D.new()
		root.name = "MapNode3D_%02d" % [index]
		route_node_root.add_child(root)

		var sprite := Sprite3D.new()
		sprite.name = "NodeSprite"
		sprite.pixel_size = 0.0046
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		root.add_child(sprite)

		var label := Label3D.new()
		label.name = "NodeLabel"
		label.font_size = 46
		label.pixel_size = 0.0047
		label.outline_size = 7
		label.outline_modulate = Color(0.0, 0.0, 0.0, 0.86)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0.0, -0.24, 0.0)
		root.add_child(label)

		node_visuals.append(root)


func _make_board_material(texture: Texture2D, tint: Color, transparent: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = texture
	material.roughness = 0.72
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if transparent or tint.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _route_world_position(index: int, count: int) -> Vector3:
	var positions := _route_world_positions(maxi(1, count))
	if positions.is_empty():
		return Vector3.ZERO
	return positions[wrapi(index, 0, positions.size())]


func _route_world_positions(count: int) -> Array[Vector3]:
	if count == 32:
		return _route_world_positions_for_32_nodes()

	var result: Array[Vector3] = []
	var bounds := _route_bounds()
	var left := float(bounds["left"])
	var right := float(bounds["right"])
	var top := float(bounds["top"])
	var bottom := float(bounds["bottom"])
	var width := maxf(1.0, right - left)
	var depth := maxf(1.0, bottom - top)
	var perimeter := width * 2.0 + depth * 2.0
	for route_index in range(count):
		var distance := perimeter * float(route_index) / float(maxi(1, count))
		var position := Vector3.ZERO
		if distance <= width:
			position = Vector3(left + distance, 0.0, top)
		elif distance <= width + depth:
			position = Vector3(right, 0.0, top + distance - width)
		elif distance <= width * 2.0 + depth:
			position = Vector3(right - (distance - width - depth), 0.0, bottom)
		else:
			position = Vector3(left, 0.0, bottom - (distance - width * 2.0 - depth))
		result.append(position)
	return result


func _route_world_positions_for_32_nodes() -> Array[Vector3]:
	var bounds := _route_bounds()
	var left := float(bounds["left"])
	var right := float(bounds["right"])
	var top := float(bounds["top"])
	var bottom := float(bounds["bottom"])
	var result: Array[Vector3] = []
	result.append_array(_line_world_positions(Vector3(left, 0.0, top), Vector3(right, 0.0, top), 11))
	result.append_array(_line_world_positions(Vector3(right, 0.0, top), Vector3(right, 0.0, bottom), 7).slice(1, 6))
	result.append_array(_line_world_positions(Vector3(right, 0.0, bottom), Vector3(left, 0.0, bottom), 11))
	result.append_array(_line_world_positions(Vector3(left, 0.0, bottom), Vector3(left, 0.0, top), 7).slice(1, 6))
	return result


func _line_world_positions(start: Vector3, end: Vector3, count: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if count <= 1:
		result.append(start)
		return result
	for index in range(count):
		var t := float(index) / float(count - 1)
		result.append(start.lerp(end, t))
	return result


func _route_bounds() -> Dictionary:
	var table := _table_size()
	var inset := _tabletop_route_inset()
	return {
		"left": -table.x * 0.5 + inset.x,
		"right": table.x * 0.5 - inset.x,
		"top": -table.y * 0.5 + inset.y,
		"bottom": table.y * 0.5 - inset.y,
	}


func _visible_node_count() -> int:
	if route_node_root == null or not route_node_root.visible:
		return 0
	var count := 0
	for node_visual in node_visuals:
		if node_visual != null and is_instance_valid(node_visual) and node_visual.visible:
			count += 1
	return count


func _table_size() -> Vector2:
	if art_config != null:
		var configured = art_config.get("tabletop_table_size")
		if configured is Vector2:
			var size := configured as Vector2
			if size.x > 0.0 and size.y > 0.0:
				return size
	return DEFAULT_TABLE_SIZE


func _tabletop_route_inset() -> Vector2:
	if art_config != null:
		var configured = art_config.get("tabletop_route_inset")
		if configured is Vector2:
			var inset := configured as Vector2
			return Vector2(maxf(0.0, inset.x), maxf(0.0, inset.y))
	return Vector2(0.78, 0.72)


func _tabletop_board_texture() -> Texture2D:
	if art_config == null:
		return null
	var texture := art_config.get("tabletop_board_texture") as Texture2D
	if texture != null:
		return texture
	return art_config.get("map_stage_skin_texture") as Texture2D


func _tabletop_overlay_texture() -> Texture2D:
	if art_config == null:
		return null
	return art_config.get("tabletop_overlay_texture") as Texture2D


func _tabletop_board_tint() -> Color:
	if art_config != null:
		var value = art_config.get("tabletop_board_tint")
		if value is Color:
			return value as Color
	return Color.WHITE


func _tabletop_overlay_tint() -> Color:
	if art_config != null:
		var value = art_config.get("tabletop_overlay_tint")
		if value is Color:
			return value as Color
	return Color(1.0, 1.0, 1.0, 0.45)


func _player_marker_texture() -> Texture2D:
	if art_config != null:
		return art_config.get("player_marker_texture") as Texture2D
	return null


func _node_texture_for_type(node_type: StringName) -> Texture2D:
	if art_config == null:
		return null
	if art_config.has_method("node_texture_for_type"):
		return art_config.call("node_texture_for_type", node_type)
	return null


func _node_short_name(node_type: StringName) -> String:
	match node_type:
		&"start":
			return "起点"
		&"battle":
			return "战斗"
		&"elite":
			return "精英"
		&"boss":
			return "首领"
		&"shop":
			return "商店"
		&"forge":
			return "铸骰"
		&"reward":
			return "奖励"
		&"penalty":
			return "惩罚"
		&"event":
			return "奇遇"
		&"rest":
			return "休整"
		_:
			return "?"


func _texture_path(texture: Texture2D) -> String:
	if texture == null:
		return ""
	return texture.resource_path
