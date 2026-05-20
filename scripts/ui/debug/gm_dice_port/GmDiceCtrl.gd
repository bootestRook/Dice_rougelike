extends RigidBody3D
class_name GmDiceCtrl


signal roll_started(dice)
signal roll_stopped(dice, face_index: int, face_value: int)


const FACE_ROTATIONS_DEG := [
	Vector3(0.0, 0.0, 0.0),
	Vector3(90.0, 0.0, 0.0),
	Vector3(0.0, 0.0, 90.0),
	Vector3(0.0, 0.0, -90.0),
	Vector3(270.0, 0.0, 0.0),
	Vector3(180.0, 0.0, 0.0),
]
const UNITY_VECTOR3_EQUAL_EPS_SQ := 1.0e-10
const STOP_LINEAR_SPEED := 0.10
const STOP_ANGULAR_SPEED := 0.16
const GODOT_STOP_STABLE_FRAMES := 28
const VELOCITY_SCALE := 0.1
const TORQUE_SCALE := 0.5
const MAX_ANGULAR_SPEED := 1000.0
const DIE_SIZE := 0.72
const DIE_HALF := DIE_SIZE * 0.5
const SHADOW_Y := 0.028
const DEFAULT_THROW_TUNING := {
	"forward_speed": 10.0,
	"lateral_speed": 5.0,
	"upward_speed": 3.2,
	"angular_speed": 28.0,
	"torque_impulse": 24.0,
}


@export var inner_dice: Node3D = null
@export var number_label: Label3D = null
@export var select_area: Area3D = null

var config: GmDiceInstance = null
var is_rolling := false
var stable_frames := 0
var roll_multiplier := 1.0
var throw_tuning := DEFAULT_THROW_TUNING.duplicate(true)

var _rng := RandomNumberGenerator.new()
var _body_mesh: MeshInstance3D = null
var _hover_shadow: MeshInstance3D = null
var _shadow_material: StandardMaterial3D = null
var _face_labels: Array[Label3D] = []


func _ready() -> void:
	if inner_dice == null:
		build_visuals(Color(0.94, 0.96, 0.98), Color(0.12, 0.14, 0.18))
	_rng.randomize()
	_update_hover_shadow()


func _physics_process(_delta: float) -> void:
	_update_hover_shadow()


func build_visuals(body_color: Color, mark_color: Color) -> void:
	freeze = true
	mass = 1.0
	linear_damp = 0.085
	angular_damp = 0.11
	contact_monitor = true
	max_contacts_reported = 8
	continuous_cd = true
	var body_physics_material := PhysicsMaterial.new()
	body_physics_material.friction = 0.42
	body_physics_material.bounce = 0.20
	physics_material_override = body_physics_material

	if get_node_or_null("CollisionShape3D") == null:
		var shape := BoxShape3D.new()
		shape.size = Vector3.ONE * (DIE_SIZE * 1.04)
		shape.margin = 0.035
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		collision.shape = shape
		add_child(collision)

	inner_dice = Node3D.new()
	inner_dice.name = "InnerDice"
	add_child(inner_dice)

	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = body_color
	body_material.roughness = 0.52
	body_material.metallic = 0.02
	body_material.emission_enabled = true
	body_material.emission = body_color.darkened(0.35)
	body_material.emission_energy_multiplier = 0.18

	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * DIE_SIZE
	_body_mesh = MeshInstance3D.new()
	_body_mesh.name = "DiceMesh"
	_body_mesh.mesh = mesh
	_body_mesh.material_override = body_material
	_body_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	inner_dice.add_child(_body_mesh)

	var face_visuals := Node3D.new()
	face_visuals.name = "FaceVisuals"
	inner_dice.add_child(face_visuals)
	_create_face_labels(face_visuals, mark_color)

	var fx_anchors := Node3D.new()
	fx_anchors.name = "FxAnchors"
	add_child(fx_anchors)
	for anchor_name in ["Center", "Face", "Vertex", "InnerCenter"]:
		var marker := Marker3D.new()
		marker.name = anchor_name
		fx_anchors.add_child(marker)
	fx_anchors.get_node("Face").position = Vector3(0.0, DIE_HALF, 0.0)
	fx_anchors.get_node("Vertex").position = Vector3(DIE_HALF, DIE_HALF, DIE_HALF)

	select_area = Area3D.new()
	select_area.name = "SelectArea"
	var area_shape := CollisionShape3D.new()
	area_shape.name = "SelectShape"
	var sphere := SphereShape3D.new()
	sphere.radius = DIE_SIZE * 0.72
	area_shape.shape = sphere
	select_area.add_child(area_shape)
	add_child(select_area)

	number_label = Label3D.new()
	number_label.name = "NumberLabel"
	number_label.text = ""
	number_label.visible = false
	number_label.position = Vector3(0.0, DIE_SIZE * 0.92, 0.0)
	number_label.font_size = 64
	number_label.pixel_size = 0.012
	number_label.modulate = Color(1.0, 0.98, 0.82)
	number_label.outline_size = 12
	number_label.outline_modulate = Color(0.03, 0.03, 0.04)
	add_child(number_label)
	_build_hover_shadow()


func init_dice(instance: GmDiceInstance, skip_init_app := false) -> void:
	config = instance
	if config != null:
		config.avatar = self
		config.set_face_index(config.value)
	_update_face_labels()
	change_inner_by_value(0.0)
	show_number(not skip_init_app)
	_update_hover_shadow()


func set_throw_tuning(config_values: Dictionary) -> void:
	for key in throw_tuning.keys():
		if config_values.has(key):
			throw_tuning[key] = maxf(0.0, float(config_values[key]))


func get_throw_tuning() -> Dictionary:
	return throw_tuning.duplicate(true)


func roll(requested_face = -1, need_broadcast := true) -> void:
	if config == null:
		return
	_prepare_roll_body()
	random_face(requested_face, 0.15)
	_apply_throw_motion(need_broadcast)


func roll_face_index(face_index: int, need_broadcast := true) -> void:
	if config == null:
		return
	_prepare_roll_body()
	config.set_face_index(face_index)
	change_inner_by_value(0.15)
	_apply_throw_motion(need_broadcast)


func random_face(requested_face = -1, tween_time := 0.15) -> void:
	if config == null or config.run_faces.is_empty():
		return
	var face_index := config.resolve_face_request(requested_face)
	if face_index < 0:
		face_index = _rng.randi_range(0, config.run_faces.size() - 1)
	config.set_face_index(face_index)
	change_inner_by_value(tween_time)


func change_inner_by_value(tween_time := 0.15) -> void:
	if inner_dice == null or config == null:
		return
	var target_deg: Vector3 = FACE_ROTATIONS_DEG[clampi(config.value, 0, FACE_ROTATIONS_DEG.size() - 1)]
	var target_rad := Vector3(
		deg_to_rad(target_deg.x),
		deg_to_rad(target_deg.y),
		deg_to_rad(target_deg.z)
	)
	if tween_time <= 0.0 or not is_inside_tree():
		inner_dice.rotation = target_rad
		return
	var tween := create_tween()
	tween.tween_property(inner_dice, "rotation", target_rad, tween_time)


func check_roll_stop() -> bool:
	var stopped := (
		linear_velocity.length() <= STOP_LINEAR_SPEED
		and angular_velocity.length() <= STOP_ANGULAR_SPEED
	)
	if stopped:
		stable_frames += 1
	else:
		stable_frames = 0
	return stable_frames >= GODOT_STOP_STABLE_FRAMES


func after_roll(need_broadcast := true) -> void:
	if config == null:
		return
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	is_rolling = false
	show_number(true)
	if need_broadcast:
		roll_stopped.emit(self, config.value, config.get_actual_face_one())


func set_ready_hover(hover_position: Vector3, yaw_degrees := 0.0) -> void:
	global_position = hover_position
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	is_rolling = false
	stable_frames = 0
	rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	apply_hover_presentation_rotation()
	show_number(true)
	_update_hover_shadow()


func apply_hover_presentation_rotation() -> void:
	if inner_dice == null or config == null:
		return
	inner_dice.basis = _hover_presentation_basis(config.value)


func recover_to_stage(stage_position: Vector3, requested_face = null) -> void:
	if config == null:
		return
	global_position = stage_position
	is_rolling = true
	stable_frames = 0
	freeze = false
	sleeping = false
	random_face(requested_face, 0.0)
	linear_velocity = Vector3(
		_rng.randf_range(-0.55, 0.55),
		0.28,
		_rng.randf_range(-0.55, 0.55)
	)
	angular_velocity = _random_unit_vector() * _rng.randf_range(1.4, 3.2)
	show_number(false)


func show_number(show := true) -> void:
	if number_label == null:
		return
	number_label.visible = false
	number_label.text = ""


func get_debug_snapshot() -> Dictionary:
	return {
		"face_index": config.value if config != null else -1,
		"face_value": config.get_actual_face_one() if config != null else 0,
		"rolling": is_rolling,
		"stable_frames": stable_frames,
		"linear_speed": linear_velocity.length(),
		"angular_speed": angular_velocity.length(),
		"position": global_position,
		"rotation_degrees": rotation_degrees,
		"hover_shadow_visible": _hover_shadow != null and _hover_shadow.visible,
		"hover_shadow_position": _hover_shadow.global_position if _hover_shadow != null else Vector3.ZERO,
	}


func _prepare_roll_body() -> void:
	is_rolling = true
	stable_frames = 0
	freeze = false
	sleeping = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	rotation_degrees = Vector3(
		_rng.randi_range(-360, 359),
		_rng.randi_range(-360, 359),
		_rng.randi_range(-360, 359)
	)


func _apply_throw_motion(need_broadcast: bool) -> void:
	var m := maxf(0.1, roll_multiplier)
	var forward_speed := maxf(0.0, float(throw_tuning.get("forward_speed", DEFAULT_THROW_TUNING["forward_speed"]))) * m
	var lateral_speed := maxf(0.0, float(throw_tuning.get("lateral_speed", DEFAULT_THROW_TUNING["lateral_speed"]))) * m
	var upward_speed := maxf(0.0, float(throw_tuning.get("upward_speed", DEFAULT_THROW_TUNING["upward_speed"]))) * m
	var angular_speed := maxf(0.0, float(throw_tuning.get("angular_speed", DEFAULT_THROW_TUNING["angular_speed"]))) * m
	var torque_impulse := maxf(0.0, float(throw_tuning.get("torque_impulse", DEFAULT_THROW_TUNING["torque_impulse"]))) * m
	var forward_dir := Vector3(-global_position.x, 0.0, -global_position.z)
	if forward_dir.length_squared() <= 0.001:
		forward_dir = Vector3(0.0, 0.0, 1.0)
	forward_dir = forward_dir.normalized()
	var lateral_dir := Vector3(forward_dir.z, 0.0, -forward_dir.x).normalized()
	linear_velocity = (
		forward_dir * _rng.randf_range(forward_speed * 0.70, forward_speed * 1.15)
		+ lateral_dir * _rng.randf_range(-lateral_speed, lateral_speed)
		+ Vector3.UP * _rng.randf_range(upward_speed * 0.65, upward_speed * 1.20)
	)
	angular_velocity = _random_unit_vector() * _rng.randf_range(angular_speed * 0.65, angular_speed * 1.25)
	var torque := _random_unit_vector() * _rng.randf_range(torque_impulse * 0.65, torque_impulse * 1.25)
	apply_torque_impulse(torque)
	if angular_velocity.length() > MAX_ANGULAR_SPEED:
		angular_velocity = angular_velocity.limit_length(MAX_ANGULAR_SPEED)
	show_number(false)
	if need_broadcast:
		roll_started.emit(self)


func _random_unit_vector() -> Vector3:
	var vector := Vector3(
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0)
	)
	if vector.length_squared() <= 0.001:
		return Vector3.UP
	return vector.normalized()


func _build_hover_shadow() -> void:
	_shadow_material = StandardMaterial3D.new()
	_shadow_material.albedo_color = Color(0.0, 0.0, 0.0, 0.26)
	_shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow_material.no_depth_test = false

	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = DIE_SIZE * 0.48
	shadow_mesh.bottom_radius = DIE_SIZE * 0.48
	shadow_mesh.height = 0.012
	shadow_mesh.radial_segments = 48

	_hover_shadow = MeshInstance3D.new()
	_hover_shadow.name = "HoverShadow"
	_hover_shadow.mesh = shadow_mesh
	_hover_shadow.material_override = _shadow_material
	_hover_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hover_shadow.top_level = true
	add_child(_hover_shadow)
	_update_hover_shadow()


func _update_hover_shadow() -> void:
	if _hover_shadow == null:
		return
	if not is_inside_tree():
		_hover_shadow.visible = false
		return
	var height := maxf(global_position.y - SHADOW_Y, 0.0)
	var shadow_scale := clampf(0.76 + height * 0.08, 0.76, 0.98)
	var shadow_alpha := clampf(0.24 - height * 0.035, 0.11, 0.22)
	_hover_shadow.visible = config != null
	_hover_shadow.global_position = Vector3(global_position.x, SHADOW_Y, global_position.z)
	_hover_shadow.global_rotation = Vector3.ZERO
	_hover_shadow.scale = Vector3(shadow_scale, 1.0, shadow_scale)
	if _shadow_material != null:
		_shadow_material.albedo_color = Color(0.0, 0.0, 0.0, shadow_alpha)


func _create_face_labels(parent: Node3D, mark_color: Color) -> void:
	_face_labels.clear()
	var face_rows := [
		{"name": "Face1", "position": Vector3(0.0, DIE_HALF + 0.012, 0.0), "rotation": Vector3(-PI * 0.5, 0.0, 0.0)},
		{"name": "Face6", "position": Vector3(0.0, -DIE_HALF - 0.012, 0.0), "rotation": Vector3(PI * 0.5, 0.0, 0.0)},
		{"name": "Face2", "position": Vector3(0.0, 0.0, -DIE_HALF - 0.012), "rotation": Vector3(0.0, PI, 0.0)},
		{"name": "Face5", "position": Vector3(0.0, 0.0, DIE_HALF + 0.012), "rotation": Vector3(0.0, 0.0, 0.0)},
		{"name": "Face3", "position": Vector3(DIE_HALF + 0.012, 0.0, 0.0), "rotation": Vector3(0.0, PI * 0.5, 0.0)},
		{"name": "Face4", "position": Vector3(-DIE_HALF - 0.012, 0.0, 0.0), "rotation": Vector3(0.0, -PI * 0.5, 0.0)},
	]
	for index in range(face_rows.size()):
		var row: Dictionary = face_rows[index]
		var label := Label3D.new()
		label.name = str(row["name"])
		label.text = str(index + 1)
		label.position = row["position"]
		label.rotation = row["rotation"]
		label.font_size = 72
		label.pixel_size = 0.0065
		label.modulate = mark_color
		parent.add_child(label)
		_face_labels.append(label)


func _update_face_labels() -> void:
	for index in range(_face_labels.size()):
		var label := _face_labels[index]
		if config != null and index < config.run_faces.size():
			var face = config.run_faces[index]
			label.text = str(face.label)
		else:
			label.text = str(index + 1)


func _hover_presentation_basis(face_index: int) -> Basis:
	match clampi(face_index, 0, 5):
		0:
			return Basis.IDENTITY
		1:
			return Basis(Vector3.LEFT, Vector3.FORWARD, Vector3.DOWN)
		2:
			return Basis(Vector3.UP, Vector3.FORWARD, Vector3.LEFT)
		3:
			return Basis(Vector3.DOWN, Vector3.FORWARD, Vector3.RIGHT)
		4:
			return Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
		5:
			return Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.FORWARD)
		_:
			return Basis.IDENTITY
