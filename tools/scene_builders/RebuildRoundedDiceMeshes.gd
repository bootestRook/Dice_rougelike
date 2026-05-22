extends SceneTree


const RoundedDiceMeshFactory := preload("res://scripts/ui/debug/RoundedDiceMeshFactory.gd")

const BASE_MESH_PATH := "res://assets/models/dice/rounded_d6_mesh.tres"
const BASE_PREVIEW_PATH := "res://assets/models/dice/rounded_d6_preview.tscn"
const BATTLE_STAR_MESH_PATH := "res://assets/models/dice/battle_star/rounded_dice_mesh.tres"


func _init() -> void:
	print("--- RebuildRoundedDiceMeshes: start ---")
	var ok := _ensure_directories()
	ok = _save_base_mesh_and_preview() and ok
	ok = _save_battle_star_mesh() and ok
	print("PASS: RebuildRoundedDiceMeshes" if ok else "FAIL: RebuildRoundedDiceMeshes")
	print("--- RebuildRoundedDiceMeshes: end ---")
	quit(0 if ok else 1)


func _ensure_directories() -> bool:
	var ok := true
	for path in ["res://assets/models/dice", "res://assets/models/dice/battle_star"]:
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
		if error != OK and error != ERR_ALREADY_EXISTS:
			push_error("Cannot create directory: %s" % path)
			ok = false
	return ok


func _save_base_mesh_and_preview() -> bool:
	var mesh := _make_mesh("rounded_d6_mesh")
	if not _save_resource(mesh, BASE_MESH_PATH):
		return false

	var root := Node3D.new()
	root.name = "RoundedD6PreviewModel"
	var dice := MeshInstance3D.new()
	dice.name = "DiceMesh"
	dice.mesh = mesh
	root.add_child(dice)
	dice.owner = root
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Cannot pack rounded d6 preview scene")
		root.free()
		return false
	var saved := _save_resource(packed, BASE_PREVIEW_PATH)
	root.free()
	return saved


func _save_battle_star_mesh() -> bool:
	return _save_resource(_make_mesh("RoundedDiceMesh"), BATTLE_STAR_MESH_PATH)


func _make_mesh(resource_name: String) -> ArrayMesh:
	var mesh := RoundedDiceMeshFactory.create_rounded_cube({
		"bevel_radius": 0.125,
		"bevel_segments": 6,
		"edge_length_segments": 7,
		"resource_name": resource_name,
	})
	mesh.resource_name = resource_name
	return mesh


func _save_resource(resource: Resource, path: String) -> bool:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Cannot save resource: %s error=%s" % [path, error])
		return false
	print("saved: %s" % path)
	return true
