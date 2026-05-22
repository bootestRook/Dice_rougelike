extends SceneTree


const RoundedDiceMeshFactory := preload("res://scripts/ui/debug/RoundedDiceMeshFactory.gd")

const PREVIEW_BODY_MESH_PATH := "res://assets/models/dice/preview_rounded_d6_body_mesh.tres"


func _init() -> void:
	print("--- RebuildDicePreviewBodyMesh: start ---")
	var ok := _ensure_directories()
	if ok:
		ok = _save_preview_body_mesh() and ok
	print("PASS: RebuildDicePreviewBodyMesh" if ok else "FAIL: RebuildDicePreviewBodyMesh")
	print("--- RebuildDicePreviewBodyMesh: end ---")
	quit(0 if ok else 1)


func _ensure_directories() -> bool:
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/models/dice"))
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Cannot create dice model directory")
		return false
	return true


func _save_preview_body_mesh() -> bool:
	var mesh := RoundedDiceMeshFactory.create_rounded_cube({
		"bevel_radius": 0.125,
		"bevel_segments": 6,
		"edge_length_segments": 9,
		"resource_name": "preview_rounded_d6_body_mesh",
	})
	mesh.resource_name = "preview_rounded_d6_body_mesh"
	return _save_resource(mesh, PREVIEW_BODY_MESH_PATH)


func _save_resource(resource: Resource, path: String) -> bool:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Cannot save resource: %s error=%s" % [path, error])
		return false
	print("saved: %s" % path)
	return true
