extends SubViewportContainer
class_name GmDiceViewport


signal dice_clicked(dice)


const VIEWPORT_SIZE := Vector2i(1280, 720)
const VISIBLE_MAT_WIDTH := 16.8
const VISIBLE_MAT_DEPTH := 11.0
const COLLISION_WIDTH := 14.2
const COLLISION_DEPTH := 8.2
const FLOOR_THICKNESS := 0.56
const WALL_HEIGHT := 6.4
const WALL_THICKNESS := 1.85
const GUARD_WALL_THICKNESS := 2.25
const DEFAULT_CAMERA_FOV := 38.0
const DEFAULT_CAMERA_POSITION := Vector3(0.0, 18.5, 1.0)
const DEFAULT_CAMERA_LOOK_AT := Vector3(0.0, 0.72, -0.04)
const DEFAULT_READY_ROW_HEIGHT := 7.5
const DEFAULT_KEY_LIGHT_ROTATION := Vector3(-63.0, 115.0, 0.0)
const PROJECTED_DICE_PICK_RADIUS := 84.0
const VISUAL_REPRO_STAGE_SCENE_PATH := "res://assets/models/stage/star_astrology_disc.tscn"
const VISUAL_REPRO_ENVIRONMENT_PATH := "res://assets/environments/gm_dice_visual_repro_environment.tres"
const MULTI_DIFFUSE_LIGHT_SPECS := [
	{
		"name": "WarmFrontDiffuseLight",
		"position": Vector3(-5.8, 6.6, 5.4),
		"color": Color(1.00, 0.68, 0.42),
		"energy": 1.44,
		"range": 15.0,
	},
	{
		"name": "CoolBackDiffuseLight",
		"position": Vector3(5.4, 6.2, -5.2),
		"color": Color(0.48, 0.70, 1.00),
		"energy": 1.34,
		"range": 15.0,
	},
	{
		"name": "GreenSideDiffuseLight",
		"position": Vector3(-6.4, 5.4, -0.6),
		"color": Color(0.40, 1.00, 0.72),
		"energy": 1.08,
		"range": 13.5,
	},
	{
		"name": "VioletLowDiffuseLight",
		"position": Vector3(4.8, 4.6, 3.8),
		"color": Color(0.88, 0.56, 1.00),
		"energy": 0.96,
		"range": 12.5,
	},
]
const METAL_REFLECTION_LIGHT_SPECS := [
	{
		"name": "WarmMetalReflectionLight",
		"position": Vector3(-3.4, 4.8, 4.6),
		"color": Color(1.00, 0.76, 0.46),
		"energy": 0.72,
		"range": 10.5,
		"specular": 0.42,
	},
	{
		"name": "CoolMetalReflectionLight",
		"position": Vector3(3.8, 4.2, -4.4),
		"color": Color(0.58, 0.72, 1.00),
		"energy": 0.58,
		"range": 10.0,
		"specular": 0.34,
	},
]
const VISUAL_LIGHT_ROLE_SPECS := [
	{
		"role": "soft_key_top",
		"name": "SoftTopKeyLight",
		"position": Vector3(0.0, 8.4, 1.6),
		"color": Color(1.00, 0.90, 0.72),
		"energy": 0.94,
		"range": 16.0,
		"specular": 0.18,
		"attenuation": 0.62,
	},
	{
		"role": "cool_table_bounce",
		"name": "CoolTableBounceLight",
		"position": Vector3(-2.8, 1.35, 1.8),
		"color": Color(0.26, 0.52, 1.00),
		"energy": 0.74,
		"range": 12.0,
		"specular": 0.08,
		"attenuation": 0.72,
	},
	{
		"role": "warm_gold_edge_kicker",
		"name": "WarmGoldEdgeKickerLight",
		"position": Vector3(4.8, 3.1, 3.5),
		"color": Color(1.00, 0.66, 0.28),
		"energy": 0.78,
		"range": 10.2,
		"specular": 0.42,
		"attenuation": 0.68,
	},
	{
		"role": "local_glint_highlight",
		"name": "LocalGlintHighlightLight",
		"position": Vector3(-1.3, 2.4, 2.2),
		"color": Color(0.84, 0.96, 1.00),
		"energy": 0.46,
		"range": 5.4,
		"specular": 0.56,
		"attenuation": 0.56,
	},
	{
		"role": "reflection_reference",
		"name": "ReflectionReferenceLight",
		"position": Vector3(2.2, 4.4, -3.0),
		"color": Color(0.92, 0.98, 1.00),
		"energy": 0.34,
		"range": 9.4,
		"specular": 0.62,
		"attenuation": 0.60,
	},
]


var sub_viewport: SubViewport = null
var dice_world: Node3D = null
var world_environment: WorldEnvironment = null
var reflection_probe: Node3D = null
var fixed_camera: Camera3D = null
var key_light: DirectionalLight3D = null
var multi_diffuse_lights: Array[OmniLight3D] = []
var metal_reflection_lights: Array[OmniLight3D] = []
var visual_role_lights: Array[OmniLight3D] = []
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
	mouse_filter = Control.MOUSE_FILTER_STOP

	sub_viewport = SubViewport.new()
	sub_viewport.name = "SubViewport"
	sub_viewport.size = VIEWPORT_SIZE
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.transparent_bg = false
	sub_viewport.physics_object_picking = true
	add_child(sub_viewport)

	dice_world = Node3D.new()
	dice_world.name = "DiceWorld"
	sub_viewport.add_child(dice_world)

	_build_environment()
	_build_collision_stage()
	_build_anchors()
	_build_camera()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var dice := pick_dice_at_local_position(mouse_event.position)
			if dice != null:
				dice_clicked.emit(dice)
				accept_event()


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


func set_throw_surface_texture(texture: Texture2D, tint: Color = Color.WHITE, visible_when_empty: bool = true) -> void:
	var throw_mat_node := _fixed_throw_mat_node()
	var throw_mat := _fixed_throw_mat()
	if throw_mat_node == null and throw_mat == null:
		return
	if texture == null:
		if throw_mat != null:
			_restore_default_throw_surface_mesh(throw_mat)
			throw_mat.material_override = _make_material(Color(0.30, 0.29, 0.39, 1.0), 0.78, 0.0)
		if throw_mat_node != null:
			throw_mat_node.visible = visible_when_empty
		return
	if throw_mat == null:
		return
	_apply_texture_throw_surface_mesh(throw_mat, texture)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.roughness = 0.72
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	throw_mat.material_override = material
	if throw_mat_node != null:
		throw_mat_node.visible = true


func get_throw_surface_texture_path() -> String:
	var throw_mat := _fixed_throw_mat()
	if throw_mat == null:
		return ""
	var material := throw_mat.material_override as StandardMaterial3D
	if material == null or material.albedo_texture == null:
		return ""
	return material.albedo_texture.resource_path


func get_throw_surface_normalized_rect(fit_collision_area: bool = true) -> Rect2:
	if fixed_camera == null or sub_viewport == null:
		return Rect2(0.0, 0.0, 1.0, 1.0)
	var width := COLLISION_WIDTH if fit_collision_area else VISIBLE_MAT_WIDTH
	var depth := COLLISION_DEPTH if fit_collision_area else VISIBLE_MAT_DEPTH
	var corners := [
		Vector3(-width * 0.5, 0.0, -depth * 0.5),
		Vector3(width * 0.5, 0.0, -depth * 0.5),
		Vector3(width * 0.5, 0.0, depth * 0.5),
		Vector3(-width * 0.5, 0.0, depth * 0.5),
	]
	var min_point := Vector2(INF, INF)
	var max_point := Vector2(-INF, -INF)
	for corner in corners:
		var projected := fixed_camera.unproject_position(corner)
		min_point.x = minf(min_point.x, projected.x)
		min_point.y = minf(min_point.y, projected.y)
		max_point.x = maxf(max_point.x, projected.x)
		max_point.y = maxf(max_point.y, projected.y)
	var viewport_size := Vector2(sub_viewport.size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Rect2(0.0, 0.0, 1.0, 1.0)
	var normalized_position := Vector2(
		clampf(min_point.x / viewport_size.x, 0.0, 1.0),
		clampf(min_point.y / viewport_size.y, 0.0, 1.0)
	)
	var normalized_end := Vector2(
		clampf(max_point.x / viewport_size.x, 0.0, 1.0),
		clampf(max_point.y / viewport_size.y, 0.0, 1.0)
	)
	return Rect2(normalized_position, normalized_end - normalized_position)


func _fixed_throw_mat() -> MeshInstance3D:
	if dice_world == null:
		return null
	return dice_world.get_node_or_null("FixedThrowMat") as MeshInstance3D


func _fixed_throw_mat_node() -> Node3D:
	if dice_world == null:
		return null
	return dice_world.get_node_or_null("FixedThrowMat") as Node3D


func _apply_texture_throw_surface_mesh(throw_mat: MeshInstance3D, texture: Texture2D) -> void:
	var texture_size := texture.get_size()
	var aspect := 16.0 / 9.0
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		aspect = texture_size.x / texture_size.y
	var plane := PlaneMesh.new()
	plane.size = Vector2(VISIBLE_MAT_WIDTH, VISIBLE_MAT_WIDTH / aspect)
	throw_mat.mesh = plane
	throw_mat.position = Vector3(0.0, 0.006, 0.0)


func _restore_default_throw_surface_mesh(throw_mat: MeshInstance3D) -> void:
	var mat_box := BoxMesh.new()
	mat_box.size = Vector3(VISIBLE_MAT_WIDTH, 0.035, VISIBLE_MAT_DEPTH)
	throw_mat.mesh = mat_box
	throw_mat.position = Vector3(0.0, 0.002, 0.0)


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
		"multi_diffuse_lights": _get_multi_diffuse_light_state(),
		"metal_reflection_lights": _get_metal_reflection_light_state(),
		"visual_light_roles": _get_visual_light_role_state(),
		"rendering_features": _get_rendering_feature_state(),
		"visible_stage_size": Vector2(VISIBLE_MAT_WIDTH, VISIBLE_MAT_DEPTH),
		"collision_stage_size": Vector2(COLLISION_WIDTH, COLLISION_DEPTH),
		"throw_surface_texture_path": get_throw_surface_texture_path(),
	}


func pick_dice_at_local_position(local_position: Vector2) -> Node:
	if sub_viewport == null or fixed_camera == null:
		return null
	var projected_dice := _find_nearest_projected_dice(local_position)
	if projected_dice != null:
		return projected_dice
	if sub_viewport.world_3d == null:
		return null
	var viewport_position := container_to_viewport_position(local_position)
	if viewport_position.x < 0.0 or viewport_position.y < 0.0:
		return null
	if viewport_position.x > float(sub_viewport.size.x) or viewport_position.y > float(sub_viewport.size.y):
		return null
	var ray_origin := fixed_camera.project_ray_origin(viewport_position)
	var ray_end := ray_origin + fixed_camera.project_ray_normal(viewport_position) * 120.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.collision_mask = 0xFFFFFFFF
	var hit := sub_viewport.world_3d.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return _find_dice_from_collider(hit.get("collider"))


func get_dice_local_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	if dice_container == null or fixed_camera == null:
		return points
	for child in dice_container.get_children():
		var node_3d := child as Node3D
		if node_3d == null:
			continue
		points.append(viewport_to_container_position(fixed_camera.unproject_position(node_3d.global_position)))
	return points


func container_to_viewport_position(local_position: Vector2) -> Vector2:
	if sub_viewport == null or size.x <= 0.0 or size.y <= 0.0:
		return local_position
	return Vector2(
		local_position.x * float(sub_viewport.size.x) / size.x,
		local_position.y * float(sub_viewport.size.y) / size.y
	)


func viewport_to_container_position(viewport_position: Vector2) -> Vector2:
	if sub_viewport == null or sub_viewport.size.x <= 0 or sub_viewport.size.y <= 0:
		return viewport_position
	return Vector2(
		viewport_position.x * size.x / float(sub_viewport.size.x),
		viewport_position.y * size.y / float(sub_viewport.size.y)
	)


func screen_entry_to_world_position(screen_x: float, screen_y: float, spawn_y: float, reference_y := -1.0) -> Vector3:
	var resolved_reference_y := ready_row_height if reference_y < 0.0 else reference_y
	var base_position := screen_point_to_world_on_y(screen_x, screen_y, resolved_reference_y)
	return Vector3(base_position.x, spawn_y, base_position.z)


func screen_point_to_world_on_y(screen_x: float, screen_y: float, plane_y: float) -> Vector3:
	if fixed_camera == null or sub_viewport == null:
		return Vector3(0.0, plane_y, 0.0)
	var viewport_position := Vector2(
		clampf(screen_x, 0.0, 1.0) * float(sub_viewport.size.x),
		clampf(screen_y, 0.0, 1.0) * float(sub_viewport.size.y)
	)
	var ray_origin := fixed_camera.project_ray_origin(viewport_position)
	var ray_normal := fixed_camera.project_ray_normal(viewport_position)
	if absf(ray_normal.y) <= 0.0001:
		return Vector3(0.0, plane_y, 0.0)
	var distance := (plane_y - ray_origin.y) / ray_normal.y
	if distance < 0.0:
		return Vector3(0.0, plane_y, 0.0)
	return ray_origin + ray_normal * distance


func _build_environment() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var env := _make_visual_environment()
	world_environment.environment = env
	dice_world.add_child(world_environment)
	_build_reflection_probe()

	key_light = DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.rotation_degrees = key_light_rotation
	key_light.light_energy = 1.58
	key_light.light_specular = 0.48
	key_light.shadow_enabled = true
	dice_world.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "FillLight"
	fill_light.position = Vector3(-2.6, 3.0, 2.8)
	fill_light.light_color = Color(0.62, 0.86, 1.0)
	fill_light.light_energy = 0.88
	fill_light.light_specular = 0.28
	fill_light.omni_range = 9.0
	dice_world.add_child(fill_light)

	var rim_light := OmniLight3D.new()
	rim_light.name = "RimLight"
	rim_light.position = Vector3(3.2, 2.2, -2.7)
	rim_light.light_color = Color(0.00, 0.94, 0.72)
	rim_light.light_energy = 1.28
	rim_light.light_specular = 0.32
	rim_light.omni_range = 8.0
	dice_world.add_child(rim_light)

	_build_multi_diffuse_lights()
	_build_metal_reflection_lights()
	_build_visual_role_lights()


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

	_add_visual_throw_mat()

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


func _build_multi_diffuse_lights() -> void:
	multi_diffuse_lights.clear()
	for spec in MULTI_DIFFUSE_LIGHT_SPECS:
		var light := OmniLight3D.new()
		light.name = str(spec["name"])
		light.position = spec["position"]
		light.light_color = spec["color"]
		light.light_energy = float(spec["energy"])
		light.light_specular = 0.12
		light.omni_range = float(spec["range"])
		light.omni_attenuation = 0.75
		light.shadow_enabled = false
		dice_world.add_child(light)
		multi_diffuse_lights.append(light)


func _build_metal_reflection_lights() -> void:
	metal_reflection_lights.clear()
	for spec in METAL_REFLECTION_LIGHT_SPECS:
		var light := OmniLight3D.new()
		light.name = str(spec["name"])
		light.position = spec["position"]
		light.light_color = spec["color"]
		light.light_energy = float(spec["energy"])
		light.light_specular = float(spec["specular"])
		light.omni_range = float(spec["range"])
		light.omni_attenuation = 0.68
		light.shadow_enabled = false
		dice_world.add_child(light)
		metal_reflection_lights.append(light)


func _build_visual_role_lights() -> void:
	visual_role_lights.clear()
	for spec in VISUAL_LIGHT_ROLE_SPECS:
		var light := OmniLight3D.new()
		light.name = str(spec["name"])
		light.position = spec["position"]
		light.light_color = spec["color"]
		light.light_energy = float(spec["energy"])
		light.light_specular = float(spec["specular"])
		light.omni_range = float(spec["range"])
		light.omni_attenuation = float(spec["attenuation"])
		light.shadow_enabled = false
		light.set_meta("visual_light_role", str(spec["role"]))
		dice_world.add_child(light)
		visual_role_lights.append(light)


func _build_reflection_probe() -> void:
	reflection_probe = null
	if not ClassDB.class_exists("ReflectionProbe"):
		return
	var probe := ClassDB.instantiate("ReflectionProbe") as Node3D
	if probe == null:
		return
	probe.name = "GlossReflectionProbe"
	probe.position = Vector3(0.0, 2.20, 0.10)
	_set_existing(probe, ["size"], Vector3(10.5, 5.2, 8.5))
	_set_existing(probe, ["origin_offset"], Vector3(0.0, 0.18, 0.0))
	_set_existing(probe, ["intensity"], 0.68)
	_set_existing(probe, ["max_distance"], 14.0)
	_set_existing(probe, ["box_projection"], true)
	_set_existing(probe, ["enable_shadows"], false)
	dice_world.add_child(probe)
	reflection_probe = probe


func _get_multi_diffuse_light_state() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for light in multi_diffuse_lights:
		if light == null:
			continue
		rows.append({
			"name": light.name,
			"position": light.position,
			"color": light.light_color,
			"energy": light.light_energy,
			"range": light.omni_range,
			"specular": light.light_specular,
		})
	return rows


func _get_metal_reflection_light_state() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for light in metal_reflection_lights:
		if light == null:
			continue
		rows.append({
			"name": light.name,
			"position": light.position,
			"color": light.light_color,
			"energy": light.light_energy,
			"range": light.omni_range,
			"specular": light.light_specular,
		})
	return rows


func _get_visual_light_role_state() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for light in visual_role_lights:
		if light == null:
			continue
		rows.append({
			"role": str(light.get_meta("visual_light_role", "")),
			"name": light.name,
			"position": light.position,
			"color": light.light_color,
			"energy": light.light_energy,
			"range": light.omni_range,
			"specular": light.light_specular,
			"attenuation": light.omni_attenuation,
		})
	return rows


func _get_rendering_feature_state() -> Dictionary:
	var env := world_environment.environment if world_environment != null else null
	return {
		"renderer": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")),
		"world_environment": world_environment != null and env != null,
		"reflection_probe": reflection_probe != null,
		"reflection_probe_name": reflection_probe.name if reflection_probe != null else "",
		"glow_enabled": _object_bool(env, "glow_enabled"),
		"ssao_enabled": _object_bool(env, "ssao_enabled"),
		"tonemap_mode": int(_object_value(env, "tonemap_mode", -1)),
		"ambient_light_energy": env.ambient_light_energy if env != null else 0.0,
		"contact_shadow_fallback": true,
		"transparent_marker_layers": true,
	}


func _camera_pitch_degrees() -> float:
	var direction := camera_look_at - camera_position
	var flat_distance := Vector2(direction.x, direction.z).length()
	return rad_to_deg(atan2(direction.y, flat_distance))


func _find_dice_from_collider(collider) -> Node:
	var node := collider as Node
	while node != null:
		if node.get_parent() == dice_container:
			return node
		if node == dice_world:
			return null
		node = node.get_parent()
	return null


func _find_nearest_projected_dice(local_position: Vector2) -> Node:
	if dice_container == null or fixed_camera == null:
		return null
	var radius_scale := maxf(size.x / float(VIEWPORT_SIZE.x), size.y / float(VIEWPORT_SIZE.y))
	var max_distance_sq := pow(PROJECTED_DICE_PICK_RADIUS * maxf(0.1, radius_scale), 2.0)
	var best_distance_sq := max_distance_sq
	var best_dice: Node = null
	for child in dice_container.get_children():
		var dice := child as Node3D
		if dice == null:
			continue
		var projected := viewport_to_container_position(fixed_camera.unproject_position(dice.global_position))
		var distance_sq := projected.distance_squared_to(local_position)
		if distance_sq <= best_distance_sq:
			best_distance_sq = distance_sq
			best_dice = dice
	return best_dice


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


func _make_visual_environment() -> Environment:
	var env: Environment = null
	if ResourceLoader.exists(VISUAL_REPRO_ENVIRONMENT_PATH):
		env = load(VISUAL_REPRO_ENVIRONMENT_PATH) as Environment
	if env != null:
		env = env.duplicate(true) as Environment
	else:
		env = Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.034, 0.060, 0.145)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.30, 0.38, 0.62)
	env.background_color = Color(0.034, 0.060, 0.145)
	env.ambient_light_color = Color(0.30, 0.38, 0.62)
	env.ambient_light_energy = 0.42
	env.ambient_light_sky_contribution = 0.16
	_set_existing(env, ["tonemap_mode"], 3)
	_set_existing(env, ["tonemap_exposure"], 1.00)
	_set_existing(env, ["tonemap_white"], 1.70)
	_set_existing(env, ["glow_enabled"], true)
	_set_existing(env, ["glow_intensity"], 0.40)
	_set_existing(env, ["glow_strength"], 0.72)
	_set_existing(env, ["glow_bloom"], 0.10)
	_set_existing(env, ["glow_hdr_threshold"], 0.82)
	_set_existing(env, ["ssao_enabled"], true)
	_set_existing(env, ["ssao_radius"], 1.35)
	_set_existing(env, ["ssao_intensity"], 0.62)
	return env


func _add_visual_throw_mat() -> void:
	if ResourceLoader.exists(VISUAL_REPRO_STAGE_SCENE_PATH):
		var stage_scene := load(VISUAL_REPRO_STAGE_SCENE_PATH) as PackedScene
		if stage_scene != null:
			var stage := stage_scene.instantiate() as Node3D
			if stage != null:
				stage.name = "FixedThrowMat"
				stage.position = Vector3(0.0, 0.002, 0.0)
				stage.rotation_degrees = Vector3.ZERO
				stage.scale = Vector3.ONE * 1.32
				dice_world.add_child(stage)
				return
	var material := _make_material(Color(0.025, 0.050, 0.110, 1.0), 0.38, 0.02)
	material.emission_enabled = true
	material.emission = Color(0.035, 0.095, 0.180)
	material.emission_energy_multiplier = 0.10
	_add_static_box(
		dice_world,
		"FixedThrowMat",
		Vector3(0.0, 0.0, 0.0),
		Vector3(VISIBLE_MAT_WIDTH, 0.045, VISIBLE_MAT_DEPTH),
		material
	)


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _set_existing(object: Object, names: Array, value) -> bool:
	var properties := {}
	for item in object.get_property_list():
		properties[item["name"]] = true
	for name in names:
		if properties.has(name):
			object.set(name, value)
			return true
	return false


func _object_bool(object: Object, property_name: String) -> bool:
	if object == null:
		return false
	for item in object.get_property_list():
		if str(item.get("name", "")) == property_name:
			return bool(object.get(property_name))
	return false


func _object_value(object: Object, property_name: String, fallback):
	if object == null:
		return fallback
	for item in object.get_property_list():
		if str(item.get("name", "")) == property_name:
			return object.get(property_name)
	return fallback
