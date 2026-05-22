extends RefCounted
class_name RoundedDiceMeshFactory


const DEFAULT_CELL_SIZE := 128.0
const DEFAULT_ATLAS_COLS := 3
const DEFAULT_ATLAS_ROWS := 2
const DEFAULT_DICE_HALF := 0.5
const DEFAULT_BEVEL_RADIUS := 0.125
const DEFAULT_BEVEL_SEGMENTS := 6
const DEFAULT_EDGE_LENGTH_SEGMENTS := 7


static func create_rounded_cube(options: Dictionary = {}) -> ArrayMesh:
	var settings := _settings(options)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	_add_flat_faces(vertices, normals, uvs, indices, settings)
	_add_edge_patches(vertices, normals, uvs, indices, settings)
	_add_corner_patches(vertices, normals, uvs, indices, settings)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.resource_name = str(settings["resource_name"])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _settings(options: Dictionary) -> Dictionary:
	var dice_half := float(options.get("dice_half", DEFAULT_DICE_HALF))
	var bevel_radius := clampf(float(options.get("bevel_radius", DEFAULT_BEVEL_RADIUS)), 0.001, dice_half - 0.001)
	return {
		"cell_size": float(options.get("cell_size", DEFAULT_CELL_SIZE)),
		"atlas_cols": int(options.get("atlas_cols", DEFAULT_ATLAS_COLS)),
		"atlas_rows": int(options.get("atlas_rows", DEFAULT_ATLAS_ROWS)),
		"dice_half": dice_half,
		"bevel_radius": bevel_radius,
		"bevel_segments": maxi(2, int(options.get("bevel_segments", DEFAULT_BEVEL_SEGMENTS))),
		"edge_length_segments": maxi(2, int(options.get("edge_length_segments", DEFAULT_EDGE_LENGTH_SEGMENTS))),
		"inner_half": dice_half - bevel_radius,
		"resource_name": str(options.get("resource_name", "RoundedDiceMesh")),
	}


static func _add_flat_faces(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	settings: Dictionary
) -> void:
	var h := float(settings["dice_half"])
	var a := float(settings["inner_half"])
	_add_face_grid(vertices, normals, uvs, indices, settings, 1, h, 0, 2, Vector3.UP, -a, a, -a, a)
	_add_face_grid(vertices, normals, uvs, indices, settings, 1, -h, 0, 2, Vector3.DOWN, -a, a, -a, a)
	_add_face_grid(vertices, normals, uvs, indices, settings, 2, h, 0, 1, Vector3.BACK, -a, a, -a, a)
	_add_face_grid(vertices, normals, uvs, indices, settings, 2, -h, 0, 1, Vector3.FORWARD, -a, a, -a, a)
	_add_face_grid(vertices, normals, uvs, indices, settings, 0, h, 2, 1, Vector3.RIGHT, -a, a, -a, a)
	_add_face_grid(vertices, normals, uvs, indices, settings, 0, -h, 2, 1, Vector3.LEFT, -a, a, -a, a)


static func _add_face_grid(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	settings: Dictionary,
	fixed_axis: int,
	fixed_value: float,
	axis_u: int,
	axis_v: int,
	normal: Vector3,
	min_u: float,
	max_u: float,
	min_v: float,
	max_v: float
) -> void:
	var grid: Array = []
	var edge_segments := int(settings["edge_length_segments"])
	for y in range(edge_segments + 1):
		var row: Array[int] = []
		var v := lerpf(min_v, max_v, float(y) / float(edge_segments))
		for x in range(edge_segments + 1):
			var u := lerpf(min_u, max_u, float(x) / float(edge_segments))
			var point := Vector3.ZERO
			point[fixed_axis] = fixed_value
			point[axis_u] = u
			point[axis_v] = v
			row.append(_append_vertex(vertices, normals, uvs, point, normal, settings))
		grid.append(row)
	_add_grid_indices(vertices, normals, indices, grid)


static func _add_edge_patches(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	settings: Dictionary
) -> void:
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			_add_edge_patch(vertices, normals, uvs, indices, settings, 0, sx, 1, sy, 2)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_edge_patch(vertices, normals, uvs, indices, settings, 0, sx, 2, sz, 1)
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_edge_patch(vertices, normals, uvs, indices, settings, 1, sy, 2, sz, 0)


static func _add_edge_patch(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	settings: Dictionary,
	axis_a: int,
	sign_a: float,
	axis_b: int,
	sign_b: float,
	free_axis: int
) -> void:
	var grid: Array = []
	var bevel_segments := int(settings["bevel_segments"])
	var edge_segments := int(settings["edge_length_segments"])
	var inner_half := float(settings["inner_half"])
	var bevel_radius := float(settings["bevel_radius"])
	for i in range(bevel_segments + 1):
		var theta := (PI * 0.5) * float(i) / float(bevel_segments)
		var row: Array[int] = []
		for j in range(edge_segments + 1):
			var t := -inner_half + 2.0 * inner_half * float(j) / float(edge_segments)
			var normal := Vector3.ZERO
			normal[axis_a] = sign_a * cos(theta)
			normal[axis_b] = sign_b * sin(theta)
			normal = normal.normalized()
			var position := Vector3.ZERO
			position[axis_a] = sign_a * inner_half + normal[axis_a] * bevel_radius
			position[axis_b] = sign_b * inner_half + normal[axis_b] * bevel_radius
			position[free_axis] = t
			row.append(_append_vertex(vertices, normals, uvs, position, normal, settings))
		grid.append(row)
	_add_grid_indices(vertices, normals, indices, grid)


static func _add_corner_patches(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	settings: Dictionary
) -> void:
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_add_corner_patch(vertices, normals, uvs, indices, settings, sx, sy, sz)


static func _add_corner_patch(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	settings: Dictionary,
	sx: float,
	sy: float,
	sz: float
) -> void:
	var grid: Array = []
	var bevel_segments := int(settings["bevel_segments"])
	var inner_half := float(settings["inner_half"])
	var bevel_radius := float(settings["bevel_radius"])
	for i in range(bevel_segments + 1):
		var u := (PI * 0.5) * float(i) / float(bevel_segments)
		var row: Array[int] = []
		for j in range(bevel_segments + 1):
			var v := (PI * 0.5) * float(j) / float(bevel_segments)
			var n_abs := Vector3(cos(u) * cos(v), sin(u) * cos(v), sin(v))
			var normal := Vector3(sx * n_abs.x, sy * n_abs.y, sz * n_abs.z).normalized()
			var center := Vector3(sx * inner_half, sy * inner_half, sz * inner_half)
			var position := center + normal * bevel_radius
			row.append(_append_vertex(vertices, normals, uvs, position, normal, settings))
		grid.append(row)
	_add_grid_indices(vertices, normals, indices, grid)


static func _add_grid_indices(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, grid: Array) -> void:
	for y in range(grid.size() - 1):
		var row_a: Array = grid[y]
		var row_b: Array = grid[y + 1]
		for x in range(row_a.size() - 1):
			var a := int(row_a[x])
			var b := int(row_b[x])
			var c := int(row_b[x + 1])
			var d := int(row_a[x + 1])
			_add_triangle_indices(vertices, normals, indices, a, b, c)
			_add_triangle_indices(vertices, normals, indices, a, c, d)


static func _append_vertex(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	position: Vector3,
	normal: Vector3,
	settings: Dictionary
) -> int:
	var normalized := normal.normalized()
	vertices.append(position)
	normals.append(normalized)
	uvs.append(_uv_for_point(position, normalized, settings))
	return vertices.size() - 1


static func _add_triangle_indices(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, i0: int, i1: int, i2: int) -> void:
	var edge_a := vertices[i1] - vertices[i0]
	var edge_b := vertices[i2] - vertices[i0]
	var face_normal := edge_a.cross(edge_b)
	if face_normal.length_squared() <= 0.00000001:
		return
	var target_normal := (normals[i0] + normals[i1] + normals[i2]).normalized()
	# Godot 3D treats clockwise vertex order as front-facing. For an exterior
	# face with outward vertex normals, the geometric cross normal points inward.
	if face_normal.dot(target_normal) > 0.0:
		indices.append_array(PackedInt32Array([i0, i2, i1]))
	else:
		indices.append_array(PackedInt32Array([i0, i1, i2]))


static func _uv_for_point(position: Vector3, normal: Vector3, settings: Dictionary) -> Vector2:
	var value := _face_value_from_normal(normal)
	var rect := _uv_rect_for_value(value, settings)
	var dice_half := float(settings["dice_half"])
	var local := Vector2.ZERO
	match value:
		1, 6:
			local = Vector2(position.x + dice_half, position.z + dice_half)
		2, 5:
			local = Vector2(position.x + dice_half, position.y + dice_half)
		3, 4:
			local = Vector2(position.z + dice_half, position.y + dice_half)
	local.x = clampf(local.x, 0.0, 1.0)
	local.y = clampf(local.y, 0.0, 1.0)
	return Vector2(rect.position.x + rect.size.x * local.x, rect.position.y + rect.size.y * (1.0 - local.y))


static func _face_value_from_normal(normal: Vector3) -> int:
	var ax := absf(normal.x)
	var ay := absf(normal.y)
	var az := absf(normal.z)
	if ay >= ax and ay >= az:
		return 1 if normal.y >= 0.0 else 6
	if az >= ax:
		return 2 if normal.z >= 0.0 else 5
	return 3 if normal.x >= 0.0 else 4


static func _uv_rect_for_value(value: int, settings: Dictionary) -> Rect2:
	var index := value - 1
	var atlas_cols := int(settings["atlas_cols"])
	var atlas_rows := int(settings["atlas_rows"])
	var pad := 1.5 / float(settings["cell_size"])
	var col := index % atlas_cols
	var row := int(index / atlas_cols)
	var u0 := float(col) / float(atlas_cols) + pad
	var v0 := float(row) / float(atlas_rows) + pad
	var u1 := float(col + 1) / float(atlas_cols) - pad
	var v1 := float(row + 1) / float(atlas_rows) - pad
	return Rect2(Vector2(u0, v0), Vector2(u1 - u0, v1 - v0))
