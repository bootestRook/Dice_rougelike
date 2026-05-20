extends SubViewportContainer
class_name GmDiceViewport


const VIEWPORT_SIZE := Vector2i(1280, 720)
const VISIBLE_MAT_WIDTH := 16.8
const VISIBLE_MAT_DEPTH := 11.0
const COLLISION_WIDTH := 14.2
const COLLISION_DEPTH := 8.2
const FLOOR_THICKNESS := 0.56
const WALL_HEIGHT := 6.4
const WALL_THICKNESS := 1.85
const GUARD_WALL_THICKNESS := 2.25
const CEILING_THICKNESS := 0.70
const DEFAULT_CAMERA_FOV := 38.0
const DEFAULT_CAMERA_POSITION := Vector3(0.0, 18.5, 1.0)
const DEFAULT_CAMERA_LOOK_AT := Vector3(0.0, 0.72, -0.04)
const DEFAULT_READY_ROW_HEIGHT := 7.5
const DEFAULT_KEY_LIGHT_ROTATION := Vector3(-63.0, 115.0, 0.0)


var sub_viewport: SubViewport = null
var dice_world: Node3D = null
var fixed_camera: Camera3D = null
var key_light: DirectionalLight3D = null
var dice_box_anchors: Node3D = null
var spawn_point: Marker3D = null
var dice_container: Node3D = null
var floor_physics_material: PhysicsMaterial = null
var wall_physics_material: PhysicsMaterial = null
var camera_fov := DEFAULT_CAMERA_FOV
var camera_position := DEFAULT_CAMERA_POSITION
var camera_look_at := DEFAULT_CAMERA_LOOK_AT
var ready_row_height := DEFAULT_READY_ROW_HEIGHT
var key_light_rotation := DEFAULT_KEY_LIGHT_ROTATION


func build() -> void:
	name = "DiceViewport"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	sub_viewport = SubViewport.new()
	sub_viewport.name = "SubViewport"
	sub_viewport.size = VIEWPORT_SIZE
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.transparent_bg = false
	add_child(sub_viewport)

	dice_world = Node3D.new()
	dice_world.name = "DiceWorld"
	sub_viewport.add_child(dice_world)

	_build_environment()
	_build_collision_stage()
	_build_anchors()
	_build_camera()


func configure_camera(new_fov: float, new_position: Vector3, new_look_at: Vector3) -> void:
	camera_fov = new_fov
	camera_position = new_position
	camera_look_at = new_look_at
	_apply_camera_settings()


func configure_ready_row_height(new_height: float) -> void:
	ready_row_height = new_height
	var show_point := (dice_box_anchors.get_node_or_null("ShowPoint") as Marker3D) if dice_box_anchors != null else null
	if show_point != null:
		show_point.position.y = ready_row_height


func configure_key_light(new_pitch: float, new_yaw: float) -> void:
	key_light_rotation = Vector3(new_pitch, new_yaw, 0.0)
	if key_light != null:
		key_light.rotation_degrees = key_light_rotation


func get_camera_state() -> Dictionary:
	return {
		"display_mode": "fixed_2_5d_subviewport",
		"camera_control_enabled": false,
		"camera_projection": "perspective",
		"camera_fov": camera_fov,
		"camera_yaw": 0.0,
		"camera_pitch": _camera_pitch_degrees(),
		"camera_distance": camera_position.distance_to(camera_look_at),
		"camera_position": fixed_camera.position if fixed_camera != null else camera_position,
		"camera_look_at": camera_look_at,
		"dice_initial_height": ready_row_height,
		"key_light_pitch": key_light_rotation.x,
		"key_light_yaw": key_light_rotation.y,
		"visible_stage_size": Vector2(VISIBLE_MAT_WIDTH, VISIBLE_MAT_DEPTH),
		"collision_stage_size": Vector2(COLLISION_WIDTH, COLLISION_DEPTH),
	}


func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.08, 0.20)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.50, 0.48, 0.66)
	env.ambient_light_energy = 0.82
	environment.environment = env
	dice_world.add_child(environment)

	key_light = DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.rotation_degrees = key_light_rotation
	key_light.light_energy = 2.5
	key_light.shadow_enabled = true
	dice_world.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "FillLight"
	fill_light.position = Vector3(-2.6, 3.0, 2.8)
	fill_light.light_color = Color(0.62, 0.86, 1.0)
	fill_light.light_energy = 1.6
	fill_light.omni_range = 7.0
	dice_world.add_child(fill_light)

	var rim_light := OmniLight3D.new()
	rim_light.name = "RimLight"
	rim_light.position = Vector3(3.2, 2.2, -2.7)
	rim_light.light_color = Color(0.00, 0.94, 0.72)
	rim_light.light_energy = 1.35
	rim_light.omni_range = 6.0
	dice_world.add_child(rim_light)


func _build_collision_stage() -> void:
	floor_physics_material = PhysicsMaterial.new()
	floor_physics_material.friction = 0.34
	floor_physics_material.bounce = 0.28
	wall_physics_material = PhysicsMaterial.new()
	wall_physics_material.friction = 0.24
	wall_physics_material.bounce = 0.42

	var floor_body := _add_static_box(
		dice_world,
		"ThrowPlane",
		Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0),
		Vector3(COLLISION_WIDTH, FLOOR_THICKNESS, COLLISION_DEPTH),
		null,
		floor_physics_material
	)
	floor_body.collision_layer = 1
	floor_body.collision_mask = 1

	var safety_net := _add_static_box(
		dice_world,
		"SafetyNet",
		Vector3(0.0, -0.90, 0.0),
		Vector3(COLLISION_WIDTH + 2.0, 0.54, COLLISION_DEPTH + 2.0),
		null,
		floor_physics_material
	)
	safety_net.collision_layer = 1
	safety_net.collision_mask = 1

	var mat_mesh := MeshInstance3D.new()
	mat_mesh.name = "FixedThrowMat"
	var mat_box := BoxMesh.new()
	mat_box.size = Vector3(VISIBLE_MAT_WIDTH, 0.035, VISIBLE_MAT_DEPTH)
	mat_mesh.mesh = mat_box
	mat_mesh.position = Vector3(0.0, 0.002, 0.0)
	mat_mesh.material_override = _make_material(Color(0.30, 0.29, 0.39, 1.0), 0.78, 0.0)
	dice_world.add_child(mat_mesh)

	var bounds := Node3D.new()
	bounds.name = "Bounds"
	dice_world.add_child(bounds)
	var half_w := COLLISION_WIDTH * 0.5
	var half_d := COLLISION_DEPTH * 0.5
	var wall_y := WALL_HEIGHT * 0.5
	var horizontal_wall_width := COLLISION_WIDTH + WALL_THICKNESS * 2.0
	var vertical_wall_depth := COLLISION_DEPTH + WALL_THICKNESS * 2.0
	_add_static_box(bounds, "BackBound", Vector3(0.0, wall_y, -half_d - WALL_THICKNESS * 0.5), Vector3(horizontal_wall_width, WALL_HEIGHT, WALL_THICKNESS), null, wall_physics_material)
	_add_static_box(bounds, "FrontBound", Vector3(0.0, wall_y, half_d + WALL_THICKNESS * 0.5), Vector3(horizontal_wall_width, WALL_HEIGHT, WALL_THICKNESS), null, wall_physics_material)
	_add_static_box(bounds, "LeftBound", Vector3(-half_w - WALL_THICKNESS * 0.5, wall_y, 0.0), Vector3(WALL_THICKNESS, WALL_HEIGHT, vertical_wall_depth), null, wall_physics_material)
	_add_static_box(bounds, "RightBound", Vector3(half_w + WALL_THICKNESS * 0.5, wall_y, 0.0), Vector3(WALL_THICKNESS, WALL_HEIGHT, vertical_wall_depth), null, wall_physics_material)

	var guard_y := WALL_HEIGHT * 0.5
	var guard_width := COLLISION_WIDTH + (WALL_THICKNESS + GUARD_WALL_THICKNESS) * 2.0
	var guard_depth := COLLISION_DEPTH + (WALL_THICKNESS + GUARD_WALL_THICKNESS) * 2.0
	_add_static_box(bounds, "BackGuardBound", Vector3(0.0, guard_y, -half_d - WALL_THICKNESS - GUARD_WALL_THICKNESS * 0.5), Vector3(guard_width, WALL_HEIGHT, GUARD_WALL_THICKNESS), null, wall_physics_material)
	_add_static_box(bounds, "FrontGuardBound", Vector3(0.0, guard_y, half_d + WALL_THICKNESS + GUARD_WALL_THICKNESS * 0.5), Vector3(guard_width, WALL_HEIGHT, GUARD_WALL_THICKNESS), null, wall_physics_material)
	_add_static_box(bounds, "LeftGuardBound", Vector3(-half_w - WALL_THICKNESS - GUARD_WALL_THICKNESS * 0.5, guard_y, 0.0), Vector3(GUARD_WALL_THICKNESS, WALL_HEIGHT, guard_depth), null, wall_physics_material)
	_add_static_box(bounds, "RightGuardBound", Vector3(half_w + WALL_THICKNESS + GUARD_WALL_THICKNESS * 0.5, guard_y, 0.0), Vector3(GUARD_WALL_THICKNESS, WALL_HEIGHT, guard_depth), null, wall_physics_material)
	_add_static_box(bounds, "CeilingBound", Vector3(0.0, WALL_HEIGHT + CEILING_THICKNESS * 0.5, 0.0), Vector3(guard_width, CEILING_THICKNESS, guard_depth), null, wall_physics_material)


func _build_anchors() -> void:
	dice_box_anchors = Node3D.new()
	dice_box_anchors.name = "DiceBoxAnchors"
	dice_world.add_child(dice_box_anchors)

	spawn_point = Marker3D.new()
	spawn_point.name = "SpawnPoint"
	spawn_point.position = Vector3(0.0, 0.82, 0.05)
	dice_box_anchors.add_child(spawn_point)

	for row in [
		["FlyPoint", Vector3(0.0, 1.15, 3.05)],
		["ShowPoint", Vector3(0.00, ready_row_height, 0.08)],
		["ShopDicePoint", Vector3(2.45, 0.70, -0.85)],
		["BossDicePoint", Vector3(2.45, 0.70, 0.85)],
		["DiceCallPoint", Vector3(-2.60, 0.85, 0.95)],
		["JudgeDiceAnchor", Vector3(0.0, 0.75, 0.0)],
	]:
		var marker := Marker3D.new()
		marker.name = str(row[0])
		marker.position = row[1]
		dice_box_anchors.add_child(marker)

	dice_container = Node3D.new()
	dice_container.name = "DiceContainer"
	dice_world.add_child(dice_container)

	var card_container := Node3D.new()
	card_container.name = "CardContainer"
	dice_world.add_child(card_container)


func _build_camera() -> void:
	fixed_camera = Camera3D.new()
	fixed_camera.name = "FixedCamera"
	fixed_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	fixed_camera.near = 0.05
	fixed_camera.far = 80.0
	fixed_camera.current = true
	dice_world.add_child(fixed_camera)
	_apply_camera_settings()


func _apply_camera_settings() -> void:
	if fixed_camera == null:
		return
	fixed_camera.fov = camera_fov
	fixed_camera.position = camera_position
	fixed_camera.look_at(camera_look_at, Vector3.UP)


func _camera_pitch_degrees() -> float:
	var direction := camera_look_at - camera_position
	var flat_distance := Vector2(direction.x, direction.z).length()
	return rad_to_deg(atan2(direction.y, flat_distance))


func _add_static_box(parent: Node, node_name: String, position: Vector3, size: Vector3, material: Material, physics_material: PhysicsMaterial = null) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.physics_material_override = physics_material
	body.collision_layer = 1
	body.collision_mask = 1
	parent.add_child(body)

	var shape := BoxShape3D.new()
	shape.size = size
	shape.margin = 0.035
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)

	if material != null:
		var mesh := BoxMesh.new()
		mesh.size = size
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		mesh_instance.mesh = mesh
		mesh_instance.material_override = material
		body.add_child(mesh_instance)
	return body


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
