extends SceneTree
class_name DebugRoundedD6MeshSmokeTest


const ROUNDED_MESH_PATH := "res://assets/models/dice/rounded_d6_mesh.tres"


func _init() -> void:
	print("--- DebugRoundedD6MeshSmokeTest: start ---")
	var all_passed := true
	var mesh := load(ROUNDED_MESH_PATH) as ArrayMesh
	all_passed = _check("rounded d6 mesh loads", mesh != null) and all_passed
	if mesh != null:
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		all_passed = _check("rounded d6 has vertices", vertices.size() > 0) and all_passed
		all_passed = _check("rounded d6 has triangle indices", indices.size() > 0 and indices.size() % 3 == 0) and all_passed
		all_passed = _check("rounded d6 has normals for every vertex", normals.size() == vertices.size()) and all_passed
		all_passed = _check("rounded d6 has dense bevel geometry", vertices.size() >= 900) and all_passed
		all_passed = _check("rounded d6 top edge has continuous bevel normals", _top_edge_normal_bucket_count(normals) >= 4) and all_passed
		all_passed = _check("rounded d6 corners are rounded geometry", _corner_normal_count(normals) >= 64) and all_passed
		var area_by_axis := _surface_area_by_axis(vertices, indices)
		for axis in ["+X", "-X", "+Y", "-Y", "+Z", "-Z"]:
			all_passed = _check("rounded d6 closed face area %s" % axis, float(area_by_axis.get(axis, 0.0)) >= 0.55) and all_passed
		var boundary_count := _boundary_edge_count(vertices, indices)
		all_passed = _check("rounded d6 has no open boundary edges", boundary_count == 0) and all_passed
		all_passed = _check("rounded d6 vertex normals point away from center", _outward_vertex_normal_error_count(vertices, normals) == 0) and all_passed
		var winding_errors := _godot_front_face_winding_error_count(vertices, normals, indices)
		all_passed = _check("rounded d6 triangle winding is Godot front-facing outside", winding_errors == 0) and all_passed
		var position_winding_errors := _position_front_face_winding_error_count(vertices, indices)
		all_passed = _check("rounded d6 triangle winding matches exterior position", position_winding_errors == 0) and all_passed
	print("PASS: DebugRoundedD6MeshSmokeTest" if all_passed else "FAIL: DebugRoundedD6MeshSmokeTest")
	print("--- DebugRoundedD6MeshSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _surface_area_by_axis(vertices: PackedVector3Array, indices: PackedInt32Array) -> Dictionary:
	var result := {
		"+X": 0.0,
		"-X": 0.0,
		"+Y": 0.0,
		"-Y": 0.0,
		"+Z": 0.0,
		"-Z": 0.0,
	}
	for i in range(0, indices.size(), 3):
		var a := vertices[int(indices[i])]
		var b := vertices[int(indices[i + 1])]
		var c := vertices[int(indices[i + 2])]
		var normal := (b - a).cross(c - a)
		var area := normal.length() * 0.5
		if area <= 0.000001:
			continue
		normal = -normal.normalized()
		var axis := _dominant_axis_key(normal)
		result[axis] = float(result[axis]) + area
	return result


func _boundary_edge_count(vertices: PackedVector3Array, indices: PackedInt32Array) -> int:
	var edge_counts := {}
	for i in range(0, indices.size(), 3):
		var ids := [int(indices[i]), int(indices[i + 1]), int(indices[i + 2])]
		_count_edge(edge_counts, vertices[ids[0]], vertices[ids[1]])
		_count_edge(edge_counts, vertices[ids[1]], vertices[ids[2]])
		_count_edge(edge_counts, vertices[ids[2]], vertices[ids[0]])
	var count := 0
	for edge_key in edge_counts.keys():
		if int(edge_counts[edge_key]) != 2:
			count += 1
	return count


func _godot_front_face_winding_error_count(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> int:
	var count := 0
	for i in range(0, indices.size(), 3):
		var ia := int(indices[i])
		var ib := int(indices[i + 1])
		var ic := int(indices[i + 2])
		var face_normal := (vertices[ib] - vertices[ia]).cross(vertices[ic] - vertices[ia])
		if face_normal.length_squared() <= 0.00000001:
			continue
		var target := (normals[ia] + normals[ib] + normals[ic]).normalized()
		if face_normal.normalized().dot(target) > -0.72:
			count += 1
	return count


func _outward_vertex_normal_error_count(vertices: PackedVector3Array, normals: PackedVector3Array) -> int:
	var count := 0
	for i in range(vertices.size()):
		var expected := _dominant_position_normal(vertices[i])
		if expected == Vector3.ZERO:
			continue
		if normals[i].normalized().dot(expected) < 0.45:
			count += 1
	return count


func _position_front_face_winding_error_count(vertices: PackedVector3Array, indices: PackedInt32Array) -> int:
	var count := 0
	for i in range(0, indices.size(), 3):
		var a := vertices[int(indices[i])]
		var b := vertices[int(indices[i + 1])]
		var c := vertices[int(indices[i + 2])]
		var cross_normal := (b - a).cross(c - a)
		if cross_normal.length_squared() <= 0.00000001:
			continue
		var expected := _dominant_position_normal((a + b + c) / 3.0)
		if expected == Vector3.ZERO:
			continue
		var godot_front_normal := -cross_normal.normalized()
		if godot_front_normal.dot(expected) < 0.45:
			count += 1
	return count


func _dominant_position_normal(position: Vector3) -> Vector3:
	var ax := absf(position.x)
	var ay := absf(position.y)
	var az := absf(position.z)
	if ax >= ay and ax >= az:
		return Vector3.RIGHT if position.x >= 0.0 else Vector3.LEFT
	if ay >= az:
		return Vector3.UP if position.y >= 0.0 else Vector3.DOWN
	return Vector3.BACK if position.z >= 0.0 else Vector3.FORWARD


func _count_edge(edge_counts: Dictionary, a: Vector3, b: Vector3) -> void:
	var ka := _vertex_key(a)
	var kb := _vertex_key(b)
	var key := "%s|%s" % [ka, kb] if ka < kb else "%s|%s" % [kb, ka]
	edge_counts[key] = int(edge_counts.get(key, 0)) + 1


func _vertex_key(v: Vector3) -> String:
	return "%d,%d,%d" % [
		roundi(v.x * 100000.0),
		roundi(v.y * 100000.0),
		roundi(v.z * 100000.0),
	]


func _dominant_axis_key(normal: Vector3) -> String:
	var ax := absf(normal.x)
	var ay := absf(normal.y)
	var az := absf(normal.z)
	if ax >= ay and ax >= az:
		return "+X" if normal.x >= 0.0 else "-X"
	if ay >= az:
		return "+Y" if normal.y >= 0.0 else "-Y"
	return "+Z" if normal.z >= 0.0 else "-Z"


func _top_edge_normal_bucket_count(normals: PackedVector3Array) -> int:
	var buckets := {}
	for normal in normals:
		var horizontal := maxf(absf(normal.x), absf(normal.z))
		if normal.y > 0.08 and normal.y < 0.98 and horizontal > 0.08:
			buckets[roundi(normal.y * 100.0)] = true
	return buckets.size()


func _corner_normal_count(normals: PackedVector3Array) -> int:
	var count := 0
	for normal in normals:
		if absf(normal.x) > 0.08 and absf(normal.y) > 0.08 and absf(normal.z) > 0.08:
			count += 1
	return count


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
