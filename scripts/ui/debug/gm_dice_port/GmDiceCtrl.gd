extends RigidBody3D
class_name GmDiceCtrl


signal roll_started(dice)
signal roll_stopped(dice, face_index: int, face_value: int)
signal ready_return_finished(dice)
signal exit_finished(dice)
signal exit_return_finished(dice)
signal unselected_hold_finished(dice)
signal unselected_hold_return_finished(dice)
signal selection_requested(dice)


const GmDiceMaterialResolver = preload("res://scripts/ui/debug/gm_dice_port/GmDiceMaterialResolver.gd")
const DiceFaceLayerSystem = preload("res://scripts/ui/dice_face_layers/DiceFaceLayerSystem.gd")

const FACE_ROTATIONS_DEG := [
	Vector3(0.0, 0.0, 0.0),
	Vector3(90.0, 0.0, 0.0),
	Vector3(0.0, 0.0, 90.0),
	Vector3(0.0, 0.0, -90.0),
	Vector3(270.0, 0.0, 0.0),
	Vector3(180.0, 0.0, 0.0),
]
const FACE_LOCAL_NORMALS := [
	Vector3.UP,
	Vector3.DOWN,
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.RIGHT,
	Vector3.LEFT,
]
const UNITY_VECTOR3_EQUAL_EPS_SQ := 1.0e-10
const STOP_LINEAR_SPEED := 0.18
const STOP_ANGULAR_SPEED := 0.30
const GODOT_STOP_STABLE_FRAMES := 12
const VELOCITY_SCALE := 0.1
const TORQUE_SCALE := 0.5
const MAX_ANGULAR_SPEED := 1000.0
const DIE_SIZE := 0.72
const DIE_HALF := DIE_SIZE * 0.5
const FACE_TEXTURE_SURFACE_OFFSET := 0.024
const FACE_TEXTURE_SIZE := DIE_SIZE * 0.54
const FACE_TEXTURE_BORDER_THICKNESS := DIE_SIZE * 0.026
const FACE_LABEL_SURFACE_OFFSET := 0.034
const FACE_LABEL_FONT_SIZE := 70
const FACE_LABEL_PIXEL_SIZE := 0.0058
const SHADOW_Y := 0.028
const SELECTION_FRAME_SIZE := DIE_SIZE * 1.18
const SELECTION_FRAME_CORNER_LENGTH := DIE_SIZE * 0.28
const SELECTION_FRAME_THICKNESS := 0.030
const SELECTION_FRAME_Y_OFFSET := 0.07
const DOWNWARD_THROW_TARGET_RADIUS_MIN := 0.75
const DOWNWARD_THROW_TARGET_RADIUS_MAX := 2.15
const DOWNWARD_THROW_TARGET_Y_MIN := -1.20
const DOWNWARD_THROW_TARGET_Y_MAX := -0.05
const READY_RETURN_DURATION := 0.58
const READY_RETURN_ARC_HEIGHT := 0.85
const UNSELECTED_HOLD_DURATION := 0.36
const DEFAULT_THROW_SPEED_TUNING := {
	"linear_speed_min": 8.0,
	"linear_speed_max": 12.0,
}
const DEFAULT_THROW_SPIN_TUNING := {
	"angular_speed_min": 4.0,
	"angular_speed_max": 9.5,
	"torque_min": 2.0,
	"torque_max": 5.0,
}
const DEFAULT_IDLE_DRIFT_TUNING := {
	"min_seconds": 1.15,
	"max_seconds": 2.35,
	"max_distance": 0.07,
	"speed": 0.05,
}
const PIPELINE_DICE_MESH_PATH := "res://assets/models/dice/rounded_d6_mesh.tres"
const REPRO_DICE_SHADER_PATH := "res://assets/shaders/dice/repro_glow_dice.gdshader"
const BRONZE_DICE_MATERIAL_PATH := "res://assets/materials/dice/bronze_dice.tres"
const GOLD_DICE_MATERIAL_PATH := "res://assets/materials/dice/gold_dice.tres"
const CRYSTAL_DICE_MATERIAL_PATH := "res://assets/materials/dice/crystal_dice.tres"
const REPRO_BLUE_DICE_MATERIAL_PATH := "res://assets/materials/dice/repro_blue_dice.tres"
const REPRO_PURPLE_DICE_MATERIAL_PATH := "res://assets/materials/dice/repro_purple_dice.tres"
const REPRO_CYAN_DICE_MATERIAL_PATH := "res://assets/materials/dice/repro_cyan_dice.tres"
const REPRO_GOLD_DICE_MATERIAL_PATH := "res://assets/materials/dice/repro_gold_dice.tres"
const REPRO_SILVERWHITE_DICE_MATERIAL_PATH := "res://assets/materials/dice/repro_silverwhite_dice.tres"


@export var inner_dice: Node3D = null
@export var number_label: Label3D = null
@export var select_area: Area3D = null

var config: GmDiceInstance = null
var is_rolling := false
var is_returning_to_ready := false
var is_returning_from_exit := false
var is_exiting := false
var is_exited := false
var is_moving_to_unselected_hold := false
var is_in_unselected_hold := false
var is_returning_from_unselected_hold := false
var selected := false
var stable_frames := 0
var roll_multiplier := 1.0
var throw_speed_tuning := DEFAULT_THROW_SPEED_TUNING.duplicate(true)
var throw_spin_tuning := DEFAULT_THROW_SPIN_TUNING.duplicate(true)
var idle_drift_tuning := DEFAULT_IDLE_DRIFT_TUNING.duplicate(true)

var _rng := RandomNumberGenerator.new()
var _body_layer: Node3D = null
var _body_mesh: MeshInstance3D = null
var _body_material: Material = null
var _edge_rim_layer: Node3D = null
var _edge_rim_material: StandardMaterial3D = null
var _face_marker_layer: Node3D = null
var _face_texture_layer: Node3D = null
var _state_overlay_layer: Node3D = null
var _contact_shadow_layer: Node3D = null
var _face_layer_system: DiceFaceLayerSystem = null
var _face_albedo_texture: Texture2D = null
var _hover_shadow: MeshInstance3D = null
var _shadow_material: StandardMaterial3D = null
var _selection_frame: Node3D = null
var _selection_material: StandardMaterial3D = null
var _face_labels: Array[Label3D] = []
var _base_body_color := Color(0.94, 0.96, 0.98)
var _mark_color := Color(0.12, 0.14, 0.18)
var _idle_anchor_position := Vector3.ZERO
var _idle_drift_offset := 0.0
var _idle_drift_direction := 1.0
var _idle_drift_elapsed := 0.0
var _idle_drift_duration := 1.0
var _idle_drift_active := false
var _last_throw_origin_position := Vector3.ZERO
var _last_throw_target_position := Vector3.ZERO
var _last_throw_direction := Vector3.DOWN
var _last_throw_velocity := Vector3.ZERO
var _last_settled_face_index := -1
var _last_settled_face_value := 0
var _last_settled_position := Vector3.ZERO
var _last_settled_linear_speed := 0.0
var _last_settled_angular_speed := 0.0
var _last_settled_stable_frames := 0
var _last_ready_return_start_position := Vector3.ZERO
var _last_ready_return_target_position := Vector3.ZERO
var _ready_return_progress := 0.0
var _ready_return_curve_offset := 0.0
var _exit_progress := 0.0
var _last_exit_start_position := Vector3.ZERO
var _last_exit_target_position := Vector3.ZERO
var _exit_return_progress := 0.0
var _last_exit_return_start_position := Vector3.ZERO
var _last_exit_return_target_position := Vector3.ZERO
var _last_exit_return_delay_seconds := 0.0
var _last_unselected_hold_start_position := Vector3.ZERO
var _last_unselected_hold_target_position := Vector3.ZERO
var _last_unselected_hold_return_start_position := Vector3.ZERO
var _last_unselected_hold_return_target_position := Vector3.ZERO
var _unselected_hold_progress := 0.0
var _unselected_hold_return_progress := 0.0
var _unselected_hold_collision_disabled := false
var _unselected_hold_tween: Tween = null
var _stored_collision_layer := 1
var _stored_collision_mask := 1
var _stored_select_area_pickable := true


func _ready() -> void:
	if inner_dice == null:
		build_visuals(Color(0.94, 0.96, 0.98), Color(0.12, 0.14, 0.18))
	_rng.randomize()
	_update_hover_shadow()


func _physics_process(delta: float) -> void:
	_update_idle_drift(delta)
	_update_hover_shadow()
	_update_selection_frame()


func build_visuals(body_color: Color, mark_color: Color) -> void:
	_base_body_color = body_color
	_mark_color = mark_color
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

	_body_layer = Node3D.new()
	_body_layer.name = "BodyMaterialLayer"
	inner_dice.add_child(_body_layer)

	_rebuild_face_layers()
	_body_material = _make_body_material(body_color, GmDiceDefinition.MATERIAL_STANDARD)

	_body_mesh = MeshInstance3D.new()
	_body_mesh.name = "DiceMesh"
	_body_mesh.material_override = _body_material
	_body_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_body_layer.add_child(_body_mesh)

	_apply_body_mesh(GmDiceDefinition.MATERIAL_STANDARD)

	_face_marker_layer = Node3D.new()
	_face_marker_layer.name = "FaceMarkerLayer"
	inner_dice.add_child(_face_marker_layer)
	_create_face_labels(_face_marker_layer, mark_color)

	_state_overlay_layer = Node3D.new()
	_state_overlay_layer.name = "StateOverlayLayer"
	add_child(_state_overlay_layer)

	_contact_shadow_layer = Node3D.new()
	_contact_shadow_layer.name = "ContactShadowLayer"
	add_child(_contact_shadow_layer)

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
	select_area.input_ray_pickable = true
	select_area.collision_layer = 4
	select_area.collision_mask = 0
	var area_shape := CollisionShape3D.new()
	area_shape.name = "SelectShape"
	var sphere := SphereShape3D.new()
	sphere.radius = DIE_SIZE * 0.72
	area_shape.shape = sphere
	select_area.add_child(area_shape)
	select_area.input_event.connect(_on_select_area_input_event)
	add_child(select_area)

	number_label = null
	_build_hover_shadow()
	_build_selection_frame()


func init_dice(instance: GmDiceInstance, skip_init_app := false) -> void:
	config = instance
	if config != null:
		config.avatar = self
		config.set_face_index(config.value)
	visible = true
	_kill_unselected_hold_tween()
	is_returning_from_exit = false
	is_exiting = false
	is_exited = false
	is_moving_to_unselected_hold = false
	is_in_unselected_hold = false
	is_returning_from_unselected_hold = false
	_restore_physics_collision()
	set_selected(false)
	_apply_config_visuals()
	change_inner_by_value(0.0)
	show_number(not skip_init_app)
	_update_hover_shadow()
	_update_selection_frame()


func set_throw_spin_tuning(config_values: Dictionary) -> void:
	var angular_min := clampf(float(config_values.get("angular_speed_min", throw_spin_tuning["angular_speed_min"])), 0.0, 48.0)
	var angular_max := clampf(float(config_values.get("angular_speed_max", throw_spin_tuning["angular_speed_max"])), 0.0, 48.0)
	if angular_max < angular_min:
		angular_max = angular_min
	var torque_min := clampf(float(config_values.get("torque_min", throw_spin_tuning["torque_min"])), 0.0, 32.0)
	var torque_max := clampf(float(config_values.get("torque_max", throw_spin_tuning["torque_max"])), 0.0, 32.0)
	if torque_max < torque_min:
		torque_max = torque_min
	throw_spin_tuning = {
		"angular_speed_min": angular_min,
		"angular_speed_max": angular_max,
		"torque_min": torque_min,
		"torque_max": torque_max,
	}


func set_throw_speed_tuning(config_values: Dictionary) -> void:
	var speed_min := clampf(float(config_values.get("linear_speed_min", throw_speed_tuning["linear_speed_min"])), 0.0, 24.0)
	var speed_max := clampf(float(config_values.get("linear_speed_max", throw_speed_tuning["linear_speed_max"])), 0.0, 24.0)
	if speed_max < speed_min:
		speed_max = speed_min
	throw_speed_tuning = {
		"linear_speed_min": speed_min,
		"linear_speed_max": speed_max,
	}


func get_throw_speed_tuning() -> Dictionary:
	return throw_speed_tuning.duplicate(true)


func get_throw_spin_tuning() -> Dictionary:
	return throw_spin_tuning.duplicate(true)


func set_idle_drift_tuning(config_values: Dictionary) -> void:
	var min_seconds := clampf(float(config_values.get("min_seconds", idle_drift_tuning["min_seconds"])), 0.10, 10.0)
	var max_seconds := clampf(float(config_values.get("max_seconds", idle_drift_tuning["max_seconds"])), 0.10, 12.0)
	if max_seconds < min_seconds:
		max_seconds = min_seconds
	var max_distance := clampf(float(config_values.get("max_distance", idle_drift_tuning["max_distance"])), 0.0, 1.5)
	var speed := clampf(float(config_values.get("speed", idle_drift_tuning["speed"])), 0.0, 1.5)
	idle_drift_tuning = {
		"min_seconds": min_seconds,
		"max_seconds": max_seconds,
		"max_distance": max_distance,
		"speed": speed,
	}
	_idle_drift_offset = clampf(_idle_drift_offset, -max_distance, max_distance)
	if not selected and not is_rolling and config != null:
		global_position = _idle_anchor_position + Vector3(0.0, 0.0, _idle_drift_offset)
		if not _idle_drift_active:
			_begin_idle_drift_round()


func get_idle_drift_tuning() -> Dictionary:
	return idle_drift_tuning.duplicate(true)


func set_selected(value: bool) -> void:
	if is_exiting or is_exited or is_returning_from_exit or is_moving_to_unselected_hold or is_in_unselected_hold or is_returning_from_unselected_hold:
		value = false
	selected = value
	if selected:
		_stop_idle_drift(true)
	elif not is_rolling and not is_returning_to_ready:
		_begin_idle_drift_round()
	_update_selection_frame()


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
	var settled_face_index := _resolve_face_from_settled_pose()
	if settled_face_index >= 0:
		config.set_face_index(settled_face_index)
	_last_settled_face_index = config.value
	_last_settled_face_value = config.get_actual_face_one()
	_last_settled_position = global_position
	_last_settled_linear_speed = linear_velocity.length()
	_last_settled_angular_speed = angular_velocity.length()
	_last_settled_stable_frames = stable_frames
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	is_rolling = false
	show_number(true)
	if need_broadcast:
		roll_stopped.emit(self, config.value, config.get_actual_face_one())


func return_to_ready_hover(hover_position: Vector3, yaw_degrees := 0.0, duration := READY_RETURN_DURATION, arc_height := READY_RETURN_ARC_HEIGHT) -> void:
	if config == null:
		ready_return_finished.emit(self)
		return
	visible = true
	_kill_unselected_hold_tween()
	is_returning_from_exit = false
	is_exiting = false
	is_exited = false
	is_moving_to_unselected_hold = false
	is_in_unselected_hold = false
	is_returning_from_unselected_hold = false
	_restore_physics_collision()
	_stop_idle_drift(false)
	is_returning_to_ready = true
	is_rolling = false
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_idle_anchor_position = hover_position
	_last_ready_return_start_position = global_position
	_last_ready_return_target_position = hover_position
	_ready_return_progress = 0.0
	_ready_return_curve_offset = 0.0
	var start_position := global_position
	var target_position := hover_position
	var start_basis := global_transform.basis.orthonormalized()
	var target_basis := Basis.from_euler(Vector3(0.0, deg_to_rad(yaw_degrees), 0.0))
	var start_inner_basis := inner_dice.basis.orthonormalized() if inner_dice != null else Basis.IDENTITY
	var target_inner_basis := _hover_presentation_basis(config.value)
	var resolved_duration := maxf(0.05, duration)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(progress: float) -> void:
		_apply_ready_return_pose(
			progress,
			start_position,
			target_position,
			start_basis,
			target_basis,
			start_inner_basis,
			target_inner_basis,
			arc_height
		),
		0.0,
		1.0,
		resolved_duration
	)
	tween.finished.connect(func() -> void:
		set_ready_hover(target_position, yaw_degrees)
		is_returning_to_ready = false
		_ready_return_progress = 1.0
		_ready_return_curve_offset = 0.0
		ready_return_finished.emit(self)
	)


func set_ready_hover(hover_position: Vector3, yaw_degrees := 0.0) -> void:
	visible = true
	_kill_unselected_hold_tween()
	is_returning_from_exit = false
	is_exiting = false
	is_exited = false
	is_moving_to_unselected_hold = false
	is_in_unselected_hold = false
	is_returning_from_unselected_hold = false
	_restore_physics_collision()
	_idle_anchor_position = hover_position
	global_position = hover_position
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	is_rolling = false
	is_returning_to_ready = false
	stable_frames = 0
	rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	apply_hover_presentation_rotation()
	show_number(true)
	_idle_drift_offset = 0.0
	if selected:
		_stop_idle_drift(true)
	else:
		_begin_idle_drift_round()
	_update_hover_shadow()
	_update_selection_frame()


func apply_hover_presentation_rotation() -> void:
	if inner_dice == null or config == null:
		return
	inner_dice.basis = _hover_presentation_basis(config.value)


func recover_to_stage(stage_position: Vector3, requested_face = null) -> void:
	if config == null:
		return
	visible = true
	_kill_unselected_hold_tween()
	is_returning_from_exit = false
	is_exiting = false
	is_exited = false
	is_moving_to_unselected_hold = false
	is_in_unselected_hold = false
	is_returning_from_unselected_hold = false
	_restore_physics_collision()
	_stop_idle_drift(false)
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


func play_exit_to(target_position: Vector3, duration := 0.55, delay := 0.0, arc_height := 0.85) -> void:
	if config == null:
		exit_finished.emit(self)
		return
	_stop_idle_drift(false)
	selected = false
	is_rolling = false
	is_returning_to_ready = false
	is_returning_from_exit = false
	_kill_unselected_hold_tween()
	is_moving_to_unselected_hold = false
	is_in_unselected_hold = false
	is_returning_from_unselected_hold = false
	is_exiting = true
	is_exited = false
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_exit_progress = 0.0
	_last_exit_start_position = global_position
	_last_exit_target_position = target_position
	var start_position := global_position
	var start_basis := global_transform.basis.orthonormalized()
	var target_basis := start_basis.rotated(Vector3.FORWARD, deg_to_rad(18.0)).orthonormalized()
	visible = true
	if _hover_shadow != null:
		_hover_shadow.visible = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	var exit_motion := func(progress: float) -> void:
		_apply_exit_pose(progress, start_position, target_position, start_basis, target_basis, arc_height)
	tween.tween_method(exit_motion, 0.0, 1.0, maxf(0.05, duration))
	tween.finished.connect(func() -> void:
		_exit_progress = 1.0
		global_position = target_position
		is_exiting = false
		is_exited = true
		visible = false
		if _hover_shadow != null:
			_hover_shadow.visible = false
		exit_finished.emit(self)
	)


func play_exit_return_from(spawn_position: Vector3, target_position: Vector3, yaw_degrees := 0.0, duration := 0.55, delay := 0.0) -> void:
	if config == null:
		exit_return_finished.emit(self)
		return
	_stop_idle_drift(false)
	selected = false
	is_rolling = false
	is_returning_to_ready = false
	is_exiting = false
	is_exited = false
	is_returning_from_exit = true
	_kill_unselected_hold_tween()
	is_moving_to_unselected_hold = false
	is_in_unselected_hold = false
	is_returning_from_unselected_hold = false
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_exit_return_progress = 0.0
	_last_exit_return_start_position = spawn_position
	_last_exit_return_target_position = target_position
	_last_exit_return_delay_seconds = delay
	_idle_anchor_position = target_position
	visible = false
	if _hover_shadow != null:
		_hover_shadow.visible = false
	var target_basis := Basis.from_euler(Vector3(0.0, deg_to_rad(yaw_degrees), 0.0))
	var target_inner_basis := _hover_presentation_basis(config.value)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		visible = true
		global_position = spawn_position
		var transform := global_transform
		transform.origin = spawn_position
		transform.basis = target_basis
		global_transform = transform
		if inner_dice != null:
			inner_dice.basis = target_inner_basis
		_update_hover_shadow()
	)
	var return_motion := func(progress: float) -> void:
		_apply_exit_return_pose(progress, spawn_position, target_position, target_basis, target_inner_basis)
	tween.tween_method(return_motion, 0.0, 1.0, maxf(0.05, duration))
	tween.finished.connect(func() -> void:
		set_ready_hover(target_position, yaw_degrees)
		is_returning_from_exit = false
		is_exited = false
		_exit_return_progress = 1.0
		exit_return_finished.emit(self)
	)


func move_to_unselected_hold(target_position: Vector3, duration := UNSELECTED_HOLD_DURATION, yaw_degrees := 0.0) -> void:
	if config == null:
		unselected_hold_finished.emit(self)
		return
	selected = false
	_stop_idle_drift(false)
	is_rolling = false
	is_returning_to_ready = false
	is_returning_from_exit = false
	is_exiting = false
	is_exited = false
	is_moving_to_unselected_hold = true
	is_in_unselected_hold = false
	is_returning_from_unselected_hold = false
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_disable_physics_collision()
	visible = true
	_last_unselected_hold_start_position = global_position
	_last_unselected_hold_target_position = target_position
	_unselected_hold_progress = 0.0
	_unselected_hold_return_progress = 0.0
	var start_position := global_position
	var start_basis := global_transform.basis.orthonormalized()
	var target_basis := Basis.from_euler(Vector3(0.0, deg_to_rad(yaw_degrees), 0.0))
	var start_inner_basis := inner_dice.basis.orthonormalized() if inner_dice != null else Basis.IDENTITY
	var target_inner_basis := _hover_presentation_basis(config.value)
	_kill_unselected_hold_tween()
	var tween := create_tween()
	_unselected_hold_tween = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(progress: float) -> void:
		_apply_unselected_hold_pose(
			progress,
			start_position,
			target_position,
			start_basis,
			target_basis,
			start_inner_basis,
			target_inner_basis
		),
		0.0,
		1.0,
		maxf(0.05, duration)
	)
	tween.finished.connect(func() -> void:
		_apply_unselected_hold_pose(1.0, start_position, target_position, start_basis, target_basis, start_inner_basis, target_inner_basis)
		_unselected_hold_tween = null
		is_moving_to_unselected_hold = false
		is_in_unselected_hold = true
		unselected_hold_finished.emit(self)
	)


func return_unselected_hold_to_ready(hover_position: Vector3, yaw_degrees := 0.0, duration := READY_RETURN_DURATION) -> void:
	if config == null:
		_restore_physics_collision()
		unselected_hold_return_finished.emit(self)
		return
	if not (is_moving_to_unselected_hold or is_in_unselected_hold or is_returning_from_unselected_hold):
		unselected_hold_return_finished.emit(self)
		return
	selected = false
	_stop_idle_drift(false)
	is_rolling = false
	is_returning_to_ready = false
	is_returning_from_exit = false
	is_exiting = false
	is_exited = false
	is_moving_to_unselected_hold = false
	is_in_unselected_hold = false
	is_returning_from_unselected_hold = true
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_disable_physics_collision()
	visible = true
	_last_unselected_hold_return_start_position = global_position
	_last_unselected_hold_return_target_position = hover_position
	_unselected_hold_return_progress = 0.0
	var start_position := global_position
	var start_basis := global_transform.basis.orthonormalized()
	var target_basis := Basis.from_euler(Vector3(0.0, deg_to_rad(yaw_degrees), 0.0))
	var start_inner_basis := inner_dice.basis.orthonormalized() if inner_dice != null else Basis.IDENTITY
	var target_inner_basis := _hover_presentation_basis(config.value)
	_kill_unselected_hold_tween()
	var tween := create_tween()
	_unselected_hold_tween = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(progress: float) -> void:
		_apply_unselected_hold_return_pose(
			progress,
			start_position,
			hover_position,
			start_basis,
			target_basis,
			start_inner_basis,
			target_inner_basis
		),
		0.0,
		1.0,
		maxf(0.05, duration)
	)
	tween.finished.connect(func() -> void:
		_unselected_hold_tween = null
		_restore_physics_collision()
		is_returning_from_unselected_hold = false
		is_in_unselected_hold = false
		is_moving_to_unselected_hold = false
		set_ready_hover(hover_position, yaw_degrees)
		_unselected_hold_return_progress = 1.0
		unselected_hold_return_finished.emit(self)
	)


func show_number(show := true) -> void:
	if number_label == null:
		return
	number_label.visible = false
	number_label.text = ""


func refresh_from_config() -> void:
	_apply_config_visuals()
	if config != null:
		config.set_face_index(config.value)
	if not is_rolling and not is_returning_to_ready and inner_dice != null:
		apply_hover_presentation_rotation()
	show_number(true)
	_update_selection_frame()


func get_debug_snapshot() -> Dictionary:
	var visual_top_face_index := _resolve_visual_top_face_index()
	var visual_top_text_alignment := _visual_top_text_alignment(visual_top_face_index)
	return {
		"face_index": config.value if config != null else -1,
		"face_value": config.get_actual_face_one() if config != null else 0,
		"material_id": str(config.material_id) if config != null else "",
		"material_name": config.get_material_name() if config != null else "",
		"body_material_source_path": _pipeline_body_material_path(GmDiceDefinition.normalize_material_id(config.material_id)) if config != null else "",
		"body_material_resource_path": _body_mesh.material_override.resource_path if _body_mesh != null and _body_mesh.material_override != null else "",
		"body_material_shader_path": _body_material_shader_path(),
		"body_material_face_detail_strength": _body_material_shader_float("face_detail_strength"),
		"body_material_edge_line_strength": _body_material_shader_float("edge_line_strength"),
		"body_material_face_layer_enabled": _body_material_shader_float("face_layer_enabled"),
		"body_material_face_layer_strength": _body_material_shader_float("face_layer_strength"),
		"body_mesh_resource_path": _body_mesh.mesh.resource_path if _body_mesh != null and _body_mesh.mesh != null else "",
		"face_pips": config.get_face_pips() if config != null else [],
		"face_labels": config.get_face_labels() if config != null else [],
		"face_layer_system": _face_layer_system.to_dictionary() if _face_layer_system != null else {},
		"face_albedo_texture_size": _face_albedo_texture_size(),
		"face_albedo_texture_exists": _face_albedo_texture != null,
		"visual_layer_roles": _visual_layer_roles_snapshot(),
		"body_layer_exists": _body_layer != null,
		"edge_rim_layer_exists": _edge_rim_layer != null,
		"edge_rim_material_name": _edge_rim_material.resource_name if _edge_rim_material != null else "",
		"edge_rim_emission_energy": _edge_rim_material_emission_energy(),
		"edge_rim_alpha": _edge_rim_material_alpha(),
		"edge_rim_bar_count": _edge_rim_bar_count(),
		"edge_rim_is_full_shell": false,
		"face_marker_layer_exists": _face_marker_layer != null,
		"face_texture_layer_exists": _face_texture_layer != null,
		"face_texture_panel_count": _face_texture_panel_count(),
		"face_marker_label_count": _face_labels.size() if _face_marker_layer != null else 0,
		"state_overlay_layer_exists": _state_overlay_layer != null,
		"contact_shadow_layer_exists": _contact_shadow_layer != null,
		"face_label_count": _face_labels.size(),
		"face_label_nodes_visible": _face_label_nodes_visible(),
		"face_label_centered": _face_labels_are_centered(),
		"face_label_double_sided": _face_labels_are_double_sided(),
		"face_label_min_surface_offset": _face_label_min_surface_offset(),
		"visual_top_face_index": visual_top_face_index,
		"visual_top_face_value": _face_value_for_index(visual_top_face_index),
		"visual_top_text_alignment": visual_top_text_alignment,
		"rolling": is_rolling,
		"returning_to_ready": is_returning_to_ready,
		"returning_from_exit": is_returning_from_exit,
		"exiting": is_exiting,
		"exited": is_exited,
		"moving_to_unselected_hold": is_moving_to_unselected_hold,
		"in_unselected_hold": is_in_unselected_hold,
		"returning_from_unselected_hold": is_returning_from_unselected_hold,
		"unselected_hold_active": is_moving_to_unselected_hold or is_in_unselected_hold or is_returning_from_unselected_hold,
		"unselected_hold_collision_disabled": _unselected_hold_collision_disabled,
		"unselected_hold_start_position": _last_unselected_hold_start_position,
		"unselected_hold_target_position": _last_unselected_hold_target_position,
		"unselected_hold_progress": _unselected_hold_progress,
		"unselected_hold_return_start_position": _last_unselected_hold_return_start_position,
		"unselected_hold_return_target_position": _last_unselected_hold_return_target_position,
		"unselected_hold_return_progress": _unselected_hold_return_progress,
		"exit_progress": _exit_progress,
		"exit_start_position": _last_exit_start_position,
		"exit_target_position": _last_exit_target_position,
		"exit_return_progress": _exit_return_progress,
		"exit_return_start_position": _last_exit_return_start_position,
		"exit_return_target_position": _last_exit_return_target_position,
		"exit_return_delay_seconds": _last_exit_return_delay_seconds,
		"stable_frames": stable_frames,
		"linear_speed": linear_velocity.length(),
		"angular_speed": angular_velocity.length(),
		"position": global_position,
		"rotation_degrees": rotation_degrees,
		"hover_shadow_visible": _hover_shadow != null and _hover_shadow.visible,
		"hover_shadow_position": _hover_shadow.global_position if _hover_shadow != null else Vector3.ZERO,
		"selected": selected,
		"selection_frame_visible": _selection_frame != null and _selection_frame.visible,
		"select_area_pickable": select_area != null and select_area.input_ray_pickable,
		"idle_anchor_position": _idle_anchor_position,
		"idle_drift_active": _idle_drift_active,
		"idle_drift_offset": _idle_drift_offset,
		"idle_drift_direction": _idle_drift_direction,
		"idle_drift_duration": _idle_drift_duration,
		"idle_drift_tuning": idle_drift_tuning.duplicate(true),
		"last_throw_origin_position": _last_throw_origin_position,
		"last_throw_target_position": _last_throw_target_position,
		"last_throw_direction": _last_throw_direction,
		"last_throw_velocity": _last_throw_velocity,
		"last_settled_face_index": _last_settled_face_index,
		"last_settled_face_value": _last_settled_face_value,
		"last_settled_position": _last_settled_position,
		"last_settled_linear_speed": _last_settled_linear_speed,
		"last_settled_angular_speed": _last_settled_angular_speed,
		"last_settled_stable_frames": _last_settled_stable_frames,
		"ready_return_start_position": _last_ready_return_start_position,
		"ready_return_target_position": _last_ready_return_target_position,
		"ready_return_progress": _ready_return_progress,
		"ready_return_curve_offset": _ready_return_curve_offset,
		"throw_speed_tuning": throw_speed_tuning.duplicate(true),
		"throw_spin_tuning": throw_spin_tuning.duplicate(true),
	}


func _body_shader_material() -> ShaderMaterial:
	if _body_mesh == null:
		return null
	return _body_mesh.material_override as ShaderMaterial


func _body_material_shader_path() -> String:
	var material := _body_shader_material()
	if material == null or material.shader == null:
		return ""
	return material.shader.resource_path


func _body_material_shader_float(parameter_name: String) -> float:
	var material := _body_shader_material()
	if material == null:
		return 0.0
	var value = material.get_shader_parameter(parameter_name)
	if value == null:
		return 0.0
	return float(value)


func _visual_layer_roles_snapshot() -> Dictionary:
	return {
		"body": _body_layer != null and _body_mesh != null and _body_mesh.mesh != null,
		"edge_rim": _edge_rim_layer != null and _edge_rim_bar_count() > 0 and _edge_rim_material != null,
		"face_marker": _face_marker_layer != null and _face_texture_panel_count() == 0 and _face_layer_system != null,
		"face_albedo_texture": _face_albedo_texture != null and _body_material_shader_float("face_layer_enabled") > 0.5,
		"state_overlay": _state_overlay_layer != null and _selection_frame != null,
		"contact_shadow": _contact_shadow_layer != null and _hover_shadow != null,
	}


func _face_albedo_texture_size() -> Vector2i:
	if _face_albedo_texture == null:
		return Vector2i.ZERO
	var image := _face_albedo_texture.get_image()
	if image == null:
		return Vector2i.ZERO
	return Vector2i(image.get_width(), image.get_height())


func _edge_rim_material_emission_energy() -> float:
	if _edge_rim_material == null:
		return 0.0
	return _edge_rim_material.emission_energy_multiplier


func _edge_rim_material_alpha() -> float:
	if _edge_rim_material == null:
		return 0.0
	return _edge_rim_material.albedo_color.a


func _edge_rim_bar_count() -> int:
	if _edge_rim_layer == null:
		return 0
	return _edge_rim_layer.get_child_count()


func _face_texture_panel_count() -> int:
	if _face_texture_layer == null:
		return 0
	var count := 0
	for child in _face_texture_layer.get_children():
		if str(child.name).begins_with("FaceTexturePanel"):
			count += 1
	return count


func _face_labels_are_centered() -> bool:
	if _face_labels.is_empty():
		return true
	for label in _face_labels:
		if label == null:
			return false
		if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
			return false
		if label.vertical_alignment != VERTICAL_ALIGNMENT_CENTER:
			return false
	return true


func _face_labels_are_double_sided() -> bool:
	if _face_labels.is_empty():
		return true
	for label in _face_labels:
		if label == null or not label.double_sided:
			return false
	return true


func _face_label_nodes_visible() -> bool:
	for label in _face_labels:
		if label != null and label.visible:
			return true
	return false


func _face_label_min_surface_offset() -> float:
	if _face_labels.is_empty():
		return 0.0
	var min_offset := INF
	for label in _face_labels:
		if label == null:
			return 0.0
		var position := label.position
		var dominant := maxf(absf(position.x), maxf(absf(position.y), absf(position.z)))
		min_offset = minf(min_offset, dominant - DIE_HALF)
	return min_offset


func _prepare_roll_body() -> void:
	visible = true
	_kill_unselected_hold_tween()
	is_returning_from_exit = false
	is_exiting = false
	is_exited = false
	is_moving_to_unselected_hold = false
	is_in_unselected_hold = false
	is_returning_from_unselected_hold = false
	_restore_physics_collision()
	_stop_idle_drift(false)
	is_rolling = true
	is_returning_to_ready = false
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


func _begin_idle_drift_round() -> void:
	if config == null or is_rolling or is_returning_to_ready or is_returning_from_exit or is_moving_to_unselected_hold or is_in_unselected_hold or is_returning_from_unselected_hold or selected:
		return
	var min_seconds := float(idle_drift_tuning.get("min_seconds", DEFAULT_IDLE_DRIFT_TUNING["min_seconds"]))
	var max_seconds := float(idle_drift_tuning.get("max_seconds", DEFAULT_IDLE_DRIFT_TUNING["max_seconds"]))
	var max_distance := maxf(0.0, float(idle_drift_tuning.get("max_distance", DEFAULT_IDLE_DRIFT_TUNING["max_distance"])))
	if max_seconds < min_seconds:
		max_seconds = min_seconds
	_idle_drift_active = true
	_idle_drift_elapsed = 0.0
	_idle_drift_duration = _rng.randf_range(min_seconds, max_seconds)
	_idle_drift_direction = -1.0 if _rng.randf() < 0.5 else 1.0
	if _idle_drift_offset >= max_distance and _idle_drift_direction > 0.0:
		_idle_drift_direction = -1.0
	elif _idle_drift_offset <= -max_distance and _idle_drift_direction < 0.0:
		_idle_drift_direction = 1.0


func _stop_idle_drift(return_to_anchor: bool) -> void:
	_idle_drift_active = false
	_idle_drift_elapsed = 0.0
	_idle_drift_offset = 0.0
	if return_to_anchor:
		global_position = _idle_anchor_position


func _update_idle_drift(delta: float) -> void:
	if selected or is_rolling or is_returning_to_ready or is_returning_from_exit or is_moving_to_unselected_hold or is_in_unselected_hold or is_returning_from_unselected_hold or is_exiting or is_exited or config == null:
		return
	if not _idle_drift_active:
		_begin_idle_drift_round()
	if not _idle_drift_active:
		return
	var max_distance := maxf(0.0, float(idle_drift_tuning.get("max_distance", DEFAULT_IDLE_DRIFT_TUNING["max_distance"])))
	var speed := maxf(0.0, float(idle_drift_tuning.get("speed", DEFAULT_IDLE_DRIFT_TUNING["speed"])))
	if max_distance <= 0.0 or speed <= 0.0:
		_idle_drift_offset = 0.0
		global_position = _idle_anchor_position
		return
	_idle_drift_elapsed += delta
	_idle_drift_offset += _idle_drift_direction * speed * delta
	var reached_limit := absf(_idle_drift_offset) >= max_distance
	if reached_limit:
		_idle_drift_offset = clampf(_idle_drift_offset, -max_distance, max_distance)
	global_position = _idle_anchor_position + Vector3(0.0, 0.0, _idle_drift_offset)
	if reached_limit or _idle_drift_elapsed >= _idle_drift_duration:
		_begin_idle_drift_round()


func _apply_throw_motion(need_broadcast: bool) -> void:
	var m := maxf(0.1, roll_multiplier)
	_last_throw_origin_position = global_position
	_last_throw_target_position = _random_downward_throw_target(_last_throw_origin_position)
	_last_throw_direction = (_last_throw_target_position - _last_throw_origin_position).normalized()
	if _last_throw_direction.length_squared() <= 0.001:
		_last_throw_direction = Vector3.DOWN
	var linear_speed_min := float(throw_speed_tuning.get("linear_speed_min", DEFAULT_THROW_SPEED_TUNING["linear_speed_min"]))
	var linear_speed_max := maxf(linear_speed_min, float(throw_speed_tuning.get("linear_speed_max", DEFAULT_THROW_SPEED_TUNING["linear_speed_max"])))
	var throw_speed := _rng.randf_range(linear_speed_min, linear_speed_max) * m
	linear_velocity = _last_throw_direction * throw_speed
	_last_throw_velocity = linear_velocity
	var angular_speed_min := float(throw_spin_tuning.get("angular_speed_min", DEFAULT_THROW_SPIN_TUNING["angular_speed_min"]))
	var angular_speed_max := maxf(angular_speed_min, float(throw_spin_tuning.get("angular_speed_max", DEFAULT_THROW_SPIN_TUNING["angular_speed_max"])))
	var torque_min := float(throw_spin_tuning.get("torque_min", DEFAULT_THROW_SPIN_TUNING["torque_min"]))
	var torque_max := maxf(torque_min, float(throw_spin_tuning.get("torque_max", DEFAULT_THROW_SPIN_TUNING["torque_max"])))
	angular_velocity = _random_unit_vector() * _rng.randf_range(angular_speed_min, angular_speed_max) * m
	var torque := _random_unit_vector() * _rng.randf_range(torque_min, torque_max) * m
	apply_torque_impulse(torque)
	if angular_velocity.length() > MAX_ANGULAR_SPEED:
		angular_velocity = angular_velocity.limit_length(MAX_ANGULAR_SPEED)
	show_number(false)
	if need_broadcast:
		roll_started.emit(self)


func _apply_exit_pose(progress: float, start_position: Vector3, target_position: Vector3, start_basis: Basis, target_basis: Basis, arc_height: float) -> void:
	var t := clampf(progress, 0.0, 1.0)
	_exit_progress = t
	var position := start_position.lerp(target_position, t)
	position += Vector3.UP * sin(t * PI) * arc_height
	var transform := global_transform
	transform.origin = position
	transform.basis = start_basis.slerp(target_basis, t).orthonormalized()
	global_transform = transform
	_update_hover_shadow()
	_update_selection_frame()


func _apply_exit_return_pose(progress: float, start_position: Vector3, target_position: Vector3, target_basis: Basis, target_inner_basis: Basis) -> void:
	var t := clampf(progress, 0.0, 1.0)
	_exit_return_progress = t
	var transform := global_transform
	transform.origin = start_position.lerp(target_position, t)
	transform.basis = target_basis
	global_transform = transform
	if inner_dice != null:
		inner_dice.basis = target_inner_basis
	_update_hover_shadow()
	_update_selection_frame()


func _apply_unselected_hold_pose(
	progress: float,
	start_position: Vector3,
	target_position: Vector3,
	start_basis: Basis,
	target_basis: Basis,
	start_inner_basis: Basis,
	target_inner_basis: Basis
) -> void:
	var t := clampf(progress, 0.0, 1.0)
	_unselected_hold_progress = t
	var transform := global_transform
	transform.origin = start_position.lerp(target_position, t)
	transform.basis = start_basis.slerp(target_basis, t).orthonormalized()
	global_transform = transform
	if inner_dice != null:
		inner_dice.basis = start_inner_basis.slerp(target_inner_basis, t).orthonormalized()
	_update_hover_shadow()
	_update_selection_frame()


func _apply_unselected_hold_return_pose(
	progress: float,
	start_position: Vector3,
	target_position: Vector3,
	start_basis: Basis,
	target_basis: Basis,
	start_inner_basis: Basis,
	target_inner_basis: Basis
) -> void:
	var t := clampf(progress, 0.0, 1.0)
	_unselected_hold_return_progress = t
	var transform := global_transform
	transform.origin = start_position.lerp(target_position, t)
	transform.basis = start_basis.slerp(target_basis, t).orthonormalized()
	global_transform = transform
	if inner_dice != null:
		inner_dice.basis = start_inner_basis.slerp(target_inner_basis, t).orthonormalized()
	_update_hover_shadow()
	_update_selection_frame()


func _random_downward_throw_target(origin: Vector3) -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var radius := _rng.randf_range(DOWNWARD_THROW_TARGET_RADIUS_MIN, DOWNWARD_THROW_TARGET_RADIUS_MAX)
	return Vector3(
		origin.x + cos(angle) * radius,
		_rng.randf_range(DOWNWARD_THROW_TARGET_Y_MIN, DOWNWARD_THROW_TARGET_Y_MAX),
		origin.z + sin(angle) * radius
	)


func _random_unit_vector() -> Vector3:
	var vector := Vector3(
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0)
	)
	if vector.length_squared() <= 0.001:
		return Vector3.UP
	return vector.normalized()


func _resolve_face_from_settled_pose() -> int:
	return _resolve_visual_top_face_index()


func _resolve_visual_top_face_index() -> int:
	if config == null or config.run_faces.is_empty():
		return -1
	var best_index := clampi(config.value, 0, config.run_faces.size() - 1)
	var best_dot := -INF
	var face_count := mini(FACE_LOCAL_NORMALS.size(), config.run_faces.size())
	for index in range(face_count):
		var face_normal: Vector3 = (inner_dice.global_transform.basis * FACE_LOCAL_NORMALS[index]).normalized() if inner_dice != null else FACE_LOCAL_NORMALS[index]
		var up_dot: float = face_normal.dot(Vector3.UP)
		if up_dot > best_dot:
			best_dot = up_dot
			best_index = index
	return best_index


func _face_value_for_index(face_index: int) -> int:
	if config == null or face_index < 0 or face_index >= config.run_faces.size():
		return 0
	var face = config.run_faces[face_index]
	if face == null:
		return 0
	return int(face.value)


func _visual_top_text_alignment(face_index: int) -> float:
	if face_index < 0 or inner_dice == null:
		return -1.0
	var text_up_world := inner_dice.global_transform.basis * _face_text_up_local(face_index)
	text_up_world = (text_up_world - Vector3.UP * text_up_world.dot(Vector3.UP))
	if text_up_world.length_squared() <= 0.001:
		return -1.0
	return text_up_world.normalized().dot(_ready_text_up_world())


func _apply_ready_return_pose(
	progress: float,
	start_position: Vector3,
	target_position: Vector3,
	start_basis: Basis,
	target_basis: Basis,
	start_inner_basis: Basis,
	target_inner_basis: Basis,
	arc_height: float
) -> void:
	var t := clampf(progress, 0.0, 1.0)
	_ready_return_progress = t
	_ready_return_curve_offset = sin(t * PI) * arc_height
	var position := start_position.lerp(target_position, t) + Vector3.UP * _ready_return_curve_offset
	var transform := global_transform
	transform.origin = position
	transform.basis = start_basis.slerp(target_basis, t).orthonormalized()
	global_transform = transform
	if inner_dice != null:
		inner_dice.basis = start_inner_basis.slerp(target_inner_basis, t).orthonormalized()
	_update_hover_shadow()
	_update_selection_frame()


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
	var parent := _contact_shadow_layer if _contact_shadow_layer != null else self
	parent.add_child(_hover_shadow)
	_update_hover_shadow()


func _update_hover_shadow() -> void:
	if _hover_shadow == null:
		return
	if not is_inside_tree() or is_exited:
		_hover_shadow.visible = false
		return
	var height := maxf(global_position.y - SHADOW_Y, 0.0)
	var shadow_scale := clampf(0.76 + height * 0.08, 0.76, 0.98)
	var shadow_alpha := clampf(0.28 - height * 0.038, 0.13, 0.26)
	_hover_shadow.visible = config != null
	_hover_shadow.global_position = Vector3(global_position.x, SHADOW_Y, global_position.z)
	_hover_shadow.global_rotation = Vector3.ZERO
	_hover_shadow.scale = Vector3(shadow_scale, 1.0, shadow_scale)
	if _shadow_material != null:
		_shadow_material.albedo_color = Color(0.0, 0.0, 0.0, shadow_alpha)


func _build_selection_frame() -> void:
	_selection_material = StandardMaterial3D.new()
	_selection_material.albedo_color = Color(0.64, 1.0, 0.42, 0.96)
	_selection_material.emission_enabled = true
	_selection_material.emission = Color(0.64, 1.0, 0.42)
	_selection_material.emission_energy_multiplier = 0.95
	_selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_selection_material.no_depth_test = false

	_selection_frame = Node3D.new()
	_selection_frame.name = "SelectionFrame"
	_selection_frame.top_level = true
	_selection_frame.visible = false
	var parent := _state_overlay_layer if _state_overlay_layer != null else self
	parent.add_child(_selection_frame)

	var half := SELECTION_FRAME_SIZE * 0.5
	var corner_center := half - SELECTION_FRAME_CORNER_LENGTH * 0.5
	var horizontal_size := Vector3(SELECTION_FRAME_CORNER_LENGTH, SELECTION_FRAME_THICKNESS, SELECTION_FRAME_THICKNESS)
	var vertical_size := Vector3(SELECTION_FRAME_THICKNESS, SELECTION_FRAME_THICKNESS, SELECTION_FRAME_CORNER_LENGTH)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_selection_frame_bar(Vector3(sx * corner_center, 0.0, sz * half), horizontal_size)
			_add_selection_frame_bar(Vector3(sx * half, 0.0, sz * corner_center), vertical_size)
	_update_selection_frame()


func _add_selection_frame_bar(local_position: Vector3, size: Vector3) -> void:
	if _selection_frame == null:
		return
	var mesh := BoxMesh.new()
	mesh.size = size
	var bar := MeshInstance3D.new()
	bar.name = "SelectionFrameBar"
	bar.mesh = mesh
	bar.position = local_position
	bar.material_override = _selection_material
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_selection_frame.add_child(bar)


func _update_selection_frame() -> void:
	if _selection_frame == null:
		return
	_selection_frame.visible = selected and config != null and is_inside_tree()
	if not _selection_frame.visible:
		return
	_selection_frame.global_position = Vector3(
		global_position.x,
		global_position.y + DIE_HALF + SELECTION_FRAME_Y_OFFSET,
		global_position.z
	)


func _apply_config_visuals() -> void:
	var material_id := GmDiceDefinition.MATERIAL_STANDARD
	if config != null:
		material_id = GmDiceDefinition.normalize_material_id(config.material_id)
	_rebuild_face_layers()
	_body_material = _make_body_material(_base_body_color, material_id)
	if _body_mesh != null:
		_body_mesh.material_override = _body_material
		_apply_body_mesh(material_id)
	_apply_face_label_style(material_id)


func _make_body_material(body_color: Color, material_id: StringName) -> Material:
	return GmDiceMaterialResolver.make_body_material_instance(body_color, material_id, _face_albedo_texture, true)


func _apply_body_mesh(material_id: StringName) -> void:
	if _body_mesh == null:
		return
	var pipeline_mesh := _load_pipeline_body_mesh(material_id)
	if pipeline_mesh != null:
		_body_mesh.mesh = pipeline_mesh
		_body_mesh.scale = Vector3.ONE * DIE_SIZE
		_sync_edge_rim_mesh()
		return
	push_error("Rounded dice body mesh is unavailable")
	_body_mesh.mesh = null
	_sync_edge_rim_mesh()


func _sync_edge_rim_mesh() -> void:
	if _edge_rim_layer == null:
		return
	for child in _edge_rim_layer.get_children():
		_edge_rim_layer.remove_child(child)
		child.free()
	var half := DIE_SIZE * 0.432
	var length := half * 2.0
	var radius := DIE_SIZE * 0.010
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_edge_bevel_rail(Vector3(0.0, sy * half, sz * half), "x", length, radius)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_edge_bevel_rail(Vector3(sx * half, 0.0, sz * half), "y", length, radius)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			_add_edge_bevel_rail(Vector3(sx * half, sy * half, 0.0), "z", length, radius)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_add_edge_corner_bevel_cap(Vector3(sx * half, sy * half, sz * half), radius)


func _add_edge_bevel_rail(local_position: Vector3, axis: String, length: float, radius: float) -> void:
	if _edge_rim_layer == null:
		return
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 10
	mesh.rings = 1
	var bar := MeshInstance3D.new()
	bar.name = "EdgeBevelRail_%02d" % [_edge_rim_layer.get_child_count() + 1]
	bar.mesh = mesh
	bar.position = local_position
	if axis == "x":
		bar.rotation.z = PI * 0.5
	elif axis == "z":
		bar.rotation.x = PI * 0.5
	bar.material_override = _edge_rim_material
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_edge_rim_layer.add_child(bar)


func _add_edge_corner_bevel_cap(local_position: Vector3, radius: float) -> void:
	if _edge_rim_layer == null:
		return
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var cap := MeshInstance3D.new()
	cap.name = "EdgeCornerBevelCap_%02d" % [_edge_rim_layer.get_child_count() + 1]
	cap.mesh = mesh
	cap.position = local_position
	cap.material_override = _edge_rim_material
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_edge_rim_layer.add_child(cap)


func _apply_edge_rim_style(material_id: StringName) -> void:
	_edge_rim_material = GmDiceMaterialResolver.make_edge_rim_material(material_id, _mark_color)
	if _edge_rim_layer != null:
		_sync_edge_rim_mesh()


func _load_pipeline_body_material(material_id: StringName) -> Material:
	return GmDiceMaterialResolver.load_body_material(material_id)


func _load_pipeline_body_mesh(material_id: StringName) -> Mesh:
	return GmDiceMaterialResolver.load_body_mesh(material_id)


func _pipeline_body_material_path(material_id: StringName) -> String:
	return GmDiceMaterialResolver.material_resource_path(material_id)


func _make_repro_body_material(body_color: Color, material_id: StringName) -> Material:
	return GmDiceMaterialResolver.make_programmatic_body_material(body_color, material_id)


func _apply_face_label_style(material_id: StringName) -> void:
	var text_color := _face_label_color_for_material(material_id)
	var outline_color := _face_label_outline_color_for_material(material_id)
	for label in _face_labels:
		if label == null:
			continue
		label.modulate = text_color
		label.outline_size = 12
		label.outline_modulate = outline_color


func _sync_face_texture_decals(material_id: StringName) -> void:
	if _face_texture_layer == null:
		return
	for child in _face_texture_layer.get_children():
		_face_texture_layer.remove_child(child)
		child.free()
	var fill_material := _make_face_texture_material(material_id)
	var border_material := _make_face_texture_border_material(material_id)
	var face_offset := DIE_HALF + FACE_TEXTURE_SURFACE_OFFSET
	var face_rows := [
		{"name": "FaceTexture1", "normal": Vector3.UP, "axis_x": Vector3.RIGHT, "axis_z": Vector3.BACK},
		{"name": "FaceTexture6", "normal": Vector3.DOWN, "axis_x": Vector3.RIGHT, "axis_z": Vector3.FORWARD},
		{"name": "FaceTexture2", "normal": Vector3.FORWARD, "axis_x": Vector3.RIGHT, "axis_z": Vector3.UP},
		{"name": "FaceTexture5", "normal": Vector3.BACK, "axis_x": Vector3.LEFT, "axis_z": Vector3.UP},
		{"name": "FaceTexture3", "normal": Vector3.RIGHT, "axis_x": Vector3.BACK, "axis_z": Vector3.UP},
		{"name": "FaceTexture4", "normal": Vector3.LEFT, "axis_x": Vector3.FORWARD, "axis_z": Vector3.UP},
	]
	for index in range(face_rows.size()):
		var row: Dictionary = face_rows[index]
		var normal: Vector3 = (row["normal"] as Vector3).normalized()
		var axis_x: Vector3 = (row["axis_x"] as Vector3).normalized()
		var axis_z: Vector3 = (row["axis_z"] as Vector3).normalized()
		var basis := Basis(axis_x, normal, axis_z).orthonormalized()
		var center := normal * face_offset
		_add_face_texture_quad(
			"FaceTexturePanel%d" % [index + 1],
			center,
			basis,
			Vector2(FACE_TEXTURE_SIZE, FACE_TEXTURE_SIZE),
			fill_material
		)
		var half := FACE_TEXTURE_SIZE * 0.5
		var border := FACE_TEXTURE_BORDER_THICKNESS
		var border_offset := normal * 0.0015
		_add_face_texture_quad(
			"FaceTextureBorderTop%d" % [index + 1],
			center + axis_z * (half - border * 0.5) + border_offset,
			basis,
			Vector2(FACE_TEXTURE_SIZE, border),
			border_material
		)
		_add_face_texture_quad(
			"FaceTextureBorderBottom%d" % [index + 1],
			center - axis_z * (half - border * 0.5) + border_offset,
			basis,
			Vector2(FACE_TEXTURE_SIZE, border),
			border_material
		)
		_add_face_texture_quad(
			"FaceTextureBorderLeft%d" % [index + 1],
			center - axis_x * (half - border * 0.5) + border_offset,
			basis,
			Vector2(border, FACE_TEXTURE_SIZE),
			border_material
		)
		_add_face_texture_quad(
			"FaceTextureBorderRight%d" % [index + 1],
			center + axis_x * (half - border * 0.5) + border_offset,
			basis,
			Vector2(border, FACE_TEXTURE_SIZE),
			border_material
		)


func _add_face_texture_quad(name: String, local_position: Vector3, local_basis: Basis, size: Vector2, material: Material) -> void:
	if _face_texture_layer == null:
		return
	var panel := MeshInstance3D.new()
	panel.name = name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.006, size.y)
	panel.mesh = mesh
	panel.position = local_position
	panel.basis = local_basis
	panel.material_override = material
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_face_texture_layer.add_child(panel)


func _make_face_texture_material(material_id: StringName) -> StandardMaterial3D:
	var edge := GmDiceMaterialResolver.edge_rim_color(material_id, _mark_color)
	var material := StandardMaterial3D.new()
	material.resource_name = "gm_%s_face_texture_panel" % str(GmDiceDefinition.normalize_material_id(material_id))
	material.albedo_color = Color(edge.r * 0.08, edge.g * 0.12, edge.b * 0.17, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(edge.r * 0.10, edge.g * 0.16, edge.b * 0.24, 1.0)
	material.emission_energy_multiplier = 0.34
	material.roughness = 0.52
	material.metallic = 0.0
	return material


func _make_face_texture_border_material(material_id: StringName) -> StandardMaterial3D:
	var edge := GmDiceMaterialResolver.edge_rim_color(material_id, _mark_color)
	var material := StandardMaterial3D.new()
	material.resource_name = "gm_%s_face_texture_border" % str(GmDiceDefinition.normalize_material_id(material_id))
	material.albedo_color = Color(edge.r, edge.g, edge.b, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = edge
	material.emission_energy_multiplier = 0.24
	material.roughness = 0.46
	material.metallic = 0.0
	return material


func _face_label_color_for_material(material_id: StringName) -> Color:
	return Color(0.960784, 0.949020, 0.909804, 1.0)


func _face_label_outline_color_for_material(material_id: StringName) -> Color:
	match GmDiceDefinition.normalize_material_id(material_id):
		GmDiceDefinition.MATERIAL_REPRO_BLUE:
			return Color(0.00, 0.05, 0.18, 0.84)
		GmDiceDefinition.MATERIAL_REPRO_PURPLE:
			return Color(0.08, 0.00, 0.16, 0.86)
		GmDiceDefinition.MATERIAL_REPRO_CYAN:
			return Color(0.00, 0.08, 0.10, 0.84)
		GmDiceDefinition.MATERIAL_REPRO_GOLD, GmDiceDefinition.MATERIAL_GOLD:
			return Color(0.16, 0.08, 0.00, 0.86)
		GmDiceDefinition.MATERIAL_REPRO_SILVERWHITE, GmDiceDefinition.MATERIAL_CRYSTAL:
			return Color(0.02, 0.05, 0.10, 0.82)
		_:
			return Color(0.03, 0.04, 0.08, 0.70)


func _disable_physics_collision() -> void:
	if not _unselected_hold_collision_disabled:
		_stored_collision_layer = collision_layer
		_stored_collision_mask = collision_mask
		_stored_select_area_pickable = select_area.input_ray_pickable if select_area != null else true
	_unselected_hold_collision_disabled = true
	collision_layer = 0
	collision_mask = 0
	if select_area != null:
		select_area.input_ray_pickable = false


func _restore_physics_collision() -> void:
	if not _unselected_hold_collision_disabled:
		return
	collision_layer = _stored_collision_layer
	collision_mask = _stored_collision_mask
	if select_area != null:
		select_area.input_ray_pickable = _stored_select_area_pickable
	_unselected_hold_collision_disabled = false


func _kill_unselected_hold_tween() -> void:
	if is_instance_valid(_unselected_hold_tween):
		_unselected_hold_tween.kill()
	_unselected_hold_tween = null
	if _selection_frame != null:
		_selection_frame.global_rotation = Vector3.ZERO


func _on_select_area_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if is_rolling or is_returning_to_ready:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			selection_requested.emit(self)
			var viewport := get_viewport()
			if viewport != null:
				viewport.set_input_as_handled()


func _create_face_labels(parent: Node3D, mark_color: Color) -> void:
	_face_labels.clear()
	if parent != null:
		parent.set_meta("face_marker_source", "DiceFaceLayerSystem")
		parent.set_meta("legacy_label3d_display", false)


func _update_face_labels() -> void:
	_rebuild_face_layers()
	if _body_material != null:
		GmDiceMaterialResolver.apply_face_layer_texture(_body_material, _face_albedo_texture, true)


func _rebuild_face_layers() -> void:
	var material_id := GmDiceDefinition.MATERIAL_STANDARD
	if config != null:
		material_id = GmDiceDefinition.normalize_material_id(config.material_id)
	var rows: Array = []
	if config != null and not config.run_faces.is_empty():
		for face in config.run_faces:
			rows.append(_face_layer_row_from_config_face(face))
	else:
		for value in range(1, 7):
			rows.append({"label": str(value), "mark_id": &"none"})
	_face_layer_system = DiceFaceLayerSystem.from_face_rows(rows, {
		"number_color": _face_label_color_for_material(material_id),
		"enable_numbers": true,
		"enable_marks": true,
	})
	_face_albedo_texture = _face_layer_system.get_face_albedo_texture()


func _face_layer_row_from_config_face(face) -> Dictionary:
	if face == null:
		return {"label": "", "mark_id": &"none"}
	var row := {
		"label": str(face.get("label")) if face.get("label") != null else "",
		"mark_id": StringName(str(face.get("mark_id"))) if face.get("mark_id") != null else &"none",
	}
	var layer_set = face.get("layer_set")
	if layer_set != null:
		row["layer_set"] = layer_set
	return row


func _hover_presentation_basis(face_index: int) -> Basis:
	var index: int = clampi(face_index, 0, FACE_LOCAL_NORMALS.size() - 1)
	var source_normal: Vector3 = (FACE_LOCAL_NORMALS[index] as Vector3).normalized()
	var source_text_up: Vector3 = _face_text_up_local(index)
	source_text_up = (source_text_up - source_normal * source_text_up.dot(source_normal))
	if source_text_up.length_squared() <= 0.001:
		return Basis.IDENTITY
	source_text_up = source_text_up.normalized()
	var target_normal: Vector3 = Vector3.UP
	var target_text_up: Vector3 = _ready_text_up_world()
	var source_right: Vector3 = source_text_up.cross(source_normal).normalized()
	var target_right: Vector3 = target_text_up.cross(target_normal).normalized()
	var source_basis: Basis = Basis(source_right, source_text_up, source_normal).orthonormalized()
	var target_basis: Basis = Basis(target_right, target_text_up, target_normal).orthonormalized()
	return (target_basis * source_basis.inverse()).orthonormalized()


func _face_text_up_local(face_index: int) -> Vector3:
	if face_index >= 0 and face_index < _face_labels.size() and _face_labels[face_index] != null:
		return (_face_labels[face_index] as Label3D).transform.basis.y.normalized()
	match clampi(face_index, 0, 5):
		0:
			return Vector3.FORWARD
		1:
			return Vector3.BACK
		2:
			return Vector3.UP
		3:
			return Vector3.UP
		4:
			return Vector3.UP
		5:
			return Vector3.UP
		_:
			return Vector3.FORWARD


func _ready_text_up_world() -> Vector3:
	var text_up: Vector3 = _face_text_up_local(0)
	text_up = text_up - Vector3.UP * text_up.dot(Vector3.UP)
	if text_up.length_squared() <= 0.001:
		return Vector3.FORWARD
	return text_up.normalized()
