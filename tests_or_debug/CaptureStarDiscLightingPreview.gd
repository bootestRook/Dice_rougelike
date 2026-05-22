extends SceneTree


const OUTPUT_PATH := "res://assets/scenes/preview/preview_shots/star_disc_godot_lit.png"
const DISC_SCENE_PATH := "res://assets/models/stage/star_astrology_disc.tscn"
const ENVIRONMENT_PATH := "res://assets/environments/gm_dice_visual_repro_environment.tres"


func _init() -> void:
	print("--- CaptureStarDiscLightingPreview: start ---")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/scenes/preview/preview_shots"))

	var viewport := SubViewport.new()
	viewport.name = "StarDiscPreviewViewport"
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	var world := Node3D.new()
	world.name = "StarDiscPreviewWorld"
	viewport.add_child(world)

	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = load(ENVIRONMENT_PATH) as Environment
	world.add_child(env_node)

	var stage_scene := load(DISC_SCENE_PATH) as PackedScene
	if stage_scene == null:
		push_error("Cannot load disc scene: %s" % DISC_SCENE_PATH)
		quit(1)
		return
	var stage := stage_scene.instantiate() as Node3D
	stage.name = "PreviewDisc"
	world.add_child(stage)

	_add_lights(world)
	_add_camera(world)

	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var error := _save_viewport_image(viewport, ProjectSettings.globalize_path(OUTPUT_PATH))
	print("saved=%s error=%s" % [ProjectSettings.globalize_path(OUTPUT_PATH), error])
	print("--- CaptureStarDiscLightingPreview: end ---")
	quit(0 if error == OK else 1)


func _add_lights(world: Node3D) -> void:
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-48.0, 38.0, 0.0)
	key.light_color = Color(1.00, 0.86, 0.66)
	key.light_energy = 1.55
	key.light_specular = 0.46
	key.shadow_enabled = true
	world.add_child(key)

	var blue := OmniLight3D.new()
	blue.name = "BlueRimLight"
	blue.position = Vector3(4.6, 2.6, -3.4)
	blue.light_color = Color(0.18, 0.62, 1.0)
	blue.light_energy = 1.05
	blue.light_specular = 0.34
	blue.omni_range = 8.4
	world.add_child(blue)

	var warm := OmniLight3D.new()
	warm.name = "WarmGrazingLight"
	warm.position = Vector3(-3.6, 2.2, 4.2)
	warm.light_color = Color(1.0, 0.62, 0.30)
	warm.light_energy = 0.78
	warm.light_specular = 0.42
	warm.omni_range = 7.4
	world.add_child(warm)


func _add_camera(world: Node3D) -> void:
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.position = Vector3(0.0, 6.3, 7.4)
	camera.fov = 35.0
	camera.near = 0.05
	camera.far = 80.0
	camera.current = true
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.02, 0.0), Vector3.UP)
	world.add_child(camera)


func _save_viewport_image(viewport: Viewport, output_path: String) -> int:
	if viewport == null:
		return FAILED
	var texture := viewport.get_texture()
	if texture == null:
		return FAILED
	var image := texture.get_image()
	if image == null or image.is_empty():
		return FAILED
	return image.save_png(output_path)
