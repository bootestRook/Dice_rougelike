extends Node
class_name SceneRouter


signal scene_change_requested(scene_path: String)
signal scene_changed(scene_path: String)


var current_scene_path: String = ""


func change_scene(scene_path: String) -> Error:
	scene_change_requested.emit(scene_path)
	var error := get_tree().change_scene_to_file(scene_path)

	if error == OK:
		current_scene_path = scene_path
		scene_changed.emit(scene_path)

	return error
